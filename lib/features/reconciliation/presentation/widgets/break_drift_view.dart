import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';

/// The three numbers that define a break: ours, theirs, and the difference.
///
/// Two rules are enforced here and nowhere else:
///
/// 1. Nothing is rounded and nothing is `abs()`-ed. The delta keeps its sign
///    because "they hold 500 more than us" and "we hold 500 more than them" are
///    different problems.
/// 2. When the break came from an `I1_SINGLE_SIDED` invariant, the three fields
///    are ENTRY COUNTS, not money - the backend still formats the count `2` as
///    `0.02`. In that case the raw counts are shown and the currency is not.
class BreakDriftView extends StatelessWidget {
  const BreakDriftView({required this.breakView, this.dense = false, super.key});

  final BreakView breakView;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    if (breakView.expected == null &&
        breakView.actual == null &&
        breakView.delta == null) {
      return Text(
        s.noExpectedActualPair,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (breakView.amountsAreEntryCounts) {
      return _EntryCountDrift(breakView: breakView);
    }

    final Money? delta = breakView.delta;
    final StatusTone deltaTone = delta == null || delta.isZero
        ? StatusTone.neutral
        : StatusTone.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: MetricTile(
                label: s.metricLedgerExpected,
                value: MoneyText(
                  breakView.expected,
                  style: AppTheme.moneyStyle(context, fontSize: dense ? 15 : 17),
                ),
                caption: s.captionOurBooks,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: s.metricObservedActual,
                value: MoneyText(
                  breakView.actual,
                  style: AppTheme.moneyStyle(context, fontSize: dense ? 15 : 17),
                ),
                caption: s.captionTheOtherSide,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        MetricTile(
          label: s.metricDifferenceActualExpected,
          tone: deltaTone,
          value: MoneyText(
            delta,
            alwaysShowSign: true,
            colorBySign: true,
            emphasise: !dense,
          ),
          caption: _deltaCaption(delta, s),
        ),
      ],
    );
  }

  static String _deltaCaption(Money? delta, AppStrings s) {
    if (delta == null) {
      return s.deltaCaptionOneSideMissing;
    }
    if (delta.isZero) {
      return s.deltaCaptionNoDifference;
    }
    return delta.isPositive
        ? s.deltaCaptionOtherSideMore
        : s.deltaCaptionOurBooksMore;
  }
}

/// The `I1_SINGLE_SIDED` case: counts of ledger entries, not amounts.
class _EntryCountDrift extends StatelessWidget {
  const _EntryCountDrift({required this.breakView});

  final BreakView breakView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final BigInt? expected = breakView.expectedCount;
    final BigInt? actual = breakView.actualCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NoticeStrip(
          message: s.entryCountsDriftNotice,
          tone: StatusTone.info,
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: MetricTile(
                label: s.metricEntriesRequired,
                value: Text(
                  expected?.toString() ?? s.emptyValueDash,
                  style: AppTheme.moneyStyle(context, fontSize: 17),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: s.metricEntriesFound,
                tone: StatusTone.reject,
                value: Text(
                  actual?.toString() ?? s.emptyValueDash,
                  style: AppTheme.moneyStyle(context, fontSize: 17),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.entryCountsRawExplain(currency: breakView.currencyCode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
