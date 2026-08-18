import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/admin_users/application/admin_directory_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_mutation_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/identity_cache_notice.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/role_selector.dart';

/// Add an administrator, or edit one.
///
/// One screen for both because the fields are the same three plus a role; the
/// only differences are that the Telegram id is fixed once created (there is no
/// wire field for it on PATCH) and that an edit sends a DIFF, so an untouched
/// field is never in the body and never shows up in the audit trail.
///
/// Pops with the saved [AdminUserView] on success, or null when cancelled.
class AdminUserFormScreen extends ConsumerStatefulWidget {
  const AdminUserFormScreen({this.existing, super.key});

  /// Null for a create.
  final AdminUserView? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends ConsumerState<AdminUserFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _telegramId;
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late AdminRole _role;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final AdminUserView? existing = widget.existing;
    _telegramId =
        TextEditingController(text: existing?.telegramUserIdString ?? '');
    _displayName = TextEditingController(text: existing?.displayName ?? '');
    _username = TextEditingController(text: existing?.username ?? '');
    _role = existing?.role ?? AdminRole.viewer;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _telegramId.dispose();
    _displayName.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final AdminActionGate manageGate = ref.watch(adminManageGateProvider);
    final AdminRole? actorRole = ref.watch(adminActorRoleProvider);
    final String? actorId = ref.watch(adminActorIdProvider);
    final List<AdminRole> assignable = ref.watch(assignableRolesProvider);
    final bool busy = ref.watch(adminUserMutationProvider).isBusy;

    final AdminUserView? existing = widget.existing;
    final bool isSelf =
        existing != null && actorId != null && actorId == existing.id;
    final int? knownSupers =
        ref.watch(adminDirectoryProvider).valueOrNull?.knownActiveSuperAdmins;

    // The authority gate is evaluated against what the form currently says, so
    // the reason appears the moment a forbidden role is picked - not on submit.
    final AdminActionGate authorityGate = existing == null
        ? manageGate
        : AdminUserPolicy.gateUpdate(
            actorRole: actorRole,
            actorAdminUserId: actorId,
            target: existing,
            strings: s,
            newRole: _role,
            newIsActive: _isActive,
            knownActiveSuperAdmins: knownSupers,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? s.auFormEditTitle : s.auFormCreateTitle),
      ),
      body: manageGate.isBlocked
          ? PermissionDeniedView(gate: manageGate, currentRole: actorRole)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                children: <Widget>[
                  _TelegramIdField(
                    controller: _telegramId,
                    locked: widget.isEdit,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayName,
                    textInputAction: TextInputAction.next,
                    maxLength: AdminUserFieldRules.displayNameMaxLength,
                    decoration: InputDecoration(
                      labelText: s.displayNameLabel,
                      helperText: s.auDisplayNameHelper,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        AdminUserFieldRules.displayName(value ?? '', s),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username,
                    textInputAction: TextInputAction.done,
                    maxLength: AdminUserFieldRules.usernameMaxLength,
                    decoration: InputDecoration(
                      labelText: s.auUsernameFieldLabel,
                      prefixText: '@',
                      helperText: s.auUsernameHelper,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        AdminUserFieldRules.username(value ?? '', s),
                  ),
                  const SizedBox(height: 8),
                  RoleSelector(
                    value: _role,
                    options: assignable,
                    enabled: !busy && !isSelf,
                    disabledReason: isSelf ? s.auRoleSelfLocked : null,
                    onChanged: (AdminRole role) => setState(() => _role = role),
                  ),
                  if (widget.isEdit) ...<Widget>[
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      onChanged: busy || isSelf
                          ? null
                          : (bool value) => setState(() => _isActive = value),
                      title: Text(s.auStatusActive),
                      subtitle: Text(
                        _isActive
                            ? s.auActiveOn(
                                role: AdminLabels.roleLabel(_role, s),
                              )
                            : s.auActiveOff,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isSelf)
                      Text(
                        s.auCannotDeactivateSelf,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                  if (authorityGate.isBlocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _BlockedBanner(gate: authorityGate),
                    ),
                  const SizedBox(height: 16),
                  const IdentityCacheNotice(),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: busy || authorityGate.isBlocked
                        ? null
                        : () => unawaited(_submit()),
                    icon: busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.isEdit ? s.auSaveChanges : s.auAddButton),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    child: Text(s.cancel),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final AdminUserView? existing = widget.existing;
    final String? username =
        AdminUserFieldRules.normaliseUsername(_username.text);
    final AdminUserMutationController controller =
        ref.read(adminUserMutationProvider.notifier);

    final AdminUserView? saved;
    if (existing == null) {
      saved = await controller.create(
        CreateAdminUserRequest(
          telegramUserId: BigInt.parse(_telegramId.text.trim()),
          displayName: _displayName.text.trim(),
          role: _role,
          username: username,
        ),
      );
    } else {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: existing,
        displayName: _displayName.text.trim(),
        role: _role,
        isActive: _isActive,
        username: username,
      );
      if (patch.isEmpty) {
        if (mounted) {
          AdminFeedback.info(context, context.s.auNothingChanged);
        }
        return;
      }
      saved = await controller.update(existing.id, patch);
    }

    if (!mounted) {
      return;
    }
    if (saved == null) {
      final AdminMutationState state = ref.read(adminUserMutationProvider);
      if (state is AdminMutationFailed) {
        AdminFeedback.refusal(context, state.message);
      }
      return;
    }
    Navigator.of(context).pop(saved);
  }
}

/// The Telegram id: editable once, then frozen.
///
/// There is no `telegramUserId` on `UpdateAdminUserDto`, so it genuinely cannot
/// change - showing it disabled is more honest than hiding it. A JSON number
/// would be rounded before any validator ran and the administrator created
/// would be a DIFFERENT person, which is why this is digits-only text all the
/// way to `BigInt`.
class _TelegramIdField extends StatelessWidget {
  const _TelegramIdField({required this.controller, required this.locked});

  final TextEditingController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return TextFormField(
      controller: controller,
      enabled: !locked,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: AppTheme.monoStyle(context),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
      ],
      decoration: InputDecoration(
        labelText: s.auTelegramIdFieldLabel,
        helperText:
            locked ? s.auTelegramIdHelperLocked : s.auTelegramIdHelper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      validator: locked
          ? null
          : (String? value) =>
              AdminUserFieldRules.telegramUserId(value ?? '', s),
    );
  }
}

/// Why the save button is off, stated where the operator is looking.
class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.gate});

  final AdminActionGate gate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors =
        AppSemanticColors.of(context).tone(StatusTone.reject);
    final String? code = gate.code;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.block_outlined, size: 18, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  gate.reason ?? context.s.auChangeNotAllowed,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.foreground),
                ),
                if (code != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(code, style: AppTheme.monoStyle(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
