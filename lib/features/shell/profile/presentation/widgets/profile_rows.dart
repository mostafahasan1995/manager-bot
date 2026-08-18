import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/ui/ui.dart';

/// One `label ............ value` line inside a card.
///
/// The label is flexible and the value is aligned to the reading END, so the
/// column of values lines up under RTL and LTR alike without a single
/// hard-coded direction.
class ProfileDetailRow extends StatelessWidget {
  const ProfileDetailRow({
    required this.label,
    required this.child,
    this.trailing,
    super.key,
  });

  /// Already-localised field name.
  final String label;

  /// The value. Usually a [ProfileValueText] or a [StatusChip].
  final Widget child;

  /// Optional control at the very end - a copy or a reveal button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// The value half of a [ProfileDetailRow].
///
/// Never used for an amount: those go through `AmountText`, which is exact.
class ProfileValueText extends StatelessWidget {
  const ProfileValueText(this.value, {this.tabular = false, super.key});

  /// Already-localised text, or an identifier that is not translated at all.
  final String value;

  /// Tabular, slashed-zero figures. Turn it on for ids and codes.
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w600,
        fontFeatures: tabular ? NeonFonts.numericFeatures : null,
        fontFamilyFallback: NeonFonts.arabicFallback,
      ),
    );
  }
}

/// A read-only field with a copy button - the referral code and the invite
/// link.
///
/// The value is rendered in the app's id style (tabular, dim, tracked out) so a
/// code can be compared character for character against the bot's message.
class ProfileCopyField extends StatelessWidget {
  const ProfileCopyField({
    required this.label,
    required this.value,
    required this.onCopy,
    this.icon,
    super.key,
  });

  /// Already-localised field name.
  final String label;

  /// The identifier itself. Never translated.
  final String value;

  final VoidCallback onCopy;

  /// Optional leading glyph inside the box.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppPalette.surface2,
            borderRadius: AppRadii.smRadius,
            border: Border.fromBorderSide(
              BorderSide(color: AppPalette.outline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: AppPalette.accentViolet),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NeonTheme.monoStyle(context),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  tooltip: context.s.copyTooltip,
                  color: AppPalette.accentCyan,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A full-width settings line: glyph, label, and either a value or a mirrored
/// chevron.
class ProfileNavRow extends StatelessWidget {
  const ProfileNavRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.iconColor,
    super.key,
  });

  final IconData icon;

  /// Already-localised label.
  final String label;

  /// Trailing read-only value, shown when there is nothing to open.
  final String? value;

  /// When non-null the row is tappable and grows a forward chevron.
  final VoidCallback? onTap;

  /// Defaults to [AppPalette.accentViolet].
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor ?? AppPalette.accentViolet),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.textTertiary,
                fontFeatures: NeonFonts.numericFeatures,
              ),
            ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            const ForwardChevron(size: 18),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(
      onTap: onTap,
      splashColor: AppPalette.sheenLow,
      highlightColor: AppPalette.sheenFaint,
      child: row,
    );
  }
}
