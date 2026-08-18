import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// One row of the staff directory.
///
/// Wire shape - `AdminUserView` in `src/modules/admin/dtos/admin-user.dto.ts`:
/// ```json
/// {
///   "id": "0f6a...-uuid",
///   "telegramUserId": "7412998301",
///   "username": "nadia_ops",
///   "displayName": "Nadia",
///   "role": "FINANCE_ADMIN",
///   "isActive": true,
///   "lastLoginAt": "2026-08-16T09:11:02.114Z",
///   "createdAt": "2026-05-02T08:00:00.000Z"
/// }
/// ```
///
/// `telegramUserId` is a 64-bit id emitted as a decimal STRING (the backend
/// patches `BigInt.prototype.toJSON`). It is parsed to [BigInt] - never `int`,
/// which would silently round above 2^53.
///
/// `passwordHash` / `totpSecretEnc` are never exposed by the API and therefore
/// have no field here.
class AdminUserView {
  const AdminUserView({
    required this.id,
    required this.telegramUserId,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.username,
    this.lastLoginAt,
  });

  factory AdminUserView.fromJson(ApiJson json) => AdminUserView(
        id: Json.string(json, 'id'),
        telegramUserId: Json.bigInt(json, 'telegramUserId'),
        displayName: Json.string(json, 'displayName'),
        role: AdminRole.parseOrViewer(Json.stringOrNull(json, 'role')),
        isActive: Json.boolean(json, 'isActive'),
        createdAt: Json.dateTime(json, 'createdAt'),
        username: Json.stringOrNull(json, 'username'),
        lastLoginAt: Json.dateTimeOrNull(json, 'lastLoginAt'),
      );

  final String id;
  final BigInt telegramUserId;
  final String displayName;
  final AdminRole role;
  final bool isActive;
  final DateTime createdAt;
  final String? username;
  final DateTime? lastLoginAt;

  /// The id as the wire carries it: a decimal string, never a number.
  String get telegramUserIdString => telegramUserId.toString();

  /// `@handle`, or null when the administrator has no Telegram username.
  String? get atHandle {
    final String? raw = username;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw.startsWith('@') ? raw : '@$raw';
  }

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  bool get hasSignedIn => lastLoginAt != null;

  /// نشط / موقوف - an ADMINISTRATOR, never a payment method or destination.
  String statusLabel(AppStrings s) =>
      isActive ? s.auStatusActive : s.auStatusDeactivated;

  StatusTone get statusTone => isActive ? StatusTone.approve : StatusTone.neutral;

  /// Two initials for the avatar, derived without assuming a name has two words.
  String get initials {
    final List<String> parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final String only = parts.first;
      return (only.length == 1 ? only : only.substring(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  /// Mirror of the wire shape. Used by tests for a fromJson/toJson round trip
  /// and by the logger; it is never sent as a request body.
  ApiJson toJson() => <String, Object?>{
        'id': id,
        'telegramUserId': telegramUserIdString,
        'username': username,
        'displayName': displayName,
        'role': role.wireName,
        'isActive': isActive,
        'lastLoginAt': lastLoginAt?.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  AdminUserView copyWith({
    String? displayName,
    AdminRole? role,
    bool? isActive,
    String? username,
    DateTime? lastLoginAt,
  }) =>
      AdminUserView(
        id: id,
        telegramUserId: telegramUserId,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        username: username ?? this.username,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserView &&
          other.id == id &&
          other.telegramUserId == telegramUserId &&
          other.displayName == displayName &&
          other.role == role &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.username == username &&
          other.lastLoginAt == lastLoginAt;

  @override
  int get hashCode => Object.hash(
        id,
        telegramUserId,
        displayName,
        role,
        isActive,
        createdAt,
        username,
        lastLoginAt,
      );

  @override
  String toString() => 'AdminUserView($id, $displayName, ${role.wireName}, '
      'active: $isActive)';
}

/// Field-level validation that mirrors `CreateAdminUserDto` / `UpdateAdminUserDto`.
///
/// The server still decides - this only stops obviously-doomed round trips and
/// gives the form something to show under the field. Every message is written
/// for an operator, not for a developer.
abstract final class AdminUserFieldRules {
  /// 1-19 digits: the widest an unsigned 64-bit Telegram id can be, with no
  /// sign and no separators. Mirrors `TELEGRAM_ID_PATTERN` on the server.
  static final RegExp telegramIdPattern = RegExp(r'^\d{1,19}$');

  static const int displayNameMaxLength = 120;
  static const int usernameMaxLength = 64;

  /// Returns null when valid, otherwise an operator-facing reason.
  static String? telegramUserId(String raw, AppStrings s) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return s.auTelegramIdRequired;
    }
    if (!telegramIdPattern.hasMatch(value)) {
      return s.auTelegramIdMalformed;
    }
    return null;
  }

  static String? displayName(String raw, AppStrings s) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return s.auDisplayNameRequired;
    }
    if (value.length > displayNameMaxLength) {
      return s.auMaxChars(max: displayNameMaxLength);
    }
    return null;
  }

  /// Optional field: an empty value is valid and simply omitted from the body.
  static String? username(String raw, AppStrings s) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final String bare = value.startsWith('@') ? value.substring(1) : value;
    if (bare.isEmpty) {
      return s.auUsernameAfterAt;
    }
    if (bare.length > usernameMaxLength) {
      return s.auMaxChars(max: usernameMaxLength);
    }
    return null;
  }

