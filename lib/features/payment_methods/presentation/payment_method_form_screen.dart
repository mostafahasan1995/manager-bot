import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_actions.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_providers.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_requests.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/mutation_feedback.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/section_card.dart';

/// Create or edit a payment method.
///
/// EDIT MODE SENDS ONLY WHAT CHANGED. `code`, `rail` and `currencyCode` are
/// absent from the update DTO by design, and `forbidNonWhitelisted` turns any
/// stray key into a 400 - so they are rendered read-only rather than disabled
/// inputs that could still be serialised by accident.
///
/// Every amount goes through [Money.parseUserInput]: exact BigInt minor units,
/// never a `double`, and sent back as a major-unit decimal string with at most
/// two decimals (a third would be a 400 `INVALID_AMOUNT`).
class PaymentMethodFormScreen extends ConsumerStatefulWidget {
  const PaymentMethodFormScreen({this.method, super.key});

  /// Null creates a new method; non-null edits that one.
  final AdminPaymentMethodView? method;

  @override
  ConsumerState<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState
    extends ConsumerState<PaymentMethodFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _code;
  late final TextEditingController _displayName;
  late final TextEditingController _currency;
  late final TextEditingController _minAmount;
  late final TextEditingController _maxAmount;
  late final TextEditingController _feeFixed;
  late final TextEditingController _feeBps;
  late final TextEditingController _sortOrder;
  late final TextEditingController _referencePattern;
  late final TextEditingController _instructions;
  late final TextEditingController _referenceProbe;

  late PaymentRail _rail;
  late VerificationMode _verificationMode;
  late bool _requiresReference;
  late bool _isActive;

  Map<String, String> _serverFieldErrors = <String, String>{};
  List<FieldIssue> _localIssues = <FieldIssue>[];

  bool get _isEditing => widget.method != null;

