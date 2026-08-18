import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// A text field for one approval ceiling.
///
/// Everything typed here becomes BigInt minor units through
/// [Money.parseUserInput]; no `double` exists anywhere on this path. The field
/// caps input at two decimal places on purpose: the server's DTO regex accepts
/// up to six, and `toMinor()` then rejects anything past two with
/// `INVALID_AMOUNT` / `MONEY_TOO_MANY_DECIMALS`. Catching it here turns a
/// round-trip failure into an inline message.
class MoneyAmountField extends StatelessWidget {
  const MoneyAmountField({
    required this.controller,
    required this.label,
    required this.currencyCode,
    this.helperText,
    this.optional = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String currencyCode;
  final String? helperText;

  /// When true, an empty field is valid and the caller omits the key entirely.
  final bool optional;

  final bool enabled;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        LengthLimitingTextInputFormatter(21),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 3,
        suffixText: currencyCode,
        border: const OutlineInputBorder(),
      ),
      validator: (String? raw) => validate(raw, s),
    );
  }

  /// Null when the text is acceptable. Exposed so the form can reuse it.
  String? validate(String? raw, AppStrings s) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return optional ? null : s.moneyErrorEmpty;
    }
    final String? reason = Money.validationReason(value);
    return reason == null ? null : describeMoneyReason(reason, s);
  }

  /// Parses the field. Null when it is empty, or when the text is not a valid
  /// amount - which [validate] has already reported under the field.
  Money? parse() {
    final String value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }
    return Money.tryParseUserInput(value, currency: currencyCode);
  }
}

/// Turns a `MoneyFormatException` reason code into an operator-facing sentence.
///
/// The codes come from the core money parser and match what the server reports
/// in `details.reason`, so the same wording works for a local rejection and for
/// a 400 `INVALID_AMOUNT`.
String describeMoneyReason(String reason, AppStrings s) => switch (reason) {
      'MONEY_EMPTY' => s.moneyErrorEmpty,
      'MONEY_MALFORMED' => s.moneyErrorDigitsOnly,
      'MONEY_TOO_MANY_DECIMALS' => s.moneyErrorScaleTwoDetailed,
      'MONEY_CURRENCY_MISMATCH' => s.moneyErrorOtherCurrency,
      _ => s.moneyErrorInvalid,
    };
