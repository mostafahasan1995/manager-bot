import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/avatar_ring.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// One entry in a [StoryStrip].
@immutable
class StoryAction {
  const StoryAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.gradient,
    this.active = true,
    this.badgeCount,
  });

  /// Already-localised, one or two words. Longer labels are ellipsised.
  final String label;

  final IconData icon;
  final VoidCallback? onTap;

  /// Ring gradient. Defaults to [AppPalette.gradientSunset] via [AvatarRing].
  final LinearGradient? gradient;

  /// False dims the ring to a flat outline ("already done").
  final bool active;

  /// Renders a [CountBadge] when greater than zero.
  final int? badgeCount;
}

/// A horizontal rail of gradient-ringed quick actions.
///
/// The rail is a `ListView`, so it scrolls from the reading start under both
/// locales with no `reverse` hack. Keep it to five or six actions.
///
/// ```dart
/// StoryStrip(
///   actions: <StoryAction>[
///     StoryAction(label: s.quickTopUp, icon: Icons.bolt_rounded, onTap: topUp),
///     StoryAction(label: s.quickMethods, icon: Icons.account_balance_wallet_rounded, onTap: methods),
///     StoryAction(label: s.quickSupport, icon: Icons.support_agent_rounded, onTap: support),
///   ],
/// )
/// ```
class StoryStrip extends StatelessWidget {
  const StoryStrip({
    required this.actions,
    this.height = 106,
    this.avatarSize = 60,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.gutter,
    ),
    super.key,
  });

  final List<StoryAction> actions;

  /// Total rail height: ring + gap + one line of label.
  final double height;

  final double avatarSize;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: actions.length,
        clipBehavior: Clip.none,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.lg),
        itemBuilder: (BuildContext context, int index) {
          final StoryAction action = actions[index];
          final int? badgeCount = action.badgeCount;
          return SizedBox(
            width: avatarSize + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AvatarRing(
                  icon: action.icon,
                  size: avatarSize,
                  gradient: action.gradient ?? AppPalette.gradientSunset,
                  active: action.active,
                  onTap: action.onTap,
                  badge: badgeCount != null && badgeCount > 0
                      ? CountBadge(count: badgeCount)
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  action.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: action.active
                        ? AppPalette.textSecondary
                        : AppPalette.textTertiary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
