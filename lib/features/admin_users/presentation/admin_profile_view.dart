import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_user_tile.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/role_selector.dart';

/// Who is signed in, what they can do, and what this build is pointed at.
///
/// Four questions this screen exists to answer without anybody having to guess:
///  * WHO am I signed in as, and with which role?
///  * WHAT can that role actually do in this console?
///  * WHICH backend is this build talking to, through which auth adapter?
///  * WHAT is the last correlation id, so support can find the request?
///
/// It is the body of the settings tab. Kept in this feature because everything
/// on it - roles, capabilities, the signed-in administrator - is the staff
/// administration domain.
class AdminProfileView extends ConsumerStatefulWidget {
  const AdminProfileView({super.key});

  @override
  ConsumerState<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends ConsumerState<AdminProfileView> {
  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final AuthState auth = ref.watch(authControllerProvider);
    final AdminSession? session = auth.session;
    final AppConfig config = ref.watch(appConfigProvider);
    final AdminAuthApi adapter = ref.watch(activeAuthAdapterProvider);
    final ApiClient client = ref.watch(apiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.profileRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: session == null
          ? EmptyStateView(
              title: s.profileNotSignedInTitle,
              message: s.profileNotSignedInMessage,
              icon: Icons.badge_outlined,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: <Widget>[
                _SessionHeader(session: session),
                _IdentitySection(session: session),
                _CapabilitiesSection(role: session.role),
                _BackendSection(
                  config: config,
                  adapter: adapter,
                  correlationId: client.lastCorrelationId,
                ),
                _SignOutSection(busy: auth.isBusy),
              ],
            ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool expiringSoon = session.expiresWithin(const Duration(minutes: 10));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(session.displayName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    RoleChip(role: session.role, dense: true),
                    StatusChip(
                      label: session.isExpired
                          ? s.errorTitleSessionExpired
                          : s.profileSessionExpiresChip(
                              relative:
                                  AdminLabels.relative(session.expiresAt, s),
                            ),
                      tone: session.isExpired
                          ? StatusTone.failed
                          : (expiringSoon
                              ? StatusTone.pending
                              : StatusTone.approve),
                      dense: true,
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

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;
    return DetailSection(
      title: s.profileSignedInAsSection,
      children: <Widget>[
        DetailRow(label: s.displayNameLabel, value: session.displayName),
        DetailRow(
          label: s.auRoleFieldLabel,
          value: AdminLabels.roleWithWireName(session.role, s),
        ),
        DetailRow(
          label: s.profileAdminIdLabel,
          value: session.adminUserId,
          mono: true,
          trailing: _CopyButton(value: session.adminUserId),
        ),
        DetailRow(
          label: s.telegramIdLabel,
          value: session.telegramUserIdString ?? s.emptyValueDash,
          mono: true,
        ),
        DetailRow(
          label: s.profileIssuedLabel,
          value: AdminLabels.timestamp(session.issuedAt, s, localeTag),
        ),
        DetailRow(
          label: s.profileExpiresLabel,
          value: s.auTimestampWithRelative(
            timestamp: AdminLabels.timestamp(session.expiresAt, s, localeTag),
            relative: AdminLabels.relative(session.expiresAt, s),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            s.timesAreLocalNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _CapabilitiesSection extends StatelessWidget {
  const _CapabilitiesSection({required this.role});

  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final List<AdminCapability> granted = AdminRoles.capabilitiesOf(role);
    final List<AdminCapability> withheld = AdminCapability.values
        .where((AdminCapability capability) => !granted.contains(capability))
        .toList(growable: false);

    return DetailSection(
      title: s.profileCapabilitiesSection(
        role: AdminLabels.roleLabel(role, s),
      ),
      children: <Widget>[
        Text(
          AdminLabels.roleSummary(role, s),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        for (final AdminCapability capability in granted)
          _CapabilityRow(capability: capability, granted: true),
        if (withheld.isNotEmpty) ...<Widget>[
          const Divider(height: 20),
          Text(
            s.profileNotAvailableToRole,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          for (final AdminCapability capability in withheld)
            _CapabilityRow(capability: capability, granted: false),
        ],
        const SizedBox(height: 8),
        Text(
          s.profileServerEnforces,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.capability, required this.granted});

  final AdminCapability capability;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = granted
        ? AppSemanticColors.of(context).tone(StatusTone.approve).foreground
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Icon(
            granted ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AdminLabels.capability(capability, context.s),
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendSection extends StatelessWidget {
  const _BackendSection({
    required this.config,
    required this.adapter,
    required this.correlationId,
  });

  final AppConfig config;
  final AdminAuthApi adapter;
  final String? correlationId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    return DetailSection(
      title: s.profileBuildSection,
      trailing: StatusChip(
        label: config.environment.wireName.toUpperCase(),
        tone: config.isProd ? StatusTone.failed : StatusTone.info,
        dense: true,
      ),
      children: <Widget>[
        DetailRow(
          label: s.profileBaseUrlLabel,
          value: config.baseUrl,
          mono: true,
          trailing: _CopyButton(value: config.baseUrl),
        ),
        DetailRow(
          label: s.profileEnvironmentLabel,
          value: config.environment.wireName,
        ),
        DetailRow(
          label: s.profileAuthAdapterLabel,
          value: adapter.adapterName,
          trailing: adapter.isFake
              ? StatusChip(
                  label: s.profileFakeChip,
                  tone: StatusTone.pending,
                  dense: true,
                )
              : null,
        ),
        DetailRow(
          label: s.profilePageSizeLabel,
          value: '${config.defaultPageSize}',
        ),
        DetailRow(
          label: s.profileCorrelationIdLabel,
          value: correlationId ?? s.emptyValueDash,
          mono: true,
          trailing:
              correlationId == null ? null : _CopyButton(value: correlationId!),
        ),
        const SizedBox(height: 8),
        Text(
          config.describe(),
          style: AppTheme.monoStyle(context),
        ),
        if (adapter.isFake) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            s.profileFakeAdapterWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.of(context)
                  .tone(StatusTone.pending)
                  .foreground,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          s.profileCorrelationNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        tooltip: context.s.copyTooltip,
        icon: const Icon(Icons.copy_all_outlined),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            AdminFeedback.info(context, context.s.copied);
          }
        },
      );
}

class _SignOutSection extends ConsumerWidget {
  const _SignOutSection({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DetailSection(
        title: context.s.profileSessionSection,
        children: <Widget>[
          Text(
            context.s.profileSignOutNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => unawaited(_confirm(context, ref)),
              icon: const Icon(Icons.logout),
              label: Text(context.s.profileSignOutButton),
            ),
          ),
        ],
      );

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: s.profileSignOutConfirmTitle,
      message: s.profileSignOutConfirmMessage,
      confirmLabel: s.profileSignOutButton,
      tone: StatusTone.reject,
    );
    if (!(result?.confirmed ?? false)) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
