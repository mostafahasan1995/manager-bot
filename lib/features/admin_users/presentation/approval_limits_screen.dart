import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/application/approval_limits_controller.dart';
import 'package:manager_bot/features/admin_users/data/approval_limit.dart';
import 'package:manager_bot/features/admin_users/presentation/approval_limit_form_screen.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_user_tile.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/permission_denied_view.dart';

/// Roles that may approve money movements AT ALL.
///
/// Mirrors `APPROVER_ROLES` in `src/modules/admin/admin.constants.ts`. A role
/// outside this set is denied before any ceiling is consulted, which is why the
/// screen says "this role may never approve" instead of "no ceiling
/// configured" - the two are different problems with different fixes.
const Set<AdminRole> approverRoles = <AdminRole>{
  AdminRole.superAdmin,
  AdminRole.financeAdmin,
  AdminRole.reviewer,
};

/// The approval-ceiling history of one administrator.
///
/// Readable by SUPER_ADMIN and FINANCE_ADMIN; writable by SUPER_ADMIN only.
/// History is never rewritten - setting a ceiling closes the version in force
/// and opens a new one at the same instant, so there is never a gap in which
/// the administrator has no ceiling (which the evaluator would read as DENIED)
/// and never an overlap in which two versions both apply.
class ApprovalLimitsScreen extends ConsumerWidget {
  const ApprovalLimitsScreen({
    required this.adminUserId,
    required this.adminDisplayName,
    required this.adminRole,
    super.key,
  });

  final String adminUserId;
  final String adminDisplayName;
  final AdminRole adminRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminActionGate viewGate = ref.watch(adminDirectoryGateProvider);
    final AdminActionGate manageGate = ref.watch(adminManageGateProvider);
    final AdminRole? actorRole = ref.watch(adminActorRoleProvider);

    _listen(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.alCeilingsSection),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                adminDisplayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: viewGate.isBlocked || manageGate.isBlocked
          ? null
          : FloatingActionButton.extended(
              onPressed: () => unawaited(_openForm(context)),
              icon: const Icon(Icons.add),
              label: Text(s.alSetCeilingButton),
            ),
      body: viewGate.isBlocked
          ? PermissionDeniedView(gate: viewGate, currentRole: actorRole)
          : AsyncValueView<List<ApprovalLimitView>>(
              value: ref.watch(approvalLimitsProvider(adminUserId)),
              onRetry: () => ref.invalidate(approvalLimitsProvider(adminUserId)),
              isEmpty: (List<ApprovalLimitView> history) => history.isEmpty,
              emptyTitle: s.alEmptyTitle,
              emptyMessage: s.alEmptyMessage,
              emptyIcon: Icons.speed_outlined,
              loadingLabel: s.alLoadingHistory,
              builder: (BuildContext context, List<ApprovalLimitView> history) =>
                  _History(
                history: history,
                adminUserId: adminUserId,
                adminDisplayName: adminDisplayName,
                adminRole: adminRole,
                manageGate: manageGate,
              ),
            ),
    );
  }

  void _listen(BuildContext context, WidgetRef ref) {
    ref.listen<ApprovalLimitMutationState>(approvalLimitMutationProvider,
        (ApprovalLimitMutationState? previous, ApprovalLimitMutationState next) {
      switch (next) {
        case ApprovalLimitMutationIdle():
        case ApprovalLimitMutationRunning():
          break;
        case final ApprovalLimitMutationSucceeded success:
          AdminFeedback.success(context, success.message, notice: success.notice);
        case final ApprovalLimitMutationRaced raced:
          AdminFeedback.info(context, raced.message);
        case final ApprovalLimitMutationRejected rejected:
          AdminFeedback.refusal(context, rejected.message(context.s));
        case final ApprovalLimitMutationFailed failure:
          AdminFeedback.refusal(context, failure.message);
      }
    });
  }

  Future<void> _openForm(BuildContext context) =>
      openApprovalLimitForm(
        context,
        adminUserId: adminUserId,
        adminDisplayName: adminDisplayName,
      );
}

/// Pushes the "set ceiling" form. Shared by the screen's own action button and
/// by the "replace" action on the version currently in force.
Future<void> openApprovalLimitForm(
  BuildContext context, {
  required String adminUserId,
  required String adminDisplayName,
  ApprovalLimitView? basedOn,
}) async {
  await Navigator.of(context).push<ApprovalLimitView>(
    MaterialPageRoute<ApprovalLimitView>(
      builder: (BuildContext context) => ApprovalLimitFormScreen(
        adminUserId: adminUserId,
        adminDisplayName: adminDisplayName,
        basedOn: basedOn,
      ),
    ),
  );
}

class _History extends ConsumerWidget {
  const _History({
    required this.history,
    required this.adminUserId,
    required this.adminDisplayName,
    required this.adminRole,
    required this.manageGate,
  });

