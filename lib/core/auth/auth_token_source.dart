import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';

/// What [ApiClient] needs from the auth layer, and nothing more.
///
/// Kept as a narrow port so the client does not depend on the auth controller
/// (which depends on the client - this breaks the cycle).
abstract class AccessTokenProvider {
  /// Current bearer token, or null when signed out.
  String? get accessToken;

  /// Called by the client whenever the server answers 401, so the auth layer
  /// can flip to the "expired, sign in again" state.
  void onUnauthorized(ApiUnauthorized error);
}

/// The single mutable holder of the current access token.
///
/// `AuthController` writes it; `ApiClient` reads it on every request. Reading a
/// plain field avoids hitting secure storage per request.
class AuthTokenSource implements AccessTokenProvider {
  String? _accessToken;

  /// Installed by `AuthController` during its build.
  void Function(ApiUnauthorized error)? unauthorizedHandler;

  @override
  String? get accessToken => _accessToken;

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  void setToken(String? token) {
    _accessToken = (token == null || token.isEmpty) ? null : token;
  }

  void clear() {
    _accessToken = null;
  }

  @override
  void onUnauthorized(ApiUnauthorized error) {
    unauthorizedHandler?.call(error);
  }
}

/// Process-wide token holder.
final Provider<AuthTokenSource> authTokenSourceProvider =
    Provider<AuthTokenSource>((ref) => AuthTokenSource());
