import 'dart:math';

/// Cryptographically-strong UUID v4 generator.
///
/// Deliberately hand-written: the dependency set is fixed and adding `uuid`
/// is not allowed. Backed by [Random.secure], which maps to the platform CSPRNG
/// on Android and iOS.
///
/// The output satisfies both backend patterns that matter:
/// * `Idempotency-Key`  -> `^[A-Za-z0-9_.:-]+$`, length 8..255
/// * `x-correlation-id` -> `^[A-Za-z0-9._-]{8,128}$`
abstract final class Uuid {
  static final Random _random = Random.secure();
  static const String _hex = '0123456789abcdef';

  /// Returns a canonical lowercase v4 UUID, e.g.
  /// `9f1c0f0a-6d3b-4a2e-9c1b-2f6a0d4e7b81`.
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256), growable: false);
    // Version 4 in the high nibble of byte 6, RFC-4122 variant in byte 8.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      final byte = bytes[i];
      buffer
        ..write(_hex[(byte >> 4) & 0x0f])
        ..write(_hex[byte & 0x0f]);
    }
    return buffer.toString();
  }

  /// A v4 UUID with a readable prefix, useful for correlation ids you want to
  /// spot in a server log: `mb-9f1c0f0a...`.
  ///
  /// Stays inside the 8..128 character correlation-id window for any prefix up
  /// to 90 characters; longer prefixes are truncated.
  static String prefixed(String prefix) {
    final sanitized = prefix.replaceAll(RegExp('[^A-Za-z0-9._-]'), '');
    final head = sanitized.length > 90 ? sanitized.substring(0, 90) : sanitized;
    return head.isEmpty ? v4() : '$head-${v4()}';
  }
}
