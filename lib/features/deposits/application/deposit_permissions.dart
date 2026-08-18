import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';

/// What the signed-in admin may do on the deposit surface, plus WHO they are -
/// the claim rules need the admin's own id to tell "my claim" from "someone
/// else's claim".
///
/// These gates only hide buttons an admin cannot press. The SERVER is always
/// authoritative: the role is re-read from the database on every request (60s
/// cache), so a demoted admin starts failing within a minute regardless of what
/// this object says.
class DepositPermissions {
  const DepositPermissions({this.role, this.adminUserId});

  final AdminRole? role;

  /// `AdminSession.adminUserId` - compared against
  /// `AdminDepositView.decidedByAdminId` to decide claim ownership.
  final String? adminUserId;

  /// QUEUE_ROLES: all five roles may read the queue, the detail and the proofs.
  bool get canViewQueue =>
      AdminRoles.can(role, AdminCapability.viewDepositQueue);

  /// DECIDE_ROLES: SUPER_ADMIN, FINANCE_ADMIN, REVIEWER.
  bool get canDecide => AdminRoles.can(role, AdminCapability.reviewDeposit);

  /// MAINTENANCE_ROLES: SUPER_ADMIN, FINANCE_ADMIN. REVIEWER is excluded here
  /// even though it may approve.
  bool get canRetryCredit => AdminRoles.can(role, AdminCapability.retryCredit);

  /// `POST maintenance/sweep` carries the same MAINTENANCE_ROLES guard.
  bool get canRunSweep => canRetryCredit;

  /// Whether the route guard for [action] admits this role.
  bool canFire(DepositAction action) =>
      AdminRoles.can(role, DepositActionPolicy.capabilityFor(action));

  /// True when [decidedByAdminId] is this admin - i.e. the claim is mine, so
  /// release is a real operation rather than a silent no-op.
  bool holdsClaim(String? decidedByAdminId) {
    final String? me = adminUserId;
    return me != null && decidedByAdminId != null && decidedByAdminId == me;
  }
}

/// Capabilities of the current session, recomputed whenever it changes.
final Provider<DepositPermissions> depositPermissionsProvider =
    Provider<DepositPermissions>((ref) {
  final AdminSession? session = ref.watch(currentSessionProvider);
  return DepositPermissions(
    role: session?.role,
    adminUserId: session?.adminUserId,
  );
});
