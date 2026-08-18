import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';

/// The one loud surface on this tab: who the player is, and where the account
/// stands.
///
/// A single [GlowCard] carries the whole identity block; everything below it is
/// quiet so the glow stays meaningful.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({required this.profile, super.key});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    return GlowCard(
      gradient: AppPalette.gradientHot,
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          AvatarRing(initials: profile.initials, size: 68),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  profile.usernameHandle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.textTertiary,
                    fontFeatures: NeonFonts.numericFeatures,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    StatusChip(
                      label: ProfileLabels.accountStatus(
                        s,
                        profile.accountStatus,
                      ),
                      tone: ProfileLabels.accountTone(profile.accountStatus),
                      icon: ProfileLabels.accountIcon(profile.accountStatus),
                      dense: true,
                    ),
                    StatusChip(
                      label: ProfileLabels.gamingAccount(
                        s,
                        profile.gamingAccount,
                      ),
                      tone: ProfileLabels.gamingTone(profile.gamingAccount),
                      icon: ProfileLabels.gamingIcon(profile.gamingAccount),
                      dense: true,
                      glow: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
