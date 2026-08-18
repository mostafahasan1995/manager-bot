/// The always-visible progress rail at the top of the top-up flow.
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';

/// The already-localised name of [step].
String topUpStepLabel(AppStrings s, TopUpStep step) => switch (step) {
      TopUpStep.amount => s.topupStepAmount,
      TopUpStep.method => s.topupStepMethod,
      TopUpStep.pay => s.topupStepPay,
      TopUpStep.receipt => s.topupStepReceipt,
      TopUpStep.success => s.topupStepDone,
    };

/// Five segments; the ones already reached carry the signature gradient.
///
/// The fill animates with [AnimatedContainer] rather than a controller, so the
/// bar has nothing running between step changes.
class TopUpStepIndicator extends StatelessWidget {
  const TopUpStepIndicator({required this.current, super.key});

  /// The step on screen.
  final TopUpStep current;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final LinearGradient reached =
        AppPalette.mirrored(AppPalette.gradientSignature, direction);
    return Row(
      children: <Widget>[
        for (final TopUpStep step in TopUpStep.values) ...<Widget>[
          if (step.index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: AppRadii.pillRadius,
                color: step.index <= current.index ? null : AppPalette.surface2,
                gradient: step.index <= current.index ? reached : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
