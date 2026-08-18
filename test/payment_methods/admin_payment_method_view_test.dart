import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';

/// A realistic `GET /v1/admin/payment-methods` row: money as BARE DECIMAL
/// STRINGS in MAJOR units, ids as UUID strings, `feeBps`/`sortOrder` as plain
/// JSON integers.
Map<String, Object?> bankTransferJson() => <String, Object?>{
      'id': '0f2f1f0e-9b1a-4a5d-9c2f-2a4d6e8f0a11',
      'code': 'BANK_TRANSFER_MAIN',
      'displayName': 'Bank transfer',
      'rail': 'BANK_TRANSFER',
      'currencyCode': 'NSP',
      'verificationMode': 'MANUAL_PROOF',
      'minAmount': '5000.00',
      'maxAmount': '5000000.00',
      'feeFixed': '0.00',
      'feeBps': 0,
      'requiresReference': true,
      'instructions': 'Transfer the exact amount to the account shown.',
      'requiredProofFields': <String>[
        'REFERENCE',
        'SENDER_ACCOUNT',
        'SENDER_NAME',
        'RECEIPT_IMAGE',
      ],
      'isActive': true,
      'sortOrder': 10,
      'referencePattern': r'^[A-Za-z0-9-]{6,32}$',
      'createdAt': '2026-08-14T09:12:33.482Z',
      'updatedAt': '2026-08-16T10:04:11.512Z',
    };

void main() {
  group('AdminPaymentMethodView.fromJson', () {
    test('parses money as exact minor units, never through a double', () {
      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(bankTransferJson());

      expect(method.minAmount.minor, BigInt.parse('500000'));
      expect(method.maxAmount.minor, BigInt.parse('500000000'));
      expect(method.feeFixed.minor, BigInt.zero);
      expect(method.minAmount.currency, 'NSP');
      // Round trip back to the exact wire representation.
      expect(method.minAmount.toDecimalString(), '5000.00');
      expect(method.maxAmount.toDecimalString(), '5000000.00');
      expect(method.feeFixed.toDecimalString(), '0.00');
    });

    test('parses identity, enums and timestamps', () {
      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(bankTransferJson());

      expect(method.id, '0f2f1f0e-9b1a-4a5d-9c2f-2a4d6e8f0a11');
      expect(method.code, 'BANK_TRANSFER_MAIN');
      expect(method.rail, PaymentRail.bankTransfer);
      expect(method.verificationMode, VerificationMode.manualProof);
      expect(method.feeBps, 0);
      expect(method.sortOrder, 10);
      expect(method.isActive, isTrue);
      expect(method.createdAt.toUtc().toIso8601String(),
          '2026-08-14T09:12:33.482Z');
    });

    test('keeps requiredProofFields in driver order', () {
      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(bankTransferJson());

      expect(method.requiredProofFields, <String>[
        'REFERENCE',
        'SENDER_ACCOUNT',
        'SENDER_NAME',
        'RECEIPT_IMAGE',
      ]);
      expect(method.proofFields.first, RailProofField.reference);
      expect(method.railHasNoDriver, isFalse);
    });

    test('an unknown rail degrades to INTERNAL rather than throwing', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['rail'] = 'SOME_FUTURE_RAIL'
        ..['requiredProofFields'] = <String>[];

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.rail, PaymentRail.internal);
      expect(method.railHasNoDriver, isTrue);
      expect(method.tone, StatusTone.failed);
    });

    test('nullable text fields survive being absent', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['instructions'] = null
        ..remove('referencePattern');

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.instructions, isNull);
      expect(method.referencePattern, isNull);
      expect(method.hasReferencePattern, isFalse);
    });

    test('an inactive method reads as neutral, not failed', () {
      final Map<String, Object?> json = bankTransferJson()..['isActive'] = false;

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.isActive, isFalse);
      // The METHOD pair, not the destination's and not the administrator's.
      expect(method.statusLabel(AppStrings.en), AppStrings.en.pmStatusDisabled);
      expect(method.statusLabel(AppStrings.ar), AppStrings.ar.pmStatusDisabled);
      expect(method.tone, StatusTone.neutral);
    });
  });

  group('reference rules', () {
    test('a rail that declares REFERENCE makes the toggle moot', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['requiresReference'] = false;

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.requiresReference, isFalse);
      expect(method.railDemandsReference, isTrue);
      // Turning the flag off does NOT make the reference optional.
      expect(method.referenceIsMandatory, isTrue);
      expect(method.requiresReferenceToggleIsMoot, isTrue);
    });

    test('on CRYPTO the toggle is the only source of the requirement', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['rail'] = 'CRYPTO'
        ..['requiresReference'] = false
        ..['requiredProofFields'] = <String>[
          'TX_HASH',
          'NETWORK',
          'SENDER_ACCOUNT',
          'RECEIPT_IMAGE',
        ];

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.railDemandsReference, isFalse);
      expect(method.referenceIsMandatory, isFalse);
      expect(method.requiresReferenceToggleIsMoot, isFalse);
    });

    test('flags the proof fields nothing on the server can check', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['requiredProofFields'] = <String>[
          'TX_HASH',
          'NETWORK',
          'SENDER_ACCOUNT',
          'RECEIPT_IMAGE',
        ];

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.unenforceableProofFields, <String>['TX_HASH', 'NETWORK']);
    });

    test('reports an uncompilable reference pattern', () {
      final Map<String, Object?> valid = bankTransferJson();
      final Map<String, Object?> broken = bankTransferJson()
        ..['referencePattern'] = '^[unclosed';

      expect(
        AdminPaymentMethodView.fromJson(valid).referencePatternCompileError,
        isNull,
      );
      expect(
        AdminPaymentMethodView.fromJson(broken).referencePatternCompileError,
        isNotNull,
      );
    });
  });

  group('fee arithmetic', () {
    Money nsp(String amount) => Money.fromDecimalString(amount);

    test('fixed plus proportional, all in BigInt', () {
      final Money fee = AdminPaymentMethodView.computeFee(
        amount: nsp('1000.00'),
        feeFixed: nsp('5.00'),
        feeBps: 250, // 2.5%
      );

      expect(fee.toDecimalString(), '30.00');
    });

    test('rounds half UP on the minor unit', () {
      // 1.01 * 0.5% = 0.00505 -> 0.01 minor units after HALF_UP.
      expect(
        AdminPaymentMethodView.computeFee(
          amount: nsp('1.01'),
          feeFixed: nsp('0.00'),
          feeBps: 50,
        ).minor,
        BigInt.one,
      );
      // Exactly one half rounds up.
      expect(
        AdminPaymentMethodView.computeFee(
          amount: nsp('1.00'),
          feeFixed: nsp('0.00'),
          feeBps: 50,
        ).minor,
        BigInt.one,
      );
      // Just below one half rounds down.
      expect(
        AdminPaymentMethodView.computeFee(
          amount: nsp('0.99'),
          feeFixed: nsp('0.00'),
          feeBps: 50,
        ).minor,
        BigInt.zero,
      );
    });

    test('a zero fee leaves the deposit untouched', () {
      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(bankTransferJson());

      expect(method.feeFor(method.minAmount).isZero, isTrue);
      expect(method.creditedAtMinimum, method.minAmount);
    });

    test('a fee at or above the minimum credits nothing', () {
      final Map<String, Object?> json = bankTransferJson()
        ..['feeFixed'] = '5000.00';

      final AdminPaymentMethodView method =
          AdminPaymentMethodView.fromJson(json);

      expect(method.creditedAtMinimum.isPositive, isFalse);
    });
  });
}
