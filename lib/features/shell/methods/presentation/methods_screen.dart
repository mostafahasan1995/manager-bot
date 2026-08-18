/// طرق الدفع - the rails a player can pay over.
///
/// The destination the shell mounts is [MethodsScreen]. It renders from the
/// demo catalogue in `data/payment_methods_demo_data.dart` because every real
/// endpoint needs a bearer token and there is no session while the entry code
/// is out; the loading, empty and error shapes are all wired anyway so nothing
/// has to be invented on the day the API arrives.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/methods/application/methods_providers.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';
import 'package:manager_bot/features/shell/methods/presentation/method_card.dart';
import 'package:manager_bot/features/shell/methods/presentation/method_detail_sheet.dart';
import 'package:manager_bot/features/shell/methods/presentation/methods_formats.dart';

/// Rails offered as filter chips, in the order a Syrian player thinks of them.
/// `MethodRail.internal` is deliberately absent - no player-visible method
/// settles over it.
const List<MethodRail> _filterRails = <MethodRail>[
  MethodRail.mobileWallet,
  MethodRail.bankTransfer,
  MethodRail.cashOffice,
  MethodRail.crypto,
];

/// The طرق الدفع destination.
///
/// [onStartTopUp] is handed down by the shell and fires the raised centre
/// action's flow. It is nullable so the shell can mount `const MethodsScreen()`
/// before that flow exists; the call to action simply dims to 45% until it is
/// supplied.
class MethodsScreen extends ConsumerWidget {
  const MethodsScreen({this.onStartTopUp, super.key});

  final VoidCallback? onStartTopUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MethodsBoard> board = ref.watch(methodsBoardProvider);
    final AppStrings s = context.s;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: <Widget>[
            _MethodsHeader(board: board.valueOrNull),
            const SizedBox(height: AppSpacing.lg),
            const MethodsFilterBar(),
            board.when(
              data: (MethodsBoard value) => _MethodsBody(
                board: value,
                onStartTopUp: onStartTopUp,
              ),
              loading: () => const _MethodsLoading(),
              error: (Object error, StackTrace _) => Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
                child: ErrorState(
                  title: MethodsFormats.errorTitle(error, s),
                  message: MethodsFormats.errorMessage(error, s),
                  details: MethodsFormats.errorDetails(error),
                  retryLabel: s.retry,
                  onRetry: () => ref.invalidate(methodsCatalogProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wordmark, one line of lede, and how much of the catalogue is actually open.
class _MethodsHeader extends ConsumerWidget {
  const _MethodsHeader({this.board});

  /// Null while the catalogue is loading or has failed.
  final MethodsBoard? board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final MethodsBoard? resolved = board;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: GradientText(
                s.pmScreenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: () => ref.invalidate(methodsCatalogProvider),
              tooltip: s.refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          s.methodsIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.textTertiary,
          ),
        ),
        if (resolved != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          StatusChip(
            label: s.methodsAvailableCount(
              available: resolved.availableCount,
              total: resolved.totalCount,
            ),
            tone: AppTone.credited,
            icon: Icons.bolt_rounded,
            dense: true,
          ),
        ],
      ],
    );
  }
}

/// The availability toggle plus one chip per rail. Public so a test can pump it
/// on its own.
class MethodsFilterBar extends ConsumerWidget {
  const MethodsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final MethodsFilter filter = ref.watch(methodsFilterProvider);
    final MethodsFilterController controller =
        ref.read(methodsFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: <Widget>[
          _FilterChip(
            label: s.methodsFilterAvailableOnly,
            icon: Icons.bolt_rounded,
            selected: filter.availableOnly,
            selectedTone: AppTone.credited,
            onTap: controller.toggleAvailableOnly,
          ),
          _FilterChip(
            label: s.pmFilterEveryRail,
            icon: Icons.tune_rounded,
            selected: filter.rail == null,
            onTap: () => controller.setRail(null),
          ),
          for (final MethodRail rail in _filterRails)
            _FilterChip(
              label: rail.label(s),
              icon: MethodsFormats.railIcon(rail),
              selected: filter.rail == rail,
              onTap: () => controller.toggleRail(rail),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.selectedTone = AppTone.info,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppTone selectedTone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Align(
          child: StatusChip(
            label: label,
            tone: selected ? selectedTone : AppTone.neutral,
            icon: icon,
            dense: true,
            glow: selected,
            onTap: onTap,
          ),
        ),
      );
}

/// Featured card, then everything else, then the paused rails.
class _MethodsBody extends ConsumerWidget {
  const _MethodsBody({required this.board, this.onStartTopUp});

  final MethodsBoard board;
  final VoidCallback? onStartTopUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;

    if (board.catalogueIsEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
        child: EmptyState(
          title: s.pmEmptyTitle,
          message: s.methodsEmptyMessage,
          icon: Icons.account_balance_wallet_rounded,
          actionLabel: s.refresh,
          onAction: () => ref.invalidate(methodsCatalogProvider),
        ),
      );
    }

    if (board.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
        child: EmptyState(
          title: s.pmFilterEmptyTitle,
          message: s.pmFilterEmptyMessage,
          icon: Icons.tune_rounded,
          tone: AppTone.info,
          actionLabel: s.clearFiltersAction,
          onAction: ref.read(methodsFilterProvider.notifier).clear,
        ),
      );
    }

    final String? selectedId = ref.watch(methodsSelectionProvider);
    final PlayerPaymentMethod? featured = board.featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: AppEntrance.stagger(<Widget>[
        if (featured != null) ...<Widget>[
          SectionHeader(
            title: s.methodsSectionFastest,
            icon: Icons.bolt_rounded,
          ),
          FeaturedMethodCard(
            method: featured,
            onOpen: () => _open(context, ref, featured),
            onStartTopUp: onStartTopUp,
          ),
        ],
        if (board.open.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: s.methodsSectionOther,
            icon: Icons.list_alt_rounded,
          ),
          for (final PlayerPaymentMethod method in board.open)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: MethodCard(
                method: method,
                selected: method.id == selectedId,
                onOpen: () => _open(context, ref, method),
              ),
            ),
        ],
        if (board.paused.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: s.methodsSectionPaused,
            subtitle: s.methodsPausedNote,
            icon: Icons.pause_rounded,
          ),
          for (final PlayerPaymentMethod method in board.paused)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: MethodCard(
                method: method,
                selected: method.id == selectedId,
                onOpen: () => _open(context, ref, method),
              ),
            ),
        ],
      ]),
    );
  }

  /// Marks the card as the open one, then shows the sheet. The future is
  /// deliberately not awaited here: `AppCard.onTap` is a `VoidCallback`.
  void _open(BuildContext context, WidgetRef ref, PlayerPaymentMethod method) {
    final MethodsSelectionController selection =
        ref.read(methodsSelectionProvider.notifier);
    selection.select(method.id);
    unawaited(
      showMethodDetailSheet(
        context,
        method: method,
        onStartTopUp: onStartTopUp,
        onDismissed: selection.clear,
      ),
    );
  }
}

/// Three card skeletons. Unmounted the instant real data arrives.
class _MethodsLoading extends StatelessWidget {
  const _MethodsLoading();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          for (int i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ShimmerRow(),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: <Widget>[
                        Expanded(child: ShimmerBox(height: 34)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: ShimmerBox(height: 34)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}
