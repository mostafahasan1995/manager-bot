import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/admin_users/application/approval_limits_controller.dart';
import 'package:manager_bot/features/admin_users/data/approval_limit.dart';

Map<String, Object?> _wire({
  Object? secondApprovalAbove = '10000.00',
  Object? effectiveTo,
  String currencyCode = 'NSP',
  String maxSingleApproval = '15000.00',
  String maxDailyApproval = '90000.00',
  String id = 'a1b2c3d4-0000-4000-8000-000000000001',
}) =>
    <String, Object?>{
      'id': id,
      'adminUserId': '0f6a4d8e-2b1c-4f3a-9e77-1a2b3c4d5e6f',
      'currencyCode': currencyCode,
      'maxSingleApproval': maxSingleApproval,
      'maxDailyApproval': maxDailyApproval,
      'secondApprovalAbove': secondApprovalAbove,
      'effectiveFrom': '2026-08-01T00:00:00.000Z',
      'effectiveTo': effectiveTo,
      'createdAt': '2026-08-01T00:00:00.000Z',
    };

Money _nsp(String decimal) => Money.fromDecimalString(decimal);

void main() {
  group('ApprovalLimitView.fromJson', () {
    test('parses bare decimal strings into BigInt minor units', () {
      final ApprovalLimitView limit = ApprovalLimitView.fromJson(_wire());

      expect(limit.maxSingleApproval.minor, BigInt.from(1500000));
      expect(limit.maxDailyApproval.minor, BigInt.from(9000000));
      expect(limit.secondApprovalAbove?.minor, BigInt.from(1000000));
      expect(limit.maxSingleApproval.currency, 'NSP');
      expect(limit.maxSingleApproval.scale, 2);
    });

    test('takes the currency from the sibling field, not a default', () {
      final ApprovalLimitView limit =
          ApprovalLimitView.fromJson(_wire(currencyCode: 'EUR'));

      expect(limit.currencyCode, 'EUR');
      expect(limit.maxSingleApproval.currency, 'EUR');
      expect(limit.maxDailyApproval.currency, 'EUR');
      expect(limit.secondApprovalAbove?.currency, 'EUR');
    });

    test('an absent second-approval override means inherit, not zero', () {
      final ApprovalLimitView limit =
          ApprovalLimitView.fromJson(_wire(secondApprovalAbove: null));

      expect(limit.secondApprovalAbove, isNull);
      expect(limit.inheritsGlobalThreshold, isTrue);
    });

    test('a zero override is a real override, not an inherit', () {
      final ApprovalLimitView limit =
          ApprovalLimitView.fromJson(_wire(secondApprovalAbove: '0.00'));

      expect(limit.inheritsGlobalThreshold, isFalse);
      expect(limit.secondApprovalAbove?.isZero, isTrue);
    });

    test('effectiveTo null means the version is the one in force', () {
      expect(ApprovalLimitView.fromJson(_wire()).isInForce, isTrue);
      expect(
        ApprovalLimitView.fromJson(
          _wire(effectiveTo: '2026-08-10T12:00:00.000Z'),
        ).isInForce,
        isFalse,
      );
    });

    test('round-trips through toJson', () {
      final ApprovalLimitView first = ApprovalLimitView.fromJson(_wire());
      final ApprovalLimitView second =
          ApprovalLimitView.fromJson(first.toJson());

      expect(second, first);
      expect(second.hashCode, first.hashCode);
    });

    test('round-trips a superseded version with no override', () {
      final ApprovalLimitView first = ApprovalLimitView.fromJson(
        _wire(secondApprovalAbove: null, effectiveTo: '2026-08-10T12:00:00.000Z'),
      );
      final ApprovalLimitView second =
          ApprovalLimitView.fromJson(first.toJson());

      expect(second, first);
      expect(second.effectiveTo, isNotNull);
    });
  });

  group('SetApprovalLimitRequest', () {
    test('sends major-unit decimal strings and an uppercase currency', () {
      final Map<String, Object?> body = SetApprovalLimitRequest(
        maxSingleApproval: _nsp('15000.00'),
        maxDailyApproval: _nsp('90000.00'),
        secondApprovalAbove: _nsp('10000.00'),
      ).toJson();

      expect(body, <String, Object?>{
        'currencyCode': 'NSP',
        'maxSingleApproval': '15000.00',
        'maxDailyApproval': '90000.00',
        'secondApprovalAbove': '10000.00',
      });
      expect(body['maxSingleApproval'], isA<String>());
    });

    test('omits the override entirely when it is absent', () {
      final Map<String, Object?> body = SetApprovalLimitRequest(
        maxSingleApproval: _nsp('15000.00'),
        maxDailyApproval: _nsp('90000.00'),
      ).toJson();

      expect(body.containsKey('secondApprovalAbove'), isFalse);
    });

    test('accepts a coherent configuration', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('15000.00'),
          maxDailyApproval: _nsp('90000.00'),
        ).problem,
        isNull,
      );
    });

    test('rejects a single ceiling above the daily ceiling', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('90000.01'),
          maxDailyApproval: _nsp('90000.00'),
        ).problem,
        ApprovalLimitProblem.singleAboveDaily,
      );
    });

    test('allows single exactly equal to daily', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('90000.00'),
          maxDailyApproval: _nsp('90000.00'),
        ).problem,
        isNull,
      );
    });

    test('rejects a zero or negative ceiling', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('0.00'),
          maxDailyApproval: _nsp('90000.00'),
        ).problem,
        ApprovalLimitProblem.singleNotPositive,
      );
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('10.00'),
          maxDailyApproval: _nsp('0.00'),
        ).problem,
        ApprovalLimitProblem.dailyNotPositive,
      );
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('-1.00'),
          maxDailyApproval: _nsp('90000.00'),
        ).problem,
        ApprovalLimitProblem.singleNotPositive,
      );
    });

    test('rejects a negative second-approval threshold', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: _nsp('15000.00'),
          maxDailyApproval: _nsp('90000.00'),
          secondApprovalAbove: _nsp('-0.01'),
        ).problem,
        ApprovalLimitProblem.secondApprovalNegative,
      );
    });

    test('rejects amounts in mixed currencies before anything else', () {
      expect(
        SetApprovalLimitRequest(
          maxSingleApproval: Money.fromDecimalString('15000.00'),
          maxDailyApproval:
              Money.fromDecimalString('90000.00', currency: 'EUR'),
        ).problem,
        ApprovalLimitProblem.currencyMismatch,
      );
    });
  });

  group('history helpers', () {
    final ApprovalLimitView activeNsp = ApprovalLimitView.fromJson(_wire());
    final ApprovalLimitView oldNsp = ApprovalLimitView.fromJson(
      _wire(id: 'old-nsp', effectiveTo: '2026-08-01T00:00:00.000Z'),
    );
    final ApprovalLimitView endedEur = ApprovalLimitView.fromJson(
      _wire(
        id: 'ended-eur',
        currencyCode: 'EUR',
        effectiveTo: '2026-07-01T00:00:00.000Z',
      ),
    );

    test('finds the version in force for a currency', () {
      final List<ApprovalLimitView> history = <ApprovalLimitView>[
        activeNsp,
        oldNsp,
        endedEur,
      ];

      expect(activeLimitFor(history, 'NSP'), activeNsp);
      expect(activeLimitFor(history, 'nsp'), activeNsp);
      // EUR only ever had a version that has already ended: no active ceiling,
      // which the evaluator reads as DENIED rather than "unlimited".
      expect(activeLimitFor(history, 'EUR'), isNull);
      expect(activeLimitFor(history, 'USD'), isNull);
    });

    test('lists every currency once, in first-seen order', () {
      expect(
        currenciesIn(<ApprovalLimitView>[activeNsp, oldNsp, endedEur]),
        <String>['NSP', 'EUR'],
      );
      expect(currenciesIn(<ApprovalLimitView>[]), isEmpty);
    });
  });
}
