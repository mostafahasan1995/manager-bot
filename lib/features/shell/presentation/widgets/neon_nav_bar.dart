import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/presentation/shell_tab.dart';

/// The hairline that caps the bar. Cyan fading through pink is the whole brand
/// in one and a half pixels, and it is the only decoration on the plate.
const LinearGradient _hairlineGradient = LinearGradient(
  colors: <Color>[
    Color(0x0025F4EE),
    Color(0x8C25F4EE),
    Color(0x99FF2E63),
    Color(0x00FF8A3D),
  ],
);

/// The plate fill: a hair lighter at the top so the bar reads as a surface
/// sitting in front of the canvas rather than a hole cut out of it.
const LinearGradient _plateGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[Color(0xFF14141F), Color(0xFF08080E)],
);

/// Distance from the bottom of the plate's content box to the bottom of every
/// label - tabs and the centre action alike. It is what makes the five labels
/// share one baseline even though the centre column is 30px taller.
const double _labelInset = 10;

/// How far each glitch channel sits to either side of the centre capsule.
const double _channelOffset = 4;

/// The five-slot bottom bar: four destinations and a RAISED CENTRE ACTION.
///
/// This is not a `NavigationBar` with a `FloatingActionButton` bolted on. It is
/// a `Stack` of three layers, bottom to top:
///
/// 1. a short scrim above the plate, so a list scrolling underneath dissolves
///    into the bar instead of being guillotined by it;
/// 2. the opaque plate - gradient fill, gradient hairline, one lift shadow -
///    carrying a `Row` of five equal slots, the middle one left EMPTY;
/// 3. the centre action, in its own layer, centred over that empty slot and
///    rising [centreOverhang] above the plate so it breaks the bar's plane.
///
/// Every effect is a composited transform, opacity or static shadow: there is
/// no `BackdropFilter` (it would cost a full-screen readback on every frame the
/// list under it scrolls) and nothing animates forever. The only motion is a
/// 260ms selection cross-fade and a 90ms press on the centre.
///
/// Direction is never hard-coded. The `Row` orders itself from `Directionality`
/// so الرئيسية lands on the RIGHT under Arabic, and even the hairline gradient
/// is mirrored through `AppPalette.mirrored`.
class NeonNavBar extends StatelessWidget {
  const NeonNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.centreLabel,
    required this.onCentre,
    super.key,
  });

  /// The normal destinations, in branch order.
  final List<ShellTab> tabs;

  /// The selected branch index.
  final int currentIndex;

  /// Fired with a branch index when a normal destination is tapped - including
  /// when the selected one is re-tapped, which is how the shell pops a tab back
  /// to its root.
  final ValueChanged<int> onSelect;

  /// Label under the raised centre action (شحن).
  final String centreLabel;

  /// Fired when the raised centre action is tapped.
  final VoidCallback onCentre;

  /// Height of the opaque plate, ABOVE the bottom safe area.
  static const double plateHeight = 66;

  /// How far the centre action rises above the plate, glow headroom included.
  static const double centreOverhang = 26;

  /// The bar's height before the bottom safe area is added. Screens clear it
  /// with `AppSpacing.navClearance` (108), which leaves a 16px gap.
  static const double contentHeight = plateHeight + centreOverhang;

  /// The centre action's gradient plate. Kept narrower than a slot so the two
  /// glitch channels behind it never crowd إيداعاتي or طرق الدفع.
  static const Size centreSize = Size(62, 52);

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: contentHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: plateHeight + bottomInset,
            height: centreOverhang,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppPalette.gradientScrim),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            height: plateHeight + bottomInset,
            child: _NavPlate(
              tabs: tabs,
              currentIndex: currentIndex,
              onSelect: onSelect,
              bottomInset: bottomInset,
              strings: s,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: bottomInset + _labelInset,
            child: Center(
              child: _CentreAction(label: centreLabel, onTap: onCentre),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layer 2: the plate and its five slots.
class _NavPlate extends StatelessWidget {
  const _NavPlate({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.bottomInset,
    required this.strings,
  });

  final List<ShellTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final double bottomInset;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    // The empty slot goes exactly in the middle, so the centre action stays
    // centred whether there are four destinations or (one day) six.
    final int gapSlot = tabs.length ~/ 2;
    final List<Widget> slots = <Widget>[];
    for (int i = 0; i < tabs.length; i++) {
      if (i == gapSlot) {
        slots.add(const Expanded(child: SizedBox.shrink()));
      }
      final ShellTab tab = tabs[i];
      slots.add(
        Expanded(
          child: _NavTabItem(
            tab: tab,
            label: tab.label(strings),
            selected: tab.branchIndex == currentIndex,
            onTap: () => onSelect(tab.branchIndex),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: _plateGradient,
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 1.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppPalette.mirrored(_hairlineGradient, direction),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: bottomInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: slots,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One normal destination.
///
/// The whole selected state is a single 0..1 number: the icon swaps weight and
/// lerps to the destination's accent, a soft accent pill blooms behind it, and
/// the label lerps from tertiary to primary and thickens. One
/// `TweenAnimationBuilder` drives all of it and then stops - no controller, no
/// ticker left running in a bar that is on screen for the whole session.
class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.tab,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellTab tab;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) {
            unawaited(HapticFeedback.selectionClick());
          }
          onTap();
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
          duration: animate ? AppMotion.medium : Duration.zero,
          curve: AppMotion.emphasized,
          builder: (BuildContext context, double t, Widget? _) => _content(t),
        ),
      ),
    );
  }

  Widget _content(double t) {
    final double progress = AppMotion.clamp01(t);
    final Color iconColor =
        Color.lerp(AppPalette.textTertiary, tab.accent, progress) ?? tab.accent;
    final Color labelColor =
        Color.lerp(AppPalette.textTertiary, AppPalette.textPrimary, progress) ??
            AppPalette.textPrimary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 0, 2, _labelInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Opacity(
                  opacity: progress,
                  child: SizedBox(
                    width: 40,
                    height: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tab.accent.withAlpha(0x1F),
                        borderRadius: AppRadii.pillRadius,
                        boxShadow: AppShadows.glow(
                          tab.accent,
                          blur: 16,
                          offset: Offset.zero,
                          alpha: 0x7A,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1 + 0.10 * progress,
                  child: Icon(
                    progress > 0.5 ? tab.selectedIcon : tab.icon,
                    size: 23,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              letterSpacing: 0.1,
              fontWeight: progress > 0.5 ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
              fontFamilyFallback: NeonFonts.arabicFallback,
            ),
          ),
        ],
      ),
    );
  }
}

