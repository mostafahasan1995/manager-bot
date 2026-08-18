/// Step 2 - which rail, then which account.
///
/// Methods are vivid cards; the chosen one is the single [GlowCard] on screen,
/// which is what makes the selection unmistakable without a radio button. A
/// method whose window cannot take the typed amount is shown, dimmed and
/// unselectable, rather than hidden - the player needs to know it exists.
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

/// The method-and-destination step of the top-up flow.
class TopUpMethodStep extends ConsumerWidget {
  const TopUpMethodStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final TopUpDraft draft = ref.watch(topUpDraftProvider);
    final AsyncValue<List<TopUpMethod>> catalogue =
        ref.watch(topUpMethodsProvider);
    final TopUpMethod? method = ref.watch(selectedTopUpMethodProvider);
    final Money? amount = draft.amount;
    final TopUpDestination? destination =
        method?.destinationById(draft.destinationId);
    final bool ready = method != null &&
        destination != null &&
        amount != null &&
        method.accepts(amount);

    final List<Widget> children = <Widget>[
      Text(s.topupMethodHeadline, style: theme.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      Text(
        s.topupMethodSubhead,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppPalette.textTertiary,
        ),
      ),
      SectionHeader(
        title: s.paymentMethodLabel,
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];

    children.addAll(_methodSection(context, ref, catalogue, amount, draft));

    if (method != null) {
      children.add(
        SectionHeader(
          title: s.topupDestinationSectionTitle,
          subtitle: method.name(context.localeTag),
          icon: Icons.savings_rounded,
        ),
      );
      children.addAll(_destinationSection(context, ref, method, draft));
      children.add(
        TopUpNote(
          text: s.topupReviewEta(minutes: method.reviewMinutes),
          icon: Icons.hourglass_bottom_rounded,
          tone: AppTone.info,
        ),
      );
    }

    return TopUpStepFrame(
      primary: AppButton(
        label: s.topupNext,
        trailingIcon: AppIcons.forwardArrow(context),
        expand: true,
        onPressed: ready
            ? () {
                _advance(ref);
              }
            : null,
      ),
      secondary: AppButton(
        label: s.topupBack,
        variant: AppButtonVariant.ghost,
        icon: AppIcons.backChevron(context),
        onPressed: () {
          _back(ref);
        },
      ),
      children: children,
    );
  }

  // --- sections ------------------------------------------------------------

  List<Widget> _methodSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TopUpMethod>> catalogue,
    Money? amount,
    TopUpDraft draft,
  ) {
    final AppStrings s = context.s;
    if (catalogue.hasError) {
      return <Widget>[
        ErrorState(
          title: s.topupMethodsLoadFailed,
          message: s.errorCannotReachServer,
          retryLabel: s.retry,
          onRetry: () {
            _reload(ref);
          },
          compact: true,
        ),
      ];
    }
    final List<TopUpMethod>? methods = catalogue.valueOrNull;
    if (methods == null) {
      return <Widget>[
        const AppCard(
          margin: EdgeInsetsDirectional.only(bottom: AppSpacing.md),
          padding: EdgeInsetsDirectional.all(AppSpacing.sm),
          child: ShimmerRow(),
        ),
        const AppCard(
          margin: EdgeInsetsDirectional.only(bottom: AppSpacing.md),
          padding: EdgeInsetsDirectional.all(AppSpacing.sm),
          child: ShimmerRow(),
        ),
        const AppCard(
          padding: EdgeInsetsDirectional.all(AppSpacing.sm),
          child: ShimmerRow(),
        ),
      ];
    }
    if (methods.isEmpty) {
      return <Widget>[
        EmptyState(
          title: s.topupNoMethodsTitle,
          message: s.topupNoMethodsMessage,
          icon: Icons.account_balance_wallet_rounded,
          actionLabel: s.retry,
          onAction: () {
            _reload(ref);
          },
        ),
      ];
    }
    return <Widget>[
      for (final TopUpMethod method in methods)
        _MethodCard(
          method: method,
          selected: method.id == draft.methodId,
          eligible: amount == null || method.accepts(amount),
        ),
    ];
  }

  List<Widget> _destinationSection(
    BuildContext context,
    WidgetRef ref,
    TopUpMethod method,
    TopUpDraft draft,
  ) {
    final AppStrings s = context.s;
    if (method.destinations.isEmpty) {
      return <Widget>[
        EmptyState(
          title: s.topupNoDestinationsTitle,
          message: s.topupNoDestinationsMessage,
          icon: Icons.link_rounded,
          tone: AppTone.attention,
          compact: true,
        ),
      ];
    }
    return <Widget>[
      for (final TopUpDestination destination in method.destinations)
        _DestinationCard(
          destination: destination,
          selected: destination.id == draft.destinationId,
        ),
    ];
  }

  // --- intents -------------------------------------------------------------

  static void _advance(WidgetRef ref) {
    ref.read(topUpDraftProvider.notifier).advance();
  }

  static void _back(WidgetRef ref) {
    ref.read(topUpDraftProvider.notifier).back();
  }

  static void _reload(WidgetRef ref) {
    ref.invalidate(topUpMethodsProvider);
  }
}

