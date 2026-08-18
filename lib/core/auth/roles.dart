import 'package:manager_bot/core/i18n/app_strings.dart';

/// The backend `AdminRole` enum, exactly as it appears in schema.prisma.
///
/// Wire values are SCREAMING_SNAKE and are the ONLY thing sent or compared.
enum AdminRole {
  superAdmin('SUPER_ADMIN', 5),
  financeAdmin('FINANCE_ADMIN', 4),
  reviewer('REVIEWER', 3),
  support('SUPPORT', 2),
  viewer('VIEWER', 1);

  const AdminRole(this.wireName, this.rank);

  /// Value on the wire, e.g. `FINANCE_ADMIN`.
  final String wireName;

  /// Higher means broader. Use [AdminRoles.atLeast] rather than comparing
  /// ranks by hand - the backend gates by SET MEMBERSHIP, not by rank, and the
  /// rank is only a display/sort convenience.
  final int rank;

  /// Human label for chips and headers, in the active language.
  ///
  /// Deliberately a METHOD and not a field: the console ships Arabic and
  /// English, so a role has no single English name to bake into the enum.
  /// Widgets pass `context.s`; controllers pass `ref.read(stringsProvider)`.
  String label(AppStrings s) => switch (this) {
        AdminRole.superAdmin => s.roleSuperAdmin,
        AdminRole.financeAdmin => s.roleFinanceAdmin,
        AdminRole.reviewer => s.roleReviewer,
        AdminRole.support => s.roleSupport,
        AdminRole.viewer => s.roleViewer,
      };

  /// Parses a wire value. Returns null for an unknown string so a new backend
  /// role cannot crash the login screen.
  static AdminRole? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim().toUpperCase();
    for (final role in AdminRole.values) {
      if (role.wireName == normalized) {
        return role;
      }
    }
    return null;
  }

  /// Parses a wire value, falling back to the least-privileged role.
  static AdminRole parseOrViewer(String? raw) => tryParse(raw) ?? AdminRole.viewer;
}

/// What a screen or action needs. Gate UI on these, never on a role literal.
enum AdminCapability {
  /// See the admin deposit queue and a deposit's detail.
  viewDepositQueue,

  /// Approve / reject a deposit under review.
  reviewDeposit,

  /// Provide the SECOND approval on a deposit above the dual-control threshold.
  secondApproveDeposit,

  /// Retry a failed credit / mark a deposit for reconciliation.
  retryCredit,

  /// See reconciliation breaks and agent float.
  viewReconciliation,

  /// Move a break to INVESTIGATING / RESOLVED / WRITTEN_OFF / FALSE_POSITIVE.
  resolveReconciliationBreak,

  /// See payment methods and destinations.
  viewPaymentMethods,

  /// Create / edit / enable / disable payment destinations.
  managePaymentDestinations,

  /// See the list of admin users.
  viewAdminUsers,

  /// Create / edit / deactivate admin users and change roles.
  manageAdminUsers,

  /// Read the ledger and export.
  viewLedger,
}

/// Role sets, mirroring the backend's `@Roles(...)` guards.
///
/// SERVER IS AUTHORITATIVE. These sets exist to hide buttons an admin cannot
/// press; a 403 `INSUFFICIENT_ROLE` is still the real answer and must be
/// handled. Where the backend contract was not available to the foundation
/// phase, the set is marked ASSUMED - a feature agent that reads the real
/// controller decorator should correct it HERE, in one place.
abstract final class AdminRoles {
  /// Every role, in descending privilege order.
  static const List<AdminRole> all = <AdminRole>[
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
    AdminRole.reviewer,
    AdminRole.support,
    AdminRole.viewer,
  ];

  /// VERIFIED from the contract: `GET /v1/admin/deposits` allows all five.
  static const Set<AdminRole> readAdminSurface = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
    AdminRole.reviewer,
    AdminRole.support,
    AdminRole.viewer,
  };

  /// ASSUMED: approve/reject is a reviewer-and-up action.
  static const Set<AdminRole> depositReviewers = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
    AdminRole.reviewer,
  };

  /// ASSUMED: dual control needs a finance-grade second pair of eyes.
  static const Set<AdminRole> secondApprovers = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
  };

  /// ASSUMED: money movement and break resolution are finance actions.
  static const Set<AdminRole> financeOperators = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
  };

  /// VERIFIED from `src/modules/admin/admin.constants.ts`: `ADMIN_READER_ROLES`
  /// is `['SUPER_ADMIN', 'FINANCE_ADMIN']`, and it guards every READ of the
  /// staff directory - `GET /v1/admin/admins`, `GET /v1/admin/admins/:id` and
  /// `GET /v1/admin/admins/:adminUserId/approval-limits`.
  ///
  /// This is deliberately WIDER than [adminManagers]: a finance admin may look
  /// at who can approve what, but may not change it.
  static const Set<AdminRole> adminReaders = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
  };

  /// VERIFIED from `ADMIN_MANAGER_ROLES`: only SUPER_ADMIN administers other
  /// admins (create, patch, deactivate, set approval ceilings).
  static const Set<AdminRole> adminManagers = <AdminRole>{AdminRole.superAdmin};

  static const Map<AdminCapability, Set<AdminRole>> byCapability =
      <AdminCapability, Set<AdminRole>>{
    AdminCapability.viewDepositQueue: readAdminSurface,
    AdminCapability.reviewDeposit: depositReviewers,
    AdminCapability.secondApproveDeposit: secondApprovers,
    AdminCapability.retryCredit: financeOperators,
    AdminCapability.viewReconciliation: readAdminSurface,
    AdminCapability.resolveReconciliationBreak: financeOperators,
    AdminCapability.viewPaymentMethods: readAdminSurface,
    AdminCapability.managePaymentDestinations: financeOperators,
    AdminCapability.viewAdminUsers: adminReaders,
    AdminCapability.manageAdminUsers: adminManagers,
    AdminCapability.viewLedger: readAdminSurface,
  };

  /// The gate every widget should call.
  ///
  /// ```dart
  /// if (AdminRoles.can(session.role, AdminCapability.reviewDeposit)) ...
  /// ```
  static bool can(AdminRole? role, AdminCapability capability) {
    if (role == null) {
      return false;
    }
    return byCapability[capability]?.contains(role) ?? false;
  }

  /// True when [role] is any of [allowed]. For an ad-hoc gate that has no
  /// capability of its own yet.
  static bool isAnyOf(AdminRole? role, Set<AdminRole> allowed) =>
      role != null && allowed.contains(role);

  /// Rank-based convenience for sorting and for "at least reviewer" copy.
  /// Do NOT use it to gate an action - use [can].
  static bool atLeast(AdminRole? role, AdminRole minimum) =>
      role != null && role.rank >= minimum.rank;

  /// Capabilities a role actually has, for a "your access" panel in settings.
  static List<AdminCapability> capabilitiesOf(AdminRole? role) {
    if (role == null) {
      return const <AdminCapability>[];
    }
    return AdminCapability.values
        .where((capability) => can(role, capability))
        .toList(growable: false);
  }
}

/// Sugar so widgets read naturally: `role.can(AdminCapability.reviewDeposit)`.
extension AdminRoleCapabilities on AdminRole {
  bool can(AdminCapability capability) => AdminRoles.can(this, capability);
}
