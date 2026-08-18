import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_clipboard.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_rows.dart';

/// The language switch, wired to the real locale controller.
///
/// The choice is persisted in the platform keystore by [LocaleController], so
/// the app reopens in the language the player picked. Arabic is the default and
/// stays first in reading order.
class ProfileLanguageCard extends ConsumerWidget {
  const ProfileLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final Locale locale = ref.watch(localeControllerProvider);
    final bool arabic = locale != AppLocales.english;

    return AppCard(
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.translate_rounded,
            size: 20,
            color: AppPalette.accentCyan,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              s.languageLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          StatusChip(
            label: s.languageArabic,
            tone: arabic ? AppTone.info : AppTone.neutral,
            dense: true,
            glow: arabic,
            onTap: arabic
                ? null
                : () => unawaited(
                      ref.read(localeControllerProvider.notifier).useArabic(),
                    ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            label: s.languageEnglish,
            tone: arabic ? AppTone.neutral : AppTone.info,
            dense: true,
            glow: !arabic,
            onTap: arabic
                ? () => unawaited(
                      ref.read(localeControllerProvider.notifier).useEnglish(),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Terms, support and the build version.
///
/// Nothing here leaves the app: there is no url launcher in this dependency
/// set, so the support handle is offered as copyable text instead of a link
/// that would silently do nothing.
class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({required this.profile, super.key});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ProfileNavRow(
            icon: Icons.description_outlined,
            label: s.profileTermsLabel,
            onTap: () => _openTerms(context, s),
          ),
          const Divider(height: 1),
          ProfileNavRow(
            icon: Icons.support_agent_rounded,
            label: s.profileSupportLabel,
            iconColor: AppPalette.accentMagenta,
            onTap: () => _openSupport(context, s),
          ),
          const Divider(height: 1),
          ProfileNavRow(
            icon: Icons.info_outline_rounded,
            label: s.profileAppVersionLabel,
            iconColor: AppPalette.textTertiary,
            value: profile.appVersion,
          ),
        ],
      ),
    );
  }

  void _openTerms(BuildContext context, AppStrings s) {
    _openSheet(
      context,
      title: s.profileTermsLabel,
      body: s.profileTermsBody,
    );
  }

  void _openSupport(BuildContext context, AppStrings s) {
    _openSheet(
      context,
      title: s.profileSupportLabel,
      body: s.profileSupportBody,
      extra: ProfileCopyField(
        label: s.profileSupportChannelLabel,
        value: profile.supportHandle,
        icon: Icons.send_rounded,
        onCopy: () => ProfileClipboard.copy(
          context,
          value: profile.supportHandle,
          label: s.profileSupportChannelLabel,
        ),
      ),
    );
  }

  void _openSheet(
    BuildContext context, {
    required String title,
    required String body,
    Widget? extra,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheetContext) => _InfoSheet(
          title: title,
          body: body,
          extra: extra,
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.title,
    required this.body,
    this.extra,
  });

  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.textSecondary,
              ),
            ),
            if (extra != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              extra!,
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.s.profileCloseButton,
              variant: AppButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
