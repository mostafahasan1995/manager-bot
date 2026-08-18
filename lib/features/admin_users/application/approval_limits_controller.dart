import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_mutation_controller.dart';
import 'package:manager_bot/features/admin_users/data/admin_users_repository.dart';
import 'package:manager_bot/features/admin_users/data/approval_limit.dart';

/// Full ceiling history for one administrator, newest first.
///
/// Not paginated - the endpoint returns a bare array. History is never
/// rewritten: setting a ceiling closes the open version and opens a new one, so
/// an old approval stays explicable by the limit that was in force at the time.
final FutureProviderFamily<List<ApprovalLimitView>, String> approvalLimitsProvider =
    FutureProvider.family<List<ApprovalLimitView>, String>(
  (ref, String adminUserId) =>
      ref.watch(adminUsersRepositoryProvider).approvalLimits(adminUserId),
);

/// What a ceiling write was trying to do.
enum ApprovalLimitAction {
  set,
  end;

  /// The button that starts this write.
  String label(AppStrings s) => switch (this) {
        ApprovalLimitAction.set => s.alSetCeilingButton,
        ApprovalLimitAction.end => s.alEndConfirmLabel,
      };

  /// The success sentence.
  String toast(AppStrings s) => switch (this) {
        ApprovalLimitAction.set => s.alSavedToast,
        ApprovalLimitAction.end => s.alEndedToast,
      };
}

/// Lifecycle of a single approval-limit write.
sealed class ApprovalLimitMutationState {
  const ApprovalLimitMutationState();

  bool get isBusy => this is ApprovalLimitMutationRunning;
}

final class ApprovalLimitMutationIdle extends ApprovalLimitMutationState {
  const ApprovalLimitMutationIdle();
}

final class ApprovalLimitMutationRunning extends ApprovalLimitMutationState {
  const ApprovalLimitMutationRunning(this.action);

  final ApprovalLimitAction action;
}

final class ApprovalLimitMutationSucceeded extends ApprovalLimitMutationState {
  const ApprovalLimitMutationSucceeded({
    required this.action,
    required this.limit,
    required this.message,
    this.notice,
  });

  final ApprovalLimitAction action;
  final ApprovalLimitView limit;

  /// Already resolved against the language in force when the write landed.
  final String message;
  final String? notice;
}

/// Two operators wrote the same ceiling in the same millisecond. Not an error
/// worth alarming about - retrying the identical request is the right answer.
final class ApprovalLimitMutationRaced extends ApprovalLimitMutationState {
  const ApprovalLimitMutationRaced(this.message);

  final String message;
}

/// The proposed ceilings cannot mean what the operator intended, and the client
/// knows it without asking.
final class ApprovalLimitMutationRejected extends ApprovalLimitMutationState {
  const ApprovalLimitMutationRejected(this.problem);

  final ApprovalLimitProblem problem;

  String message(AppStrings s) => problem.message(s);
}

final class ApprovalLimitMutationFailed extends ApprovalLimitMutationState {
  const ApprovalLimitMutationFailed({
    required this.action,
    required this.error,
    required this.message,
  });

  final ApprovalLimitAction action;
  final ApiError error;
  final String message;
}

/// Writes to approval ceilings.
///
/// A ceiling is what decides how much a person may release without a second
/// pair of eyes, so this controller refuses an incoherent configuration
/// client-side before it is ever sent, mirroring the server's own guard.
class ApprovalLimitMutationController extends Notifier<ApprovalLimitMutationState> {
  static const String _scope = 'admin_users.approval_limit';

  @override
  ApprovalLimitMutationState build() => const ApprovalLimitMutationIdle();

  void reset() => state = const ApprovalLimitMutationIdle();

