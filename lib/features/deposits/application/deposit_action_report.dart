import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/review_outcome.dart';

/// What to tell the operator after an action, without ever inventing an
/// optimistic result: every report is built from what the SERVER answered.
///
/// The split that matters in a review console is between
/// [DepositActionAlreadyHandled] / [DepositActionRefused] - both completely
/// normal, both styled as information - and [DepositActionFailed], which is the
/// only variant that deserves a red error.
sealed class DepositActionReport {
  const DepositActionReport({required this.action, required this.message});

  /// Builds the report for a successful HTTP call from the returned union.
  factory DepositActionReport.fromOutcome(
    DepositAction action,
    ReviewOutcome outcome,
    AppStrings s,
  ) {
    switch (outcome) {
      case ReviewApproved(ledgerTransactionId: final String? ledgerId):
        return DepositActionSucceeded(
          action: action,
          message: s.reportApproved,
          outcome: outcome,
          detail: ledgerId == null
              ? null
              : s.reportLedgerTransaction(id: ledgerId),
        );
      case ReviewAwaitingSecondApproval():
        return DepositActionSucceeded(
          action: action,
          message: s.reportAwaitingSecondApproval,
          outcome: outcome,
        );
      case ReviewRejected():
        return DepositActionSucceeded(
          action: action,
          message: s.reportRejected,
          outcome: outcome,
        );
      case ReviewClaimed():
        return DepositActionSucceeded(
          action: action,
          message: s.reportClaimed,
          outcome: outcome,
        );
      case ReviewReleased():
        return DepositActionSucceeded(
          action: action,
          message: s.reportReleased,
          outcome: outcome,
        );
      case ReviewAlreadyHandled(status: final DepositStatus? status):
        return DepositActionAlreadyHandled(
          action: action,
          message: status == null
              ? s.reportAlreadyHandled
              : s.reportAlreadyHandledWithStatus(status: status.label(s)),
          status: status,
        );
      case ReviewUnknown(kind: final String kind):
        return DepositActionAlreadyHandled(
          action: action,
          message: s.reportUnknownOutcome(kind: kind),
        );
    }
  }

  /// Classifies a thrown [ApiError] into a refusal or a real failure.
  ///
  /// Treated as NORMAL (never a red crash):
  /// * `DEPOSIT_CLAIMED_BY_OTHER` (422) - another reviewer got there first;
  /// * any [ApiConflict] whose CAS simply lost.
  ///
  /// Treated as a domain REFUSAL the operator must read (403/422 with a
  /// business meaning): approval limits, four-eyes, verified-amount rules.
  factory DepositActionReport.fromError(
    DepositAction action,
    Object error,
    AppStrings s,
  ) {
    if (error is! ApiError) {
      return DepositActionFailed(
        action: action,
        message: s.reportActionFailed(action: action.label(s)),
        error: error,
      );
    }

    if (error.code == DepositErrorCodes.depositClaimedByOther) {
      return DepositActionAlreadyHandled(
        action: action,
        message: s.reportClaimedByOther,
      );
    }

    switch (error) {
      case final ApiConflict conflict:
        return DepositActionAlreadyHandled(
          action: action,
          message: conflict.userMessage(s),
        );
      case final ApiForbidden forbidden:
        return DepositActionRefused(
          action: action,
          message: _forbiddenMessage(forbidden, s),
          error: forbidden,
        );
      case final ApiBusinessRule businessRule:
        return DepositActionRefused(
          action: action,
          message: _businessMessage(businessRule, s),
          error: businessRule,
        );
      case final ApiNotFound notFound:
        return DepositActionRefused(
          action: action,
          message: s.reportDepositGone,
          error: notFound,
        );
      case final ApiServerError serverError:
        return DepositActionFailed(
          action: action,
          message: _serverErrorMessage(action, serverError, s),
          error: serverError,
        );
      case ApiValidation():
      case ApiUnauthorized():
      case ApiRateLimited():
      case ApiNetworkError():
      case ApiTimeout():
      case ApiUnexpected():
        return DepositActionFailed(
          action: action,
          message: error.userMessage(s),
          error: error,
        );
    }
  }

  final DepositAction action;

  /// One sentence, already safe to show in a snackbar or a banner.
  final String message;

  /// True when this outcome is business-as-usual and must NOT be styled red.
  bool get isBenign => switch (this) {
        DepositActionSucceeded() => true,
        DepositActionAlreadyHandled() => true,
        DepositActionRefused() => false,
        DepositActionFailed() => false,
      };

  /// True when the row changed under us and the UI should say so calmly.
  bool get isAlreadyHandled => this is DepositActionAlreadyHandled;

