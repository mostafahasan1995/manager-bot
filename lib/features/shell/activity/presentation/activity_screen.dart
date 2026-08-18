import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/activity/application/activity_controller.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';
import 'package:manager_bot/features/shell/activity/presentation/widgets/activity_detail_sheet.dart';
import 'package:manager_bot/features/shell/activity/presentation/widgets/activity_filter_bar.dart';
import 'package:manager_bot/features/shell/activity/presentation/widgets/activity_row_card.dart';
import 'package:manager_bot/features/shell/activity/presentation/widgets/activity_skeleton.dart';

/// إيداعاتي - the player's deposit history, destination 2 of 5.
///
/// The shell mounts this directly; it owns no app bar and no bottom bar, and
/// its scroll body clears the raised centre action through
/// `AppSpacing.pagePadding`.
///
/// Layout, top to bottom:
/// 1. a fixed header - the wordmark and "N of M loaded";
/// 2. a fixed chip rail, so the filter is always one tap away no matter how
///    far the list has been scrolled;
/// 3. the scrolling feed: a totals block, then the rows, then a footer that
///    pages, retries or says the list has ended.
///
/// Loading, empty and error are all rendered from the same `AsyncValue`, and
/// every branch is a scrollable so pull-to-refresh works even when there is
/// nothing on screen.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({this.onStartTopUp, super.key});

  /// Hands the player over to the raised centre action. When null the empty
  /// state simply drops its button.
  final VoidCallback? onStartTopUp;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// Infinite scroll: ask for the next page a little before the bottom, so the
  /// footer skeleton is already there when the player gets to it.
  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final ScrollPosition position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      ref.read(activityFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _open(ActivityDeposit deposit) async {
    ref.read(activitySelectionProvider.notifier).select(deposit.shortId);
    await showActivityDetailSheet(context, deposit);
    if (!mounted) {
      return;
    }
    ref.read(activitySelectionProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final AsyncValue<ActivityFeedState> feed = ref.watch(activityFeedProvider);
    final String? selected = ref.watch(activitySelectionProvider);

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: GradientText(
                      s.activityTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _LoadedCount(feed: feed),
                ],
              ),
            ),
            const ActivityFilterBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppPalette.accentCyan,
                backgroundColor: AppPalette.surface2,
                onRefresh: () async {
                  await ref.read(activityFeedProvider.notifier).refresh();
                },
                child: feed.when(
                  loading: () => const ActivitySkeletonList(),
                  error: (Object error, StackTrace stackTrace) =>
                      _centred(ErrorState(
                    title: s.activityErrorTitle,
                    message: s.activityErrorMessage,
                    retryLabel: s.retry,
                    details: error is ActivityUnavailable ? error.reason : null,
                    onRetry: () {
                      ref.invalidate(activityFeedProvider);
                    },
                  )),
                  data: (ActivityFeedState state) => _feed(s, state, selected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keeps a non-list state scrollable, so pull-to-refresh still works.
  Widget _centred(Widget child) => ListView(
        padding: AppSpacing.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: AppSpacing.xxl),
          child,
        ],
      );

  Widget _feed(AppStrings s, ActivityFeedState state, String? selected) {
    if (state.isEmpty) {
      return _centred(
        state.filter == ActivityFilter.all
            ? EmptyState(
                title: s.activityEmptyTitle,
                message: s.activityEmptyMessage,
                icon: Icons.receipt_long_rounded,
                tone: AppTone.info,
                actionLabel: widget.onStartTopUp == null
                    ? null
                    : s.activityStartTopUpAction,
                onAction: widget.onStartTopUp,
              )
            : EmptyState(
                title: s.activityFilterEmptyTitle,
                message: s.activityFilterEmptyMessage,
                icon: Icons.filter_alt_off_rounded,
                actionLabel: s.activityShowAllAction,
                onAction: () {
                  ref.read(activityFilterProvider.notifier).reset();
                },
              ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      itemCount: state.items.length + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return AppEntrance(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: _SummaryBlock(summary: state.summary),
            ),
          );
        }
        if (index <= state.items.length) {
          final ActivityDeposit deposit = state.items[index - 1];
          return AppEntrance(
            index: index,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: ActivityRowCard(
                deposit: deposit,
                selected: deposit.shortId == selected,
                onTap: () => unawaited(_open(deposit)),
              ),
            ),
          );
        }
        return _Footer(
          state: state,
          onRetry: () {
            ref.read(activityFeedProvider.notifier).retryLoadMore();
          },
          onLoadMore: () {
            ref.read(activityFeedProvider.notifier).loadMore();
          },
        );
      },
    );
  }
}

/// "N of M" beside the wordmark. Silent while the first page is loading.
class _LoadedCount extends StatelessWidget {
  const _LoadedCount({required this.feed});

  final AsyncValue<ActivityFeedState> feed;

  @override
  Widget build(BuildContext context) {
    final ActivityFeedState? state = feed.valueOrNull;
    if (state == null || state.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      context.s.activityShowingCount(
        shown: state.items.length,
        total: state.total,
      ),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppPalette.textTertiary,
            fontFeatures: NeonFonts.numericFeatures,
          ),
    );
  }
}

/// The totals block at the head of the feed: everything that has ever landed,
/// and how much is still moving. Computed over the whole history, so scrolling
/// never changes it.
class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool hasOpen = summary.openCount > 0;
    return GlowCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  s.activitySummaryCreditedLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppPalette.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AmountText(
                  summary.totalCredited,
                  fontSize: 26,
                  tone: AppTone.credited,
                  height: 1.15,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasOpen
                      ? s.activityInProgressCount(count: summary.openCount)
                      : s.activitySummaryAllSettled,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasOpen
                        ? AppPalette.tone(AppTone.pending).foreground
                        : AppPalette.textTertiary,
                    fontFeatures: NeonFonts.numericFeatures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AvatarRing(
            icon: Icons.history_rounded,
            size: 54,
            gradient: AppPalette.gradientHot,
            badge: hasOpen ? CountBadge(count: summary.openCount) : null,
          ),
        ],
      ),
    );
  }
}

/// The end of the list: a page skeleton, a retry, a manual "load more" or the
/// full stop.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
  });

  final ActivityFeedState state;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    if (state.loadMoreError != null) {
      return ErrorState(
        title: s.errorTitleSomethingWentWrong,
        message: s.activityErrorMessage,
        retryLabel: s.retry,
        onRetry: onRetry,
        compact: true,
      );
    }
    if (state.isLoadingMore) {
      return const AppCard(child: ShimmerRow(padding: EdgeInsets.zero));
    }
    if (state.hasMore) {
      return AppButton(
        label: s.loadMore,
        variant: AppButtonVariant.tonal,
        expand: true,
        onPressed: onLoadMore,
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text(
          s.endOfList,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.textDisabled,
              ),
        ),
      ),
    );
  }
}
