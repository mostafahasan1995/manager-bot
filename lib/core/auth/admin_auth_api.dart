import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// An authenticated admin session.
///
/// There is NO refresh token: the backend mints admin access tokens through
/// `issueAdminAccessToken` only, and never returns a refresh token for an
/// admin principal. When [expiresAt] passes, the admin must sign in again.
/// Nothing in this app pretends otherwise.
class AdminSession {
  const AdminSession({
    required this.accessToken,
    required this.expiresAt,
    required this.adminUserId,
    required this.role,
    required this.displayName,
    this.telegramUserId,
    this.issuedAt,
  });

  /// Parses the shape the app expects from `POST /v1/admin/auth/bot-code`.
  ///
  /// ```json
  /// {
  ///   "accessToken": "...",
  ///   "expiresAt": "2026-08-16T18:04:11.512Z",
  ///   "admin": {
  ///     "id": "0f3b...uuid",
  ///     "telegramUserId": "7123456789",
  ///     "role": "FINANCE_ADMIN",
  ///     "displayName": "Layla"
  ///   }
  /// }
  /// ```
  /// `telegramUserId` is a decimal STRING (64-bit) and is parsed as [BigInt].
  ///
  /// `expiresAt` is REQUIRED. There used to be an invented 8-hour fallback here;
  /// it was a bug. Every expiry decision in the app - the 30-second timer, the
  /// guard band before a review is started, the restore path - reads this field,
  /// so a fabricated value keeps a token that is already dead looking alive in
  /// memory and turns the next call into a surprise 401. A payload without it is
  /// a contract violation and is reported as one.
  factory AdminSession.fromJson(
    Map<String, Object?> json, {
    AppStrings strings = AppStrings.ar,
  }) {
    final admin = Json.objectOrNull(json, 'admin') ?? json;
    final DateTime? expiresAt = Json.dateTimeOrNull(json, 'expiresAt') ??
        Json.dateTimeOrNull(json, 'accessTokenExpiresAt');
    if (expiresAt == null) {
      throw JsonParseException('expiresAt', strings.errorSessionNoExpiry);
    }
    return AdminSession(
      accessToken: Json.string(json, 'accessToken'),
      expiresAt: expiresAt,
      adminUserId: Json.stringOrNull(admin, 'id') ??
          Json.stringOrNull(admin, 'adminUserId') ??
          '',
      telegramUserId: Json.bigIntOrNull(admin, 'telegramUserId'),
      role: AdminRole.parseOrViewer(Json.stringOrNull(admin, 'role')),
      displayName: Json.stringOrNull(admin, 'displayName') ??
          Json.stringOrNull(admin, 'name') ??
          strings.adminDisplayNameFallback,
      issuedAt: Json.dateTimeOrNull(json, 'issuedAt'),
    );
  }

  /// Restores a session persisted by [TokenStore].
  factory AdminSession.fromStorageJson(
    Map<String, Object?> json, {
    AppStrings strings = AppStrings.ar,
  }) =>
      AdminSession(
        accessToken: Json.string(json, 'accessToken'),
        expiresAt: Json.dateTime(json, 'expiresAt'),
        adminUserId: Json.stringOrNull(json, 'adminUserId') ?? '',
        telegramUserId: Json.bigIntOrNull(json, 'telegramUserId'),
        role: AdminRole.parseOrViewer(Json.stringOrNull(json, 'role')),
        displayName: Json.stringOrNull(json, 'displayName') ??
            strings.adminDisplayNameFallback,
        issuedAt: Json.dateTimeOrNull(json, 'issuedAt'),
      );

  /// Bearer token. NEVER log this; [toString] deliberately redacts it.
  final String accessToken;

  /// Absolute expiry, local time. Refresh decisions use THIS, never a decoded
  /// JWT payload.
  final DateTime expiresAt;

  /// UUID of the admin_user row.
  final String adminUserId;

  /// Telegram id of the admin, 64-bit, nullable. Kept as [BigInt] because it
  /// exceeds 2^53 and arrives as a decimal string.
  final BigInt? telegramUserId;

  final AdminRole role;
  final String displayName;
  final DateTime? issuedAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  Duration get timeToExpiry => expiresAt.difference(DateTime.now());

  /// True when the session dies within [window]. Use it to warn BEFORE an admin
  /// starts a review they cannot submit.
  bool expiresWithin(Duration window) =>
      timeToExpiry <= window && !timeToExpiry.isNegative;

  /// Telegram id as the decimal string the API uses.
  String? get telegramUserIdString => telegramUserId?.toString();

  /// Persisted shape. Symmetric with [AdminSession.fromStorageJson].
  Map<String, Object?> toStorageJson() => <String, Object?>{
        'accessToken': accessToken,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'adminUserId': adminUserId,
        'telegramUserId': telegramUserId?.toString(),
        'role': role.wireName,
        'displayName': displayName,
        'issuedAt': issuedAt?.toUtc().toIso8601String(),
      };

  AdminSession copyWith({
    String? accessToken,
    DateTime? expiresAt,
    String? adminUserId,
    BigInt? telegramUserId,
    AdminRole? role,
    String? displayName,
    DateTime? issuedAt,
  }) =>
      AdminSession(
        accessToken: accessToken ?? this.accessToken,
        expiresAt: expiresAt ?? this.expiresAt,
        adminUserId: adminUserId ?? this.adminUserId,
        telegramUserId: telegramUserId ?? this.telegramUserId,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        issuedAt: issuedAt ?? this.issuedAt,
      );

  @override
  String toString() => 'AdminSession(admin=$adminUserId, role=${role.wireName}, '
      'displayName=$displayName, expiresAt=$expiresAt, token=<redacted>)';
}

/// PORT for admin authentication.
///
/// Two adapters implement it:
/// * `FakeAdminAuthApi`  - in-memory, dev only, bound when
///   `AppConfig.useFakeAuth` is true.
/// * `HttpAdminAuthApi`  - the real one, written against an endpoint the
///   backend HAS NOT SHIPPED YET (see http_admin_auth_api.dart).
///
/// Everything above this port is adapter-agnostic, so the console is fully
/// usable today and switches to the server the day the endpoint lands.
abstract class AdminAuthApi {
  /// Name used in the startup log line, mirroring how the backend announces
  /// its Ichancy fake.
  String get adapterName;

  /// True when this adapter is not talking to a real server.
  bool get isFake;

  /// Exchanges a one-time code issued by the bot for an admin session.
  ///
  /// Throws [ApiUnauthorized] with code `BOT_CODE_INVALID` when the code is
  /// wrong or already used, and the usual [ApiError] variants for transport
  /// problems.
  Future<AdminSession> exchangeBotCode(String code);

  /// Extends a session.
  ///
  /// Admin tokens have NO server-side refresh today, so the HTTP adapter throws
  /// [AuthUnsupportedError]. Callers must handle that by prompting for a new
  /// sign-in rather than silently retrying.
  Future<AdminSession> refresh(AdminSession current);

  /// Best-effort server-side session revocation. Must never throw: the local
  /// session is cleared regardless.
  Future<void> logout();
}
