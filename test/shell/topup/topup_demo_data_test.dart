import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/topup/data/topup_demo_data.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';

void main() {
  group('TopUpDemoData catalogue', () {
    test('ids are unique across methods and destinations', () {
      final Set<String> methodIds = <String>{};
      final Set<String> destinationIds = <String>{};
      for (final TopUpMethod method in TopUpDemoData.methods) {
        expect(methodIds.add(method.id), isTrue, reason: method.id);
        for (final TopUpDestination destination in method.destinations) {
          expect(
            destinationIds.add(destination.id),
            isTrue,
            reason: destination.id,
          );
        }
      }
      expect(methodIds.length, TopUpDemoData.methods.length);
    });

    test('every window is positive, ordered and wider than its fee', () {
      for (final TopUpMethod method in TopUpDemoData.methods) {
        expect(method.minAmount.isPositive, isTrue, reason: method.id);
        expect(method.minAmount < method.maxAmount, isTrue, reason: method.id);
        expect(method.feeFixed.isNegative, isFalse, reason: method.id);
        // A method that credits nothing at its own minimum is a broken method.
        expect(
          method.creditedFor(method.minAmount).isPositive,
          isTrue,
          reason: method.id,
        );
      }
    });

    test('every amount is NSP at scale 2', () {
      for (final TopUpMethod method in TopUpDemoData.methods) {
        for (final Money amount in <Money>[
          method.minAmount,
          method.maxAmount,
          method.feeFixed,
        ]) {
          expect(amount.currency, 'NSP');
          expect(amount.scale, 2);
        }
      }
    });

    test('quick picks sit inside the union window', () {
      final TopUpLimits? limits = TopUpLimits.across(TopUpDemoData.methods);
      expect(limits, isNotNull);
      final TopUpLimits window = limits!;
      for (final Money pick in TopUpDemoData.quickPicks) {
        expect(window.accepts(pick), isTrue, reason: pick.toDecimalString());
      }
      expect(TopUpDemoData.quickPicks.length, 4);
      expect(TopUpDemoData.quickPicks.first.toMinorString(), '1000000');
    });

    test('at least one method has no destination, so the empty state is real',
        () {
      final bool anyEmpty = TopUpDemoData.methods
          .any((TopUpMethod method) => method.destinations.isEmpty);
      final bool anyStocked = TopUpDemoData.methods
          .any((TopUpMethod method) => method.destinations.isNotEmpty);
      expect(anyEmpty, isTrue);
      expect(anyStocked, isTrue);
    });

    test('both locales carry a name and instructions', () {
      for (final TopUpMethod method in TopUpDemoData.methods) {
        expect(method.name('ar').trim(), isNotEmpty);
        expect(method.name('en').trim(), isNotEmpty);
        expect(method.instructions('ar').trim(), isNotEmpty);
        expect(method.instructions('en').trim(), isNotEmpty);
        for (final TopUpDestination destination in method.destinations) {
          expect(destination.label('ar').trim(), isNotEmpty);
          expect(destination.label('en').trim(), isNotEmpty);
          expect(destination.accountHolder.trim(), isNotEmpty);
          expect(destination.accountNumber.trim(), isNotEmpty);
        }
      }
    });

    test('accepts() is inclusive and exact', () {
      final TopUpMethod method = TopUpDemoData.methods.first;
      expect(method.accepts(method.minAmount), isTrue);
      expect(method.accepts(method.maxAmount), isTrue);
      expect(
        method.accepts(
          Money.fromMinor(method.minAmount.minor - BigInt.one),
        ),
        isFalse,
      );
      expect(
        method.accepts(
          Money.fromMinor(method.maxAmount.minor + BigInt.one),
        ),
        isFalse,
      );
    });

    test('generated identifiers avoid look-alike characters', () {
      final String shortId = TopUpDemoData.newShortId();
      final String reference = TopUpDemoData.newReference();
      expect(shortId.startsWith('DP-'), isTrue);
      expect(shortId.length, 9);
      expect(reference.startsWith('TX'), isTrue);
      expect(reference.length, 10);
      expect(RegExp('[ILO01]').hasMatch(shortId.substring(3)), isFalse);
      expect(RegExp('[ILO01]').hasMatch(reference.substring(2)), isFalse);
    });

    test('loadMethods answers with the same catalogue', () async {
      final List<TopUpMethod> loaded = await TopUpDemoData.loadMethods();
      expect(loaded.length, TopUpDemoData.methods.length);
      expect(loaded.first.id, TopUpDemoData.methods.first.id);
    });
  });
}
