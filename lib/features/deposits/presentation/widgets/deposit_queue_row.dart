import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_formatting.dart';

/// One row of the review queue.
///
/// Optimised for triage rather than completeness: reference, player, amount,
/// method, age, status and a risk indicator - everything a reviewer needs to
/// decide which receipt to open next.
class DepositQueueRow extends StatelessWidget {
  const DepositQueueRow({
    required this.deposit,
    required this.onTap,
    required this.now,
    super.key,
  });

  final AdminDepositView deposit;
  final VoidCallback onTap;

  /// Passed in so a whole list shares one clock and cannot show two different
  /// "now"s in the same frame.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final AppSemanticColors semantics = AppSemanticColors.of(context);
    final bool claimed = deposit.claimIsFresh(now);
    final int? claimMinutes = DepositActionPolicy.claimMinutesRemaining(
      deposit.reviewStartedAt,
      now,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        deposit.shortId,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFeatures: AppTheme.numericFeatures,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deposit.playerLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    MoneyText(deposit.claimed),
                    const SizedBox(height: 2),
                    StatusChip(
                      label: deposit.status.label(s),
                      tone: deposit.status.tone,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    deposit.destination?.methodName ?? s.unknownMethod,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (deposit.proofCount > 0) ...<Widget>[
                  Icon(
                    Icons.image_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${deposit.proofCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  DepositFormat.age(deposit.createdAt, s, now: now),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: AppTheme.numericFeatures,
                  ),
                ),
              ],
            ),
            if (claimed || deposit.hasRiskFlags) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (claimed)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: StatusChip(
                        label: claimMinutes == null
                            ? s.claimedChip
                            : s.claimedChipMinutes(minutes: claimMinutes),
                        tone: StatusTone.info,
                        icon: Icons.lock_clock,
                        dense: true,
                      ),
                    ),
                  if (deposit.hasRiskFlags)
                    Expanded(
                      child: _RiskSummary(
                        flags: deposit.riskFlags,
                        color: semantics.riskFlag,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The worst risk flag plus a count, so a dense row stays one line.
///
/// Flags are evidence for the human, never a verdict, and an empty list is
/// never proof of a clean deposit - so this only ever adds information.
class _RiskSummary extends StatelessWidget {
  const _RiskSummary({required this.flags, required this.color});

  final List<String> flags;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    // The list arrives sorted by severity, so the first entry is the worst.
    final String worst = RiskFlags.label(flags.first, s);
    final int extra = flags.length - 1;

    return Row(
      children: <Widget>[
        Icon(Icons.flag_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            extra > 0 ? s.riskMoreFlags(worst: worst, count: extra) : worst,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
