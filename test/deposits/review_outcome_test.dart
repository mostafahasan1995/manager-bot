import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/deposits/application/deposit_action_report.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';
import 'package:manager_bot/features/deposits/data/review_outcome.dart';

/// Report copy comes from the catalogue; the English bundle keeps these
/// expectations readable.
const AppStrings _en = AppStrings.en;

/// The raw Prisma row the server embeds in a ReviewOutcome: bigints as decimal
/// STRINGS in MINOR units, dates as ISO-8601.
Map<String, Object?> _rawDeposit({String status = 'APPROVED'}) =>
    <String, Object?>{
      'id': '5f7c2a10-3b4d-4e5f-8a9b-0c1d2e3f4a5b',
      'shortId': 'K7Q2ZP9V3M',
      'playerId': 'aa11bb22-cc33-4d44-8e55-ff6677889900',
      'paymentMethodId': 'bb22cc33-dd44-4e55-8f66-001122334455',
      'paymentDestinationId': null,
      'currencyCode': 'NSP',
      'claimedAmountMinor': '150000',
      'verifiedAmountMinor': '148000',
      'feeMinor': '2500',
      'creditedAmountMinor': '145500',
      'status': status,
      'externalReference': 'REF-9911',
      'senderAccount': null,
      'expiresAt': null,
      'submittedAt': '2026-08-16T10:05:00.000Z',
      'reviewStartedAt': null,
      'decidedAt': '2026-08-16T10:30:00.000Z',
      'secondApprovedAt': null,
      'creditedAt': null,
      'decidedByAdminId': 'admin-1',
      'secondApproverAdminId': null,
      'rejectionCode': null,
      'rejectionNote': null,
      'idempotencyKey': null,
      'creditKeyEpoch': 0,
      'creditAttempts': 1,
      'creditVerifiedBy': null,
      'balanceBeforeMinor': null,
      'balanceAfterMinor': null,
      'ledgerClaimTxId': null,
      'ledgerCreditTxId': null,
      'adminChatId': '7123456789012345678',
      'adminMessageId': '981',
      'adminThreadId': null,
      'source': 'miniapp',
      'ipAddress': null,
      'userAgent': null,
      'createdAt': '2026-08-16T10:04:11.512Z',
      'updatedAt': '2026-08-16T10:30:00.000Z',
    };

