/// The account-status banner, in plain words.
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';

/// Tells the player whether their casino account is linked yet.
///
/// A top-up is worthless until the cashier knows which Ichancy account to
/// credit, so the unlinked state is the loudest thing on the screen after the
/// balance: a gradient-edged card with one instruction and one button. Once
/// linked it collapses to a quiet, reassuring row - the state a player should
/// stop noticing.
class HomeAccountBanner extends StatelessWidget {
  const HomeAccountBanner({required this.linked, this.onLink, super.key});

  final bool linked;

  /// Starts the linking flow. Null leaves the button dimmed.
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);

    if (linked) {
      return AppCard(
        child: Row(
          children: <Widget>[
            Icon(
              Icons.verified_rounded,
              size: 22,
              color: AppPalette.tone(AppTone.credited).foreground,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    s.homeAccountLinkedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.homeAccountLinkedMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlowCard(
      gradient: AppPalette.gradientNeon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.link_rounded,
                size: 22,
                color: AppPalette.tone(AppTone.attention).foreground,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  s.homeAccountNotLinkedTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.homeAccountNotLinkedMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.homeAccountLinkCta,
            onPressed: onLink,
            variant: AppButtonVariant.tonal,
            icon: Icons.link_rounded,
            tone: AppTone.attention,
            expand: true,
          ),
        ],
      ),
    );
  }
}
