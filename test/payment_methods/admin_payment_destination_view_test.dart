import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';

/// A realistic destination row. `dailyCap` is a bare decimal string or null;
/// there is no currency field on this payload.
Map<String, Object?> destinationJson() => <String, Object?>{
      'id': 'b6a3c4d2-1e5f-4a7b-8c9d-0e1f2a3b4c5d',
      'paymentMethodId': '0f2f1f0e-9b1a-4a5d-9c2f-2a4d6e8f0a11',
      'label': 'Main bank account',
      'accountIdentifier': 'SEED-PLACEHOLDER-BANK-0000',
      'accountHolder': 'REPLACE ME',
      'notes': 'Created by the seed. Replace with a real account before taking '
          'deposits.',
      'isActive': true,
      'priority': 0,
      'dailyCap': null,
      'createdAt': '2026-08-14T09:12:33.482Z',
      'updatedAt': '2026-08-14T09:12:33.482Z',
    };

void main() {
  group('AdminPaymentDestinationView.fromJson', () {
    test('parses the seeded placeholder row', () {
      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(destinationJson());

      expect(destination.id, 'b6a3c4d2-1e5f-4a7b-8c9d-0e1f2a3b4c5d');
      expect(destination.paymentMethodId,
          '0f2f1f0e-9b1a-4a5d-9c2f-2a4d6e8f0a11');
      expect(destination.label, 'Main bank account');
      expect(destination.priority, 0);
      expect(destination.isActive, isTrue);
      expect(destination.dailyCap, isNull);
    });

    test('keeps the account identifier byte-for-byte', () {
      // A Base58 address must survive verbatim: uppercasing it would produce a
      // different, valid-looking address.
      const String address = '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2';
      final Map<String, Object?> json = destinationJson()
        ..['accountIdentifier'] = address;

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.accountIdentifier, address);
    });

    test('parses a daily cap as exact minor units', () {
      final Map<String, Object?> json = destinationJson()
        ..['dailyCap'] = '250000.00';

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.dailyCap?.minor, BigInt.parse('25000000'));
      expect(destination.dailyCap?.toDecimalString(), '250000.00');
    });

    test('restates the cap in the owning method currency', () {
      final Map<String, Object?> json = destinationJson()
        ..['dailyCap'] = '250000.00';

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);
      final BigInt before = destination.dailyCap!.minor;

      expect(destination.dailyCapIn('EUR')?.currency, 'EUR');
      // Only the label moves; the exact amount never does.
      expect(destination.dailyCapIn('EUR')?.minor, before);
      expect(destination.dailyCapIn('NSP'), destination.dailyCap);
    });

    test('a null cap stays null in every currency', () {
      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(destinationJson());

      expect(destination.dailyCapIn('NSP'), isNull);
    });
  });

  group('placeholder detection', () {
    test('flags the seeded row on all three signals', () {
      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(destinationJson());

      expect(destination.looksLikePlaceholder, isTrue);
      expect(destination.isLivePlaceholder, isTrue);
      // The reasons are prose now, so they are asked for in a locale. Both
      // bundles must produce the same COUNT.
      expect(destination.placeholderReasons(AppStrings.en).length, 3);
      expect(destination.placeholderReasons(AppStrings.ar).length, 3);
    });

    test('a disabled placeholder is not LIVE', () {
      final Map<String, Object?> json = destinationJson()..['isActive'] = false;

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.looksLikePlaceholder, isTrue);
      expect(destination.isLivePlaceholder, isFalse);
    });

    test('a real account is not flagged', () {
      final Map<String, Object?> json = destinationJson()
        ..['accountIdentifier'] = 'DE89370400440532013000'
        ..['accountHolder'] = 'Northern Holdings Ltd'
        ..['notes'] = 'Business account, branch 004.';

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.looksLikePlaceholder, isFalse);
      expect(destination.placeholderReasons(AppStrings.en), isEmpty);
    });

    test('flags a hand-typed CHANGEME identifier', () {
      final Map<String, Object?> json = destinationJson()
        ..['accountIdentifier'] = 'changeme-0001'
        ..['accountHolder'] = 'Northern Holdings Ltd'
        ..['notes'] = null;

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.looksLikePlaceholder, isTrue);
      expect(destination.placeholderReasons(AppStrings.en).length, 1);
    });

    test('an empty account holder is not treated as a placeholder', () {
      final Map<String, Object?> json = destinationJson()
        ..['accountIdentifier'] = 'DE89370400440532013000'
        ..['accountHolder'] = null
        ..['notes'] = null;

      final AdminPaymentDestinationView destination =
          AdminPaymentDestinationView.fromJson(json);

      expect(destination.accountHolder, isNull);
      expect(destination.looksLikePlaceholder, isFalse);
    });
  });
}
