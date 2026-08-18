import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

const AppStrings _en = AppStrings.en;
const AppStrings _ar = AppStrings.ar;

/// A queue row exactly as `GET /v1/admin/deposits` emits it: money as
/// `MoneyView` objects, the Telegram id as a 64-bit decimal STRING, every
/// timestamp ISO-8601 UTC.
Map<String, Object?> _wireRow({
  Map<String, Object?> overrides = const <String, Object?>{},
}) {
  final Map<String, Object?> base = <String, Object?>{
    'id': '5f7c2a10-3b4d-4e5f-8a9b-0c1d2e3f4a5b',
    'shortId': 'K7Q2ZP9V3M',
    'status': 'SUBMITTED',
    'playerId': 'aa11bb22-cc33-4d44-8e55-ff6677889900',
    // Exceeds 2^53 - must never become a double.
    'playerTelegramUserId': '7123456789012345678',
    'playerTelegramUsername': 'lucky_player',
    'paymentMethodId': 'bb22cc33-dd44-4e55-8f66-001122334455',
    'claimed': <String, Object?>{
      'minor': '150000',
      'amount': '1500.00',
      'currency': 'NSP',
    },
    'verified': null,
    'credited': null,
    'fee': <String, Object?>{
      'minor': '2500',
      'amount': '25.00',
      'currency': 'NSP',
    },
    'externalReference': 'REF-9911',
    'senderAccount': '0955123456',
    'proofCount': 1,
    'createdAt': '2026-08-16T10:04:11.512Z',
    'expiresAt': '2026-08-16T22:04:11.512Z',
    'submittedAt': '2026-08-16T10:05:00.000Z',
    'reviewStartedAt': null,
    'decidedAt': null,
    'creditedAt': null,
    'rejectionCode': null,
    'rejectionNote': null,
    'decidedByAdminId': null,
    'secondApproverAdminId': null,
    'creditVerifiedBy': null,
    'creditAttempts': 0,
    'creditKeyEpoch': 0,
    'riskFlags': <Object?>['NEW_PLAYER', 'DUPLICATE_PROOF_EXACT'],
    'requiresSecondApproval': false,
    'destination': <String, Object?>{
      'methodCode': 'SYRIATEL_CASH',
      'methodName': 'Syriatel Cash',
      'instructions': 'Send to the number below.',
      'requiresReference': true,
      'label': 'Main wallet',
      'accountIdentifier': '0999888777',
      'accountHolder': 'House Ltd',
    },
    'proofs': <Object?>[
      <String, Object?>{
        'id': 'cc33dd44-ee55-4f66-8a77-112233445566',
        'source': 'TELEGRAM_PHOTO',
        'mimeType': 'image/jpeg',
        'sizeBytes': 204800,
        'sha256': 'a' * 64,
        'width': 1280,
        'height': 720,
        'createdAt': '2026-08-16T10:04:50.000Z',
      },
    ],
  };
  return <String, Object?>{...base, ...overrides};
}

