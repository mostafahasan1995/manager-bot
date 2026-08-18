import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_query.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';
import 'package:manager_bot/features/deposits/data/review_outcome.dart';

/// Every call to `DepositAdminController`, and nothing else.
///
/// Contract notes that shape this class:
/// * Admin routes address deposits by UUID (`AdminDepositView.id`), NEVER by
///   `shortId`. The router only carries a shortId, so [findByShortId] resolves
///   one through the queue's exact-match filter.
/// * claim/release/approve/reject all return HTTP 200 with a [ReviewOutcome]
///   union; `alreadyHandled` is a SUCCESS, so it is a value here, not a throw.
/// * No route on this controller honours `Idempotency-Key`; the server-side CAS
///   is the deduplication, which is why every action is safe to retry.
class DepositRepository {
  const DepositRepository(this._client);

  static const String basePath = '/v1/admin/deposits';

  final ApiClient _client;

  /// The review queue, cursor-paginated over (createdAt, id).
  ///
  /// [cursor] must be a value that came out of a previous page's `nextCursor`:
  /// it is OPAQUE. A malformed one is silently ignored server-side (page 1),
  /// never an error.
  Future<CursorPage<AdminDepositView>> queue({
    DepositQueueFilter filter = DepositQueueFilter.initial,
    String? cursor,
    int? limit,
    CancelToken? cancelToken,
  }) {
    return _client.getCursorPage<AdminDepositView>(
      basePath,
      fromJson: AdminDepositView.fromJson,
      cursor: cursor,
      limit: limit,
      query: filter.toQuery(),
      cancelToken: cancelToken,
    );
  }

