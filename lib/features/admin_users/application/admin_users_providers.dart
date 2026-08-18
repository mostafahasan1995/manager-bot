import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/admin_users_repository.dart';

/// The signed-in administrator's own row id, or null when there is no session.
///
/// This is what the self-modification guard compares against - not the display
/// name, not the Telegram id.
final Provider<String?> adminActorIdProvider = Provider<String?>(
  (ref) => ref.watch(currentSessionProvider)?.adminUserId,
);

/// The signed-in administrator's role, or null when there is no session.
final Provider<AdminRole?> adminActorRoleProvider = Provider<AdminRole?>(
  (ref) => ref.watch(currentRoleProvider),
);

/// May this session open the staff directory at all?
///
/// The screens render [AdminActionBlocked.reason] as a permission-denied state
/// rather than an error, because a viewer landing here has done nothing wrong.
final Provider<AdminActionGate> adminDirectoryGateProvider =
    Provider<AdminActionGate>(
  (ref) => AdminUserPolicy.gateViewDirectory(
    ref.watch(adminActorRoleProvider),
    ref.watch(stringsProvider),
  ),
);

/// May this session create, edit, deactivate, or set approval ceilings?
final Provider<AdminActionGate> adminManageGateProvider = Provider<AdminActionGate>(
  (ref) => AdminUserPolicy.gateManage(
    ref.watch(adminActorRoleProvider),
    ref.watch(stringsProvider),
  ),
);

/// Convenience booleans for widgets that only need to enable or disable.
final Provider<bool> canViewAdminUsersProvider = Provider<bool>(
  (ref) => ref.watch(adminDirectoryGateProvider).isAllowed,
);

final Provider<bool> canManageAdminUsersProvider = Provider<bool>(
  (ref) => ref.watch(adminManageGateProvider).isAllowed,
);

/// Roles the current session is allowed to hand out in the role picker.
final Provider<List<AdminRole>> assignableRolesProvider = Provider<List<AdminRole>>(
  (ref) => AdminUserPolicy.assignableRoles(ref.watch(adminActorRoleProvider)),
);

/// One administrator, fetched fresh by id.
///
/// Keyed by the row's uuid. The detail screen watches this so an edit made
/// somewhere else (or by somebody else) shows up on the next invalidate rather
/// than being carried around as a stale copy.
final FutureProviderFamily<AdminUserView, String> adminUserDetailProvider =
    FutureProvider.family<AdminUserView, String>(
  (ref, String adminUserId) =>
      ref.watch(adminUsersRepositoryProvider).getById(adminUserId),
);

/// Which auth adapter is wired up right now - shown on the profile screen so
/// nobody mistakes a fake dev session for a real one.
final Provider<AdminAuthApi> activeAuthAdapterProvider = Provider<AdminAuthApi>(
  (ref) => ref.watch(adminAuthApiProvider),
);
