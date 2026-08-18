import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/reconciliation/application/break_filter_controller.dart';
import 'package:manager_bot/features/reconciliation/data/break_filter.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/data/reconciliation_repository.dart';

/// Everything the breaks list renders: the accumulated page plus the state of
/// an in-flight "load more".
///
/// A failed page 2 must NOT throw away page 1 - an admin working a queue would
/// lose their place - so the tail error lives here as a value rather than in
/// the surrounding [AsyncValue].
class BreakListState {
  const BreakListState({
    required this.page,
    required this.filter,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final CursorPage<BreakView> page;

  /// The filter these rows were fetched under.
  final BreakFilter filter;

  final bool isLoadingMore;

  /// Failure of the LAST page fetch only; page 1 is still valid.
  ///
  /// Typed [Object] rather than [ApiError] on purpose: a row whose money field
  /// the parser rejects surfaces as an `ApiUnexpected` today, but a parse
  /// failure raised anywhere else must still be showable instead of leaving the
  /// footer spinning forever. `ErrorStateView` renders any of them.
  final Object? loadMoreError;

  List<BreakView> get items => page.items;
  bool get isEmpty => page.isEmpty;

  /// The cursor is opaque and null means exhausted, so both halves are checked.
  bool get hasMore => page.hasMore && page.nextCursor != null;

  int get openCount =>
      items.where((BreakView item) => !item.status.isTerminal).length;

  /// Rows that should shout: unresolved and either severe or drifting.
  int get attentionCount =>
      items.where((BreakView item) => item.needsAttention).length;

  /// True when at least one unresolved break carries a non-zero difference.
  bool get hasOutstandingDrift => items.any(
        (BreakView item) => !item.status.isTerminal && item.hasDrift,
      );

  /// True when a "load more" would actually be sent. A failed page must be
  /// retried DELIBERATELY (see [BreakListController.retryLoadMore]); otherwise
  /// the scroll listener re-fires the same failing request on every tick.
  bool get canLoadMore => hasMore && !isLoadingMore && loadMoreError == null;

  BreakListState copyWith({
    CursorPage<BreakView>? page,
    BreakFilter? filter,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return BreakListState(
      page: page ?? this.page,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

/// Cursor-paged breaks list.
///
/// Watches [breakFilterProvider]: changing a facet rebuilds from page 1, which
/// is mandatory because a cursor is only meaningful for the query that produced
/// it. A stale or malformed cursor is silently treated as page 1 by the server,
/// never as an error, so there is no cursor-reset error path to handle.
class BreakListController extends AsyncNotifier<BreakListState> {
  bool _loadingMore = false;

  @override
  Future<BreakListState> build() async {
    final BreakFilter filter = ref.watch(breakFilterProvider);
    final CursorPage<BreakView> page = await ref
        .read(reconciliationRepositoryProvider)
        .listBreaks(filter: filter);
    return BreakListState(page: page, filter: filter);
  }

  /// Fetches the next page and appends it. Safe to call from a scroll listener:
  /// re-entrant calls, "no more pages" and "the last page already failed" are
  /// all no-ops.
  ///
  /// The [BreakListState.loadMoreError] guard is what stops a request storm: a
  /// 429 or a timeout would otherwise be re-issued on every scroll tick,
  /// including the momentum of the fling that triggered it.
  Future<void> loadMore() async {
    final BreakListState? current = state.valueOrNull;
    if (current == null || _loadingMore || !current.canLoadMore) {
      return;
    }
    _loadingMore = true;
    state = AsyncValue<BreakListState>.data(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final CursorPage<BreakView> next = await ref
          .read(reconciliationRepositoryProvider)
          .listBreaks(cursor: current.page.nextCursor, filter: current.filter);
      final BreakListState? latest = state.valueOrNull;
      if (latest == null) {
        return;
      }
      state = AsyncValue<BreakListState>.data(
        latest.copyWith(
          page: latest.page.append(next),
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      // Deliberately NOT `on ApiError`: a BreakView whose amount the parser
      // rejects is not an ApiError at the throw site, and a narrower catch left
      // `isLoadingMore` published as true forever - a permanent spinner and a
      // permanently wedged pager.
      AppLogger.error(
        'Breaks page 2+ failed: '
        '${error is ApiError ? error.code : error.runtimeType}',
        scope: 'reconciliation',
        error: error,
        stackTrace: stackTrace,
      );
      final BreakListState? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue<BreakListState>.data(
          latest.copyWith(isLoadingMore: false, loadMoreError: error),
        );
      }
    } finally {
      _loadingMore = false;
    }
  }

  /// Clears the tail error and tries the next page again.
  ///
  /// The footer's "Try again" must go through here: [loadMore] alone would see
  /// the stale [BreakListState.loadMoreError] and refuse.
  Future<void> retryLoadMore() async {
    final BreakListState? current = state.valueOrNull;
    if (current == null || _loadingMore) {
      return;
    }
    if (current.loadMoreError != null) {
      state = AsyncValue<BreakListState>.data(
        current.copyWith(clearLoadMoreError: true),
      );
    }
    await loadMore();
  }

  /// Pull-to-refresh: back to page 1 under the current filter.
  Future<void> refresh() async {
    final BreakFilter filter = ref.read(breakFilterProvider);
    state = await AsyncValue.guard<BreakListState>(() async {
      final CursorPage<BreakView> page = await ref
          .read(reconciliationRepositoryProvider)
          .listBreaks(filter: filter);
      return BreakListState(page: page, filter: filter);
    });
  }

  /// Swaps one already-loaded row for the server's fresh copy, so acting on a
  /// break from its detail screen updates the list without a refetch.
  ///
  /// If the row no longer matches the active filter (e.g. it was just closed
  /// while the filter shows unresolved work only) it is dropped instead.
  void replaceBreak(BreakView updated) {
    final BreakListState? current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final bool stillMatches =
        current.filter.effectiveStatuses.contains(updated.status);
    final List<BreakView> next = <BreakView>[];
    bool found = false;
    for (final BreakView item in current.items) {
      if (item.id != updated.id) {
        next.add(item);
        continue;
      }
      found = true;
      if (stillMatches) {
        next.add(updated);
      }
    }
    if (!found) {
      return;
    }
    state = AsyncValue<BreakListState>.data(
      current.copyWith(
        page: CursorPage<BreakView>(
          items: List<BreakView>.unmodifiable(next),
          nextCursor: current.page.nextCursor,
          hasMore: current.page.hasMore,
          correlationId: current.page.correlationId,
        ),
      ),
    );
  }

  /// Drops a row that the server says is gone.
  void removeBreak(String id) {
    final BreakListState? current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final List<BreakView> next = <BreakView>[
      for (final BreakView item in current.items)
        if (item.id != id) item,
    ];
    if (next.length == current.items.length) {
      return;
    }
    state = AsyncValue<BreakListState>.data(
      current.copyWith(
        page: CursorPage<BreakView>(
          items: List<BreakView>.unmodifiable(next),
          nextCursor: current.page.nextCursor,
          hasMore: current.page.hasMore,
          correlationId: current.page.correlationId,
        ),
      ),
    );
  }
}

final AsyncNotifierProvider<BreakListController, BreakListState>
    breakListProvider =
    AsyncNotifierProvider<BreakListController, BreakListState>(
  BreakListController.new,
);
