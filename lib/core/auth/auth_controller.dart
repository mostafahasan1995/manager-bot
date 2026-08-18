import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_token_source.dart';
import 'package:manager_bot/core/auth/fake_admin_auth_api.dart';
import 'package:manager_bot/core/auth/http_admin_auth_api.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/auth/token_store.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';

/// Auth state machine.
///
/// The router handles the coarse routing; a screen switches on the detail:
///
/// ```dart
/// final AppStrings s = context.s;
/// final String banner = switch (ref.watch(authControllerProvider)) {
///   AuthInitializing() => s.loginHeadlineRestoring,
///   AuthUnauthenticated(:final message) => message ?? s.loginHeadlineSignIn,
///   AuthAuthenticating() => s.loginHeadlineChecking,
///   AuthAuthenticated(:final session) =>
///     s.loginHeadlineSignedInAs(name: session.displayName),
///   AuthExpired() => s.loginHeadlineSessionEnded,
/// };
/// ```
sealed class AuthState {
  const AuthState();

  /// The live session, or null in every state but [AuthAuthenticated].
  AdminSession? get session => switch (this) {
        AuthAuthenticated(session: final value) => value,
        AuthInitializing() => null,
        AuthUnauthenticated() => null,
        AuthAuthenticating() => null,
        AuthExpired() => null,
      };

  bool get isAuthenticated => this is AuthAuthenticated;

  /// True while a restore or a bot-code exchange is running.
  bool get isBusy => this is AuthInitializing || this is AuthAuthenticating;
}

/// Reading the keystore at launch. Show a splash, do NOT bounce to login yet.
final class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// No session. [error] is set when the last sign-in attempt failed.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error, this.message});

  final ApiError? error;

  /// Plain text to show above the code field (e.g. after an explicit sign-out).
  final String? message;
}

/// A bot code is being exchanged.
final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

/// Signed in and the token is still valid.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  @override
  final AdminSession session;
}

/// The token ran out or the server rejected it.
///
/// Deliberately distinct from [AuthUnauthenticated]: the console knows WHO was
/// signed in and can say "your session expired, Layla - sign in again" instead
/// of pretending a refresh is possible. Admin tokens have no refresh token.
final class AuthExpired extends AuthState {
  const AuthExpired(this.previous, {required this.reason});

  /// The session that just died - name and role are still worth showing.
  final AdminSession previous;

  /// Why, in one line, ALREADY LOCALISED: one of the `reason*` keys, or a raw
  /// backend code (`TOKEN_EXPIRED`, `SESSION_REVOKED`) which is never
  /// translated. Render it verbatim.
  final String reason;
}

/// Binds the auth adapter and announces the choice, mirroring how the backend
/// announces its Ichancy fake at boot.
final Provider<AdminAuthApi> adminAuthApiProvider = Provider<AdminAuthApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final AdminAuthApi api = config.useFakeAuth
      ? FakeAdminAuthApi(strings: () => ref.read(stringsProvider))
      : HttpAdminAuthApi(ref.watch(apiClientProvider));

  if (api.isFake) {
    AppLogger.warn(
      'AUTH ADAPTER = ${api.adapterName} (useFakeAuth=true, '
      'env=${config.environment.wireName}). No real admin login is performed. '
      'Accepted dev codes: DEV-SUPER_ADMIN, DEV-FINANCE_ADMIN, DEV-REVIEWER, '
      'DEV-SUPPORT, DEV-VIEWER (add :SHORT for a 2 minute session).',
      scope: 'auth',
    );
  } else if (!HttpAdminAuthApi.backendEndpointImplemented) {
    // Loud on purpose. This is the one configuration in which NOBODY can sign
    // in: the real adapter is bound and the route it needs does not exist, so
    // every sign-in attempt is refused before a request is sent.
    AppLogger.error(
      'AUTH ADAPTER = ${api.adapterName} -> POST ${HttpAdminAuthApi.exchangePath} '
      'at ${config.baseUrl}, but that endpoint IS NOT IMPLEMENTED by the '
      'backend. Sign-in will be refused. Ship the endpoint and set '
      'HttpAdminAuthApi.backendEndpointImplemented = true, or run dev with '
      '--dart-define=MB_USE_FAKE_AUTH=true.',
      scope: 'auth',
    );
  } else {
    AppLogger.info(
      'AUTH ADAPTER = ${api.adapterName} -> POST ${HttpAdminAuthApi.exchangePath} '
      'at ${config.baseUrl}.',
      scope: 'auth',
    );
  }
  return api;
});

/// The auth state machine. Read it for gating, use `.notifier` for actions.
final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The live session, or null. Convenience for widgets that only need the data.
final Provider<AdminSession?> currentSessionProvider = Provider<AdminSession?>(
  (ref) => ref.watch(authControllerProvider).session,
);

/// The signed-in admin's role, or null when signed out.
final Provider<AdminRole?> currentRoleProvider = Provider<AdminRole?>(
  (ref) => ref.watch(currentSessionProvider)?.role,
);

class AuthController extends Notifier<AuthState> {
  /// How often the expiry clock is checked.
  static const Duration expiryCheckInterval = Duration(seconds: 30);

  /// A session with less than this left is treated as already expired, so an
  /// admin never starts a review they cannot submit.
  static const Duration expiryGuardBand = Duration(seconds: 20);

  Timer? _expiryTimer;

