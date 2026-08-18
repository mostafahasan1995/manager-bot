/// One rich row of "آخر العمليات".
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';
import 'package:manager_bot/features/shell/home/presentation/home_labels.dart';

/// A deposit as the PLAYER sees it: the rail they paid over, the exact amount,
/// the reference the bot quoted them, and where it stands.
///
/// Two lines rather than one wide row on purpose - at 360dp an amount, a status
/// chip and a rail name do not fit side by side without the amount shrinking,
/// and the amount is the one thing that must never shrink.
class HomeDepositCard extends StatelessWidget {
  const HomeDepositCard({required this.deposit, this.onTap, super.key});

  final HomeDeposit deposit;

  /// Opens the deposit. Null leaves the card inert (no session yet).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarRing(
                icon: HomeLabels.depositIcon(deposit.status),
                size: 42,
                gradient: HomeLabels.depositGradient(deposit.status),
                ringWidth: 2,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  deposit.methodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // The most readable thing in the row, always.
              AmountText(deposit.amount, fontSize: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.headlineCreatedAgo(
                    shortId: deposit.shortId,
                    age: HomeAgeFormat.compact(s, deposit.age),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.textTertiary,
                    fontFeatures: NeonFonts.numericFeatures,
                    fontFamilyFallback: NeonFonts.arabicFallback,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: HomeLabels.depositStatus(s, deposit.status),
                tone: HomeLabels.depositTone(deposit.status),
                dense: true,
                // Four chips can share one viewport here; a bloom each is not
                // free on a budget Android phone.
                glow: false,
              ),
              const ForwardChevron(size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
