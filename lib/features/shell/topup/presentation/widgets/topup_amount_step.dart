/// Step 1 - how much.
///
/// A live gradient-framed preview of the exact amount, four one-tap quick
/// picks and the field itself. Everything is parsed through
/// `Money.parseUserInput`; no value in this file is ever a `double`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/topup/application/topup_amount_rules.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
import 'package:manager_bot/features/shell/topup/data/topup_demo_data.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_shared.dart';

/// The amount step of the top-up flow.
class TopUpAmountStep extends ConsumerStatefulWidget {
  const TopUpAmountStep({super.key});

  @override
  ConsumerState<TopUpAmountStep> createState() => _TopUpAmountStepState();
}

class _TopUpAmountStepState extends ConsumerState<TopUpAmountStep> {
  /// Western digits plus the separators `Money.parseUserInput` understands.
  /// Everything else is dropped before it can reach the parser.
  static final RegExp _allowed = RegExp(r'[0-9., ]');

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(topUpDraftProvider).amountInput,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setInput(String value) {
    ref.read(topUpDraftProvider.notifier).setAmountInput(value);
  }

  void _pick(Money amount) {
    final String text = amount.toDecimalString();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _setInput(text);
  }

  void _advance() {
    ref.read(topUpDraftProvider.notifier).advance();
  }

  void _reloadCatalogue() {
    ref.invalidate(topUpMethodsProvider);
  }

  String _issueText(
    BuildContext context,
    TopUpAmountIssue issue,
    TopUpLimits? limits,
  ) {
    final AppStrings s = context.s;
    final TopUpLimits? window = limits;
    return switch (issue) {
      TopUpAmountIssue.empty => s.moneyErrorEmpty,
      TopUpAmountIssue.malformed => s.moneyErrorMalformed,
      TopUpAmountIssue.tooManyDecimals =>
        s.moneyErrorTooManyDecimals(scale: Money.defaultScale),
      TopUpAmountIssue.notPositive => s.topupAmountErrorNotPositive,
      TopUpAmountIssue.belowMinimum => s.topupAmountErrorBelowMin(
          min: window == null
              ? s.emptyValueDash
              : AmountText.render(context, window.minimum),
        ),
      TopUpAmountIssue.aboveMaximum => s.topupAmountErrorAboveMax(
          max: window == null
              ? s.emptyValueDash
              : AmountText.render(context, window.maximum),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpDraft draft = ref.watch(topUpDraftProvider);
    final AsyncValue<List<TopUpMethod>> catalogue =
        ref.watch(topUpMethodsProvider);
    final TopUpLimits? limits = ref.watch(topUpLimitsProvider);

    final Money? typed = draft.amount;
    final TopUpAmountIssue? issue = TopUpAmountRules.validate(
      draft.amountInput,
      minimum: limits?.minimum,
      maximum: limits?.maximum,
    );
    final bool touched = draft.amountInput.trim().isNotEmpty;
    final bool ready = issue == null && limits != null;

    return TopUpStepFrame(
      primary: AppButton(
        label: s.topupNext,
        trailingIcon: AppIcons.forwardArrow(context),
        expand: true,
        onPressed: ready ? _advance : null,
      ),
      children: <Widget>[
        Text(
          s.topupAmountHeadline,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          s.topupAmountSubhead,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // The hero of this step: the exact figure, big and unmistakable.
        GlowCard(
          gradient: AppPalette.gradientNeon,
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                s.topupAmountToSendLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppPalette.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountText(
                typed ?? Money.zero(),
                fontSize: 38,
                height: 1.1,
                color: typed == null
                    ? AppPalette.textDisabled
                    : AppPalette.textPrimary,
              ),
              const SizedBox(height: AppSpacing.md),
              if (limits == null && catalogue.hasError)
                StatusChip(
                  label: s.topupMethodsLoadFailed,
                  tone: AppTone.rejected,
                  icon: Icons.error_outline_rounded,
                  dense: true,
                  glow: false,
                )
              else if (limits == null)
                const ShimmerBox(width: 180, height: 14)
              else
                Text(
                  s.topupAmountHelper(
                    min: AmountText.render(
                      context,
                      limits.minimum,
                      showCurrency: false,
                    ),
                    max: AmountText.render(context, limits.maximum),
                  ),
                  style: NeonTheme.monoStyle(context),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          s.topupQuickPicksLabel,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final Money pick in TopUpDemoData.quickPicks)
              StatusChip(
                label: AmountText.render(context, pick, showCurrency: false),
                tone: pick == typed ? AppTone.info : AppTone.neutral,
                icon: pick == typed ? Icons.check_rounded : Icons.bolt_rounded,
                glow: false,
                onTap: () {
                  _pick(pick);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          label: s.topupAmountFieldLabel,
          controller: _controller,
          hint: s.topupAmountFieldHint,
          numeric: true,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(_allowed),
          ],
          prefixIcon: Icons.payments_rounded,
          onChanged: _setInput,
          errorText:
              touched && issue != null ? _issueText(context, issue, limits) : null,
          helper: draft.amountInput.isEmpty ? s.topupDemoNotice : null,
        ),

        if (catalogue.hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
            child: ErrorState(
              title: s.topupMethodsLoadFailed,
              message: s.errorCannotReachServer,
              retryLabel: s.retry,
              onRetry: _reloadCatalogue,
              compact: true,
            ),
          )
        else if (catalogue.isLoading)
          const Padding(
            padding: EdgeInsetsDirectional.only(top: AppSpacing.lg),
            child: ShimmerRow(showLeading: false),
          ),
      ],
    );
  }
}
