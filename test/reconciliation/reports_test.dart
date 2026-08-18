import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/data/float_sync_result.dart';
import 'package:manager_bot/features/reconciliation/data/ledger_invariant_report.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';

void main() {
  group('FloatSyncResult.fromJson', () {
    test('parses a drifting comparison with an exact signed delta', () {
      final FloatSyncResult result = FloatSyncResult.fromJson(<String, Object?>{
        'currencyCode': 'NSP',
        'ledgerMinor': '150000',
        'ichancyMinor': '162550',
        'deltaMinor': '12550',
        'breakId': '2f3d5a1c-0000-4000-8000-000000000001',
        'belowWatermark': false,
      });

      expect(result.ledger.minor, BigInt.from(150000));
      expect(result.ichancy?.minor, BigInt.from(162550));
      expect(result.delta?.minor, BigInt.from(12550));
      expect(result.delta?.currency, 'NSP');
      expect(result.hasDrift, isTrue);
      expect(result.inTolerance, isFalse);
      expect(result.ichancyHoldsMore, isTrue);
      expect(result.walletUnavailable, isFalse);
    });

    test('an unreachable wallet is a success with nulls, not an error', () {
      final FloatSyncResult result = FloatSyncResult.fromJson(<String, Object?>{
        'currencyCode': 'NSP',
        'ledgerMinor': '150000',
        'ichancyMinor': null,
        'deltaMinor': null,
        'breakId': null,
        'belowWatermark': true,
      });

      expect(result.walletUnavailable, isTrue);
      expect(result.delta, isNull);
      expect(result.hasDrift, isFalse);
      expect(result.inTolerance, isFalse);
      expect(result.breakId, isNull);
      // The watermark was computed against OUR ledger in this branch.
      expect(result.watermarkSubject.minor, BigInt.from(150000));
    });

    test('a zero delta is in tolerance and opens no break', () {
      final FloatSyncResult result = FloatSyncResult.fromJson(<String, Object?>{
        'currencyCode': 'NSP',
        'ledgerMinor': '0',
        'ichancyMinor': '0',
        'deltaMinor': '0',
        'breakId': null,
        'belowWatermark': false,
      });

      expect(result.inTolerance, isTrue);
      expect(result.hasDrift, isFalse);
      expect(result.breakId, isNull);
    });

    test('keeps a negative 64-bit delta exact', () {
      final FloatSyncResult result = FloatSyncResult.fromJson(<String, Object?>{
        'currencyCode': 'NSP',
        'ledgerMinor': '9007199254740993',
        'ichancyMinor': '0',
        'deltaMinor': '-9007199254740993',
        'breakId': null,
        'belowWatermark': true,
      });

      expect(result.delta?.minor, BigInt.parse('-9007199254740993'));
      expect(result.ichancyHoldsMore, isFalse);
    });
  });

  group('CorrectFloatReceipt.fromJson', () {
    test('takes its currency from the break, since the body carries none', () {
      final CorrectFloatReceipt receipt =
          CorrectFloatReceipt.fromJson(<String, Object?>{
        'ledgerTransactionId': '2f3d5a1c-0000-4000-8000-0000000000ff',
        'deltaMinor': '-12550',
      });

      expect(receipt.ledgerTransactionId,
          '2f3d5a1c-0000-4000-8000-0000000000ff');
      expect(receipt.delta.minor, BigInt.from(-12550));
      expect(receipt.delta.currency, 'NSP');
    });
  });

  group('RailAgeingReport.fromJson', () {
    Map<String, Object?> bucket(
      String label,
      int fromDays,
      Object? toDays,
      String net,
      int count,
    ) {
      return <String, Object?>{
        'label': label,
        'fromDays': fromDays,
        'toDays': toDays,
        'debitMinor': net.startsWith('-') ? '0' : net,
        'creditMinor': net.startsWith('-') ? net.substring(1) : '0',
        'netMinor': net,
        'entryCount': count,
      };
    }

    Map<String, Object?> report() {
      return <String, Object?>{
        'generatedAt': '2026-08-16T10:04:11.512Z',
        'rows': <Object?>[
          <String, Object?>{
            'accountId': '2f3d5a1c-0000-4000-8000-00000000a001',
            'accountCode': 'RAIL_CLEARING:BANK',
            'currencyCode': 'NSP',
            'paymentMethodId': null,
            'balanceMinor': '250000',
            'oldestUnsettledAt': '2026-07-01T00:00:00Z',
            'buckets': <Object?>[
              bucket('0-1d', 0, 1, '50000', 3),
              bucket('30d+', 30, null, '200000', 7),
            ],
          },
          <String, Object?>{
            'accountId': '2f3d5a1c-0000-4000-8000-00000000a002',
            'accountCode': 'RAIL_CLEARING:WALLET',
            'currencyCode': 'NSP',
            'paymentMethodId': '2f3d5a1c-0000-4000-8000-00000000b001',
            'balanceMinor': '-1200',
            'oldestUnsettledAt': null,
            'buckets': <Object?>[bucket('1-3d', 1, 3, '-1200', 1)],
          },
        ],
        'staleAccountCodes': <Object?>['RAIL_CLEARING:BANK'],
      };
    }

    test('parses sparse buckets without indexing by position', () {
      final RailAgeingReport parsed = RailAgeingReport.fromJson(report());
      final RailAgeingRow bank = parsed.rows.first;

      expect(parsed.rows, hasLength(2));
      expect(bank.buckets, hasLength(2));
      expect(bank.buckets.first.label, '0-1d');
      expect(bank.openEndedBucket?.label, '30d+');
      expect(bank.openEndedBucket?.toDays, isNull);
      expect(bank.openEndedBucket?.net.minor, BigInt.from(200000));
      expect(bank.entryCount, 10);
    });

    test('bucket chips are localised while the wire label is untouched', () {
      final RailAgeingReport parsed = RailAgeingReport.fromJson(report());
      final RailAgeingBucket first = parsed.rows.first.buckets.first;

      expect(first.label, '0-1d');
      expect(first.displayLabel(AppStrings.en), AppStrings.en.bucket0to1d);
      expect(first.displayLabel(AppStrings.ar), AppStrings.ar.bucket0to1d);

      // A label this build has never seen degrades to the raw wire value.
      final RailAgeingBucket future = RailAgeingBucket.fromJson(
        <String, Object?>{
          'label': '90d+',
          'fromDays': 90,
          'toDays': null,
          'debitMinor': '0',
          'creditMinor': '0',
          'netMinor': '0',
          'entryCount': 0,
        },
      );
      expect(future.displayLabel(AppStrings.ar), '90d+');
    });

    test('keeps a negative balance negative', () {
      final RailAgeingReport parsed = RailAgeingReport.fromJson(report());
      final RailAgeingRow wallet = parsed.rows[1];

      expect(wallet.balance.minor, BigInt.from(-1200));
      expect(wallet.balance.isNegative, isTrue);
      expect(wallet.openEndedBucket, isNull);
      expect(wallet.oldestUnsettledAt, isNull);
      expect(wallet.ageOfOldest(), isNull);
    });

    test('marks stale accounts and puts them first', () {
      final RailAgeingReport parsed = RailAgeingReport.fromJson(report());

      expect(parsed.hasStaleAccounts, isTrue);
      expect(parsed.isStale('RAIL_CLEARING:BANK'), isTrue);
      expect(parsed.isStale('RAIL_CLEARING:WALLET'), isFalse);
      expect(
        parsed.rowsWorstFirst.first.accountCode,
        'RAIL_CLEARING:BANK',
      );
    });

    test('an empty ledger yields two empty lists, never null', () {
      final RailAgeingReport parsed =
          RailAgeingReport.fromJson(<String, Object?>{
        'generatedAt': '2026-08-16T10:04:11.512Z',
        'rows': <Object?>[],
        'staleAccountCodes': <Object?>[],
      });

      expect(parsed.isEmpty, isTrue);
      expect(parsed.staleAccountCodes, isEmpty);
      expect(parsed.hasStaleAccounts, isFalse);
    });
  });

  group('LedgerInvariantReport.fromJson', () {
    Map<String, Object?> violation(
      String invariant,
      String expected,
      String actual,
      String delta,
    ) {
      return <String, Object?>{
        'invariant': invariant,
        'subject': '2f3d5a1c-0000-4000-8000-00000000c001',
        'currencyCode': 'NSP',
        'expectedMinor': expected,
        'actualMinor': actual,
        'deltaMinor': delta,
        'detail': 'Account HOUSE_ROUNDING:NSP caches 100 but its entries sum to 0',
      };
    }

    test('a healthy ledger parses as ok with no violations', () {
      final LedgerInvariantReport parsed =
          LedgerInvariantReport.fromJson(<String, Object?>{
        'ok': true,
        'checkedAt': '2026-08-16T10:04:11.512Z',
        'violations': <Object?>[],
        'truncated': false,
      });

      expect(parsed.isHealthy, isTrue);
      expect(parsed.violations, isEmpty);
      expect(parsed.truncated, isFalse);
      expect(parsed.countsByInvariant, isEmpty);
    });

    test('I3 values are money', () {
      final LedgerInvariantReport parsed =
          LedgerInvariantReport.fromJson(<String, Object?>{
        'ok': false,
        'checkedAt': '2026-08-16T10:04:11.512Z',
        'violations': <Object?>[
          violation('I3_ACCOUNT_BALANCE_MATCHES_ENTRIES', '100', '0', '-100'),
        ],
        'truncated': false,
      });
      final LedgerInvariantViolation first = parsed.violations.first;

      expect(first.invariant, LedgerInvariant.accountBalanceMatchesEntries);
      expect(first.valuesAreEntryCounts, isFalse);
      expect(first.expected?.minor, BigInt.from(100));
      expect(first.delta?.toDecimalString(), '-1.00');
      // Money is formatted by Money itself - Western digits in both bundles.
      expect(first.deltaLabel(AppStrings.en), contains('-1.00'));
      expect(first.deltaLabel(AppStrings.ar), contains('-1.00'));
      expect(first.invariant.subjectKind(AppStrings.en), 'Account');
      expect(
        first.invariant.subjectKind(AppStrings.ar),
        AppStrings.ar.subjectKindAccount,
      );
    });

    test('I1_SINGLE_SIDED values are ENTRY COUNTS, not money', () {
      final LedgerInvariantReport parsed =
          LedgerInvariantReport.fromJson(<String, Object?>{
        'ok': false,
        'checkedAt': '2026-08-16T10:04:11.512Z',
        'violations': <Object?>[violation('I1_SINGLE_SIDED', '2', '1', '-1')],
        'truncated': true,
      });
      final LedgerInvariantViolation first = parsed.violations.first;

      expect(first.valuesAreEntryCounts, isTrue);
      expect(first.expected, isNull);
      expect(first.actual, isNull);
      expect(first.delta, isNull);
      expect(first.expectedRaw, BigInt.two);
      expect(first.expectedLabel(AppStrings.en), '2 entries');
      expect(first.actualLabel(AppStrings.en), '1 entry');
      expect(first.deltaLabel(AppStrings.en), '-1 entries');
      expect(first.invariant.subjectKind(AppStrings.en), 'Transaction');
      expect(parsed.truncated, isTrue);
    });

    test('unknown invariants degrade instead of crashing', () {
      final LedgerInvariantReport parsed =
          LedgerInvariantReport.fromJson(<String, Object?>{
        'ok': false,
        'checkedAt': '2026-08-16T10:04:11.512Z',
        'violations': <Object?>[violation('I9_FROM_THE_FUTURE', '1', '2', '1')],
        'truncated': false,
      });
      final LedgerInvariantViolation first = parsed.violations.first;

      expect(first.invariant, LedgerInvariant.unknown);
      expect(first.invariantWire, 'I9_FROM_THE_FUTURE');
      expect(first.valuesAreEntryCounts, isFalse);
    });

    test('orders the broken books ahead of a drifted cache', () {
      final LedgerInvariantReport parsed =
          LedgerInvariantReport.fromJson(<String, Object?>{
        'ok': false,
        'checkedAt': '2026-08-16T10:04:11.512Z',
        'violations': <Object?>[
          violation('I3_ACCOUNT_BALANCE_MATCHES_ENTRIES', '100', '0', '-100'),
          violation('I2_GLOBAL_ZERO_SUM', '0', '500', '500'),
        ],
        'truncated': false,
      });

      expect(
        parsed.violationsWorstFirst.first.invariant,
        LedgerInvariant.globalZeroSum,
      );
      expect(
        parsed.countsByInvariant[LedgerInvariant.globalZeroSum],
        1,
      );
    });
  });
}
