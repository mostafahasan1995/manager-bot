import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/features/reconciliation/data/break_action_result.dart';
import 'package:manager_bot/features/reconciliation/data/break_filter.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/data/float_sync_result.dart';
import 'package:manager_bot/features/reconciliation/data/ledger_invariant_report.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';
import 'package:manager_bot/features/reconciliation/data/reconciliation_error_codes.dart';

/// Every reconciliation call, in one place.
///
/// Rules this class enforces so no screen has to:
/// * The cursor is OPAQUE - `page.nextCursor` goes back verbatim. A cursor that
///   the server cannot decode is silently treated as page 1, never an error.
/// * No reconciliation route wants an `Idempotency-Key`, and none is rate
///   limited, so nothing here passes `idempotent: true`.
/// * `correct-float` is NOT safely retryable: the ledger posting dedupes but
///   the follow-up resolve does not. Its 422 answers are mapped to values so a
///   caller cannot accidentally treat "already resolved" as a plain failure.
class ReconciliationRepository {
  const ReconciliationRepository(this._client);

  static const String basePath = '/v1/admin/reconciliation';
  static const String breaksPath = '$basePath/breaks';
  static const String agentFloatSyncPath = '$basePath/agent-float/sync';
  static const String railAgeingPath = '$basePath/rail-ageing';
  static const String invariantsRunPath = '$basePath/invariants/run';

  final ApiClient _client;

