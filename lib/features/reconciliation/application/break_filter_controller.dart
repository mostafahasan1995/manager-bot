import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/features/reconciliation/data/break_filter.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// Holds the break-list filter. The list controller WATCHES this, so any change
/// here restarts pagination from page 1 - which is the only correct behaviour
/// with an opaque cursor: a cursor taken under one filter is meaningless under
/// another.
class BreakFilterController extends Notifier<BreakFilter> {
  @override
  BreakFilter build() => BreakFilter.unresolved;

  void toggleStatus(BreakStatus status) {
    state = state.toggleStatus(status);
  }

  void toggleCategory(BreakCategory category) {
    state = state.toggleCategory(category);
  }

  /// Null clears the severity floor.
  void setMinSeverity(int? severity) {
    state = state.withMinSeverity(severity);
  }

  /// Back to the server default view (OPEN + INVESTIGATING, no other narrowing).
  void clear() {
    state = BreakFilter.unresolved;
  }

  /// One-tap preset: everything that still needs a human.
  void showUnresolvedOnly() {
    state = const BreakFilter(statuses: BreakStatus.serverDefaultFilter);
  }

  /// One-tap preset: only what is actively bleeding.
  void showCriticalOnly() {
    state = const BreakFilter(
      statuses: BreakStatus.serverDefaultFilter,
      minSeverity: 4,
    );
  }

  void replace(BreakFilter filter) {
    state = filter;
  }
}

final NotifierProvider<BreakFilterController, BreakFilter> breakFilterProvider =
    NotifierProvider<BreakFilterController, BreakFilter>(
  BreakFilterController.new,
);
