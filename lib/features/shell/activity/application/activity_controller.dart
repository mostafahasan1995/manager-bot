import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/features/shell/activity/data/activity_demo_data.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';

/// THE SEAM. Everything below reads the history through this provider, so
/// pointing إيداعاتي at the real, token-authenticated backend is one override.
final Provider<ActivityRepository> activityRepositoryProvider =
    Provider<ActivityRepository>(
  (ref) => ActivityDemoRepository(),
);

/// The chip the player has selected. Kept apart from the feed so tapping a chip
/// is one cheap, atomic state change that the feed simply watches.
class ActivityFilterController extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() => ActivityFilter.all;

  /// Selects [filter]. A no-op when it is already selected, so the feed does
  /// not reload on a double tap.
  void select(ActivityFilter filter) {
    if (filter != state) {
      state = filter;
    }
  }

  void reset() => select(ActivityFilter.all);
}

/// Which row's detail sheet is open, by `shortId`.
///
/// The list uses it to keep the tapped row lit while the sheet covers it, so
/// dismissing the sheet never leaves the player wondering what they opened.
class ActivitySelectionController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String shortId) {
    if (state != shortId) {
      state = shortId;
    }
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

/// Everything the list needs in one immutable value.
class ActivityFeedState {
  const ActivityFeedState({
    required this.items,
    required this.filter,
    required this.hasMore,
    required this.total,
    required this.summary,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// Rows loaded so far, newest first.
  final List<ActivityDeposit> items;

  /// The filter these rows were loaded under.
  final ActivityFilter filter;

  /// Another page exists behind the ones loaded.
  final bool hasMore;

  /// How many rows match [filter] in total.
  final int total;

  /// Totals over the WHOLE history, unaffected by [filter] or by paging.
  final ActivitySummary summary;

  /// A page request is in flight right now.
  final bool isLoadingMore;

  /// The last "load more" failure, kept so the footer can offer a retry
  /// without blanking the rows already on screen.
  final Object? loadMoreError;

  /// True when another page can be asked for right now.
  bool get canLoadMore => hasMore && !isLoadingMore && loadMoreError == null;

  /// True when the filter matched nothing at all.
  bool get isEmpty => items.isEmpty;

  ActivityFeedState copyWith({
    List<ActivityDeposit>? items,
    bool? hasMore,
    int? total,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) =>
      ActivityFeedState(
        items: items ?? this.items,
        filter: filter,
        hasMore: hasMore ?? this.hasMore,
        total: total ?? this.total,
        summary: summary,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError:
            clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      );
}

/// The feed. Reloads from scratch whenever [activityFilterProvider] changes,
/// and appends a page at a time as the player scrolls.
class ActivityFeedController extends AsyncNotifier<ActivityFeedState> {
  /// Deliberately small: the demo history is short and the infinite-scroll
  /// behaviour has to be visible, not theoretical.
  static const int pageSize = 6;

  @override
  Future<ActivityFeedState> build() async {
    final ActivityFilter filter = ref.watch(activityFilterProvider);
    final ActivityRepository repository = ref.read(activityRepositoryProvider);
    final ActivityPage page = await repository.page(
      filter: filter,
      offset: 0,
      limit: pageSize,
    );
    final ActivitySummary summary = await repository.summary();
    return ActivityFeedState(
      items: List<ActivityDeposit>.unmodifiable(page.items),
      filter: filter,
      hasMore: page.hasMore,
      total: page.total,
      summary: summary,
    );
  }

  /// Fire-and-forget entry point for the scroll listener, so the widget layer
  /// never has to hold a `Future`.
  void loadMore() {
    final ActivityFeedState? current = state.valueOrNull;
    if (current == null || !current.canLoadMore) {
      return;
    }
    unawaited(_loadMore(current));
  }

  /// Clears a page failure so the footer offers the retry again.
  void retryLoadMore() {
    final ActivityFeedState? current = state.valueOrNull;
    if (current == null || current.loadMoreError == null) {
      return;
    }
    state = AsyncData<ActivityFeedState>(
      current.copyWith(clearLoadMoreError: true),
    );
    loadMore();
  }

  /// Pull-to-refresh. Re-reads page 1 and the totals from scratch.
  Future<void> refresh() async {
    final ActivityFilter filter = ref.read(activityFilterProvider);
    final ActivityRepository repository = ref.read(activityRepositoryProvider);
    try {
      final ActivityPage page = await repository.page(
        filter: filter,
        offset: 0,
        limit: pageSize,
      );
      final ActivitySummary summary = await repository.summary();
      state = AsyncData<ActivityFeedState>(
        ActivityFeedState(
          items: List<ActivityDeposit>.unmodifiable(page.items),
          filter: filter,
          hasMore: page.hasMore,
          total: page.total,
          summary: summary,
        ),
      );
    } on Object catch (error, stackTrace) {
      final ActivityFeedState? current = state.valueOrNull;
      if (current == null) {
        state = AsyncError<ActivityFeedState>(error, stackTrace);
        return;
      }
      state = AsyncData<ActivityFeedState>(
        current.copyWith(loadMoreError: error, isLoadingMore: false),
      );
    }
  }

  Future<void> _loadMore(ActivityFeedState current) async {
    state = AsyncData<ActivityFeedState>(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final ActivityPage page =
          await ref.read(activityRepositoryProvider).page(
                filter: current.filter,
                offset: current.items.length,
                limit: pageSize,
              );
      final ActivityFeedState? latest = state.valueOrNull;
      if (latest == null || latest.filter != current.filter) {
        // The chip changed while the page was in flight; build() has already
        // produced a fresh first page, so this one is stale.
        return;
      }
      state = AsyncData<ActivityFeedState>(
        latest.copyWith(
          items: _appendDistinct(latest.items, page.items),
          hasMore: page.hasMore,
          total: page.total,
          isLoadingMore: false,
        ),
      );
    } on Object catch (error, stackTrace) {
      final ActivityFeedState? latest = state.valueOrNull;
      if (latest == null) {
        state = AsyncError<ActivityFeedState>(error, stackTrace);
        return;
      }
      state = AsyncData<ActivityFeedState>(
        latest.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  /// Appends by `shortId`, so a row that straddles a page boundary cannot show
  /// up twice.
  static List<ActivityDeposit> _appendDistinct(
    List<ActivityDeposit> existing,
    List<ActivityDeposit> addition,
  ) {
    final Set<String> seen = <String>{
      for (final ActivityDeposit row in existing) row.shortId,
    };
    final List<ActivityDeposit> merged = List<ActivityDeposit>.of(existing);
    for (final ActivityDeposit row in addition) {
      if (seen.add(row.shortId)) {
        merged.add(row);
      }
    }
    return List<ActivityDeposit>.unmodifiable(merged);
  }
}

/// The selected chip.
final NotifierProvider<ActivityFilterController, ActivityFilter>
    activityFilterProvider =
    NotifierProvider<ActivityFilterController, ActivityFilter>(
  ActivityFilterController.new,
);

/// The `shortId` whose detail sheet is open, or null.
final NotifierProvider<ActivitySelectionController, String?>
    activitySelectionProvider =
    NotifierProvider<ActivitySelectionController, String?>(
  ActivitySelectionController.new,
);

/// The paged history itself.
final AsyncNotifierProvider<ActivityFeedController, ActivityFeedState>
    activityFeedProvider =
    AsyncNotifierProvider<ActivityFeedController, ActivityFeedState>(
  ActivityFeedController.new,
);