void main() {
  group('ReviewOutcome.fromJson', () {
    test('approved carries the deposit and the ledger transaction id', () {
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'approved',
        'deposit': _rawDeposit(),
        'ledgerTransactionId': 'dd44ee55-ff66-4a77-8b88-223344556677',
      });

      expect(outcome, isA<ReviewApproved>());
      final ReviewApproved approved = outcome as ReviewApproved;
      expect(
        approved.ledgerTransactionId,
        'dd44ee55-ff66-4a77-8b88-223344556677',
      );
      expect(approved.deposit?.status, DepositStatus.approved);
      // Minor units, exact.
      expect(approved.deposit?.verifiedAmount?.minor, BigInt.from(148000));
      expect(approved.deposit?.creditedAmount?.minor, BigInt.from(145500));
      expect(approved.deposit?.fee?.minor, BigInt.from(2500));
      expect(outcome.isAlreadyHandled, isFalse);
      expect(outcome.resultingStatus, DepositStatus.approved);
    });

    test('awaiting_second_approval has no ledger transaction id', () {
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'awaiting_second_approval',
        'deposit': _rawDeposit(status: 'PENDING_SECOND_APPROVAL'),
      });

      expect(outcome, isA<ReviewAwaitingSecondApproval>());
      expect(outcome.resultingStatus, DepositStatus.pendingSecondApproval);
    });

    test('alreadyHandled has NO deposit key and still parses', () {
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'alreadyHandled',
        'status': 'CREDITED',
      });

      expect(outcome, isA<ReviewAlreadyHandled>());
      expect(outcome.isAlreadyHandled, isTrue);
      expect(
        (outcome as ReviewAlreadyHandled).status,
        DepositStatus.credited,
      );
    });

    test('alreadyHandled with a null status (the row is gone)', () {
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'alreadyHandled',
        'status': null,
      });

      expect((outcome as ReviewAlreadyHandled).status, isNull);
      expect(outcome.resultingStatus, isNull);
    });

    test('claimed and released parse', () {
      expect(
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'claimed',
          'deposit': _rawDeposit(status: 'UNDER_REVIEW'),
        }),
        isA<ReviewClaimed>(),
      );
      expect(
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'released',
          'deposit': _rawDeposit(status: 'SUBMITTED'),
        }),
        isA<ReviewReleased>(),
      );
      expect(
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'rejected',
          'deposit': _rawDeposit(status: 'REJECTED'),
        }),
        isA<ReviewRejected>(),
      );
    });

    test('an unknown kind degrades instead of throwing', () {
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'some_future_variant',
      });

      expect(outcome, isA<ReviewUnknown>());
      expect((outcome as ReviewUnknown).kind, 'some_future_variant');
      expect(outcome.resultingStatus, isNull);
    });

    test('a malformed raw deposit does not break a successful outcome', () {
      // The action already committed server-side; a shape surprise in the raw
      // row must never turn that into a client failure.
      final ReviewOutcome outcome = ReviewOutcome.fromJson(<String, Object?>{
        'kind': 'approved',
        'deposit': <String, Object?>{'id': 'x', 'status': 'APPROVED'},
        'ledgerTransactionId': 'tx',
      });

      expect(outcome, isA<ReviewApproved>());
      final ReviewApproved approved = outcome as ReviewApproved;
      expect(approved.deposit?.claimedAmount, isNull);
      expect(approved.deposit?.status, DepositStatus.approved);
    });
  });

  group('DepositActionReport.fromOutcome', () {
    test('an approval is benign and succeeded', () {
      final DepositActionReport report = DepositActionReport.fromOutcome(
        DepositAction.approve,
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'approved',
          'deposit': _rawDeposit(),
          'ledgerTransactionId': 'tx-1',
        }),
        _en,
      );

      expect(report, isA<DepositActionSucceeded>());
      expect(report.isBenign, isTrue);
      expect(report.isAlreadyHandled, isFalse);
      expect((report as DepositActionSucceeded).detail, contains('tx-1'));
      expect(report.isAwaitingSecondApproval, isFalse);
    });

    test('a first-of-two approval says nothing moved yet', () {
      final DepositActionReport report = DepositActionReport.fromOutcome(
        DepositAction.approve,
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'awaiting_second_approval',
          'deposit': _rawDeposit(status: 'PENDING_SECOND_APPROVAL'),
        }),
        _en,
      );

      expect(report, isA<DepositActionSucceeded>());
      expect((report as DepositActionSucceeded).isAwaitingSecondApproval, isTrue);
      expect(report.message, _en.reportAwaitingSecondApproval);
    });

    test('alreadyHandled is benign, never a failure', () {
      final DepositActionReport report = DepositActionReport.fromOutcome(
        DepositAction.approve,
        ReviewOutcome.fromJson(<String, Object?>{
          'kind': 'alreadyHandled',
          'status': 'REJECTED',
        }),
        _en,
      );

      expect(report, isA<DepositActionAlreadyHandled>());
      expect(report.isBenign, isTrue);
      expect(report.isAlreadyHandled, isTrue);
      // The status label is interpolated as-is now - no synthesised lowercase.
      expect(report.message, contains(_en.statusRejected));
    });
  });

  group('DepositActionReport.fromError', () {
    test('DEPOSIT_CLAIMED_BY_OTHER is a normal race, not a red error', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.claim,
        const ApiBusinessRule(
          code: DepositErrorCodes.depositClaimedByOther,
          message: 'Another reviewer is looking at this deposit.',
          statusCode: 422,
        ),
        _en,
      );

      expect(report, isA<DepositActionAlreadyHandled>());
      expect(report.isBenign, isTrue);
    });

    test('a CAS conflict is treated as already handled', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.approve,
        const ApiConflict(
          code: ApiErrorCodes.writeConflict,
          message: 'conflict',
          statusCode: 409,
        ),
        _en,
      );

      expect(report, isA<DepositActionAlreadyHandled>());
      expect(report.isBenign, isTrue);
    });

    test('an approval-limit refusal is a refusal, not a crash', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.approve,
        const ApiForbidden(
          code: DepositErrorCodes.adminLimitExceeded,
          message: 'This amount is above your approval authority.',
          statusCode: 403,
        ),
        _en,
      );

      expect(report, isA<DepositActionRefused>());
      expect(report.isBenign, isFalse);
      expect(report.message, _en.reportAboveApprovalLimit);
    });

    test('four-eyes violation explains who has to act', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.approve,
        const ApiForbidden(
          code: DepositErrorCodes.secondApproverMustDiffer,
          message: 'A second, different administrator must approve.',
          statusCode: 403,
        ),
        _en,
      );

      expect(report, isA<DepositActionRefused>());
      expect(report.message, _en.reportSecondApproverMustDiffer);
    });

    test('the known retry-credit 500 is named as a backend defect', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.retryCredit,
        const ApiServerError(
          code: ApiErrorCodes.internalError,
          message: 'An unexpected error occurred.',
          statusCode: 500,
        ),
        _en,
      );

      expect(report, isA<DepositActionFailed>());
      expect(report.message, _en.reportRetryCreditBackendDefect);
    });

    test('a transport failure stays a real failure', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.reject,
        const ApiNetworkError(message: 'no route to host'),
        _en,
      );

      expect(report, isA<DepositActionFailed>());
      expect(report.isBenign, isFalse);
      expect((report as DepositActionFailed).isRetryable, isTrue);
    });

    test('a non-ApiError object is still handled', () {
      final DepositActionReport report = DepositActionReport.fromError(
        DepositAction.claim,
        StateError('boom'),
        _en,
      );

      expect(report, isA<DepositActionFailed>());
      expect((report as DepositActionFailed).isRetryable, isFalse);
      expect(
        report.message,
        _en.reportActionFailed(action: DepositAction.claim.label(_en)),
      );
    });
  });

  group('RetryCreditResult / SweepReport', () {
    test('creditKeyEpoch is a plain JSON number', () {
      final RetryCreditResult result =
          RetryCreditResult.fromJson(<String, Object?>{
        'requeued': true,
        'creditKeyEpoch': 4,
      });

      expect(result.requeued, isTrue);
      expect(result.creditKeyEpoch, 4);
    });

    test('sweep counts summarise', () {
      final SweepReport empty = SweepReport.fromJson(<String, Object?>{
        'expired': 0,
        'released': 0,
        'reaped': 0,
      });
      expect(empty.isNoop, isTrue);
      expect(empty.summary(_en), _en.sweepNothingToDo);

      final SweepReport busy = SweepReport.fromJson(<String, Object?>{
        'expired': 3,
        'released': 2,
        'reaped': 1,
      });
      expect(busy.total, 6);
      expect(
        busy.summary(_en),
        _en.sweepSummary(expired: 3, released: 2, reaped: 1),
      );
      // Arabic wording, but the counts stay Western digits.
      expect(busy.summary(AppStrings.ar), contains('3'));
    });
  });

  group('ProofUrlResult and image sniffing', () {
    test('a null url on the LOCAL driver forces the stream fallback', () {
      final ProofUrlResult result = ProofUrlResult.fromJson(<String, Object?>{
        'url': null,
        'streamPath': '/v1/admin/deposits/a/proofs/b/content',
        'expiresInSeconds': 300,
      });

      expect(result.hasPresignedUrl, isFalse);
      expect(result.streamPath, '/v1/admin/deposits/a/proofs/b/content');
      expect(result.expiresInSeconds, 300);
    });

    test('detects the image formats a proof can be', () {
      expect(
        ImageSniffer.detectMimeType(_bytes(<int>[0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        ImageSniffer.detectMimeType(_bytes(<int>[0x89, 0x50, 0x4E, 0x47])),
        'image/png',
      );
      expect(
        ImageSniffer.detectMimeType(_bytes(<int>[0x47, 0x49, 0x46, 0x38])),
        'image/gif',
      );
      expect(ImageSniffer.detectMimeType(_bytes(<int>[1, 2, 3, 4])), isNull);
      expect(ImageSniffer.detectMimeType(_bytes(<int>[1])), isNull);
    });

    test('recognises an envelope where bytes were promised', () {
      // The documented risk: the global TransformInterceptor wraps the
      // StreamableFile, so /content answers JSON.
      expect(
        ImageSniffer.looksLikeJson(_bytes(<int>[0x7B, 0x22, 0x73])),
        isTrue,
      );
      expect(
        ImageSniffer.looksLikeJson(_bytes(<int>[0x20, 0x0A, 0x7B])),
        isTrue,
      );
      expect(
        ImageSniffer.looksLikeJson(_bytes(<int>[0xFF, 0xD8, 0xFF])),
        isFalse,
      );
    });
  });
}

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);
