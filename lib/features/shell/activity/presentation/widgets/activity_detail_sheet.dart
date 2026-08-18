import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';
import 'package:manager_bot/features/shell/activity/presentation/activity_presentation.dart';

/// Opens the detail sheet for [deposit] and resolves when it is dismissed.
///
/// The caller owns the selection state: set it before awaiting this, clear it
/// after, and the row underneath stays lit for exactly as long as the sheet is
/// up.
Future<void> showActivityDetailSheet(
  BuildContext context,
  ActivityDeposit deposit,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) =>
          ActivityDetailSheet(deposit: deposit),
    );

/// What happened to one deposit, and what happens next - in plain language.
///
/// Three blocks, in this order: the AMOUNT (the hero, and the most readable
/// thing on the sheet), the timeline of what has already happened, and the
/// record itself. Nothing here is a wire value dressed up as prose: every
/// sentence comes from `AppStrings`, every amount from `AmountText`.
class ActivityDetailSheet extends StatelessWidget {
  const ActivityDetailSheet({required this.deposit, super.key});

  final ActivityDeposit deposit;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final AppTone tone = ActivityStatusStyle.tone(deposit.status);
    final List<ActivityStep> steps = deposit.timeline;
    final ActivityStep? pending = deposit.currentStep ?? deposit.failedStep;
    final ActivityStepKind nextKind = pending?.kind ?? ActivityStepKind.credited;
    final Money? credited = deposit.credited;
    final String? note = deposit.staffNote;
    final String? reference = deposit.reference;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppPalette.surface0,
        borderRadius: AppRadii.sheetRadius,
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsetsDirectional.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppPalette.outlineStrong,
                borderRadius: AppRadii.pillRadius,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GradientText(
                          s.activityDetailTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: ActivityStatusStyle.label(s, deposit.status),
                        tone: tone,
                        icon: ActivityStatusStyle.icon(deposit.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 1. THE AMOUNT. Nothing on this sheet is louder.
                  GlowCard(
                    gradient: ActivityStatusStyle.gradient(deposit.status),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          s.activityDetailAmountLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppPalette.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AmountText(deposit.amount, fontSize: 34, height: 1.1),
                        if (credited != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          const Divider(
                            height: 1,
                            color: AppPalette.outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  s.activityDetailCreditedLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppPalette.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AmountText(
                                credited,
                                fontSize: 17,
                                tone: AppTone.credited,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. WHAT COMES NEXT, in one sentence.
                  SectionHeader(
                    title: s.activityNextStepHeading,
                    icon: Icons.navigation_rounded,
                  ),
                  AppCard(
                    borderColor: AppPalette.tone(tone).border,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          ActivityStepCopy.icon(nextKind),
                          size: 20,
                          color: AppPalette.tone(tone).foreground,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            ActivityStepCopy.body(s, nextKind),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (note != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      borderColor: AppPalette.tone(AppTone.attention).border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            s.activityStaffNoteLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppPalette.tone(AppTone.attention)
                                  .foreground,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            note,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 3. THE TIMELINE.
                  SectionHeader(
                    title: s.activityTimelineHeading,
                    icon: Icons.timeline_rounded,
                  ),
                  AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int i = 0; i < steps.length; i++)
                          _TimelineTile(
                            step: steps[i],
                            statusTone: tone,
                            isLast: i == steps.length - 1,
                          ),
                      ],
                    ),
                  ),

                  // 4. THE RECORD.
                  SectionHeader(
                    title: s.activityRecordHeading,
                    icon: Icons.receipt_long_rounded,
                  ),
                  AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _DetailRow(
                          label: s.activityDetailMethodLabel,
                          value: deposit.methodName,
                        ),
                        _DetailRow(
                          label: s.activityDetailDestinationLabel,
                          value: deposit.destinationLabel,
                        ),
                        _DetailRow(
                          label: s.activityDetailSenderLabel,
                          value: deposit.senderName,
                        ),
                        _DetailRow(
                          label: s.referenceLabel,
                          value: reference ?? s.emptyValueDash,
                          copyable: reference != null,
                        ),
                        _DetailRow(
                          label: s.activityRequestNumberLabel,
                          value: deposit.shortId,
                          copyable: true,
                        ),
                        _DetailRow(
                          label: s.activityDetailSubmittedLabel,
                          value: AppDateFormats.mediumDayTime(
                            deposit.submittedAt,
                            context.localeTag,
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.timesAreLocalNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.textDisabled,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: s.activityCloseButton,
                    variant: AppButtonVariant.ghost,
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One rung of the ladder: a tone-coloured node, a connector down to the next
/// one, a title, one sentence and the moment it happened.
class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.statusTone,
    required this.isLast,
  });

  final ActivityStep step;
  final AppTone statusTone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final AppTone tone = ActivityStepCopy.tone(step.state, statusTone);
    final ToneColors colors = AppPalette.tone(tone);
    final bool isCurrent = step.state == ActivityStepState.current;
    final DateTime? at = step.at;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Column(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                    boxShadow: isCurrent
                        ? AppShadows.glow(
                            colors.glow,
                            blur: 16,
                            spread: -8,
                            offset: Offset.zero,
                          )
                        : null,
                  ),
                  child: Icon(
                    ActivityStepCopy.icon(step.kind),
                    size: 15,
                    color: colors.foreground,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: AppPalette.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          ActivityStepCopy.title(s, step.kind),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: step.state == ActivityStepState.upcoming
                                ? AppPalette.textTertiary
                                : AppPalette.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrent) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                          label: s.activityStepNowBadge,
                          tone: tone,
                          dense: true,
                          glow: false,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ActivityStepCopy.body(s, step.kind),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.textTertiary,
                    ),
                  ),
                  if (at != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppDateFormats.mediumDayTime(at, context.localeTag),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.textDisabled,
                        fontFeatures: NeonFonts.numericFeatures,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label/value pair inside the record card, optionally copyable.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final Widget body = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.textPrimary,
                fontFeatures: NeonFonts.numericFeatures,
              ),
            ),
          ),
          if (copyable) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.copy_rounded,
              size: 16,
              color: AppPalette.textTertiary,
            ),
          ],
        ],
      ),
    );

    final Widget row = copyable
        ? InkWell(
            borderRadius: AppRadii.smRadius,
            onTap: () {
              unawaited(Clipboard.setData(ClipboardData(text: value)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.copiedToClipboard(label: label))),
              );
            },
            child: body,
          )
        : body;

    if (isLast) {
      return row;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        row,
        const Divider(height: 1, color: AppPalette.outline),
      ],
    );
  }
}
