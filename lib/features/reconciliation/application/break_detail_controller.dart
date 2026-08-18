import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/reconciliation/application/break_list_controller.dart';
import 'package:manager_bot/features/reconciliation/data/break_action_result.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/data/reconciliation_repository.dart';

/// One break, plus the three writes that can be performed on it.
///
/// Every action RETURNS its outcome instead of throwing: "somebody already
/// closed it" and "the ledger refused" are answers a reviewer needs to read,
/// not crashes. The screen switches on the returned sealed value and the state
/// here is already up to date by the time it does.
class BreakDetailController
    extends AutoDisposeFamilyAsyncNotifier<BreakView, String> {
  bool _busy = false;

  /// True while an action is in flight; the screen disables its buttons on it.
  bool get isBusy => _busy;

  @override
  Future<BreakView> build(String arg) {
    return ref.read(reconciliationRepositoryProvider).breakById(arg);
  }

  /// Re-reads the break. Used after a correction, which does not return the
  /// updated row, and after any "already handled" answer.
  Future<void> reload() async {
    state = await AsyncValue.guard<BreakView>(
      () => ref.read(reconciliationRepositoryProvider).breakById(arg),
    );
  }

  /// Take ownership: assignee becomes the caller, status becomes INVESTIGATING.
  ///
  /// Refuses locally for a terminal break: the endpoint has NO guard and would
  /// happily re-open a closed break while leaving its resolution fields in
  /// place, producing an INVESTIGATING row that still carries a resolution note.
  Future<BreakActionResult> assign() async {
    final BreakView? current = state.valueOrNull;
    if (current != null && !current.canAssign) {
      return BreakActionRejected.wouldReopen(current.status);
    }
    return _run(() => ref.read(reconciliationRepositoryProvider).assign(arg));
  }

  /// Close the break with a terminal status and a mandatory note.
  Future<BreakActionResult> resolve({
    required BreakStatus status,
    required String note,
  }) {
    return _run(
      () => ref.read(reconciliationRepositoryProvider).resolve(
            id: arg,
            status: status,
            note: note,
          ),
    );
  }

  /// Post a ledger correction for an agent-float mismatch and auto-resolve it.
  ///
  /// The response carries no break, so the break is re-fetched on every outcome
  /// that changed something - including `BREAK_ALREADY_RESOLVED`, which after a
  /// timeout means the correction most likely went through.
  Future<CorrectFloatResult> correctFloat({required String note}) async {
    final BreakView? current = state.valueOrNull;
    if (current == null) {
      return const CorrectFloatRejected.stillLoading();
    }
    if (!current.category.supportsFloatCorrection) {
      return const CorrectFloatRejected.notFloatMismatch();
    }
    if (!current.hasDrift) {
      return const CorrectFloatNothingToCorrect();
    }
    if (_busy) {
      return const CorrectFloatRejected.busy();
    }
    _busy = true;
    try {
      final CorrectFloatResult result =
          await ref.read(reconciliationRepositoryProvider).correctFloat(
                breakId: arg,
                note: note,
                currencyCode: current.currencyCode,
              );
      if (result.shouldRefresh) {
        await reload();
        final BreakView? refreshed = state.valueOrNull;
        if (refreshed != null) {
          ref.read(breakListProvider.notifier).replaceBreak(refreshed);
        }
      }
      if (result is CorrectFloatFailed) {
        AppLogger.error(
          'correct-float on $arg failed: ${result.error.code}',
          scope: 'reconciliation',
          error: result.error,
        );
      }
      return result;
    } finally {
      _busy = false;
    }
  }

  Future<BreakActionResult> _run(
    Future<BreakActionResult> Function() action,
  ) async {
    if (_busy) {
      return const BreakActionRejected.busy();
    }
    _busy = true;
    try {
      final BreakActionResult result = await action();
      switch (result) {
        case BreakActionApplied(:final BreakView updated):
          state = AsyncValue<BreakView>.data(updated);
          ref.read(breakListProvider.notifier).replaceBreak(updated);
        case BreakActionAlreadyClosed():
        case BreakActionRejected():
          {
            // The server's answer contradicts what is on screen, so the truth
            // has to be re-read rather than guessed at.
            await reload();
            final BreakView? refreshed = state.valueOrNull;
            if (refreshed != null) {
              ref.read(breakListProvider.notifier).replaceBreak(refreshed);
            }
          }
        case BreakActionMissing():
          ref.read(breakListProvider.notifier).removeBreak(arg);
        case BreakActionFailed(:final ApiError error):
          AppLogger.warn(
            'Break action on $arg failed: ${error.code}',
            scope: 'reconciliation',
          );
      }
      return result;
    } finally {
      _busy = false;
    }
  }
}

final AutoDisposeAsyncNotifierProviderFamily<BreakDetailController, BreakView,
        String> breakDetailProvider =
    AsyncNotifierProvider.autoDispose
        .family<BreakDetailController, BreakView, String>(
  BreakDetailController.new,
);
