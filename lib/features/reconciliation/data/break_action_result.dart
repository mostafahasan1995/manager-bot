import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// Which write produced a [BreakActionApplied].
///
/// The success line is NOT built by concatenation any more: `Assigned to you`
/// and `Closed as <status>` are two different sentences in Arabic, so the kind
/// travels with the result and the wording is resolved at render time.
enum BreakActionKind {
  /// `POST /breaks/:id/assign`.
  assigned,

  /// `POST /breaks/:id/resolve`.
  closed,
}

/// Why an action was refused, when the refusal was NOT the server's own prose.
enum BreakRejection {
  /// Local guard: resolve was asked for a non-terminal status.
  onlyTerminalStatuses,

  /// Local guard: the resolution note was empty after trimming.
  resolutionNoteRequired,

  /// Local guard: assigning a closed break would silently re-open it.
  assignWouldReopen,

  /// Local guard: another write on this break is still in flight.
  anotherActionRunning,

  /// The server explained itself; [BreakActionRejected.serverMessage] holds it.
  server,
}

/// Outcome of `assign` or `resolve`.
///
/// The refusals a break can legitimately answer with - already closed, not a
/// closing status, gone - are VALUES, not exceptions: two admins working the
/// same queue is normal and must not paint the screen red. Anything genuinely
/// unexpected is still carried as an [ApiError] inside [BreakActionFailed] so
/// the caller has one total switch instead of a try/catch chain.
sealed class BreakActionResult {
  const BreakActionResult();

  /// True when the break as shown on screen is now out of date.
  bool get shouldRefresh;

  /// One line for a snackbar.
  String userMessage(AppStrings s);
}

/// The action was applied; [updated] is the server's fresh view of the break.
final class BreakActionApplied extends BreakActionResult {
  const BreakActionApplied(this.updated, {required this.kind, this.closedAs});

  final BreakView updated;

  /// Which write this was.
  final BreakActionKind kind;

  /// The terminal status the break was closed with, for [BreakActionKind.closed].
  final BreakStatus? closedAs;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => switch (kind) {
        BreakActionKind.assigned => s.actionAssignedToYou,
        BreakActionKind.closed => s.actionClosedAsStatus(
            status: (closedAs ?? updated.status).label(s),
          ),
      };
}

/// 422 `BREAK_ALREADY_RESOLVED` - somebody closed it first.
final class BreakActionAlreadyClosed extends BreakActionResult {
  const BreakActionAlreadyClosed({this.existingStatus});

  /// From `details.status`; null when the server sent no details.
  final BreakStatus? existingStatus;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) {
    final BreakStatus? status = existingStatus;
    if (status == null) {
      return s.breakAlreadyClosedByOther;
    }
    return s.breakAlreadyClosedAsStatus(status: status.label(s));
  }
}

/// 400/422 `CORRECTION_NOT_ALLOWED`, or a local guard: the requested
/// transition is not legal.
final class BreakActionRejected extends BreakActionResult {
  const BreakActionRejected._({
    required this.reason,
    this.serverMessage,
    this.currentStatus,
  });

  /// The server refused and said why, in its own words.
  const BreakActionRejected.server(String message, {BreakStatus? currentStatus})
      : this._(
          reason: BreakRejection.server,
          serverMessage: message,
          currentStatus: currentStatus,
        );

  /// Resolve was asked for OPEN or INVESTIGATING.
  const BreakActionRejected.onlyTerminalStatuses()
      : this._(reason: BreakRejection.onlyTerminalStatuses);

  /// The resolution note was empty.
  const BreakActionRejected.noteRequired()
      : this._(reason: BreakRejection.resolutionNoteRequired);

  /// Assigning [status] would re-open a closed break.
  const BreakActionRejected.wouldReopen(BreakStatus status)
      : this._(
          reason: BreakRejection.assignWouldReopen,
          currentStatus: status,
        );

  /// Another write on this break is still running.
  const BreakActionRejected.busy()
      : this._(reason: BreakRejection.anotherActionRunning);

  final BreakRejection reason;

  /// Only set for [BreakRejection.server]. The envelope legitimately carries an
  /// EMPTY sentence, which falls back to the catalogue rather than to a blank.
  final String? serverMessage;

  final BreakStatus? currentStatus;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => switch (reason) {
        BreakRejection.server => (serverMessage?.isEmpty ?? true)
            ? s.errorRequestFailed
            : serverMessage!,
        BreakRejection.onlyTerminalStatuses => s.actionOnlyTerminalStatuses,
        BreakRejection.resolutionNoteRequired => s.resolutionNoteRequired,
        BreakRejection.assignWouldReopen => s.assignWouldReopen(
            status: (currentStatus ?? BreakStatus.unknown).label(s),
          ),
        BreakRejection.anotherActionRunning => s.anotherActionRunning,
      };
}

/// 404 - `BREAK_NOT_FOUND` or the generic `RESOURCE_NOT_FOUND`, depending on
/// which route was called for the very same condition.
final class BreakActionMissing extends BreakActionResult {
  const BreakActionMissing();

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => s.breakNoLongerExists;
}

/// Anything else: a role gate, a write conflict, a timeout, a 500.
final class BreakActionFailed extends BreakActionResult {
  const BreakActionFailed(this.error);

