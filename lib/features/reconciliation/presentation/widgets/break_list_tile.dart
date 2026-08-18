import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_formats.dart';

/// One row of the breaks list.
///
/// The delta is the headline, signed and unrounded, because that is the number
/// an admin is triaging on. Severity and status ride beside it; the id is
/// shortened but the full one is on the detail screen.
class BreakListTile extends StatelessWidget {
  const BreakListTile({
    required this.breakView,
    required this.onTap,
    super.key,
  });

  final BreakView breakView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final AppSemanticColors semantics = AppSemanticColors.of(context);
    final Money? delta = breakView.delta;
    final bool attention = breakView.needsAttention;
    final BigInt? actualCount = breakView.actualCount;
    final BigInt? expectedCount = breakView.expectedCount;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          // Directional: the severity stripe rides the READING edge, so it is
          // on the right in Arabic.
          border: BorderDirectional(
            start: BorderSide(
              width: 3,
              color: attention
                  ? semantics.tone(BreakSeverity.tone(breakView.severity)).foreground
                  : Colors.transparent,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    breakView.category == BreakCategory.unknown
                        ? breakView.categoryWire
                        : breakView.category.label(s),
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: breakView.status == BreakStatus.unknown
                      ? breakView.statusWire
                      : breakView.status.label(s),
                  tone: breakView.status.tone,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: breakView.amountsAreEntryCounts
                      ? Text(
                          actualCount == null || expectedCount == null
                              ? s.emptyValueDash
                              : s.tileEntriesOfEntries(
                                  actual: actualCount.toInt(),
                                  expected: expectedCount.toInt(),
                                ),
                          style: AppTheme.moneyStyle(context, fontSize: 16),
                        )
                      : MoneyText(
                          delta,
                          alwaysShowSign: true,
                          colorBySign: true,
                          style: AppTheme.moneyStyle(context, fontSize: 16),
                          placeholder: s.moneyNoDifferenceRecorded,
                        ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: BreakSeverity.shortLabel(breakView.severity, s),
                  tone: BreakSeverity.tone(breakView.severity),
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    ReconciliationFormats.since(breakView.detectedAt, s),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (breakView.isAssigned)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Icon(
                      Icons.person_outline,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (breakView.touchesDeposit)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 15,
                      color: semantics.riskFlag,
                    ),
                  ),
                Text(breakView.shortId, style: AppTheme.monoStyle(context)),
              ],
            ),
            if (breakView.isReopenedAfterClosure) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                s.tileReopenedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantics.pending.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