  /// `GET /breaks` - cursor paged, newest `detectedAt` first.
  Future<CursorPage<BreakView>> listBreaks({
    String? cursor,
    BreakFilter filter = BreakFilter.unresolved,
    int? limit,
    CancelToken? cancelToken,
  }) {
    return _client.getCursorPage<BreakView>(
      breaksPath,
      cursor: cursor,
      limit: limit,
      query: filter.toQuery(),
      fromJson: BreakView.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// `GET /breaks/:id`. A missing id is a 404 `RESOURCE_NOT_FOUND` here (NOT
  /// the domain code), and a non-UUID id is a 400 `BAD_REQUEST`.
  Future<BreakView> breakById(String id, {CancelToken? cancelToken}) {
    return _client.getObject<BreakView>(
      '$breaksPath/$id',
      fromJson: BreakView.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// `POST /breaks/:id/assign` - take ownership; the server sets the assignee
  /// to the caller and the status to INVESTIGATING. Empty POST, 200 not 201.
  ///
  /// There is NO terminal-status guard server-side: assigning a closed break
  /// re-opens it as INVESTIGATING while leaving its resolution fields intact.
  /// [BreakView.canAssign] is the only thing stopping that, so callers must
  /// check it before calling this.
  Future<BreakActionResult> assign(String id) async {
    try {
      final BreakView updated = await _client.postObject<BreakView>(
        '$breaksPath/$id/assign',
        fromJson: BreakView.fromJson,
      );
      return BreakActionApplied(updated, kind: BreakActionKind.assigned);
    } on ApiNotFound catch (_) {
      return const BreakActionMissing();
    } on ApiError catch (e) {
      return BreakActionFailed(e);
    }
  }

  /// `POST /breaks/:id/resolve` - close with a terminal status and a note.
  ///
  /// [note] is trimmed and must be non-empty: the backend has NO minimum length
  /// despite its own doc comment, so the only thing preventing an empty audit
  /// note is this client.
  Future<BreakActionResult> resolve({
    required String id,
    required BreakStatus status,
    required String note,
  }) async {
    if (!status.isTerminal) {
      // Sending OPEN/INVESTIGATING would be a 400 CORRECTION_NOT_ALLOWED; there
      // is no reason to spend a round trip discovering that.
      return const BreakActionRejected.onlyTerminalStatuses();
    }
    final String trimmed = note.trim();
    if (trimmed.isEmpty) {
      return const BreakActionRejected.noteRequired();
    }
    try {
      final BreakView updated = await _client.postObject<BreakView>(
        '$breaksPath/$id/resolve',
        fromJson: BreakView.fromJson,
        body: <String, Object?>{
          'status': status.wireName,
          'note': trimmed,
        },
      );
      return BreakActionApplied(
        updated,
        kind: BreakActionKind.closed,
        closedAs: status,
      );
    } on ApiNotFound catch (_) {
      // 404 BREAK_NOT_FOUND on this route specifically.
      return const BreakActionMissing();
    } on ApiBusinessRule catch (e) {
      if (e.code == ReconciliationErrorCodes.breakAlreadyResolved) {
        return BreakActionAlreadyClosed(
          existingStatus: BreakStatus.tryParse(e.detailString('status')),
        );
      }
      return BreakActionFailed(e);
    } on ApiValidation catch (e) {
      // The one place a domain code rides a 400.
      if (e.code == ReconciliationErrorCodes.correctionNotAllowed) {
        return BreakActionRejected.server(
          e.message,
          currentStatus: BreakStatus.tryParse(e.detailString('status')),
        );
      }
      return BreakActionFailed(e);
    } on ApiError catch (e) {
      return BreakActionFailed(e);
    }
  }

  /// `POST /breaks/:id/correct-float` - post a real `AGENT_FLOAT_SYNC` ledger
  /// transaction for the break's stored delta, then auto-resolve it.
  ///
  /// THIS CHANGES THE BOOKS. There is no amount parameter: the corrected value
  /// is always the break's own delta, which is why [currencyCode] must be the
  /// break's currency - the response carries none.
  Future<CorrectFloatResult> correctFloat({
    required String breakId,
    required String note,
    required String currencyCode,
  }) async {
    final String trimmed = note.trim();
    if (trimmed.isEmpty) {
      return const CorrectFloatRejected.noteRequired();
    }
    try {
      final CorrectFloatReceipt receipt =
          await _client.postObject<CorrectFloatReceipt>(
        '$breaksPath/$breakId/correct-float',
        fromJson: (Map<String, Object?> json) =>
            CorrectFloatReceipt.fromJson(json, currencyCode: currencyCode),
        body: <String, Object?>{'note': trimmed},
      );
      return CorrectFloatPosted(
        ledgerTransactionId: receipt.ledgerTransactionId,
        delta: receipt.delta,
      );
    } on ApiBusinessRule catch (e) {
      switch (e.code) {
        case ReconciliationErrorCodes.breakAlreadyResolved:
          return CorrectFloatAlreadyResolved(
            existingStatus: BreakStatus.tryParse(e.detailString('status')),
          );
        case ReconciliationErrorCodes.nothingToCorrect:
          return const CorrectFloatNothingToCorrect();
        case ReconciliationErrorCodes.correctionNotAllowed:
          // Also raised when the break id simply does not exist: a missing
          // break is a 422 on this route, not a 404.
          return CorrectFloatRejected.server(e.message);
        default:
          return CorrectFloatFailed(e);
      }
    } on ApiError catch (e) {
      return CorrectFloatFailed(e);
    }
  }

  /// `POST /agent-float/sync` - compare the ledger float against the Ichancy
  /// agent wallet now. No body, no query, 200.
  ///
  /// An unreachable Ichancy API is a SUCCESS with null ichancy/delta/breakId.
  Future<FloatSyncResult> syncAgentFloat({CancelToken? cancelToken}) {
    return _client.postObject<FloatSyncResult>(
      agentFloatSyncPath,
      fromJson: FloatSyncResult.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// `GET /rail-ageing`. Live raw-SQL aggregate on every call - no cache.
  Future<RailAgeingReport> railAgeing({CancelToken? cancelToken}) {
    return _client.getObject<RailAgeingReport>(
      railAgeingPath,
      fromJson: RailAgeingReport.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// `POST /invariants/run` - I1/I2/I3 synchronously. Three full ledger
  /// aggregates in one transaction, so this is the slowest call in the module.
  Future<LedgerInvariantReport> runInvariants({CancelToken? cancelToken}) {
    return _client.postObject<LedgerInvariantReport>(
      invariantsRunPath,
      fromJson: LedgerInvariantReport.fromJson,
      cancelToken: cancelToken,
    );
  }
}

final Provider<ReconciliationRepository> reconciliationRepositoryProvider =
    Provider<ReconciliationRepository>(
  (ref) => ReconciliationRepository(ref.watch(apiClientProvider)),
);
