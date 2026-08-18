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
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_requests.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/mutation_feedback.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/section_card.dart';

/// Create or edit ONE destination - the account a player is told to pay into.
///
/// This is the screen the backend's STATUS.md points at: "Replace via
/// POST /v1/admin/payment-methods/:id/destinations before any real player."
/// Everything that can silently lose money is called out inline rather than
/// left to a help page:
///
/// * `accountIdentifier` is stored EXACTLY as typed and is IMMUTABLE. It is
///   never case-normalised here either, because uppercasing a Base58 address
///   produces a different, valid-looking address.
/// * on CRYPTO the `label` is the CHAIN NAME the player reads as
///   `Network: {label}`, and `accountHolder` is ignored entirely.
/// * `dailyCap` is a SOFT cap and cannot be cleared once set.
class PaymentDestinationFormScreen extends ConsumerStatefulWidget {
  const PaymentDestinationFormScreen({
    required this.method,
    this.destination,
    super.key,
  });

  /// Owning method: supplies the path id, the rail captions and the currency.
  final AdminPaymentMethodView method;

  /// Null creates a new destination; non-null edits that one.
  final AdminPaymentDestinationView? destination;

  @override
  ConsumerState<PaymentDestinationFormScreen> createState() =>
      _PaymentDestinationFormScreenState();
}

