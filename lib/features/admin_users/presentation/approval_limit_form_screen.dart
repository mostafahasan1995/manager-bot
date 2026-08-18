import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/application/approval_limits_controller.dart';
import 'package:manager_bot/features/admin_users/data/approval_limit.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/money_amount_field.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/permission_denied_view.dart';

/// Sets the approval ceiling that applies from now.
///
/// Not an edit form: the write creates a new VERSION and closes the one in
/// force at the same instant. That is why the button says "Set ceiling" and why
/// the previous values are only ever a starting point.
///
/// Every amount typed here becomes BigInt minor units. No `double` is
/// constructed anywhere on this path - these numbers decide how much a person
/// may release without a second pair of eyes.
class ApprovalLimitFormScreen extends ConsumerStatefulWidget {
  const ApprovalLimitFormScreen({
    required this.adminUserId,
    required this.adminDisplayName,
    this.basedOn,
    super.key,
  });

  final String adminUserId;
  final String adminDisplayName;

  /// The version currently in force, pre-filled so a small change is a small
  /// edit rather than a re-type of every field.
  final ApprovalLimitView? basedOn;

  @override
  ConsumerState<ApprovalLimitFormScreen> createState() =>
      _ApprovalLimitFormScreenState();
}

class _ApprovalLimitFormScreenState
    extends ConsumerState<ApprovalLimitFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _currency;
  late final TextEditingController _single;
  late final TextEditingController _daily;
  late final TextEditingController _secondAbove;

  ApprovalLimitProblem? _problem;

  @override
  void initState() {
    super.initState();
    final ApprovalLimitView? basis = widget.basedOn;
    _currency = TextEditingController(
      text: basis?.currencyCode ?? AppConfig.defaultCurrency,
    );
    _single = TextEditingController(
      text: basis?.maxSingleApproval.toDecimalString() ?? '',
    );
    _daily = TextEditingController(
      text: basis?.maxDailyApproval.toDecimalString() ?? '',
    );
    _secondAbove = TextEditingController(
      text: basis?.secondApprovalAbove?.toDecimalString() ?? '',
    );
  }

  @override
  void dispose() {
    _currency.dispose();
    _single.dispose();
    _daily.dispose();
    _secondAbove.dispose();
    super.dispose();
  }

  String get _currencyCode {
    final String raw = _currency.text.trim().toUpperCase();
    return raw.isEmpty ? AppConfig.defaultCurrency : raw;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final AdminActionGate manageGate = ref.watch(adminManageGateProvider);
    final AdminRole? actorRole = ref.watch(adminActorRoleProvider);
    final bool busy = ref.watch(approvalLimitMutationProvider).isBusy;
    final ApprovalLimitProblem? problem = _problem;

    if (manageGate.isBlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(s.alFormTitle)),
        body: PermissionDeniedView(gate: manageGate, currentRole: actorRole),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.alFormTitle)),
      body: Form(
        key: _formKey,
        onChanged: _revalidate,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: <Widget>[
            Text(
              s.alFormHeading(name: widget.adminDisplayName),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              s.alFormIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _currency,
              enabled: !busy,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                LengthLimitingTextInputFormatter(3),
                const UpperCaseTextFormatter(),
              ],
              decoration: InputDecoration(
                labelText: s.currencyLabel,
                helperText: s.alCurrencyHelper,
                border: const OutlineInputBorder(),
              ),
              validator: (String? raw) => _validateCurrency(raw, s),
            ),
            const SizedBox(height: 16),
            MoneyAmountField(
              controller: _single,
              label: s.alMaxSingleLabel,
              currencyCode: _currencyCode,
              enabled: !busy,
              helperText: s.alMaxSingleHelper,
            ),
            const SizedBox(height: 16),
            MoneyAmountField(
              controller: _daily,
              label: s.alMaxDailyLabel,
              currencyCode: _currencyCode,
              enabled: !busy,
              helperText: s.alMaxDailyHelper,
            ),
            const SizedBox(height: 16),
            MoneyAmountField(
              controller: _secondAbove,
              label: s.alSecondAboveLabel,
              currencyCode: _currencyCode,
              enabled: !busy,
              optional: true,
              textInputAction: TextInputAction.done,
              helperText: s.alSecondAboveHelper,
            ),
            if (problem != null) ...<Widget>[
              const SizedBox(height: 16),
              _ProblemBanner(problem: problem),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : () => unawaited(_submit()),
              icon: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(s.alSetCeilingButton),
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

  String? _validateCurrency(String? raw, AppStrings s) {
    final String value = (raw ?? '').trim();
    if (value.length != 3) {
      return s.alCurrencyThreeLetters(currency: AppConfig.defaultCurrency);
    }
    return null;
  }

  /// Re-runs the coherence check as the operator types, so "single above daily"
  /// is visible before the button is ever pressed.
  void _revalidate() {
    final SetApprovalLimitRequest? request = _build();
    final ApprovalLimitProblem? problem = request?.problem;
    if (problem != _problem) {
      setState(() => _problem = problem);
    }
  }

  /// Null when a field is still unparseable - the form validator reports that.
  SetApprovalLimitRequest? _build() {
    final String currency = _currencyCode;
    final Money? single =
        Money.tryParseUserInput(_single.text.trim(), currency: currency);
    final Money? daily =
        Money.tryParseUserInput(_daily.text.trim(), currency: currency);
    if (single == null || daily == null) {
      return null;
    }
    final String secondRaw = _secondAbove.text.trim();
    final Money? second = secondRaw.isEmpty
        ? null
        : Money.tryParseUserInput(secondRaw, currency: currency);
    if (secondRaw.isNotEmpty && second == null) {
      return null;
    }
    return SetApprovalLimitRequest(
      maxSingleApproval: single,
      maxDailyApproval: daily,
      secondApprovalAbove: second,
    );
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final SetApprovalLimitRequest? request = _build();
    if (request == null) {
      if (mounted) {
        AdminFeedback.refusal(context, context.s.alAmountNotNumber);
      }
      return;
    }
    final ApprovalLimitProblem? problem = request.problem;
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }

    final ApprovalLimitView? saved = await ref
        .read(approvalLimitMutationProvider.notifier)
        .setLimit(widget.adminUserId, request);

    if (!mounted || saved == null) {
      return;
    }
    Navigator.of(context).pop(saved);
  }
}

/// Uppercases as the operator types, so the currency matches what the server
/// stores without a surprise transformation on submit.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.problem});

  final ApprovalLimitProblem problem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors =
        AppSemanticColors.of(context).tone(StatusTone.reject);
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
          Icon(Icons.report_problem_outlined, size: 18, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              problem.message(context.s),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
