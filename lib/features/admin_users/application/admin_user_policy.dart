import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/admin_user_error_codes.dart';

/// Whether a control may be used, and if not, why - in words an operator can
/// act on.
///
/// The server is always the real gate. This exists so a button that will be
/// refused is disabled with an explanation instead of failing after a round
/// trip, and so the refusal reads the same before and after the request.
sealed class AdminActionGate {
  const AdminActionGate();

  const factory AdminActionGate.allowed() = AdminActionAllowed;

  const factory AdminActionGate.blocked({
    required String code,
    required String reason,
  }) = AdminActionBlocked;

  bool get isAllowed;

  bool get isBlocked => !isAllowed;

  /// Null when allowed.
  String? get reason;

  /// The wire-style code this gate mirrors, or null when allowed.
  String? get code;
}

final class AdminActionAllowed extends AdminActionGate {
  const AdminActionAllowed();

  @override
  bool get isAllowed => true;

  @override
  String? get reason => null;

  @override
  String? get code => null;
}

final class AdminActionBlocked extends AdminActionGate {
  const AdminActionBlocked({required this.code, required this.reason});

  @override
  final String code;

  @override
  final String reason;

  @override
  bool get isAllowed => false;
}

/// Client-side mirror of the backend's staff-administration rules.
///
/// Three rules, all of them load-bearing:
///
///  1. Reading the directory needs [AdminCapability.viewAdminUsers]; every write
///     needs [AdminCapability.manageAdminUsers]. On the server those map to
///     `ADMIN_READER_ROLES` (SUPER_ADMIN, FINANCE_ADMIN) and
///     `ADMIN_MANAGER_ROLES` (SUPER_ADMIN).
///  2. NOBODY MAY DEACTIVATE OR DEMOTE THEMSELVES - not because it is dangerous
///     in itself, but because it is the fastest way to remove the only person
///     who could undo it.
///  3. THE LAST ACTIVE SUPER ADMINISTRATOR CANNOT BE REMOVED. The server checks
///     this inside the write transaction; the client can only check it when it
///     has the whole unfiltered directory loaded, so this gate is advisory.
///
/// Every method here is pure, which is why it is unit tested.
abstract final class AdminUserPolicy {
  /// Client-only code for "your role cannot do this".
  static const String insufficientRoleCode = 'INSUFFICIENT_ROLE';

  /// How long a deactivation takes to be fully in force.
  ///
  /// `AdminIdentityService` caches Telegram-id lookups for 60 seconds. The write
  /// invalidates the entry, but any replica that already answered from cache
  /// keeps the previous answer until it expires.
  static const Duration identityCacheTtl = Duration(seconds: 60);

  static const AdminActionGate _allowed = AdminActionAllowed();

  /// May the caller open the staff directory at all?
  static AdminActionGate gateViewDirectory(AdminRole? actorRole, AppStrings s) {
    if (AdminRoles.can(actorRole, AdminCapability.viewAdminUsers)) {
      return _allowed;
    }
    return AdminActionBlocked(
      code: insufficientRoleCode,
      reason: s.gateViewDirectoryReason,
    );
  }

  /// May the caller create, edit, deactivate or set ceilings?
  static AdminActionGate gateManage(AdminRole? actorRole, AppStrings s) {
    if (AdminRoles.can(actorRole, AdminCapability.manageAdminUsers)) {
      return _allowed;
    }
    return AdminActionBlocked(
      code: insufficientRoleCode,
      reason: s.gateManageReason,
    );
  }

  /// May the caller add somebody to the directory?
  static AdminActionGate gateCreate(AdminRole? actorRole, AppStrings s) =>
      gateManage(actorRole, s);

  /// May the caller change approval ceilings?
  static AdminActionGate gateManageLimits(AdminRole? actorRole, AppStrings s) =>
      gateManage(actorRole, s);

  /// True when the patch touches authority, which is what the server's
  /// self-modification guard reacts to. A no-op (setting the same value) does
  /// NOT count - the server compares against the stored row too.
  static bool changesAuthority({
    required AdminUserView target,
    AdminRole? newRole,
    bool? newIsActive,
  }) =>
      (newRole != null && newRole != target.role) ||
      (newIsActive != null && newIsActive != target.isActive);

