import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/application/admin_directory_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_mutation_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/presentation/admin_user_form_screen.dart';
import 'package:manager_bot/features/admin_users/presentation/approval_limits_screen.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_user_tile.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/identity_cache_notice.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/role_selector.dart';

/// One administrator: who they are, what they can do, and the three writes that
/// can change that.
///
/// Pushed from [AdminUsersScreen] on the shell's own navigator, so the bottom
/// navigation stays visible. It is not a `go_router` destination: the router
/// defines `/settings/admin-users` only, and inventing a path here would
/// collide with whatever the router owner adds later.
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({
    required this.adminUserId,
    this.initial,
    super.key,
  });

  final String adminUserId;

  /// The row the list already had. Used for the title while the fresh copy
  /// loads, so the screen never opens on a blank app bar.
  final AdminUserView? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminActionGate viewGate = ref.watch(adminDirectoryGateProvider);
    final AdminRole? actorRole = ref.watch(adminActorRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(initial?.displayName ?? s.auDetailFallbackTitle),
        actions: <Widget>[
          if (viewGate.isAllowed)
            IconButton(
              tooltip: s.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminUserDetailProvider(adminUserId)),
            ),
        ],
      ),
      body: viewGate.isBlocked
          ? PermissionDeniedView(gate: viewGate, currentRole: actorRole)
          : AsyncValueView<AdminUserView>(
              value: ref.watch(adminUserDetailProvider(adminUserId)),
              onRetry: () => ref.invalidate(adminUserDetailProvider(adminUserId)),
              loadingLabel: s.auLoadingAdministrator,
              builder: (BuildContext context, AdminUserView admin) =>
                  _DetailBody(admin: admin),
            ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.admin});

  final AdminUserView admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;
    final AdminRole? actorRole = ref.watch(adminActorRoleProvider);
    final String? actorId = ref.watch(adminActorIdProvider);
    final int? knownSupers =
        ref.watch(adminDirectoryProvider).valueOrNull?.knownActiveSuperAdmins;
    final bool isSelf = actorId != null && actorId == admin.id;
    final AdminMutationState mutation = ref.watch(adminUserMutationProvider);

    final AdminActionGate manageGate = ref.watch(adminManageGateProvider);
    final AdminActionGate deactivateGate = AdminUserPolicy.gateDeactivate(
      actorRole: actorRole,
      actorAdminUserId: actorId,
      target: admin,
      strings: s,
      knownActiveSuperAdmins: knownSupers,
    );
    final AdminActionGate reactivateGate = AdminUserPolicy.gateReactivate(
      actorRole: actorRole,
      actorAdminUserId: actorId,
      target: admin,
      strings: s,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: <Widget>[
        _Header(admin: admin, isSelf: isSelf),
        DetailSection(
          title: s.auIdentitySection,
          children: <Widget>[
            DetailRow(
              label: s.telegramIdLabel,
              value: admin.telegramUserIdString,
              mono: true,
            ),
            DetailRow(
              label: s.auUsernameLabel,
              value: admin.atHandle ?? s.emptyValueDash,
              mono: admin.atHandle != null,
            ),
            DetailRow(label: s.auRowIdLabel, value: admin.id, mono: true),
          ],
        ),
        DetailSection(
          title: s.auAuthoritySection,
          trailing: RoleChip(role: admin.role, dense: true),
          children: <Widget>[
            DetailRow(
              label: s.auRoleFieldLabel,
              value: AdminLabels.roleWithWireName(admin.role, s),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                AdminLabels.roleSummary(admin.role, s),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            DetailRow(label: s.statusLabel, value: admin.statusLabel(s)),
            DetailRow(
              label: s.auCreatedRowLabel,
              value: s.auTimestampWithRelative(
                timestamp: AdminLabels.timestamp(admin.createdAt, s, localeTag),
                relative: AdminLabels.relative(admin.createdAt, s),
              ),
            ),
            DetailRow(
              label: s.auLastSignInLabel,
              value: admin.hasSignedIn
                  ? s.auTimestampWithRelative(
                      timestamp:
                          AdminLabels.timestamp(admin.lastLoginAt, s, localeTag),
                      relative: AdminLabels.relative(admin.lastLoginAt, s),
                    )
                  : s.auNeverSignedInValue,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                s.timesAreLocalNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        DetailSection(
          title: s.alCeilingsSection,
          children: <Widget>[
            Text(
              s.alCeilingsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ApprovalLimitsScreen(
                        adminUserId: admin.id,
                        adminDisplayName: admin.displayName,
                        adminRole: admin.role,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.speed_outlined),
                label: Text(s.alOpenCeilingsButton),
              ),
            ),
          ],
        ),
        _Actions(
          admin: admin,
          isSelf: isSelf,
          busy: mutation.isBusy,
          manageGate: manageGate,
          deactivateGate: deactivateGate,
          reactivateGate: reactivateGate,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.admin, required this.isSelf});

  final AdminUserView admin;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: admin.isActive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: admin.isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            child: Text(admin.initials, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(admin.displayName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    StatusChip(
                      label: admin.statusLabel(s),
                      tone: admin.statusTone,
                      dense: true,
                    ),
                    RoleChip(role: admin.role, dense: true),
                    if (isSelf)
                      StatusChip(
                        label: s.auYouChip,
                        tone: StatusTone.info,
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

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.admin,
    required this.isSelf,
    required this.busy,
    required this.manageGate,
    required this.deactivateGate,
    required this.reactivateGate,
  });

  final AdminUserView admin;
  final bool isSelf;
  final bool busy;
  final AdminActionGate manageGate;
  final AdminActionGate deactivateGate;
  final AdminActionGate reactivateGate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    if (manageGate.isBlocked) {
      return DetailSection(
        title: s.actionsCardTitle,
        children: <Widget>[
          PermissionDeniedHint(gate: manageGate, icon: Icons.lock_outline),
        ],
      );
    }

    final AdminActionGate activationGate =
        admin.isActive ? deactivateGate : reactivateGate;

    return DetailSection(
      title: s.actionsCardTitle,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: busy ? null : () => unawaited(_openEdit(context)),
              icon: const Icon(Icons.edit_outlined),
              label: Text(s.editButton),
            ),
            if (admin.isActive)
              OutlinedButton.icon(
                onPressed: busy || activationGate.isBlocked
                    ? null
                    : () => unawaited(_confirmDeactivate(context, ref)),
                icon: const Icon(Icons.person_off_outlined),
                label: Text(s.auDeactivateButton),
              )
            else
              OutlinedButton.icon(
                onPressed: busy || activationGate.isBlocked
                    ? null
                    : () => unawaited(_confirmReactivate(context, ref)),
                icon: const Icon(Icons.person_add_alt),
                label: Text(s.auReactivateButton),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        if (activationGate.isBlocked) PermissionDeniedHint(gate: activationGate),
        const SizedBox(height: 12),
        const IdentityCacheNotice(),
      ],
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    await Navigator.of(context).push<AdminUserView>(
      MaterialPageRoute<AdminUserView>(
        builder: (BuildContext context) => AdminUserFormScreen(existing: admin),
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: s.auDeactivateConfirmTitle(name: admin.displayName),
      message: s.auDeactivateConfirmMessage,
      confirmLabel: s.auDeactivateButton,
      tone: StatusTone.reject,
    );
    if (!(result?.confirmed ?? false) || !context.mounted) {
      return;
    }
    await ref.read(adminUserMutationProvider.notifier).deactivate(admin.id);
    if (context.mounted) {
      _reportOutcome(context, ref);
    }
  }

  Future<void> _confirmReactivate(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: s.auReactivateConfirmTitle(name: admin.displayName),
      message: s.auReactivateConfirmMessage(
        role: AdminLabels.roleLabel(admin.role, s),
      ),
      confirmLabel: s.auReactivateButton,
      tone: StatusTone.approve,
    );
    if (!(result?.confirmed ?? false) || !context.mounted) {
      return;
    }
    await ref.read(adminUserMutationProvider.notifier).reactivate(admin.id);
    if (context.mounted) {
      _reportOutcome(context, ref);
    }
  }

  /// The directory screen also listens and shows a snackbar, but this screen is
  /// pushed on top of it, so the outcome has to be repeated here to be seen.
  void _reportOutcome(BuildContext context, WidgetRef ref) {
    final AdminMutationState state = ref.read(adminUserMutationProvider);
    switch (state) {
      case AdminMutationIdle():
      case AdminMutationRunning():
        break;
      case final AdminMutationSucceeded success:
        AdminFeedback.success(context, success.message, notice: success.notice);
      case final AdminMutationFailed failure:
        AdminFeedback.refusal(context, failure.message);
    }
  }
}
