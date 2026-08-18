import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/application/break_filter_controller.dart';
import 'package:manager_bot/features/reconciliation/data/break_filter.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// Compact filter summary with a "Filter" button that opens [BreakFilterSheet].
class BreakFilterBar extends ConsumerWidget {
  const BreakFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final BreakFilter filter = ref.watch(breakFilterProvider);
    final int facets = filter.activeFacetCount;

    return Padding(
      // Directional: the summary keeps its 16 on the reading edge and the
      // buttons keep their tighter 8 on the trailing one, in both directions.
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              filter.describe(s),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!filter.isDefault)
            TextButton(
              onPressed: () => ref.read(breakFilterProvider.notifier).clear(),
              child: Text(s.resetButton),
            ),
          TextButton.icon(
            onPressed: () async {
              await BreakFilterSheet.show(context);
            },
            icon: const Icon(Icons.tune, size: 18),
            label: Text(
              facets == 0 ? s.filterLabel : s.filterWithCount(count: facets),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status / category / severity picker.
///
/// Every selection is turned into ONE comma-separated uppercase query param by
/// [BreakFilter.toQuery]; the sheet never builds a query string itself.
class BreakFilterSheet extends ConsumerWidget {
  const BreakFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => const BreakFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final BreakFilter filter = ref.watch(breakFilterProvider);
    final BreakFilterController controller =
        ref.read(breakFilterProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(s.breakFilterSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              s.filterDefaultHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(s.statusLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final BreakStatus status in BreakStatus.filterable)
                  FilterChip(
                    label: Text(status.label(s)),
                    selected: filter.statuses.contains(status),
                    onSelected: (_) => controller.toggleStatus(status),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(s.filterCategoryHeading, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              s.filterCategoryHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final BreakCategory category in BreakCategory.filterable)
                  FilterChip(
                    label: Text(category.label(s)),
                    selected: filter.categories.contains(category),
                    avatar: category.hasDetector
                        ? null
                        : const Icon(Icons.remove_circle_outline, size: 16),
                    onSelected: (_) => controller.toggleCategory(category),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(s.filterMinSeverityHeading, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(s.filterAll),
                  selected: filter.minSeverity == null,
                  onSelected: (_) => controller.setMinSeverity(null),
                ),
                for (int severity = BreakSeverity.min;
                    severity <= BreakSeverity.max;
                    severity++)
                  ChoiceChip(
                    label: Text(BreakSeverity.label(severity, s)),
                    selected: filter.minSeverity == severity,
                    onSelected: (_) => controller.setMinSeverity(severity),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.clear,
                    child: Text(s.resetButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.filterDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
