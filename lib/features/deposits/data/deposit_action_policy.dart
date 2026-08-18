import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// The five admin actions `DepositAdminController` exposes for one deposit.
enum DepositAction {
  claim,
  release,
  approve,
  reject,
  retryCredit;

  /// Button label in the active language.
  String label(AppStrings s) => switch (this) {
        DepositAction.claim => s.actionClaim,
        DepositAction.release => s.actionRelease,
        DepositAction.approve => s.actionApprove,
        DepositAction.reject => s.actionReject,
        DepositAction.retryCredit => s.actionRetryCredit,
      };

  /// One-line explanation of what firing this action does.
  String description(AppStrings s) => switch (this) {
        DepositAction.claim => s.actionClaimDescription,
        DepositAction.release => s.actionReleaseDescription,
        DepositAction.approve => s.actionApproveDescription,
        DepositAction.reject => s.actionRejectDescription,
        DepositAction.retryCredit => s.actionRetryCreditDescription,
      };

  StatusTone get tone => switch (this) {
        DepositAction.approve => StatusTone.approve,
        DepositAction.reject => StatusTone.reject,
        DepositAction.retryCredit => StatusTone.failed,
        DepositAction.claim => StatusTone.info,
        DepositAction.release => StatusTone.neutral,
      };

  /// True when firing this action moves money or is otherwise irreversible, so
  /// the UI must confirm before firing.
  bool get isDestructive => switch (this) {
        DepositAction.approve ||
        DepositAction.reject ||
        DepositAction.retryCredit =>
          true,
        DepositAction.claim || DepositAction.release => false,
      };
}

/// Why an action that is legal from the current status is still not offered.
enum DepositActionBlock {
  /// The signed-in role is not in the route's `@AdminAuth(...)` set.
  role,

  /// Another reviewer holds a claim younger than [DepositActionPolicy.claimTtl].
  claimedByOther,

  /// `release` only succeeds for the admin who holds the claim; releasing
  /// somebody else's claim is a silent server-side no-op.
  notClaimHolder,
}

/// One offerable action plus whether it can actually be fired right now.
class DepositActionOption {
  const DepositActionOption({
    required this.action,
    required this.enabled,
    this.block,
    this.blockReason,
  });

  final DepositAction action;

  /// False means "show it greyed out with [blockReason]", not "hide it".
  final bool enabled;

  final DepositActionBlock? block;

  /// Human sentence explaining [block]. Null when [enabled].
  final String? blockReason;

  @override
  String toString() =>
      'DepositActionOption(${action.name}, enabled=$enabled, block=${block?.name})';
}

/// The legal-transition map, encoded once.
///
/// Derived from `ALLOWED_TRANSITIONS` plus each service's `from` set, so the
/// console never offers an action the server will refuse:
///
/// | status                    | legal admin actions                  |
/// |---------------------------|--------------------------------------|
/// | DRAFT / AWAITING_PROOF    | none (sweep only)                    |
/// | SUBMITTED                 | claim (broken), approve, reject       |
/// | UNDER_REVIEW              | claim (broken), release, approve, reject |
/// | PENDING_SECOND_APPROVAL   | approve, reject                      |
/// | APPROVED / CREDITING      | none (worker only)                   |
/// | CREDIT_FAILED             | retry credit (broken)                |
/// | NEEDS_RECONCILIATION      | retry credit (broken)                |
/// | CREDITED/REJECTED/EXPIRED/REVERSED | none (terminal)             |
///
/// "(broken)" means the route's `from` set is what the SERVICE declares, but the
/// server cannot honour it today: `DepositStateMachine.transition` asserts
/// legality for every candidate before touching the row, and one candidate is
/// missing from `ALLOWED_TRANSITIONS`, so the call answers 500 `INTERNAL_ERROR`
/// whatever the row's real status is.
///
/// * claim needs an UNDER_REVIEW -> UNDER_REVIEW self-edge, which does not exist;
/// * retry credit needs NEEDS_RECONCILIATION -> APPROVED, which does not exist.
///
/// The actions are still OFFERED, because the table describes the CONTRACT and
/// both become reachable the moment the backend adds the missing edges. What
/// changes is the copy: `DepositActionReport` names the defect instead of
/// telling the operator to quote a correlation id to support. Nothing is
/// blocked by this - the claim is advisory, and approve/reject work without it.
abstract final class DepositActionPolicy {
  /// `REVIEW_CLAIM_MINUTES = 10`. A claim older than this is stealable by
  /// anyone and is released by the sweep.
  static const Duration claimTtl = Duration(minutes: 10);

  /// Statuses each action's service accepts as its `from` set.
  static const Map<DepositAction, Set<DepositStatus>> legalFrom =
      <DepositAction, Set<DepositStatus>>{
    DepositAction.claim: <DepositStatus>{
      DepositStatus.submitted,
      DepositStatus.underReview,
    },
    DepositAction.release: <DepositStatus>{DepositStatus.underReview},
    DepositAction.approve: <DepositStatus>{
      DepositStatus.submitted,
      DepositStatus.underReview,
      DepositStatus.pendingSecondApproval,
    },
    DepositAction.reject: <DepositStatus>{
      DepositStatus.submitted,
      DepositStatus.underReview,
      DepositStatus.pendingSecondApproval,
    },
    DepositAction.retryCredit: <DepositStatus>{
      DepositStatus.creditFailed,
      DepositStatus.needsReconciliation,
    },
  };

