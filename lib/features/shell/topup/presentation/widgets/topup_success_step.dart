/// Step 5 - filed.
///
/// One celebratory surface, the short id the player will quote to a cashier,
/// and three plain sentences about what happens next. The amount stays the
/// most readable thing on screen even here.
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

/// The confirmation step of the top-up flow.
class TopUpSuccessStep extends ConsumerWidget {
  const TopUpSuccessStep({required this.onDone, super.key});

  /// Leaves the flow. The shell decides whether that pops a route or switches
  /// back to the home destination.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpDraft draft = ref.watch(topUpDraftProvider);
    final TopUpMethod? method = ref.watch(selectedTopUpMethodProvider);
    final Money amount = draft.amount ?? Money.zero();
    final String? shortId = draft.shortId;
    final String? receiptName = draft.receiptName;

    return TopUpStepFrame(
      primary: AppButton(
        label: s.topupDoneCta,
        icon: Icons.check_rounded,
        gradient: AppPalette.gradientCredited,
        expand: true,
        onPressed: onDone,
      ),
      secondary: AppButton(
        label: s.topupAnotherCta,
        variant: AppButtonVariant.ghost,
        icon: Icons.add_rounded,
        onPressed: () {
          _again(ref);
        },
      ),
      children: <Widget>[
        GlowCard(
          gradient: AppPalette.gradientCredited,
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            children: <Widget>[
              const AvatarRing(
                icon: Icons.check_rounded,
                size: 72,
                gradient: AppPalette.gradientCredited,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientText(
                s.topupSuccessHeadline,
                gradient: AppPalette.gradientCredited,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountText(amount, fontSize: 30, height: 1.1),
              const SizedBox(height: AppSpacing.md),
              StatusChip(
                label: s.statusSubmitted,
                tone: AppTone.pending,
                icon: Icons.hourglass_bottom_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                s.topupSuccessMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textTertiary,
                ),
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
                label: s.topupShortIdLabel,
                value: shortId ?? s.emptyValueDash,
                icon: Icons.tag_rounded,
                copyable: shortId != null,
              ),
              if (method != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TopUpValueRow(
                  label: s.paymentMethodLabel,
                  value: method.name(context.localeTag),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
              if (receiptName != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TopUpValueRow(
                  label: s.proofFieldReceiptImage,
                  value: receiptName,
                  icon: Icons.receipt_long_rounded,
                ),
              ],
            ],
          ),
        ),

        SectionHeader(
          title: s.topupWhatHappensNext,
          icon: Icons.bolt_rounded,
        ),
        _NextStep(
          index: 1,
          text: s.topupNextStepReview,
          icon: Icons.hourglass_bottom_rounded,
          tone: AppTone.pending,
        ),
        _NextStep(
          index: 2,
          text: s.topupNextStepCredit,
          icon: Icons.savings_rounded,
          tone: AppTone.credited,
        ),
        _NextStep(
          index: 3,
          text: s.topupNextStepNotify,
          icon: Icons.notifications_active_rounded,
          tone: AppTone.info,
        ),
        TopUpNote(text: s.timesAreLocalNote),
      ],
    );
  }

  static void _again(WidgetRef ref) {
    ref.read(topUpDraftProvider.notifier).reset();
  }
}

/// One numbered "what happens next" line.
class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.index,
    required this.text,
    required this.icon,
    required this.tone,
  });

  final int index;
  final String text;
  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = AppPalette.tone(tone);
    return AppCard(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          AvatarRing(
            icon: icon,
            size: 40,
            badge: CountBadge(
              count: index,
              color: colors.foreground,
              foreground: AppPalette.textOnAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
