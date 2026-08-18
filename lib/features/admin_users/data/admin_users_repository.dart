import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/approval_limit.dart';

/// HTTP access to the staff directory and to approval ceilings.
///
/// Endpoints (all verified against `src/modules/admin/controllers/`):
///
/// | verb   | path                                             | roles                      |
/// |--------|--------------------------------------------------|----------------------------|
/// | GET    | /v1/admin/admins                                 | SUPER_ADMIN, FINANCE_ADMIN |
/// | GET    | /v1/admin/admins/{id}                            | SUPER_ADMIN, FINANCE_ADMIN |
/// | POST   | /v1/admin/admins                                 | SUPER_ADMIN                |
/// | PATCH  | /v1/admin/admins/{id}                            | SUPER_ADMIN                |
/// | DELETE | /v1/admin/admins/{id}                            | SUPER_ADMIN                |
/// | GET    | /v1/admin/admins/{adminUserId}/approval-limits    | SUPER_ADMIN, FINANCE_ADMIN |
/// | POST   | /v1/admin/admins/{adminUserId}/approval-limits    | SUPER_ADMIN                |
/// | DELETE | /v1/admin/approval-limits/{id}                    | SUPER_ADMIN                |
///
/// Every method throws [ApiError] and never a `DioException` - the client
/// translates transport failures before they get here. Nothing on this feature
/// needs an `Idempotency-Key`: `POST /v1/deposits` is the only endpoint in the
/// whole backend that demands one.
class AdminUsersRepository {
  const AdminUsersRepository(this._client);

  /// Collection root for the staff directory.
  static const String adminsPath = '/v1/admin/admins';

  /// Approval-limit versions are addressed by their own id when being ended.
  static const String approvalLimitsPath = '/v1/admin/approval-limits';

  /// How long a deactivation can keep working after the write commits.
  ///
  /// `AdminIdentityService` caches the Telegram-id -> admin lookup for 60
  /// seconds, including negative results. The service invalidates the entry on
  /// every mutation, but a replica that already answered from cache keeps the
  /// old answer until it expires. Surfaced in the UI because "switched off" and
  /// "cannot act any more" are up to a minute apart.
  static const Duration identityCacheTtl = Duration(seconds: 60);

  final ApiClient _client;

  /// Offset-paginated directory listing.
  ///
  /// The page metadata (`total`, `limit`, `offset`, `hasMore`) is merged into
  /// the envelope's `meta`, never nested under `data`; [ApiClient.getOffsetPage]
  /// already knows that.
  ///
  /// There is no server-side text search on this endpoint - filtering by name is
  /// done client-side over the rows that have been loaded.
  Future<OffsetPage<AdminUserView>> list({
    AdminRole? role,
    bool? isActive,
    int offset = 0,
    int? limit,
    CancelToken? cancelToken,
  }) {
    return _client.getOffsetPage<AdminUserView>(
      adminsPath,
      fromJson: AdminUserView.fromJson,
      offset: offset,
      limit: limit,
      query: <String, Object?>{
        if (role != null) 'role': role.wireName,
        if (isActive != null) 'isActive': isActive,
      },
      cancelToken: cancelToken,
    );
  }

