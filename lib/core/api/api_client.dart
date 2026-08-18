import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/api/uuid.dart';
import 'package:manager_bot/core/auth/auth_token_source.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/core/money/money.dart';

/// Convenience alias for a decoded JSON object.
typedef ApiJson = Map<String, Object?>;

/// The one HTTP entry point of the app.
///
/// Guarantees, in order of importance:
/// 1. A `DioException` NEVER escapes. Every failure is an [ApiError]. That
///    includes model mapping: a hand-written `fromJson` runs INSIDE the guard,
///    so a `JsonParseException` or a `MoneyFormatException` from a contract
///    change arrives as [ApiUnexpected] and not as a raw throw.
/// 2. The envelope is unwrapped once, here. Callers see `data` and `meta`.
/// 3. 204 is handled without decoding a body.
/// 4. `Authorization: Bearer` is injected from [AccessTokenProvider].
/// 5. `Idempotency-Key` is generated for the endpoints that demand it.
/// 6. `x-correlation-id` is sent and captured, so support can trace a request.
/// 7. Every sentence it mints comes from [AppStrings], in the admin's language.
class ApiClient {
  /// [strings] is a READER, not a value: the language can change while the
  /// client lives, and rebuilding the client (and its dio connection pool) on
  /// a language toggle would cancel in-flight requests. Defaults to the Arabic
  /// bundle, which is the app default.
  ApiClient({
    required AppConfig config,
    AccessTokenProvider? tokenProvider,
    AppStrings Function()? strings,
    Dio? dio,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _strings = strings ?? _arabicStrings,
        _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      // Never let dio decide what an error is: every status is unwrapped by
      // decodeEnvelope so the envelope, not the status, drives the mapping.
      validateStatus: (int? status) => status != null && status < 600,
      headers: <String, Object?>{'accept': 'application/json'},
    );
    _dio.interceptors.add(
      _RequestDecorationInterceptor(
        tokenProvider: () => _tokenProvider?.accessToken,
        verbose: config.verboseHttpLog,
      ),
    );
  }

  /// Endpoints that REQUIRE an `Idempotency-Key`.
  ///
  /// Exactly one exists today: `POST /v1/deposits` (scope `deposit.create`).
  /// `POST /v1/deposits/:shortId/proof` is deliberately NOT in this set - it
  /// dedupes by image sha256 instead.
  static const Set<String> idempotentPostPaths = <String>{'/v1/deposits'};

  /// `extra` key that forces an `Idempotency-Key` on any request.
  static const String extraIdempotent = 'mb.idempotent';

  /// `extra` key carrying a caller-supplied idempotency key.
  static const String extraIdempotencyKey = 'mb.idempotencyKey';

  /// `extra` key that suppresses the `Authorization` header (health, login).
  static const String extraSkipAuth = 'mb.skipAuth';

  final AppConfig _config;
  final AccessTokenProvider? _tokenProvider;
  final AppStrings Function() _strings;
  final Dio _dio;

  String? _lastCorrelationId;

  /// The bundle the admin is reading right now. Hand it to any parser that
  /// needs to mint a sentence (see `AdminSession.fromJson`).
  AppStrings get strings => _strings();

  static AppStrings _arabicStrings() => AppStrings.ar;

  /// Correlation id of the most recent response, error or not. Handy for a
  /// "copy diagnostics" button in settings.
  String? get lastCorrelationId => _lastCorrelationId;

  /// Escape hatch for a feature that needs a raw dio call (multipart upload,
  /// download). Prefer the typed methods.
  Dio get rawDio => _dio;

  AppConfig get config => _config;

  Future<ApiResponse<Object?>> get(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) =>
      _send(
        method: 'GET',
        path: path,
        query: query,
        cancelToken: cancelToken,
        authenticated: authenticated,
      );

