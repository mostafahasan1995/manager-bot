import 'package:manager_bot/core/i18n/app_strings.dart';

/// Domain error codes owned by the backend `admin` module.
///
/// Source of truth: `src/modules/admin/admin.constants.ts` -> `AdminErrorCodes`.
/// These are NOT modelled as a Dart enum on purpose: `ApiError.code` is an OPEN
/// string on this API and a closed enum would crash on the first code a feature
/// module adds. They are plain constants to compare against.
abstract final class AdminUserErrorCodes {
  /// `404` - the administrator id in the path does not exist.
  static const String adminNotFound = 'ADMIN_NOT_FOUND';

  /// `409` - telegram id or username collides with an existing administrator.
  static const String adminAlreadyExists = 'ADMIN_ALREADY_EXISTS';

  /// `422` - you tried to change your own role or deactivate yourself.
  static const String adminSelfModification = 'ADMIN_SELF_MODIFICATION';

  /// `422` - refusing to remove the last active super administrator.
  static const String adminLastSuperAdmin = 'ADMIN_LAST_SUPER_ADMIN';

  /// `404` - the approval-limit version id does not exist.
  static const String approvalLimitNotFound = 'APPROVAL_LIMIT_NOT_FOUND';

  /// `400`/`409` - incoherent ceilings, or the version already ended.
  static const String approvalLimitInvalid = 'APPROVAL_LIMIT_INVALID';

  /// A short, operator-facing explanation for the codes this feature owns.
  ///
  /// Returns `null` for anything else so the caller falls back to
  /// `ApiError.userMessage`, which is always safe to show.
  static String? explain(String code, AppStrings s) => switch (code) {
        adminNotFound => s.errAdminNotFound,
        adminAlreadyExists => s.errAdminAlreadyExists,
        adminSelfModification => s.gateSelfModificationReason,
        adminLastSuperAdmin => s.gateLastSuperAdminReason,
        approvalLimitNotFound => s.errApprovalLimitNotFound,
        approvalLimitInvalid => s.errApprovalLimitInvalid,
        _ => null,
      };

  /// Every code [explain] has wording for. Kept as data rather than as a call
  /// into [explain] so "do I know this code?" needs no string bundle.
  static const Set<String> known = <String>{
    adminNotFound,
    adminAlreadyExists,
    adminSelfModification,
    adminLastSuperAdmin,
    approvalLimitNotFound,
    approvalLimitInvalid,
  };

  /// True when the code is one this feature knows how to explain.
  static bool isKnown(String code) => known.contains(code);
}
