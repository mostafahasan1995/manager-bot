import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// Renders a [Money] exactly, with tabular figures and Western digits.
///
/// It NEVER rounds, never abbreviates ("1.5k" is not a thing here) and never
/// goes through `double`: the text comes straight from `Money.format`, which is
/// exact `BigInt` minor-unit arithmetic. Grouping is `1,234.56` in BOTH
/// locales, deliberately, so an amount on screen can be compared character for
/// character with the amount the Telegram bot quoted.
///
/// ```dart
/// AmountText(deposit.amount)                                  // 150,000.00 NSP
/// AmountText(delta, signed: true, colorBySign: true)          // +1,500.00 NSP in green
/// AmountText(total, fontSize: 28, tone: AppTone.credited)
/// ```
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.tone,
    this.showCurrency = true,
    this.signed = false,
    this.colorBySign = false,
    this.maxLines = 1,
    this.textAlign,
    this.height,
    super.key,
  });

  /// The exact amount. Minor units, scale 2, `BigInt` inside.
  final Money amount;

  final double fontSize;
  final FontWeight fontWeight;

  /// Explicit colour. Wins over [tone] and [colorBySign].
  final Color? color;

  /// Colour from the semantic palette.
  final AppTone? tone;

  /// Append the currency code (`NSP`).
  final bool showCurrency;

  /// Show a leading `+` on positive, non-zero amounts.
  final bool signed;

  /// Green for positive, red for negative, neutral for zero. Used on ledger
  /// rows; leave it off for a plain balance.
  final bool colorBySign;

  final int maxLines;
  final TextAlign? textAlign;

  /// Line height multiplier. Tighten it for very large sizes.
  final double? height;

  /// The exact string this widget paints. Handy for `Semantics` labels and for
  /// composing an amount into a sentence.
  static String render(
    BuildContext context,
    Money amount, {
    bool showCurrency = true,
    bool signed = false,
  }) =>
      amount.format(
        locale: 'en',
        withCurrency: showCurrency,
        alwaysShowSign: signed,
        strings: context.s,
      );

  Color _resolveColor() {
    final Color? explicit = color;
    if (explicit != null) {
      return explicit;
    }
    final AppTone? semantic = tone;
    if (semantic != null) {
      return AppPalette.tone(semantic).foreground;
    }
    if (!colorBySign) {
      return AppPalette.textPrimary;
    }
    if (amount.isNegative) {
      return AppPalette.moneyNegative;
    }
    if (amount.isPositive) {
      return AppPalette.moneyPositive;
    }
    return AppPalette.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final Color resolved = _resolveColor();
    return Text(
      render(context, amount, showCurrency: showCurrency, signed: signed),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: resolved,
        height: height,
        letterSpacing: -0.2,
        fontFeatures: NeonFonts.numericFeatures,
        fontFamilyFallback: NeonFonts.arabicFallback,
      ),
    );
  }
}
