/// الرئيسية - the face of the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/home/application/home_providers.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';
import 'package:manager_bot/features/shell/home/presentation/home_account_banner.dart';
import 'package:manager_bot/features/shell/home/presentation/home_deposit_card.dart';
import 'package:manager_bot/features/shell/home/presentation/home_labels.dart';
import 'package:manager_bot/features/shell/home/presentation/home_promo_carousel.dart';

/// The home destination: balance, quick actions, announcements, recent
/// activity.
///
/// The screen owns no navigation. Every way out is a callback the shell hands
/// in, so this widget can be pumped in a test with nothing behind it and the
/// tab bar stays the single source of truth for where a tap goes.
///
/// Reading order, top to bottom, is the order a player cares about:
/// 1. who they are and whether the server is up,
/// 2. HOW MUCH MONEY THEY HAVE - the largest, highest-contrast thing here,
/// 3. the one button that adds more,
/// 4. the four things they might do next,
/// 5. whether their casino account is even linked yet,
/// 6. what is new,
/// 7. what happened recently.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    this.onStartTopUp,
    this.onOpenDeposits,
    this.onOpenPaymentMethods,
    this.onOpenSupport,
    this.onOpenProfile,
    super.key,
  });

  /// Raised centre action: start a top-up.
  final VoidCallback? onStartTopUp;

  /// إيداعاتي.
  final VoidCallback? onOpenDeposits;

  /// طرق الدفع.
  final VoidCallback? onOpenPaymentMethods;

  /// Support / account linking. Both live in the bot today.
  final VoidCallback? onOpenSupport;

  /// حسابي.
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeSnapshot> snapshot = ref.watch(homeSnapshotProvider);
    final HomeSnapshot? loaded = snapshot.valueOrNull;

    final List<Widget> sections = snapshot.when(
      data: (HomeSnapshot value) => _dataSections(context, ref, value),
      error: (Object error, StackTrace stackTrace) =>
          _errorSections(context, ref, error),
      loading: _loadingSections,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: AppPalette.accentCyan,
          backgroundColor: AppPalette.surface2,
          child: ListView(
            // The list must stay draggable even when it is shorter than the
            // viewport, or pull-to-refresh dies on the empty state.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            children: AppEntrance.stagger(<Widget>[
              _HomeHeader(
                name: loaded?.playerName,
                initials: loaded?.playerInitials,
                onOpenProfile: onOpenProfile,
              ),
              const SizedBox(height: AppSpacing.lg),
              ...sections,
            ]),
          ),
        ),
      ),
    );
  }

  // --- states --------------------------------------------------------------

  List<Widget> _dataSections(
    BuildContext context,
    WidgetRef ref,
    HomeSnapshot snap,
  ) {
    final AppStrings s = context.s;
    final bool hidden = ref.watch(homeBalanceHiddenProvider);

    return <Widget>[
      BalanceHero(
        amount: snap.balance,
        label: s.homeBalanceLabel,
        statusLabel: snap.pendingCount > 0
            ? s.homeBalancePendingChip(count: snap.pendingCount)
            : null,
        statusTone: AppTone.pending,
        footnote: s.homeBalanceUpdated(
          age: HomeAgeFormat.ago(s, snap.balanceAge),
        ),
        hideToggleTooltip: s.homeBalanceVisibilityTooltip,
        initiallyHidden: hidden,
        onHiddenChanged: (bool value) =>
            ref.read(homeBalanceHiddenProvider.notifier).setHidden(value),
        action: AppButton(
          label: s.homeTopUpCta,
          icon: Icons.bolt_rounded,
          expand: true,
          onPressed: onStartTopUp,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      StoryStrip(
        actions: _quickActions(s, snap),
        // The page gutter is already applied by the ListView padding.
        padding: EdgeInsetsDirectional.zero,
      ),
      const SizedBox(height: AppSpacing.lg),
      HomeAccountBanner(
        linked: snap.isCasinoAccountLinked,
        onLink: onOpenSupport,
      ),
      SectionHeader(
        title: s.homePromoSectionTitle,
        icon: Icons.campaign_rounded,
      ),
      HomePromoCarousel(promos: snap.promos, onPromoTap: _promoHandler()),
      SectionHeader(
        title: s.homeRecentTitle,
        icon: Icons.receipt_long_rounded,
        actionLabel: s.filterAll,
        onAction: onOpenDeposits,
      ),
      if (!snap.hasRecentDeposits)
        EmptyState(
          title: s.emptyDefaultTitle,
          message: s.homeRecentEmptyMessage,
          icon: Icons.receipt_long_rounded,
          actionLabel: s.homeTopUpCta,
          onAction: onStartTopUp,
        ),
      for (final HomeDeposit deposit in snap.visibleDeposits)
        HomeDepositCard(deposit: deposit, onTap: onOpenDeposits),
    ];
  }

  /// The same three shapes as every other screen: a hero skeleton and rows.
  List<Widget> _loadingSections() => const <Widget>[
        _HomeHeroSkeleton(),
        SizedBox(height: AppSpacing.lg),
        ShimmerRow(),
        ShimmerRow(),
        ShimmerRow(),
      ];

  List<Widget> _errorSections(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    final AppStrings s = context.s;
    final ApiError? api = error is ApiError ? error : null;
    return <Widget>[
      ErrorState(
        title: s.errorTitleNoConnection,
        message: api == null ? s.errorCannotReachServer : api.userMessage(s),
        details: api?.correlationId,
        retryLabel: s.retry,
        onRetry: () => ref.invalidate(homeSnapshotProvider),
      ),
    ];
  }

  // --- helpers -------------------------------------------------------------

  List<StoryAction> _quickActions(AppStrings s, HomeSnapshot snap) =>
      <StoryAction>[
        StoryAction(
          label: s.homeQuickTopUp,
          icon: Icons.add_rounded,
          onTap: onStartTopUp,
        ),
        StoryAction(
          label: s.homeQuickDeposits,
          icon: Icons.receipt_long_rounded,
          gradient: AppPalette.gradientNeon,
          onTap: onOpenDeposits,
          badgeCount: snap.pendingCount,
        ),
        StoryAction(
          label: s.homeQuickMethods,
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppPalette.gradientHot,
          onTap: onOpenPaymentMethods,
        ),
        StoryAction(
          label: s.homeQuickSupport,
          icon: Icons.support_agent_rounded,
          gradient: AppPalette.gradientCredited,
          onTap: onOpenSupport,
        ),
      ];

  /// Every announcement leads to the same place today: the top-up flow.
  ValueChanged<HomePromo>? _promoHandler() {
    final VoidCallback? start = onStartTopUp;
    if (start == null) {
      return null;
    }
    return (HomePromo promo) => start();
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(homeConnectionProvider);
    ref.invalidate(homeSnapshotProvider);
    try {
      await ref.read(homeSnapshotProvider.future);
    } on Object {
      // The AsyncValue already carries the failure and the list renders
      // ErrorState; letting it out here would only break the indicator.
    }
  }
}

/// Greeting, avatar and backend health, on one line.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.name,
    required this.initials,
    this.onOpenProfile,
  });

  /// Null while the snapshot is still loading.
  final String? name;
  final String? initials;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final HomeConnection connection =
        ref.watch(homeConnectionProvider).valueOrNull ??
            const HomeConnection.checking();
    final int? latency = connection.latencyMs;
    final String? label = name;
    final String? glyphs = initials;

    return Row(
      children: <Widget>[
        AvatarRing(
          initials: glyphs,
          icon: glyphs == null ? Icons.person_rounded : null,
          size: 46,
          gradient: AppPalette.gradientHot,
          onTap: onOpenProfile,
          ringWidth: 2,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: label == null
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ShimmerBox(width: 132),
                    SizedBox(height: AppSpacing.sm),
                    ShimmerBox(width: 88, height: 11),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // The one gradient headline on the screen. Never an amount.
                    GradientText(
                      s.homeGreeting(name: label),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.homeTagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConnectionPill(
          phase: connection.phase,
          label: HomeLabels.connection(s, connection.phase),
          detail: latency == null ? null : s.connectionLatencyMs(ms: latency),
          onTap: () => ref.invalidate(homeConnectionProvider),
          dense: true,
        ),
      ],
    );
  }
}

/// The balance hero while the snapshot loads. Same footprint, so nothing jumps
/// when the real amount lands.
class _HomeHeroSkeleton extends StatelessWidget {
  const _HomeHeroSkeleton();

  @override
  Widget build(BuildContext context) => const AppCard(
        radius: AppRadii.lg,
        padding: EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ShimmerBox(width: 120, height: 14),
            SizedBox(height: AppSpacing.md),
            ShimmerBox(width: 210, height: 38),
            SizedBox(height: AppSpacing.md),
            ShimmerBox(width: 148, height: 12),
            SizedBox(height: AppSpacing.xl),
            ShimmerBox(height: 52, radius: AppRadii.pill),
          ],
        ),
      );
}
