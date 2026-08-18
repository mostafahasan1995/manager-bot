import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// What the admin confirmed in [ApproveDepositSheet].
class ApproveDepositRequest {
  const ApproveDepositRequest({this.verifiedAmount, this.note});

  /// Null means "I verified exactly what the player claimed", which the backend
  /// records as `claimAcceptedVerbatim: true`. It is a deliberate statement,
  /// not a missing value.
  final Money? verifiedAmount;

  final String? note;
}

/// The approval confirmation: what will move, and how much.
///
/// Approving posts ledger T1 and enqueues the credit, so this is the last stop
/// before money moves. It also states plainly that the server may answer
/// "awaiting second approval" instead - whether four eyes are needed depends on
/// the admin's approval limits, which no client can know in advance.
class ApproveDepositSheet extends StatefulWidget {
  const ApproveDepositSheet({required this.deposit, super.key});

  static Future<ApproveDepositRequest?> show(
    BuildContext context, {
    required AdminDepositView deposit,
  }) {
    return showModalBottomSheet<ApproveDepositRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ApproveDepositSheet(deposit: deposit),
      ),
    );
  }

  final AdminDepositView deposit;

  @override
  State<ApproveDepositSheet> createState() => _ApproveDepositSheetState();
}

class _ApproveDepositSheetState extends State<ApproveDepositSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  bool _overrideAmount = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.deposit.claimed.toDecimalString(),
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The amount that will actually be verified: the typed override, or the
  /// claim when the admin accepts it verbatim.
  Money? get _effectiveAmount {
    if (!_overrideAmount) {
      return widget.deposit.claimed;
    }
    return Money.tryParseUserInput(
      _amount.text,
      currency: widget.deposit.claimed.currency,
    );
  }

  /// What the player receives: verified minus the method's fee.
  Money? get _net {
    final Money? verified = _effectiveAmount;
    if (verified == null) {
      return null;
    }
    return verified - widget.deposit.fee;
  }

  /// Mirrors the server's 422 VERIFIED_AMOUNT_REQUIRED rule so an impossible
  /// approval is refused before it is sent.
  String? _blockingProblem(AppStrings s) {
    final Money? verified = _effectiveAmount;
    if (verified == null) {
      return s.approveErrorInvalidAmount;
    }
    if (!verified.isPositive) {
      return s.approveErrorNotPositive;
    }
    final Money? net = _net;
    if (net == null || !net.isPositive) {
      // The fee keeps Money's own Western-digit formatting.
      return s.approveErrorBelowFee(fee: widget.deposit.fee.format());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final AdminDepositView deposit = widget.deposit;
    final String? problem = _blockingProblem(s);
    final bool isSecondApproval =
        deposit.status == DepositStatus.pendingSecondApproval;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              isSecondApproval
                  ? s.approveSheetSecondTitle
                  : s.approveSheetTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              deposit.shortId,
              style: AppTheme.monoStyle(context),
            ),
            const SizedBox(height: 16),
            _AmountBreakdown(
              claimed: deposit.claimed,
              verified: _effectiveAmount,
              fee: deposit.fee,
              net: _net,
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _overrideAmount,
              onChanged: (bool value) => setState(() => _overrideAmount = value),
              contentPadding: EdgeInsets.zero,
              title: Text(s.approveOverrideToggle),
              subtitle: Text(
                _overrideAmount ? s.approveOverrideOn : s.approveOverrideOff,
              ),
            ),
            if (_overrideAmount) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: s.verifiedAmountLabel,
                  // The currency code is never translated.
                  suffixText: deposit.claimed.currency,
                  helperText: s.atMostTwoDecimals,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.noteOptionalLabel,
                hintText: s.approveNoteHint,
              ),
            ),
            if (isSecondApproval)
              _Advisory(
                icon: Icons.groups_outlined,
                text: s.approveAdvisorySecondApproval,
              )
            else
              _Advisory(
                icon: Icons.info_outline,
                text: s.approveAdvisoryThreshold,
              ),
            if (problem != null) ...<Widget>[
              const SizedBox(height: 12),
              _Advisory(
                icon: Icons.error_outline,
                text: problem,
                isError: true,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: problem != null ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppSemanticColors.of(context).approve.foreground,
                foregroundColor: theme.colorScheme.surface,
              ),
              child: Text(
                isSecondApproval
                    ? s.approveSecondButton
                    : s.approveButton(
                        amount:
                            (_effectiveAmount ?? deposit.claimed).format(),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final String note = _note.text.trim();
    Navigator.of(context).pop(
      ApproveDepositRequest(
        // Only send the amount when the admin actually corrected it: omitting
        // it is the explicit "claim accepted verbatim" signal.
        verifiedAmount: _overrideAmount ? _effectiveAmount : null,
        note: note.isEmpty ? null : note,
      ),
    );
  }
}

/// What the admin chose in [RejectDepositSheet].
class RejectDepositRequest {
  const RejectDepositRequest({required this.code, this.note});

  final RejectionCode code;
  final String? note;
}

/// The rejection confirmation.
///
/// The code is required by the backend because a report can count a code; a
/// free-text note nobody can aggregate is a comment, not a reason.
class RejectDepositSheet extends StatefulWidget {
  const RejectDepositSheet({required this.deposit, super.key});

  static Future<RejectDepositRequest?> show(
    BuildContext context, {
    required AdminDepositView deposit,
  }) {
    return showModalBottomSheet<RejectDepositRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: RejectDepositSheet(deposit: deposit),
      ),
    );
  }

  final AdminDepositView deposit;

  @override
  State<RejectDepositSheet> createState() => _RejectDepositSheetState();
}

