import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// The role sets the reconciliation controller actually declares.
///
/// These are NARROWER than the shared `AdminRoles` sets and are verified
/// against `src/modules/reconciliation/controllers/reconciliation.controller.ts`:
///
/// * `VIEW_ROLES` excludes SUPPORT, but the shared
///   `AdminCapability.viewReconciliation` maps to `readAdminSurface`, which
///   INCLUDES SUPPORT. A SUPPORT admin therefore passes the router guard and
///   then gets a 403 from every call. That is why this file exists: the screen
///   gates on [ReconciliationRoles.viewRoles] and shows a permission-denied
///   panel instead of five failing requests.
/// * `ACT_ROLES` (resolve / assign / correct-float / agent-float sync /
///   invariants run) matches `AdminRoles.financeOperators` exactly.
///
/// The server is still authoritative: a role can change mid-session (the guard
/// re-reads it with a 60s cache), so a 403 is always handled as well.
abstract final class ReconciliationRoles {
  /// `GET /breaks`, `GET /breaks/:id`, `GET /rail-ageing`.
  static const Set<AdminRole> viewRoles = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
    AdminRole.reviewer,
    AdminRole.viewer,
  };

  /// Every POST in the module.
  static const Set<AdminRole> actRoles = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
  };

  static bool canView(AdminRole? role) =>
      role != null && viewRoles.contains(role);

  static bool canAct(AdminRole? role) => role != null && actRoles.contains(role);

  /// The role's name from the catalogue.
  ///
  /// Kept as a local mapping rather than a call to `AdminRole.label`: the role
  /// enum belongs to core, and reconciliation resolves the name itself so this
  /// surface keeps working whatever happens to that member.
  static String roleLabel(AdminRole role, AppStrings s) => switch (role) {
        AdminRole.superAdmin => s.roleSuperAdmin,
        AdminRole.financeAdmin => s.roleFinanceAdmin,
        AdminRole.reviewer => s.roleReviewer,
        AdminRole.support => s.roleSupport,
        AdminRole.viewer => s.roleViewer,
      };

  /// Human list for a "who can do this" line in the denied panel.
  ///
  /// [strings] is optional only so a caller with no `BuildContext` in reach
  /// still compiles; it then falls back to the default (Arabic) bundle. Every
  /// widget should pass `context.s`.
  static String describe(Set<AdminRole> roles, [AppStrings? strings]) {
    final AppStrings s = strings ?? AppStrings.ar;
    final List<String> labels = <String>[
      for (final AdminRole role in AdminRoles.all)
        if (roles.contains(role)) roleLabel(role, s),
    ];
    return labels.join(s.listSeparator);
  }
}

/// True when the signed-in admin may READ reconciliation.
final Provider<bool> canViewReconciliationProvider = Provider<bool>(
  (ref) => ReconciliationRoles.canView(ref.watch(currentRoleProvider)),
);

/// True when the signed-in admin may assign / resolve / correct / run sweeps.
final Provider<bool> canActOnReconciliationProvider = Provider<bool>(
  (ref) => ReconciliationRoles.canAct(ref.watch(currentRoleProvider)),
);
