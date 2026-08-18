import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/home/data/home_demo_data.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';

/// The home tab renders from local sample content until the player API gains a
/// session. These tests pin the properties that make that content SAFE to swap
/// for a live repository: exact minor units, a real spread of statuses, and a
/// newest-first ordering the screen relies on when it slices the top three.
void main() {
  group('HomeDemoData money', () {
    test('the balance is exact minor units at scale 2, never a double', () {
      final Money balance = HomeDemoData.balance();

      expect(balance.minor, BigInt.parse('150750000'));
      expect(balance.currency, 'NSP');
      expect(balance.scale, 2);
      // 150750000 minor == 1,507,500.00 major. No rounding anywhere.
      expect(balance.toDecimalString(), '1507500.00');
    });

    test('every demo amount round-trips through its minor string', () {
      for (final HomeDeposit deposit in HomeDemoData.recentDeposits()) {
        final Money reparsed = Money.fromMinorString(
          deposit.amount.toMinorString(),
        );
        expect(reparsed, deposit.amount);
        expect(deposit.amount.scale, 2);
        expect(deposit.amount.currency, 'NSP');
        expect(deposit.amount.isPositive, isTrue);
      }
    });

    test('the amounts are the ones a Syrian player would actually send', () {
      expect(
        HomeDemoData.recentDeposits()
            .map((HomeDeposit d) => d.amount.toDecimalString())
            .toList(),
        <String>['250000.00', '75000.00', '500000.00', '120000.00'],
      );
    });
  });

  group('HomeDemoData.recentDeposits', () {
    test('is newest first, which is what visibleDeposits assumes', () {
      final List<HomeDeposit> deposits = HomeDemoData.recentDeposits();

      for (int i = 1; i < deposits.length; i++) {
        expect(
          deposits[i].age > deposits[i - 1].age,
          isTrue,
          reason: 'row $i is older than the row above it',
        );
      }
    });

    test('spreads the statuses so every tone is on screen at once', () {
      final Set<HomeDepositStatus> statuses = HomeDemoData.recentDeposits()
          .map((HomeDeposit d) => d.status)
          .toSet();

      expect(statuses.length, greaterThanOrEqualTo(4));
      expect(statuses, contains(HomeDepositStatus.credited));
      expect(statuses, contains(HomeDepositStatus.rejected));
      expect(statuses, contains(HomeDepositStatus.underReview));
    });

    test('every row carries a reference the bot could have quoted', () {
      for (final HomeDeposit deposit in HomeDemoData.recentDeposits()) {
        expect(deposit.shortId, isNotEmpty);
        expect(deposit.methodName, isNotEmpty);
        expect(deposit.age, greaterThan(Duration.zero));
      }
    });
  });

  group('HomeSnapshot', () {
    test('the populated snapshot shows three of its four rows', () {
      final HomeSnapshot snapshot = HomeDemoData.snapshot();

      expect(snapshot.recentDeposits.length, 4);
      expect(snapshot.visibleDeposits.length, HomeSnapshot.recentLimit);
      expect(snapshot.visibleDeposits.first, snapshot.recentDeposits.first);
      expect(snapshot.hasRecentDeposits, isTrue);
    });

    test('pendingCount matches the rows that are still waiting', () {
      final HomeSnapshot snapshot = HomeDemoData.snapshot();
      final int waiting = snapshot.recentDeposits
          .where(
            (HomeDeposit d) =>
                d.status == HomeDepositStatus.submitted ||
                d.status == HomeDepositStatus.underReview,
          )
          .length;

      expect(snapshot.pendingCount, waiting);
    });

    test('the banner has something to say: the account is not linked yet', () {
      expect(HomeDemoData.snapshot().isCasinoAccountLinked, isFalse);
    });

    test('the empty snapshot is a real zero, not a missing value', () {
      final HomeSnapshot snapshot = HomeDemoData.emptySnapshot();

      expect(snapshot.recentDeposits, isEmpty);
      expect(snapshot.visibleDeposits, isEmpty);
      expect(snapshot.hasRecentDeposits, isFalse);
      expect(snapshot.balance.minor, BigInt.zero);
      expect(snapshot.balance.currency, 'NSP');
      expect(snapshot.pendingCount, 0);
    });

    test('both snapshots name a player and carry avatar glyphs', () {
      for (final HomeSnapshot snapshot in <HomeSnapshot>[
        HomeDemoData.snapshot(),
        HomeDemoData.emptySnapshot(),
      ]) {
        expect(snapshot.playerName, isNotEmpty);
        expect(snapshot.playerInitials, isNotEmpty);
      }
    });
  });

  group('HomeDemoData.promos', () {
    test('the carousel has pages and never repeats a slot', () {
      expect(HomeDemoData.promos, isNotEmpty);
      expect(
        HomeDemoData.promos.map((HomePromo p) => p.slot).toSet().length,
        HomeDemoData.promos.length,
      );
    });

    test('each page carries its own accent so the rail is not monotone', () {
      expect(
        HomeDemoData.promos.map((HomePromo p) => p.accent).toSet().length,
        HomeDemoData.promos.length,
      );
    });
  });

  group('HomeDemoMode', () {
    test('the empty and failing shapes stay reachable', () {
      expect(
        HomeDemoMode.values,
        <HomeDemoMode>[
          HomeDemoMode.content,
          HomeDemoMode.empty,
          HomeDemoMode.unavailable,
        ],
      );
    });
  });
}
