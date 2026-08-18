import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// `meta` from the envelope.
///
/// `correlationId` and `timestamp` are always present; the interface is an
/// index signature, so page metadata is MERGED IN here (never nested under
/// `data`). [raw] keeps every extra key so a feature can read one this class
/// does not know about.
class ApiMeta {
  const ApiMeta({
    required this.correlationId,
    required this.timestamp,
    required this.raw,
  });

  factory ApiMeta.fromJson(Map<String, Object?> json, {String? headerCorrelationId}) {
    final id = Json.stringOrNull(json, 'correlationId') ?? headerCorrelationId ?? '';
    return ApiMeta(
      correlationId: id,
      timestamp: Json.dateTimeOrNull(json, 'timestamp'),
      raw: Map<String, Object?>.unmodifiable(json),
    );
  }

  /// Meta for a response that had no envelope at all (204 No Content).
  factory ApiMeta.empty({String? correlationId}) => ApiMeta(
        correlationId: correlationId ?? '',
        timestamp: null,
        raw: const <String, Object?>{},
      );

  /// Always present on success AND failure; also echoed as `x-correlation-id`.
  final String correlationId;

  /// ISO-8601 UTC server timestamp, converted to local. Null only for 204s.
  final DateTime? timestamp;

  /// Every key of `meta`, including the merged page metadata.
  final Map<String, Object?> raw;

  /// Page metadata for an OFFSET list (`total`/`limit`/`offset`/`hasMore`),
  /// or null when this was not an offset list.
  OffsetPageMeta? get offsetPage => OffsetPageMeta.fromMeta(raw);

  /// Page metadata for a CURSOR list (`limit`/`nextCursor`/`hasMore`), or null
  /// when this was not a cursor list.
  CursorPageMeta? get cursorPage => CursorPageMeta.fromMeta(raw);
}

/// Extra `meta` keys on an OFFSET list: `GET /v1/deposits` and friends.
class OffsetPageMeta {
  const OffsetPageMeta({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  /// Returns null when `meta` does not carry offset pagination.
  static OffsetPageMeta? fromMeta(Map<String, Object?> meta) {
    if (!meta.containsKey('total') || !meta.containsKey('offset')) {
      return null;
    }
    return OffsetPageMeta(
      total: Json.integer(meta, 'total', orElse: 0),
      limit: Json.integer(meta, 'limit', orElse: 20),
      offset: Json.integer(meta, 'offset', orElse: 0),
      hasMore: Json.boolean(meta, 'hasMore', orElse: false),
    );
  }

  /// Row count from a COUNT query.
  final int total;
  final int limit;
  final int offset;

  /// Server-derived as `offset + rows.length < total`.
  final bool hasMore;

  /// Offset to request for the next page.
  int get nextOffset => offset + limit;
}

/// Extra `meta` keys on a CURSOR list: `GET /v1/admin/deposits` and
/// `GET /v1/admin/reconciliation/breaks`.
///
/// DIFFERS from [OffsetPageMeta]: there is NO `total` and NO `offset`.
class CursorPageMeta {
  const CursorPageMeta({
    required this.limit,
    required this.nextCursor,
    required this.hasMore,
  });

  /// Returns null when `meta` does not carry cursor pagination.
  static CursorPageMeta? fromMeta(Map<String, Object?> meta) {
    if (!meta.containsKey('nextCursor')) {
      return null;
    }
    return CursorPageMeta(
      limit: Json.integer(meta, 'limit', orElse: 20),
      nextCursor: Json.stringOrNull(meta, 'nextCursor'),
      hasMore: Json.boolean(meta, 'hasMore', orElse: false),
    );
  }

  final int limit;

  /// OPAQUE. Null exactly when the list is exhausted. Pass it back verbatim as
  /// the `cursor` query param - never build one, never parse one.
  final String? nextCursor;

  final bool hasMore;
}

/// A decoded success envelope: `data` plus the whole `meta`.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.meta,
    required this.statusCode,
    this.replayedIdempotently = false,
  });

  /// `data` from the envelope. Null for a void handler and for a 204.
  final T data;

  final ApiMeta meta;
  final int statusCode;

  /// True when the backend answered from the idempotency store
  /// (`idempotency-replayed: true`). The body is byte-identical to the first
  /// call and the status is still 201 - this is a SUCCESS, not an error.
  final bool replayedIdempotently;

  String get correlationId => meta.correlationId;

  ApiResponse<R> withData<R>(R value) => ApiResponse<R>(
        data: value,
        meta: meta,
        statusCode: statusCode,
        replayedIdempotently: replayedIdempotently,
      );
}

