import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/break_detail_controller.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/data/break_action_result.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_drift_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_evidence_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_formats.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/resolve_break_sheet.dart';

/// One break: its numbers, the detector's evidence, and the three writes.
///
/// Pushed on the root navigator rather than routed: the app router owns a
/// single `/reconciliation` location and belongs to the foundation, so this
/// feature does not add a route to it.
class BreakDetailScreen extends ConsumerStatefulWidget {
  const BreakDetailScreen({required this.breakId, super.key});

  /// Opens the screen for [breakId].
  static Future<void> open(BuildContext context, String breakId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BreakDetailScreen(breakId: breakId),
      ),
    );
  }

  /// UUID of the break.
  final String breakId;

  @override
  ConsumerState<BreakDetailScreen> createState() => _BreakDetailScreenState();
}

class _BreakDetailScreenState extends ConsumerState<BreakDetailScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final bool canView = ref.watch(canViewReconciliationProvider);
    final AsyncValue<BreakView> value =
        ref.watch(breakDetailProvider(widget.breakId));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.breakScreenTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.refresh,
            onPressed: _working
                ? null
                : () => ref.invalidate(breakDetailProvider(widget.breakId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !canView
          ? ReconciliationDeniedView(
              role: ref.watch(currentRoleProvider),
              allowed: ReconciliationRoles.viewRoles,
              action: s.deniedActionOpenBreak,
            )
          : AsyncValueView<BreakView>(
              value: value,
              onRetry: () => ref.invalidate(breakDetailProvider(widget.breakId)),
              loadingLabel: s.loadingBreak,
              builder: (BuildContext context, BreakView breakView) =>
                  _BreakDetailBody(
                breakView: breakView,
                working: _working,
                onAssign: () => unawaited(_assign()),
                onResolve: () => unawaited(_resolve(breakView)),
                onCorrectFloat: () => unawaited(_correctFloat(breakView)),
              ),
            ),
    );
  }

  BreakDetailController get _controller =>
      ref.read(breakDetailProvider(widget.breakId).notifier);

  Future<void> _assign() async {
    if (_working) {
      return;
    }
    setState(() => _working = true);
    final BreakActionResult result = await _controller.assign();
    if (!mounted) {
      return;
    }
    setState(() => _working = false);
    _report(
      result.userMessage(context.s),
      alarming: result is BreakActionFailed,
    );
  }

  Future<void> _resolve(BreakView breakView) async {
    if (_working) {
      return;
    }
    final ResolveBreakRequest? request =
        await ResolveBreakSheet.show(context, breakView: breakView);
    if (request == null || !mounted) {
      return;
    }
    setState(() => _working = true);
    final BreakActionResult result = await _controller.resolve(
      status: request.status,
      note: request.note,
    );
    if (!mounted) {
      return;
    }
    setState(() => _working = false);
    _report(
      result.userMessage(context.s),
      alarming: result is BreakActionFailed,
    );
  }

  /// The one action that CHANGES THE BOOKS, so it gets its own confirmation
  /// with the exact signed amount in the title and a mandatory note.
  Future<void> _correctFloat(BreakView breakView) async {
    if (_working) {
      return;
    }
    final AppStrings s = context.s;
    final ConfirmActionResult? confirmation = await ConfirmActionSheet.show(
      context,
      title: s.correctFloatConfirmTitle(
        amount: breakView.delta?.format(alwaysShowSign: true) ??
            s.correctFloatConfirmTitleFallback,
      ),
      message: s.correctFloatConfirmMessage,
      confirmLabel: s.correctFloatConfirmLabel,
      cancelLabel: s.cancel,
      tone: StatusTone.failed,
      withNote: true,
      noteLabel: s.correctionNoteLabel,
      noteHint: s.correctionNoteHint,
      noteRequired: true,
      noteMaxLength: ResolveBreakSheet.noteMaxLength,
    );
    final String? note = confirmation?.note;
    if (confirmation == null || !confirmation.confirmed || note == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _working = true);
    final CorrectFloatResult result = await _controller.correctFloat(note: note);
    if (!mounted) {
      return;
    }
    setState(() => _working = false);
    _report(
      result.userMessage(context.s),
      alarming: result is CorrectFloatFailed,
    );
  }

  void _report(String message, {required bool alarming}) {
    final AppSemanticColors semantics = AppSemanticColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: alarming ? semantics.reject.foreground : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

class _BreakDetailBody extends StatelessWidget {
  const _BreakDetailBody({
    required this.breakView,
    required this.working,
    required this.onAssign,
    required this.onResolve,
    required this.onCorrectFloat,
  });

  final BreakView breakView;
  final bool working;
  final VoidCallback onAssign;
  final VoidCallback onResolve;
  final VoidCallback onCorrectFloat;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _BreakHeaderCard(breakView: breakView),
        const SizedBox(height: 14),
        ReconciliationCard(
          title: s.cardTheDifference,
          icon: Icons.difference_outlined,
          child: BreakDriftView(breakView: breakView),
        ),
        const SizedBox(height: 14),
        ReconciliationCard(
          title: s.cardDetectorEvidence,
          subtitle: s.cardDetectorEvidenceSubtitle,
          icon: Icons.science_outlined,
          child: BreakEvidenceView(breakView: breakView),
        ),
        const SizedBox(height: 14),
        ReconciliationCard(
          title: s.cardLinkedRecords,
          icon: Icons.link,
          child: BreakLinksView(breakView: breakView),
        ),
        if (breakView.resolvedAt != null) ...<Widget>[
          const SizedBox(height: 14),
          _ResolutionCard(breakView: breakView),
        ],
        const SizedBox(height: 14),
        _BreakActionsCard(
          breakView: breakView,
          working: working,
          onAssign: onAssign,
          onResolve: onResolve,
          onCorrectFloat: onCorrectFloat,
        ),
        const SizedBox(height: 14),
        // Every timestamp on this screen is the device's local time while the
        // bot prints UTC.
        Text(
          s.timesAreLocalNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _BreakHeaderCard extends StatelessWidget {
  const _BreakHeaderCard({required this.breakView});

  final BreakView breakView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    return ReconciliationCard(
      title: breakView.category == BreakCategory.unknown
          ? breakView.categoryWire
          : breakView.category.label(s),
      subtitle: ReconciliationFormats.timestampWithAge(
        breakView.detectedAt,
        s,
        context.localeTag,
      ),
      icon: Icons.report_outlined,
      tone: breakView.needsAttention ? StatusTone.failed : null,
      trailing: StatusChip(
        label: breakView.status == BreakStatus.unknown
            ? breakView.statusWire
            : breakView.status.label(s),
        tone: breakView.status.tone,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (breakView.isReopenedAfterClosure) ...<Widget>[
            NoticeStrip(
              message: s.breakReopenedNotice,
              tone: StatusTone.pending,
            ),
            const SizedBox(height: 12),
          ],
          if (!breakView.category.hasDetector) ...<Widget>[
            NoticeStrip(
              message: s.breakNoDetectorNotice,
              tone: StatusTone.info,
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusChip(
                label: BreakSeverity.label(breakView.severity, s),
                tone: BreakSeverity.tone(breakView.severity),
                dense: true,
              ),
              StatusChip(
                label: breakView.currencyCode,
                tone: StatusTone.neutral,
                dense: true,
              ),
              if (breakView.isAssigned)
                StatusChip(
                  label: s.chipAssigned,
                  tone: StatusTone.info,
                  icon: Icons.person_outline,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          KeyValueRow(
            label: s.breakIdLabel,
            value: breakView.id,
            mono: true,
            copyable: true,
          ),
          if (breakView.assignedToAdminId != null)
            KeyValueRow(
              label: s.assignedToAdminLabel,
              value: breakView.assignedToAdminId,
              mono: true,
              copyable: true,
            ),
          if (breakView.dedupeKey != null) ...<Widget>[
            KeyValueRow(
              label: s.dedupeKeyLabel,
              value: breakView.dedupeKey,
              mono: true,
              copyable: true,
            ),
            const SizedBox(height: 4),
            Text(
              s.dedupeKeyHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.breakView});

  final BreakView breakView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final DateTime? resolvedAt = breakView.resolvedAt;
    final String? note = breakView.resolutionNote;

    return ReconciliationCard(
      title: breakView.isTerminal
          ? s.resolutionCardClosedTitle
          : s.resolutionCardEarlierTitle,
      icon: Icons.history_edu_outlined,
      tone: breakView.isTerminal ? StatusTone.approve : StatusTone.pending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (note != null) ...<Widget>[
            Text(note, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
          KeyValueRow(
            label: s.closedAtLabel,
            value: resolvedAt == null
                ? null
                : ReconciliationFormats.timestamp(resolvedAt, context.localeTag),
          ),
          KeyValueRow(
            label: s.closedByAdminLabel,
            value: breakView.resolvedByAdminId,
            mono: true,
            copyable: true,
          ),
          KeyValueRow(
            label: s.ledgerCorrectionLabel,
            value: breakView.resolutionTxId ?? s.ledgerCorrectionNone,
            mono: breakView.resolutionTxId != null,
            copyable: breakView.resolutionTxId != null,
          ),
        ],
      ),
    );
  }
}

class _BreakActionsCard extends ConsumerWidget {
  const _BreakActionsCard({
    required this.breakView,
    required this.working,
    required this.onAssign,
    required this.onResolve,
    required this.onCorrectFloat,
  });

  final BreakView breakView;
  final bool working;
  final VoidCallback onAssign;
  final VoidCallback onResolve;
  final VoidCallback onCorrectFloat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool canAct = ref.watch(canActOnReconciliationProvider);

    if (!canAct) {
      return ReconciliationCard(
        title: s.actionsCardTitle,
        icon: Icons.lock_outline,
        child: Text(
          s.actionsNeedRole(
            roles: ReconciliationRoles.describe(ReconciliationRoles.actRoles, s),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (breakView.isTerminal) {
      return ReconciliationCard(
        title: s.actionsCardTitle,
        icon: Icons.check_circle_outline,
        child: Text(
          s.actionsBreakClosedNotice(status: breakView.status.label(s)),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ReconciliationCard(
      title: s.actionsCardTitle,
      icon: Icons.bolt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: working ? null : onAssign,
            icon: const Icon(Icons.person_add_alt),
            label: Text(
              breakView.isAssigned ? s.takeOverBreak : s.assignToMe,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: working ? null : onResolve,
            icon: const Icon(Icons.task_alt),
            label: Text(s.closeTheBreak),
          ),
          if (breakView.canCorrectFloat) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              s.ledgerCorrectionLabel,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              s.ledgerCorrectionExplain,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: working ? null : onCorrectFloat,
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppSemanticColors.of(context).reject.foreground,
                foregroundColor: theme.colorScheme.surface,
              ),
              icon: const Icon(Icons.account_balance),
              label: Text(s.correctTheLedger),
            ),
          ],
          if (working) ...<Widget>[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}
