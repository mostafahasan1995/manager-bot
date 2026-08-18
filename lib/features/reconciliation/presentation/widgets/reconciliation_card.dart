import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// A titled panel section.
///
/// `cardTheme` is deliberately unset app-wide (its type changed between Flutter
/// versions), so every card in this feature is a themed [Container] built here.
class ReconciliationCard extends StatelessWidget {
  const ReconciliationCard({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.tone,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  /// Tints the border and the title, for a card that is itself a warning.
  final StatusTone? tone;

  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StatusTone? toneValue = tone;
    final SemanticTone? colors =
        toneValue == null ? null : AppSemanticColors.of(context).tone(toneValue);
    final String? titleText = title;
    final String? subtitleText = subtitle;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors?.background ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors?.border ?? theme.colorScheme.outlineVariant,
        ),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (titleText != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 18,
                    color: colors?.foreground ?? theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        titleText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors?.foreground,
                        ),
                      ),
                      if (subtitleText != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          if (titleText != null) const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// A label / value line. [value] is rendered monospaced when it is an id.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.mono = false,
    this.copyable = false,
    super.key,
  });

  final String label;

  /// Plain text value. Ignored when [valueWidget] is given.
  final String? value;

  /// Rich value (a [MoneyText], a chip, ...).
  final Widget? valueWidget;

  /// Tabular, dimmed rendering for UUIDs, cursors and codes.
  final bool mono;

  /// Adds a tap-to-copy affordance. Only meaningful with [value].
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String text = value ?? s.emptyValueDash;
    final Widget rendered = valueWidget ??
        Text(
          text,
          textAlign: TextAlign.end,
          style: mono
              ? AppTheme.monoStyle(context)
              : theme.textTheme.bodyMedium,
        );

    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: rendered,
            ),
          ),
        ],
      ),
    );

    if (!copyable || value == null) {
      return body;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.copiedToClipboard(label: label))),
          );
        }
      },
      child: body,
    );
  }
}

/// A small headline metric: a caption above a value.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
    super.key,
  });

  final String label;
  final Widget value;
  final String? caption;
  final StatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StatusTone? toneValue = tone;
    final SemanticTone? colors =
        toneValue == null ? null : AppSemanticColors.of(context).tone(toneValue);
    final String? captionText = caption;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors?.background ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors?.border ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          value,
          if (captionText != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              captionText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors?.foreground ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-width notice strip. Used for drift, stale rails and re-opened breaks.
class NoticeStrip extends StatelessWidget {
  const NoticeStrip({
    required this.message,
    required this.tone,
    this.icon = Icons.warning_amber_rounded,
    this.action,
    super.key,
  });

  final String message;
  final StatusTone tone;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors = AppSemanticColors.of(context).tone(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.foreground,
              ),
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}
