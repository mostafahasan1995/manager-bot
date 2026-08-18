import 'package:flutter/material.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// A titled card that groups one block of configuration.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? caption = subtitle;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleMedium),
                      if (caption != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          caption,
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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A label/value row. [value] is a widget so money can be rendered with
/// [MoneyText] rather than being stringified early.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.hint,
    super.key,
  });

  /// Convenience for plain text values.
  DetailRow.text({
    required String label,
    required String value,
    String? hint,
    bool monospace = false,
    Key? key,
  }) : this(
          label: label,
          value: _MonoOrPlain(value: value, monospace: monospace),
          hint: hint,
          key: key,
        );

  final String label;
  final Widget value;

  /// Small explanatory line under the value, for the many fields on this
  /// surface whose behaviour is not what the name suggests.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? caption = hint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: value,
                ),
              ),
            ],
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonoOrPlain extends StatelessWidget {
  const _MonoOrPlain({required this.value, required this.monospace});

  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    if (monospace) {
      return SelectableText(value, style: AppTheme.monoStyle(context));
    }
    return Text(value, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// A coloured callout. Used for every "this does not do what you think"
/// warning on this surface, of which there are several.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.title,
    required this.tone,
    this.message,
    this.bullets = const <String>[],
    this.icon,
    this.action,
    this.margin = const EdgeInsets.fromLTRB(12, 6, 12, 6),
    super.key,
  });

  final String title;
  final String? message;
  final List<String> bullets;
  final StatusTone tone;
  final IconData? icon;
  final Widget? action;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors = AppSemanticColors.of(context).tone(tone);
    final String? body = message;
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon ?? Icons.info_outline_rounded,
            size: 20,
            color: colors.foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
                for (final String bullet in bullets) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('- ', style: theme.textTheme.bodySmall),
                      Expanded(
                        child: Text(bullet, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
                if (action != null) ...<Widget>[
                  const SizedBox(height: 10),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