  /// The full gate for a patch of [target].
  ///
  /// [actorAdminUserId] is the signed-in administrator's own id, taken from the
  /// session. [knownActiveSuperAdmins] is the number of active super
  /// administrators the client can actually see - pass null whenever the
  /// directory is filtered or only partly loaded, and the last-super-admin rule
  /// is left to the server.
  static AdminActionGate gateUpdate({
    required AdminRole? actorRole,
    required String? actorAdminUserId,
    required AdminUserView target,
    required AppStrings strings,
    AdminRole? newRole,
    bool? newIsActive,
    int? knownActiveSuperAdmins,
  }) {
    final AdminActionGate manage = gateManage(actorRole, strings);
    if (manage.isBlocked) {
      return manage;
    }

    final bool touchesAuthority = changesAuthority(
      target: target,
      newRole: newRole,
      newIsActive: newIsActive,
    );

    if (touchesAuthority &&
        actorAdminUserId != null &&
        actorAdminUserId == target.id) {
      return AdminActionBlocked(
        code: AdminUserErrorCodes.adminSelfModification,
        reason: strings.gateSelfModificationReason,
      );
    }

    if (_wouldRemoveLastSuperAdmin(
      target: target,
      newRole: newRole,
      newIsActive: newIsActive,
      knownActiveSuperAdmins: knownActiveSuperAdmins,
    )) {
      return AdminActionBlocked(
        code: AdminUserErrorCodes.adminLastSuperAdmin,
        reason: strings.gateLastSuperAdminReason,
      );
    }

    return _allowed;
  }

  /// Gate for the deactivate button. Deactivation is `isActive: false`, so it
  /// runs through exactly the same rules as any other authority change.
  static AdminActionGate gateDeactivate({
    required AdminRole? actorRole,
    required String? actorAdminUserId,
    required AdminUserView target,
    required AppStrings strings,
    int? knownActiveSuperAdmins,
  }) {
    final AdminActionGate manage = gateManage(actorRole, strings);
    if (manage.isBlocked) {
      return manage;
    }
    if (!target.isActive) {
      return AdminActionBlocked(
        code: 'ALREADY_DEACTIVATED',
        reason: strings.gateAlreadyDeactivated,
      );
    }
    return gateUpdate(
      actorRole: actorRole,
      actorAdminUserId: actorAdminUserId,
      target: target,
      strings: strings,
      newIsActive: false,
      knownActiveSuperAdmins: knownActiveSuperAdmins,
    );
  }

  /// Gate for the reactivate button. Turning somebody back ON can never remove
  /// the last super administrator, so only role and self-modification apply.
  static AdminActionGate gateReactivate({
    required AdminRole? actorRole,
    required String? actorAdminUserId,
    required AdminUserView target,
    required AppStrings strings,
  }) {
    final AdminActionGate manage = gateManage(actorRole, strings);
    if (manage.isBlocked) {
      return manage;
    }
    if (target.isActive) {
      return AdminActionBlocked(
        code: 'ALREADY_ACTIVE',
        reason: strings.gateAlreadyActive,
      );
    }
    return gateUpdate(
      actorRole: actorRole,
      actorAdminUserId: actorAdminUserId,
      target: target,
      strings: strings,
      newIsActive: true,
    );
  }

  /// Roles a super administrator may assign. All of them - the backend accepts
  /// any `AdminRole` and enforces the last-super-admin rule separately.
  static List<AdminRole> assignableRoles(AdminRole? actorRole) =>
      AdminRoles.can(actorRole, AdminCapability.manageAdminUsers)
          ? AdminRoles.all
          : const <AdminRole>[];

  /// Whether losing this role/activation would remove the last way back in.
  static bool _wouldRemoveLastSuperAdmin({
    required AdminUserView target,
    required AdminRole? newRole,
    required bool? newIsActive,
    required int? knownActiveSuperAdmins,
  }) {
    if (knownActiveSuperAdmins == null) {
      return false; // The client cannot see the whole directory; server decides.
    }
    if (!target.isSuperAdmin || !target.isActive) {
      return false;
    }
    final bool losesSuperAdmin =
        (newRole != null && newRole != AdminRole.superAdmin) ||
            newIsActive == false;
    return losesSuperAdmin && knownActiveSuperAdmins <= 1;
  }
}
