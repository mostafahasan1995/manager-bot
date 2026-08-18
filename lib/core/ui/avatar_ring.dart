import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// A circular avatar inside a gradient ring - the Instagram story shape.
///
/// Shows [icon] when given, otherwise [initials], otherwise nothing. There is
/// no network image: the app has no session and therefore no avatar URLs, and
/// nothing here may reach the network anyway.
///
/// `active: false` swaps the gradient for a flat outline, the "already seen"
/// state, so a rail can show which quick action is spent.
///
/// ```dart
/// AvatarRing(initials: 'م ح', size: 64, gradient: AppPalette.gradientHot)
/// AvatarRing(icon: Icons.add_rounded, onTap: startTopUp)
/// ```
class AvatarRing extends StatelessWidget {
  const AvatarRing({
    this.initials,
    this.icon,
    this.size = 56,
    this.gradient = AppPalette.gradientSunset,
    this.active = true,
    this.onTap,
    this.badge,
    this.ringWidth = 2.5,
    this.fill,
    this.foreground,
    super.key,
  });

  /// One or two glyphs. Ignored when [icon] is set.
  final String? initials;

  /// Glyph in the middle. Wins over [initials].
  final IconData? icon;

  /// Outer diameter, ring included.
  final double size;

  /// The ring. Defaults to [AppPalette.gradientSunset].
  final LinearGradient gradient;

  /// False renders a flat [AppPalette.outline] ring instead of the gradient.
  final bool active;

  final VoidCallback? onTap;

  /// Small widget pinned to the bottom END corner - a count, a tick, a dot.
  final Widget? badge;

  /// Ring thickness.
  final double ringWidth;

  /// Interior colour. Defaults to [AppPalette.surface2].
  final Color? fill;

  /// Colour of [icon] / [initials]. Defaults to [AppPalette.textPrimary].
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final Color content = foreground ?? AppPalette.textPrimary;
    final double inner = size - (ringWidth + 2) * 2;

    final Widget core = DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? AppPalette.surface2,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: inner * 0.46, color: content)
            : Text(
                initials ?? '',
                maxLines: 1,
                style: TextStyle(
                  fontSize: inner * 0.34,
                  fontWeight: FontWeight.w700,
                  color: content,
                  fontFamilyFallback: NeonFonts.arabicFallback,
                ),
              ),
      ),
    );

    final Widget ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppPalette.mirrored(gradient, direction) : null,
        color: active ? null : AppPalette.outline,
      ),
      padding: EdgeInsets.all(ringWidth),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppPalette.canvas,
          shape: BoxShape.circle,
        ),
        child: Padding(padding: const EdgeInsets.all(2), child: core),
      ),
    );

    final Widget tappable = onTap == null
        ? ring
        : Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: ring,
            ),
          );

    if (badge == null) {
      return tappable;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        tappable,
        PositionedDirectional(end: -2, bottom: -2, child: badge!),
      ],
    );
  }
}

/// The little count bubble that sits on an [AvatarRing] or a nav icon.
///
/// Digits are ASCII in both locales, exactly like every amount in this app.
class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    this.color = AppPalette.accentPink,
    this.foreground = Colors.white,
    super.key,
  });

  /// Values above 99 render as `99+`.
  final int count;

  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: AppPalette.canvas, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: foreground,
            height: 1,
            fontFeatures: NeonFonts.numericFeatures,
          ),
        ),
      );
}
