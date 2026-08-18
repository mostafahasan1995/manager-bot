import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/application/deposit_action_report.dart';
import 'package:manager_bot/features/deposits/application/deposit_queue_controller.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_repository.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';
import 'package:manager_bot/features/deposits/data/review_outcome.dart';

/// One deposit, plus whatever the last action reported.
class DepositDetailState {
  const DepositDetailState({
    required this.deposit,
    this.pendingAction,
    this.lastReport,
    this.staleWarning,
  });

  final AdminDepositView deposit;

  /// The action currently in flight, so the UI can disable exactly one button
  /// and spin exactly one indicator.
  final DepositAction? pendingAction;

  /// Result of the most recent action, kept for a persistent banner.
  final DepositActionReport? lastReport;

  /// Set when an action succeeded but the follow-up re-read failed, so the
  /// screen can say "this is what we last saw" instead of quietly lying.
  final String? staleWarning;

  bool get isActing => pendingAction != null;

  DepositDetailState copyWith({
    AdminDepositView? deposit,
    DepositAction? pendingAction,
    DepositActionReport? lastReport,
    String? staleWarning,
    bool clearPendingAction = false,
    bool clearLastReport = false,
    bool clearStaleWarning = false,
  }) =>
      DepositDetailState(
        deposit: deposit ?? this.deposit,
        pendingAction:
            clearPendingAction ? null : (pendingAction ?? this.pendingAction),
        lastReport: clearLastReport ? null : (lastReport ?? this.lastReport),
        staleWarning:
            clearStaleWarning ? null : (staleWarning ?? this.staleWarning),
      );
}

