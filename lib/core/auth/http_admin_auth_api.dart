// =============================================================================
// LIVE. The backend endpoint now exists.
// =============================================================================
// Shipped 2026-08-16 in the backend repo:
//
//   POST /v1/admin/auth/bot-code           (admin-auth.controller.ts)
//   Public (no Authorization header) - it mints the credential, so requiring
//   one would be circular.
//   Body:     { "code": "<one-time code the bot DM'd to the admin>" }
//   Success:  200 envelope, data = {
//               accessToken: string,
//               expiresAt:   ISO-8601 string,
//               admin: {
//                 id:             uuid string,
//                 telegramUserId: decimal STRING (64-bit),
//                 role:           AdminRole wire value,
//                 displayName:    string
//               }
//             }
//   Failure:  401 { code: "BOT_CODE_INVALID" }   unknown / used / expired
//             403 { code: "ADMIN_INACTIVE" }     deactivated between mint and use
//             429                                10/min then blocked 5 min
//
// How an operator gets a code: send /login to the bot IN A DIRECT CHAT. The bot
// refuses in a group, because ctx.reply answers wherever the command was sent
// and a code posted in the admin supergroup is a credential handed to everyone
// in it. Codes are single-use, 5 minutes, and minting a new one kills the old.
//
// Still true, and why `refresh()` below throws: admin tokens are minted with NO
// refresh token, so expiry means asking the bot again.
// =============================================================================

import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/logging/app_logger.dart';

/// Real HTTP adapter for admin authentication.
class HttpAdminAuthApi implements AdminAuthApi {
  HttpAdminAuthApi(this._client);

  /// The bot-code exchange the backend must implement. Public route: no
  /// Authorization header is sent.
  static const String exchangePath = '/v1/admin/auth/bot-code';

  /// True since the backend shipped [exchangePath].
  ///
  /// Kept as a switch rather than deleted: if the app is ever pointed at an
  /// older backend, flipping this back makes the failure say WHY instead of
  /// surfacing a Nest 404 as "That record could not be found." - a message that
  /// reads like a wrong code and sends the operator hunting for one.
  static const bool backendEndpointImplemented = true;

  /// Why the exchange cannot run, in the words a developer needs. Shown on the
  /// login screen verbatim, so it names the file the backend has to change.
  static const String missingEndpointReason =
      'The backend has no admin login endpoint. `issueAdminAccessToken` exists '
      'in src/core/auth/services/session.service.ts but has zero callers, and '
      'the only token-minting route is the player-only Telegram initData '
      'exchange, which a native app cannot produce. Add '
      'POST /v1/admin/auth/bot-code (see the header of '
      'lib/core/auth/http_admin_auth_api.dart and README.md), then set '
      'HttpAdminAuthApi.backendEndpointImplemented = true. Until then run with '
      '--dart-define=MB_USE_FAKE_AUTH=true.';

  final ApiClient _client;

  @override
  String get adapterName => 'HttpAdminAuthApi';

  @override
  bool get isFake => false;

  @override
  Future<AdminSession> exchangeBotCode(String code) async {
    if (!backendEndpointImplemented) {
      throw const AuthUnsupportedError('exchangeBotCode', missingEndpointReason);
    }
    final AppStrings s = _client.strings;
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw ApiValidation(
        code: ApiErrorCodes.validationFailed,
        message: s.enterBotCode,
        fieldMessages: <String>[s.codeMustNotBeEmpty],
        statusCode: 400,
      );
    }
    final session = await _client.postObject<AdminSession>(
      exchangePath,
      body: <String, Object?>{'code': trimmed},
      authenticated: false,
      fromJson: (Map<String, Object?> json) =>
          AdminSession.fromJson(json, strings: s),
    );
    AppLogger.info(
      'Signed in as ${session.role.wireName} (${session.adminUserId}); '
      'token expires ${session.expiresAt.toIso8601String()}.',
      scope: 'auth',
    );
    return session;
  }

  /// Always throws.
  ///
  /// There is no admin refresh token on the server, so there is nothing to
  /// exchange. The honest behaviour is to surface a re-login prompt; silently
  /// "refreshing" would just produce a 401 on the next real call.
  @override
  Future<AdminSession> refresh(AdminSession current) async {
    throw const AuthUnsupportedError(
      'refresh',
      'The backend issues admin access tokens with no refresh token '
          '(session.service.ts issueAdminAccessToken). Prompt for a new bot '
          'code instead of retrying.',
    );
  }

  /// Local only. There is NO server round trip, on purpose.
  ///
  /// `POST /v1/auth/logout` does exist, but it is decorated `@PlayerAuth()` and
  /// reads `@CurrentPlayer('sessionId')`. `AuthGuard.enforceRequirement` throws
  /// `ForbiddenError(WRONG_PRINCIPAL)` when the requirement is PLAYER and no
  /// player principal was attached, and an admin token never attaches one - so
  /// an admin gets 403 every single time, never the 204 the old comment here
  /// claimed. Swallowing that as a warning made it look like server-side
  /// revocation happened when nothing was revoked.
  ///
  /// Admin access tokens also have no server-side session row to revoke: they
  /// are minted stateless by `issueAdminAccessToken` with no refresh token.
  /// Dropping the token locally IS the whole sign-out.
  ///
  /// Re-add a call here only when an ADMIN-scoped logout route exists.
  @override
  Future<void> logout() async {
    AppLogger.info(
      'Admin sign-out is local only: there is no admin-scoped logout route and '
      'no server-side admin session to revoke.',
      scope: 'auth',
    );
  }
}
