/// Step 4 - the proof.
///
/// There is no image-picker package in the fixed dependency set, so the picker
/// itself is a placeholder: tapping it attaches a believable file name from the
/// demo source and says plainly that picking is not wired yet. BOTH visual
/// states - empty dashed frame and filled preview - are real, so dropping a
/// picker in later changes one callback and nothing else.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
import 'package:manager_bot/features/shell/topup/data/topup_demo_data.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';
import 'package:manager_bot/features/shell/topup/presentation/widgets/topup_shared.dart';

/// The receipt-upload step of the top-up flow.
class TopUpReceiptStep extends ConsumerStatefulWidget {
  const TopUpReceiptStep({super.key});

  @override
  ConsumerState<TopUpReceiptStep> createState() => _TopUpReceiptStepState();
}

class _TopUpReceiptStepState extends ConsumerState<TopUpReceiptStep> {
  late final TextEditingController _sender;

  @override
  void initState() {
    super.initState();
    _sender = TextEditingController(
      text: ref.read(topUpDraftProvider).senderName,
    );
  }

  @override
  void dispose() {
    _sender.dispose();
    super.dispose();
  }

  void _setSender(String value) {
    ref.read(topUpDraftProvider.notifier).setSenderName(value);
  }

  void _pickReceipt() {
    ref
        .read(topUpDraftProvider.notifier)
        .attachReceipt(TopUpDemoData.newReceiptName());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.topupReceiptPickerUnavailable)),
    );
  }

  void _removeReceipt() {
    ref.read(topUpDraftProvider.notifier).removeReceipt();
  }

  void _back() {
    ref.read(topUpDraftProvider.notifier).back();
  }

  void _submit() {
    unawaited(ref.read(topUpDraftProvider.notifier).submit());
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpDraft draft = ref.watch(topUpDraftProvider);
    final TopUpMethod? method = ref.watch(selectedTopUpMethodProvider);
    final Money? amount = draft.amount;
    final String? receipt = draft.receiptName;

    return TopUpStepFrame(
      primary: AppButton(
        label: s.topupSubmitCta,
        icon: Icons.done_all_rounded,
        expand: true,
        loading: draft.submitting,
        onPressed: draft.hasProof ? _submit : null,
      ),
      secondary: AppButton(
        label: s.topupBack,
        variant: AppButtonVariant.ghost,
        icon: AppIcons.backChevron(context),
        onPressed: draft.submitting ? null : _back,
      ),
      children: <Widget>[
        Text(s.topupReceiptHeadline, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          s.topupReceiptSubhead,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (receipt == null)
          _EmptyFrame(onPick: _pickReceipt)
        else
          _FilledFrame(fileName: receipt, onRemove: _removeReceipt),

        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: receipt == null
                    ? s.topupReceiptPickCta
                    : s.topupReceiptReplaceCta,
                variant: AppButtonVariant.tonal,
                icon: Icons.add_photo_alternate_rounded,
                tone: AppTone.info,
                expand: true,
                onPressed: _pickReceipt,
              ),
            ),
            if (receipt != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              AppButton(
                label: s.topupReceiptRemoveCta,
                variant: AppButtonVariant.ghost,
                icon: Icons.delete_outline_rounded,
                tone: AppTone.rejected,
                onPressed: _removeReceipt,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          label: s.proofFieldSenderName,
          controller: _sender,
          helper: s.topupSenderNameHelper,
          prefixIcon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: _setSender,
        ),

        SectionHeader(
          title: s.topupSummaryTitle,
          icon: Icons.receipt_long_rounded,
        ),
        AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s.topupAmountToSendLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  AmountText(amount ?? Money.zero(), fontSize: 17),
                ],
              ),
              if (method != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TopUpValueRow(
                  label: s.paymentMethodLabel,
                  value: method.name(context.localeTag),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.topupCreditedLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    AmountText(
                      method.creditedFor(amount ?? Money.zero()),
                      fontSize: 17,
                      tone: AppTone.credited,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        if (draft.submitFailed)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
            child: ErrorState(
              title: s.topupSubmitFailedTitle,
              message: s.errorCannotReachServer,
              retryLabel: s.retry,
              onRetry: _submit,
              compact: true,
            ),
          ),
        TopUpNote(text: s.topupDemoNotice),
      ],
    );
  }
}

/// Nothing attached yet: a dashed frame the player taps.
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    return Material(
      color: AppPalette.surface1,
      borderRadius: AppRadii.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: CustomPaint(
          painter: const TopUpDashedFrame(),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AvatarRing(
                  icon: Icons.add_photo_alternate_rounded,
                  size: 64,
                  gradient: AppPalette.gradientNeon,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.topupReceiptEmptyTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    s.topupReceiptEmptyMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A receipt is attached: the preview frame stands in for the bitmap.
class _FilledFrame extends StatelessWidget {
  const _FilledFrame({
    required this.fileName,
    required this.onRemove,
  });

  final String fileName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ToneColors colors = AppPalette.tone(AppTone.credited);
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.surface2,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.glow(colors.glow, blur: 20, spread: -12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppPalette.gradientHeroWash,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: colors.foreground,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeonTheme.monoStyle(context).copyWith(
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.sm,
            start: AppSpacing.sm,
            child: StatusChip(
              label: s.proofFieldReceiptImage,
              tone: AppTone.credited,
              icon: Icons.check_rounded,
              dense: true,
              glow: false,
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.xs,
            end: AppSpacing.xs,
            child: IconButton(
              tooltip: s.topupReceiptRemoveCta,
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