  /// Full detail for one deposit, addressed by UUID.
  Future<AdminDepositView> detailById(String id, {CancelToken? cancelToken}) {
    return _client.getObject<AdminDepositView>(
      '$basePath/$id',
      fromJson: AdminDepositView.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Resolves a human-facing `shortId` to the full row.
  ///
  /// There is NO `GET /v1/admin/deposits/{shortId}` route, so this uses the
  /// queue's exact-match `shortId` filter. ALL 13 statuses are listed
  /// explicitly because omitting `status` defaults to the three reviewable
  /// ones, which would hide an already-credited or rejected deposit.
  Future<AdminDepositView?> findByShortId(
    String shortId, {
    CancelToken? cancelToken,
  }) async {
    final String normalized = shortId.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final CursorPage<AdminDepositView> page =
        await _client.getCursorPage<AdminDepositView>(
      basePath,
      fromJson: AdminDepositView.fromJson,
      limit: 1,
      query: <String, Object?>{
        'shortId': normalized,
        'status': DepositStatus.values
            .map((DepositStatus status) => status.wireName)
            .join(','),
      },
      cancelToken: cancelToken,
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  /// Takes the advisory 10-minute soft claim.
  ///
  /// Sends NO BODY - there is no DTO on this route.
  ///
  /// KNOWN BACKEND DEFECT - THIS CALL CANNOT SUCCEED TODAY. `DepositReviewService
  /// .claim` asks the state machine to move `[SUBMITTED, UNDER_REVIEW] ->
  /// UNDER_REVIEW`, and `DepositStateMachine.transition` asserts legality for
  /// EVERY candidate before touching the row.
  /// `ALLOWED_TRANSITIONS[UNDER_REVIEW]` is
  /// `[SUBMITTED, PENDING_SECOND_APPROVAL, APPROVED, REJECTED, EXPIRED]` - there
  /// is no UNDER_REVIEW self-edge - so `IllegalDepositTransitionError` (a plain
  /// Error, not an AppException) is thrown whatever the row's real status is and
  /// the client receives 500 `INTERNAL_ERROR`.
  ///
  /// The DECLARED behaviour, which this client is written for and which becomes
  /// reachable the day `DepositStatus.UNDER_REVIEW` is added to
  /// `ALLOWED_TRANSITIONS[UNDER_REVIEW]`: re-claiming your own claim succeeds, a
  /// claim older than 10 minutes is stealable, and a fresh claim held by
  /// somebody else is a 422 `DEPOSIT_CLAIMED_BY_OTHER` reaching the caller as
  /// [ApiBusinessRule]. Neither shape is observable today.
  ///
  /// `DepositActionReport.fromError` names the defect so an operator is not sent
  /// to support for a reproducible server bug. Approve and reject do NOT need a
  /// claim: the claim is advisory, so review work is not blocked by this.
  Future<ReviewOutcome> claim(String id, {CancelToken? cancelToken}) {
    return _client.postObject<ReviewOutcome>(
      '$basePath/$id/claim',
      fromJson: ReviewOutcome.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Returns a claimed deposit to the queue (UNDER_REVIEW -> SUBMITTED).
  ///
  /// Sends NO BODY: the release reason is generated server-side as
  /// `Released by <displayName>` and cannot be supplied. Releasing somebody
  /// else's claim is a SILENT no-op that answers `alreadyHandled`.
  Future<ReviewOutcome> release(String id, {CancelToken? cancelToken}) {
    return _client.postObject<ReviewOutcome>(
      '$basePath/$id/release',
      fromJson: ReviewOutcome.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Approves, optionally correcting the amount the player claimed.
  ///
  /// OMITTING [verifiedAmount] means "I verified exactly what was claimed" and
  /// is recorded as `claimAcceptedVerbatim: true`. When supplied it is sent as
  /// the nested `MoneyDto` object - never a bare string or number - and its
  /// `currencyCode` is IGNORED by the server, which uses the deposit's own
  /// currency.
  ///
  /// May legitimately answer [ReviewAwaitingSecondApproval]: whether four eyes
  /// are required is decided by the admin's approval limits, which the client
  /// cannot see in advance.
  Future<ReviewOutcome> approve(
    String id, {
    Money? verifiedAmount,
    String? note,
    CancelToken? cancelToken,
  }) {
    final String? trimmedNote = _trimToNull(note);
    return _client.postObject<ReviewOutcome>(
      '$basePath/$id/approve',
      fromJson: ReviewOutcome.fromJson,
      // `{}` is a valid body. Unknown keys are a 400, so only these two appear.
      body: <String, Object?>{
        if (verifiedAmount != null)
          'verifiedAmount': verifiedAmount.toMoneyDtoJson(),
        if (trimmedNote != null) 'note': trimmedNote,
      },
      cancelToken: cancelToken,
    );
  }

  /// Rejects. Posts NOTHING to the ledger and is terminal.
  ///
  /// [code] is required by the server precisely because a free-text note cannot
  /// be aggregated into a report.
  Future<ReviewOutcome> reject(
    String id, {
    required RejectionCode code,
    String? note,
    CancelToken? cancelToken,
  }) {
    final String? trimmedNote = _trimToNull(note);
    return _client.postObject<ReviewOutcome>(
      '$basePath/$id/reject',
      fromJson: ReviewOutcome.fromJson,
      body: <String, Object?>{
        'rejectionCode': code.wireName,
        if (trimmedNote != null) 'rejectionNote': trimmedNote,
      },
      cancelToken: cancelToken,
    );
  }

  /// Re-runs a failed credit (CREDIT_FAILED / NEEDS_RECONCILIATION).
  ///
  /// KNOWN BACKEND DEFECT: `DepositRetryService` asks the state machine to move
  /// `[CREDIT_FAILED, NEEDS_RECONCILIATION] -> APPROVED`, and the machine
  /// asserts legality for EVERY candidate before running the update.
  /// `ALLOWED_TRANSITIONS[NEEDS_RECONCILIATION]` does not contain APPROVED, so
  /// `IllegalDepositTransitionError` is thrown on every call that gets past the
  /// pre-checks - INCLUDING a legitimately CREDIT_FAILED row - and the client
  /// receives 500 INTERNAL_ERROR. The declared 202 shape is unreachable today.
  ///
  /// This client is built for the DECLARED shape; the caller is responsible for
  /// telling the operator that a 500 here is a known server bug rather than a
  /// bad request.
  Future<RetryCreditResult> retryCredit(
    String id, {
    String? reason,
    CancelToken? cancelToken,
  }) {
    final String? trimmedReason = _trimToNull(reason);
    return _client.postObject<RetryCreditResult>(
      '$basePath/$id/retry-credit',
      fromJson: RetryCreditResult.fromJson,
      body: <String, Object?>{
        if (trimmedReason != null) 'reason': trimmedReason,
      },
      cancelToken: cancelToken,
    );
  }

  /// Runs the expiry / stale-claim / stuck-credit sweep now.
  ///
  /// Bounded to 100 rows per phase, so a backlog needs repeated calls.
  Future<SweepReport> sweep({CancelToken? cancelToken}) {
    return _client.postObject<SweepReport>(
      '$basePath/maintenance/sweep',
      fromJson: SweepReport.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Mints the short-lived download descriptor for one proof.
  Future<ProofUrlResult> proofUrl(
    String depositId,
    String proofId, {
    CancelToken? cancelToken,
  }) {
    return _client.getObject<ProofUrlResult>(
      '$basePath/$depositId/proofs/$proofId/url',
      fromJson: ProofUrlResult.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Loads one proof image as bytes.
  ///
  /// A plain `Image.network` CANNOT work here: the streaming route needs the
  /// same bearer token as every other admin call, and there is no signed-URL or
  /// query-token variant. So:
  ///  1. ask `/url` for a presigned link and, when present, fetch it with NO
  ///     Authorization header (it is itself the credential, and forwarding an
  ///     admin token to object storage would leak it);
  ///  2. otherwise stream `/content` through the API with the bearer token.
  ///
  /// Step 2 is then SNIFFED, because the handler returns a Nest
  /// `StreamableFile` while the global `TransformInterceptor` wraps every
  /// non-envelope payload in JSON - so the route can answer with an envelope
  /// where image bytes were promised. That is reported as an explained empty
  /// state rather than a corrupt image.
  Future<ProofImage> loadProofImage(
    String depositId,
    DepositProofView proof, {
    required AppStrings strings,
    CancelToken? cancelToken,
  }) async {
    final ProofUrlResult descriptor;
    try {
      descriptor = await proofUrl(depositId, proof.id, cancelToken: cancelToken);
    } on ApiError catch (error) {
      return ProofImageUnavailable(
        code: error.code,
        message: error.code == DepositErrorCodes.proofNotFound
            ? strings.proofGone
            : error.userMessage(strings),
        detail: error.correlationId,
      );
    }

    if (descriptor.hasPresignedUrl) {
      final ProofImage fromStorage = await _fetchBytes(
        descriptor.url!,
        proof: proof,
        authenticated: false,
        viaPresignedUrl: true,
        strings: strings,
        cancelToken: cancelToken,
      );
      if (fromStorage is ProofImageBytes) {
        return fromStorage;
      }
      AppLogger.warn(
        'Presigned proof fetch failed for ${proof.id}; falling back to the '
        'API stream',
        scope: 'deposits',
      );
    }

    final String streamPath = descriptor.streamPath.isEmpty
        ? '$basePath/$depositId/proofs/${proof.id}/content'
        : descriptor.streamPath;

    return _fetchBytes(
      streamPath,
      proof: proof,
      authenticated: true,
      viaPresignedUrl: false,
      strings: strings,
      cancelToken: cancelToken,
    );
  }

  Future<ProofImage> _fetchBytes(
    String path, {
    required DepositProofView proof,
    required bool authenticated,
    required bool viaPresignedUrl,
    required AppStrings strings,
    CancelToken? cancelToken,
  }) async {
    try {
      // `rawDio` is the documented escape hatch for a binary download: the
      // typed verbs all decode an envelope, which these bytes are not.
      final Response<List<int>> response = await _client.rawDio.get<List<int>>(
        path,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          extra: <String, Object?>{ApiClient.extraSkipAuth: !authenticated},
        ),
      );

      final int status = response.statusCode ?? 0;
      final List<int>? payload = response.data;
      if (status < 200 || status >= 300 || payload == null || payload.isEmpty) {
        return ProofImageUnavailable(
          code: ProofImageUnavailable.codeTransportFailed,
          message: strings.proofDownloadFailed,
          detail: 'HTTP $status',
        );
      }

      final Uint8List bytes = Uint8List.fromList(payload);
      final String? sniffed = ImageSniffer.detectMimeType(bytes);
      if (sniffed != null) {
        return ProofImageBytes(
          bytes: bytes,
          // Prefer the sniffed type: Content-Disposition hard-codes ".jpg"
          // regardless of what was actually stored.
          mimeType: sniffed,
          viaPresignedUrl: viaPresignedUrl,
        );
      }

      if (ImageSniffer.looksLikeJson(bytes)) {
        return ProofImageUnavailable(
          code: ProofImageUnavailable.codeEnvelopeInsteadOfBytes,
          message: strings.proofEnvelopeInsteadOfBytes,
          detail: strings.proofEnvelopeDetail,
        );
      }

      return ProofImageUnavailable(
        code: ProofImageUnavailable.codeNotAnImage,
        message: strings.proofNotAnImage,
        detail: strings.proofNotAnImageDetail(
          mimeType: proof.mimeType,
          bytes: bytes.lengthInBytes,
        ),
      );
    } on DioException catch (error) {
      // rawDio bypasses ApiClient's mapping, so a DioException must be handled
      // here or it would escape as an untyped failure.
      return ProofImageUnavailable(
        code: error.type == DioExceptionType.cancel
            ? ApiErrorCodes.clientCancelled
            : ProofImageUnavailable.codeTransportFailed,
        message: error.type == DioExceptionType.cancel
            ? strings.proofDownloadCancelled
            : strings.proofDownloadFailed,
        detail: error.message,
      );
    }
  }

  static String? _trimToNull(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// The repository, wired to the app-wide [ApiClient].
final Provider<DepositRepository> depositRepositoryProvider =
    Provider<DepositRepository>(
  (ref) => DepositRepository(ref.watch(apiClientProvider)),
);