  @override
  void initState() {
    super.initState();
    final AdminPaymentMethodView? method = widget.method;
    _code = TextEditingController(text: method?.code ?? '');
    _displayName = TextEditingController(text: method?.displayName ?? '');
    _currency = TextEditingController(
      text: method?.currencyCode ?? Money.defaultCurrency,
    );
    _minAmount = TextEditingController(
      text: method?.minAmount.toDecimalString() ?? '',
    );
    _maxAmount = TextEditingController(
      text: method?.maxAmount.toDecimalString() ?? '',
    );
    _feeFixed = TextEditingController(
      text: method?.feeFixed.toDecimalString() ?? '',
    );
    _feeBps = TextEditingController(text: '${method?.feeBps ?? 0}');
    _sortOrder = TextEditingController(text: '${method?.sortOrder ?? 0}');
    _referencePattern =
        TextEditingController(text: method?.referencePattern ?? '');
    _instructions = TextEditingController(text: method?.instructions ?? '');
    _referenceProbe = TextEditingController();

    _rail = method?.rail ?? PaymentRail.bankTransfer;
    _verificationMode = method?.verificationMode ?? VerificationMode.manualProof;
    _requiresReference = method?.requiresReference ?? false;
    _isActive = method?.isActive ?? true;

    for (final TextEditingController controller in <TextEditingController>[
      _minAmount,
      _maxAmount,
      _feeFixed,
      _feeBps,
      _referencePattern,
      _referenceProbe,
    ]) {
      controller.addListener(_onLivePreviewChanged);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _minAmount,
      _maxAmount,
      _feeFixed,
      _feeBps,
      _referencePattern,
      _referenceProbe,
    ]) {
      controller.removeListener(_onLivePreviewChanged);
    }
    _code.dispose();
    _displayName.dispose();
    _currency.dispose();
    _minAmount.dispose();
    _maxAmount.dispose();
    _feeFixed.dispose();
    _feeBps.dispose();
    _sortOrder.dispose();
    _referencePattern.dispose();
    _instructions.dispose();
    _referenceProbe.dispose();
    super.dispose();
  }

  void _onLivePreviewChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final bool canManage = ref.watch(canManagePaymentMethodsProvider);
    final bool isBusy = ref
        .watch(paymentMethodActionsProvider)
        .isBusy(widget.method?.id ?? PaymentMethodActionState.createKey);
    final String title =
        _isEditing ? s.pmFormEditTitle : s.pmFormCreateTitle;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PermissionDeniedView(
          role: ref.watch(currentRoleProvider),
          allowedRoles: PaymentMethodRoles.managers,
          title: s.pmManagersDeniedTitle,
          message: s.pmManagersDeniedMessage,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: isBusy
                ? null
                : () async {
                    await _save();
                  },
            child: Text(isBusy ? s.savingButton : s.saveButton),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 48),
          children: <Widget>[
            if (_localIssues.isNotEmpty)
              InfoBanner(
                title: s.pmFixBeforeSaving,
                tone: StatusTone.failed,
                icon: Icons.error_outline,
                bullets: _localIssues
                    .map(
                      (FieldIssue issue) =>
                          PaymentMethodRules.describeIssue(issue, s),
                    )
                    .toList(growable: false),
              ),
            _identitySection(s),
            _limitsSection(s),
            _referenceSection(s),
            _instructionsSection(s),
          ],
        ),
      ),
    );
  }

  Widget _identitySection(AppStrings s) {
    final AdminPaymentMethodView? method = widget.method;
    return SectionCard(
      title: s.pmIdentitySection,
      subtitle: _isEditing
          ? s.pmIdentitySubtitleEdit
          : s.pmIdentitySubtitleCreate,
      children: <Widget>[
        if (_isEditing && method != null) ...<Widget>[
          DetailRow.text(
            label: s.pmMachineCodeLabel,
            value: method.code,
            monospace: true,
          ),
          DetailRow.text(label: s.pmRailLabel, value: method.rail.label(s)),
          DetailRow.text(
            label: s.currencyLabel,
            value: method.currencyCode,
          ),
        ] else ...<Widget>[
          TextFormField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(PaymentMethodRules.codeMaxLength),
            ],
            decoration: _decoration(
              'code',
              label: s.pmMachineCodeLabel,
              helper: s.pmMachineCodeHelper,
            ),
            validator: (String? value) =>
                PaymentMethodRules.validateCode(value ?? '', s)?.message,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<PaymentRail>(
            initialValue: _rail,
            decoration: _decoration(
              'rail',
              label: s.pmRailLabel,
              helper: s.pmRailHelper,
            ),
            items: <DropdownMenuItem<PaymentRail>>[
              for (final PaymentRail rail in PaymentRail.creatable)
                DropdownMenuItem<PaymentRail>(
                  value: rail,
                  child: Text(rail.label(s)),
                ),
            ],
            onChanged: (PaymentRail? value) {
              if (value != null) {
                setState(() => _rail = value);
              }
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _currency,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: _decoration(
              'currencyCode',
              label: s.currencyLabel,
              // NSP is a currency CODE, never translated.
              helper: s.pmCurrencyHelper(currency: Money.defaultCurrency),
            ),
            validator: (String? value) =>
                PaymentMethodRules.validateCurrency(value ?? '', s)?.message,
          ),
          const SizedBox(height: 14),
          _proofFieldPreview(s),
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _displayName,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(
              PaymentMethodRules.displayNameMaxLength,
            ),
          ],
          decoration: _decoration(
            'displayName',
            label: s.displayNameLabel,
            helper: s.pmDisplayNameHelper,
          ),
          validator: (String? value) =>
              PaymentMethodRules.validateDisplayName(value ?? '', s)?.message,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<VerificationMode>(
          initialValue: _verificationMode,
          decoration: _decoration(
            'verificationMode',
            label: s.pmVerificationModeLabel,
            helper: s.pmVerificationModeHelper,
          ),
          items: <DropdownMenuItem<VerificationMode>>[
            for (final VerificationMode mode in VerificationMode.values)
              DropdownMenuItem<VerificationMode>(
                value: mode,
                child: Text(mode.label(s)),
              ),
          ],
          onChanged: (VerificationMode? value) {
            if (value != null) {
              setState(() => _verificationMode = value);
            }
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _sortOrder,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            'sortOrder',
            label: s.pmSortOrderLabel,
            helper: s.pmSortOrderHelper,
          ),
          validator: (String? value) => PaymentMethodRules.validateIntegerInput(
            value ?? '',
            s,
            required: true,
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          onChanged: (bool value) => setState(() => _isActive = value),
          // A METHOD is مفعّلة, not the destination's مفعّل.
          title: Text(s.pmStatusActive),
          subtitle: Text(
            _isActive ? s.pmActiveSwitchOn : s.pmActiveSwitchOff,
          ),
        ),
      ],
    );
  }

  Widget _proofFieldPreview(AppStrings s) {
    final List<RailProofField> fields = _rail.declaredProofFields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.pmProofFieldsPreview,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final RailProofField field in fields)
              Chip(
                label: Text(field.label(s)),
                avatar: Icon(
                  field.machineEnforced
                      ? Icons.verified_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _limitsSection(AppStrings s) {
    final String currency = _currencyCode();
    final Money? minAmount = _parseMoney(_minAmount.text, currency);
    final Money? maxAmount = _parseMoney(_maxAmount.text, currency);
    final Money? feeFixed = _parseMoney(_feeFixed.text, currency);
    final int? feeBps = int.tryParse(_feeBps.text.trim());

    return SectionCard(
      title: s.pmLimitsSection,
      subtitle: s.pmLimitsFormSubtitle,
      children: <Widget>[
        TextFormField(
          controller: _minAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(
            'minAmount',
            label: s.pmMinAmountLabel,
            helper: _moneyHelper(minAmount, s.pmMinAmountHelper, s),
          ),
          validator: (String? value) => PaymentMethodRules.validateMoneyInput(
            value ?? '',
            s,
            required: !_isEditing,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _maxAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(
            'maxAmount',
            label: s.pmMaxAmountLabel,
            helper: _moneyHelper(maxAmount, s.pmMaxAmountHelper, s),
          ),
          validator: (String? value) => PaymentMethodRules.validateMoneyInput(
            value ?? '',
            s,
            required: !_isEditing,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _feeFixed,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(
            'feeFixed',
            label: s.pmFixedFeeLabel,
            helper: _moneyHelper(feeFixed, s.pmFeeFixedHelper, s),
          ),
          validator: (String? value) => PaymentMethodRules.validateMoneyInput(
            value ?? '',
            s,
            required: false,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _feeBps,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            'feeBps',
            label: s.pmFeeBpsLabel,
            helper: s.pmFeeBpsHelper,
          ),
          validator: (String? value) => PaymentMethodRules.validateIntegerInput(
            value ?? '',
            s,
            required: true,
            min: 0,
            max: PaymentMethodRules.feeBpsMax,
          ),
        ),
        if (minAmount != null && feeFixed != null && feeBps != null) ...<Widget>[
          const Divider(height: 24),
          _creditPreview(
            minAmount: minAmount,
            feeFixed: feeFixed,
            feeBps: feeBps,
            s: s,
          ),
        ],
      ],
    );
  }

  Widget _creditPreview({
    required Money minAmount,
    required Money feeFixed,
    required int feeBps,
    required AppStrings s,
  }) {
    final Money fee = AdminPaymentMethodView.computeFee(
      amount: minAmount,
      feeFixed: feeFixed,
      feeBps: feeBps,
    );
    final Money credited = minAmount - fee;
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Three already-formatted amounts; the catalogue never sees a Money.
        Text(
          s.pmCreditPreview(
            min: minAmount.format(),
            fee: fee.format(),
            credited: credited.format(),
          ),
          style: theme.textTheme.bodySmall,
        ),
        if (!credited.isPositive) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            s.pmCreditsNothingWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.of(context).reject.foreground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _referenceSection(AppStrings s) {
    final String pattern = _referencePattern.text;
    final String? warning =
        PaymentMethodRules.referencePatternWarning(pattern, s);
    final String probe = _referenceProbe.text;
    final bool? probeMatches = probe.isEmpty
        ? null
        : PaymentMethodRules.matchesReferencePattern(pattern, probe);
    final bool railDemandsReference =
        _rail.declaredProofFields.contains(RailProofField.reference);

    return SectionCard(
      title: s.referenceLabel,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _requiresReference,
          onChanged: (bool value) => setState(() => _requiresReference = value),
          title: Text(s.pmRequiresReferenceSwitch),
          subtitle: Text(
            railDemandsReference
                ? s.pmRequiresReferenceOnRail(rail: _rail.label(s))
                : s.pmRequiresReferenceHint,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referencePattern,
          decoration: _decoration(
            'referencePattern',
            label: s.pmReferencePatternFieldLabel,
            helper: s.pmReferencePatternFieldHelper,
          ),
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(
              PaymentMethodRules.referencePatternMaxLength,
            ),
          ],
          validator: (String? value) =>
              PaymentMethodRules.validateReferencePattern(value ?? '', s)
                  ?.message,
        ),
        if (warning != null) ...<Widget>[
          const SizedBox(height: 10),
          InfoBanner(
            title: s.pmPatternMayNotWorkTitle,
            tone: StatusTone.pending,
            icon: Icons.code_off,
            message: warning,
            margin: EdgeInsets.zero,
          ),
        ],
        if (pattern.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          TextField(
            controller: _referenceProbe,
            decoration: InputDecoration(
              labelText: s.pmProbeLabel,
              helperMaxLines: 3,
              helperText: switch (probeMatches) {
                null => s.pmProbeIdleHelper,
                true => s.pmProbeAccepted,
                false => s.pmProbeRejected,
              },
            ),
          ),
        ],
        if (_isEditing) ...<Widget>[
          const SizedBox(height: 10),
          InfoBanner(
            title: s.pmPatternCannotClearTitle,
            tone: StatusTone.neutral,
            icon: Icons.info_outline,
            message: s.pmPatternCannotClearMessage,
            margin: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _instructionsSection(AppStrings s) {
    return SectionCard(
      title: s.pmInstructionsSection,
      subtitle: s.pmInstructionsFormSubtitle,
      children: <Widget>[
        TextFormField(
          controller: _instructions,
          minLines: 3,
          maxLines: 8,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(
              PaymentMethodRules.instructionsMaxLength,
            ),
          ],
          decoration: _decoration(
            'instructions',
            label: s.instructionsLabel,
            helper: s.pmInstructionsFieldHelper,
          ),
          validator: (String? value) =>
              PaymentMethodRules.validateInstructions(value ?? '', s)?.message,
        ),
      ],
    );
  }

  InputDecoration _decoration(
    String field, {
    required String label,
    String? helper,
  }) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 4,
        errorText: _serverFieldErrors[field],
        errorMaxLines: 4,
      );

  String _currencyCode() {
    final AdminPaymentMethodView? method = widget.method;
    if (method != null) {
      return method.currencyCode;
    }
    final String typed = PaymentMethodRules.normalizeCurrency(_currency.text);
    return typed.length == 3 ? typed : Money.defaultCurrency;
  }

  static Money? _parseMoney(String raw, String currency) =>
      Money.tryParseUserInput(raw, currency: currency);

  /// Echoes the EXACT decimal string that will go on the wire, ahead of the
  /// field's own rule. The amount is never localised.
  static String _moneyHelper(Money? parsed, String rule, AppStrings s) =>
      parsed == null
          ? rule
          : '${s.pmMoneyWillBeSent(value: parsed.toDecimalString())} $rule';

  Future<void> _save() async {
    final AppStrings s = context.s;
    setState(() {
      _serverFieldErrors = <String, String>{};
      _localIssues = <FieldIssue>[];
    });
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String currency = _currencyCode();
    final AdminPaymentMethodView? existing = widget.method;

    // Merged values, exactly as the server evaluates a PATCH: incoming where
    // present, stored otherwise.
    final Money? minAmount =
        _parseMoney(_minAmount.text, currency) ?? existing?.minAmount;
    final Money? maxAmount =
        _parseMoney(_maxAmount.text, currency) ?? existing?.maxAmount;
    final Money feeFixed = _parseMoney(_feeFixed.text, currency) ??
        existing?.feeFixed ??
        Money.zero(currency: currency);
    final int feeBps = int.tryParse(_feeBps.text.trim()) ?? 0;
    final int sortOrder = int.tryParse(_sortOrder.text.trim()) ?? 0;

    if (minAmount == null || maxAmount == null) {
      setState(() {
        _localIssues = <FieldIssue>[
          FieldIssue('minAmount', s.pmBothLimitsRequired),
        ];
      });
      return;
    }

    final FieldIssue? feeBpsIssue =
        PaymentMethodRules.validateFeeBps(feeBps, s);
    final List<FieldIssue> issues = <FieldIssue>[
      ...PaymentMethodRules.validateAmounts(
        minAmount: minAmount,
        maxAmount: maxAmount,
        feeFixed: feeFixed,
        strings: s,
      ),
      if (feeBpsIssue != null) feeBpsIssue,
    ];
    if (issues.isNotEmpty) {
      setState(() => _localIssues = issues);
      return;
    }

    final PaymentMethodActionsController actions =
        ref.read(paymentMethodActionsProvider.notifier);
    final MutationResult<AdminPaymentMethodView> result = existing == null
        ? await actions.createMethod(
            CreatePaymentMethodRequest(
              code: PaymentMethodRules.normalizeCode(_code.text),
              displayName: _displayName.text.trim(),
              rail: _rail,
              currencyCode: currency,
              verificationMode: _verificationMode,
              minAmount: minAmount,
              maxAmount: maxAmount,
              feeFixed: feeFixed,
              feeBps: feeBps,
              requiresReference: _requiresReference,
              referencePattern: _referencePattern.text.trim().isEmpty
                  ? null
                  : _referencePattern.text,
              instructions: _instructions.text.trim().isEmpty
                  ? null
                  : _instructions.text,
              isActive: _isActive,
              sortOrder: sortOrder,
            ),
          )
        : await actions.updateMethod(
            existing.id,
            _buildUpdate(
              existing: existing,
              minAmount: minAmount,
              maxAmount: maxAmount,
              feeFixed: feeFixed,
              feeBps: feeBps,
              sortOrder: sortOrder,
            ),
          );

    if (!mounted) {
      return;
    }
    showMutationResult<AdminPaymentMethodView>(context, result);
    if (result is MutationSuccess<AdminPaymentMethodView>) {
      Navigator.of(context).pop(true);
      return;
    }
    if (result is MutationFailure<AdminPaymentMethodView>) {
      final MutationFailure<AdminPaymentMethodView> failure = result;
      setState(() {
        _serverFieldErrors = <String, String>{
          for (final FieldIssue issue in failure.fieldIssues)
            issue.field: issue.message,
        };
      });
    }
  }

  /// Only the fields that actually changed. An empty body is a legal no-op but
  /// still writes an audit row, so the save is skipped instead.
  UpdatePaymentMethodRequest _buildUpdate({
    required AdminPaymentMethodView existing,
    required Money minAmount,
    required Money maxAmount,
    required Money feeFixed,
    required int feeBps,
    required int sortOrder,
  }) {
    final String displayName = _displayName.text.trim();
    final String referencePattern = _referencePattern.text;
    final String instructions = _instructions.text;
    return UpdatePaymentMethodRequest(
      displayName: displayName == existing.displayName ? null : displayName,
      verificationMode: _verificationMode == existing.verificationMode
          ? null
          : _verificationMode,
      minAmount: minAmount == existing.minAmount ? null : minAmount,
      maxAmount: maxAmount == existing.maxAmount ? null : maxAmount,
      feeFixed: feeFixed == existing.feeFixed ? null : feeFixed,
      feeBps: feeBps == existing.feeBps ? null : feeBps,
      requiresReference: _requiresReference == existing.requiresReference
          ? null
          : _requiresReference,
      referencePattern:
          referencePattern == (existing.referencePattern ?? '')
              ? null
              : referencePattern,
      instructions:
          instructions == (existing.instructions ?? '') ? null : instructions,
      isActive: _isActive == existing.isActive ? null : _isActive,
      sortOrder: sortOrder == existing.sortOrder ? null : sortOrder,
    );
  }
}
