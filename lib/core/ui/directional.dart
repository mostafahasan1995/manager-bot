import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// Direction-aware icon choices.
///
/// Arabic is the DEFAULT locale, so a "next" chevron points LEFT most of the
/// time. Never hard-code `Icons.chevron_right`; ask here instead.
abstract final class AppIcons {
  /// The chevron that means "forward / deeper": left under RTL, right under
  /// LTR.
  static IconData forwardChevron(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? Icons.chevron_left
          : Icons.chevron_right;

  /// The chevron that means "back": mirror of [forwardChevron].
  static IconData backChevron(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? Icons.chevron_right
          : Icons.chevron_left;

  /// A thin arrow meaning "go", already mirrored.
  static IconData forwardArrow(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? Icons.arrow_back_rounded
          : Icons.arrow_forward_rounded;
}

/// The mirrored "open this" chevron, at the end of a tappable row.
///
/// ```dart
/// Row(children: <Widget>[Expanded(child: title), const ForwardChevron()])
/// ```
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({this.size = 20, this.color, super.key});

  final double size;

  /// Defaults to [AppPalette.textTertiary].
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
        AppIcons.forwardChevron(context),
        size: size,
        color: color ?? AppPalette.textTertiary,
      );
}
