import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';
import 'package:manager_bot/features/shell/activity/presentation/activity_presentation.dart';

/// One deposit in the history.
///
/// Reading order, top to bottom: the AMOUNT (largest, brightest thing in the
/// row - this is a money app), the status, the rail it went out on, then the
/// quiet technical pair of request number and relative age. The leading ring
/// carries the status colour so the list can be skimmed on colour alone, and
/// the chevron mirrors itself under Arabic.
class ActivityRowCard extends StatelessWidget {
  const ActivityRowCard({
    required this.deposit,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final ActivityDeposit deposit;

  /// Opens the detail sheet.
  final VoidCallback onTap;

  /// True while this row's sheet is open, so the player can see what they
  /// tapped once the sheet is dismissed.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final AppTone tone = ActivityStatusStyle.tone(deposit.status);
    final ToneColors colors = AppPalette.tone(tone);

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        borderRadius: AppRadii.mdRadius,
        boxShadow: selected
            ? AppShadows.glow(colors.glow, blur: 20, spread: -12)
            : null,
      ),
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? colors.border : AppPalette.outline,
        child: Row(
          children: <Widget>[
            AvatarRing(
              icon: ActivityStatusStyle.icon(deposit.status),
              size: 46,
              gradient: ActivityStatusStyle.gradient(deposit.status),
              active: ActivityStatusStyle.isRingActive(deposit.status),
              ringWidth: 2,
              foreground: colors.foreground,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: AmountText(deposit.amount)),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: ActivityStatusStyle.label(s, deposit.status),
                        tone: tone,
                        dense: true,
                        glow: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    s.activityViaMethod(method: deposit.methodName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          deposit.shortId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NeonTheme.monoStyle(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ActivityAge.relative(s, deposit.lastEventAt),
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.textTertiary,
                          fontFeatures: NeonFonts.numericFeatures,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const ForwardChevron(),
          ],
        ),
      ),
    );
  }
}