  /// POST.
  ///
  /// Set [idempotent] (or hit one of [idempotentPostPaths]) to attach an
  /// `Idempotency-Key`. To make a RETRY replay instead of creating a second
  /// row, keep the key: generate it once with [newIdempotencyKey] and pass the
  /// same value on every attempt with the IDENTICAL body.
  Future<ApiResponse<Object?>> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool idempotent = false,
    String? idempotencyKey,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) =>
      _send(
        method: 'POST',
        path: path,
        body: body,
        query: query,
        idempotent: idempotent,
        idempotencyKey: idempotencyKey,
        cancelToken: cancelToken,
        authenticated: authenticated,
      );

  Future<ApiResponse<Object?>> patch(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) =>
      _send(
        method: 'PATCH',
        path: path,
        body: body,
        query: query,
        cancelToken: cancelToken,
        authenticated: authenticated,
      );

  Future<ApiResponse<Object?>> delete(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) =>
      _send(
        method: 'DELETE',
        path: path,
        body: body,
        query: query,
        cancelToken: cancelToken,
        authenticated: authenticated,
      );

  /// GET one object and map it with a hand-written factory.
  Future<T> getObject<T>(
    String path, {
    required T Function(ApiJson json) fromJson,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final response = await get(
      path,
      query: query,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
    return _mapObject<T>(response, fromJson, method: 'GET', path: path);
  }

  /// POST and map the created object.
  Future<T> postObject<T>(
    String path, {
    required T Function(ApiJson json) fromJson,
    Object? body,
    Map<String, Object?>? query,
    bool idempotent = false,
    String? idempotencyKey,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final response = await post(
      path,
      body: body,
      query: query,
      idempotent: idempotent,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
    return _mapObject<T>(response, fromJson, method: 'POST', path: path);
  }

  /// PATCH and map the updated object.
  Future<T> patchObject<T>(
    String path, {
    required T Function(ApiJson json) fromJson,
    Object? body,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final response = await patch(
      path,
      body: body,
      query: query,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
    return _mapObject<T>(response, fromJson, method: 'PATCH', path: path);
  }

  /// GET a CURSOR-paginated list (admin deposit queue, reconciliation breaks).
  ///
  /// [cursor] must be a value that came out of a previous [CursorPage.nextCursor].
  /// Never construct or parse one.
  Future<CursorPage<T>> getCursorPage<T>(
    String path, {
    required T Function(ApiJson json) fromJson,
    String? cursor,
    int? limit,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    final params = <String, Object?>{
      ...?query,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': _clampLimit(limit),
    };
    final response = await get(path, query: params, cancelToken: cancelToken);
    final page = response.meta.cursorPage;
    return CursorPage<T>(
      items: _mapList<T>(response, fromJson, method: 'GET', path: path),
      nextCursor: page?.nextCursor,
      hasMore: page?.hasMore ?? false,
      correlationId: response.correlationId,
    );
  }

  /// GET an OFFSET-paginated list. `meta` carries total/limit/offset/hasMore.
  Future<OffsetPage<T>> getOffsetPage<T>(
    String path, {
    required T Function(ApiJson json) fromJson,
    int offset = 0,
    int? limit,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    final resolvedLimit = _clampLimit(limit);
    final params = <String, Object?>{
      ...?query,
      'limit': resolvedLimit,
      'offset': offset < 0 ? 0 : offset,
    };
    final response = await get(path, query: params, cancelToken: cancelToken);
    final page = response.meta.offsetPage;
    final items = _mapList<T>(response, fromJson, method: 'GET', path: path);
    return OffsetPage<T>(
      items: items,
      total: page?.total ?? items.length,
      limit: page?.limit ?? resolvedLimit,
      offset: page?.offset ?? offset,
      hasMore: page?.hasMore ?? false,
      correlationId: response.correlationId,
    );
  }

  /// A fresh key that satisfies `^[A-Za-z0-9_.:-]+$`, length 8..255.
  ///
  /// Generate ONCE per logical operation and reuse it across retries; a new key
  /// on a retry creates a second deposit.
  static String newIdempotencyKey() => Uuid.v4();

  void close() {
    _dio.close(force: true);
  }

  /// Runs a hand-written `fromJson` INSIDE the client's guarantee.
  ///
  /// The mapping deliberately happens here rather than at the call site: a
  /// parser can raise [JsonParseException] (a field of the wrong type) or
  /// [MoneyFormatException] (an amount with three decimals, or a number where a
  /// decimal string was promised), and neither is an [ApiError]. Letting either
  /// escape would break the class contract - "every failure is an ApiError" -
  /// and every `on ApiError catch` in the feature layer would miss it.
  T _mapObject<T>(
    ApiResponse<Object?> response,
    T Function(ApiJson json) fromJson, {
    required String method,
    required String path,
  }) {
    try {
      return fromJson(Json.asObject(response.data, path: path));
    } on JsonParseException catch (e) {
      throw _malformed(e.path, e.reason, method, path, response.correlationId);
    } on MoneyFormatException catch (e) {
      throw _badAmount(e.reason, method, path, response.correlationId);
    }
  }

  /// [Json.list] inside the same guarantee as [_mapObject].
  List<T> _mapList<T>(
    ApiResponse<Object?> response,
    T Function(ApiJson json) fromJson, {
    required String method,
    required String path,
  }) {
    try {
      return Json.list<T>(response.data, fromJson, path: path);
    } on JsonParseException catch (e) {
      throw _malformed(e.path, e.reason, method, path, response.correlationId);
    } on MoneyFormatException catch (e) {
      throw _badAmount(e.reason, method, path, response.correlationId);
    }
  }

  ApiUnexpected _malformed(
    String field,
    String reason,
    String method,
    String path,
    String? correlationId,
  ) {
    AppLogger.error(
      '$method $path returned a payload this app cannot read '
      '($field: $reason)',
      scope: 'http',
    );
    return ApiUnexpected(
      code: ApiErrorCodes.clientMalformedResponse,
      message: strings.errorCouldNotReadResponse(
        method: method,
        path: path,
        field: field,
        reason: reason,
      ),
      correlationId: correlationId,
    );
  }

  ApiUnexpected _badAmount(
    String reason,
    String method,
    String path,
    String? correlationId,
  ) {
    AppLogger.error(
      '$method $path carried an amount this app refuses to round ($reason)',
      scope: 'http',
    );
    return ApiUnexpected(
      code: ApiErrorCodes.clientMalformedResponse,
      message: strings.errorAmountNotExact(
        method: method,
        path: path,
        reason: reason,
      ),
      correlationId: correlationId,
    );
  }

  int _clampLimit(int? limit) {
    final value = limit ?? _config.defaultPageSize;
    if (value < 1) {
      return 1;
    }
    return value > AppConfig.maxPageSize ? AppConfig.maxPageSize : value;
  }

  Future<ApiResponse<Object?>> _send({
    required String method,
    required String path,
    Object? body,
    Map<String, Object?>? query,
    bool idempotent = false,
    String? idempotencyKey,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final needsKey = idempotent ||
        idempotencyKey != null ||
        (method == 'POST' && idempotentPostPaths.contains(_normalizePath(path)));

    final extra = <String, Object?>{
      extraSkipAuth: !authenticated,
      if (needsKey) extraIdempotent: true,
      if (needsKey) extraIdempotencyKey: idempotencyKey ?? newIdempotencyKey(),
    };

    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        options: Options(method: method, extra: extra),
      );
      return _unwrap(response);
    } on DioException catch (e, stackTrace) {
      throw _mapDioException(e, stackTrace, method: method, path: path);
    } on ApiUnauthorized catch (e) {
      // Admin tokens cannot be refreshed server-side, so the auth layer has to
      // hear about this immediately and ask for a new bot code.
      AppLogger.warn('$method $path -> 401 ${e.code}', scope: 'http');
      _tokenProvider?.onUnauthorized(e);
      rethrow;
    } on ApiError {
      rethrow;
    } on JsonParseException catch (e) {
      throw ApiUnexpected(
        code: ApiErrorCodes.clientMalformedResponse,
        message: strings.errorCouldNotReadResponse(
          method: method,
          path: path,
          field: e.path,
          reason: e.reason,
        ),
        correlationId: _lastCorrelationId,
      );
    }
  }

  ApiResponse<Object?> _unwrap(Response<Object?> response) {
    final correlationId =
        response.headers.value(AppConfig.correlationIdHeader)?.trim();
    if (correlationId != null && correlationId.isNotEmpty) {
      _lastCorrelationId = correlationId;
    }
    final replayed =
        response.headers.value(AppConfig.idempotencyReplayedHeader)?.toLowerCase() ==
            'true';
    final retryAfterHeader = response.headers.value('retry-after');
    final retryAfterSeconds =
        retryAfterHeader == null ? null : int.tryParse(retryAfterHeader.trim());

    final unwrapped = decodeEnvelope(
      body: response.data,
      statusCode: response.statusCode,
      headerCorrelationId: correlationId,
      replayedIdempotently: replayed,
      retryAfter:
          retryAfterSeconds == null ? null : Duration(seconds: retryAfterSeconds),
      strings: strings,
    );
    if (unwrapped.meta.correlationId.isNotEmpty) {
      _lastCorrelationId = unwrapped.meta.correlationId;
    }
    if (_config.verboseHttpLog) {
      AppLogger.debug(
        '${response.requestOptions.method} ${response.requestOptions.path} '
        '-> ${response.statusCode} cid=${unwrapped.meta.correlationId}'
        '${replayed ? ' (idempotent replay)' : ''}',
        scope: 'http',
      );
    }
    return unwrapped;
  }

  ApiError _mapDioException(
    DioException e,
    StackTrace stackTrace, {
    required String method,
    required String path,
  }) {
    final correlationId =
        e.response?.headers.value(AppConfig.correlationIdHeader) ?? _lastCorrelationId;
    final AppStrings s = strings;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      // Raised when decoding the body outruns its budget rather than the
      // socket. Still a timeout to the operator, and still safe to retry.
      case DioExceptionType.transformTimeout:
        AppLogger.warn('$method $path timed out (${e.type.name})', scope: 'http');
        return ApiTimeout(
          message: s.errorRequestTimedOutPath(path: path),
          correlationId: correlationId,
        );
      case DioExceptionType.cancel:
        return ApiNetworkError(
          message: s.errorRequestCancelled,
          code: ApiErrorCodes.clientCancelled,
          isCancelled: true,
        );
      case DioExceptionType.badCertificate:
        return ApiNetworkError(
          message: s.errorCertificateRejected,
          correlationId: correlationId,
        );
      case DioExceptionType.badResponse:
        // validateStatus lets every status through, so this is a decode
        // failure rather than an HTTP status problem.
        AppLogger.error(
          '$method $path returned an undecodable response',
          scope: 'http',
          error: e,
          stackTrace: stackTrace,
        );
        return ApiUnexpected(
          code: ApiErrorCodes.clientMalformedResponse,
          message: s.errorResponseUndecodable(method: method, path: path),
          correlationId: correlationId,
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        AppLogger.warn(
          '$method $path failed to reach the server: ${e.message ?? e.error}',
          scope: 'http',
        );
        return ApiNetworkError(
          message: s.errorCouldNotReachHost(baseUrl: _config.baseUrl),
          correlationId: correlationId,
        );
    }
  }

  static Map<String, dynamic>? _cleanQuery(Map<String, Object?>? query) {
    if (query == null || query.isEmpty) {
      return null;
    }
    final cleaned = <String, dynamic>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String && value.isEmpty) {
        continue;
      }
      cleaned[entry.key] = value;
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  static String _normalizePath(String path) {
    var normalized = path.trim();
    final queryIndex = normalized.indexOf('?');
    if (queryIndex >= 0) {
      normalized = normalized.substring(0, queryIndex);
    }
    while (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    return normalized;
  }
}

/// Adds bearer token, idempotency key and correlation id to every request.
class _RequestDecorationInterceptor extends Interceptor {
  _RequestDecorationInterceptor({
    required this.tokenProvider,
    required this.verbose,
  });

  final String? Function() tokenProvider;
  final bool verbose;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra[ApiClient.extraSkipAuth] == true;
    if (!skipAuth) {
      final token = tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['authorization'] = 'Bearer $token';
      }
    }

    if (options.extra[ApiClient.extraIdempotent] == true) {
      final provided = options.extra[ApiClient.extraIdempotencyKey];
      final key = provided is String && provided.isNotEmpty
          ? provided
          : ApiClient.newIdempotencyKey();
      options.headers[AppConfig.idempotencyKeyHeader] = key;
    }

    // The server honours our id when it matches ^[A-Za-z0-9._-]{8,128}$ and
    // mints its own otherwise; sending one makes client and server logs line up.
    options.headers.putIfAbsent(
      AppConfig.correlationIdHeader,
      () => Uuid.prefixed('mb'),
    );

    if (verbose) {
      AppLogger.debug(
        '${options.method} ${options.path}'
        '${options.queryParameters.isEmpty ? '' : ' ${options.queryParameters}'}',
        scope: 'http',
      );
    }
    handler.next(options);
  }
}

/// The app-wide client. Rebuilt only if [appConfigProvider] is overridden.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    config: ref.watch(appConfigProvider),
    tokenProvider: ref.watch(authTokenSourceProvider),
    // read, not watch: a language toggle must not tear down the connection
    // pool underneath an in-flight review.
    strings: () => ref.read(stringsProvider),
  );
  ref.onDispose(client.close);
  return client;
});
