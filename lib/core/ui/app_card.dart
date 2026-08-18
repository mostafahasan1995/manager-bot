import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/directional.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// The default container for content.
///
/// A quiet gradient fill (never a flat grey slab), a hairline outline, 20px
/// corners and an optional ripple. Screens should not build their own
/// `Container` + `BoxDecoration` for a card.
///
/// ```dart
/// AppCard(
///   onTap: () => context.push('/deposits/$id'),
///   child: Row(children: <Widget>[...]),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadii.md,
    this.color,
    this.borderColor,
    this.showShadow = true,
    super.key,
  });

  final Widget child;

  /// Defaults to [AppSpacing.cardPadding] (16 on every side).
  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  /// When non-null the whole card is tappable and shows a ripple.
  final VoidCallback? onTap;

  /// Corner radius. Use [AppRadii.sm] for a dense tile, [AppRadii.lg] for a
  /// hero-sized surface.
  final double radius;

  /// Flat fill. When null the card uses [AppPalette.gradientSurface].
  final Color? color;

  /// Defaults to [AppPalette.outline].
  final Color? borderColor;

  /// Drop the shadow when the card sits inside another card.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(radius);
    final Widget body = Padding(
      padding: padding ?? AppSpacing.cardPadding,
      child: child,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? AppPalette.gradientSurface : null,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? AppPalette.outline),
        boxShadow: showShadow ? AppShadows.card : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? body
            : InkWell(
                onTap: onTap,
                splashColor: AppPalette.sheenLow,
                highlightColor: AppPalette.sheenFaint,
                child: body,
              ),
      ),
    );
  }
}

/// A card that glows: gradient edge, coloured bloom, dark interior.
///
/// This is the "look at me" card - the top-up call to action, a live promo, a
/// state that needs celebrating. One per screen, at most two.
///
/// The gradient is drawn as a 1.4px border by stacking a gradient container
/// under an inset dark container, which costs one extra rect and no shader
/// per frame.
///
/// ```dart
/// GlowCard(
///   gradient: AppPalette.gradientHot,
///   onTap: startTopUp,
///   child: Column(children: <Widget>[...]),
/// )
/// ```
class GlowCard extends StatelessWidget {
  const GlowCard({
    required this.child,
    this.gradient = AppPalette.gradientSignature,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadii.lg,
    this.glowColor,
    this.borderWidth = 1.4,
    this.fill,
    super.key,
  });

  final Widget child;

  /// The edge gradient. Defaults to [AppPalette.gradientSignature].
  final LinearGradient gradient;

  /// Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Corner radius. Defaults to [AppRadii.lg] (28).
  final double radius;

  /// The bloom colour. Defaults to the gradient's first stop.
  final Color? glowColor;

  /// Thickness of the gradient edge.
  final double borderWidth;

  /// Interior colour. Defaults to [AppPalette.surface1].
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final BorderRadius outer = BorderRadius.circular(radius);
    final BorderRadius inner = BorderRadius.circular(radius - borderWidth);
    final Color bloom = glowColor ?? gradient.colors.first;
    final Widget body = Padding(
      padding: padding ?? AppSpacing.cardPadding,
      child: child,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppPalette.mirrored(gradient, direction),
        borderRadius: outer,
        boxShadow: AppShadows.glow(bloom),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: fill ?? AppPalette.surface1,
          borderRadius: inner,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? body
              : InkWell(
                  onTap: onTap,
                  splashColor: bloom.withAlpha(0x22),
                  highlightColor: AppPalette.sheenFaint,
                  child: body,
                ),
        ),
      ),
    );
  }
}

/// The title above a group of cards, with an optional trailing action.
///
/// ```dart
/// SectionHeader(
///   title: context.s.myDepositsTitle,
///   actionLabel: context.s.viewAll,
///   onAction: () => context.go('/deposits'),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.md,
    ),
    super.key,
  });

  /// Already-localised section title.
  final String title;

  /// Optional one-line explanation under the title.
  final String? subtitle;

  /// Already-localised label for the trailing button. Ignored when [onAction]
  /// is null.
  final String? actionLabel;

  final VoidCallback? onAction;

  /// Small leading glyph, tinted with the accent.
  final IconData? icon;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasAction = onAction != null && actionLabel != null;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: AppPalette.accentCyan),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasAction)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.accentCyan,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const ForwardChevron(size: 16, color: AppPalette.accentCyan),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
