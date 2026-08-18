import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/deposits/application/deposit_action_report.dart';
import 'package:manager_bot/features/deposits/application/deposit_detail_controller.dart';
import 'package:manager_bot/features/deposits/application/deposit_permissions.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_action_bar.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_decision_sheets.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_formatting.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_timeline.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/proof_gallery.dart';

/// Everything about one deposit, and every legal action on it.
///
/// Reached by the human `shortId` from the route; the controller resolves that
/// to the UUID the admin API actually addresses rows by.
class DepositDetailScreen extends ConsumerStatefulWidget {
  const DepositDetailScreen({required this.shortId, super.key});

  final String shortId;

  @override
  ConsumerState<DepositDetailScreen> createState() =>
      _DepositDetailScreenState();
}

class _DepositDetailScreenState extends ConsumerState<DepositDetailScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // The claim countdown is only meaningful if it actually counts down.
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final DepositPermissions permissions = ref.watch(depositPermissionsProvider);
    final AsyncValue<DepositDetailState> detail =
        ref.watch(depositDetailProvider(widget.shortId));

    if (!permissions.canViewQueue) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.shortId)),
        body: PermissionDeniedView(
          title: s.detailNoAccessTitle,
          message: s.detailNoAccessMessage,
          role: permissions.role,
        ),
      );
    }

    final DepositDetailState? loaded = detail.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.deposit.shortId ?? widget.shortId),
        actions: <Widget>[
          IconButton(
            tooltip: s.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(_refresh()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget content = AsyncValueView<DepositDetailState>(
              value: detail,
              onRetry: () =>
                  ref.invalidate(depositDetailProvider(widget.shortId)),
              loadingLabel: s.detailLoadingLabel(shortId: widget.shortId),
              builder: (BuildContext context, DepositDetailState state) =>
                  _DetailBody(
                // The family key is the route's shortId, NOT the deposit's -
                // they can differ in case and would address two providers.
                providerKey: widget.shortId,
                state: state,
                permissions: permissions,
                now: _now,
              ),
            );

            if (loaded != null) {
              return content;
            }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: loaded == null
          ? null
          : DepositActionBar(
              status: loaded.deposit.status,
              pendingAction: loaded.pendingAction,
              options: DepositActionPolicy.resolve(
                status: loaded.deposit.status,
                role: permissions.role,
                now: _now,
                strings: s,
                currentAdminUserId: permissions.adminUserId,
                decidedByAdminId: loaded.deposit.decidedByAdminId,
                reviewStartedAt: loaded.deposit.reviewStartedAt,
              ),
              onSelected: (DepositAction action) =>
                  unawaited(_handle(action, loaded.deposit)),
            ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _now = DateTime.now());
    await ref.read(depositDetailProvider(widget.shortId).notifier).refresh();
  }

  /// Confirms, fires, then reports - never optimistically.
  Future<void> _handle(DepositAction action, AdminDepositView deposit) async {
    final AppStrings s = context.s;
    final DepositDetailController controller =
        ref.read(depositDetailProvider(widget.shortId).notifier);

    DepositActionReport? report;
    // Each case gets its own block: every case of a switch shares one scope in
    // Dart, so two cases could not otherwise both declare a local `request`.
    switch (action) {
      case DepositAction.claim:
        {
          // Taking over a claim that went stale removes it from another
          // reviewer, so that case confirms; taking a free deposit does not.
          final bool stealing = deposit.reviewStartedAt != null &&
              !_holdsClaim(deposit) &&
              !DepositActionPolicy.claimIsFresh(deposit.reviewStartedAt, _now);
          if (stealing) {
            final bool confirmed = await _confirm(
              title: s.claimTakeOverTitle,
              message: s.claimTakeOverMessage,
              confirmLabel: s.claimTakeOverConfirm,
              tone: StatusTone.info,
            );
            if (!confirmed) {
              return;
            }
          }
          report = await controller.claim();
        }

      case DepositAction.release:
        {
          final bool confirmed = await _confirm(
            title: s.releaseConfirmTitle(shortId: deposit.shortId),
            message: s.releaseConfirmMessage,
            confirmLabel: s.releaseConfirmButton,
          );
          if (!confirmed) {
            return;
          }
          report = await controller.release();
        }

      case DepositAction.approve:
        {
          final ApproveDepositRequest? request =
              await ApproveDepositSheet.show(context, deposit: deposit);
          if (request == null) {
            return;
          }
          report = await controller.approve(
            verifiedAmount: request.verifiedAmount,
            note: request.note,
          );
        }

      case DepositAction.reject:
        {
          final RejectDepositRequest? request =
              await RejectDepositSheet.show(context, deposit: deposit);
          if (request == null) {
            return;
          }
          report = await controller.reject(
            code: request.code,
            note: request.note,
          );
        }

      case DepositAction.retryCredit:
        {
          final ConfirmActionResult? confirmation =
              await ConfirmActionSheet.show(
            context,
            title: s.retryCreditConfirmTitle,
            message: s.retryCreditConfirmMessage(
              // Money keeps its own Western-digit formatting.
              amount: deposit.credited?.format() ?? deposit.claimed.format(),
            ),
            confirmLabel: s.retryCreditConfirmButton,
            cancelLabel: s.cancel,
            tone: StatusTone.failed,
            withNote: true,
            noteLabel: s.retryCreditReasonLabel,
            noteHint: s.retryCreditReasonHint,
          );
          if (!(confirmation?.confirmed ?? false)) {
            return;
          }
          report = await controller.retryCredit(reason: confirmation?.note);
        }
    }

    if (!mounted) {
      return;
    }
    _showReport(report);
  }

  bool _holdsClaim(AdminDepositView deposit) =>
      ref.read(depositPermissionsProvider).holdsClaim(deposit.decidedByAdminId);

  Future<bool> _confirm({
    required String title,
    required String confirmLabel,
    String? message,
    StatusTone tone = StatusTone.neutral,
  }) async {
    final ConfirmActionResult? result = await ConfirmActionSheet.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: context.s.cancel,
      tone: tone,
    );
    return result?.confirmed ?? false;
  }

  /// Nullable so the caller never has to prove definite assignment across an
  /// exhaustive switch.
  void _showReport(DepositActionReport? report) {
    if (report == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(report.message),
        duration: report.isBenign
            ? const Duration(seconds: 4)
            : const Duration(seconds: 7),
      ),
    );
  }
}