  final List<ApprovalLimitView> history;
  final String adminUserId;
  final String adminDisplayName;
  final AdminRole adminRole;
  final AdminActionGate manageGate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool mayApprove = approverRoles.contains(adminRole);
    final List<String> currencies = currenciesIn(history);
    final bool busy = ref.watch(approvalLimitMutationProvider).isBusy;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(approvalLimitsProvider(adminUserId));
        try {
          await ref.read(approvalLimitsProvider(adminUserId).future);
        } on Object {
          // Already the provider's state; AsyncValueView renders it with retry.
        }
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: <Widget>[
          if (!mayApprove)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _Banner(
                tone: StatusTone.reject,
                icon: Icons.block_outlined,
                title: s.alRoleMayNeverApproveTitle(
                  role: AdminLabels.roleLabel(adminRole, s),
                ),
                message: s.alRoleMayNeverApproveMessage,
              ),
            ),
          for (final String currency in currencies)
            _CurrencyBlock(
              currency: currency,
              history: history,
              adminUserId: adminUserId,
              adminDisplayName: adminDisplayName,
              manageGate: manageGate,
              busy: busy,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              s.alVersioningNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              s.timesAreLocalNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyBlock extends ConsumerWidget {
  const _CurrencyBlock({
    required this.currency,
    required this.history,
    required this.adminUserId,
    required this.adminDisplayName,
    required this.manageGate,
    required this.busy,
  });

  final String currency;
  final List<ApprovalLimitView> history;
  final String adminUserId;
  final String adminDisplayName;
  final AdminActionGate manageGate;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final List<ApprovalLimitView> versions = history
        .where((ApprovalLimitView limit) =>
            limit.currencyCode.toUpperCase() == currency)
        .toList(growable: false);
    final ApprovalLimitView? active = activeLimitFor(history, currency);

    return DetailSection(
      title: currency,
      trailing: StatusChip(
        label: active == null ? s.alNoActiveChip : s.alInForceChip,
        tone: active == null ? StatusTone.failed : StatusTone.approve,
        dense: true,
      ),
      children: <Widget>[
        if (active == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              s.alNoActiveMessage(currency: currency),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final ApprovalLimitView limit in versions)
          _LimitCard(
            limit: limit,
            adminUserId: adminUserId,
            adminDisplayName: adminDisplayName,
            manageGate: manageGate,
            busy: busy,
          ),
      ],
    );
  }
}

class _LimitCard extends ConsumerWidget {
  const _LimitCard({
    required this.limit,
    required this.adminUserId,
    required this.adminDisplayName,
    required this.manageGate,
    required this.busy,
  });

  final ApprovalLimitView limit;
  final String adminUserId;
  final String adminDisplayName;
  final AdminActionGate manageGate;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: limit.isInForce
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusChip(
                label: limit.statusLabel(s),
                tone: limit.statusTone,
                dense: true,
              ),
              const Spacer(),
              Text(
                AdminLabels.timestamp(limit.effectiveFrom, s, localeTag),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MoneyRow(
            label: s.alSingleApprovalLabel,
            money: limit.maxSingleApproval,
          ),
          _MoneyRow(label: s.alDailyBudgetLabel, money: limit.maxDailyApproval),
          if (limit.inheritsGlobalThreshold)
            DetailRow(
              label: s.alSecondApprovalLabel,
              value: s.alInheritsGlobal,
            )
          else
            _MoneyRow(
              label: s.alSecondApprovalAboveLabel,
              money: limit.secondApprovalAbove,
            ),
          if (!limit.isInForce)
            DetailRow(
              label: s.alEndedLabel,
              value: AdminLabels.timestamp(limit.effectiveTo, s, localeTag),
            ),
          if (limit.isInForce && manageGate.isAllowed) ...<Widget>[
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              children: <Widget>[
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => unawaited(
                            openApprovalLimitForm(
                              context,
                              adminUserId: adminUserId,
                              adminDisplayName: adminDisplayName,
                              basedOn: limit,
                            ),
                          ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.alReplaceButton),
                ),
                TextButton.icon(
                  onPressed:
                      busy ? null : () => unawaited(_confirmEnd(context, ref)),
                  icon: const Icon(Icons.timer_off_outlined),
                  label: Text(s.alEndCeilingButton),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: s.alEndConfirmTitle(currency: limit.currencyCode),
      message: s.alEndConfirmMessage,
      confirmLabel: s.alEndConfirmLabel,
      tone: StatusTone.reject,
    );
    if (!(result?.confirmed ?? false)) {
      return;
    }
    await ref
        .read(approvalLimitMutationProvider.notifier)
        .endLimit(adminUserId, limit.id);
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.money});

  final String label;
  final Money? money;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: MoneyText(money, emphasise: true)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
  });

  final StatusTone tone;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors = AppSemanticColors.of(context).tone(tone);
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
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