class _PaymentDestinationFormScreenState
    extends ConsumerState<PaymentDestinationFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _accountIdentifier;
  late final TextEditingController _accountHolder;
  late final TextEditingController _priority;
  late final TextEditingController _dailyCap;
  late final TextEditingController _notes;

  late bool _isActive;

  Map<String, String> _serverFieldErrors = <String, String>{};
  List<FieldIssue> _localIssues = <FieldIssue>[];

  bool get _isEditing => widget.destination != null;

  PaymentRail get _rail => widget.method.rail;

  @override
  void initState() {
    super.initState();
    final AdminPaymentDestinationView? destination = widget.destination;
    _label = TextEditingController(text: destination?.label ?? '');
    _accountIdentifier =
        TextEditingController(text: destination?.accountIdentifier ?? '');
    _accountHolder =
        TextEditingController(text: destination?.accountHolder ?? '');
    _priority = TextEditingController(text: '${destination?.priority ?? 0}');
    _dailyCap = TextEditingController(
      text: destination?.dailyCap?.toDecimalString() ?? '',
    );
    _notes = TextEditingController(text: destination?.notes ?? '');
    _isActive = destination?.isActive ?? true;

    _accountIdentifier.addListener(_onPreviewChanged);
    _dailyCap.addListener(_onPreviewChanged);
  }

  @override
  void dispose() {
    _accountIdentifier.removeListener(_onPreviewChanged);
    _dailyCap.removeListener(_onPreviewChanged);
    _label.dispose();
    _accountIdentifier.dispose();
    _accountHolder.dispose();
    _priority.dispose();
    _dailyCap.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onPreviewChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final bool canManage = ref.watch(canManagePaymentMethodsProvider);
    final bool isBusy = ref.watch(paymentMethodActionsProvider).isBusy(
          widget.destination?.id ?? PaymentMethodActionState.createKey,
        );
    final String title =
        _isEditing ? s.pdFormEditTitle : s.pdFormCreateTitle;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PermissionDeniedView(
          role: ref.watch(currentRoleProvider),
          allowedRoles: PaymentMethodRoles.managers,
          title: s.pdManagersDeniedTitle,
          message: s.pdManagersDeniedMessage,
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
            if (_rail == PaymentRail.crypto)
              InfoBanner(
                title: s.pdCryptoChainTitle,
                tone: StatusTone.pending,
                icon: Icons.currency_bitcoin,
                // `{label}` is a TEMPLATE TOKEN standing for whatever is typed
                // below, exactly as before - not a value and not prose.
                message: s.pdCryptoChainMessage(label: '{label}'),
              ),
            _accountSection(s),
            _routingSection(s),
            _notesSection(s),
          ],
        ),
      ),
    );
  }

  Widget _accountSection(AppStrings s) {
    final AdminPaymentDestinationView? destination = widget.destination;
    final String typedIdentifier = _accountIdentifier.text;
    return SectionCard(
      title: s.accountLabel,
      subtitle: s.pdAccountSubtitle,
      children: <Widget>[
        TextFormField(
          controller: _label,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(PaymentMethodRules.labelMaxLength),
          ],
          decoration: _decoration(
            'label',
            label: s.pdLabelFieldLabel(
              caption: _rail.destinationLabelCaption(s),
            ),
            helper: _rail.destinationLabelHint(s),
          ),
          validator: (String? value) =>
              PaymentMethodRules.validateDestinationLabel(value ?? '', s)
                  ?.message,
        ),
        const SizedBox(height: 14),
        if (_isEditing && destination != null) ...<Widget>[
          DetailRow.text(
            label: _rail.accountIdentifierCaption(s),
            value: destination.accountIdentifier,
            monospace: true,
            hint: s.pdAccountIdentifierImmutableHint,
          ),
        ] else ...<Widget>[
          TextFormField(
            controller: _accountIdentifier,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(
                PaymentMethodRules.accountIdentifierMaxLength,
              ),
            ],
            decoration: _decoration(
              'accountIdentifier',
              label: _rail.accountIdentifierCaption(s),
              helper: s.pdAccountIdentifierHelper,
            ),
            validator: (String? value) =>
                PaymentMethodRules.validateAccountIdentifier(value ?? '', s)
                    ?.message,
          ),
          if (_looksLikePlaceholder(typedIdentifier)) ...<Widget>[
            const SizedBox(height: 10),
            InfoBanner(
              title: s.pdPlaceholderTypedTitle,
              tone: StatusTone.failed,
              icon: Icons.warning_amber_rounded,
              message: s.pdPlaceholderTypedMessage,
              margin: EdgeInsets.zero,
            ),
          ],
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _accountHolder,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(
              PaymentMethodRules.accountHolderMaxLength,
            ),
          ],
          decoration: _decoration(
            'accountHolder',
            label: s.accountHolderLabel,
            helper: _rail.ignoresAccountHolder
                ? s.pdAccountHolderIgnoredHelper(rail: _rail.label(s))
                : s.pdAccountHolderHelper,
          ),
          validator: (String? value) =>
              PaymentMethodRules.validateAccountHolder(value ?? '', s)?.message,
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          onChanged: (bool value) => setState(() => _isActive = value),
          // A DESTINATION is مفعّل - not the method's مفعّلة.
          title: Text(s.pdStatusActive),
          subtitle: Text(
            _isActive ? s.pdActiveSwitchOn : s.pdActiveSwitchOff,
          ),
        ),
      ],
    );
  }

  Widget _routingSection(AppStrings s) {
    final Money? cap = Money.tryParseUserInput(
      _dailyCap.text,
      currency: widget.method.currencyCode,
    );
    return SectionCard(
      title: s.pdRoutingSection,
      subtitle: s.pdRoutingSubtitle,
      children: <Widget>[
        TextFormField(
          controller: _priority,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            'priority',
            label: s.pdPriorityLabel,
            helper: s.pdPriorityHelper,
          ),
          validator: (String? value) => PaymentMethodRules.validateIntegerInput(
            value ?? '',
            s,
            required: true,
            min: 0,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _dailyCap,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(
            'dailyCap',
            // The currency CODE is never translated.
            label: s.pdDailyCapLabel(currency: widget.method.currencyCode),
            helper: cap == null
                ? s.pdDailyCapHelper
                : s.pdDailyCapHelperParsed(value: cap.toDecimalString()),
          ),
          validator: (String? value) => PaymentMethodRules.validateMoneyInput(
            value ?? '',
            s,
            required: false,
          ),
        ),
        if (_isEditing && widget.destination?.dailyCap != null) ...<Widget>[
          const SizedBox(height: 10),
          InfoBanner(
            title: s.pdCapCannotBeRemovedTitle,
            tone: StatusTone.neutral,
            icon: Icons.info_outline,
            message: s.pdCapCannotBeRemovedMessage,
            margin: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _notesSection(AppStrings s) {
    return SectionCard(
      title: s.notesLabel,
      subtitle: s.pdNotesSubtitle,
      children: <Widget>[
        TextFormField(
          controller: _notes,
          minLines: 2,
          maxLines: 6,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(PaymentMethodRules.notesMaxLength),
          ],
          decoration: _decoration(
            'notes',
            label: s.notesLabel,
            helper: s.pdNotesHelper,
          ),
          validator: (String? value) =>
              PaymentMethodRules.validateNotes(value ?? '', s)?.message,
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

  static bool _looksLikePlaceholder(String identifier) {
    final String value = identifier.trim().toUpperCase();
    if (value.isEmpty) {
      return false;
    }
    if (value.startsWith(AdminPaymentDestinationView.seedPlaceholderPrefix)) {
      return true;
    }
    return AdminPaymentDestinationView.placeholderMarkers
        .any(value.contains);
  }

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

    final int priority = int.tryParse(_priority.text.trim()) ?? 0;
    final FieldIssue? priorityIssue =
        PaymentMethodRules.validatePriority(priority, s);
    if (priorityIssue != null) {
      setState(() => _localIssues = <FieldIssue>[priorityIssue]);
      return;
    }

    final Money? dailyCap = Money.tryParseUserInput(
      _dailyCap.text,
      currency: widget.method.currencyCode,
    );
    final String holder = _accountHolder.text.trim();
    final String notes = _notes.text;
    final String label = _label.text.trim();

    final PaymentMethodActionsController actions =
        ref.read(paymentMethodActionsProvider.notifier);
    final AdminPaymentDestinationView? existing = widget.destination;

    final MutationResult<AdminPaymentDestinationView> result = existing == null
        ? await actions.createDestination(
            widget.method.id,
            CreatePaymentDestinationRequest(
              label: label,
              // Trim only. NEVER normalise the case: a Base58 address that is
              // uppercased is a different, valid-looking address.
              accountIdentifier: _accountIdentifier.text.trim(),
              accountHolder: holder.isEmpty ? null : holder,
              isActive: _isActive,
              priority: priority,
              dailyCap: dailyCap,
              notes: notes.trim().isEmpty ? null : notes,
            ),
          )
        : await actions.updateDestination(
            destinationId: existing.id,
            methodId: widget.method.id,
            request: _buildUpdate(existing, label, holder, notes, priority, dailyCap),
          );

    if (!mounted) {
      return;
    }
    showMutationResult<AdminPaymentDestinationView>(context, result);
    if (result is MutationSuccess<AdminPaymentDestinationView>) {
      Navigator.of(context).pop(true);
      return;
    }
    if (result is MutationFailure<AdminPaymentDestinationView>) {
      final MutationFailure<AdminPaymentDestinationView> failure = result;
      setState(() {
        _serverFieldErrors = <String, String>{
          for (final FieldIssue issue in failure.fieldIssues)
            issue.field: issue.message,
        };
      });
    }
  }

  /// Only what actually changed.
  ///
  /// The stored cap is parsed without a currency (the wire does not send one),
  /// so it is compared on exact MINOR UNITS rather than on `Money` equality,
  /// which also compares the currency label.
  UpdatePaymentDestinationRequest _buildUpdate(
    AdminPaymentDestinationView existing,
    String label,
    String holder,
    String notes,
    int priority,
    Money? dailyCap,
  ) {
    final Money? storedCap = existing.dailyCap;
    final bool capUnchanged = dailyCap == null
        ? storedCap == null
        : storedCap != null && storedCap.minor == dailyCap.minor;
    return UpdatePaymentDestinationRequest(
      label: label == existing.label ? null : label,
      accountHolder: holder == (existing.accountHolder ?? '') ? null : holder,
      isActive: _isActive == existing.isActive ? null : _isActive,
      priority: priority == existing.priority ? null : priority,
      // Omitted when unchanged or blank: null is rejected by the DTO and an
      // omitted key leaves the stored cap untouched, so a cap can only ever be
      // overwritten - never cleared.
      dailyCap: capUnchanged ? null : dailyCap,
      notes: notes == (existing.notes ?? '') ? null : notes,
    );
  }
}