/// One page of a cursor-paginated list, already mapped to models.
class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.correlationId,
  });

  final List<T> items;

  /// Feed straight back into the next call. Null == exhausted.
  final String? nextCursor;
  final bool hasMore;
  final String correlationId;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Appends a freshly fetched page to an already-loaded one.
  CursorPage<T> append(CursorPage<T> next) => CursorPage<T>(
        items: <T>[...items, ...next.items],
        nextCursor: next.nextCursor,
        hasMore: next.hasMore,
        correlationId: next.correlationId,
      );

  static CursorPage<T> empty<T>() => CursorPage<T>(
        items: const <Never>[],
        nextCursor: null,
        hasMore: false,
        correlationId: '',
      );
}

/// One page of an offset-paginated list, already mapped to models.
class OffsetPage<T> {
  const OffsetPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
    required this.correlationId,
  });

  final List<T> items;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
  final String correlationId;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get nextOffset => offset + limit;
}

/// Turns a decoded envelope body into an [ApiResponse], or throws the mapped
/// [ApiError]. Shared by [ApiClient] and by tests.
///
/// [strings] supplies the one human sentence this function can mint (a body
/// that was not an envelope at all). It defaults to the Arabic bundle, which
/// is the app default, so a caller with no locale in hand still gets real copy.
ApiResponse<Object?> decodeEnvelope({
  required Object? body,
  required int? statusCode,
  String? headerCorrelationId,
  bool replayedIdempotently = false,
  Duration? retryAfter,
  AppStrings strings = AppStrings.ar,
}) {
  final status = statusCode ?? 0;

  // 204 (POST /v1/auth/logout) sends an EMPTY body - Node strips it even though
  // the interceptor built an envelope. Blind-decoding here would crash.
  final isEmptyBody = body == null || (body is String && body.trim().isEmpty);
  if (status == 204 || isEmptyBody) {
    if (status >= 200 && status < 300) {
      return ApiResponse<Object?>(
        data: null,
        meta: ApiMeta.empty(correlationId: headerCorrelationId),
        statusCode: status,
        replayedIdempotently: replayedIdempotently,
      );
    }
    throw ApiError.fromEnvelope(
      statusCode: status,
      code: null,
      message: null,
      correlationId: headerCorrelationId,
    );
  }

  Map<String, Object?>? envelope;
  if (body is Map<Object?, Object?>) {
    final asMap = Json.asObject(body);
    if (asMap['success'] is bool && asMap.containsKey('data') && asMap.containsKey('error')) {
      envelope = asMap;
    }
  }

  if (envelope == null) {
    // Anything failing before the interceptors (helmet, CORS, body-parser, a
    // proxy 502) is not an envelope.
    if (status >= 200 && status < 300) {
      return ApiResponse<Object?>(
        data: body,
        meta: ApiMeta.empty(correlationId: headerCorrelationId),
        statusCode: status,
        replayedIdempotently: replayedIdempotently,
      );
    }
    throw ApiUnexpected(
      code: ApiErrorCodes.clientMalformedResponse,
      message: strings.errorEnvelopeMissing,
      correlationId: headerCorrelationId,
      statusCode: statusCode,
      details: body,
    );
  }

  final metaJson = envelope['meta'];
  final meta = metaJson is Map<Object?, Object?>
      ? ApiMeta.fromJson(Json.asObject(metaJson), headerCorrelationId: headerCorrelationId)
      : ApiMeta.empty(correlationId: headerCorrelationId);

  final success = envelope['success'] == true;
  if (success && status >= 200 && status < 300) {
    return ApiResponse<Object?>(
      data: envelope['data'],
      meta: meta,
      statusCode: status,
      replayedIdempotently: replayedIdempotently,
    );
  }

  final errorJson = envelope['error'];
  final error = errorJson is Map<Object?, Object?> ? Json.asObject(errorJson) : null;
  final mapped = ApiError.fromEnvelope(
    statusCode: statusCode,
    code: error == null ? null : Json.stringOrNull(error, 'code'),
    message: error == null ? null : Json.stringOrNull(error, 'message'),
    correlationId: meta.correlationId.isEmpty ? headerCorrelationId : meta.correlationId,
    details: error?['details'],
  );
  if (mapped is ApiRateLimited && retryAfter != null) {
    throw ApiRateLimited(
      code: mapped.code,
      message: mapped.message,
      retryAfter: retryAfter,
      correlationId: mapped.correlationId,
      statusCode: mapped.statusCode,
      details: mapped.details,
    );
  }
  throw mapped;
}