/// Layer 3: the hero of the bar.
///
/// A gradient capsule with two hard-offset colour channels behind it - the
/// TikTok record button's split-channel signature, borrowed and not copied -
/// wrapped in a violet/pink bloom so it reads as lit rather than merely
/// coloured. Pressing it scales to 90% in 90ms and springs back; that is the
/// only stateful motion in the whole bar.
class _CentreAction extends StatefulWidget {
  const _CentreAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CentreAction> createState() => _CentreActionState();
}

class _CentreActionState extends State<_CentreAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) => _setPressed(true),
        onTapUp: (TapUpDetails details) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          unawaited(HapticFeedback.mediumImpact());
          widget.onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: _pressed ? 0.90 : 1,
              duration: animate ? AppMotion.instant : Duration.zero,
              curve: AppMotion.springy,
              child: const _CentrePlate(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.15,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary,
                fontFamilyFallback: NeonFonts.arabicFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }
}

/// The capsule itself, split out so a press rebuilds nothing but a transform:
/// `AnimatedScale` is handed a `const _CentrePlate()` that never rebuilds.
class _CentrePlate extends StatelessWidget {
  const _CentrePlate();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: NeonNavBar.centreSize.width + 10,
        height: NeonNavBar.centreSize.height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.translate(
              offset: const Offset(-_channelOffset, 0),
              child: const _Channel(color: AppPalette.accentCyan),
            ),
            Transform.translate(
              offset: const Offset(_channelOffset, 0),
              child: const _Channel(color: AppPalette.accentPink),
            ),
            SizedBox(
              width: NeonNavBar.centreSize.width,
              height: NeonNavBar.centreSize.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppPalette.gradientSignature,
                  borderRadius: AppRadii.lgRadius,
                  boxShadow: <BoxShadow>[
                    ...AppShadows.glow(
                      AppPalette.accentViolet,
                      blur: 22,
                      spread: -4,
                      offset: const Offset(0, 8),
                      alpha: 0x99,
                    ),
                    ...AppShadows.glow(
                      AppPalette.accentPink,
                      blur: 30,
                      spread: -10,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// The two offset colour channels. Symmetric by construction, so they read the
/// same under LTR and RTL and need no mirroring.
class _Channel extends StatelessWidget {
  const _Channel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: NeonNavBar.centreSize.width,
        height: NeonNavBar.centreSize.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withAlpha(0x7A),
            borderRadius: AppRadii.lgRadius,
          ),
        ),
      );
}