  StatusTone get tone => switch (this) {
        DepositActionSucceeded(action: final DepositAction a) => a.tone,
        DepositActionAlreadyHandled() => StatusTone.info,
        DepositActionRefused() => StatusTone.pending,
        DepositActionFailed() => StatusTone.reject,
      };

  /// Correlation id to quote to support, when the server gave one.
  String? get correlationId => switch (this) {
        DepositActionSucceeded() => null,
        DepositActionAlreadyHandled() => null,
        DepositActionRefused(error: final ApiError e) => e.correlationId,
        DepositActionFailed(error: final Object e) =>
          e is ApiError ? e.correlationId : null,
      };

  /// Names the two reproducible backend defects instead of sending the operator
  /// to support with a correlation id nobody can act on.
  ///
  /// Both have the same shape: a service asks `DepositStateMachine.transition`
  /// for a set of candidate `from` statuses, the machine asserts legality for
  /// EVERY candidate before touching the row, and one candidate is missing from
  /// `ALLOWED_TRANSITIONS`. `IllegalDepositTransitionError` is a plain `Error`,
  /// not an `AppException`, so it surfaces as 500 `INTERNAL_ERROR` whatever the
  /// row's real status is.
  ///
  /// * claim:        `[SUBMITTED, UNDER_REVIEW] -> UNDER_REVIEW`, and
  ///   `ALLOWED_TRANSITIONS[UNDER_REVIEW]` has no UNDER_REVIEW self-edge.
  /// * retry credit: `[CREDIT_FAILED, NEEDS_RECONCILIATION] -> APPROVED`, and
  ///   `ALLOWED_TRANSITIONS[NEEDS_RECONCILIATION]` does not contain APPROVED.
  ///
  /// Retrying either can never succeed, so the copy says so.
  static String _serverErrorMessage(
    DepositAction action,
    ApiServerError error,
    AppStrings s,
  ) {
    if (error.code != ApiErrorCodes.internalError) {
      return error.userMessage(s);
    }
    return switch (action) {
      DepositAction.claim => s.reportClaimBackendDefect,
      DepositAction.retryCredit => s.reportRetryCreditBackendDefect,
      DepositAction.release ||
      DepositAction.approve ||
      DepositAction.reject =>
        error.userMessage(s),
    };
  }

  static String _forbiddenMessage(ApiForbidden error, AppStrings s) =>
      switch (error.code) {
        DepositErrorCodes.adminNoApprovalLimit => s.blockRoleCannotDecide,
        DepositErrorCodes.adminLimitExceeded => s.reportAboveApprovalLimit,
        DepositErrorCodes.secondApproverMustDiffer =>
          s.reportSecondApproverMustDiffer,
        _ => error.userMessage(s),
      };

  static String _businessMessage(ApiBusinessRule error, AppStrings s) =>
      switch (error.code) {
        DepositErrorCodes.verifiedAmountRequired => error.message.isEmpty
            ? s.reportVerifiedAmountRequired
            : error.message,
        DepositErrorCodes.depositInvalidState => s.reportInvalidState,
        // An empty envelope message must not render as a blank banner: fall
        // through to the localised default rather than to `message` verbatim.
        _ => error.userMessage(s),
      };
}

/// The server did what was asked.
final class DepositActionSucceeded extends DepositActionReport {
  const DepositActionSucceeded({
    required super.action,
    required super.message,
    required this.outcome,
    this.detail,
  });

  final ReviewOutcome outcome;

  /// Secondary line, e.g. the ledger transaction id.
  final String? detail;

  /// True when the approval was parked for a second pair of eyes and NOTHING
  /// was posted to the ledger.
  bool get isAwaitingSecondApproval => outcome is ReviewAwaitingSecondApproval;
}

/// Nothing changed because somebody else got there first. A NORMAL outcome:
/// refresh the row, do not alarm.
final class DepositActionAlreadyHandled extends DepositActionReport {
  const DepositActionAlreadyHandled({
    required super.action,
    required super.message,
    this.status,
  });

  /// The status the row actually holds now, when the server said.
  final DepositStatus? status;
}

/// A domain rule refused the action. The request was fine; the answer is no.
final class DepositActionRefused extends DepositActionReport {
  const DepositActionRefused({
    required super.action,
    required super.message,
    required this.error,
  });

  final ApiError error;
}

/// A genuine failure: transport, auth, or a server defect.
final class DepositActionFailed extends DepositActionReport {
  const DepositActionFailed({
    required super.action,
    required super.message,
    required this.error,
  });

  final Object error;

  bool get isRetryable => error is ApiError && (error as ApiError).isRetryable;
}
