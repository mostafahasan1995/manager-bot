import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// Text painted with a gradient instead of a flat colour.
///
/// Use it for ONE thing per screen - a title, a headline number, the brand
/// wordmark. Never for an amount the player must read carefully and never for
/// body copy: a gradient lowers effective contrast at every stop, and this is a
/// money app.
///
/// The mask is `BlendMode.srcIn` over white text, so the [style] colour is
/// ignored on purpose.
///
/// ```dart
/// GradientText(
///   context.s.homeGreeting,
///   style: Theme.of(context).textTheme.headlineSmall,
/// )
/// ```
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    this.gradient = AppPalette.gradientSignature,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Already-localised text. Never a raw wire value.
  final String text;

  /// Defaults to [AppPalette.gradientSignature]. Mirrored automatically under
  /// RTL, so a sweep always runs from the reading start to the reading end.
  final LinearGradient gradient;

  /// Size / weight / spacing. Any colour on it is discarded by the mask.
  final TextStyle? style;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final LinearGradient resolved = AppPalette.mirrored(gradient, direction);
    final TextStyle painted =
        (style ?? const TextStyle()).copyWith(color: Colors.white);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) =>
          resolved.createShader(bounds, textDirection: direction),
      child: Text(
        text,
        style: painted,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
