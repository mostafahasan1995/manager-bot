import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/data/break_filter.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

void main() {
  group('BreakFilter.toQuery', () {
    test('sends nothing when nothing is selected, so the server default wins',
        () {
      expect(BreakFilter.unresolved.toQuery(), isEmpty);
      expect(BreakFilter.unresolved.isDefault, isTrue);
      expect(
        BreakFilter.unresolved.effectiveStatuses,
        <BreakStatus>{BreakStatus.open, BreakStatus.investigating},
      );
    });

    test('emits ONE comma-separated uppercase status param', () {
      final BreakFilter filter = BreakFilter.unresolved
          .toggleStatus(BreakStatus.investigating)
          .toggleStatus(BreakStatus.open);

      // Order follows the declared filterable order, not tap order, so the
      // query string is stable across taps.
      expect(filter.toQuery()['status'], 'OPEN,INVESTIGATING');
    });

    test('emits ONE comma-separated uppercase category param', () {
      final BreakFilter filter = BreakFilter.unresolved
          .toggleCategory(BreakCategory.ledgerImbalance)
          .toggleCategory(BreakCategory.agentFloatMismatch);

      expect(
        filter.toQuery()['category'],
        'AGENT_FLOAT_MISMATCH,LEDGER_IMBALANCE',
      );
    });

    test('never emits the UNKNOWN sentinels', () {
      const BreakFilter filter = BreakFilter(
        statuses: <BreakStatus>{BreakStatus.unknown, BreakStatus.open},
        categories: <BreakCategory>{
          BreakCategory.unknown,
          BreakCategory.missingCredit,
        },
      );

      expect(filter.toQuery()['status'], 'OPEN');
      expect(filter.toQuery()['category'], 'MISSING_CREDIT');
    });

    test('sends minSeverity as an integer and clamps it', () {
      expect(
        BreakFilter.unresolved.withMinSeverity(4).toQuery()['minSeverity'],
        4,
      );
      expect(
        BreakFilter.unresolved.withMinSeverity(9).toQuery()['minSeverity'],
        5,
      );
      expect(
        BreakFilter.unresolved.withMinSeverity(4).withMinSeverity(null).toQuery(),
        isEmpty,
      );
    });

    test('only ever emits whitelisted keys', () {
      final BreakFilter filter = BreakFilter.unresolved
          .toggleStatus(BreakStatus.resolved)
          .toggleCategory(BreakCategory.agentFloatMismatch)
          .withMinSeverity(2);

      expect(
        filter.toQuery().keys.toSet(),
        <String>{'status', 'category', 'minSeverity'},
      );
    });
  });

  group('BreakFilter selection', () {
    test('toggling twice removes the facet again', () {
      final BreakFilter filter = BreakFilter.unresolved
          .toggleStatus(BreakStatus.resolved)
          .toggleStatus(BreakStatus.resolved);

      expect(filter.statuses, isEmpty);
      expect(filter.isDefault, isTrue);
    });

    test('counts active facets for the filter button', () {
      expect(BreakFilter.unresolved.activeFacetCount, 0);
      expect(
        BreakFilter.unresolved
            .toggleStatus(BreakStatus.open)
            .withMinSeverity(3)
            .activeFacetCount,
        2,
      );
    });

    test('knows when closed breaks can appear', () {
      expect(BreakFilter.unresolved.includesTerminal, isFalse);
      expect(
        BreakFilter.unresolved.toggleStatus(BreakStatus.writtenOff).includesTerminal,
        isTrue,
      );
    });

    test('describes itself for the filter bar', () {
      expect(
        BreakFilter.unresolved.describe(AppStrings.en),
        'Unresolved breaks',
      );
      expect(
        BreakFilter.unresolved
            .toggleStatus(BreakStatus.resolved)
            .withMinSeverity(5)
            .describe(AppStrings.en),
        'Resolved - severity S5+',
      );
    });

    test('describes itself in Arabic without touching the wire values', () {
      final BreakFilter filter = BreakFilter.unresolved
          .toggleStatus(BreakStatus.resolved)
          .withMinSeverity(5);

      expect(filter.describe(AppStrings.ar), isNot(contains('Resolved')));
      // The severity chip stays Latin in both locales.
      expect(filter.describe(AppStrings.ar), contains('S5'));
      expect(filter.toQuery()['status'], 'RESOLVED');
    });

    test('compares by value so the list provider only refetches on change', () {
      final BreakFilter a = BreakFilter.unresolved
          .toggleStatus(BreakStatus.open)
          .toggleStatus(BreakStatus.investigating);
      final BreakFilter b = BreakFilter.unresolved
          .toggleStatus(BreakStatus.investigating)
          .toggleStatus(BreakStatus.open);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.withMinSeverity(1), isFalse);
    });
  });
}
