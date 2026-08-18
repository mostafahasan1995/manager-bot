import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/logging/app_logger.dart';

/// In-memory admin auth, so the console is fully usable and testable TODAY.
///
/// The backend has no admin login endpoint yet, so without this adapter nobody
/// could open a single screen. Bound when `AppConfig.useFakeAuth` is true,
/// which is forced to false in `AppEnvironment.prod`.
///
/// ACCEPTED DEV CODES
/// ------------------
/// `DEV-<ROLE>` optionally followed by `:<option>`, case-insensitive:
///
/// * `DEV-SUPER_ADMIN`          -> 8h session as SUPER_ADMIN
/// * `DEV-FINANCE_ADMIN`        -> 8h session as FINANCE_ADMIN
/// * `DEV-REVIEWER`             -> 8h session as REVIEWER
/// * `DEV-SUPPORT`              -> 8h session as SUPPORT
/// * `DEV-VIEWER`               -> 8h session as VIEWER
/// * `DEV-REVIEWER:SHORT`       -> 2 MINUTE session, to exercise the expiry
///                                 and re-login flow
/// * `DEV-SUPPORT:Layla`        -> 8h session whose display name is `Layla`
/// * `DEV-DENY`                 -> always rejected, to exercise the error path
///
/// Hyphens may be used instead of the underscore (`DEV-SUPER-ADMIN` works).
///
/// [refresh] deliberately throws [AuthUnsupportedError] exactly like the real
/// adapter: admin tokens have no server-side refresh, and a fake that quietly
/// extended the session would hide the one UX case that matters.
class FakeAdminAuthApi implements AdminAuthApi {
  FakeAdminAuthApi({
    AppStrings Function()? strings,
    this.latency = const Duration(milliseconds: 350),
    this.sessionDuration = const Duration(hours: 8),
    this.shortSessionDuration = const Duration(minutes: 2),
  }) : _strings = strings ?? _arabicStrings;

  /// Simulated round-trip time, so loading states are visible in dev.
  final Duration latency;
  final Duration sessionDuration;
  final Duration shortSessionDuration;

  final AppStrings Function() _strings;

  static AppStrings _arabicStrings() => AppStrings.ar;

  static final RegExp _codePattern = RegExp(
    r'^DEV[-_]([A-Z][A-Z_-]*)(?::(.+))?$',
    caseSensitive: false,
  );

  /// Base for synthetic Telegram ids; comfortably above 2^32 so any code that
  /// wrongly parses these as 32-bit ints fails loudly in dev.
  static final BigInt _telegramIdBase = BigInt.parse('7100000000');

  AdminSession? _current;

  /// The session this fake currently considers valid, if any.
  AdminSession? get currentSession => _current;

  @override
  String get adapterName => 'FakeAdminAuthApi';

  @override
  bool get isFake => true;

  @override
  Future<AdminSession> exchangeBotCode(String code) async {
    await Future<void>.delayed(latency);

    final trimmed = code.trim();
    final match = _codePattern.firstMatch(trimmed);
    if (match == null) {
      throw _reject(trimmed);
    }

    final roleToken = (match.group(1) ?? '').toUpperCase().replaceAll('-', '_');
    final option = match.group(2)?.trim() ?? '';

    if (roleToken == 'DENY') {
      throw _reject(trimmed);
    }

    final role = AdminRole.tryParse(roleToken);
    if (role == null) {
      throw _reject(trimmed);
    }

    final isShort = option.toUpperCase() == 'SHORT';
    final displayName = option.isEmpty || isShort ? _displayNameFor(role) : option;
    final now = DateTime.now();
    final session = AdminSession(
      accessToken: 'fake.${role.wireName}.${now.microsecondsSinceEpoch}',
      expiresAt: now.add(isShort ? shortSessionDuration : sessionDuration),
      adminUserId: 'fake-admin-${role.wireName.toLowerCase()}',
      telegramUserId: _telegramIdBase + BigInt.from(role.rank),
      role: role,
      displayName: displayName,
      issuedAt: now,
    );
    _current = session;
    AppLogger.warn(
      'FAKE AUTH: issued a ${role.wireName} session for "$displayName" '
      'valid for ${session.timeToExpiry.inMinutes} min. No server was contacted.',
      scope: 'auth',
    );
    return session;
  }

  @override
  Future<AdminSession> refresh(AdminSession current) async {
    await Future<void>.delayed(latency);
    throw const AuthUnsupportedError(
      'refresh',
      'Admin sessions have no refresh token server-side. The fake mirrors that '
          'on purpose: when the session expires the admin must exchange a new '
          'bot code.',
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(latency);
    _current = null;
    AppLogger.info('FAKE AUTH: local session discarded.', scope: 'auth');
  }

  ApiUnauthorized _reject(String code) {
    AppLogger.warn('FAKE AUTH: rejected code "$code".', scope: 'auth');
    // The sentence is localised; the dev-code list after it is developer text
    // and stays English on purpose - the codes themselves are Latin literals.
    return ApiUnauthorized(
      code: ApiErrorCodes.botCodeInvalid,
      message: '${_strings().botCodeInvalid} In dev, use DEV-REVIEWER, '
          'DEV-FINANCE_ADMIN, DEV-SUPER_ADMIN, DEV-SUPPORT or DEV-VIEWER.',
      statusCode: 401,
    );
  }

  /// The synthetic name a bare `DEV-<ROLE>` code gets. It reaches the login
  /// banner and the profile screen, so it goes through the catalogue; a
  /// `DEV-SUPPORT:Layla` code replaces it with the typed value instead.
  String _displayNameFor(AdminRole role) {
    final AppStrings s = _strings();
    return s.devDisplayName(role: role.label(s));
  }
}
