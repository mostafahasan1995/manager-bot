import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal structured logger.
///
/// Uses `dart:developer` so lines show up in the IDE log view and in
/// `flutter logs`, and stays silent in release for everything below a warning.
/// No logging package is added: the dependency set is fixed.
abstract final class AppLogger {
  static const String _channel = 'manager_bot';

  /// Startup / lifecycle facts an operator wants to see once.
  static void info(String message, {String? scope}) {
    _emit(message, scope: scope, level: 800);
  }

  /// Chatter that only exists in debug builds (HTTP traces, redirects).
  static void debug(String message, {String? scope}) {
    if (!kDebugMode) {
      return;
    }
    _emit(message, scope: scope, level: 500);
  }

  /// Something recoverable happened that a human should know about.
  static void warn(String message, {String? scope}) {
    _emit(message, scope: scope, level: 900);
  }

  /// A failure. Always logged, including release builds.
  static void error(
    String message, {
    String? scope,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: scope == null ? _channel : '$_channel.$scope',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _emit(String message, {String? scope, required int level}) {
    if (kReleaseMode && level < 900) {
      return;
    }
    developer.log(
      message,
      name: scope == null ? _channel : '$_channel.$scope',
      level: level,
    );
  }
}
