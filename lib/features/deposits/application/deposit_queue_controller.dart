import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_query.dart';
import 'package:manager_bot/features/deposits/data/deposit_repository.dart';

/// The filter the queue is currently showing.
///
/// Kept separate from the queue itself so changing a filter is a cheap, atomic
/// state change that the queue controller simply watches.
class DepositFilterController extends Notifier<DepositQueueFilter> {
  @override
  DepositQueueFilter build() => DepositQueueFilter.initial;

  /// Replaces the whole filter (what the filter sheet does on "Apply").
  void apply(DepositQueueFilter filter) {
    if (filter != state) {
      state = filter;
    }
  }

  void setSort(DepositSort sort) {
    if (sort != state.sort) {
      state = state.copyWith(sort: sort);
    }
  }

  /// Quick search from the app bar: an EXACT shortId match, since the backend
  /// has no substring or free-text search on this surface.
  void searchShortId(String? shortId) {
    final String? value = _blankToNull(shortId);
    state = value == null
        ? state.copyWith(clearShortId: true)
        : state.copyWith(shortId: value);
  }

  void searchExternalReference(String? reference) {
    final String? value = _blankToNull(reference);
    state = value == null
        ? state.copyWith(clearExternalReference: true)
        : state.copyWith(externalReference: value);
  }

  void reset() {
    if (state != DepositQueueFilter.initial) {
      state = DepositQueueFilter.initial;
    }
  }

