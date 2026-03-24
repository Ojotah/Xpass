import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';
import 'exceptions.dart';

abstract final class ErrorHandler {
  static void handleFlutterError(FlutterErrorDetails details) {
    AppLogger.error(
      'Unhandled Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      scope: 'flutter',
    );
  }

  static String toUserMessage(Object error) {
    return switch (error) {
      WrongPasswordException() => 'Incorrect password',
      FileCorruptedException() => 'Vault file corrupted',
      VaultException() => 'Unable to load vault',
      _ => 'Something went wrong. Please try again.',
    };
  }

  static void logRecoverable(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      context,
      error: error,
      stackTrace: stackTrace,
      scope: 'recoverable',
    );
  }
}