  @override
  AuthState build() {
    final tokenSource = ref.read(authTokenSourceProvider);
    tokenSource.unauthorizedHandler = _onServerUnauthorized;

    _expiryTimer = Timer.periodic(expiryCheckInterval, (_) => _checkExpiry());
    ref.onDispose(() {
      _expiryTimer?.cancel();
      _expiryTimer = null;
      tokenSource.unauthorizedHandler = null;
    });

    unawaited(_restore());
    return const AuthInitializing();
  }

  AdminSession? get session => state.session;

  /// The bundle the admin is reading right now. Read (never watched) so a
  /// language toggle does not rebuild the auth state machine.
  AppStrings get _s => ref.read(stringsProvider);

  /// Client-side capability gate. The server still decides.
  bool can(AdminCapability capability) =>
      AdminRoles.can(state.session?.role, capability);

  /// Exchanges a bot code for a session.
  ///
  /// Never throws: failures land in [AuthUnauthenticated.error] so the login
  /// screen can render them.
  Future<void> signInWithBotCode(String code) async {
    if (state is AuthAuthenticating) {
      return;
    }
    state = const AuthAuthenticating();
    try {
      final api = ref.read(adminAuthApiProvider);
      final session = await api.exchangeBotCode(code);
      if (session.isExpired) {
        state = AuthExpired(session, reason: _s.reasonTokenAlreadyExpired);
        return;
      }
      await _adopt(session);
    } on ApiError catch (e) {
      AppLogger.warn('Sign-in failed: ${e.code}', scope: 'auth');
      _clearToken();
      state = AuthUnauthenticated(error: e, message: e.userMessage(_s));
    } on AuthUnsupportedError catch (e) {
      _clearToken();
      state = AuthUnauthenticated(message: e.reason);
    }
  }

  /// Signs out.
  ///
  /// Local only in practice: no adapter contacts a server, because there is no
  /// admin-scoped logout route and admin access tokens have no server-side
  /// session to revoke (see `HttpAdminAuthApi.logout`). The [AdminAuthApi.logout]
  /// call is still made so the day such a route lands, only that adapter
  /// changes. The token is dropped in the `finally` either way.
  Future<void> signOut({String? message}) async {
    final api = ref.read(adminAuthApiProvider);
    state = AuthUnauthenticated(message: message ?? _s.signedOut);
    try {
      await api.logout();
    } on ApiError catch (e) {
      AppLogger.warn('Server logout failed (${e.code}).', scope: 'auth');
    } finally {
      _clearToken();
      await ref.read(tokenStoreProvider).clear();
    }
  }

  /// Flips to [AuthExpired] and drops the token.
  ///
  /// Called by the expiry timer and by `ApiClient` on any 401. There is no
  /// refresh path for admins, so this is the whole recovery story: tell the
  /// human, keep their name on screen, ask for a new code.
  /// [reason] is already-localised copy (a `reason*` key) or a raw backend
  /// code; null falls back to [AppStrings.reasonSessionExpired].
  void markExpired({String? reason}) {
    final AppStrings s = _s;
    final String resolved = reason ?? s.reasonSessionExpired;
    final previous = state.session;
    _clearToken();
    unawaited(ref.read(tokenStoreProvider).clear());
    state = previous == null
        ? AuthUnauthenticated(message: s.signInAgainWithReason(reason: resolved))
        : AuthExpired(previous, reason: resolved);
  }

  /// Attempts to extend the session.
  ///
  /// Kept honest: today every adapter throws [AuthUnsupportedError], so this
  /// resolves to [markExpired] and a re-login prompt. When the backend grows a
  /// real admin refresh, only this method changes.
  Future<void> tryRefresh() async {
    final current = state.session;
    if (current == null) {
      return;
    }
    try {
      final refreshed = await ref.read(adminAuthApiProvider).refresh(current);
      await _adopt(refreshed);
    } on AuthUnsupportedError catch (e) {
      AppLogger.info('Refresh is not supported: ${e.reason}', scope: 'auth');
      markExpired(reason: _s.reasonNoRefresh);
    } on ApiError catch (e) {
      markExpired(reason: e.code);
    }
  }

  /// Re-reads the keystore. Exposed for a manual "retry" on the splash screen.
  Future<void> restore() => _restore();

  Future<void> _restore() async {
    final stored = await ref.read(tokenStoreProvider).read();
    if (stored == null) {
      _clearToken();
      state = const AuthUnauthenticated();
      return;
    }
    if (stored.timeToExpiry <= expiryGuardBand) {
      AppLogger.info('Stored session for ${stored.adminUserId} has expired.',
          scope: 'auth');
      _clearToken();
      await ref.read(tokenStoreProvider).clear();
      state = AuthExpired(stored, reason: _s.reasonStoredSessionExpired);
      return;
    }
    ref.read(authTokenSourceProvider).setToken(stored.accessToken);
    state = AuthAuthenticated(stored);
    AppLogger.info(
      'Restored ${stored.role.wireName} session for ${stored.displayName}; '
      '${stored.timeToExpiry.inMinutes} min left.',
      scope: 'auth',
    );
  }

  Future<void> _adopt(AdminSession session) async {
    ref.read(authTokenSourceProvider).setToken(session.accessToken);
    await ref.read(tokenStoreProvider).write(session);
    state = AuthAuthenticated(session);
  }

  void _onServerUnauthorized(ApiUnauthorized error) {
    if (state is AuthAuthenticated) {
      markExpired(reason: error.code);
    }
  }

  void _checkExpiry() {
    final current = state.session;
    if (current == null) {
      return;
    }
    if (current.timeToExpiry <= expiryGuardBand) {
      markExpired();
    }
  }

  void _clearToken() {
    ref.read(authTokenSourceProvider).clear();
  }
}
