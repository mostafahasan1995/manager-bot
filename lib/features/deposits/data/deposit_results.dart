import 'dart:typed_data';

import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// `GET /{id}/proofs/{proofId}/url`.
///
/// A proof is a document identifying a real person, so no url is ever embedded
/// in a list response - it is minted on demand and lives for 5 minutes.
class ProofUrlResult {
  const ProofUrlResult({
    required this.streamPath,
    required this.expiresInSeconds,
    this.url,
  });

  factory ProofUrlResult.fromJson(Map<String, Object?> json) => ProofUrlResult(
        streamPath: Json.stringOrNull(json, 'streamPath') ?? '',
        expiresInSeconds: Json.integer(json, 'expiresInSeconds', orElse: 300),
        url: Json.stringOrNull(json, 'url'),
      );

  /// Relative, always present:
  /// `/v1/admin/deposits/<id>/proofs/<proofId>/content`.
  final String streamPath;

  /// Constant 300 today.
  final int expiresInSeconds;

  /// Presigned S3/MinIO GET, needing NO Authorization header. NULL on the LOCAL
  /// disk driver, which cannot sign - the client MUST then fall back to
  /// [streamPath].
  ///
  /// This is a bearer credential: never cache it, never log it.
  final String? url;

  bool get hasPresignedUrl {
    final String? value = url;
    return value != null && value.trim().isNotEmpty;
  }
}

/// `POST /{id}/retry-credit`.
class RetryCreditResult {
  const RetryCreditResult({required this.requeued, required this.creditKeyEpoch});

  factory RetryCreditResult.fromJson(Map<String, Object?> json) =>
      RetryCreditResult(
        requeued: Json.boolean(json, 'requeued', orElse: false),
        // int32 JSON number, NOT a string.
        creditKeyEpoch: Json.integer(json, 'creditKeyEpoch', orElse: 0),
      );

  /// False with the UNCHANGED epoch when the CAS found nothing to move.
  final bool requeued;

  /// New epoch (old + 1) on success, current epoch otherwise.
  final int creditKeyEpoch;
}

/// `POST /v1/admin/deposits/maintenance/sweep`.
///
/// Each pass is bounded to 100 rows per phase, so a backlog needs repeated
/// calls. Safe to call concurrently - every row moves through the same CAS.
class SweepReport {
  const SweepReport({
    required this.expired,
    required this.released,
    required this.reaped,
  });

  factory SweepReport.fromJson(Map<String, Object?> json) => SweepReport(
        expired: Json.integer(json, 'expired', orElse: 0),
        released: Json.integer(json, 'released', orElse: 0),
        reaped: Json.integer(json, 'reaped', orElse: 0),
      );

  /// DRAFT/AWAITING_PROOF rows past `expiresAt` moved to EXPIRED.
  final int expired;

  /// UNDER_REVIEW rows whose claim went stale, moved back to SUBMITTED.
  final int released;

  /// CREDITING rows untouched for 20 minutes, moved back to APPROVED.
  final int reaped;

  int get total => expired + released + reaped;

  bool get isNoop => total == 0;

  String summary(AppStrings s) {
    if (isNoop) {
      return s.sweepNothingToDo;
    }
    return s.sweepSummary(
      expired: expired,
      released: released,
      reaped: reaped,
    );
  }
}

/// The result of loading one proof image.
///
/// Sealed rather than "bytes or null" because an unavailable proof has a REASON
/// the reviewer needs: a receipt they cannot see is a reason not to approve.
sealed class ProofImage {
  const ProofImage();
}

/// Decoded bytes ready for `Image.memory`.
final class ProofImageBytes extends ProofImage {
  const ProofImageBytes({
    required this.bytes,
    required this.mimeType,
    required this.viaPresignedUrl,
  });

  final Uint8List bytes;

  /// Content type reported by the transport, falling back to the proof's own
  /// stored `mimeType`.
  final String mimeType;

  /// True when the bytes came from the presigned URL rather than streamed
  /// through the API.
  final bool viaPresignedUrl;

  int get sizeBytes => bytes.lengthInBytes;
}

/// The bytes could not be shown, with a reason worth putting on screen.
final class ProofImageUnavailable extends ProofImage {
  const ProofImageUnavailable({
    required this.code,
    required this.message,
    this.detail,
  });

  /// Stable-ish code for support: an `ApiErrorCodes`/`DepositErrorCodes` value
  /// or one of the client codes below.
  final String code;

  final String message;

  /// Extra technical context (status line, content type), never a credential.
  final String? detail;

  /// The API wrapped the byte stream in the JSON envelope, so no image was
  /// returned. A backend bug, not a client mistake.
  static const String codeEnvelopeInsteadOfBytes = 'PROOF_STREAM_ENVELOPED';

  /// The response was neither a known image format nor an envelope.
  static const String codeNotAnImage = 'PROOF_NOT_AN_IMAGE';

  /// The transport failed outright.
  static const String codeTransportFailed = 'PROOF_TRANSPORT_FAILED';
}

/// Magic-number sniffing for the byte payloads a proof can legitimately be.
///
/// Needed because `GET .../content` returns a Nest `StreamableFile` while the
/// GLOBAL `TransformInterceptor` wraps every non-envelope payload in JSON, so
/// the route can answer with an envelope where bytes were promised. Sniffing
/// turns that into an explained empty state instead of a broken image.
abstract final class ImageSniffer {
  /// Detected mime type, or null when the bytes are not a known image.
  static String? detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) {
      return null;
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // GIF: 'GIF8'
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    // BMP: 'BM'
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    // WEBP: 'RIFF' .... 'WEBP'
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  /// True when the payload is JSON text rather than an image - i.e. the API
  /// enveloped the stream.
  static bool looksLikeJson(Uint8List bytes) {
    for (final int byte in bytes) {
      // Skip leading whitespace: space, tab, CR, LF.
      if (byte == 0x20 || byte == 0x09 || byte == 0x0D || byte == 0x0A) {
        continue;
      }
      return byte == 0x7B || byte == 0x5B; // '{' or '['
    }
    return false;
  }
}
