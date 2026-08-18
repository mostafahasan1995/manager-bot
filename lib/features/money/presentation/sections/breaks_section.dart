import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/break_list_controller.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/break_detail_screen.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_list_tile.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/router/app_router.dart';

/// Unresolved reconciliation breaks, worst first.
///
/// The list itself is [breakListProvider] - the same cursor-paged controller the
/// workbench uses, under the same filter, so a break closed there disappears
/// here without a refetch. Only the first [previewCount] rows are shown: this is
/// a health summary, not the queue. The header link hands over to the full
/// workbench, which owns filtering, paging and NEEDS_RECONCILIATION triage.
///
/// Ordering is deliberately NOT the server's (newest first): on a summary the
/// question is "what is worst", so rows are re-sorted by severity and, within a
/// severity, oldest first - the one that has been bleeding longest.
class BreaksSection extends ConsumerWidget {
  const BreaksSection({super.key});

  /// How many rows a summary is allowed to show before it stops being one.
  static const int previewCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AsyncValue<BreakListState> value = ref.watch(breakListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          title: s.tabBreaks,
          actionLabel: s.reconciliationTitle,
          onAction: () => context.goNamed(AppRoute.reconciliation),
        ),
        const SizedBox(height: 8),
        value.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: LoadingStateView(label: s.loadingBreaks),
          ),
          error: (Object error, StackTrace stackTrace) => ErrorStateView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(breakListProvider),
          ),
          data: (BreakListState state) => state.isEmpty
              ? EmptyStateView(
                  title: s.emptyBreaksTitle,
                  message: s.emptyBreaksMessage,
                  icon: Icons.verified_outlined,
                )
              : _BreaksSummary(state: state),
        ),
      ],
    );
  }
}

class _BreaksSummary extends StatelessWidget {
  const _BreaksSummary({required this.state});

  final BreakListState state;

  /// Unresolved rows, severest first, then oldest first within a severity.
  static List<BreakView> worstFirst(List<BreakView> items) {
    final List<BreakView> open = <BreakView>[
      for (final BreakView item in items)
        if (!item.status.isTerminal) item,
    ];
    open.sort((BreakView a, BreakView b) {
      final int bySeverity = b.severity.compareTo(a.severity);
      if (bySeverity != 0) {
        return bySeverity;
      }
      return a.detectedAt.compareTo(b.detectedAt);
    });
    return open;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final int attention = state.attentionCount;
    final List<BreakView> preview = worstFirst(state.items)
        .take(BreaksSection.previewCount)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (state.hasOutstandingDrift) ...<Widget>[
          NoticeStrip(message: s.outstandingDriftNotice, tone: StatusTone.failed),
          const SizedBox(height: 10),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: MetricTile(
                label: s.metricLoaded,
                value: Text(
                  '${state.items.length}',
                  style: AppTheme.moneyStyle(context, fontSize: 18),
                ),
                caption:
                    state.hasMore ? s.captionMoreAvailable : s.captionAllOfThem,
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
        const SizedBox(height: 6),
        for (final BreakView item in preview)
          BreakListTile(
            breakView: item,
            onTap: () => unawaited(BreakDetailScreen.open(context, item.id)),
          ),
      ],
    );
  }
}

/// Section title plus the one link out of it.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
