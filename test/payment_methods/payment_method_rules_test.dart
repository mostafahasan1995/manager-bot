import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';

/// Every validator now takes a catalogue. English is used for the assertions
/// that compare wording; the RULES themselves must not depend on the locale,
/// which is what the Arabic spot-checks below pin down.
const AppStrings en = AppStrings.en;
const AppStrings ar = AppStrings.ar;

void main() {
  group('PaymentMethodRoles', () {
    test('every reader role the backend accepts, and no others', () {
      expect(PaymentMethodRoles.canView(AdminRole.superAdmin), isTrue);
      expect(PaymentMethodRoles.canView(AdminRole.financeAdmin), isTrue);
      expect(PaymentMethodRoles.canView(AdminRole.reviewer), isTrue);
      expect(PaymentMethodRoles.canView(AdminRole.support), isTrue);
      // VIEWER is in NEITHER backend tuple and gets a 403 even on the GETs.
      expect(PaymentMethodRoles.canView(AdminRole.viewer), isFalse);
      expect(PaymentMethodRoles.canView(null), isFalse);
    });

    test('only finance-grade roles may write', () {
      expect(PaymentMethodRoles.canManage(AdminRole.superAdmin), isTrue);
      expect(PaymentMethodRoles.canManage(AdminRole.financeAdmin), isTrue);
      expect(PaymentMethodRoles.canManage(AdminRole.reviewer), isFalse);
      expect(PaymentMethodRoles.canManage(AdminRole.support), isFalse);
      expect(PaymentMethodRoles.canManage(AdminRole.viewer), isFalse);
      expect(PaymentMethodRoles.canManage(null), isFalse);
    });

    test('a manager can always read', () {
      for (final AdminRole role in PaymentMethodRoles.managers) {
        expect(PaymentMethodRoles.canView(role), isTrue);
      }
    });

    test('agrees with the core capability map on writes', () {
      for (final AdminRole role in AdminRoles.all) {
        expect(
          PaymentMethodRoles.canManage(role),
          AdminRoles.can(role, AdminCapability.managePaymentDestinations),
          reason: 'write gate disagrees for ${role.wireName}',
        );
      }
    });
  });

  group('validateAmounts', () {
    Money nsp(String amount) => Money.fromDecimalString(amount);

    test('accepts a coherent configuration', () {
      expect(
        PaymentMethodRules.validateAmounts(
          minAmount: nsp('50.00'),
          maxAmount: nsp('5000.00'),
          feeFixed: nsp('1.00'),
          strings: en,
        ),
        isEmpty,
      );
    });

    test('rejects a non-positive minimum before anything else', () {
      final List<FieldIssue> issues = PaymentMethodRules.validateAmounts(
        minAmount: nsp('0.00'),
        maxAmount: nsp('5000.00'),
        feeFixed: nsp('0.00'),
        strings: en,
      );

      expect(issues.length, 1);
      expect(issues.single.field, 'minAmount');
    });

    test('rejects a maximum below the minimum', () {
      final List<FieldIssue> issues = PaymentMethodRules.validateAmounts(
        minAmount: nsp('500.00'),
        maxAmount: nsp('100.00'),
        feeFixed: nsp('0.00'),
        strings: en,
      );

      expect(issues.map((FieldIssue i) => i.field), contains('maxAmount'));
    });

    test('rejects a fee that would eat the smallest deposit', () {
      // feeFixed must be STRICTLY below minAmount.
      final List<FieldIssue> equal = PaymentMethodRules.validateAmounts(
        minAmount: nsp('50.00'),
        maxAmount: nsp('5000.00'),
        feeFixed: nsp('50.00'),
        strings: en,
      );
      final List<FieldIssue> above = PaymentMethodRules.validateAmounts(
        minAmount: nsp('50.00'),
        maxAmount: nsp('5000.00'),
        feeFixed: nsp('50.01'),
        strings: en,
      );

      expect(equal.single.field, 'feeFixed');
      expect(above.single.field, 'feeFixed');
    });

    test('rejects a negative fee', () {
      final List<FieldIssue> issues = PaymentMethodRules.validateAmounts(
        minAmount: nsp('50.00'),
        maxAmount: nsp('5000.00'),
        feeFixed: nsp('-1.00'),
        strings: en,
      );

      expect(issues.single.field, 'feeFixed');
    });

    test('a max equal to the min is fine', () {
      expect(
        PaymentMethodRules.validateAmounts(
          minAmount: nsp('50.00'),
          maxAmount: nsp('50.00'),
          feeFixed: nsp('0.00'),
          strings: en,
        ),
        isEmpty,
      );
    });

    test('refuses to compare across currencies', () {
      final List<FieldIssue> issues = PaymentMethodRules.validateAmounts(
        minAmount: nsp('50.00'),
        maxAmount: Money.fromDecimalString('5000.00', currency: 'EUR'),
        feeFixed: nsp('0.00'),
        strings: en,
      );

      expect(issues.single.field, 'currencyCode');
    });
  });

  group('field validators', () {
    test('code must be SCREAMING_SNAKE_CASE', () {
      expect(PaymentMethodRules.validateCode('BANK_TRANSFER_MAIN', en), isNull);
      expect(PaymentMethodRules.validateCode('  bank_transfer  ', en), isNull);
      expect(PaymentMethodRules.validateCode('B', en), isNotNull);
      expect(PaymentMethodRules.validateCode('9BANK', en), isNotNull);
      expect(PaymentMethodRules.validateCode('BANK-TRANSFER', en), isNotNull);
      expect(PaymentMethodRules.validateCode('', en), isNotNull);
      // The RULE does not move with the language, only the wording does.
      expect(PaymentMethodRules.validateCode('BANK-TRANSFER', ar), isNotNull);
      expect(
        PaymentMethodRules.validateCode('BANK-TRANSFER', ar)?.message,
        isNot(PaymentMethodRules.validateCode('BANK-TRANSFER', en)?.message),
      );
    });

    test('code is normalised the way the server normalises it', () {
      expect(PaymentMethodRules.normalizeCode(' bank_main '), 'BANK_MAIN');
    });

    test('currency must be three letters', () {
      expect(PaymentMethodRules.validateCurrency('nsp', en), isNull);
      expect(PaymentMethodRules.validateCurrency('NSPX', en), isNotNull);
      expect(PaymentMethodRules.validateCurrency('N5P', en), isNotNull);
    });

    test('feeBps is bounded at 100%', () {
      expect(PaymentMethodRules.validateFeeBps(0, en), isNull);
      expect(PaymentMethodRules.validateFeeBps(10000, en), isNull);
      expect(PaymentMethodRules.validateFeeBps(10001, en), isNotNull);
      expect(PaymentMethodRules.validateFeeBps(-1, en), isNotNull);
      expect(PaymentMethodRules.validateFeeBps(null, en), isNull);
    });

    test('priority cannot be negative', () {
      expect(PaymentMethodRules.validatePriority(0, en), isNull);
      expect(PaymentMethodRules.validatePriority(16, en), isNull);
      expect(PaymentMethodRules.validatePriority(-1, en), isNotNull);
    });

    test('money input rejects a third decimal, exactly like the server', () {
      expect(
        PaymentMethodRules.validateMoneyInput('1500.00', en, required: true),
        isNull,
      );
      expect(
        PaymentMethodRules.validateMoneyInput('1500.123', en, required: true),
        PaymentMethodRules.messageForMoneyReason('MONEY_TOO_MANY_DECIMALS', en),
      );
      expect(
        PaymentMethodRules.validateMoneyInput('', en, required: true),
        isNotNull,
      );
      // Optional fields accept blank: it means "omit the key".
      expect(
        PaymentMethodRules.validateMoneyInput('  ', en, required: false),
        isNull,
      );
      // Arabic rejects and accepts exactly the same inputs.
      expect(
        PaymentMethodRules.validateMoneyInput('1500.00', ar, required: true),
        isNull,
      );
      expect(
        PaymentMethodRules.validateMoneyInput('1500.123', ar, required: true),
        isNotNull,
      );
    });

    test('integer input is bounded on both sides', () {
      expect(
        PaymentMethodRules.validateIntegerInput('5', en, required: true),
        isNull,
      );
      expect(
        PaymentMethodRules.validateIntegerInput(
          '-3',
          en,
          required: true,
          min: 0,
        ),
        isNotNull,
      );
      expect(
        PaymentMethodRules.validateIntegerInput('x', en, required: true),
        isNotNull,
      );
      expect(
        PaymentMethodRules.validateIntegerInput('', en, required: false),
        isNull,
      );
    });

    test('a wire field name resolves to a catalogue label in both bundles', () {
      expect(
        PaymentMethodRules.labelForField('minAmount', en),
        en.pmMinAmountLabel,
      );
      expect(
        PaymentMethodRules.labelForField('minAmount', ar),
        ar.pmMinAmountLabel,
      );
      // An unknown field falls back to the RAW WIRE NAME, never to prose.
      expect(
        PaymentMethodRules.labelForField('brandNewField', ar),
        'brandNewField',
      );
    });
  });

  group('reference patterns', () {
    test('a compilable pattern raises no warning', () {
      expect(
        PaymentMethodRules.referencePatternWarning(r'^[A-Za-z0-9-]{6,32}$', en),
        isNull,
      );
      expect(PaymentMethodRules.referencePatternWarning('  ', en), isNull);
    });

    test('an uncompilable pattern is reported, since the server never will',
        () {
      expect(
        PaymentMethodRules.referencePatternWarning('^[unclosed', en),
        isNotNull,
      );
      expect(
        PaymentMethodRules.referencePatternWarning('^[unclosed', ar),
        isNotNull,
      );
    });

    test('probing a reference mirrors the driver', () {
      const String pattern = r'^[A-Za-z0-9-]{6,32}$';

      expect(
        PaymentMethodRules.matchesReferencePattern(pattern, 'ABC-123456'),
        isTrue,
      );
      expect(
        PaymentMethodRules.matchesReferencePattern(pattern, 'short'),
        isFalse,
      );
      // The 128-character ReDoS guard runs BEFORE the operator regex.
      expect(
        PaymentMethodRules.matchesReferencePattern(pattern, 'A' * 129),
        isFalse,
      );
      // A blank or broken pattern means "no pattern" server-side.
      expect(PaymentMethodRules.matchesReferencePattern('', 'anything'), isNull);
      expect(
        PaymentMethodRules.matchesReferencePattern('^[unclosed', 'anything'),
        isNull,
      );
    });
  });

  group('rail metadata', () {
    test('declared proof fields match the drivers, in order', () {
      expect(
        PaymentRail.bankTransfer.declaredProofFields,
        <RailProofField>[
          RailProofField.reference,
          RailProofField.senderAccount,
          RailProofField.senderName,
          RailProofField.receiptImage,
        ],
      );
      expect(
        PaymentRail.crypto.declaredProofFields,
        <RailProofField>[
          RailProofField.txHash,
          RailProofField.network,
          RailProofField.senderAccount,
          RailProofField.receiptImage,
        ],
      );
      expect(PaymentRail.internal.declaredProofFields, isEmpty);
    });

    test('only INTERNAL has no driver, and it is never creatable', () {
      expect(PaymentRail.internal.hasDriver, isFalse);
      expect(PaymentRail.creatable.contains(PaymentRail.internal), isFalse);
      expect(PaymentRail.creatable.length, 4);
    });

    test('only three proof fields are machine enforced', () {
      expect(RailProofField.isMachineEnforced('REFERENCE'), isTrue);
      expect(RailProofField.isMachineEnforced('SENDER_ACCOUNT'), isTrue);
      expect(RailProofField.isMachineEnforced('RECEIPT_IMAGE'), isTrue);
      expect(RailProofField.isMachineEnforced('SENDER_NAME'), isFalse);
      expect(RailProofField.isMachineEnforced('TX_HASH'), isFalse);
      expect(RailProofField.isMachineEnforced('NETWORK'), isFalse);
      // An unknown field is reported as unchecked, the safe direction.
      expect(RailProofField.isMachineEnforced('FUTURE_FIELD'), isFalse);
    });

    test('the crypto label is the chain name', () {
      // On CRYPTO the destination caption IS the network, in both bundles.
      expect(PaymentRail.crypto.destinationLabelCaption(en), en.networkLabel);
      expect(PaymentRail.crypto.destinationLabelCaption(ar), ar.networkLabel);
      expect(PaymentRail.crypto.ignoresAccountHolder, isTrue);
      expect(PaymentRail.bankTransfer.ignoresAccountHolder, isFalse);
    });

    test('every rail and mode label resolves in both bundles', () {
      for (final PaymentRail rail in PaymentRail.values) {
        expect(rail.label(en), isNotEmpty);
        expect(rail.label(ar), isNotEmpty);
        expect(rail.destinationLabelHint(ar), isNotEmpty);
        expect(rail.accountIdentifierCaption(ar), isNotEmpty);
      }
      for (final VerificationMode mode in VerificationMode.values) {
        expect(mode.label(en), isNotEmpty);
        expect(mode.label(ar), isNotEmpty);
      }
    });

    test('a proof field this build does not know keeps its wire code', () {
      expect(RailProofField.labelFor('REFERENCE', en), en.referenceLabel);
      expect(RailProofField.labelFor('REFERENCE', ar), ar.referenceLabel);
      expect(RailProofField.labelFor('FUTURE_FIELD', ar), 'FUTURE_FIELD');
    });

    test('wire parsing is case-insensitive on input, exact on output', () {
      expect(PaymentRail.tryParse('bank_transfer'), PaymentRail.bankTransfer);
      expect(PaymentRail.tryParse('NOT_A_RAIL'), isNull);
      expect(PaymentRail.bankTransfer.wireName, 'BANK_TRANSFER');
      expect(
        VerificationMode.tryParse('manual_proof'),
        VerificationMode.manualProof,
      );
    });
  });
}