  final ApiError error;

  /// `WRITE_CONFLICT` is explicitly documented as safe to retry whole.
  bool get canRetry => error.isRetryable;

  @override
  bool get shouldRefresh => error is ApiConflict;

  @override
  String userMessage(AppStrings s) => error.userMessage(s);
}

/// Why a ledger correction was refused without the server saying so.
enum CorrectFloatRejection {
  /// Local guard: the note was empty after trimming.
  correctionNoteRequired,

  /// Local guard: the break has not finished loading.
  breakStillLoading,

  /// Local guard: only an agent float mismatch is correctable this way.
  onlyFloatMismatchCorrectable,

  /// Local guard: another write on this break is still in flight.
  anotherActionRunning,

  /// The server explained itself; [CorrectFloatRejected.serverMessage] holds it.
  server,
}

/// Outcome of `POST /breaks/:id/correct-float`, which POSTS TO THE LEDGER.
///
/// Kept separate from [BreakActionResult] because its failure modes are
/// different in kind: the call is NOT safely retryable at the HTTP level, and
/// an "already resolved" answer after a timeout means it probably WORKED.
sealed class CorrectFloatResult {
  const CorrectFloatResult();

  /// True when the break must be re-fetched to learn the real state.
  bool get shouldRefresh;

  String userMessage(AppStrings s);
}

/// The ledger correction was posted and the break auto-resolved.
final class CorrectFloatPosted extends CorrectFloatResult {
  const CorrectFloatPosted({
    required this.ledgerTransactionId,
    required this.delta,
  });

  final String ledgerTransactionId;

  /// The break's stored delta that was corrected. Signed, never abs()-ed.
  final Money delta;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) =>
      s.correctionPosted(amount: delta.format(alwaysShowSign: true));
}

/// 422 `BREAK_ALREADY_RESOLVED`.
///
/// The ledger posting dedupes on `ledger:agent-float-sync:<breakId>` but the
/// follow-up resolve does not, so this is exactly what a RETRY of a successful
/// correction returns. Treat it as "it probably went through" and re-fetch.
final class CorrectFloatAlreadyResolved extends CorrectFloatResult {
  const CorrectFloatAlreadyResolved({this.existingStatus});

  final BreakStatus? existingStatus;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => s.correctionAlreadyResolved;
}

/// 422 `NOTHING_TO_CORRECT` - the stored delta is null or zero.
final class CorrectFloatNothingToCorrect extends CorrectFloatResult {
  const CorrectFloatNothingToCorrect();

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => s.correctionNothingToCorrect;
}

/// 422 `CORRECTION_NOT_ALLOWED` - not an agent float mismatch, or gone - or a
/// local guard that never left the device.
final class CorrectFloatRejected extends CorrectFloatResult {
  const CorrectFloatRejected._({required this.reason, this.serverMessage});

  /// The server refused and said why, in its own words.
  const CorrectFloatRejected.server(String message)
      : this._(reason: CorrectFloatRejection.server, serverMessage: message);

  /// The correction note was empty.
  const CorrectFloatRejected.noteRequired()
      : this._(reason: CorrectFloatRejection.correctionNoteRequired);

  /// The break has not finished loading.
  const CorrectFloatRejected.stillLoading()
      : this._(reason: CorrectFloatRejection.breakStillLoading);

  /// The break is not an agent float mismatch.
  const CorrectFloatRejected.notFloatMismatch()
      : this._(reason: CorrectFloatRejection.onlyFloatMismatchCorrectable);

  /// Another write on this break is still running.
  const CorrectFloatRejected.busy()
      : this._(reason: CorrectFloatRejection.anotherActionRunning);

  final CorrectFloatRejection reason;

  /// Only set for [CorrectFloatRejection.server]. An empty envelope sentence
  /// falls back to the catalogue rather than to a blank snackbar.
  final String? serverMessage;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) => switch (reason) {
        CorrectFloatRejection.server => (serverMessage?.isEmpty ?? true)
            ? s.errorRequestFailed
            : serverMessage!,
        CorrectFloatRejection.correctionNoteRequired => s.correctionNoteRequired,
        CorrectFloatRejection.breakStillLoading => s.breakStillLoading,
        CorrectFloatRejection.onlyFloatMismatchCorrectable =>
          s.onlyFloatMismatchCorrectable,
        CorrectFloatRejection.anotherActionRunning => s.anotherActionRunning,
      };
}

/// Anything else, including the opaque 500 a ledger refusal produces.
final class CorrectFloatFailed extends CorrectFloatResult {
  const CorrectFloatFailed(this.error);

  final ApiError error;

  /// A ledger refusal reaches the client as `INTERNAL_ERROR` with nothing but a
  /// correlation id, so the id is the whole actionable artefact.
  bool get isOpaqueLedgerRefusal =>
      error is ApiServerError && error.code == ApiErrorCodes.internalError;

  @override
  bool get shouldRefresh => true;

  @override
  String userMessage(AppStrings s) {
    if (!isOpaqueLedgerRefusal) {
      return error.userMessage(s);
    }
    return s.ledgerRefusedCorrection(
      reference: error.correlationId ?? s.correlationIdFallback,
    );
  }
}
