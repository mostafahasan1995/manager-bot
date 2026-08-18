import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/admin_users/application/admin_directory_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/admin_user_error_codes.dart';
import 'package:manager_bot/features/admin_users/data/admin_users_repository.dart';

/// What a write to the staff directory was trying to do. Carried through the
/// state so a snackbar can say "Could not deactivate ..." rather than
/// "Something went wrong".
enum AdminMutationAction {
  create,
  update,
  deactivate,
  reactivate;

  /// The button that starts this write.
  String label(AppStrings s) => switch (this) {
        AdminMutationAction.create => s.auFormCreateTitle,
        AdminMutationAction.update => s.auSaveChanges,
        AdminMutationAction.deactivate => s.auDeactivateButton,
        AdminMutationAction.reactivate => s.auReactivateButton,
      };

  /// The success sentence. One key per action rather than a shared
  /// "{name} {pastTense}" template - Arabic puts the verb first.
  String toast(AppStrings s, {required String name}) => switch (this) {
        AdminMutationAction.create => s.auCreatedToast(name: name),
        AdminMutationAction.update => s.auUpdatedToast(name: name),
        AdminMutationAction.deactivate => s.auDeactivatedToast(name: name),
        AdminMutationAction.reactivate => s.auReactivatedToast(name: name),
      };
}

/// Lifecycle of a single directory write.
sealed class AdminMutationState {
  const AdminMutationState();

  bool get isBusy => this is AdminMutationRunning;
}

final class AdminMutationIdle extends AdminMutationState {
  const AdminMutationIdle();
}

final class AdminMutationRunning extends AdminMutationState {
  const AdminMutationRunning(this.action);

  final AdminMutationAction action;
}

final class AdminMutationSucceeded extends AdminMutationState {
  const AdminMutationSucceeded({
    required this.action,
    required this.admin,
    required this.message,
    this.notice,
  });

  final AdminMutationAction action;
  final AdminUserView admin;

  /// Already resolved against the language in force when the write landed.
  final String message;

  /// Extra context the operator must read - currently only the identity-cache
  /// warning after an authority change.
  final String? notice;
}

final class AdminMutationFailed extends AdminMutationState {
  const AdminMutationFailed({
    required this.action,
    required this.error,
    required this.message,
  });

  final AdminMutationAction action;
  final ApiError error;

  /// Already resolved to something an operator can act on.
  final String message;

  /// Field-level messages from a 400. WARNING: for `VALIDATION_FAILED` these are
  /// human sentences, not field names, so they are shown as a list rather than
  /// used to highlight inputs.
  List<String> get fieldMessages {
    final ApiError current = error;
    return current is ApiValidation ? current.fieldMessages : const <String>[];
  }
}

/// Every write to the staff directory goes through here.
///
/// Two things it always does, and screens therefore never have to:
///  * refresh the directory and the affected detail row after a success;
///  * turn an [ApiError] into a sentence, preferring this feature's own domain
///    codes (`ADMIN_SELF_MODIFICATION`, `ADMIN_LAST_SUPER_ADMIN`,
///    `ADMIN_ALREADY_EXISTS`) over the generic message.
///
/// A 401 is deliberately NOT handled here: it flips [AuthController] to expired
/// and the router leaves for /login on its own.
class AdminUserMutationController extends Notifier<AdminMutationState> {
  static const String _scope = 'admin_users.mutation';

  @override
  AdminMutationState build() => const AdminMutationIdle();

  void reset() => state = const AdminMutationIdle();

  /// Adds somebody to the directory. Returns the created row, or null on
  /// failure - in which case [state] is an [AdminMutationFailed].
  Future<AdminUserView?> create(CreateAdminUserRequest request) {
    return _run(
      AdminMutationAction.create,
      () => ref.read(adminUsersRepositoryProvider).create(request),
      noticeFor: (AdminUserView created, AppStrings s) =>
          created.isActive ? s.auNoticeNewAdminCanSignIn : null,
    );
  }

  /// Patches an administrator. A patch that carries no changes is a no-op that
  /// never reaches the network.
  Future<AdminUserView?> update(String id, UpdateAdminUserRequest request) {
    if (request.isEmpty) {
      AppLogger.debug('empty patch for $id ignored', scope: _scope);
      return Future<AdminUserView?>.value();
    }
    return _run(
      AdminMutationAction.update,
      () => ref.read(adminUsersRepositoryProvider).update(id, request),
      noticeFor: (AdminUserView _, AppStrings s) =>
          request.changesAuthority ? s.identityCacheNotice : null,
    );
  }