  Future<AdminUserView> getById(String id, {CancelToken? cancelToken}) {
    return _client.getObject<AdminUserView>(
      '$adminsPath/$id',
      fromJson: AdminUserView.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Creates an administrator. 409 `ADMIN_ALREADY_EXISTS` when the Telegram id
  /// or the username is already in the directory.
  Future<AdminUserView> create(CreateAdminUserRequest request) {
    return _client.postObject<AdminUserView>(
      adminsPath,
      fromJson: AdminUserView.fromJson,
      body: request.toJson(),
    );
  }

  /// Patches an administrator.
  ///
  /// 422 `ADMIN_SELF_MODIFICATION` when the caller is changing their own role or
  /// deactivating themselves; 422 `ADMIN_LAST_SUPER_ADMIN` when the patch would
  /// leave no active super administrator. Both are domain refusals, not bugs -
  /// the screens render them as messages.
  Future<AdminUserView> update(String id, UpdateAdminUserRequest request) {
    return _client.patchObject<AdminUserView>(
      '$adminsPath/$id',
      fromJson: AdminUserView.fromJson,
      body: request.toJson(),
    );
  }

  /// Soft delete. `admin_users` is referenced by every deposit the person ever
  /// decided with `onDelete: Restrict`, so DELETE deactivates and returns the
  /// updated row rather than destroying the audit trail.
  ///
  /// Takes up to [identityCacheTtl] to be fully in force.
  Future<AdminUserView> deactivate(String id) async {
    final ApiResponse<Object?> response = await _client.delete('$adminsPath/$id');
    return AdminUserView.fromJson(Json.asObject(response.data));
  }

  /// Turning somebody back on is an ordinary patch, not a resurrect endpoint.
  Future<AdminUserView> reactivate(String id) {
    return update(id, const UpdateAdminUserRequest(isActive: true));
  }

  /// Full ceiling history for one administrator, newest first.
  ///
  /// `data` is a bare array here, not a page - this endpoint is not paginated.
  Future<List<ApprovalLimitView>> approvalLimits(
    String adminUserId, {
    CancelToken? cancelToken,
  }) async {
    final ApiResponse<Object?> response = await _client.get(
      '$adminsPath/$adminUserId/approval-limits',
      cancelToken: cancelToken,
    );
    return Json.list<ApprovalLimitView>(
      response.data,
      ApprovalLimitView.fromJson,
      path: r'$.data',
    );
  }

  /// Supersedes whatever ceiling is in force for (administrator, currency).
  ///
  /// A 409 `APPROVAL_LIMIT_INVALID` here means two operators set the same
  /// ceiling in the same millisecond; retrying is the right answer, so it is
  /// returned as a value rather than thrown.
  Future<SetApprovalLimitOutcome> setApprovalLimit(
    String adminUserId,
    SetApprovalLimitRequest request,
  ) async {
    try {
      final ApprovalLimitView limit = await _client.postObject<ApprovalLimitView>(
        '$adminsPath/$adminUserId/approval-limits',
        fromJson: ApprovalLimitView.fromJson,
        body: request.toJson(),
      );
      return SetApprovalLimitOutcome.applied(limit);
    } on ApiConflict catch (error) {
      return SetApprovalLimitOutcome.raced(error);
    }
  }

  /// Ends a version WITHOUT replacing it.
  ///
  /// The administrator is then left with no active ceiling, which the evaluator
  /// reads as DENIED. This revokes authority; it never grants it.
  Future<ApprovalLimitView> endApprovalLimit(String limitId) async {
    final ApiResponse<Object?> response =
        await _client.delete('$approvalLimitsPath/$limitId');
    return ApprovalLimitView.fromJson(Json.asObject(response.data));
  }
}

/// Result of setting a ceiling: either the new version, or a lost race that the
/// operator should simply retry.
sealed class SetApprovalLimitOutcome {
  const SetApprovalLimitOutcome();

  const factory SetApprovalLimitOutcome.applied(ApprovalLimitView limit) =
      SetApprovalLimitApplied;

  const factory SetApprovalLimitOutcome.raced(ApiConflict error) =
      SetApprovalLimitRaced;
}

final class SetApprovalLimitApplied extends SetApprovalLimitOutcome {
  const SetApprovalLimitApplied(this.limit);

  final ApprovalLimitView limit;
}

final class SetApprovalLimitRaced extends SetApprovalLimitOutcome {
  const SetApprovalLimitRaced(this.error);

  final ApiConflict error;
}

final Provider<AdminUsersRepository> adminUsersRepositoryProvider =
    Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(ref.watch(apiClientProvider)),
);