  /// Strips a leading `@` so the stored value matches what Telegram reports.
  static String? normaliseUsername(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final String bare = value.startsWith('@') ? value.substring(1) : value;
    return bare.isEmpty ? null : bare;
  }
}

/// Body of `POST /v1/admin/admins`.
///
/// The endpoint validates with `forbidNonWhitelisted`, so an unknown key is a
/// 400 rather than a silent drop - only the four documented keys are emitted,
/// and `username` is omitted entirely when absent.
class CreateAdminUserRequest {
  const CreateAdminUserRequest({
    required this.telegramUserId,
    required this.displayName,
    required this.role,
    this.username,
  });

  final BigInt telegramUserId;
  final String displayName;
  final AdminRole role;
  final String? username;

  ApiJson toJson() => <String, Object?>{
        'telegramUserId': telegramUserId.toString(),
        'displayName': displayName,
        'role': role.wireName,
        if (username != null) 'username': username,
      };

  @override
  String toString() => 'CreateAdminUserRequest($telegramUserId, $displayName, '
      '${role.wireName})';
}

/// Body of `PATCH /v1/admin/admins/{id}`.
///
/// Every field is optional and an absent field means "leave it alone". `null`
/// is never sent: the server's validators are `@IsOptional() @IsString()`, so a
/// literal null would fail validation rather than clear the column.
class UpdateAdminUserRequest {
  const UpdateAdminUserRequest({
    this.displayName,
    this.role,
    this.isActive,
    this.username,
  });

  /// Builds the minimal patch that turns [before] into the supplied values.
  ///
  /// Unchanged fields are dropped so the audit trail records only real edits
  /// and so a no-op edit never trips the self-modification guard.
  factory UpdateAdminUserRequest.diff({
    required AdminUserView before,
    required String displayName,
    required AdminRole role,
    required bool isActive,
    String? username,
  }) =>
      UpdateAdminUserRequest(
        displayName: displayName == before.displayName ? null : displayName,
        role: role == before.role ? null : role,
        isActive: isActive == before.isActive ? null : isActive,
        username: username == before.username ? null : username,
      );

  final String? displayName;
  final AdminRole? role;
  final bool? isActive;
  final String? username;

  /// True when the body would carry no changes at all - do not send it.
  bool get isEmpty =>
      displayName == null && role == null && isActive == null && username == null;

  bool get isNotEmpty => !isEmpty;

  /// True when this patch touches authority (role or activation), which is what
  /// the server's self-modification and last-super-admin guards react to.
  bool get changesAuthority => role != null || isActive != null;

  ApiJson toJson() => <String, Object?>{
        if (displayName != null) 'displayName': displayName,
        if (role != null) 'role': role!.wireName,
        if (isActive != null) 'isActive': isActive,
        if (username != null) 'username': username,
      };

  @override
  String toString() => 'UpdateAdminUserRequest(${toJson()})';
}
