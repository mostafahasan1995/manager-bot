import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which backend deployment this build talks to.
enum AppEnvironment {
  dev('dev'),
  prod('prod');

  const AppEnvironment(this.wireName);

  /// Value accepted by `--dart-define=MB_ENV=...`.
  final String wireName;

  bool get isDev => this == AppEnvironment.dev;
  bool get isProd => this == AppEnvironment.prod;

  static AppEnvironment fromName(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final value in AppEnvironment.values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return AppEnvironment.dev;
  }
}

/// Immutable, compile-time-seeded configuration.
///
/// Every value comes from `--dart-define` so that no secret or host name is
/// baked into source control. Defaults are DEV defaults.
///
/// Example release invocation:
/// ```
/// flutter build apk --release \
///   --dart-define=MB_ENV=prod \
///   --dart-define=MB_API_BASE_URL=https://api.example.com \
///   --dart-define=MB_USE_FAKE_AUTH=false
/// ```
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.useFakeAuth,
    required this.connectTimeout,
    required this.sendTimeout,
    required this.receiveTimeout,
    required this.defaultPageSize,
    required this.verboseHttpLog,
  });

  /// Builds the configuration from `--dart-define` values.
  ///
  /// ANDROID EMULATOR CAVEAT
  /// -----------------------
  /// `localhost` inside an Android emulator refers to the EMULATOR itself, not
  /// to the developer machine. The emulator reaches the host loopback through
  /// the special alias `10.0.2.2`, which is why the dev default below is
  /// `http://10.0.2.2:3000` and not `http://localhost:3000`.
  ///
  /// * Android emulator  -> `http://10.0.2.2:3000`      (the default)
  /// * iOS simulator     -> `http://localhost:3000`     (shares the host loopback)
  /// * Physical device   -> `http://<your-LAN-ip>:3000` (and the API must bind 0.0.0.0)
  ///
  /// Override for the iOS simulator or a physical handset with:
  /// `--dart-define=MB_API_BASE_URL=http://localhost:3000`
  ///
  /// Cleartext HTTP additionally requires a debug network-security exemption on
  /// Android and an `NSAllowsLocalNetworking` entry on iOS; both are debug-only
  /// concerns because production is HTTPS.
  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment('MB_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.fromName(environmentName);

    const baseUrl = String.fromEnvironment(
      'MB_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    );

    // Fake auth defaults ON in dev because the backend has no admin login
    // endpoint yet (see lib/core/auth/http_admin_auth_api.dart), and OFF in
    // prod no matter what, so a mis-set define can never ship a bypass.
    const fakeAuthDefine = String.fromEnvironment(
      'MB_USE_FAKE_AUTH',
    );
    final bool fakeAuthRequested =
        fakeAuthDefine.isEmpty || fakeAuthDefine.toLowerCase() == 'true';
    final bool useFakeAuth = !environment.isProd && fakeAuthRequested;

    const connectMs = int.fromEnvironment('MB_CONNECT_TIMEOUT_MS', defaultValue: 10000);
    const sendMs = int.fromEnvironment('MB_SEND_TIMEOUT_MS', defaultValue: 20000);
    const receiveMs = int.fromEnvironment('MB_RECEIVE_TIMEOUT_MS', defaultValue: 20000);
    const pageSize = int.fromEnvironment('MB_PAGE_SIZE', defaultValue: 20);
    const verboseDefine = String.fromEnvironment('MB_VERBOSE_HTTP');

    return AppConfig(
      environment: environment,
      baseUrl: _stripTrailingSlash(baseUrl),
      useFakeAuth: useFakeAuth,
      connectTimeout: const Duration(milliseconds: connectMs),
      sendTimeout: const Duration(milliseconds: sendMs),
      receiveTimeout: const Duration(milliseconds: receiveMs),
      defaultPageSize: pageSize < 1 || pageSize > maxPageSize ? 20 : pageSize,
      verboseHttpLog: verboseDefine.isEmpty
          ? environment.isDev
          : verboseDefine.toLowerCase() == 'true',
    );
  }

  /// Hard server-side cap on any list endpoint (`limit` 1..100).
  static const int maxPageSize = 100;

  /// Default currency of the platform. Minor units, scale 2.
  static const String defaultCurrency = 'NSP';

  /// Minor-unit scale for [defaultCurrency]. `minor = major * 100`.
  static const int defaultCurrencyScale = 2;

  /// Header the backend stamps on every response and honours on request.
  static const String correlationIdHeader = 'x-correlation-id';

  /// Header demanded by exactly one endpoint: `POST /v1/deposits`.
  static const String idempotencyKeyHeader = 'idempotency-key';

  /// Header the backend sets to `true` when a request was an idempotent replay.
  static const String idempotencyReplayedHeader = 'idempotency-replayed';

  final AppEnvironment environment;

  /// Origin only, no trailing slash, no `/v1` suffix. Feature paths carry their
  /// own version segment because the backend has NO global prefix and health
  /// routes are deliberately unversioned (`/health/live`, not `/v1/health/live`).
  final String baseUrl;

  /// When true the in-memory [FakeAdminAuthApi] is bound instead of the HTTP
  /// adapter. Forced to false in [AppEnvironment.prod].
  final bool useFakeAuth;

  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;

  /// Page size sent as `limit` on list endpoints. Server default is 20, max 100.
  final int defaultPageSize;

  /// Log method, path, status and correlation id for every request.
  final bool verboseHttpLog;

  bool get isDev => environment.isDev;
  bool get isProd => environment.isProd;

  AppConfig copyWith({
    AppEnvironment? environment,
    String? baseUrl,
    bool? useFakeAuth,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    int? defaultPageSize,
    bool? verboseHttpLog,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      baseUrl: baseUrl == null ? this.baseUrl : _stripTrailingSlash(baseUrl),
      useFakeAuth: useFakeAuth ?? this.useFakeAuth,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      defaultPageSize: defaultPageSize ?? this.defaultPageSize,
      verboseHttpLog: verboseHttpLog ?? this.verboseHttpLog,
    );
  }

  /// One-line summary for the startup log.
  String describe() {
    return 'env=${environment.wireName} baseUrl=$baseUrl useFakeAuth=$useFakeAuth '
        'pageSize=$defaultPageSize timeouts(c/s/r)='
        '${connectTimeout.inMilliseconds}/${sendTimeout.inMilliseconds}/'
        '${receiveTimeout.inMilliseconds}ms';
  }

  static String _stripTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}

/// The single source of truth for configuration. Override in tests with
/// `ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)])`.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
