import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';

/// Lifetime numbers: how much has been topped up, how many times, and since
/// when.
///
/// The amount gets a card of its own and the biggest type on the tab - this is
/// a money app, so the money is the most readable thing on screen.
class ProfileStatTiles extends StatelessWidget {
  const ProfileStatTiles({required this.profile, this.now, super.key});

  final PlayerProfile profile;

  /// Reference point for the "member since" age. Defaults to the wall clock;
  /// tests pass a fixed instant.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final DateTime reference = now ?? DateTime.now();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              const AvatarRing(
                icon: Icons.savings_rounded,
                size: 48,
                gradient: AppPalette.gradientCredited,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      s.profileStatTotalDeposited,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: AmountText(
                        profile.totalDeposited,
                        fontSize: 26,
                        tone: AppTone.credited,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  icon: Icons.receipt_long_rounded,
                  accent: AppPalette.accentCyan,
                  label: s.profileStatDepositCount,
                  value: '${profile.depositCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month_rounded,
                  accent: AppPalette.accentViolet,
                  label: s.profileStatMemberSince,
                  value: AppDateFormats.custom(
                    'MM/yyyy',
                    profile.memberSince,
                    context.localeTag,
                  ),
                  caption: ProfileLabels.ago(
                    s,
                    profile.membershipAge(reference),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final Color accent;
  final String label;

  /// Already-formatted. Digits are Western in both locales.
  final String value;

  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NeonTheme.moneyStyle(context, fontSize: 20),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.textDisabled,
                fontFeatures: NeonFonts.numericFeatures,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
