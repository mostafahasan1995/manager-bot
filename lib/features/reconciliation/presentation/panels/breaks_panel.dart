import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/break_filter_controller.dart';
import 'package:manager_bot/features/reconciliation/application/break_list_controller.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/break_detail_screen.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_filter_bar.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_list_tile.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';

/// The breaks queue: filter bar, drift summary, cursor-paged list.
class BreaksPanel extends ConsumerWidget {
  const BreaksPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AsyncValue<BreakListState> value = ref.watch(breakListProvider);

    return Column(
      children: <Widget>[
        const BreakFilterBar(),
        const Divider(height: 1),
        Expanded(
          child: AsyncValueView<BreakListState>(
            value: value,
            onRetry: () => ref.invalidate(breakListProvider),
            isEmpty: (BreakListState state) => state.isEmpty,
            emptyTitle: s.emptyBreaksTitle,
            emptyMessage: s.emptyBreaksMessage,
            emptyIcon: Icons.verified_outlined,
            loadingLabel: s.loadingBreaks,
            emptyAction: OutlinedButton.icon(
              onPressed: () => ref.read(breakFilterProvider.notifier).clear(),
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(s.resetFilterAction),
            ),
            builder: (BuildContext context, BreakListState state) =>
                _BreakList(state: state),
          ),
        ),
      ],
    );
  }
}

class _BreakList extends ConsumerWidget {
  const _BreakList({required this.state});

  final BreakListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BreakListController controller = ref.read(breakListProvider.notifier);
    final List<BreakView> items = state.items;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          final ScrollMetrics metrics = notification.metrics;
          // `canLoadMore` includes `loadMoreError == null`: once a page has
          // failed, only the footer's explicit "Try again" may re-issue it.
          // Without that, a 429 is made strictly worse by the same fling.
          if (metrics.axis == Axis.vertical &&
              metrics.pixels >= metrics.maxScrollExtent - 320 &&
              state.canLoadMore) {
            unawaited(controller.loadMore());
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 2,
          separatorBuilder: (BuildContext context, int index) =>
              index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _BreakListSummary(state: state);
            }
            if (index <= items.length) {
              final BreakView item = items[index - 1];
              return BreakListTile(
                breakView: item,
                onTap: () =>
                    unawaited(BreakDetailScreen.open(context, item.id)),
              );
            }
            return _BreakListFooter(state: state);
          },
        ),
      ),
    );
  }
}

/// The "why you are here" strip: how much of the visible queue is bleeding.
class _BreakListSummary extends StatelessWidget {
  const _BreakListSummary({required this.state});

  final BreakListState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final int total = state.items.length;
    final int attention = state.attentionCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (state.hasOutstandingDrift)
            NoticeStrip(
              message: s.outstandingDriftNotice,
              tone: StatusTone.failed,
            ),
          if (state.hasOutstandingDrift) const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: s.metricLoaded,
                  value: Text(
                    '$total',
                    style: AppTheme.moneyStyle(context, fontSize: 18),
                  ),
                  caption: state.hasMore
                      ? s.captionMoreAvailable
                      : s.captionAllOfThem,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: s.metricNeedAttention,
                  tone: attention > 0 ? StatusTone.failed : StatusTone.approve,
                  value: Text(
                    '$attention',
                    style: AppTheme.moneyStyle(context, fontSize: 18),
                  ),
                  caption: attention > 0
                      ? s.captionSevereOrDrifting
                      : s.captionNothingUrgent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.breaksSortHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tail of the list: paging spinner, a page-2 failure, or the end marker.
class _BreakListFooter extends ConsumerWidget {
  const _BreakListFooter({required this.state});

  final BreakListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: LoadingStateView(label: s.loadingMore),
      );
    }

    final Object? error = state.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorStateView(
          error: error,
          compact: true,
          onRetry: () =>
              unawaited(ref.read(breakListProvider.notifier).retryLoadMore()),
        ),
      );
    }

    if (state.hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: OutlinedButton(
          onPressed: () =>
              unawaited(ref.read(breakListProvider.notifier).loadMore()),
          child: Text(s.loadMore),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Text(
        s.endOfList,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
