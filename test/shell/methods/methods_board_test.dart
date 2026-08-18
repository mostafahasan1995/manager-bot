import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/methods/application/methods_providers.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';
import 'package:manager_bot/features/shell/methods/data/payment_methods_demo_data.dart';
import 'package:manager_bot/features/shell/methods/presentation/methods_formats.dart';

/// Pure-Dart cover for the طرق الدفع destination.
///
/// Nothing here pumps a widget: the catalogue, the filter and the board are all
/// plain values on purpose, so the money invariants can be pinned exactly.
void main() {
  group('demo catalogue', () {
    test('every amount is exact minor units in NSP at scale 2', () {
      for (final PlayerPaymentMethod method in PaymentMethodsDemoData.methods()) {
        for (final Money amount in <Money>[
          method.minAmount,
          method.maxAmount,
          method.fixedFee,
        ]) {
          expect(amount.currency, 'NSP', reason: method.id);
          expect(amount.scale, 2, reason: method.id);
          expect(amount.isNegative, isFalse, reason: method.id);
        }
        expect(method.minAmount.isPositive, isTrue, reason: method.id);
        expect(method.minAmount < method.maxAmount, isTrue, reason: method.id);
      }
    });

    test('minor units decode to the intended major amounts', () {
      final PlayerPaymentMethod syriatel = _byId('syriatel-cash');
      expect(syriatel.minAmount.toMinorString(), '2500000');
      expect(syriatel.minAmount.toDecimalString(), '25000.00');
      expect(syriatel.maxAmount.toDecimalString(), '3000000.00');
      expect(syriatel.fixedFee.isZero, isTrue);
      expect(syriatel.hasFee, isFalse);

      final PlayerPaymentMethod mtn = _byId('mtn-cash');
      expect(mtn.fixedFee.toDecimalString(), '2500.00');
      expect(mtn.hasFee, isTrue);
    });

    test('ids are unique and every card has content to render', () {
      final List<PlayerPaymentMethod> catalogue =
          PaymentMethodsDemoData.methods();
      final Set<String> ids =
          catalogue.map((PlayerPaymentMethod m) => m.id).toSet();
      expect(ids.length, catalogue.length);

      for (final PlayerPaymentMethod method in catalogue) {
        expect(method.monogram.trim(), isNotEmpty, reason: method.id);
        expect(method.destinationAccount.trim(), isNotEmpty, reason: method.id);
        expect(method.steps, isNotEmpty, reason: method.id);
        expect(method.proofItems, isNotEmpty, reason: method.id);
        expect(method.name.resolve('ar').trim(), isNotEmpty, reason: method.id);
        expect(method.name.resolve('en').trim(), isNotEmpty, reason: method.id);
        expect(method.settlement > Duration.zero, isTrue, reason: method.id);
        expect(method.checkedAgo > Duration.zero, isTrue, reason: method.id);
      }
    });

    test('exactly one featured rail, and it is one a player can actually use',
        () {
      final List<PlayerPaymentMethod> popular = PaymentMethodsDemoData.methods()
          .where((PlayerPaymentMethod m) => m.popular)
          .toList(growable: false);
      expect(popular.length, 1);
      expect(popular.single.acceptsTopUp, isTrue);
    });

    test('the three availability states are all represented', () {
      final Set<MethodAvailability> states = PaymentMethodsDemoData.methods()
          .map((PlayerPaymentMethod m) => m.availability)
          .toSet();
      expect(states, containsAll(MethodAvailability.values));
    });
  });

  group('MethodsFilter', () {
    test('a null rail clears the rail filter and is not "filtered"', () {
      const MethodsFilter base = MethodsFilter();
      expect(base.isUnfiltered, isTrue);
      expect(base.withRail(MethodRail.crypto).isUnfiltered, isFalse);
      expect(
        base.withRail(MethodRail.crypto).withRail(null).isUnfiltered,
        isTrue,
      );
      expect(base.withAvailableOnly(true).isUnfiltered, isFalse);
    });

    test('allows() combines rail and availability', () {
      final PlayerPaymentMethod paused = _byId('sham-cash');
      expect(const MethodsFilter().allows(paused), isTrue);
      expect(
        const MethodsFilter(availableOnly: true).allows(paused),
        isFalse,
      );
      expect(
        const MethodsFilter(rail: MethodRail.crypto).allows(paused),
        isFalse,
      );
    });

    test('value equality, so a rebuild with the same filter is a no-op', () {
      expect(
        const MethodsFilter(rail: MethodRail.crypto),
        const MethodsFilter(rail: MethodRail.crypto),
      );
      expect(
        const MethodsFilter(rail: MethodRail.crypto).hashCode,
        const MethodsFilter(rail: MethodRail.crypto).hashCode,
      );
      expect(
        const MethodsFilter(rail: MethodRail.crypto) ==
            const MethodsFilter(rail: MethodRail.cashOffice),
        isFalse,
      );
    });
  });

  group('MethodsBoard', () {
    test('unfiltered: hero is promoted out of the open list', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: PaymentMethodsDemoData.methods(),
        filter: const MethodsFilter(),
      );
      final PlayerPaymentMethod? hero = board.featured;
      expect(hero, isNotNull);
      expect(hero?.id, 'syriatel-cash');
      expect(board.open.map((PlayerPaymentMethod m) => m.id), isNot(contains('syriatel-cash')));
      expect(board.isEmpty, isFalse);
      expect(board.catalogueIsEmpty, isFalse);
      expect(board.isFiltered, isFalse);
    });

    test('paused rails are separated but never dropped', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: PaymentMethodsDemoData.methods(),
        filter: const MethodsFilter(),
      );
      expect(board.paused, isNotEmpty);
      for (final PlayerPaymentMethod method in board.paused) {
        expect(method.acceptsTopUp, isFalse);
      }
      for (final PlayerPaymentMethod method in board.open) {
        expect(method.acceptsTopUp, isTrue);
      }
      expect(
        board.open.length + board.paused.length + 1,
        board.totalCount,
      );
    });

    test('counts are of the WHOLE catalogue, not of the filtered view', () {
      final List<PlayerPaymentMethod> catalogue =
          PaymentMethodsDemoData.methods();
      final MethodsBoard board = MethodsBoard.from(
        catalogue: catalogue,
        filter: const MethodsFilter(rail: MethodRail.crypto),
      );
      expect(board.totalCount, catalogue.length);
      expect(
        board.availableCount,
        catalogue.where((PlayerPaymentMethod m) => m.acceptsTopUp).length,
      );
      expect(board.isFiltered, isTrue);
    });

    test('availableOnly hides every paused rail', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: PaymentMethodsDemoData.methods(),
        filter: const MethodsFilter(availableOnly: true),
      );
      expect(board.paused, isEmpty);
      expect(board.isEmpty, isFalse);
    });

    test('a filter that matches nothing is empty but the catalogue is not', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: PaymentMethodsDemoData.methods(),
        filter: const MethodsFilter(rail: MethodRail.internal),
      );
      expect(board.isEmpty, isTrue);
      expect(board.catalogueIsEmpty, isFalse);
    });

    test('an empty catalogue reports itself as empty', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: const <PlayerPaymentMethod>[],
        filter: const MethodsFilter(),
      );
      expect(board.catalogueIsEmpty, isTrue);
      expect(board.isEmpty, isTrue);
      expect(board.featured, isNull);
    });

    test('a paused rail is never promoted into the hero slot', () {
      final MethodsBoard board = MethodsBoard.from(
        catalogue: <PlayerPaymentMethod>[
          PlayerPaymentMethod(
            id: 'paused-popular',
            name: const LocalizedText('معطّلة', 'Paused'),
            monogram: 'PP',
            rail: MethodRail.mobileWallet,
            accent: MethodAccent.hot,
            minAmount: Money.fromMinorString('100000'),
            maxAmount: Money.fromMinorString('10000000'),
            fixedFee: Money.zero(),
            settlement: const Duration(minutes: 5),
            requiresReference: true,
            availability: MethodAvailability.unavailable,
            checkedAgo: const Duration(minutes: 3),
            destinationAccount: '0000',
            destinationHolder: const LocalizedText('اختبار', 'Test'),
            popular: true,
            steps: const <LocalizedText>[LocalizedText('خطوة', 'Step')],
            proofItems: const <LocalizedText>[LocalizedText('إثبات', 'Proof')],
          ),
        ],
        filter: const MethodsFilter(),
      );
      expect(board.featured, isNull);
      expect(board.paused.length, 1);
    });
  });

  group('PaymentMethodsDemoSource', () {
    test('the data outcome returns the catalogue', () async {
      const PaymentMethodsDemoSource source =
          PaymentMethodsDemoSource(latency: Duration.zero);
      expect(await source.load(), isNotEmpty);
    });

    test('the empty outcome returns an empty list, not null', () async {
      const PaymentMethodsDemoSource source = PaymentMethodsDemoSource(
        latency: Duration.zero,
        outcome: MethodsDemoOutcome.empty,
      );
      expect(await source.load(), isEmpty);
    });

    test('the failure outcome throws the sealed transport error', () async {
      const PaymentMethodsDemoSource source = PaymentMethodsDemoSource(
        latency: Duration.zero,
        outcome: MethodsDemoOutcome.failure,
      );
      await expectLater(source.load(), throwsA(isA<ApiNetworkError>()));
    });
  });

  group('MethodsFormats.duration', () {
    test('renders Western digits under both locales', () {
      expect(
        MethodsFormats.duration(const Duration(minutes: 12), AppStrings.ar),
        contains('12'),
      );
      expect(
        MethodsFormats.duration(const Duration(minutes: 12), AppStrings.en),
        contains('12'),
      );
    });

    test('coarsens hours and days the way the catalogue phrases them', () {
      expect(
        MethodsFormats.duration(const Duration(hours: 3), AppStrings.en),
        '3h',
      );
      expect(
        MethodsFormats.duration(
          const Duration(hours: 1, minutes: 30),
          AppStrings.en,
        ),
        '1h 30m',
      );
      expect(
        MethodsFormats.duration(const Duration(seconds: 20), AppStrings.en),
        AppStrings.en.ageNow,
      );
    });
  });
}

PlayerPaymentMethod _byId(String id) => PaymentMethodsDemoData.methods()
    .firstWhere((PlayerPaymentMethod method) => method.id == id);
