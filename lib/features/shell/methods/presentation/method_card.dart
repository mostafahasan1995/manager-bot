/// The two card shapes of the طرق الدفع list.
///
/// [FeaturedMethodCard] is the single hero - a `GlowCard` with the method's own
/// gradient edge and the "شحن الآن" call to action on it. [MethodCard] is the
/// quiet row shape used for everything else, including the temporarily paused
/// rails, which are deliberately drained of glow and colour so the difference
/// is obvious at a glance rather than only on reading.
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';
import 'package:manager_bot/features/shell/methods/presentation/methods_formats.dart';

/// The hero card. At most ONE of these is on screen at a time.
class FeaturedMethodCard extends StatelessWidget {
  const FeaturedMethodCard({
    required this.method,
    required this.onOpen,
    this.onStartTopUp,
    super.key,
  });

  final PlayerPaymentMethod method;

  /// Opens the detail sheet.
  final VoidCallback onOpen;

  /// Starts a top-up. Null disables the call to action.
  final VoidCallback? onStartTopUp;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final LinearGradient gradient = MethodsFormats.gradientOf(method.accent);

    return GlowCard(
      gradient: gradient,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarRing(
                initials: method.monogram,
                size: 58,
                gradient: gradient,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StatusChip(
                      label: s.methodsBadgeMostUsed,
                      tone: AppTone.info,
                      icon: Icons.star_rounded,
                      dense: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GradientText(
                      method.displayName(context.localeTag),
                      gradient: gradient,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.rail.label(s),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MethodLimitsRow(method: method),
          const SizedBox(height: AppSpacing.md),
          MethodFactsWrap(method: method),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.methodsTopUpNowCta,
            icon: Icons.add_rounded,
            expand: true,
            gradient: gradient,
            onPressed: onStartTopUp,
          ),
        ],
      ),
    );
  }
}

/// The list row. Used for open, busy and paused rails alike - the difference
/// is carried by colour, ring and glow, never by hiding information.
class MethodCard extends StatelessWidget {
  const MethodCard({
    required this.method,
    required this.onOpen,
    this.selected = false,
    super.key,
  });

  final PlayerPaymentMethod method;
  final VoidCallback onOpen;

  /// True while this method's detail sheet is the one that is open.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool live = method.acceptsTopUp;
    final LinearGradient gradient = MethodsFormats.gradientOf(method.accent);
    final AppTone tone = MethodsFormats.availabilityTone(method.availability);
    final String? note =
        MethodsFormats.availabilityNote(method.availability, s);

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            AvatarRing(
              initials: method.monogram,
              size: 48,
              gradient: gradient,
              active: live,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    method.displayName(context.localeTag),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: live
                          ? AppPalette.textPrimary
                          : AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.rail.label(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const ForwardChevron(size: 18, color: AppPalette.textTertiary),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        MethodLimitsRow(method: method),
        const SizedBox(height: AppSpacing.md),
        MethodFactsWrap(method: method),
        if (note != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _NoteLine(text: note, tone: tone),
        ],
        const SizedBox(height: AppSpacing.md),
        _CheckedLine(checkedAgo: method.checkedAgo),
      ],
    );

    return AppCard(
      onTap: onOpen,
      showShadow: live,
      borderColor: selected ? AppPalette.accentCyan : null,
      // A paused rail is demoted, never made unreadable: 0.7 still leaves the
      // amounts above 9:1 against the canvas.
      child: live ? body : Opacity(opacity: 0.7, child: body),
    );
  }
}

/// Minimum and maximum, side by side. The amounts are the most readable thing
/// in the card by design - they are `AmountText`, exact over `BigInt`.
class MethodLimitsRow extends StatelessWidget {
  const MethodLimitsRow({required this.method, super.key});

  final PlayerPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _AmountStat(label: s.pmMinimumLabel, amount: method.minAmount),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AmountStat(label: s.pmMaximumLabel, amount: method.maxAmount),
        ),
      ],
    );
  }
}

/// Health, settlement speed and the reference rule, as chips.
///
/// A `Wrap` rather than a `Row`: "Temporarily unavailable" is a long phrase in
/// English and a chip must never push the method's name off the card.
class MethodFactsWrap extends StatelessWidget {
  const MethodFactsWrap({required this.method, super.key});

  final PlayerPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        StatusChip(
          label: MethodsFormats.availabilityLabel(method.availability, s),
          tone: MethodsFormats.availabilityTone(method.availability),
          icon: MethodsFormats.availabilityIcon(method.availability),
          dense: true,
          glow: false,
        ),
        StatusChip(
          label: MethodsFormats.settlement(method.settlement, s),
          tone: AppTone.approved,
          icon: Icons.schedule_rounded,
          dense: true,
          glow: false,
        ),
        StatusChip(
          label: method.requiresReference
              ? s.referenceRequiredLabel
              : s.methodsReferenceOptionalShort,
          tone: method.requiresReference ? AppTone.attention : AppTone.neutral,
          icon: Icons.confirmation_number_rounded,
          dense: true,
          glow: false,
        ),
      ],
    );
  }
}

class _AmountStat extends StatelessWidget {
  const _AmountStat({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AmountText(amount, fontSize: 16, maxLines: 2),
      ],
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.text, required this.tone});

  final String text;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToneColors colors = AppPalette.tone(tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.info_rounded, size: 16, color: colors.foreground),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckedLine extends StatelessWidget {
  const _CheckedLine({required this.checkedAgo});

  final Duration checkedAgo;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: AppPalette.textDisabled,
    );
    return Row(
      children: <Widget>[
        const Icon(
          Icons.refresh_rounded,
          size: 14,
          color: AppPalette.textDisabled,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(s.methodsCheckedLabel, style: style),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            MethodsFormats.checked(checkedAgo, s),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(fontFeatures: NeonFonts.numericFeatures),
          ),
        ),
      ],
    );
  }
}
