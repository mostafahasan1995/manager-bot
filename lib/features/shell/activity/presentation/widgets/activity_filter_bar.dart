import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/activity/application/activity_controller.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';
import 'package:manager_bot/features/shell/activity/presentation/activity_presentation.dart';

/// The four chips across the top of إيداعاتي: الكل / قيد المراجعة / مكتملة /
/// مرفوضة.
///
/// The selected chip carries its filter's tone and its bloom; the rest stay
/// neutral and flat, so exactly one thing on the row is lit. Selecting writes
/// to `activityFilterProvider`, which the feed watches - the list reloads from
/// page 1 on its own.
class ActivityFilterBar extends ConsumerWidget {
  const ActivityFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ActivityFilter selected = ref.watch(activityFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          for (final ActivityFilter filter in ActivityFilterStyle.ordered)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: AnimatedScale(
                scale: filter == selected ? 1 : 0.94,
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                child: StatusChip(
                  label: ActivityFilterStyle.label(s, filter),
                  tone: filter == selected
                      ? ActivityFilterStyle.tone(filter)
                      : AppTone.neutral,
                  icon: ActivityFilterStyle.icon(filter),
                  glow: filter == selected,
                  onTap: () {
                    ref
                        .read(activityFilterProvider.notifier)
                        .select(filter);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
