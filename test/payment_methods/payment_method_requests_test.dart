import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_requests.dart';

/// The backend runs `whitelist + forbidNonWhitelisted` and every optional field
/// carries `@IsString`/`@IsBoolean`/`@IsInt`, so an explicit null is a 400 just
/// like an unknown key. These tests pin the "omit, never null" contract.
void main() {
  group('CreatePaymentMethodRequest', () {
    test('sends money as major-unit decimal strings with two decimals', () {
      final Map<String, Object?> json = CreatePaymentMethodRequest(
        code: 'BANK_TRANSFER_MAIN',
        displayName: 'Bank transfer',
        rail: PaymentRail.bankTransfer,
        currencyCode: 'NSP',
        verificationMode: VerificationMode.manualProof,
        minAmount: Money.fromDecimalString('5000.00'),
        maxAmount: Money.fromDecimalString('5000000.00'),
        feeFixed: Money.fromDecimalString('12.5'),
      ).toJson();

      expect(json['minAmount'], '5000.00');
      expect(json['maxAmount'], '5000000.00');
      // A one-decimal input is padded, never truncated or floated.
      expect(json['feeFixed'], '12.50');
      expect(json['minAmount'], isA<String>());
    });

    test('omits every absent optional instead of sending null', () {
      final Map<String, Object?> json = CreatePaymentMethodRequest(
        code: 'CASH_DESK',
        displayName: 'Cash desk',
        rail: PaymentRail.cashOffice,
        currencyCode: 'NSP',
        verificationMode: VerificationMode.manualProof,
        minAmount: Money.fromDecimalString('10.00'),
        maxAmount: Money.fromDecimalString('100.00'),
      ).toJson();

      expect(json.keys, <String>[
        'code',
        'displayName',
        'rail',
        'currencyCode',
        'verificationMode',
        'minAmount',
        'maxAmount',
      ]);
      expect(json.containsKey('feeFixed'), isFalse);
      expect(json.containsKey('instructions'), isFalse);
      expect(json.values.contains(null), isFalse);
    });

    test('serialises enums by their exact wire spelling', () {
      final Map<String, Object?> json = CreatePaymentMethodRequest(
        code: 'CRYPTO_MAIN',
        displayName: 'Crypto',
        rail: PaymentRail.crypto,
        currencyCode: 'NSP',
        verificationMode: VerificationMode.referenceMatch,
        minAmount: Money.fromDecimalString('10.00'),
        maxAmount: Money.fromDecimalString('100.00'),
      ).toJson();

      expect(json['rail'], 'CRYPTO');
      expect(json['verificationMode'], 'REFERENCE_MATCH');
    });

    test('keeps a false boolean, which is not the same as omitting it', () {
      final Map<String, Object?> json = CreatePaymentMethodRequest(
        code: 'X_RAIL',
        displayName: 'X',
        rail: PaymentRail.mobileWallet,
        currencyCode: 'NSP',
        verificationMode: VerificationMode.none,
        minAmount: Money.fromDecimalString('10.00'),
        maxAmount: Money.fromDecimalString('100.00'),
        isActive: false,
        requiresReference: false,
        feeBps: 0,
      ).toJson();

      expect(json['isActive'], false);
      expect(json['requiresReference'], false);
      expect(json['feeBps'], 0);
    });
  });

  group('UpdatePaymentMethodRequest', () {
    test('an untouched request serialises to an empty body', () {
      const UpdatePaymentMethodRequest request = UpdatePaymentMethodRequest();

      expect(request.toJson(), isEmpty);
      expect(request.isEmpty, isTrue);
      expect(request.isNotEmpty, isFalse);
    });

    test('never carries the immutable trio', () {
      final Map<String, Object?> json = UpdatePaymentMethodRequest(
        displayName: 'Renamed',
        minAmount: Money.fromDecimalString('1.00'),
      ).toJson();

      expect(json.containsKey('code'), isFalse);
      expect(json.containsKey('rail'), isFalse);
      expect(json.containsKey('currencyCode'), isFalse);
      expect(json['displayName'], 'Renamed');
      expect(json['minAmount'], '1.00');
    });

    test('the activation shorthand sends exactly one key', () {
      const UpdatePaymentMethodRequest request =
          UpdatePaymentMethodRequest.activation(isActive: true);

      expect(request.toJson(), <String, Object?>{'isActive': true});
    });

    test('an empty string is sent, because null cannot be', () {
      // The API has no way to clear a pattern back to null; '' is the closest
      // available action and the driver reads it as "no pattern".
      final Map<String, Object?> json =
          const UpdatePaymentMethodRequest(referencePattern: '').toJson();

      expect(json, <String, Object?>{'referencePattern': ''});
    });
  });

  group('destination requests', () {
    test('create omits absent optionals and keeps the identifier verbatim', () {
      const String address = '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2';
      final Map<String, Object?> json = const CreatePaymentDestinationRequest(
        label: 'Bitcoin',
        accountIdentifier: address,
      ).toJson();

      expect(json, <String, Object?>{
        'label': 'Bitcoin',
        'accountIdentifier': address,
      });
    });

    test('create sends a daily cap as a major-unit decimal string', () {
      final Map<String, Object?> json = CreatePaymentDestinationRequest(
        label: 'Main bank',
        accountIdentifier: 'DE89370400440532013000',
        dailyCap: Money.fromDecimalString('250000.00'),
        priority: 2,
      ).toJson();

      expect(json['dailyCap'], '250000.00');
      expect(json['priority'], 2);
    });

    test('update never carries the immutable fields', () {
      final Map<String, Object?> json = const UpdatePaymentDestinationRequest(
        label: 'Renamed',
        accountHolder: '',
      ).toJson();

      expect(json.containsKey('accountIdentifier'), isFalse);
      expect(json.containsKey('paymentMethodId'), isFalse);
      expect(json, <String, Object?>{'label': 'Renamed', 'accountHolder': ''});
    });

    test('the activation shorthand sends exactly one key', () {
      const UpdatePaymentDestinationRequest request =
          UpdatePaymentDestinationRequest.activation(isActive: false);

      expect(request.toJson(), <String, Object?>{'isActive': false});
    });
  });
}
