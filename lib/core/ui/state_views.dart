import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/app_button.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// "There is nothing here yet" - a calm, centred state with one way forward.
///
/// Every string is passed in already localised; this widget owns no text.
///
/// ```dart
/// EmptyState(
///   title: context.s.emptyDefaultTitle,
///   message: context.s.queueEmptyMessage,
///   icon: Icons.receipt_long_rounded,
///   actionLabel: context.s.topUpCta,
///   onAction: startTopUp,
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.tone = AppTone.neutral,
    this.compact = false,
    super.key,
  });

  /// Already-localised headline.
  final String title;

  /// Already-localised supporting line.
  final String? message;

  final IconData icon;

  /// Already-localised button label. The button appears only when this AND
  /// [onAction] are non-null.
  final String? actionLabel;

  final VoidCallback? onAction;

  /// Colours the glyph halo.
  final AppTone tone;

  /// Tighter padding, for an empty state inside a card.
  final bool compact;

  @override
  Widget build(BuildContext context) => _StateBody(
        icon: icon,
        tone: tone,
        title: title,
        message: message,
        compact: compact,
        actionLabel: actionLabel,
        onAction: onAction,
        actionVariant: AppButtonVariant.gradient,
      );
}

/// "It broke" - the same shape as [EmptyState] with a red halo, an optional
/// retry and an optional technical detail line.
///
/// Map an `ApiError` to [title] / [message] with the existing presentation
/// helpers; this widget never inspects an error itself.
///
/// ```dart
/// ErrorState(
///   title: context.s.errorTitleNoConnection,
///   message: context.s.errorCannotReachServer,
///   retryLabel: context.s.retry,
///   onRetry: controller.reload,
/// )
/// ```
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.tone = AppTone.rejected,
    this.details,
    this.compact = false,
    super.key,
  });

  /// Already-localised headline.
  final String title;

  /// Already-localised explanation.
  final String? message;

  /// Already-localised retry label, e.g. `context.s.retry`.
  final String? retryLabel;

  final VoidCallback? onRetry;

  final IconData icon;
  final AppTone tone;

  /// Correlation id or wire code. Rendered small, tabular and dim - never
  /// translated.
  final String? details;

  final bool compact;

  @override
  Widget build(BuildContext context) => _StateBody(
        icon: icon,
        tone: tone,
        title: title,
        message: message,
        compact: compact,
        details: details,
        actionLabel: retryLabel,
        onAction: onRetry,
        actionVariant: AppButtonVariant.tonal,
      );
}

class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.compact,
    required this.actionLabel,
    required this.onAction,
    required this.actionVariant,
    this.details,
  });

  final IconData icon;
  final AppTone tone;
  final String title;
  final String? message;
  final bool compact;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToneColors colors = AppPalette.tone(tone);
    final double halo = compact ? 56 : 76;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compact ? AppSpacing.xl : AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: halo,
            height: halo,
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
              boxShadow: AppShadows.glow(
                colors.glow,
                blur: 24,
                spread: -10,
                offset: Offset.zero,
              ),
            ),
            child: Icon(icon, size: halo * 0.42, color: colors.foreground),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textTertiary,
                ),
              ),
            ),
          if (details != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: Text(
                details!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.textDisabled,
                  fontFeatures: NeonFonts.numericFeatures,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
              child: AppButton(
                label: actionLabel!,
                variant: actionVariant,
                onPressed: onAction,
              ),
            ),
        ],
      ),
    );
  }
}
