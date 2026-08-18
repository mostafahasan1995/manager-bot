import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/motion.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// A hand-written skeleton bar: a light band sweeping across a dark rounded
/// rectangle.
///
/// No package. One [AnimationController] per box, driving a gradient's stops -
/// no opacity layer, no blur, no `RepaintBoundary` gymnastics. It is the ONLY
/// repeating animation in the kit and it exists only while data is loading, so
/// tear it down as soon as the real content arrives. It also stops itself when
/// the platform asks for reduced motion.
///
/// ```dart
/// Column(
///   crossAxisAlignment: CrossAxisAlignment.start,
///   children: const <Widget>[
///     ShimmerBox(width: 160, height: 22),
///     SizedBox(height: 10),
///     ShimmerBox(height: 14),
///     SizedBox(height: 10),
///     ShimmerBox(width: 220, height: 14),
///   ],
/// )
/// ```
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height = 16,
    this.radius = AppRadii.sm,
    this.margin,
    this.baseColor = AppPalette.surface2,
    this.highlightColor = AppPalette.surface3,
    super.key,
  });

  /// Null stretches to the incoming max width.
  final double? width;

  final double height;

  /// Corner radius. Pass `height / 2` for a pill, `height` for a circle when
  /// width == height.
  final double radius;

  final EdgeInsetsGeometry? margin;

  /// The resting fill.
  final Color baseColor;

  /// The colour of the travelling band.
  final Color highlightColor;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(widget.radius);
    return Container(
      // Null means "fill the row": a bare DecoratedBox has no intrinsic size,
      // so under loose constraints it would collapse to zero width.
      width: widget.width ?? double.infinity,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = _controller.value * 1.6 - 0.3;
          final double lead = AppMotion.clamp01(t - 0.22);
          final double peak = AppMotion.clamp01(t);
          final double tail = AppMotion.clamp01(t + 0.22);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                colors: <Color>[
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: <double>[lead, peak, tail],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A ready-made skeleton for one list row: avatar, two lines, an amount.
///
/// Use it while a demo/repository future resolves so the list does not pop in
/// from nothing.
class ShimmerRow extends StatelessWidget {
  const ShimmerRow({this.showLeading = true, this.padding, super.key});

  /// Draw the round leading placeholder.
  final bool showLeading;

  /// Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            if (showLeading) ...const <Widget>[
              ShimmerBox(width: 44, height: 44, radius: 22),
              SizedBox(width: AppSpacing.md),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ShimmerBox(height: 14),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerBox(width: 120, height: 12),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const ShimmerBox(width: 76, height: 18),
          ],
        ),
      );
}
