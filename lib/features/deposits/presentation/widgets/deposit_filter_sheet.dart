import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_query.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_formatting.dart';

/// Every filter `GET /v1/admin/deposits` accepts, as one sheet.
///
/// Edits a DRAFT copy and only publishes it on "Apply", so a half-typed UUID
/// never triggers a fetch. Client-side validation mirrors the server's, which
/// turns a typo into an inline message instead of a 400 round trip.
class DepositFilterSheet extends StatefulWidget {
  const DepositFilterSheet({required this.initial, super.key});

  /// Shows the sheet and resolves to the new filter, or null when dismissed.
  static Future<DepositQueueFilter?> show(
    BuildContext context, {
    required DepositQueueFilter initial,
  }) {
    return showModalBottomSheet<DepositQueueFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) =>
          DepositFilterSheet(initial: initial),
    );
  }

  final DepositQueueFilter initial;

  @override
  State<DepositFilterSheet> createState() => _DepositFilterSheetState();
}

class _DepositFilterSheetState extends State<DepositFilterSheet> {
  late Set<DepositStatus> _statuses;
  late DepositSort _sort;
  late bool _unclaimedOnly;
  late DateTime? _createdFrom;
  late DateTime? _createdTo;

  late final TextEditingController _shortId;
  late final TextEditingController _reference;
  late final TextEditingController _playerId;
  late final TextEditingController _paymentMethodId;
  late final TextEditingController _minAmount;
  late final TextEditingController _maxAmount;

  List<String> _problems = const <String>[];

  @override
  void initState() {
    super.initState();
    final DepositQueueFilter initial = widget.initial;
    _statuses = Set<DepositStatus>.of(initial.statuses);
    _sort = initial.sort;
    _unclaimedOnly = initial.unclaimedOnly;
    _createdFrom = initial.createdFrom;
    _createdTo = initial.createdTo;
    _shortId = TextEditingController(text: initial.shortId ?? '');
    _reference = TextEditingController(text: initial.externalReference ?? '');
    _playerId = TextEditingController(text: initial.playerId ?? '');
    _paymentMethodId =
        TextEditingController(text: initial.paymentMethodId ?? '');
    _minAmount =
        TextEditingController(text: initial.minAmount?.toDecimalString() ?? '');
    _maxAmount =
        TextEditingController(text: initial.maxAmount?.toDecimalString() ?? '');
  }

