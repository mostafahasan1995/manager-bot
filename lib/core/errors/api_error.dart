import 'package:manager_bot/core/i18n/app_strings.dart';

/// Stable, never-translated `error.code` values from the backend envelope.
///
/// `error.code` is an OPEN string: feature modules (deposit, reconciliation)
/// add their own codes. NEVER model it as a closed Dart enum - a closed enum
/// crashes on the first feature code. Compare against these constants instead.
abstract final class ApiErrorCodes {
  // --- auth / principal ----------------------------------------------------
  static const String unauthenticated = 'UNAUTHENTICATED';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String sessionRevoked = 'SESSION_REVOKED';
  static const String refreshTokenInvalid = 'REFRESH_TOKEN_INVALID';
  static const String refreshTokenReused = 'REFRESH_TOKEN_REUSED';
  static const String wrongPrincipal = 'WRONG_PRINCIPAL';
  static const String forbidden = 'FORBIDDEN';
  static const String insufficientRole = 'INSUFFICIENT_ROLE';
  static const String adminNotFound = 'ADMIN_NOT_FOUND';
  static const String adminInactive = 'ADMIN_INACTIVE';

  // --- telegram initData / webhook (player surface, listed for completeness)
  static const String initDataMalformed = 'INIT_DATA_MALFORMED';
  static const String initDataHashMissing = 'INIT_DATA_HASH_MISSING';
  static const String initDataHashInvalid = 'INIT_DATA_HASH_INVALID';
  static const String initDataExpired = 'INIT_DATA_EXPIRED';
  static const String initDataAuthDateMissing = 'INIT_DATA_AUTH_DATE_MISSING';
  static const String initDataUserMissing = 'INIT_DATA_USER_MISSING';
  static const String initDataReplayed = 'INIT_DATA_REPLAYED';
  static const String telegramWebhookSecretInvalid = 'TELEGRAM_WEBHOOK_SECRET_INVALID';
  static const String callbackDataTooLong = 'CALLBACK_DATA_TOO_LONG';
  static const String callbackDataMalformed = 'CALLBACK_DATA_MALFORMED';

  // --- request shape -------------------------------------------------------
  static const String validationFailed = 'VALIDATION_FAILED';
  static const String invalidAmount = 'INVALID_AMOUNT';
  static const String invalidCurrency = 'INVALID_CURRENCY';
  static const String badRequest = 'BAD_REQUEST';
  static const String payloadTooLarge = 'PAYLOAD_TOO_LARGE';
  static const String unsupportedMediaType = 'UNSUPPORTED_MEDIA_TYPE';
  static const String methodNotAllowed = 'METHOD_NOT_ALLOWED';

  // --- resource / concurrency ---------------------------------------------
  static const String resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const String duplicateResource = 'DUPLICATE_RESOURCE';
  static const String referenceConstraint = 'REFERENCE_CONSTRAINT';
  static const String writeConflict = 'WRITE_CONFLICT';
  static const String lockUnavailable = 'LOCK_UNAVAILABLE';
  static const String businessRuleViolation = 'BUSINESS_RULE_VIOLATION';

  // --- idempotency (POST /v1/deposits is the only endpoint that demands it) -
  static const String idempotencyKeyRequired = 'IDEMPOTENCY_KEY_REQUIRED';
  static const String idempotencyKeyInvalid = 'IDEMPOTENCY_KEY_INVALID';
  static const String idempotencyInFlight = 'IDEMPOTENCY_IN_FLIGHT';
  static const String idempotencyKeyReused = 'IDEMPOTENCY_KEY_REUSED';

  // --- infrastructure ------------------------------------------------------
  static const String rateLimited = 'RATE_LIMITED';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String upstreamTimeout = 'UPSTREAM_TIMEOUT';
  static const String internalError = 'INTERNAL_ERROR';

  // --- client-side codes minted by this app (never sent by the server) -----
  /// The transport failed before any HTTP status existed.
  static const String clientNetworkFailure = 'CLIENT_NETWORK_FAILURE';

  /// A dio timeout (connect/send/receive) fired.
  static const String clientTimeout = 'CLIENT_TIMEOUT';

