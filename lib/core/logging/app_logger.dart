import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized, safe logger.
///
/// Never pass passwords, raw vault payloads, or other secrets.
abstract final class AppLogger {
  static void event(String message, {String scope = 'app'}) {
    developer.log(message, name: scope, level: 800);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String scope = 'app',
  }) {
    developer.log(message,
        name: scope, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String scope = 'app'}) {
    if (kDebugMode) {
      developer.log(message, name: scope, level: 500);
    }
  }
}
