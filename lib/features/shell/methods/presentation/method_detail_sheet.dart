/// The detail sheet behind a tap on a payment-method card.
///
/// It answers the three questions a player actually has - how do I pay, what
/// must I be able to show afterwards, and can I start right now - and ends in
/// the "شحن الآن" call to action, which is disabled (never hidden) while the
/// rail is paused.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';
import 'package:manager_bot/features/shell/methods/presentation/method_card.dart';
import 'package:manager_bot/features/shell/methods/presentation/methods_formats.dart';

/// Opens [MethodDetailSheet] as a modal bottom sheet.
///
/// Callers are tap handlers, so wrap this in `unawaited(...)` rather than
/// making the handler async - `AppButton.onPressed` and `AppCard.onTap` are
/// both plain `VoidCallback`s.
Future<void> showMethodDetailSheet(
  BuildContext context, {
  required PlayerPaymentMethod method,
  VoidCallback? onStartTopUp,
  VoidCallback? onDismissed,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.surface0,
    barrierColor: AppPalette.scrim,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
    builder: (BuildContext _) => MethodDetailSheet(
      method: method,
      onStartTopUp: onStartTopUp,
    ),
  );
  onDismissed?.call();
}

/// Full instructions for one rail.
class MethodDetailSheet extends StatelessWidget {
  const MethodDetailSheet({required this.method, this.onStartTopUp, super.key});

  final PlayerPaymentMethod method;

  /// Starts a top-up. Null - or a paused rail - disables the call to action.
  final VoidCallback? onStartTopUp;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;
    final ThemeData theme = Theme.of(context);
    final LinearGradient gradient = MethodsFormats.gradientOf(method.accent);
    final bool live = method.acceptsTopUp;
    final AppTone tone = MethodsFormats.availabilityTone(method.availability);
    final String? note =
        MethodsFormats.availabilityNote(method.availability, s);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                0,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  AvatarRing(
                    initials: method.monogram,
                    size: 52,
                    gradient: gradient,
                    active: live,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        GradientText(
                          method.displayName(localeTag),
                          gradient: gradient,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          method.rail.label(s),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: AppEntrance.stagger(<Widget>[
                  Row(
                    children: <Widget>[
                      StatusChip(
                        label: MethodsFormats.availabilityLabel(
                          method.availability,
                          s,
                        ),
                        tone: tone,
                        icon: MethodsFormats.availabilityIcon(
                          method.availability,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          MethodsFormats.checked(method.checkedAgo, s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.textDisabled,
                            fontFeatures: NeonFonts.numericFeatures,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (note != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    _SheetNote(text: note, tone: tone),
                  ],
                  SectionHeader(
                    title: s.pmLimitsSection,
                    icon: Icons.tune_rounded,
                  ),
                  AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        MethodLimitsRow(method: method),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailRow(
                          label: s.pmFixedFeeLabel,
                          value: method.hasFee
                              ? AmountText(method.fixedFee, fontSize: 15)
                              : Text(
                                  s.methodsFeeNone,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppPalette.moneyPositive,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          label: s.methodsSettlementLabel,
                          value: Text(
                            MethodsFormats.settlement(method.settlement, s),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFeatures: NeonFonts.numericFeatures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: s.methodsDestinationTitle,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          s.accountLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                method.destinationAccount,
                                style: NeonTheme.monoStyle(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _copyAccount(context, s),
                              tooltip: s.copyTooltip,
                              icon: const Icon(
                                Icons.content_copy_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          label: s.accountHolderLabel,
                          value: Text(
                            method.destinationHolder.resolve(localeTag),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: s.methodsHowToTitle,
                    icon: Icons.list_alt_rounded,
                  ),
                  AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int i = 0; i < method.steps.length; i++)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              bottom: i == method.steps.length - 1
                                  ? 0
                                  : AppSpacing.md,
                            ),
                            child: _StepLine(
                              index: i,
                              gradient: gradient,
                              text: method.steps[i].resolve(localeTag),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: s.methodsProofTitle,
                    icon: Icons.photo_camera_rounded,
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final LocalizedText item in method.proofItems)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _BulletLine(text: item.resolve(localeTag)),
                          ),
                        Text(
                          method.requiresReference
                              ? s.methodsReferenceHintRequired
                              : s.methodsReferenceHintOptional,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: method.requiresReference
                                ? AppPalette.tone(AppTone.attention).foreground
                                : AppPalette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: AppButton(
                label: s.methodsTopUpNowCta,
                icon: Icons.add_rounded,
                expand: true,
                gradient: gradient,
                onPressed: live ? onStartTopUp : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAccount(BuildContext context, AppStrings s) {
    unawaited(
      Clipboard.setData(ClipboardData(text: method.destinationAccount)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.methodsAccountCopied)),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 4,
        margin: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppPalette.outlineStrong,
          borderRadius: AppRadii.pillRadius,
        ),
      );
}

class _SheetNote extends StatelessWidget {
  const _SheetNote({required this.text, required this.tone});

  final String text;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = AppPalette.tone(tone);
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      color: colors.background,
      borderColor: colors.border,
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_rounded, size: 18, color: colors.foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.textTertiary,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: value),
        ],
      );
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.gradient,
    required this.text,
  });

  final int index;
  final LinearGradient gradient;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            gradient: AppPalette.mirrored(
              gradient,
              Directionality.of(context),
            ),
            borderRadius: AppRadii.pillRadius,
          ),
          // A numeral, not a sentence: Western digits in both locales, exactly
          // like every other number this app shows.
          child: Text(
            '${index + 1}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppPalette.textOnAccent,
              fontFeatures: NeonFonts.numericFeatures,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 3),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 6),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppPalette.moneyPositive,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.textSecondary,
                  ),
            ),
          ),
        ],
      );
}
