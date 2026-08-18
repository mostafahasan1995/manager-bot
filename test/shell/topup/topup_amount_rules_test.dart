import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/topup/application/topup_amount_rules.dart';

void main() {
  final Money min = Money.fromMinorString('500000'); // 5,000.00 NSP
  final Money max = Money.fromMinorString('150000000'); // 1,500,000.00 NSP

  group('TopUpAmountRules.validate', () {
    test('blank input is empty, not malformed', () {
      expect(
        TopUpAmountRules.validate('', minimum: min, maximum: max),
        TopUpAmountIssue.empty,
      );
      expect(
        TopUpAmountRules.validate('   ', minimum: min, maximum: max),
        TopUpAmountIssue.empty,
      );
    });

    test('letters and stray punctuation are malformed', () {
      expect(
        TopUpAmountRules.validate('abc', minimum: min, maximum: max),
        TopUpAmountIssue.malformed,
      );
      expect(
        TopUpAmountRules.validate('1.', minimum: min, maximum: max),
        TopUpAmountIssue.malformed,
      );
    });

    test('a third decimal is rejected, not rounded away', () {
      expect(
        TopUpAmountRules.validate('10000.123', minimum: min, maximum: max),
        TopUpAmountIssue.tooManyDecimals,
      );
    });

    test('zero and negatives are not positive', () {
      expect(
        TopUpAmountRules.validate('0', minimum: min, maximum: max),
        TopUpAmountIssue.notPositive,
      );
      expect(
        TopUpAmountRules.validate('-10000', minimum: min, maximum: max),
        TopUpAmountIssue.notPositive,
      );
    });

    test('the window is inclusive at both ends', () {
      expect(
        TopUpAmountRules.validate('5000', minimum: min, maximum: max),
        isNull,
      );
      expect(
        TopUpAmountRules.validate('1500000', minimum: min, maximum: max),
        isNull,
      );
      expect(
        TopUpAmountRules.validate('4999.99', minimum: min, maximum: max),
        TopUpAmountIssue.belowMinimum,
      );
      expect(
        TopUpAmountRules.validate('1500000.01', minimum: min, maximum: max),
        TopUpAmountIssue.aboveMaximum,
      );
    });

    test('grouped input a player actually types is accepted exactly', () {
      expect(
        TopUpAmountRules.validate('50,000', minimum: min, maximum: max),
        isNull,
      );
      expect(
        Money.parseUserInput('50,000').toMinorString(),
        '5000000',
      );
      expect(
        Money.parseUserInput('50 000.25').toMinorString(),
        '5000025',
      );
    });

    test('range checks are skipped while the catalogue is unknown', () {
      // Amount step still gives live feedback before the methods arrive.
      expect(TopUpAmountRules.validate('1'), isNull);
      expect(TopUpAmountRules.validate('0'), TopUpAmountIssue.notPositive);
    });

    test('isUsable mirrors validate', () {
      expect(TopUpAmountRules.isUsable('25000', minimum: min, maximum: max),
          isTrue);
      expect(TopUpAmountRules.isUsable('1', minimum: min, maximum: max),
          isFalse);
    });
  });
}