/// One payment method. Glows when chosen, dims when it cannot take the amount.
class _MethodCard extends ConsumerWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.eligible,
  });

  final TopUpMethod method;
  final bool selected;
  final bool eligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final String localeTag = context.localeTag;

    final Widget body = Row(
      children: <Widget>[
        AvatarRing(
          icon: _railIcon(method.rail),
          size: 46,
          gradient: _railGradient(method.rail),
          active: eligible,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                method.name(localeTag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _railLabel(s, method.rail),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.topupMethodLimits(
                  min: AmountText.render(
                    context,
                    method.minAmount,
                    showCurrency: false,
                  ),
                  max: AmountText.render(context, method.maxAmount),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NeonTheme.monoStyle(context),
              ),
              if (!eligible) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                  label: s.topupMethodNotForAmount,
                  tone: AppTone.attention,
                  icon: Icons.error_outline_rounded,
                  dense: true,
                  glow: false,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (selected)
          StatusChip(
            label: s.topupSelectedBadge,
            tone: AppTone.credited,
            icon: Icons.check_rounded,
            dense: true,
            glow: false,
          )
        else
          const ForwardChevron(),
      ],
    );

    if (selected) {
      return GlowCard(
        gradient: AppPalette.gradientHot,
        radius: AppRadii.md,
        margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
        child: body,
      );
    }
    return AppCard(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      onTap: eligible
          ? () {
              _select(ref, method.id);
            }
          : null,
      child: Opacity(opacity: eligible ? 1.0 : 0.55, child: body),
    );
  }

  static void _select(WidgetRef ref, String methodId) {
    ref.read(topUpDraftProvider.notifier).selectMethod(methodId);
  }
}

/// One receiving account on the chosen method.
class _DestinationCard extends ConsumerWidget {
  const _DestinationCard({
    required this.destination,
    required this.selected,
  });

  final TopUpDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      borderColor: selected
          ? AppPalette.tone(AppTone.credited).border
          : AppPalette.outline,
      onTap: () {
        _select(ref, destination.id);
      },
      child: Row(
        children: <Widget>[
          AvatarRing(
            initials: _initials(destination.accountHolder),
            size: 42,
            active: selected,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  destination.label(context.localeTag),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  destination.accountHolder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  destination.accountNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTheme.monoStyle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (selected)
            StatusChip(
              label: s.topupSelectedBadge,
              tone: AppTone.credited,
              icon: Icons.check_rounded,
              dense: true,
              glow: false,
            )
          else
            const ForwardChevron(),
        ],
      ),
    );
  }

  static void _select(WidgetRef ref, String destinationId) {
    ref.read(topUpDraftProvider.notifier).selectDestination(destinationId);
  }

  /// First letter of the first two words of a holder name.
  static String _initials(String name) {
    final List<String> parts = name
        .split(' ')
        .where((String part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1);
    }
    return '${parts[0].substring(0, 1)} ${parts[1].substring(0, 1)}';
  }
}

IconData _railIcon(TopUpRail rail) => switch (rail) {
      TopUpRail.mobileWallet => Icons.smartphone_rounded,
      TopUpRail.bankTransfer => Icons.account_balance_rounded,
      TopUpRail.cashOffice => Icons.storefront_rounded,
      TopUpRail.crypto => Icons.link_rounded,
    };

LinearGradient _railGradient(TopUpRail rail) => switch (rail) {
      TopUpRail.mobileWallet => AppPalette.gradientHot,
      TopUpRail.bankTransfer => AppPalette.gradientNeon,
      TopUpRail.cashOffice => AppPalette.gradientSunset,
      TopUpRail.crypto => AppPalette.gradientCredited,
    };

String _railLabel(AppStrings s, TopUpRail rail) => switch (rail) {
      TopUpRail.mobileWallet => s.railMobileWallet,
      TopUpRail.bankTransfer => s.railBankTransfer,
      TopUpRail.cashOffice => s.railCashOffice,
      TopUpRail.crypto => s.railCrypto,
    };