  /// The caller cancelled the request via a `CancelToken`.
  static const String clientCancelled = 'CLIENT_CANCELLED';

  /// The body was not the standard envelope (proxy page, helmet/CORS reject,
  /// body-parser failure before the translator, or plain garbage).
  static const String clientMalformedResponse = 'CLIENT_MALFORMED_RESPONSE';

  /// The admin login endpoint the app needs does not exist on the backend yet.
  static const String authUnsupported = 'AUTH_UNSUPPORTED';

  /// The dev-only bot code entered on the login screen was not accepted.
  static const String botCodeInvalid = 'BOT_CODE_INVALID';

  /// Codes that mean "your credentials are gone, sign in again".
  static const Set<String> reauthRequired = <String>{
    unauthenticated,
    invalidToken,
    tokenExpired,
    sessionRevoked,
    refreshTokenInvalid,
    refreshTokenReused,
  };
}

/// Every failure the app can surface, as a Dart 3 sealed hierarchy.
///
/// `ApiClient` NEVER lets a `DioException` escape: everything becomes one of
/// these. The human-facing wording lives in [AppStrings], so ask the error for
/// it rather than switching on the variant:
///
/// ```dart
/// Text(error.userMessage(context.s));
/// ```
sealed class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.correlationId,
    this.statusCode,
    this.details,
  });

  /// Builds the right variant from a decoded failure envelope.
  ///
  /// [statusCode] is the HTTP status (null for transport failures) and [code]
  /// is `error.code`. When the body was not an envelope at all, pass
  /// `code: null` and the status decides.
  ///
  /// A missing [message] is stored as the EMPTY string rather than as a
  /// synthesised English sentence: the wording is decided at render time by
  /// [userMessage], which has the active [AppStrings].
  factory ApiError.fromEnvelope({
    required int? statusCode,
    required String? code,
    required String? message,
    String? correlationId,
    Object? details,
  }) {
    final resolvedCode = (code == null || code.trim().isEmpty)
        ? _codeForStatus(statusCode)
        : code.trim();
    final resolvedMessage = message == null ? '' : message.trim();

    // The code wins over the status where they disagree, because the backend
    // sometimes answers 422 for an idempotency reuse and 409 for in-flight.
    switch (resolvedCode) {
      case ApiErrorCodes.idempotencyInFlight:
      case ApiErrorCodes.idempotencyKeyReused:
      case ApiErrorCodes.writeConflict:
      case ApiErrorCodes.lockUnavailable:
      case ApiErrorCodes.duplicateResource:
      case ApiErrorCodes.referenceConstraint:
        return ApiConflict(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case ApiErrorCodes.adminInactive:
      case ApiErrorCodes.adminNotFound:
      case ApiErrorCodes.wrongPrincipal:
      case ApiErrorCodes.insufficientRole:
      case ApiErrorCodes.forbidden:
        return ApiForbidden(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case ApiErrorCodes.rateLimited:
        return ApiRateLimited(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      default:
        break;
    }
    if (ApiErrorCodes.reauthRequired.contains(resolvedCode)) {
      return ApiUnauthorized(
        code: resolvedCode,
        message: resolvedMessage,
        correlationId: correlationId,
        statusCode: statusCode,
        details: details,
      );
    }

    switch (statusCode) {
      case 400:
      case 415:
      case 413:
      case 405:
        return ApiValidation(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
          fieldMessages: extractFieldStrings(details),
        );
      case 401:
        return ApiUnauthorized(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case 403:
        return ApiForbidden(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case 404:
        return ApiNotFound(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case 409:
        return ApiConflict(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case 422:
        return ApiBusinessRule(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      case 429:
        return ApiRateLimited(
          code: resolvedCode,
          message: resolvedMessage,
          correlationId: correlationId,
          statusCode: statusCode,
          details: details,
        );
      default:
        break;
    }
    final status = statusCode ?? 0;
    if (status >= 500) {
      return ApiServerError(
        code: resolvedCode,
        message: resolvedMessage,
        correlationId: correlationId,
        statusCode: statusCode,
        details: details,
      );
    }
    return ApiUnexpected(
      code: resolvedCode,
      message: resolvedMessage,
      correlationId: correlationId,
      statusCode: statusCode,
      details: details,
    );
  }

  /// Stable SCREAMING_SNAKE contract code. Switch on THIS, never on [message].
  final String code;

  /// The server's own sentence, verbatim. EMPTY when the envelope carried
  /// none - never read it directly, call [userMessage] or [resolvedMessage].
  final String message;

  /// `meta.correlationId` / the `x-correlation-id` response header. Support
  /// looks requests up by this, so show it on every non-trivial error.
  final String? correlationId;

  /// HTTP status, null when the failure happened before a response existed.
  final int? statusCode;

  /// `error.details`; the KEY IS ABSENT (not null) when the server has no
  /// context, so this is legitimately null most of the time.
  final Object? details;

  /// True when the only sane recovery is to send the admin back to login.
  bool get requiresReauth => this is ApiUnauthorized;

  /// True when repeating the IDENTICAL request may succeed.
  ///
  /// `WRITE_CONFLICT` is explicitly documented by the backend as safe to retry,
  /// and `IDEMPOTENCY_IN_FLIGHT` means "the same call is still running".
  bool get isRetryable => switch (this) {
        ApiTimeout() => true,
        ApiNetworkError(isCancelled: final cancelled) => !cancelled,
        ApiRateLimited() => true,
        ApiServerError(code: final c) =>
          c == ApiErrorCodes.serviceUnavailable || c == ApiErrorCodes.upstreamTimeout,
        ApiConflict(code: final c) =>
          c == ApiErrorCodes.writeConflict || c == ApiErrorCodes.idempotencyInFlight,
        ApiUnauthorized() => false,
        ApiForbidden() => false,
        ApiValidation() => false,
        ApiNotFound() => false,
        ApiBusinessRule() => false,
        ApiUnexpected() => false,
      };

  /// Localised stand-in for an envelope that carried no message at all.
  String defaultMessage(AppStrings s) {
    final status = statusCode;
    return status == null
        ? s.errorRequestFailed
        : s.errorServerReturnedStatus(status: status, code: code);
  }

  /// The server sentence when there is one, the localised default otherwise.
  String resolvedMessage(AppStrings s) =>
      message.isEmpty ? defaultMessage(s) : message;

  /// Short line for a snackbar. Always safe to show to an admin.
  String userMessage(AppStrings s) => resolvedMessage(s);

  /// Message plus the correlation id, for an error panel an admin can quote.
  String supportMessage(AppStrings s) {
    final id = correlationId;
    if (id == null || id.isEmpty) {
      return s.errorSupportLineShort(message: resolvedMessage(s), code: code);
    }
    return s.errorSupportLine(
      message: resolvedMessage(s),
      code: code,
      correlationId: id,
    );
  }

  /// `details.fields` as a list of strings.
  ///
  /// WARNING: the same key carries TWO different meanings, distinguished by
  /// [code]. For `VALIDATION_FAILED` it is a list of HUMAN-READABLE MESSAGES
  /// ("limit must be an integer"), so it must NOT be used to key form-field
  /// highlighting. For `DUPLICATE_RESOURCE` / `REFERENCE_CONSTRAINT` (Prisma
  /// P2002/P2003/P2000) it is a list of COLUMN NAMES.
  static List<String> extractFieldStrings(Object? details) {
    if (details is Map<Object?, Object?>) {
      final fields = details['fields'];
      if (fields is List<Object?>) {
        return fields
            .whereType<Object>()
            .map((value) => value.toString())
            .toList(growable: false);
      }
      final field = details['field'];
      if (field is String) {
        return <String>[field];
      }
    }
    return const <String>[];
  }

  /// Reads a string value out of `error.details` without leaking `dynamic`.
  String? detailString(String key) {
    final data = details;
    if (data is Map<Object?, Object?>) {
      final value = data[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  @override
  String toString() => '$runtimeType($code, status=$statusCode, "$message", '
      'correlationId=$correlationId)';

  static String _codeForStatus(int? status) => switch (status) {
        400 => ApiErrorCodes.badRequest,
        401 => ApiErrorCodes.unauthenticated,
        403 => ApiErrorCodes.forbidden,
        404 => ApiErrorCodes.resourceNotFound,
        405 => ApiErrorCodes.methodNotAllowed,
        409 => ApiErrorCodes.duplicateResource,
        413 => ApiErrorCodes.payloadTooLarge,
        415 => ApiErrorCodes.unsupportedMediaType,
        422 => ApiErrorCodes.businessRuleViolation,
        429 => ApiErrorCodes.rateLimited,
        503 => ApiErrorCodes.serviceUnavailable,
        504 => ApiErrorCodes.upstreamTimeout,
        _ => ApiErrorCodes.internalError,
      };
}

/// 401. The access token is missing, invalid, expired or revoked.
///
/// Admin tokens have NO server-side refresh, so the only recovery is a new
/// bot-code exchange. `AuthController` flips to `AuthExpired` on this.
final class ApiUnauthorized extends ApiError {
  const ApiUnauthorized({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  @override
  String userMessage(AppStrings s) => s.errorSessionNoLongerValid;
}

/// 403. Authenticated, but not allowed.
///
/// Includes `INSUFFICIENT_ROLE` (role too low), `WRONG_PRINCIPAL` (a player
/// token on an admin route) and `ADMIN_INACTIVE` / `ADMIN_NOT_FOUND` (the admin
/// record was disabled or removed while the token was still alive).
final class ApiForbidden extends ApiError {
  const ApiForbidden({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  bool get isAdminInactive => code == ApiErrorCodes.adminInactive;
  bool get isAdminMissing => code == ApiErrorCodes.adminNotFound;
  bool get isWrongPrincipal => code == ApiErrorCodes.wrongPrincipal;
  bool get isInsufficientRole => code == ApiErrorCodes.insufficientRole;

  @override
  String userMessage(AppStrings s) => switch (code) {
        ApiErrorCodes.adminInactive => s.errorAdminDeactivated,
        ApiErrorCodes.adminNotFound => s.errorAdminNotFound,
        ApiErrorCodes.wrongPrincipal => s.errorWrongPrincipal,
        ApiErrorCodes.insufficientRole => s.errorInsufficientRole,
        _ => resolvedMessage(s),
      };
}

/// 400 (and 405/413/415). A field/shape problem - render as field errors.
final class ApiValidation extends ApiError {
  const ApiValidation({
    required super.code,
    required super.message,
    this.fieldMessages = const <String>[],
    super.correlationId,
    super.statusCode,
    super.details,
  });

  /// See [ApiError.extractFieldStrings] for the two meanings of this list.
  final List<String> fieldMessages;

  /// True when the list holds Prisma COLUMN NAMES rather than sentences.
  bool get fieldsAreColumnNames =>
      code == ApiErrorCodes.duplicateResource ||
      code == ApiErrorCodes.referenceConstraint;

  @override
  String userMessage(AppStrings s) => fieldMessages.isEmpty
      ? resolvedMessage(s)
      : s.errorValidationWithFields(
          message: resolvedMessage(s),
          fields: fieldMessages.join('\n- '),
        );
}

/// 404. The deposit / destination / admin is gone or was never visible.
final class ApiNotFound extends ApiError {
  const ApiNotFound({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  @override
  String userMessage(AppStrings s) => s.errorRecordNotFound;
}

/// 409 (plus the 422 `IDEMPOTENCY_KEY_REUSED`).
///
/// IMPORTANT: in a review console this is a NORMAL outcome, not a crash. Two
/// admins opening the same deposit and both tapping Approve is expected; the
/// loser gets a conflict and simply needs a refresh. Treat it as "already
/// handled" and reload, do NOT show a red failure.
final class ApiConflict extends ApiError {
  const ApiConflict({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  /// A compare-and-set lost: someone else already moved this record.
  bool get isAlreadyHandled =>
      code == ApiErrorCodes.writeConflict ||
      code == ApiErrorCodes.duplicateResource ||
      code == ApiErrorCodes.lockUnavailable;

  /// The identical request is still running server-side; retry it shortly
  /// WITHOUT changing a single byte of the body.
  bool get isIdempotencyInFlight => code == ApiErrorCodes.idempotencyInFlight;

  /// The same Idempotency-Key was reused with a DIFFERENT body. This is a
  /// client bug; retrying never helps.
  bool get isIdempotencyKeyReused => code == ApiErrorCodes.idempotencyKeyReused;

  /// `details.since` on `IDEMPOTENCY_IN_FLIGHT`.
  DateTime? get inFlightSince {
    final raw = detailString('since');
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  @override
  String userMessage(AppStrings s) {
    if (isIdempotencyInFlight) {
      return s.errorRequestStillProcessing;
    }
    if (isIdempotencyKeyReused) {
      return s.errorRequestAlreadySubmitted;
    }
    return s.errorAlreadyHandledByOther;
  }
}

/// 422. A domain rule refused the action - render as a business message, not
/// as a field error (the payload was well formed).
final class ApiBusinessRule extends ApiError {
  const ApiBusinessRule({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });
}

/// 429. Back off on `retry-after` / the `x-ratelimit-*` headers.
final class ApiRateLimited extends ApiError {
  const ApiRateLimited({
    required super.code,
    required super.message,
    this.retryAfter,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  /// Parsed `retry-after` response header (seconds form), when present.
  final Duration? retryAfter;

  @override
  String userMessage(AppStrings s) {
    final wait = retryAfter;
    if (wait == null) {
      return s.errorTooManyRequests;
    }
    return s.errorTooManyRequestsRetryIn(seconds: wait.inSeconds);
  }
}

/// The request never reached the API (DNS, refused connection, no route,
/// TLS failure) or was cancelled by the caller.
final class ApiNetworkError extends ApiError {
  const ApiNetworkError({
    required super.message,
    super.code = ApiErrorCodes.clientNetworkFailure,
    this.isCancelled = false,
    super.correlationId,
    super.details,
  });

  final bool isCancelled;

  @override
  String userMessage(AppStrings s) =>
      isCancelled ? s.errorRequestCancelled : s.errorCannotReachServer;
}

/// A connect / send / receive timeout fired before the server answered.
final class ApiTimeout extends ApiError {
  const ApiTimeout({
    required super.message,
    super.code = ApiErrorCodes.clientTimeout,
    super.correlationId,
    super.details,
  });

  @override
  String userMessage(AppStrings s) => s.errorServerTookTooLong;
}

/// 5xx. Carries the correlation id so an admin can quote it to support.
final class ApiServerError extends ApiError {
  const ApiServerError({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  @override
  String userMessage(AppStrings s) {
    final id = correlationId;
    if (id == null || id.isEmpty) {
      return s.errorServerInternal;
    }
    return s.errorServerInternalWithRef(correlationId: id);
  }
}

/// The response was not the standard envelope, or could not be decoded.
///
/// Reached by: a proxy error page, a helmet/CORS rejection, a body-parser
/// failure before the translator, or a payload whose shape does not match what
/// a parser expected.
final class ApiUnexpected extends ApiError {
  const ApiUnexpected({
    required super.code,
    required super.message,
    super.correlationId,
    super.statusCode,
    super.details,
  });

  @override
  String userMessage(AppStrings s) => s.errorUnreadableFromServer;
}

/// Thrown by an [AdminAuthApi] operation the backend does not implement yet
/// (today: admin token REFRESH - there is no refresh token for admins).
///
/// This is deliberately NOT an [ApiError]: it is a capability gap, not a
/// request failure, and it must never be retried or silently swallowed.
class AuthUnsupportedError implements Exception {
  const AuthUnsupportedError(this.operation, this.reason);

  /// e.g. `refresh`.
  final String operation;

  /// Why it cannot work, in words a developer reading a crash report needs.
  final String reason;

  String get code => ApiErrorCodes.authUnsupported;

  @override
  String toString() => 'AuthUnsupportedError($operation): $reason';
}
