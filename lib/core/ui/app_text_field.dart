import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// The app's text input: a label ABOVE the field, a filled rounded box, a cyan
/// focus edge and a red error line.
///
/// The label sits outside the box on purpose - a floating Material label
/// animates across the field's start edge, which under RTL collides with a
/// prefix icon and reads badly in Arabic.
///
/// The field never sets `textDirection`: Arabic text and Western digits are
/// laid out by the bidi algorithm from the ambient [Directionality], which is
/// what makes "150000 ل.س" come out right in both locales. Pass
/// [numeric] for amounts to get tabular figures.
///
/// ```dart
/// AppTextField(
///   label: context.s.amountLabel,
///   controller: amountController,
///   numeric: true,
///   keyboardType: const TextInputType.numberWithOptions(decimal: true),
///   inputFormatters: <TextInputFormatter>[
///     FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
///   ],
///   errorText: reason == null ? null : context.s.errorTitleUnreadableAmount,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.focusNode,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.numeric = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  /// Already-localised label, drawn above the box.
  final String label;

  final TextEditingController? controller;

  /// Already-localised placeholder inside the box.
  final String? hint;

  /// Already-localised hint under the box. Hidden while [errorText] shows.
  final String? helper;

  /// Already-localised error. Non-null turns the field red.
  final String? errorText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  /// Leading glyph inside the box, on the reading-start side.
  final IconData? prefixIcon;

  /// Trailing widget inside the box - a unit label, a paste button, an eye.
  final Widget? suffix;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Tapping the field itself. Use with [readOnly] for a picker.
  final VoidCallback? onTap;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  /// Tabular, slashed-zero figures. Turn on for amounts, references and codes.
  final bool numeric;

  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasError = errorText != null;
    final Color edge = hasError
        ? AppPalette.tone(AppTone.rejected).foreground
        : AppPalette.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          cursorColor: AppPalette.accentCyan,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? AppPalette.textPrimary : AppPalette.textDisabled,
            fontWeight: numeric ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: numeric ? NeonFonts.numericFeatures : null,
            fontFamilyFallback: NeonFonts.arabicFallback,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: AppPalette.textTertiary),
            suffixIcon: suffix,
            counterText: '',
            filled: true,
            fillColor: enabled ? AppPalette.surface2 : AppPalette.surface1,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            hintStyle: const TextStyle(color: AppPalette.textDisabled),
            border: OutlineInputBorder(
              borderRadius: AppRadii.smRadius,
              borderSide: BorderSide(color: edge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.smRadius,
              borderSide: BorderSide(color: edge),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.smRadius,
              borderSide: BorderSide(color: AppPalette.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.smRadius,
              borderSide: BorderSide(
                color: hasError
                    ? AppPalette.tone(AppTone.rejected).foreground
                    : AppPalette.accentCyan,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (hasError || helper != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              top: AppSpacing.sm,
            ),
            child: Text(
              hasError ? errorText! : helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasError
                    ? AppPalette.tone(AppTone.rejected).foreground
                    : AppPalette.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
