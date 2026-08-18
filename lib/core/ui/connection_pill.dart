import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/motion.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// What the backend health probe currently knows.
enum ConnectionPhase {
  /// A probe is in flight and there is no previous answer to show.
  checking,

  /// The last probe succeeded.
  online,

  /// The last probe failed or timed out.
  offline,
}

/// A compact backend-health badge for an app bar or a home header.
///
/// It renders ONLY what it is given: this widget performs no request, holds no
/// timer and owns no text. The screen runs the `/health/live` probe through the
/// existing `ApiClient`, formats the latency, and pushes the result in - so the
/// pill costs nothing when it is off screen.
///
/// The tone change is animated with [AnimatedContainer], which runs for 160ms
/// on a state change and then stops; nothing ticks while the state is steady.
///
/// ```dart
/// ConnectionPill(
///   phase: ConnectionPhase.online,
///   label: s.connectionOnline,   // MISSING KEY - see the kit manifest
///   detail: '82 ms',
/// )
/// ```
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    required this.phase,
    required this.label,
    this.detail,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final ConnectionPhase phase;

  /// Already-localised state text.
  final String label;

  /// Already-formatted trailing detail, typically the latency ("82 ms").
  /// Rendered tabular so the pill does not jitter between probes.
  final String? detail;

  /// Usually "probe again".
  final VoidCallback? onTap;

  final bool dense;

  /// The tone each phase paints in. Exposed so a screen can colour a matching
  /// banner without duplicating the mapping.
  static AppTone toneOf(ConnectionPhase phase) => switch (phase) {
        ConnectionPhase.checking => AppTone.info,
        ConnectionPhase.online => AppTone.credited,
        ConnectionPhase.offline => AppTone.rejected,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToneColors colors = AppPalette.tone(toneOf(phase));
    final double dot = dense ? 7 : 8;
    final TextStyle? labelStyle =
        (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(color: colors.foreground, fontWeight: FontWeight.w700);

    final Widget leading = phase == ConnectionPhase.checking
        ? SizedBox(
            width: dot + 4,
            height: dot + 4,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: colors.foreground,
            ),
          )
        : Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: colors.foreground,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(
                colors.glow,
                blur: 8,
                spread: -1,
                offset: Offset.zero,
                alpha: 0xCC,
              ),
            ),
          );

    final Widget pill = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          leading,
          SizedBox(width: dense ? 6 : AppSpacing.sm),
          Text(label, style: labelStyle),
          if (detail != null) ...<Widget>[
            SizedBox(width: dense ? 4 : 6),
            Text(
              detail!,
              style: labelStyle?.copyWith(
                color: AppPalette.textTertiary,
                fontWeight: FontWeight.w600,
                fontFeatures: NeonFonts.numericFeatures,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return pill;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.pillRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: pill),
    );
  }
}
