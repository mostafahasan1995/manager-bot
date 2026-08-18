/// شحن الرصيد - the destination behind the raised centre action.
///
/// One screen, five steps, one draft. The header (wordmark, step rail, step
/// name) never moves; only the body swaps, so the player always knows how far
/// along they are and stepping back never costs them anything they typed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_amount_step.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_method_step.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_pay_step.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_receipt_step.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_step_indicator.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_success_step.dart';

/// The top-up flow.
///
/// Present it full screen (that is the TikTok-register shape the raised centre
/// action implies). If the shell keeps its floating nav bar visible over this
/// screen, pass `bottomInset: AppSpacing.navClearance` so the action bar is
/// not covered.
class TopUpScreen extends ConsumerWidget {
  const TopUpScreen({this.onClose, this.bottomInset = 0, super.key});

  /// How the shell dismisses the flow. When null the screen pops its route.
  final VoidCallback? onClose;

  /// Space to leave under the action bar for a floating nav bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpStep step = ref.watch(
      topUpDraftProvider.select((TopUpDraft draft) => draft.step),
    );

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: bottomInset),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GradientText(
                            s.topupTitle,
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: s.topupCloseTooltip,
                          onPressed: () {
                            _close(context, ref);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TopUpStepIndicator(current: step),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            topUpStepLabel(s, step),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          s.topupStepOfTotal(
                            step: step.index + 1,
                            total: TopUpStep.values.length,
                          ),
                          style: NeonTheme.monoStyle(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, ref, step)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, TopUpStep step) =>
      AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: AppMotion.exit,
        child: switch (step) {
          TopUpStep.amount => const TopUpAmountStep(
              key: ValueKey<TopUpStep>(TopUpStep.amount),
            ),
          TopUpStep.method => const TopUpMethodStep(
              key: ValueKey<TopUpStep>(TopUpStep.method),
            ),
          TopUpStep.pay => const TopUpPayStep(
              key: ValueKey<TopUpStep>(TopUpStep.pay),
            ),
          TopUpStep.receipt => const TopUpReceiptStep(
              key: ValueKey<TopUpStep>(TopUpStep.receipt),
            ),
          TopUpStep.success => TopUpSuccessStep(
              key: const ValueKey<TopUpStep>(TopUpStep.success),
              onDone: () {
                _close(context, ref);
              },
            ),
        },
      );

  /// Leaves the flow. A finished draft is cleared so the next tap on the centre
  /// action starts fresh; an unfinished one is kept exactly as it was.
  void _close(BuildContext context, WidgetRef ref) {
    if (ref.read(topUpDraftProvider).step == TopUpStep.success) {
      ref.read(topUpDraftProvider.notifier).reset();
    }
    final VoidCallback? handler = onClose;
    if (handler != null) {
      handler();
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