/// The scrollable body of the detail screen.
class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.providerKey,
    required this.state,
    required this.permissions,
    required this.now,
  });

  /// The exact argument [depositDetailProvider] was watched with.
  final String providerKey;

  final DepositDetailState state;
  final DepositPermissions permissions;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminDepositView deposit = state.deposit;
    final DepositActionReport? report = state.lastReport;
    final String? stale = state.staleWarning;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        if (report != null)
          _ReportBanner(
            report: report,
            onDismiss: () => ref
                .read(depositDetailProvider(providerKey).notifier)
                .clearReport(),
          ),
        if (stale != null) _StaleBanner(message: stale),
        _Headline(deposit: deposit, now: now),
        const SizedBox(height: 16),
        _ClaimBanner(deposit: deposit, permissions: permissions, now: now),
        _Section(
          title: s.sectionAmounts,
          child: Column(
            children: <Widget>[
              _MoneyRow(label: s.amountPlayerClaimed, value: deposit.claimed),
              _MoneyRow(
                label: s.amountVerifiedByAdmin,
                value: deposit.verified,
                hint: deposit.verified == null ? s.amountNotVerifiedYet : null,
              ),
              _MoneyRow(label: s.amountFee, value: deposit.fee),
              _MoneyRow(
                label: s.amountCreditedToPlayer,
                value: deposit.credited,
                hint: deposit.credited == null ? s.amountNotCreditedYet : null,
                emphasise: true,
              ),
            ],
          ),
        ),
        _Section(
          title: s.playerLabel,
          child: Column(
            children: <Widget>[
              _InfoRow(
                label: s.playerTelegram,
                value: deposit.playerTelegramUsername == null
                    ? s.emptyValueDash
                    : deposit.playerLabel,
              ),
              // 64-bit id: shown and copied as a STRING, never narrowed.
              _InfoRow(
                label: s.telegramIdLabel,
                value: deposit.playerTelegramUserIdString ?? s.emptyValueDash,
                mono: true,
                copyable: true,
              ),
              _InfoRow(
                label: s.playerIdLabel,
                value: deposit.playerId,
                mono: true,
                copyable: true,
              ),
            ],
          ),
        ),
        _Section(
          title: s.sectionDestination,
          child: _DestinationBlock(deposit: deposit),
        ),
        _Section(
          title: s.sectionSubmitted,
          child: Column(
            children: <Widget>[
              _InfoRow(
                label: s.externalReferenceLabel,
                value: deposit.externalReference ?? s.emptyValueDash,
                mono: deposit.externalReference != null,
                copyable: deposit.externalReference != null,
                hint: deposit.externalReference == null &&
                        (deposit.destination?.requiresReference ?? false)
                    ? s.externalReferenceMissingHint
                    : null,
              ),
              _InfoRow(
                label: s.senderAccountLabel,
                value: deposit.senderAccount ?? s.emptyValueDash,
                mono: deposit.senderAccount != null,
                copyable: deposit.senderAccount != null,
              ),
            ],
          ),
        ),
        if (deposit.hasRiskFlags)
          _Section(
            title: s.riskSignals,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RiskFlagStrip(
                  flags: deposit.riskFlags
                      .map((String flag) => RiskFlags.label(flag, s))
                      .toList(growable: false),
                  dense: false,
                ),
                const SizedBox(height: 8),
                Text(
                  s.riskFlagsDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        _Section(
          title: s.sectionProof(count: deposit.proofs.length),
          child: ProofGallery(depositId: deposit.id, proofs: deposit.proofs),
        ),
        _Section(
          title: s.sectionHistory,
          child: DepositTimeline(deposit: deposit, now: now),
        ),
        _Section(
          title: s.sectionTechnical,
          child: Column(
            children: <Widget>[
              _InfoRow(
                label: s.technicalDepositId,
                value: deposit.id,
                mono: true,
                copyable: true,
              ),
              _InfoRow(
                label: s.technicalPaymentMethodId,
                value: deposit.paymentMethodId,
                mono: true,
                copyable: true,
              ),
              _InfoRow(
                label: s.technicalCreditAttempts,
                value: '${deposit.creditAttempts}',
                mono: true,
              ),
              _InfoRow(
                label: s.technicalCreditKeyEpoch,
                value: '${deposit.creditKeyEpoch}',
                mono: true,
              ),
              if (deposit.creditVerifiedBy != null)
                _InfoRow(
                  label: s.technicalCreditVerifiedBy,
                  value: deposit.creditVerifiedBy!.label(s),
                ),
              if (deposit.decidedByAdminId != null)
                _InfoRow(
                  label: s.technicalDecidedByAdmin,
                  value: deposit.decidedByAdminId!,
                  mono: true,
                  copyable: true,
                ),
              if (deposit.secondApproverAdminId != null)
                _InfoRow(
                  label: s.technicalSecondApprover,
                  value: deposit.secondApproverAdminId!,
                  mono: true,
                  copyable: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Amount, status and the headline facts a reviewer reads first.
class _Headline extends StatelessWidget {
  const _Headline({required this.deposit, required this.now});

  final AdminDepositView deposit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: MoneyText(deposit.claimed, emphasise: true)),
            StatusChip(
              label: deposit.status.label(s),
              tone: deposit.status.tone,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.headlineCreatedAgo(
            shortId: deposit.shortId,
            age: DepositFormat.age(deposit.createdAt, s, now: now),
          ),
          style: AppTheme.monoStyle(context),
        ),
        if (deposit.status == DepositStatus.pendingSecondApproval) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            s.pendingSecondApprovalNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.of(context).pending.foreground,
            ),
          ),
        ],
      ],
    );
  }
}

