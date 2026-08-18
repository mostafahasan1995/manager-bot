/// Step 3 - send the money.
///
/// The amount is the loudest thing here by a wide margin; everything else on
/// the card is a value the player must copy verbatim into a banking app, so it
/// is rendered tabular and given a copy button rather than being made pretty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_shared.dart';

/// The "transfer it now" step of the top-up flow.
class TopUpPayStep extends ConsumerWidget {
  const TopUpPayStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpDraft draft = ref.watch(topUpDraftProvider);
    final TopUpMethod? method = ref.watch(selectedTopUpMethodProvider);
    final TopUpDestination? destination =
        method?.destinationById(draft.destinationId);
    final Money? amount = draft.amount;

    if (method == null || destination == null || amount == null) {
      return TopUpStepFrame(
        primary: AppButton(
          label: s.topupBack,
          icon: AppIcons.backChevron(context),
          expand: true,
          onPressed: () {
            _back(ref);
          },
        ),
        children: <Widget>[
          ErrorState(
            title: s.topupSubmitFailedTitle,
            message: s.topupNoDestinationsMessage,
            retryLabel: s.topupBack,
            onRetry: () {
              _back(ref);
            },
          ),
        ],
      );
    }

    final DateTime? deadline = draft.deadline;
    final String? reference = draft.reference;
    final Money credited = method.creditedFor(amount);

    return TopUpStepFrame(
      primary: AppButton(
        label: s.topupPaidCta,
        icon: Icons.check_rounded,
        expand: true,
        onPressed: () {
          _advance(ref);
        },
      ),
      secondary: AppButton(
        label: s.topupBack,
        variant: AppButtonVariant.ghost,
        icon: AppIcons.backChevron(context),
        onPressed: () {
          _back(ref);
        },
      ),
      children: <Widget>[
        Text(s.topupPayHeadline, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          s.topupPaySubhead,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // The one glowing surface on this screen.
        GlowCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s.topupAmountToSendLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppPalette.textTertiary,
                      ),
                    ),
                  ),
                  if (deadline != null) TopUpCountdown(deadline: deadline),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountText(amount, fontSize: 34, height: 1.1),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s.topupFeeLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  AmountText(
                    method.feeFixed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s.topupCreditedLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  AmountText(
                    credited,
                    fontSize: 16,
                    tone: AppTone.credited,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TopUpValueRow(
                label: s.paymentMethodLabel,
                value: method.name(context.localeTag),
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              TopUpValueRow(
                label: s.destinationLabel,
                value: destination.label(context.localeTag),
                icon: Icons.savings_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              TopUpValueRow(
                label: s.accountLabel,
                value: destination.accountNumber,
                icon: Icons.tag_rounded,
                copyable: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              TopUpValueRow(
                label: s.accountHolderLabel,
                value: destination.accountHolder,
                icon: Icons.person_rounded,
                copyable: true,
              ),
              if (reference != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TopUpValueRow(
                  label: s.referenceLabel,
                  value: reference,
                  icon: Icons.receipt_long_rounded,
                  copyable: true,
                ),
              ],
              if (deadline != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TopUpValueRow(
                  label: s.topupDeadlineLabel,
                  value: AppDateFormats.mediumDayTime(
                    deadline,
                    context.localeTag,
                  ),
                  icon: Icons.timer_outlined,
                ),
              ],
            ],
          ),
        ),

        if (method.requiresReference)
          TopUpNote(
            text: s.topupReferenceHint,
            icon: Icons.warning_amber_rounded,
            tone: AppTone.attention,
          ),

        SectionHeader(
          title: s.instructionsLabel,
          icon: Icons.receipt_long_rounded,
        ),
        AppCard(
          child: Text(
            method.instructions(context.localeTag),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        TopUpNote(text: s.timesAreLocalNote),
      ],
    );
  }

  static void _advance(WidgetRef ref) {
    ref.read(topUpDraftProvider.notifier).advance();
  }

  static void _back(WidgetRef ref) {
    ref.read(topUpDraftProvider.notifier).back();
  }
}
