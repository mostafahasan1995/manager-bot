import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_query.dart';

const String _uuidV4 = 'aa11bb22-cc33-4d44-8e55-ff6677889900';
const String _uuidV7 = 'aa11bb22-cc33-7d44-8e55-ff6677889900';

/// Validation messages come from the catalogue now; the English bundle keeps
/// the expectations readable.
const AppStrings _en = AppStrings.en;

void main() {
  group('DepositSort', () {
    test('only the createdAt sorts can be keyset-paged', () {
      expect(DepositSort.newest.isPageable, isTrue);
      expect(DepositSort.oldest.isPageable, isTrue);
      // The server's cursor carries only (createdAt, id), so echoing it back on
      // an amount sort returns the same first page forever.
      expect(DepositSort.amountDesc.isPageable, isFalse);
      expect(DepositSort.amountAsc.isPageable, isFalse);
    });

    test('wire names match the DTO whitelist exactly', () {
      expect(
        DepositSort.values.map((DepositSort s) => s.wireName).toList(),
        <String>['newest', 'oldest', 'amount_desc', 'amount_asc'],
      );
      expect(DepositSort.tryParse('amount_desc'), DepositSort.amountDesc);
      expect(DepositSort.tryParse('AMOUNT_ASC'), DepositSort.amountAsc);
      expect(DepositSort.tryParse('sideways'), isNull);
    });
  });

  group('DepositQueueFilter.toQuery', () {
    test('the untouched filter sends only the sort', () {
      expect(
        DepositQueueFilter.initial.toQuery(),
        <String, Object?>{'sort': 'newest'},
      );
      expect(DepositQueueFilter.initial.isActive, isFalse);
      expect(DepositQueueFilter.initial.activeCount, 0);
    });

    test('statuses go out comma separated', () {
      const DepositQueueFilter filter = DepositQueueFilter(
        statuses: <DepositStatus>{
          DepositStatus.submitted,
          DepositStatus.underReview,
        },
      );

      final Object? status = filter.toQuery()['status'];
      expect(status, isA<String>());
      expect(
        (status! as String).split(',').toSet(),
        <String>{'SUBMITTED', 'UNDER_REVIEW'},
      );
    });

    test('amounts are always emitted with exactly 2 decimals', () {
      // The queue controller parses these DIRECTLY with parseDecimalToMinor,
      // so more than 2 decimals escapes as a plain Error and 500s.
      final DepositQueueFilter filter = DepositQueueFilter(
        minAmount: Money.fromDecimalString('1500'),
        maxAmount: Money.fromDecimalString('2000.5'),
      );

      expect(filter.toQuery()['minAmount'], '1500.00');
      expect(filter.toQuery()['maxAmount'], '2000.50');
    });

    test('unclaimedOnly is omitted when false and "true" when set', () {
      expect(
        DepositQueueFilter.initial.toQuery().containsKey('unclaimedOnly'),
        isFalse,
      );
      expect(
        const DepositQueueFilter(unclaimedOnly: true)
            .toQuery()['unclaimedOnly'],
        'true',
      );
    });

    test('shortId is upper-cased and dates go out as UTC ISO-8601', () {
      final DepositQueueFilter filter = DepositQueueFilter(
        shortId: ' k7q2zp9v3m ',
        createdFrom: DateTime.utc(2026, 8, 16, 10),
        createdTo: DateTime.utc(2026, 8, 17, 10),
      );

      final Map<String, Object?> query = filter.toQuery();
      expect(query['shortId'], 'K7Q2ZP9V3M');
      expect(query['createdFrom'], '2026-08-16T10:00:00.000Z');
      expect(query['createdTo'], '2026-08-17T10:00:00.000Z');
    });

    test('emits no key the DTO would reject', () {
      final DepositQueueFilter filter = DepositQueueFilter(
        statuses: <DepositStatus>{DepositStatus.submitted},
        sort: DepositSort.oldest,
        playerId: _uuidV4,
        paymentMethodId: _uuidV4,
        shortId: 'ABC',
        externalReference: 'REF-1',
        createdFrom: DateTime.utc(2026),
        createdTo: DateTime.utc(2027),
        minAmount: Money.fromDecimalString('1.00'),
        maxAmount: Money.fromDecimalString('2.00'),
        unclaimedOnly: true,
      );

      // whitelist + forbidNonWhitelisted means an unknown key is a 400.
      const Set<String> allowed = <String>{
        'cursor',
        'limit',
        'status',
        'playerId',
        'paymentMethodId',
        'shortId',
        'externalReference',
        'createdFrom',
        'createdTo',
        'minAmount',
        'maxAmount',
        'unclaimedOnly',
        'sort',
      };
      expect(filter.toQuery().keys.every(allowed.contains), isTrue);
    });
  });

  group('DepositQueueFilter.validate', () {
    test('accepts a v4 uuid and rejects a v7 one on the query filters', () {
      expect(
        const DepositQueueFilter(playerId: _uuidV4).validate(_en),
        isEmpty,
      );
      // Path params take any uuid version; these query filters are @IsUUID('4').
      expect(
        const DepositQueueFilter(playerId: _uuidV7).validate(_en),
        contains(_en.validationPlayerIdUuid),
      );
      expect(
        const DepositQueueFilter(paymentMethodId: 'not-a-uuid').validate(_en),
        isNotEmpty,
      );
      // The same filter is refused in Arabic, with Arabic wording.
      expect(
        const DepositQueueFilter(playerId: _uuidV7).validate(AppStrings.ar),
        contains(AppStrings.ar.validationPlayerIdUuid),
      );
    });

    test('catches an inverted amount range', () {
      final DepositQueueFilter filter = DepositQueueFilter(
        minAmount: Money.fromDecimalString('2000.00'),
        maxAmount: Money.fromDecimalString('1000.00'),
      );
      expect(filter.validate(_en), isNotEmpty);
    });

    test('catches an inverted date range', () {
      final DepositQueueFilter filter = DepositQueueFilter(
        createdFrom: DateTime.utc(2026, 8, 17),
        createdTo: DateTime.utc(2026, 8, 16),
      );
      expect(filter.validate(_en), isNotEmpty);
    });

    test('enforces the server max lengths', () {
      expect(
        DepositQueueFilter(externalReference: 'x' * 121).validate(_en),
        isNotEmpty,
      );
      expect(DepositQueueFilter(shortId: 'y' * 33).validate(_en), isNotEmpty);
    });
  });

  group('DepositQueueFilter equality and copyWith', () {
    test('two filters with the same values are equal', () {
      final DepositQueueFilter a = DepositQueueFilter(
        statuses: <DepositStatus>{
          DepositStatus.submitted,
          DepositStatus.underReview,
        },
        minAmount: Money.fromDecimalString('10.00'),
      );
      final DepositQueueFilter b = DepositQueueFilter(
        // Same set, different insertion order.
        statuses: <DepositStatus>{
          DepositStatus.underReview,
          DepositStatus.submitted,
        },
        minAmount: Money.fromDecimalString('10.00'),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith clear flags actually remove a value', () {
      const DepositQueueFilter filter = DepositQueueFilter(shortId: 'ABC');
      expect(filter.copyWith(clearShortId: true).shortId, isNull);
      // Passing null alone must NOT clear - that is the "leave unchanged" case.
      expect(filter.copyWith().shortId, 'ABC');
    });

    test('activeCount groups ranges into a single filter', () {
      final DepositQueueFilter filter = DepositQueueFilter(
        minAmount: Money.fromDecimalString('1.00'),
        maxAmount: Money.fromDecimalString('2.00'),
        createdFrom: DateTime.utc(2026),
        createdTo: DateTime.utc(2027),
        unclaimedOnly: true,
      );

      // amount range + date range + unclaimed = 3.
      expect(filter.activeCount, 3);
      expect(filter.isActive, isTrue);
    });
  });
}
