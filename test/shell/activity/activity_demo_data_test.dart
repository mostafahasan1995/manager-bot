import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/activity/data/activity_demo_data.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';

/// Pure-Dart guards on the demo source and on the rules the screen leans on.
///
/// None of these need a widget tree: they check that the money stays exact
/// `BigInt` minor units, that the four chips partition the history without
/// overlap or loss, that local paging hands every row over exactly once, and
/// that the timeline never dangles a "credited" rung under a rejection.
void main() {
  final DateTime anchor = DateTime(2026, 8, 17, 14, 30);

  ActivityDemoRepository repository() =>
      ActivityDemoRepository(anchor: anchor, latency: Duration.zero);

  group('demo content', () {
    test('every amount is NSP at scale 2 and exact', () {
      final List<ActivityDeposit> rows = ActivityDemoData.feed(now: anchor);
      expect(rows, isNotEmpty);
      for (final ActivityDeposit row in rows) {
        expect(row.amount.currency, 'NSP');
        expect(row.amount.scale, 2);
        expect(row.amount.isPositive, isTrue);
        // Re-parsing the exact minor string must round-trip bit for bit; a
        // double anywhere in the pipeline would break this.
        expect(
          Money.fromMinorString(row.amount.toMinorString()),
          row.amount,
        );
        final Money? credited = row.credited;
        if (credited != null) {
          expect(credited.currency, 'NSP');
          expect(credited <= row.amount, isTrue);
        }
      }
    });

    test('short ids are unique, so paging can dedupe on them', () {
      final List<ActivityDeposit> rows = ActivityDemoData.feed(now: anchor);
      final Set<String> ids = <String>{
        for (final ActivityDeposit row in rows) row.shortId,
      };
      expect(ids.length, rows.length);
    });

    test('only settled rows carry a credited amount', () {
      for (final ActivityDeposit row in ActivityDemoData.feed(now: anchor)) {
        if (row.credited != null) {
          expect(row.status, ActivityStatus.credited);
        }
      }
    });

    test('the history spans every status the screen can render', () {
      final Set<ActivityStatus> seen = <ActivityStatus>{
        for (final ActivityDeposit row in ActivityDemoData.feed(now: anchor))
          row.status,
      };
      expect(seen, contains(ActivityStatus.submitted));
      expect(seen, contains(ActivityStatus.underReview));
      expect(seen, contains(ActivityStatus.crediting));
      expect(seen, contains(ActivityStatus.approved));
      expect(seen, contains(ActivityStatus.credited));
      expect(seen, contains(ActivityStatus.rejected));
      expect(seen, contains(ActivityStatus.expired));
    });
  });

  group('filters', () {
    test('the three narrow chips partition الكل exactly', () {
      final List<ActivityDeposit> rows = ActivityDemoData.feed(now: anchor);
      int inReview = 0;
      int completed = 0;
      int rejected = 0;
      for (final ActivityDeposit row in rows) {
        if (ActivityFilter.inReview.matches(row.status)) {
          inReview += 1;
        }
        if (ActivityFilter.completed.matches(row.status)) {
          completed += 1;
        }
        if (ActivityFilter.rejected.matches(row.status)) {
          rejected += 1;
        }
        expect(ActivityFilter.all.matches(row.status), isTrue);
      }
      expect(inReview + completed + rejected, rows.length);
      expect(inReview, greaterThan(0));
      expect(completed, greaterThan(0));
      expect(rejected, greaterThan(0));
    });
  });

  group('local paging', () {
    test('walks the whole filtered set once, then stops', () async {
      final ActivityDemoRepository source = repository();
      final List<String> collected = <String>[];
      int offset = 0;
      bool more = true;
      int total = 0;
      while (more) {
        final ActivityPage page = await source.page(
          filter: ActivityFilter.all,
          offset: offset,
          limit: 6,
        );
        total = page.total;
        for (final ActivityDeposit row in page.items) {
          collected.add(row.shortId);
        }
        offset += page.items.length;
        more = page.hasMore;
      }
      expect(collected.length, total);
      expect(collected.toSet().length, collected.length);
    });

    test('an offset past the end is an empty, terminal page', () async {
      final ActivityPage page = await repository().page(
        filter: ActivityFilter.completed,
        offset: 9999,
        limit: 6,
      );
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('failLoads surfaces the error branch', () async {
      final ActivityDemoRepository source = ActivityDemoRepository(
        anchor: anchor,
        latency: Duration.zero,
        failLoads: true,
      );
      await expectLater(
        source.page(filter: ActivityFilter.all, offset: 0, limit: 6),
        throwsA(isA<ActivityUnavailable>()),
      );
      await expectLater(
        source.summary(),
        throwsA(isA<ActivityUnavailable>()),
      );
    });
  });

  group('summary', () {
    test('totals the credited rows exactly, in BigInt', () async {
      final ActivityDemoRepository source = repository();
      final ActivitySummary summary = await source.summary();

      Money expected = Money.zero();
      int open = 0;
      for (final ActivityDeposit row in ActivityDemoData.feed(now: anchor)) {
        final Money? credited = row.credited;
        if (credited != null) {
          expected = expected + credited;
        }
        if (row.status.isOpen) {
          open += 1;
        }
      }

      expect(summary.totalCredited, expected);
      expect(summary.totalCredited.minor, expected.minor);
      expect(summary.openCount, open);
      expect(summary.totalCount, ActivityDemoData.feed(now: anchor).length);
    });
  });

  group('timeline', () {
    test('a settled deposit is four done rungs and nothing pending', () {
      final ActivityDeposit row = ActivityDemoData.feed(now: anchor).firstWhere(
        (ActivityDeposit candidate) =>
            candidate.status == ActivityStatus.credited,
      );
      final List<ActivityStep> steps = row.timeline;
      expect(steps.length, 4);
      for (final ActivityStep step in steps) {
        expect(step.state, ActivityStepState.done);
        expect(step.at, isNotNull);
      }
      expect(row.currentStep, isNull);
      expect(row.failedStep, isNull);
    });

    test('a rejection never dangles an upcoming credit rung', () {
      final ActivityDeposit row = ActivityDemoData.feed(now: anchor).firstWhere(
        (ActivityDeposit candidate) =>
            candidate.status == ActivityStatus.rejected,
      );
      final List<ActivityStep> steps = row.timeline;
      expect(
        steps.map((ActivityStep step) => step.kind),
        isNot(contains(ActivityStepKind.credited)),
      );
      expect(row.failedStep, isNotNull);
      expect(row.currentStep, isNull);
      expect(row.staffNote, isNotNull);
    });

    test('an open deposit has exactly one current rung', () {
      for (final ActivityDeposit row in ActivityDemoData.feed(now: anchor)) {
        if (!row.status.isOpen) {
          continue;
        }
        final int current = row.timeline
            .where((ActivityStep step) =>
                step.state == ActivityStepState.current)
            .length;
        expect(current, 1, reason: row.shortId);
      }
    });
  });
}