/// Who holds the 10-minute soft claim, and for how much longer.
class _ClaimBanner extends StatelessWidget {
  const _ClaimBanner({
    required this.deposit,
    required this.permissions,
    required this.now,
  });

  final AdminDepositView deposit;
  final DepositPermissions permissions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final DateTime? started = deposit.reviewStartedAt;
    if (started == null) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool mine = permissions.holdsClaim(deposit.decidedByAdminId);
    final int? minutes =
        DepositActionPolicy.claimMinutesRemaining(started, now);
    final bool stale = minutes == null;

    final String text;
    if (mine && !stale) {
      text = s.claimHeldByYou(minutes: minutes);
    } else if (mine) {
      text = s.claimExpiredMine;
    } else if (stale) {
      text = s.claimStaleOther;
    } else {
      text = s.claimHeldByOther(minutes: minutes);
    }

    final SemanticTone tone = AppSemanticColors.of(context)
        .tone(stale ? StatusTone.neutral : StatusTone.info);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lock_clock, size: 18, color: tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The outcome of the last action, kept on screen until dismissed.
class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.report, required this.onDismiss});

  final DepositActionReport report;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone tone = AppSemanticColors.of(context).tone(report.tone);
    final String? correlationId = report.correlationId;
    // Local copy so the sealed-type check promotes; a public widget field
    // would not.
    final DepositActionReport current = report;
    final String? detail =
        current is DepositActionSucceeded ? current.detail : null;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            report.isBenign ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: tone.foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  report.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: tone.foreground),
                ),
                if (detail != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(detail, style: AppTheme.monoStyle(context)),
                ],
                if (correlationId != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    // The id itself is never translated.
                    context.s.correlationIdLine(correlationId: correlationId),
                    style: AppTheme.monoStyle(context),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.sync_problem_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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

/// The destination the player was instructed to pay into.
class _DestinationBlock extends StatelessWidget {
  const _DestinationBlock({required this.deposit});

  final AdminDepositView deposit;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final DepositDestinationView? destination = deposit.destination;
    if (destination == null) {
      return Text(
        s.destinationMissing,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final String? instructions = destination.instructions;
    return Column(
      children: <Widget>[
        _InfoRow(label: s.paymentMethodLabel, value: destination.methodName),
        // The machine code (e.g. SYRIATEL_CASH) is never translated.
        _InfoRow(
          label: s.destinationMethodCode,
          value: destination.methodCode,
          mono: true,
        ),
        _InfoRow(
          label: s.destinationLabel,
          value: destination.label ?? s.emptyValueDash,
        ),
        _InfoRow(
          label: s.accountLabel,
          value: destination.accountIdentifier ?? s.emptyValueDash,
          mono: destination.accountIdentifier != null,
          copyable: destination.accountIdentifier != null,
        ),
        _InfoRow(
          label: s.accountHolderLabel,
          value: destination.accountHolder ?? s.emptyValueDash,
        ),
        _InfoRow(
          label: s.referenceRequiredLabel,
          value: destination.requiresReference ? s.yes : s.no,
        ),
        if (instructions != null && instructions.trim().isNotEmpty)
          _InfoRow(label: s.instructionsLabel, value: instructions),
      ],
    );
  }
}

/// A titled block of detail rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            // NOT upper-cased: Arabic has no case, so the two languages would
            // otherwise read as two different designs.
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.hint,
    this.emphasise = false,
  });

  final String label;
  final Money? value;
  final String? hint;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? note = hint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(
            value,
            style: emphasise
                ? AppTheme.moneyStyle(context)
                : theme.textTheme.bodyMedium
                    ?.copyWith(fontFeatures: AppTheme.numericFeatures),
          ),
        ],
      ),
    );
  }
}

/// A label/value row, optionally monospaced and copy-on-tap.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.hint,
    this.mono = false,
    this.copyable = false,
  });

  final String label;
  final String value;
  final String? hint;
  final bool mono;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? note = hint;

    final Widget valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: mono
          ? AppTheme.monoStyle(context)
          : theme.textTheme.bodyMedium,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (copyable && value != context.s.emptyValueDash)
                  InkWell(
                    onTap: () => unawaited(_copy(context)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: valueText,
                    ),
                  )
                else
                  valueText,
                if (note != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String confirmation = context.s.copiedToClipboard(label: label);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }
}