  /// Supersedes the ceiling in force for (administrator, currency).
  ///
  /// Returns the new version, or null when the write did not happen - the
  /// reason is in [state].
  Future<ApprovalLimitView?> setLimit(
    String adminUserId,
    SetApprovalLimitRequest request,
  ) async {
    if (state.isBusy) {
      return null;
    }

    final ApprovalLimitProblem? problem = request.problem;
    if (problem != null) {
      state = ApprovalLimitMutationRejected(problem);
      return null;
    }

    state = const ApprovalLimitMutationRunning(ApprovalLimitAction.set);
    // No BuildContext here: the bundle comes from the locale controller.
    final AppStrings s = ref.read(stringsProvider);
    try {
      final SetApprovalLimitOutcome outcome = await ref
          .read(adminUsersRepositoryProvider)
          .setApprovalLimit(adminUserId, request);

      switch (outcome) {
        case final SetApprovalLimitApplied applied:
          AppLogger.info(
            'ceiling set for $adminUserId: single '
            '${applied.limit.maxSingleApproval.toDecimalString()} '
            '${applied.limit.currencyCode}',
            scope: _scope,
          );
          ref.invalidate(approvalLimitsProvider(adminUserId));
          state = ApprovalLimitMutationSucceeded(
            action: ApprovalLimitAction.set,
            limit: applied.limit,
            message: ApprovalLimitAction.set.toast(s),
            notice: s.alSetNotice,
          );
          return applied.limit;
        case final SetApprovalLimitRaced raced:
          AppLogger.warn(
            'ceiling write raced for $adminUserId: ${raced.error.code}',
            scope: _scope,
          );
          ref.invalidate(approvalLimitsProvider(adminUserId));
          state = ApprovalLimitMutationRaced(s.alRacedMessage);
          return null;
      }
    } on ApiError catch (error, stackTrace) {
      return _fail(ApprovalLimitAction.set, error, stackTrace, s);
    }
  }

  /// Ends a version WITHOUT replacing it.
  ///
  /// The administrator is then left with no active ceiling, which the server's
  /// evaluator reads as DENIED. This revokes authority; it never grants it.
  Future<ApprovalLimitView?> endLimit(String adminUserId, String limitId) async {
    if (state.isBusy) {
      return null;
    }
    state = const ApprovalLimitMutationRunning(ApprovalLimitAction.end);
    final AppStrings s = ref.read(stringsProvider);
    try {
      final ApprovalLimitView ended =
          await ref.read(adminUsersRepositoryProvider).endApprovalLimit(limitId);
      AppLogger.info('ceiling $limitId ended for $adminUserId', scope: _scope);
      ref.invalidate(approvalLimitsProvider(adminUserId));
      state = ApprovalLimitMutationSucceeded(
        action: ApprovalLimitAction.end,
        limit: ended,
        message: ApprovalLimitAction.end.toast(s),
        notice: s.alEndNotice(currency: ended.currencyCode),
      );
      return ended;
    } on ApiError catch (error, stackTrace) {
      return _fail(ApprovalLimitAction.end, error, stackTrace, s);
    }
  }

  Future<ApprovalLimitView?> _fail(
    ApprovalLimitAction action,
    ApiError error,
    StackTrace stackTrace,
    AppStrings s,
  ) async {
    AppLogger.error(
      '${action.name} failed: ${error.code} '
      '(correlation ${error.correlationId ?? 'unknown'})',
      scope: _scope,
      error: error,
      stackTrace: stackTrace,
    );
    state = ApprovalLimitMutationFailed(
      action: action,
      error: error,
      message: describeAdminError(error, s),
    );
    return null;
  }
}

final NotifierProvider<ApprovalLimitMutationController, ApprovalLimitMutationState>
    approvalLimitMutationProvider = NotifierProvider<ApprovalLimitMutationController,
        ApprovalLimitMutationState>(
  ApprovalLimitMutationController.new,
);

/// The version currently in force for one currency, if any.
///
/// Returns null when the administrator has no active ceiling - which is a
/// meaningful state, not a missing one: the evaluator fails closed, so no
/// active ceiling means every approval is denied.
ApprovalLimitView? activeLimitFor(
  List<ApprovalLimitView> history,
  String currencyCode,
) {
  for (final ApprovalLimitView limit in history) {
    if (limit.isInForce &&
        limit.currencyCode.toUpperCase() == currencyCode.toUpperCase()) {
      return limit;
    }
  }
  return null;
}

/// Every currency this administrator has ever had a ceiling in, newest first.
List<String> currenciesIn(List<ApprovalLimitView> history) {
  final List<String> seen = <String>[];
  for (final ApprovalLimitView limit in history) {
    final String code = limit.currencyCode.toUpperCase();
    if (!seen.contains(code)) {
      seen.add(code);
    }
  }
  return seen;
}
