import 'package:flutter/material.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// A compact, colour-coded state badge.
///
/// The chip knows nothing about deposits or breaks: the feature maps its own
/// enum to a [StatusTone] and a label, so every screen colours the same idea
/// the same way.
///
/// ```dart
/// StatusChip(
///   label: status.label(context.s),
///   tone: switch (status) {
///     DepositStatus.credited || DepositStatus.approved => StatusTone.approve,
///     DepositStatus.rejected || DepositStatus.reversed => StatusTone.reject,
///     DepositStatus.creditFailed => StatusTone.failed,
///     _ => StatusTone.pending,
///   },
/// )
/// ```
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    this.dense = false,
    this.onTap,
    super.key,
  });

  /// Short, already human-readable AND already LOCALISED text. Do NOT pass a
  /// raw enum wire value to a screen an admin reads; pass `x.label(context.s)`.
  final String label;

  final StatusTone tone;
  final IconData? icon;

  /// Smaller padding and text, for a chip inside a dense list row.
  final bool dense;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.of(context).tone(tone);
    final theme = Theme.of(context);
    final textStyle = (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ) ??
        TextStyle(color: colors.foreground);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(dense ? 6 : 8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: colors.foreground),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(dense ? 6 : 8),
      onTap: onTap,
      child: chip,
    );
  }
}

/// A row of small badges, e.g. `AdminDepositView.riskFlags`.
///
/// Risk flags arrive as `String[]` of an open TypeScript const. The CALLER maps
/// each wire code to its catalogue label (`RiskFlags.label(code, context.s)`)
/// and passes the result; this widget renders what it is given verbatim. It
/// deliberately no longer lowercases or de-underscores, because that mangled an
/// Arabic label and a wire code alike.
class RiskFlagStrip extends StatelessWidget {
  const RiskFlagStrip({required this.flags, this.dense = true, super.key});

  /// Already-localised labels, NOT raw wire codes.
  final List<String> flags;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: flags
          .map(
            (flag) => StatusChip(
              label: flag,
              tone: StatusTone.failed,
              icon: Icons.flag_outlined,
              dense: dense,
            ),
          )
          .toList(growable: false),
    );
  }
}
