import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/application/profile_controller.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_clipboard.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_rows.dart';

/// The block the bot's `/profile` command prints, as a card: name, username,
/// Telegram id, currency, account status, gaming-account state, referral code
/// and invite link.
///
/// The Telegram id is masked until the player asks for it - this screen is
/// opened in public places.
class ProfileDetailCard extends ConsumerWidget {
  const ProfileDetailCard({required this.profile, super.key});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool revealed = ref.watch(profileRevealProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ProfileDetailRow(
            label: s.displayNameLabel,
            child: ProfileValueText(profile.displayName),
          ),
          ProfileDetailRow(
            label: s.profileUsernameLabel,
            child: ProfileValueText(profile.usernameHandle),
          ),
          ProfileDetailRow(
            label: s.telegramIdLabel,
            trailing: IconButton(
              onPressed: () => ref.read(profileRevealProvider.notifier).toggle(),
              tooltip: s.profileRevealTooltip,
              color: AppPalette.textTertiary,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                revealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
              ),
            ),
            child: ProfileValueText(
              revealed
                  ? profile.telegramId
                  : ProfileLabels.masked(profile.telegramId),
              tabular: true,
            ),
          ),
          ProfileDetailRow(
            label: s.currencyLabel,
            child: ProfileValueText(profile.currency, tabular: true),
          ),
          ProfileDetailRow(
            label: s.statusLabel,
            child: StatusChip(
              label: ProfileLabels.accountStatus(s, profile.accountStatus),
              tone: ProfileLabels.accountTone(profile.accountStatus),
              dense: true,
              glow: false,
            ),
          ),
          ProfileDetailRow(
            label: s.profileGamingAccountLabel,
            child: StatusChip(
              label: ProfileLabels.gamingAccount(s, profile.gamingAccount),
              tone: ProfileLabels.gamingTone(profile.gamingAccount),
              dense: true,
              glow: false,
            ),
          ),
          const Divider(height: AppSpacing.xl),
          ProfileCopyField(
            label: s.profileReferralCodeLabel,
            value: profile.referralCode,
            icon: Icons.confirmation_number_outlined,
            onCopy: () => ProfileClipboard.copy(
              context,
              value: profile.referralCode,
              label: s.profileReferralCodeLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileCopyField(
            label: s.profileInviteLinkLabel,
            value: profile.inviteLink,
            icon: Icons.link_rounded,
            onCopy: () => ProfileClipboard.copy(
              context,
              value: profile.inviteLink,
              label: s.profileInviteLinkLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.profileReferralHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
