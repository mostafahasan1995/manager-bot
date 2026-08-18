import 'package:flutter/material.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/amount_text.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/motion.dart';
import 'package:manager_bot/core/ui/palette.dart';
import 'package:manager_bot/core/ui/status_chip.dart';

/// THE signature component: the player's balance, unmissable.
///
/// A dark card - not a bright gradient slab - with a gradient edge, a soft
/// bloom and a one-shot sheen that sweeps across when the screen opens and
/// again whenever the amount changes. The card is dark on purpose: white
/// digits on `surface1` clear 17:1, while the same digits on a saturated
/// gradient would sit near 3:1. Decoration never beats the amount.
///
/// The eye toggle keeps its own state so a screen can drop the widget in with
/// no controller; pass [onHiddenChanged] if the choice must be remembered.
///
/// ```dart
/// BalanceHero(
///   amount: Money.fromMinorString('15075000'),
///   label: context.s.homeBalanceLabel,
///   statusLabel: context.s.depositStatusCredited,
///   statusTone: AppTone.credited,
///   footnote: context.s.homeBalanceUpdated(at: '14:05'),
///   action: AppButton(label: context.s.topUpCta, onPressed: startTopUp),
/// )
/// ```
class BalanceHero extends StatefulWidget {
  const BalanceHero({
    required this.amount,
    required this.label,
    this.statusLabel,
    this.statusTone = AppTone.credited,
    this.footnote,
    this.action,
    this.onTap,
    this.gradient = AppPalette.gradientSignature,
    this.amountFontSize = 40,
    this.showHideToggle = true,
    this.initiallyHidden = false,
    this.onHiddenChanged,
    this.hideToggleTooltip,
    this.hiddenPlaceholder = '••••••',
    super.key,
  });

  /// The balance. Exact minor units; never a `double`.
  final Money amount;

  /// Already-localised caption above the amount, e.g. "رصيدك في الكازينو".
  final String label;

  /// Optional already-localised chip beside the caption.
  final String? statusLabel;

  /// Tone of that chip. Ignored when [statusLabel] is null.
  final AppTone statusTone;

  /// Optional already-localised line under the amount (last update, hold, …).
  final String? footnote;

  /// Optional widget under the amount - usually an `AppButton`.
  final Widget? action;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// The edge gradient. Defaults to [AppPalette.gradientSignature].
  final LinearGradient gradient;

  /// Size of the amount. It is the largest text on the screen by design.
  final double amountFontSize;

  /// Show the eye button.
  final bool showHideToggle;

  /// Start masked.
  final bool initiallyHidden;

  /// Fires whenever the player toggles the eye, so a screen can persist it.
  final ValueChanged<bool>? onHiddenChanged;

  /// Already-localised tooltip for the eye button. Null shows no tooltip.
  final String? hideToggleTooltip;

  /// What replaces the digits when hidden. Not language, so it is not a string
  /// key.
  final String hiddenPlaceholder;

  /// Thickness of the gradient edge.
  static const double edge = 1.4;

  @override
  State<BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<BalanceHero> {
  late bool _hidden = widget.initiallyHidden;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextDirection direction = Directionality.of(context);
    final bool animate = !MediaQuery.disableAnimationsOf(context);
    final String digits = _hidden
        ? widget.hiddenPlaceholder
        : AmountText.render(context, widget.amount, showCurrency: false);

    final Widget content = Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppPalette.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (widget.statusLabel != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                StatusChip(
                  label: widget.statusLabel!,
                  tone: widget.statusTone,
                  dense: true,
                ),
              ],
              if (widget.showHideToggle)
                IconButton(
                  onPressed: _toggleHidden,
                  tooltip: widget.hideToggleTooltip,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: AppPalette.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  digits,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: widget.amountFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary,
                    height: 1.05,
                    letterSpacing: -1,
                    fontFeatures: NeonFonts.numericFeatures,
                    fontFamilyFallback: NeonFonts.arabicFallback,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.amount.currency,
                  style: TextStyle(
                    fontSize: widget.amountFontSize * 0.4,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textTertiary,
                    letterSpacing: 0.5,
                    fontFamilyFallback: NeonFonts.arabicFallback,
                  ),
                ),
              ],
            ),
          ),
          if (widget.footnote != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: Text(
                widget.footnote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.textTertiary,
                ),
              ),
            ),
          if (widget.action != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
              child: widget.action,
            ),
        ],
      ),
    );

    final Widget interior = ColoredBox(
      color: AppPalette.surface1,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppPalette.gradientHeroWash),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: widget.onTap == null
                ? content
                : InkWell(
                    onTap: widget.onTap,
                    splashColor: AppPalette.sheenLow,
                    highlightColor: AppPalette.sheenFaint,
                    child: content,
                  ),
          ),
          if (animate)
            Positioned.fill(
              child: IgnorePointer(child: _Sheen(direction: direction, seed: digits)),
            ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.mirrored(widget.gradient, direction),
        borderRadius: AppRadii.lgRadius,
        boxShadow: AppShadows.glow(
          widget.gradient.colors.first,
          blur: 34,
          spread: -10,
          alpha: 0x73,
        ),
      ),
      padding: const EdgeInsets.all(BalanceHero.edge),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg - BalanceHero.edge),
        child: interior,
      ),
    );
  }

  void _toggleHidden() {
    setState(() {
      _hidden = !_hidden;
    });
    widget.onHiddenChanged?.call(_hidden);
  }
}

/// One sweep of light across the hero. Plays once per [seed] value: mounting
/// the card runs it, and changing the amount runs it again because the key
/// changes and the tween restarts. Nothing keeps ticking afterwards.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.direction, required this.seed});

  final TextDirection direction;
  final String seed;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey<String>(seed),
        tween: Tween<double>(begin: -0.3, end: 1.3),
        duration: AppMotion.sheen,
        curve: AppMotion.sweep,
        builder: (BuildContext context, double t, Widget? child) {
          final double lead = AppMotion.clamp01(t - 0.16);
          final double peak = AppMotion.clamp01(t);
          final double tail = AppMotion.clamp01(t + 0.16);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: direction == TextDirection.rtl
                    ? Alignment.topRight
                    : Alignment.topLeft,
                end: direction == TextDirection.rtl
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                colors: const <Color>[
                  AppPalette.clearWhite,
                  AppPalette.sheenMid,
                  AppPalette.clearWhite,
                ],
                stops: <double>[lead, peak, tail],
              ),
            ),
          );
        },
      );
}
