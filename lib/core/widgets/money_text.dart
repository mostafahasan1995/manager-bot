import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// Renders a [Money] with tabular figures so columns of amounts line up.
///
/// Formatting happens HERE, at the render edge, and nowhere else: everything
/// upstream stays exact BigInt minor units.
///
/// NOT LOCALISED, deliberately. `1,500.00 NSP` is what the bot shows an Arabic
/// operator and what the backend logs, so [locale] stays null in app code and
/// the digits stay ASCII in both languages. Only [placeholder] comes from the
/// catalogue, because an em dash beats a hyphen in an RTL row.
///
/// ```dart
/// MoneyText(deposit.claimed)                          // 1,500.00 NSP
/// MoneyText(entry.amount, colorBySign: true)          // green / red
/// MoneyText(fee, style: AppTheme.moneyStyle(context), showCurrency: false)
/// ```
class MoneyText extends StatelessWidget {
  /// [money] is nullable on purpose: `verified` and `credited` are
  /// object-or-null on the wire, and a null amount renders as [placeholder].
  const MoneyText(
    this.money, {
    this.style,
    this.showCurrency = true,
    this.alwaysShowSign = false,
    this.colorBySign = false,
    this.locale,
    this.textAlign,
    this.emphasise = false,
    this.placeholder,
    super.key,
  });

  final Money? money;
  final TextStyle? style;
  final bool showCurrency;

  /// Prefix positive amounts with `+`. Use in ledger views.
  final bool alwaysShowSign;

  /// Colour credits green and debits red. Negative amounts are meaningful and
  /// are never hidden behind an `abs()`.
  final bool colorBySign;

  final String? locale;
  final TextAlign? textAlign;

  /// Larger, heavier rendering for the headline amount on a detail screen.
  final bool emphasise;

  /// Shown when the amount is null. Defaults to [AppStrings.emptyValueDash].
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final value = money;
    final theme = Theme.of(context);
    final base = style ??
        (emphasise
            ? AppTheme.moneyStyle(context, fontSize: 24)
            : AppTheme.moneyStyle(context));

    if (value == null) {
      return Text(
        placeholder ?? context.s.emptyValueDash,
        textAlign: textAlign,
        style: base.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    Color? color;
    if (colorBySign && !value.isZero) {
      final semantics = AppSemanticColors.of(context);
      color = value.isNegative ? semantics.moneyNegative : semantics.moneyPositive;
    }

    return Text(
      value.format(
        locale: locale,
        withCurrency: showCurrency,
        alwaysShowSign: alwaysShowSign,
        strings: context.s,
      ),
      textAlign: textAlign,
      // An amount is one LTR run: "-1,500.00 NSP" must not have its sign or its
      // currency code reordered by the surrounding Arabic paragraph.
      textDirection: TextDirection.ltr,
      style: color == null ? base : base.copyWith(color: color),
    );
  }
}
