/// The announcement carousel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/home/application/home_providers.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';
import 'package:manager_bot/features/shell/home/presentation/home_labels.dart';

/// A swipeable rail of promo cards with page dots.
///
/// AUTO-ADVANCE IS DELIBERATELY OFF. A carousel that moves on its own steals a
/// card out from under the reader's thumb and keeps a timer alive for as long
/// as the tab is mounted. This one moves only when a finger moves it, so it
/// costs nothing while it sits still.
///
/// The page lives in `homePromoIndexProvider` rather than in this `State`, so
/// switching tabs and coming back does not silently rewind the reader.
class HomePromoCarousel extends ConsumerStatefulWidget {
  const HomePromoCarousel({required this.promos, this.onPromoTap, super.key});

  final List<HomePromo> promos;

  /// Where a promo card leads. Null leaves the cards inert.
  final ValueChanged<HomePromo>? onPromoTap;

  @override
  ConsumerState<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends ConsumerState<HomePromoCarousel> {
  /// Tall enough for a two-line headline plus two lines of body at the largest
  /// text scale we support without the card scrolling internally.
  static const double _cardHeight = 172;

  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _clamp(ref.read(homePromoIndexProvider)),
      viewportFraction: 0.88,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promos.isEmpty) {
      return const SizedBox.shrink();
    }
    final int current = _clamp(ref.watch(homePromoIndexProvider));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.promos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (BuildContext context, int index) {
              final HomePromo promo = widget.promos[index];
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: _PromoCard(
                  promo: promo,
                  onTap: _tapHandlerFor(promo),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PromoDots(count: widget.promos.length, current: current),
      ],
    );
  }

  VoidCallback? _tapHandlerFor(HomePromo promo) {
    final ValueChanged<HomePromo>? handler = widget.onPromoTap;
    if (handler == null) {
      return null;
    }
    return () => handler(promo);
  }

  void _onPageChanged(int index) {
    ref.read(homePromoIndexProvider.notifier).select(index);
  }

  int _clamp(int value) {
    final int last = widget.promos.length - 1;
    if (last < 0 || value < 0) {
      return 0;
    }
    return value > last ? last : value;
  }
}

/// One announcement. A quiet card with a gradient ring rather than a glowing
/// slab: three blooms side by side would out-shout the balance, and the balance
/// wins every argument on this screen.
class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, this.onTap});

  final HomePromo promo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      radius: AppRadii.lg,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarRing(
                icon: HomeLabels.promoIcon(promo.slot),
                size: 40,
                gradient: HomeLabels.accent(promo.accent),
                ringWidth: 2,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  HomeLabels.promoTitle(s, promo.slot),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            HomeLabels.promoBody(s, promo.slot),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Text(
                s.homePromoAction,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppPalette.accentCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const ForwardChevron(size: 16, color: AppPalette.accentCyan),
            ],
          ),
        ],
      ),
    );
  }
}

/// The page indicator: a stretched gradient pill for the current page, dim
/// dots for the rest. One [AnimatedContainer] per dot, 160ms, then still.
class _PromoDots extends StatelessWidget {
  const _PromoDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: i == current ? 22 : 7,
              height: 7,
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: i == current ? AppPalette.gradientSignature : null,
                color: i == current ? null : AppPalette.outlineStrong,
                borderRadius: AppRadii.pillRadius,
              ),
            ),
        ],
      );
}
