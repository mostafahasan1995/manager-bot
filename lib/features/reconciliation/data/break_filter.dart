import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// Query filter for `GET /v1/admin/reconciliation/breaks`.
///
/// TWO wire quirks are handled here so no screen has to remember them:
///
/// 1. `status` / `category` accept either a comma-separated string or repeated
///    params, but ONLY the comma form is upper-cased server-side. Repeated
///    params in lower case are a 400. This class therefore always emits ONE
///    comma-separated param with exact uppercase wire values.
/// 2. The ValidationPipe runs with `forbidNonWhitelisted`, so any key beyond
///    cursor / limit / status / category / minSeverity is a 400. [toQuery] only
///    ever emits the three filter keys; the client adds cursor and limit.
class BreakFilter {
  const BreakFilter({
    this.statuses = const <BreakStatus>{},
    this.categories = const <BreakCategory>{},
    this.minSeverity,
  });

  /// The server's own default view: unresolved work only.
  static const BreakFilter unresolved = BreakFilter();

  /// Statuses selected. EMPTY means "send no status param", which makes the
  /// server apply its default of OPEN + INVESTIGATING.
  final Set<BreakStatus> statuses;

  /// Categories selected. Empty means no category filter at all.
  final Set<BreakCategory> categories;

  /// `severity >= minSeverity`, 1..5. Null means no severity filter.
  final int? minSeverity;

  /// True when nothing has been narrowed and the server default applies.
  bool get isDefault =>
      statuses.isEmpty && categories.isEmpty && minSeverity == null;

  /// The statuses actually in effect, including the server-side default.
  Set<BreakStatus> get effectiveStatuses =>
      statuses.isEmpty ? BreakStatus.serverDefaultFilter : statuses;

  /// True when the current selection can include closed breaks.
  bool get includesTerminal =>
      effectiveStatuses.any((BreakStatus status) => status.isTerminal);

  int get activeFacetCount {
    int count = 0;
    if (statuses.isNotEmpty) {
      count++;
    }
    if (categories.isNotEmpty) {
      count++;
    }
    if (minSeverity != null) {
      count++;
    }
    return count;
  }

  /// Wire query parameters. `UNKNOWN` sentinels are never sent.
  Map<String, Object?> toQuery() {
    final List<String> statusNames = <String>[
      for (final BreakStatus status in BreakStatus.filterable)
        if (statuses.contains(status)) status.wireName,
    ];
    final List<String> categoryNames = <String>[
      for (final BreakCategory category in BreakCategory.filterable)
        if (categories.contains(category)) category.wireName,
    ];
    final int? severity = minSeverity;
    return <String, Object?>{
      if (statusNames.isNotEmpty) 'status': statusNames.join(','),
      if (categoryNames.isNotEmpty) 'category': categoryNames.join(','),
      if (severity != null) 'minSeverity': severity,
    };
  }

  /// Human summary for the filter bar.
  String describe(AppStrings s) {
    if (isDefault) {
      return s.filterDescribeDefault;
    }
    final List<String> parts = <String>[];
    if (statuses.isNotEmpty) {
      parts.add(
        <String>[
          for (final BreakStatus status in BreakStatus.filterable)
            if (statuses.contains(status)) status.label(s),
        ].join(s.listSeparator),
      );
    }
    if (categories.isNotEmpty) {
      parts.add(
        <String>[
          for (final BreakCategory category in BreakCategory.filterable)
            if (categories.contains(category)) category.label(s),
        ].join(s.listSeparator),
      );
    }
    final int? severity = minSeverity;
    if (severity != null) {
      parts.add(
        s.filterDescribeSeverity(
          severity: BreakSeverity.shortLabel(severity, s),
        ),
      );
    }
    return parts.join(' - ');
  }

  BreakFilter toggleStatus(BreakStatus status) {
    final Set<BreakStatus> next = <BreakStatus>{...statuses};
    if (!next.remove(status)) {
      next.add(status);
    }
    return BreakFilter(
      statuses: Set<BreakStatus>.unmodifiable(next),
      categories: categories,
      minSeverity: minSeverity,
    );
  }

  BreakFilter toggleCategory(BreakCategory category) {
    final Set<BreakCategory> next = <BreakCategory>{...categories};
    if (!next.remove(category)) {
      next.add(category);
    }
    return BreakFilter(
      statuses: statuses,
      categories: Set<BreakCategory>.unmodifiable(next),
      minSeverity: minSeverity,
    );
  }

  /// Pass null to clear the severity floor.
  BreakFilter withMinSeverity(int? severity) => BreakFilter(
        statuses: statuses,
        categories: categories,
        minSeverity: severity == null ? null : BreakSeverity.clamp(severity),
      );

  BreakFilter cleared() => BreakFilter.unresolved;

  @override
  bool operator ==(Object other) {
    if (other is! BreakFilter) {
      return false;
    }
    if (other.minSeverity != minSeverity) {
      return false;
    }
    if (other.statuses.length != statuses.length ||
        !other.statuses.containsAll(statuses)) {
      return false;
    }
    return other.categories.length == categories.length &&
        other.categories.containsAll(categories);
  }

  @override
  int get hashCode => Object.hash(
        minSeverity,
        Object.hashAllUnordered(statuses),
        Object.hashAllUnordered(categories),
      );

  @override
  String toString() => 'BreakFilter(${toQuery()})';
}