  static String? _blankToNull(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// One page-set of the queue plus everything the list needs to render.
class DepositQueueState {
  const DepositQueueState({
    required this.items,
    required this.filter,
    required this.hasMore,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.refreshError,
    this.correlationId,
  });

  /// Rows loaded so far, oldest page first, in server order.
  final List<AdminDepositView> items;

  /// The filter these rows were fetched with.
  final DepositQueueFilter filter;

  /// Server-reported: another page exists.
  final bool hasMore;

  /// OPAQUE cursor for the next page. Null == exhausted.
  final String? nextCursor;

  final bool isLoadingMore;

  /// Failure of the LAST "load more", shown inline in the list footer so the
  /// rows already on screen are never thrown away.
  final Object? loadMoreError;

  /// Failure of the last pull-to-refresh, for a snackbar. The stale rows stay.
  final Object? refreshError;

  final String? correlationId;

  bool get isEmpty => items.isEmpty;

  /// Amount sorts cannot be keyset-paged: the server's cursor carries only
  /// `createdAt + id`, so echoing `nextCursor` back returns THE SAME FIRST PAGE
  /// forever. Paging is therefore refused rather than looping.
  bool get pagingBlockedBySort => hasMore && !filter.sort.isPageable;

  bool get canLoadMore =>
      hasMore &&
      nextCursor != null &&
      filter.sort.isPageable &&
      !isLoadingMore &&
      loadMoreError == null;

  DepositQueueState copyWith({
    List<AdminDepositView>? items,
    DepositQueueFilter? filter,
    bool? hasMore,
    String? nextCursor,
    bool? isLoadingMore,
    Object? loadMoreError,
    Object? refreshError,
    String? correlationId,
    bool clearNextCursor = false,
    bool clearLoadMoreError = false,
    bool clearRefreshError = false,
  }) =>
      DepositQueueState(
        items: items ?? this.items,
        filter: filter ?? this.filter,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError:
            clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
        refreshError:
            clearRefreshError ? null : (refreshError ?? this.refreshError),
        correlationId: correlationId ?? this.correlationId,
      );
}

/// The deposit review queue.
///
/// Cursor-paginated, append-only in memory, and never optimistic: rows are only
/// ever replaced with something the server returned.
class DepositQueueController extends AsyncNotifier<DepositQueueState> {
  /// Page size. Deliberately below the 100 maximum: the queue endpoint issues
  /// one risk-flag query PER ROW (N+1), so a large page is a slow page.
  static const int pageSize = 25;

  @override
  Future<DepositQueueState> build() async {
    final DepositQueueFilter filter = ref.watch(depositFilterProvider);
    final CursorPage<AdminDepositView> page = await ref
        .read(depositRepositoryProvider)
        .queue(filter: filter, limit: pageSize);

    return DepositQueueState(
      items: List<AdminDepositView>.unmodifiable(page.items),
      filter: filter,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
      correlationId: page.correlationId,
    );
  }

  /// Appends the next page. A no-op unless [DepositQueueState.canLoadMore].
  Future<void> loadMore() async {
    final DepositQueueState? current = state.valueOrNull;
    if (current == null || !current.canLoadMore) {
      return;
    }

    state = AsyncData<DepositQueueState>(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final CursorPage<AdminDepositView> page =
          await ref.read(depositRepositoryProvider).queue(
                filter: current.filter,
                cursor: current.nextCursor,
                limit: pageSize,
              );

      final DepositQueueState? latest = state.valueOrNull;
      if (latest == null || latest.filter != current.filter) {
        // The filter changed while the page was in flight; build() has already
        // produced a fresh first page, so this one is stale.
        return;
      }

      state = AsyncData<DepositQueueState>(
        latest.copyWith(
          items: _appendDistinct(latest.items, page.items),
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
          correlationId: page.correlationId,
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.warn('Loading the next deposit page failed: $error',
          scope: 'deposits');
      final DepositQueueState? latest = state.valueOrNull;
      if (latest == null) {
        state = AsyncError<DepositQueueState>(error, stackTrace);
        return;
      }
      state = AsyncData<DepositQueueState>(
        latest.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  /// Re-reads page 1, keeping the current rows on screen while it runs.
  ///
  /// A failure never blanks the list: the stale rows stay and the error is
  /// surfaced through [DepositQueueState.refreshError].
  Future<void> refresh() async {
    final DepositQueueState? current = state.valueOrNull;
    final DepositQueueFilter filter = current?.filter ?? ref.read(depositFilterProvider);

    try {
      final CursorPage<AdminDepositView> page = await ref
          .read(depositRepositoryProvider)
          .queue(filter: filter, limit: pageSize);

      state = AsyncData<DepositQueueState>(
        DepositQueueState(
          items: List<AdminDepositView>.unmodifiable(page.items),
          filter: filter,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
          correlationId: page.correlationId,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (current == null) {
        state = AsyncError<DepositQueueState>(error, stackTrace);
        return;
      }
      state = AsyncData<DepositQueueState>(
        current.copyWith(refreshError: error, clearLoadMoreError: true),
      );
    }
  }

  void acknowledgeRefreshError() {
    final DepositQueueState? current = state.valueOrNull;
    if (current?.refreshError == null) {
      return;
    }
    state = AsyncData<DepositQueueState>(current!.copyWith(clearRefreshError: true));
  }

  /// Clears a "load more" failure so the footer offers the retry again.
  void retryLoadMore() {
    final DepositQueueState? current = state.valueOrNull;
    if (current == null || current.loadMoreError == null) {
      return;
    }
    state = AsyncData<DepositQueueState>(current.copyWith(clearLoadMoreError: true));
  }

  /// Reconciles one row against a deposit the server just returned.
  ///
  /// This is NOT an optimistic update: [deposit] is always a freshly fetched
  /// `AdminDepositView`. When the refreshed row no longer satisfies the active
  /// filter (the usual case after approving or rejecting - it leaves the
  /// reviewable set) it is removed, mirroring what a refetch would show.
  void reconcile(AdminDepositView deposit) {
    final DepositQueueState? current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final int index = _indexOf(current.items, deposit.id);
    final bool matches = _matchesFilter(deposit, current.filter);

    if (index < 0) {
      if (!matches) {
        return;
      }
      // A row we did not have but that now belongs here (e.g. released back to
      // the queue): let the next refresh place it in server order rather than
      // guessing a position.
      return;
    }

    final List<AdminDepositView> next =
        List<AdminDepositView>.of(current.items);
    if (matches) {
      next[index] = deposit;
    } else {
      next.removeAt(index);
    }

    state = AsyncData<DepositQueueState>(
      current.copyWith(items: List<AdminDepositView>.unmodifiable(next)),
    );
  }

  /// The row for [shortId] already in memory, or null. Lets the detail screen
  /// skip a lookup round trip when the admin tapped through from the queue.
  AdminDepositView? findLoadedByShortId(String shortId) {
    final DepositQueueState? current = state.valueOrNull;
    if (current == null) {
      return null;
    }
    final String normalized = shortId.trim().toUpperCase();
    for (final AdminDepositView deposit in current.items) {
      if (deposit.shortId.toUpperCase() == normalized) {
        return deposit;
      }
    }
    return null;
  }

  /// The statuses the server is actually filtering on: an empty client filter
  /// means the server default of the three reviewable statuses.
  static Set<DepositStatus> effectiveStatuses(DepositQueueFilter filter) =>
      filter.statuses.isEmpty ? DepositStatus.reviewable : filter.statuses;

  /// Whether a refreshed row still belongs in the list.
  ///
  /// Only the two filters an admin ACTION can change are re-evaluated (status
  /// and the unclaimed flag). Amount and date filters cannot change under a
  /// review action, so they are not re-checked.
  static bool _matchesFilter(
    AdminDepositView deposit,
    DepositQueueFilter filter,
  ) {
    if (!effectiveStatuses(filter).contains(deposit.status)) {
      return false;
    }
    if (filter.unclaimedOnly && deposit.reviewStartedAt != null) {
      return false;
    }
    return true;
  }

  static int _indexOf(List<AdminDepositView> items, String id) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == id) {
        return i;
      }
    }
    return -1;
  }

  /// Appends [addition] skipping ids already present, so a row that straddles a
  /// page boundary cannot appear twice.
  static List<AdminDepositView> _appendDistinct(
    List<AdminDepositView> existing,
    List<AdminDepositView> addition,
  ) {
    final Set<String> seen = <String>{
      for (final AdminDepositView deposit in existing) deposit.id,
    };
    final List<AdminDepositView> merged =
        List<AdminDepositView>.of(existing);
    for (final AdminDepositView deposit in addition) {
      if (seen.add(deposit.id)) {
        merged.add(deposit);
      }
    }
    return List<AdminDepositView>.unmodifiable(merged);
  }
}

/// The filter the queue screen reads and the filter sheet writes.
final NotifierProvider<DepositFilterController, DepositQueueFilter>
    depositFilterProvider =
    NotifierProvider<DepositFilterController, DepositQueueFilter>(
  DepositFilterController.new,
);

/// The queue itself. Re-runs whenever [depositFilterProvider] changes.
final AsyncNotifierProvider<DepositQueueController, DepositQueueState>
    depositQueueProvider =
    AsyncNotifierProvider<DepositQueueController, DepositQueueState>(
  DepositQueueController.new,
);