/// One deposit's detail and its five actions, keyed by the human `shortId` the
/// router carries.
///
/// RESOLUTION: no admin endpoint addresses a deposit by `shortId`, so the
/// screen's shortId is resolved through the queue's exact-match `shortId`
/// filter (which returns the identical, fully populated `AdminDepositView`),
/// and the resulting UUID is then used for the detail route and every action.
///
/// RECONCILIATION: nothing here is optimistic. After every action the deposit
/// is re-read from `GET /v1/admin/deposits/{id}` and the queue row is patched
/// with that server truth.
class DepositDetailController
    extends AutoDisposeFamilyAsyncNotifier<DepositDetailState, String> {
  String? _depositId;

  /// The resolved UUID, once known. Actions are addressed by this, never by the
  /// shortId.
  String? get depositId => _depositId;

  @override
  Future<DepositDetailState> build(String shortId) async {
    final DepositRepository repository = ref.read(depositRepositoryProvider);

    final String? knownId = _depositId;
    if (knownId != null) {
      return DepositDetailState(deposit: await repository.detailById(knownId));
    }

    final AdminDepositView? found = await repository.findByShortId(shortId);
    if (found == null) {
      throw ApiNotFound(
        code: DepositErrorCodes.depositNotFound,
        message: ref.read(stringsProvider).detailNotFound(shortId: shortId),
        statusCode: 404,
      );
    }
    _depositId = found.id;
    return DepositDetailState(deposit: found);
  }

  /// Re-reads the deposit, keeping the current one on screen while it runs.
  Future<void> refresh() async {
    final DepositDetailState? current = state.valueOrNull;
    final String? id = _depositId;
    if (current == null || id == null) {
      ref.invalidateSelf();
      return;
    }
    try {
      final AdminDepositView fresh =
          await ref.read(depositRepositoryProvider).detailById(id);
      _publish(current.copyWith(deposit: fresh, clearStaleWarning: true), fresh);
    } on Object catch (error, stackTrace) {
      AppLogger.warn('Refreshing deposit $id failed: $error', scope: 'deposits');
      state = AsyncError<DepositDetailState>(error, stackTrace)
          .copyWithPrevious(state);
    }
  }

  void clearReport() {
    final DepositDetailState? current = state.valueOrNull;
    if (current?.lastReport == null) {
      return;
    }
    state = AsyncData<DepositDetailState>(current!.copyWith(clearLastReport: true));
  }

  /// Takes the 10-minute advisory claim.
  ///
  /// Safe to repeat: re-claiming your own claim succeeds, and a claim older
  /// than 10 minutes is stealable.
  Future<DepositActionReport> claim() => _runReview(
        DepositAction.claim,
        (DepositRepository repository, String id) => repository.claim(id),
      );

  /// Hands the claim back. A silent no-op server-side unless you hold it.
  Future<DepositActionReport> release() => _runReview(
        DepositAction.release,
        (DepositRepository repository, String id) => repository.release(id),
      );

  /// Approves, optionally correcting the amount.
  ///
  /// Omitting [verifiedAmount] records "the claim is what I verified". May
  /// legitimately come back as `awaiting_second_approval`: whether four eyes
  /// are needed depends on the admin's approval limits, which no client can
  /// see in advance.
  Future<DepositActionReport> approve({Money? verifiedAmount, String? note}) =>
      _runReview(
        DepositAction.approve,
        (DepositRepository repository, String id) => repository.approve(
          id,
          verifiedAmount: verifiedAmount,
          note: note,
        ),
      );

  /// Rejects with a machine-countable code and an optional note.
  Future<DepositActionReport> reject({
    required RejectionCode code,
    String? note,
  }) =>
      _runReview(
        DepositAction.reject,
        (DepositRepository repository, String id) =>
            repository.reject(id, code: code, note: note),
      );

  /// Re-runs a failed credit.
  ///
  /// Does not return a [ReviewOutcome] - the route answers
  /// `{requeued, creditKeyEpoch}` - so it builds its own report. Expect the
  /// documented backend defect (500 INTERNAL_ERROR) rather than the declared
  /// 202; that is reported as a server fault, not as a bad request.
  Future<DepositActionReport> retryCredit({String? reason}) async {
    const DepositAction action = DepositAction.retryCredit;
    final AppStrings s = ref.read(stringsProvider);
    final DepositDetailState? current = state.valueOrNull;
    final String? id = _depositId;
    if (current == null || id == null || current.isActing) {
      return DepositActionFailed(
        action: action,
        message: s.detailStillLoading,
        error: StateError('deposit not resolved'),
      );
    }

    state = AsyncData<DepositDetailState>(
      current.copyWith(pendingAction: action, clearLastReport: true),
    );

    DepositActionReport report;
    try {
      final RetryCreditResult result = await ref
          .read(depositRepositoryProvider)
          .retryCredit(id, reason: reason);
      report = result.requeued
          ? DepositActionSucceeded(
              action: action,
              message: s.retryCreditRequeued,
              outcome: const ReviewUnknown(kind: 'retry_credit'),
              detail: s.retryCreditEpochDetail(epoch: result.creditKeyEpoch),
            )
          : DepositActionAlreadyHandled(
              action: action,
              message:
                  s.retryCreditNotRequeued(epoch: result.creditKeyEpoch),
            );
    } on Object catch (error) {
      report = DepositActionReport.fromError(action, error, s);
    }

    await _settle(report);
    return report;
  }

  /// Shared body of the four `ReviewOutcome` actions.
  Future<DepositActionReport> _runReview(
    DepositAction action,
    Future<ReviewOutcome> Function(DepositRepository repository, String id) call,
  ) async {
    final AppStrings s = ref.read(stringsProvider);
    final DepositDetailState? current = state.valueOrNull;
    final String? id = _depositId;
    if (current == null || id == null) {
      return DepositActionFailed(
        action: action,
        message: s.detailStillLoading,
        error: StateError('deposit not resolved'),
      );
    }
    if (current.isActing) {
      return DepositActionFailed(
        action: action,
        message: s.detailActionInFlight,
        error: StateError('action already in flight'),
      );
    }

    // Refuse locally what the server would refuse anyway, so an impossible
    // action can never be fired by a stale screen.
    if (!DepositActionPolicy.isLegalFrom(action, current.deposit.status)) {
      return DepositActionAlreadyHandled(
        action: action,
        message: s.detailIllegalAction(
          status: current.deposit.status.label(s),
          action: action.label(s),
        ),
        status: current.deposit.status,
      );
    }

    state = AsyncData<DepositDetailState>(
      current.copyWith(pendingAction: action, clearLastReport: true),
    );

    DepositActionReport report;
    try {
      final ReviewOutcome outcome =
          await call(ref.read(depositRepositoryProvider), id);
      report = DepositActionReport.fromOutcome(action, outcome, s);
    } on Object catch (error) {
      report = DepositActionReport.fromError(action, error, s);
    }

    await _settle(report);
    return report;
  }

  /// Re-reads the deposit from the server and publishes it with [report].
  ///
  /// Runs after EVERY action, success or not: an "already handled" answer means
  /// the row moved, and a refusal may still have been preceded by a change.
  Future<void> _settle(DepositActionReport report) async {
    final DepositDetailState? current = state.valueOrNull;
    final String? id = _depositId;
    if (current == null || id == null) {
      return;
    }

    try {
      final AdminDepositView fresh =
          await ref.read(depositRepositoryProvider).detailById(id);
      _publish(
        current.copyWith(
          deposit: fresh,
          lastReport: report,
          clearPendingAction: true,
          clearStaleWarning: true,
        ),
        fresh,
      );
    } on Object catch (error) {
      // The action itself already resolved; failing to re-read must not turn a
      // completed approval into an error screen.
      AppLogger.warn(
        'Re-reading deposit $id after ${report.action.name} failed: $error',
        scope: 'deposits',
      );
      state = AsyncData<DepositDetailState>(
        current.copyWith(
          lastReport: report,
          clearPendingAction: true,
          staleWarning: ref.read(stringsProvider).detailStaleWarning,
        ),
      );
    }
  }

  /// Publishes [next] and mirrors the server truth into the queue row.
  void _publish(DepositDetailState next, AdminDepositView fresh) {
    state = AsyncData<DepositDetailState>(next);
    ref.read(depositQueueProvider.notifier).reconcile(fresh);
  }
}

/// The detail of one deposit, keyed by the `shortId` from the route.
///
/// Auto-disposed: a review console must never show a cached decision, and proof
/// bytes should not outlive the screen.
final AutoDisposeAsyncNotifierProviderFamily<DepositDetailController,
        DepositDetailState, String> depositDetailProvider =
    AsyncNotifierProvider.autoDispose
        .family<DepositDetailController, DepositDetailState, String>(
  DepositDetailController.new,
);