  /// Soft delete. The row stays, referenced by every deposit this person ever
  /// decided; only `isActive` flips.
  Future<AdminUserView?> deactivate(String id) {
    return _run(
      AdminMutationAction.deactivate,
      () => ref.read(adminUsersRepositoryProvider).deactivate(id),
      noticeFor: (AdminUserView _, AppStrings s) => s.identityCacheNotice,
    );
  }

  Future<AdminUserView?> reactivate(String id) {
    return _run(
      AdminMutationAction.reactivate,
      () => ref.read(adminUsersRepositoryProvider).reactivate(id),
      noticeFor: (AdminUserView _, AppStrings s) => s.auNoticeAccessRestored,
    );
  }

  Future<AdminUserView?> _run(
    AdminMutationAction action,
    Future<AdminUserView> Function() call, {
    required String? Function(AdminUserView admin, AppStrings s) noticeFor,
  }) async {
    if (state.isBusy) {
      return null;
    }
    state = AdminMutationRunning(action);
    // No BuildContext here: the bundle comes from the locale controller.
    final AppStrings s = ref.read(stringsProvider);

    try {
      final AdminUserView admin = await call();
      AppLogger.info(
        '${action.name} succeeded for ${admin.id} (${admin.role.wireName}, '
        'active: ${admin.isActive})',
        scope: _scope,
      );

      if (action == AdminMutationAction.create) {
        // A brand-new row belongs to no loaded page and the server decides
        // where it sorts, so this is the one case that has to refetch.
        ref.invalidate(adminDirectoryProvider);
      } else {
        // Patch the loaded list in place. The directory is deliberately NOT
        // invalidated here: `build()` refetches offset 0 only, so invalidating
        // would throw away every page the operator had scrolled through and
        // drop them back to the first 20 rows. `admin` is exactly what the
        // server just returned, so the local patch IS the authoritative value.
        ref.read(adminDirectoryProvider.notifier).applyLocalUpdate(admin);
      }
      ref.invalidate(adminUserDetailProvider(admin.id));

      state = AdminMutationSucceeded(
        action: action,
        admin: admin,
        message: action.toast(s, name: admin.displayName),
        notice: noticeFor(admin, s),
      );
      return admin;
    } on ApiError catch (error, stackTrace) {
      AppLogger.error(
        '${action.name} failed: ${error.code} '
        '(correlation ${error.correlationId ?? 'unknown'})',
        scope: _scope,
        error: error,
        stackTrace: stackTrace,
      );
      state = AdminMutationFailed(
        action: action,
        error: error,
        message: describeAdminError(error, s),
      );
      return null;
    }
  }
}

final NotifierProvider<AdminUserMutationController, AdminMutationState>
    adminUserMutationProvider =
    NotifierProvider<AdminUserMutationController, AdminMutationState>(
  AdminUserMutationController.new,
);

/// Turns an [ApiError] into one sentence an operator can act on.
///
/// Order matters: this feature's own domain codes are more specific than the
/// generic per-variant text, and `error.code` is an OPEN string, so it is
/// compared against constants rather than switched on as an enum.
String describeAdminError(ApiError error, AppStrings s) {
  // ADMIN_NOT_FOUND is ambiguous on this API: on a 404 it means "the row in the
  // path is gone", but on a 401/403 it means "YOUR administrator row is gone".
  // The auth variants are therefore never explained with the domain wording.
  if (error is! ApiForbidden && error is! ApiUnauthorized) {
    final String? domain = AdminUserErrorCodes.explain(error.code, s);
    if (domain != null) {
      return domain;
    }
  }
  return switch (error) {
    // Server-authored field sentences: shown verbatim, never translated.
    final ApiValidation validation when validation.fieldMessages.isNotEmpty =>
      validation.fieldMessages.join('\n'),
    final ApiForbidden forbidden when forbidden.isAdminInactive =>
      s.errOwnAccountDeactivated,
    final ApiForbidden forbidden when forbidden.isInsufficientRole =>
      s.errRoleNotAllowed,
    ApiRateLimited() => s.errorTooManyRequests,
    ApiNetworkError() || ApiTimeout() => s.errNetwork,
    _ => error.userMessage(s),
  };
}
