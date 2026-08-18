import 'package:flutter/material.dart';

/// The motion scale.
///
/// Two rules hold everywhere in this app:
///
/// 1. NOTHING ANIMATES FOREVER. Every effect in the kit is one-shot (an
///    entrance, a sheen that plays once, a state change). The only repeating
///    animation is `ShimmerBox`, and it exists only while data is loading.
/// 2. NO BLUR OVER A SCROLLING LIST. `BackdropFilter` is affordable once, on a
///    static bar; inside a list it costs a full-screen readback per frame.
///
/// Budget Android phones must stay at 60fps, so an effect is either a single
/// composited transform/opacity or it does not ship.
abstract final class AppMotion {
  /// 90ms - a press-down, a colour swap under the finger.
  static const Duration instant = Duration(milliseconds: 90);

  /// 160ms - a chip toggling, a small size change.
  static const Duration fast = Duration(milliseconds: 160);

  /// 260ms - the default: cards, sheets, tab switches.
  static const Duration medium = Duration(milliseconds: 260);

  /// 420ms - a hero, a full-screen transition.
  static const Duration slow = Duration(milliseconds: 420);

  /// The travel of one `AppEntrance` child.
  static const Duration entrance = Duration(milliseconds: 380);

  /// The delay added per item index in a staggered list.
  static const Duration stagger = Duration(milliseconds: 55);

  /// One sweep of the balance sheen. Plays once, then stops.
  static const Duration sheen = Duration(milliseconds: 1500);

  /// One shimmer cycle while a skeleton is on screen.
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Decelerate. The default for anything entering or growing.
  static const Curve emphasized = Curves.easeOutCubic;

  /// The gentle default for a value that is simply changing.
  static const Curve standard = Curves.easeOutQuad;

  /// A small overshoot. Use on the centre action and on success states ONLY;
  /// it is loud.
  static const Curve springy = Curves.easeOutBack;

  /// Accelerate. Anything leaving the screen.
  static const Curve exit = Curves.easeInCubic;

  /// Both ends eased. Sheens and shimmers.
  static const Curve sweep = Curves.easeInOutCubic;

  /// Clamps to 0..1 and keeps the static type `double`.
  ///
  /// `double.clamp` returns `num`, which `strict-casts` rejects on assignment,
  /// so gradient-stop maths goes through here instead.
  static double clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}

/// Fades and lifts its child in ONCE, delayed by [index] steps.
///
/// Wrap each row of a list (or each section of a column) and the screen
/// assembles itself instead of appearing all at once. There is no controller
/// and no ticker left running: `TweenAnimationBuilder` animates to its end
/// value on the first build and then stops.
///
/// ```dart
/// Column(
///   children: AppEntrance.stagger(<Widget>[
///     const BalanceHero(...),
///     const SectionHeader(title: '...'),
///     ...cards,
///   ]),
/// )
///
/// // inside a ListView.builder:
/// itemBuilder: (BuildContext context, int i) =>
///     AppEntrance(index: i, child: DepositCard(deposits[i])),
/// ```
class AppEntrance extends StatelessWidget {
  const AppEntrance({
    required this.child,
    this.index = 0,
    this.enabled = true,
    this.offset = 18,
    super.key,
  });

  /// The widget that animates in.
  final Widget child;

  /// Position in the stagger. Delay is capped at [maxStaggerSlots] so item 200
  /// of a long list is not invisible for ten seconds.
  final int index;

  /// Set false to render [child] immediately - inside a list that the user has
  /// already scrolled, or when the platform has animations disabled.
  final bool enabled;

  /// How far, in logical pixels, the child rises. Vertical only, so it never
  /// needs mirroring.
  final double offset;

  /// After this many items the delay stops growing.
  static const int maxStaggerSlots = 8;

  /// Wraps every child in an [AppEntrance] with an increasing index.
  static List<Widget> stagger(List<Widget> children, {bool enabled = true}) {
    final List<Widget> wrapped = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      wrapped.add(AppEntrance(index: i, enabled: enabled, child: children[i]));
    }
    return wrapped;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final int slot = index < 0
        ? 0
        : (index > maxStaggerSlots ? maxStaggerSlots : index);
    final Duration total = AppMotion.entrance + AppMotion.stagger * slot;
    final double start =
        (AppMotion.stagger.inMilliseconds * slot) / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: total,
      curve: Interval(
        AppMotion.clamp01(start),
        1.0,
        curve: AppMotion.emphasized,
      ),
      builder: (BuildContext context, double t, Widget? inner) => Opacity(
        opacity: AppMotion.clamp01(t),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}
