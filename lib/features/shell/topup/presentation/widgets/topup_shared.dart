/// Pieces every top-up step reuses: the page frame with its action bar, a
/// label/value row with a copy button, the transfer countdown, a note line and
/// the dashed frame the receipt placeholder is drawn in.
///
/// Nothing here owns text: every string arrives already localised.
library;

import 'dart:async';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';

/// The shape every step has: a scrolling body over a pinned action bar.
///
/// Children are staggered in, so each step assembles itself instead of
/// appearing all at once.
class TopUpStepFrame extends StatelessWidget {
  const TopUpStepFrame({
    required this.children,
    required this.primary,
    this.secondary,
    super.key,
  });

  /// The step's body, top to bottom.
  final List<Widget> children;

  /// The one forward action. Pass an [AppButton] with `expand: true`.
  final Widget primary;

  /// The back action, on the reading-start side of [primary].
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final Widget? back = secondary;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: AppEntrance.stagger(children),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppPalette.surface0,
            border: Border(top: BorderSide(color: AppPalette.outline)),
            boxShadow: AppShadows.raised,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.lg,
            ),
            child: Row(
              children: <Widget>[
                if (back != null) ...<Widget>[
                  back,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A label over a value, with an optional copy button.
///
/// The value is drawn with tabular figures because most of them are account
/// numbers, IBANs and references that get compared digit by digit against a
/// Telegram message.
class TopUpValueRow extends StatelessWidget {
  const TopUpValueRow({
    required this.label,
    required this.value,
    this.icon,
    this.copyable = false,
    super.key,
  });

  /// Already-localised caption.
  final String label;

  /// The literal value. Never reformatted.
  final String value;

  /// Optional leading glyph.
  final IconData? icon;

  /// Adds a copy button that puts [value] on the clipboard.
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final IconData? glyph = icon;
    return Row(
      children: <Widget>[
        if (glyph != null) ...<Widget>[
          Icon(glyph, size: 18, color: AppPalette.textTertiary),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppPalette.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                  letterSpacing: 0.2,
                  fontFeatures: NeonFonts.numericFeatures,
                  fontFamilyFallback: NeonFonts.arabicFallback,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            tooltip: s.copyTooltip,
            onPressed: () {
              copyToClipboard(context, value, label);
            },
            icon: const Icon(
              Icons.content_copy_rounded,
              size: 18,
              color: AppPalette.accentCyan,
            ),
          ),
      ],
    );
  }
}

/// Puts [value] on the clipboard and confirms it with the standard toast.
///
/// Fire-and-forget on purpose: the platform channel cannot fail in a way the
/// player could act on, and blocking the tap on it would feel laggy.
void copyToClipboard(BuildContext context, String value, String label) {
  unawaited(Clipboard.setData(ClipboardData(text: value)));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.s.copiedToClipboard(label: label))),
  );
}

/// A quiet explanatory line: a small glyph and a sentence.
class TopUpNote extends StatelessWidget {
  const TopUpNote({
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppTone.neutral,
    super.key,
  });

  /// Already-localised sentence.
  final String text;

  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = AppPalette.tone(tone);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.textTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The transfer window, ticking down once a second.
///
/// The only timer in the flow. It cancels itself the moment it reaches zero and
/// in `dispose`, so nothing is left running behind the sheet.
class TopUpCountdown extends StatefulWidget {
  const TopUpCountdown({required this.deadline, super.key});

  /// Local wall-clock time the window closes.
  final DateTime deadline;

  @override
  State<TopUpCountdown> createState() => _TopUpCountdownState();
}

class _TopUpCountdownState extends State<TopUpCountdown> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Duration _remaining() {
    final Duration difference = widget.deadline.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  void _tick(Timer timer) {
    final Duration next = _remaining();
    if (next.inSeconds == _left.inSeconds) {
      return;
    }
    setState(() {
      _left = next;
    });
    if (next == Duration.zero) {
      timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final bool expired = _left == Duration.zero;
    final AppTone tone = expired
        ? AppTone.rejected
        : (_left.inMinutes < 5 ? AppTone.attention : AppTone.pending);
    return StatusChip(
      label: expired
          ? s.topupDeadlineExpired
          : s.topupCountdown(
              minutes: _left.inMinutes,
              seconds: _left.inSeconds % 60,
            ),
      tone: tone,
      icon: Icons.timer_outlined,
      dense: true,
      glow: false,
    );
  }
}

/// A dashed rounded rectangle - the "drop your receipt here" frame.
///
/// Hand-drawn with a [CustomPainter] because the dependency set has no border
/// package and a dashed edge is not expressible with `BoxDecoration`.
class TopUpDashedFrame extends CustomPainter {
  const TopUpDashedFrame({
    this.color = AppPalette.outlineStrong,
    this.radius = AppRadii.md,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const double dash = 9;
    const double gap = 6;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end =
            distance + dash < metric.length ? distance + dash : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(TopUpDashedFrame oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
