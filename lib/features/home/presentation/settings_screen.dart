import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/router/app_router.dart';

/// Everything that is NOT daily work, in one place behind the app-bar gear.
///
/// The owner's complaint about the five-tab build was "taps without purpose":
/// payment methods and the staff directory were bottom-nav destinations that an
/// operator opened perhaps once a month. They live here now, alongside the
/// things that were always settings - who am I, which language, sign out.
///
/// Every configuration entry is gated on the SAME capability the router guards
/// its route with, so a role never sees a row that would bounce it straight
/// back to the queue.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminSession? session = ref.watch(currentSessionProvider);
    final AdminRole? role = session?.role;
    final bool canSeePaymentMethods =
        AdminRoles.can(role, AdminCapability.viewPaymentMethods);
    final bool canSeeDirectory =
        AdminRoles.can(role, AdminCapability.viewAdminUsers);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTooltip)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: <Widget>[
          if (session != null)
            _SettingsSection(
              title: s.profileSignedInAsSection,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(session.displayName),
                  subtitle: Text(
                    s.signedInAsRole(role: settingsRoleLabel(session.role, s)),
                  ),
                  trailing: Icon(_chevronIcon(context)),
                  onTap: () =>
                      unawaited(context.pushNamed<void>(AppRoute.profile)),
                ),
              ],
            ),
          _SettingsSection(
            title: s.languageLabel,
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _LanguageToggle(),
              ),
            ],
          ),
          if (canSeePaymentMethods)
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(s.pmScreenTitle),
              subtitle: Text(s.capViewPaymentMethods),
              trailing: Icon(_chevronIcon(context)),
              onTap: () =>
                  unawaited(context.pushNamed<void>(AppRoute.paymentMethods)),
            ),
          if (canSeeDirectory)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(s.auScreenTitle),
              subtitle: Text(s.capViewAdminUsers),
              trailing: Icon(_chevronIcon(context)),
              onTap: () =>
                  unawaited(context.pushNamed<void>(AppRoute.adminUsers)),
            ),
          if (canSeeDirectory)
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(s.alCeilingsSection),
              subtitle: Text(
                s.alCeilingsIntro,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(_chevronIcon(context)),
              onTap: () =>
                  unawaited(context.pushNamed<void>(AppRoute.approvalLimits)),
            ),
          if (canSeePaymentMethods || canSeeDirectory)
            const Divider(height: 24),
          _SettingsSection(
            title: s.profileSessionSection,
            children: const <Widget>[_SignOutTile()],
          ),
        ],
      ),
    );
  }
}

/// Arabic / English, persisted to the keystore by `LocaleController`.
///
/// The whole tree - including the RTL `Directionality` the Flutter delegates
/// install - follows this, because `ManagerBotApp` watches the same provider.
class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    // Compared as a tag, not as a Locale object: the stored value can carry a
    // country subtag and `Locale('ar') != Locale('ar', 'SY')`, which would
    // leave the toggle showing nothing selected.
    final String tag = AppLocales.tagOf(ref.watch(localeControllerProvider));

    return SegmentedButton<String>(
      segments: <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: AppLocales.tagOf(AppLocales.arabic),
          label: Text(s.languageArabic),
        ),
        ButtonSegment<String>(
          value: AppLocales.tagOf(AppLocales.english),
          label: Text(s.languageEnglish),
        ),
      ],
      selected: <String>{tag},
      showSelectedIcon: false,
      onSelectionChanged: (Set<String> selection) => unawaited(
        ref
            .read(localeControllerProvider.notifier)
            .setLocale(AppLocales.parse(selection.first)),
      ),
    );
  }
}

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool busy = ref.watch(authControllerProvider).isBusy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            s.profileSignOutNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => unawaited(_confirm(context, ref)),
              icon: const Icon(Icons.logout),
              label: Text(s.profileSignOutButton),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: s.profileSignOutConfirmTitle,
      message: s.profileSignOutConfirmMessage,
      confirmLabel: s.profileSignOutButton,
      cancelLabel: s.cancel,
      tone: StatusTone.reject,
    );
    if (!(result?.confirmed ?? false)) {
      return;
    }
    // The router's auth listener sends the app to /login; nothing here has to
    // pop the settings route by hand.
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

/// A titled group of rows.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(height: 24),
      ],
    );
  }
}

/// "Opens a sub-screen", pointing the way the language reads.
///
/// `Icon` does not mirror itself, and a chevron pointing out of the screen in
/// Arabic is the kind of small wrongness that makes an app feel foreign.
IconData _chevronIcon(BuildContext context) =>
    context.isRtl ? Icons.chevron_left : Icons.chevron_right;

/// The role name in the active language.
///
/// Deliberately local: `AdminRole.label` is English on the enum and the
/// staff-administration feature owns whatever it becomes. Navigation reads the
/// catalogue directly so a rename there cannot take this screen with it.
String settingsRoleLabel(AdminRole role, AppStrings s) => switch (role) {
      AdminRole.superAdmin => s.roleSuperAdmin,
      AdminRole.financeAdmin => s.roleFinanceAdmin,
      AdminRole.reviewer => s.roleReviewer,
      AdminRole.support => s.roleSupport,
      AdminRole.viewer => s.roleViewer,
    };