void main() {
  group('AdminDepositView.fromJson', () {
    test('parses a full queue row', () {
      final AdminDepositView deposit =
          AdminDepositView.fromJson(_wireRow());

      expect(deposit.id, '5f7c2a10-3b4d-4e5f-8a9b-0c1d2e3f4a5b');
      expect(deposit.shortId, 'K7Q2ZP9V3M');
      expect(deposit.status, DepositStatus.submitted);
      expect(deposit.externalReference, 'REF-9911');
      expect(deposit.senderAccount, '0955123456');
      expect(deposit.proofCount, 1);
      expect(deposit.creditAttempts, 0);
      expect(deposit.creditKeyEpoch, 0);
      expect(deposit.requiresSecondApproval, isFalse);
      expect(deposit.creditVerifiedBy, isNull);
    });

    test('money is exact BigInt minor units, never a double', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(_wireRow());

      expect(deposit.claimed.minor, BigInt.from(150000));
      expect(deposit.claimed.currency, 'NSP');
      expect(deposit.claimed.toDecimalString(), '1500.00');
      expect(deposit.fee.minor, BigInt.from(2500));
      expect(deposit.verified, isNull);
      expect(deposit.credited, isNull);
      // 1500.00 - 25.00, computed on integers.
      expect(deposit.netOfFee.toDecimalString(), '1475.00');
    });

    test('keeps a 64-bit telegram id exact', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(_wireRow());

      expect(deposit.playerTelegramUserId, BigInt.parse('7123456789012345678'));
      expect(deposit.playerTelegramUserIdString, '7123456789012345678');
      // The value is beyond the double-safe range, so a lossy parse would show.
      expect(
        deposit.playerTelegramUserId! > BigInt.from(9007199254740991),
        isTrue,
      );
    });

    test('nullable money objects parse when present', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{
            'status': 'CREDITED',
            'verified': <String, Object?>{
              'minor': '148000',
              'amount': '1480.00',
              'currency': 'NSP',
            },
            'credited': <String, Object?>{
              'minor': '145500',
              'amount': '1455.00',
              'currency': 'NSP',
            },
          },
        ),
      );

      expect(deposit.status, DepositStatus.credited);
      expect(deposit.verified?.minor, BigInt.from(148000));
      expect(deposit.credited?.minor, BigInt.from(145500));
      // amountUnderReview prefers the verified amount once it exists.
      expect(deposit.amountUnderReview.minor, BigInt.from(148000));
    });

    test('risk flags come back sorted by severity, unknown ones kept last', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{
            'riskFlags': <Object?>[
              'NEW_PLAYER',
              'SOMETHING_THE_APP_HAS_NEVER_SEEN',
              'DUPLICATE_PROOF_EXACT',
              'LARGE_AMOUNT',
            ],
          },
        ),
      );

      expect(deposit.riskFlags, <String>[
        'DUPLICATE_PROOF_EXACT',
        'LARGE_AMOUNT',
        'NEW_PLAYER',
        'SOMETHING_THE_APP_HAS_NEVER_SEEN',
      ]);
      expect(deposit.hasRiskFlags, isTrue);
    });

    test('an unknown status falls back instead of throwing', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{'status': 'SOME_FUTURE_STATUS'},
        ),
      );

      expect(deposit.status, DepositStatus.submitted);
    });

    test('parses the destination and the proof list', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(_wireRow());

      expect(deposit.destination?.methodCode, 'SYRIATEL_CASH');
      expect(deposit.destination?.requiresReference, isTrue);
      expect(deposit.destination?.accountIdentifier, '0999888777');

      expect(deposit.proofs, hasLength(1));
      final DepositProofView proof = deposit.proofs.first;
      expect(proof.id, 'cc33dd44-ee55-4f66-8a77-112233445566');
      // Labels resolve through the catalogue; the English bundle is asserted so
      // the wording stays readable here.
      expect(proof.sourceLabel(_en), 'Telegram photo');
      expect(proof.mimeType, 'image/jpeg');
      expect(proof.looksRenderable, isTrue);
      // Digits stay Western in both bundles. Only the SEPARATOR differs: the
      // Arabic bundle sets the dimension label with the multiplication sign
      // (U+00D7), which is bidi-neutral and keeps the numeric run intact.
      expect(proof.dimensionLabel(_en), '1280 x 720');
      expect(proof.dimensionLabel(_ar), '1280 × 720');
      expect(proof.shortHash, 'aaaaaaaaaaaa');
      expect(proof.sizeLabel(_en), '200 KB');
    });

    test('timestamps parse to local time and null stays null', () {
      final AdminDepositView deposit = AdminDepositView.fromJson(_wireRow());

      expect(deposit.createdAt.isUtc, isFalse);
      expect(
        deposit.createdAt.toUtc().toIso8601String(),
        '2026-08-16T10:04:11.512Z',
      );
      expect(deposit.reviewStartedAt, isNull);
      expect(deposit.decidedAt, isNull);
      expect(deposit.expiresAt, isNotNull);
    });

    test('handles an absent proofs key without throwing', () {
      final Map<String, Object?> row = _wireRow();
      row.remove('proofs');

      final AdminDepositView deposit = AdminDepositView.fromJson(row);
      expect(deposit.proofs, isEmpty);
    });

    test('a missing required field raises JsonParseException, not a silent 0',
        () {
      final Map<String, Object?> row = _wireRow();
      row.remove('claimed');

      expect(
        () => AdminDepositView.fromJson(row),
        throwsA(isA<JsonParseException>()),
      );
    });

    test('playerLabel prefers the username, then the telegram id', () {
      final AdminDepositView withUsername =
          AdminDepositView.fromJson(_wireRow());
      expect(withUsername.playerLabel, '@lucky_player');

      final AdminDepositView withoutUsername = AdminDepositView.fromJson(
        _wireRow(overrides: <String, Object?>{'playerTelegramUsername': null}),
      );
      expect(withoutUsername.playerLabel, '7123456789012345678');

      final AdminDepositView anonymous = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{
            'playerTelegramUsername': null,
            'playerTelegramUserId': null,
          },
        ),
      );
      expect(anonymous.playerLabel, 'aa11bb22...');
    });

    test('claimIsFresh follows the 10-minute claim TTL', () {
      final DateTime now = DateTime(2026, 8, 16, 12);
      final AdminDepositView fresh = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{
            'reviewStartedAt': now
                .subtract(const Duration(minutes: 4))
                .toUtc()
                .toIso8601String(),
          },
        ),
      );
      final AdminDepositView stale = AdminDepositView.fromJson(
        _wireRow(
          overrides: <String, Object?>{
            'reviewStartedAt': now
                .subtract(const Duration(minutes: 11))
                .toUtc()
                .toIso8601String(),
          },
        ),
      );

      expect(fresh.claimIsFresh(now), isTrue);
      expect(stale.claimIsFresh(now), isFalse);
    });
  });

  group('Money round trip through the deposit wire shapes', () {
    test('MoneyView minor is authoritative', () {
      final Money money = Money.fromMoneyView(<String, Object?>{
        'minor': '-150000',
        'amount': '-1500.00',
        'currency': 'NSP',
      });

      expect(money.minor, BigInt.from(-150000));
      expect(money.isNegative, isTrue);
      expect(money.toMinorString(), '-150000');
      expect(money.toDecimalString(), '-1500.00');
      // What we would send back on approve.
      expect(money.toMoneyDtoJson(), <String, Object?>{
        'amount': '-1500.00',
        'currencyCode': 'NSP',
      });
    });

    test('a huge amount survives without precision loss', () {
      final Money money = Money.fromMoneyView(<String, Object?>{
        'minor': '922337203685477580',
        'amount': '9223372036854775.80',
        'currency': 'NSP',
      });

      expect(money.minor, BigInt.parse('922337203685477580'));
      expect(money.toDecimalString(), '9223372036854775.80');
    });
  });
}
