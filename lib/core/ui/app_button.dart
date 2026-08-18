import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// The three weights a button can have.
enum AppButtonVariant {
  /// Filled with the signature gradient and a bloom. The one primary action on
  /// a screen - "شحن", "تأكيد", "رفع الإيصال".
  gradient,

  /// Tinted fill with a hairline. Secondary actions, tone-coloured actions.
  tonal,

  /// Outline only. Tertiary and destructive-adjacent actions.
  ghost,
}

/// The app's button. Pill-shaped, 52 high (40 when [dense]).
///
/// The loading state does NOT change the button's width: the label stays laid
/// out at zero opacity underneath a centred spinner, so a row of buttons never
/// jumps while a request is in flight.
///
/// ```dart
/// AppButton(
///   label: context.s.topUpCta,
///   icon: Icons.add_rounded,
///   loading: controller.isSubmitting,
///   onPressed: controller.canSubmit ? controller.submit : null,
/// )
///
/// AppButton(
///   label: context.s.cancel,
///   variant: AppButtonVariant.ghost,
///   onPressed: () => Navigator.of(context).pop(),
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.gradient,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.dense = false,
    this.gradient = AppPalette.gradientSignature,
    this.tone,
    super.key,
  });

  /// Already-localised label.
  final String label;

  /// Null disables the button. Must be a [VoidCallback]: if the work is async,
  /// pass a closure that starts it, so `unawaited_futures` stays satisfied at
  /// the call site.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  /// Leading glyph, before the label in reading order.
  final IconData? icon;

  /// Trailing glyph. Use a mirrored chevron from `AppIcons` if it means "next".
  final IconData? trailingIcon;

  /// Swaps the label for a spinner WITHOUT changing the button's size. The
  /// button stops responding while true.
  final bool loading;

  /// Fill the available width.
  final bool expand;

  /// 40px tall instead of 52.
  final bool dense;

  /// Fill for [AppButtonVariant.gradient].
  final LinearGradient gradient;

  /// Colours [AppButtonVariant.tonal] and [AppButtonVariant.ghost]. Ignored by
  /// the gradient variant.
  final AppTone? tone;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final AppTone? semantic = tone;
    final ToneColors? colors =
        semantic == null ? null : AppPalette.tone(semantic);
    final bool interactive = onPressed != null && !loading;
    final double height = dense ? 40 : 52;
    const BorderRadius shape = AppRadii.pillRadius;

    final Color foreground = switch (variant) {
      // Near-black on the neon fill, not white: white on the pink middle stop
      // is 3.6:1, while this is 5.5:1 against every stop of the signature
      // gradient. It is also the sharper, more TikTok-register look.
      AppButtonVariant.gradient => AppPalette.textOnAccent,
      AppButtonVariant.tonal => colors?.foreground ?? AppPalette.accentCyan,
      AppButtonVariant.ghost => colors?.foreground ?? AppPalette.textPrimary,
    };
    final Color? fill = switch (variant) {
      AppButtonVariant.gradient => null,
      AppButtonVariant.tonal => colors?.background ?? AppPalette.surface2,
      AppButtonVariant.ghost => Colors.transparent,
    };
    final BoxBorder? border = switch (variant) {
      AppButtonVariant.gradient => null,
      AppButtonVariant.tonal =>
        Border.all(color: colors?.border ?? AppPalette.outline),
      AppButtonVariant.ghost =>
        Border.all(color: colors?.border ?? AppPalette.outlineStrong),
    };
    final LinearGradient? fillGradient = variant == AppButtonVariant.gradient
        ? AppPalette.mirrored(gradient, direction)
        : null;

    final Widget row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: dense ? 16 : 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 14 : 15.5,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0.2,
              fontFamilyFallback: NeonFonts.arabicFallback,
            ),
          ),
        ),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: dense ? 16 : 18, color: foreground),
        ],
      ],
    );

    final Widget content = loading
        ? Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(opacity: 0, child: row),
              SizedBox(
                width: dense ? 16 : 20,
                height: dense ? 16 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: foreground,
                ),
              ),
            ],
          )
        : row;

    final Widget surface = Material(
      color: Colors.transparent,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: fill,
          gradient: fillGradient,
          borderRadius: shape,
          border: border,
        ),
        child: InkWell(
          onTap: interactive ? onPressed : null,
          // A white splash is invisible on the neon fill; ink the bright
          // variant with dark instead.
          splashColor: variant == AppButtonVariant.gradient
              ? const Color(0x1F000000)
              : AppPalette.sheenLow,
          highlightColor: variant == AppButtonVariant.gradient
              ? const Color(0x14000000)
              : AppPalette.sheenFaint,
          child: Container(
            height: height,
            constraints: const BoxConstraints(minWidth: 96),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: dense ? AppSpacing.lg : AppSpacing.xl,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    final Widget glowed = variant == AppButtonVariant.gradient && interactive
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              boxShadow: AppShadows.glow(
                gradient.colors.length > 1
                    ? gradient.colors[1]
                    : gradient.colors.first,
                blur: 22,
                spread: -8,
                offset: const Offset(0, 8),
                alpha: 0x80,
              ),
            ),
            child: surface,
          )
        : surface;

    if (onPressed != null) {
      return glowed;
    }
    return Opacity(opacity: 0.45, child: glowed);
  }
}
