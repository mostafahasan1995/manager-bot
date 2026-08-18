/// Thrown when a payload does not have the shape a hand-written parser expects.
///
/// Feature parsers should let this propagate: it means the backend contract
/// moved, and silently defaulting would corrupt a money screen.
class JsonParseException implements Exception {
  const JsonParseException(this.path, this.reason);

  /// Dotted path of the offending field, e.g. `data[0].amount.minor`.
  final String path;
  final String reason;

  @override
  String toString() => 'JsonParseException at "$path": $reason';
}

/// Type-safe readers for hand-written `fromJson` factories.
///
/// Every helper takes the already-decoded map and the key, so no `dynamic` ever
/// escapes a parser. The `require*` forms throw [JsonParseException]; the
/// nullable forms return null for an absent OR null value.
///
/// ```dart
/// factory AdminDepositView.fromJson(Map<String, Object?> json) => AdminDepositView(
///       shortId: Json.string(json, 'shortId'),
///       playerTelegramUserId: Json.bigIntOrNull(json, 'playerTelegramUserId'),
///       claimed: Money.fromMoneyView(Json.object(json, 'claimed')),
///       credited: Money.fromMoneyViewOrNull(json['credited']),
///       createdAt: Json.dateTime(json, 'createdAt'),
///       riskFlags: Json.stringList(json, 'riskFlags'),
///     );
/// ```
abstract final class Json {
  /// Coerces any decoded JSON object into `Map<String, Object?>`.
  ///
  /// dio hands back `Map<String, dynamic>`; this normalises it once so parsers
  /// can use a single type everywhere.
  static Map<String, Object?> asObject(Object? value, {String path = r'$'}) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map<Object?, Object?>) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw JsonParseException(path, 'expected an object, got ${value.runtimeType}');
  }

  /// Coerces any decoded JSON array into `List<Object?>`.
  static List<Object?> asArray(Object? value, {String path = r'$'}) {
    if (value is List<Object?>) {
      return value;
    }
    throw JsonParseException(path, 'expected an array, got ${value.runtimeType}');
  }

  /// Maps a JSON array of objects with a hand-written factory.
  static List<T> list<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson, {
    String path = r'$',
  }) {
    final array = asArray(value, path: path);
    final result = <T>[];
    for (var i = 0; i < array.length; i++) {
      result.add(fromJson(asObject(array[i], path: '$path[$i]')));
    }
    return List<T>.unmodifiable(result);
  }

  static String string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw JsonParseException(key, 'expected a string, got ${value.runtimeType}');
  }

  static String? stringOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String ? value : null;
  }

  static List<String> stringList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return const <String>[];
    }
    if (value is List<Object?>) {
      return List<String>.unmodifiable(value.whereType<String>());
    }
    throw JsonParseException(key, 'expected an array of strings');
  }

  static bool boolean(Map<String, Object?> json, String key, {bool? orElse}) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (orElse != null) {
      return orElse;
    }
    throw JsonParseException(key, 'expected a bool, got ${value.runtimeType}');
  }

  static bool? boolOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is bool ? value : null;
  }

  /// Reads a plain 32-bit-safe integer (page metas, counts, uptime).
  ///
  /// NEVER use this for a Telegram id or a money amount - those arrive as
  /// strings and exceed 2^53. Use [bigInt] or `Money` instead.
  static int integer(Map<String, Object?> json, String key, {int? orElse}) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    if (orElse != null) {
      return orElse;
    }
    throw JsonParseException(key, 'expected an int, got ${value.runtimeType}');
  }

  static int? intOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Reads a 64-bit id (Telegram user/chat/message/thread/update ids).
  ///
  /// The backend patches `BigInt.prototype.toJSON`, so every one of these
  /// arrives as a decimal STRING. Parsing it as `int` would be lossy on the
  /// web and is simply wrong as a contract.
  static BigInt bigInt(Map<String, Object?> json, String key) {
    final parsed = bigIntOrNull(json, key);
    if (parsed == null) {
      throw JsonParseException(key, 'expected a 64-bit decimal string');
    }
    return parsed;
  }

  static BigInt? bigIntOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return BigInt.tryParse(value.trim());
    }
    if (value is int) {
      return BigInt.from(value);
    }
    return null;
  }

  /// Parses an ISO-8601 timestamp and returns it in LOCAL time.
  static DateTime dateTime(Map<String, Object?> json, String key) {
    final parsed = dateTimeOrNull(json, key);
    if (parsed == null) {
      throw JsonParseException(key, 'expected an ISO-8601 timestamp');
    }
    return parsed;
  }

  static DateTime? dateTimeOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  static Map<String, Object?> object(Map<String, Object?> json, String key) =>
      asObject(json[key], path: key);

  static Map<String, Object?>? objectOrNull(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    return asObject(value, path: key);
  }

  /// Maps a wire enum string onto a Dart enum, falling back to [orElse].
  ///
  /// Backend enums grow. A closed parse that throws on an unknown member turns
  /// a new deposit status into a crashed queue screen, so callers should pass a
  /// neutral fallback rather than throwing.
  static T enumValue<T>(
    Map<String, Object?> json,
    String key,
    Map<String, T> byWireName, {
    required T orElse,
  }) {
    final raw = stringOrNull(json, key);
    if (raw == null) {
      return orElse;
    }
    return byWireName[raw.trim().toUpperCase()] ?? orElse;
  }
}