  /// The capability mirroring the route's `@AdminAuth(...)` decorator.
  ///
  /// claim/release/approve/reject are `DECIDE_ROLES`
  /// (SUPER_ADMIN, FINANCE_ADMIN, REVIEWER) == [AdminCapability.reviewDeposit].
  /// retry-credit is `MAINTENANCE_ROLES` (SUPER_ADMIN, FINANCE_ADMIN) ==
  /// [AdminCapability.retryCredit]; REVIEWER is deliberately excluded there
  /// even though it may approve.
  static AdminCapability capabilityFor(DepositAction action) =>
      switch (action) {
        DepositAction.claim ||
        DepositAction.release ||
        DepositAction.approve ||
        DepositAction.reject =>
          AdminCapability.reviewDeposit,
        DepositAction.retryCredit => AdminCapability.retryCredit,
      };

  static bool isLegalFrom(DepositAction action, DepositStatus status) =>
      legalFrom[action]?.contains(status) ?? false;

  /// Every action legal from [status], in the order a reviewer works.
  static List<DepositAction> legalActionsFor(DepositStatus status) =>
      DepositAction.values
          .where((DepositAction action) => isLegalFrom(action, status))
          .toList(growable: false);

  /// True when [reviewStartedAt] is a claim that has not yet gone stale.
  static bool claimIsFresh(DateTime? reviewStartedAt, DateTime now) {
    if (reviewStartedAt == null) {
      return false;
    }
    return now.difference(reviewStartedAt) < claimTtl;
  }

  /// Whole minutes left on a fresh claim, or null when there is no fresh claim.
  static int? claimMinutesRemaining(DateTime? reviewStartedAt, DateTime now) {
    if (!claimIsFresh(reviewStartedAt, now)) {
      return null;
    }
    final Duration left = claimTtl - now.difference(reviewStartedAt!);
    final int minutes = left.inMinutes;
    return minutes < 1 ? 1 : minutes;
  }

  /// The action list for one deposit, already gated on role and claim state.
  ///
  /// Actions illegal from [status] are ABSENT. Actions that are legal but that
  /// this admin cannot fire right now are present with `enabled: false` and a
  /// [DepositActionOption.blockReason], so the UI explains instead of hiding.
  ///
  /// The SERVER is still authoritative - a 403/422 must be handled regardless.
  static List<DepositActionOption> resolve({
    required DepositStatus status,
    required AdminRole? role,
    required DateTime now,
    required AppStrings strings,
    String? currentAdminUserId,
    String? decidedByAdminId,
    DateTime? reviewStartedAt,
  }) {
    final List<DepositActionOption> options = <DepositActionOption>[];

    for (final DepositAction action in legalActionsFor(status)) {
      if (!AdminRoles.can(role, capabilityFor(action))) {
        options.add(
          DepositActionOption(
            action: action,
            enabled: false,
            block: DepositActionBlock.role,
            blockReason: action == DepositAction.retryCredit
                ? strings.blockOnlyFinanceAdminRetry
                : strings.blockRoleCannotDecide,
          ),
        );
        continue;
      }

      final bool heldByMe = decidedByAdminId != null &&
          currentAdminUserId != null &&
          decidedByAdminId == currentAdminUserId;
      final bool freshClaim = claimIsFresh(reviewStartedAt, now);

      if (action == DepositAction.claim && freshClaim && !heldByMe) {
        final int? minutes = claimMinutesRemaining(reviewStartedAt, now);
        options.add(
          DepositActionOption(
            action: action,
            enabled: false,
            block: DepositActionBlock.claimedByOther,
            blockReason: minutes == null
                ? strings.blockClaimedByOtherUnknown
                : strings.blockClaimedByOther(minutes: minutes),
          ),
        );
        continue;
      }

      if (action == DepositAction.release && !heldByMe) {
        options.add(
          DepositActionOption(
            action: action,
            enabled: false,
            block: DepositActionBlock.notClaimHolder,
            blockReason: strings.blockNotClaimHolder,
          ),
        );
        continue;
      }

      options.add(DepositActionOption(action: action, enabled: true));
    }

    return List<DepositActionOption>.unmodifiable(options);
  }

  /// One line explaining why a deposit offers nothing at all.
  static String idleReasonFor(DepositStatus status, AppStrings s) =>
      switch (status) {
        DepositStatus.draft ||
        DepositStatus.awaitingProof =>
          s.idleNotSubmittedYet,
        DepositStatus.approved => s.idleApproved,
        DepositStatus.crediting => s.idleCrediting,
        DepositStatus.credited => s.idleCredited,
        DepositStatus.rejected => s.idleRejected,
        DepositStatus.expired => s.idleExpired,
        DepositStatus.reversed => s.idleReversed,
        DepositStatus.submitted ||
        DepositStatus.underReview ||
        DepositStatus.pendingSecondApproval ||
        DepositStatus.creditFailed ||
        DepositStatus.needsReconciliation =>
          s.idleNoActionForRole,
      };
}
