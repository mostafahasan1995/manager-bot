import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/ui.dart';

/// The loading shape of the profile tab.
///
/// It mirrors the real layout - identity block, one wide amount card, a list of
/// rows - so nothing jumps when the data arrives. The whole tree is `const` and
/// unmounts the moment the profile resolves.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCard(
            padding: EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Row(
              children: <Widget>[
                ShimmerBox(width: 68, height: 68, radius: AppRadii.pill),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ShimmerBox(width: 160, height: 20),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 110, height: 14),
                      SizedBox(height: AppSpacing.md),
                      ShimmerBox(width: 190, height: 22, radius: AppRadii.pill),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppCard(child: ShimmerRow(showLeading: false)),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ShimmerBox(height: 14),
                SizedBox(height: AppSpacing.lg),
                ShimmerBox(height: 14),
                SizedBox(height: AppSpacing.lg),
                ShimmerBox(height: 14),
                SizedBox(height: AppSpacing.lg),
                ShimmerBox(height: 14),
              ],
            ),
          ),
        ],
      );
}
