import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// A compact, tone-coloured state badge with an optional bloom.
///
/// The chip knows nothing about deposits: the screen maps its own status onto
/// an [AppTone] and passes an already-localised label, so the same idea is
/// always the same colour.
///
/// ```dart
/// StatusChip(
///   label: context.s.depositStatusPending,
///   tone: AppTone.pending,
///   icon: Icons.hourglass_bottom_rounded,
/// )
/// ```
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    this.dense = false,
    this.glow = true,
    this.onTap,
    super.key,
  });

  /// Already-localised text. Never a raw wire value such as `UNDER_REVIEW`.
  final String label;

  final AppTone tone;

  /// Optional leading glyph, tinted with the tone foreground.
  final IconData? icon;

  /// Smaller text and padding, for a chip inside a dense row.
  final bool dense;

  /// Soft outer bloom in the tone colour. Turn it off inside a list of many
  /// chips - a dozen blurs in one viewport is not free.
  final bool glow;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = AppPalette.tone(tone);
    final ThemeData theme = Theme.of(context);
    final TextStyle style =
        (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ) ??
            TextStyle(color: colors.foreground);
    final BorderRadius shape = BorderRadius.circular(AppRadii.pill);

    final Widget chip = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: shape,
        border: Border.all(color: colors.border),
        boxShadow: glow
            ? AppShadows.glow(
                colors.glow,
                blur: 14,
                spread: -8,
                offset: Offset.zero,
                alpha: 0x59,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: colors.foreground),
            SizedBox(width: dense ? AppSpacing.xs : 6),
          ],
          Text(label, style: style),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: chip),
    );
  }
}