  @override
  void dispose() {
    _shortId.dispose();
    _reference.dispose();
    _playerId.dispose();
    _paymentMethodId.dispose();
    _minAmount.dispose();
    _maxAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext context, ScrollController controller) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 12, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.filterSheetTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetDraft,
                      child: Text(s.resetButton),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: <Widget>[
                    _SectionLabel(
                      s.statusLabel,
                      hint: _statuses.isEmpty ? s.filterStatusHint : null,
                    ),
                    const SizedBox(height: 8),
                    _statusPresets(s),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DepositStatus.values
                          .map(
                            (DepositStatus status) => FilterChip(
                              label: Text(status.label(s)),
                              selected: _statuses.contains(status),
                              onSelected: (bool selected) => setState(() {
                                if (selected) {
                                  _statuses.add(status);
                                } else {
                                  _statuses.remove(status);
                                }
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(s.filterSectionSort),
                    const SizedBox(height: 8),
                    _sortSelector(theme, s),
                    const SizedBox(height: 20),
                    _SectionLabel(
                      s.filterSectionSearch,
                      hint: s.filterSearchHint,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shortId,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 32,
                      decoration: InputDecoration(
                        labelText: s.filterShortIdLabel,
                        hintText: s.filterShortIdHint,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reference,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: s.externalReferenceLabel,
                        hintText: s.filterCaseSensitiveHint,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(
                      s.filterSectionAmount,
                      hint: s.atMostTwoDecimals,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _amountField(_minAmount, s.filterAmountMin, s),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _amountField(_maxAmount, s.filterAmountMax, s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(
                      s.createdLabel,
                      hint: s.filterCreatedHint,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DateButton(
                            label: s.dateFrom,
                            value: _createdFrom,
                            onPick: () => _pickDate(isFrom: true),
                            onClear: _createdFrom == null
                                ? null
                                : () => setState(() => _createdFrom = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateButton(
                            label: s.dateTo,
                            value: _createdTo,
                            onPick: () => _pickDate(isFrom: false),
                            onClear: _createdTo == null
                                ? null
                                : () => setState(() => _createdTo = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(
                      s.filterSectionIdentifiers,
                      hint: s.filterIdentifiersHint,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _playerId,
                      decoration: InputDecoration(labelText: s.playerIdLabel),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _paymentMethodId,
                      decoration: InputDecoration(
                        labelText: s.technicalPaymentMethodId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _unclaimedOnly,
                      onChanged: (bool value) =>
                          setState(() => _unclaimedOnly = value),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.filterUnclaimedOnly),
                      subtitle: Text(s.filterUnclaimedOnlySubtitle),
                    ),
                    if (_problems.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      _ProblemList(problems: _problems),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(s.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: Text(s.apply),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPresets(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ActionChip(
          avatar: const Icon(Icons.inbox_outlined, size: 16),
          label: Text(s.presetReviewable),
          onPressed: () => setState(
            () => _statuses = Set<DepositStatus>.of(DepositStatus.reviewable),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.error_outline, size: 16),
          label: Text(s.presetNeedsAttention),
          onPressed: () => setState(
            () => _statuses = <DepositStatus>{
              DepositStatus.creditFailed,
              DepositStatus.needsReconciliation,
            },
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.clear_all, size: 16),
          label: Text(s.presetAnyStatus),
          onPressed: () => setState(_statuses.clear),
        ),
      ],
    );
  }

  Widget _sortSelector(ThemeData theme, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DepositSort.values
              .map(
                (DepositSort sort) => ChoiceChip(
                  label: Text(sort.label(s)),
                  selected: _sort == sort,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _sort = sort);
                    }
                  },
                ),
              )
              .toList(growable: false),
        ),
        if (!_sort.isPageable) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            s.sortNotPageableHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountField(
    TextEditingController controller,
    String label,
    AppStrings s,
  ) {
    final String raw = controller.text.trim();
    final String? reason = raw.isEmpty ? null : Money.validationReason(raw);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
      ],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        // Western digits in both locales, exactly like Money.format().
        hintText: s.amountFieldHintSample,
        errorText: reason == null ? null : _amountError(reason, s),
      ),
    );
  }

  static String _amountError(String reason, AppStrings s) => switch (reason) {
        'MONEY_TOO_MANY_DECIMALS' => s.atMostTwoDecimals,
        'MONEY_EMPTY' => s.moneyErrorEmpty,
        _ => s.moneyErrorInvalid,
      };

  Future<void> _pickDate({required bool isFrom}) async {
    final DateTime now = DateTime.now();
    final DateTime? initial = isFrom ? _createdFrom : _createdTo;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        // Inclusive lower bound: start of the chosen day.
        _createdFrom = DateTime(picked.year, picked.month, picked.day);
      } else {
        // Exclusive upper bound: start of the NEXT day, so the chosen day is
        // itself included, which is what an operator expects.
        _createdTo =
            DateTime(picked.year, picked.month, picked.day).add(const Duration(days: 1));
      }
    });
  }

  void _resetDraft() {
    setState(() {
      _statuses = <DepositStatus>{};
      _sort = DepositSort.newest;
      _unclaimedOnly = false;
      _createdFrom = null;
      _createdTo = null;
      _shortId.clear();
      _reference.clear();
      _playerId.clear();
      _paymentMethodId.clear();
      _minAmount.clear();
      _maxAmount.clear();
      _problems = const <String>[];
    });
  }

  void _apply() {
    final AppStrings s = context.s;
    final DepositQueueFilter draft = DepositQueueFilter(
      statuses: Set<DepositStatus>.unmodifiable(_statuses),
      sort: _sort,
      unclaimedOnly: _unclaimedOnly,
      createdFrom: _createdFrom,
      createdTo: _createdTo,
      shortId: _trimToNull(_shortId.text)?.toUpperCase(),
      externalReference: _trimToNull(_reference.text),
      playerId: _trimToNull(_playerId.text),
      paymentMethodId: _trimToNull(_paymentMethodId.text),
      minAmount: Money.tryParseUserInput(_minAmount.text),
      maxAmount: Money.tryParseUserInput(_maxAmount.text),
    );

    final List<String> problems = <String>[
      ...draft.validate(s),
      if (_trimToNull(_minAmount.text) != null &&
          Money.tryParseUserInput(_minAmount.text) == null)
        s.validationMinAmountInvalid,
      if (_trimToNull(_maxAmount.text) != null &&
          Money.tryParseUserInput(_maxAmount.text) == null)
        s.validationMaxAmountInvalid,
    ];

    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      return;
    }
    Navigator.of(context).pop(draft);
  }

  static String? _trimToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? subtitle = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          // NOT upper-cased: Arabic has no case, and forcing it would leave the
          // two languages looking like different designs.
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final Future<void> Function() onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final DateTime? current = value;
    return OutlinedButton.icon(
      onPressed: () => unawaited(onPick()),
      icon: Icon(
        current == null ? Icons.date_range_outlined : Icons.event_available,
        size: 18,
      ),
      label: Text(
        current == null
            ? label
            : DepositFormat.dateOnly(current, context.s, context.localeTag),
        overflow: TextOverflow.ellipsis,
      ),
      onLongPress: onClear,
    );
  }
}

class _ProblemList extends StatelessWidget {
  const _ProblemList({required this.problems});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: problems
            .map(
              (String problem) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '- $problem',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