class _RejectDepositSheetState extends State<RejectDepositSheet> {
  final TextEditingController _note = TextEditingController();
  RejectionCode? _code;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final RejectionCode? code = _code;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(s.rejectSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              s.rejectSheetSubtitle(
                shortId: widget.deposit.shortId,
                amount: widget.deposit.claimed.format(),
              ),
              style: AppTheme.monoStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              s.rejectSheetNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(s.rejectReasonLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RejectionCode.values
                  .map(
                    (RejectionCode value) => ChoiceChip(
                      label: Text(value.label(s)),
                      selected: _code == value,
                      onSelected: (bool selected) => setState(
                        () => _code = selected ? value : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.noteOptionalLabel,
                hintText: s.rejectNoteHint,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: code == null
                  ? null
                  : () {
                      final String note = _note.text.trim();
                      Navigator.of(context).pop(
                        RejectDepositRequest(
                          code: code,
                          note: note.isEmpty ? null : note,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppSemanticColors.of(context).reject.foreground,
                foregroundColor: theme.colorScheme.surface,
              ),
              child: Text(
                code == null
                    ? s.rejectChooseReason
                    : s.rejectButton(reason: code.label(s)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Claimed / verified / fee / net, so the consequence of approving is visible
/// before it is irreversible.
class _AmountBreakdown extends StatelessWidget {
  const _AmountBreakdown({
    required this.claimed,
    required this.verified,
    required this.fee,
    required this.net,
  });

  final Money claimed;
  final Money? verified;
  final Money fee;
  final Money? net;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool corrected = verified != null && verified != claimed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          _AmountLine(label: s.amountPlayerClaimed, value: claimed),
          if (corrected)
            _AmountLine(
              label: s.amountYouVerified,
              value: verified,
              emphasise: true,
            ),
          _AmountLine(label: s.amountFee, value: fee),
          const Divider(height: 18),
          _AmountLine(
            label: s.amountPlayerReceives,
            value: net,
            emphasise: true,
          ),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final Money? value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emphasise ? null : theme.colorScheme.onSurfaceVariant,
              fontWeight: emphasise ? FontWeight.w600 : null,
            ),
          ),
          MoneyText(
            value,
            style: emphasise
                ? AppTheme.moneyStyle(context)
                : theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: AppTheme.numericFeatures,
                  ),
          ),
        ],
      ),
    );
  }
}

/// A short inline note or warning.
class _Advisory extends StatelessWidget {
  const _Advisory({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
