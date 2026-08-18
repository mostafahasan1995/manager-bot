import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/ui.dart';

/// First-load skeleton for إيداعاتي: the summary block, then rows.
///
/// It mirrors the real layout one for one - same card shape, same leading
/// circle, same amount block on the end - so nothing jumps when the data
/// arrives. It is unmounted the moment the feed resolves, which is the only
/// way the kit's single repeating animation is allowed to exist.
class ActivitySkeletonList extends StatelessWidget {
  const ActivitySkeletonList({this.rows = 5, super.key});

  /// How many placeholder rows to draw under the summary block.
  final int rows;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: AppSpacing.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) => index == 0
            ? const _SummarySkeleton()
            : const AppCard(child: ShimmerRow(padding: EdgeInsets.zero)),
      );
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) => const AppCard(
        padding: EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ShimmerBox(width: 120, height: 12),
            SizedBox(height: AppSpacing.md),
            ShimmerBox(width: 210, height: 28),
            SizedBox(height: AppSpacing.md),
            ShimmerBox(width: 150, height: 12),
          ],
        ),
      );
}
