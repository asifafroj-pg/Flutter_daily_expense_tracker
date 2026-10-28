import 'package:flutter/foundation.dart';

/// Minimal app logger. Debug-only output; never log tokens, PII or
/// request/response bodies (security.md, coding-style.md §10).
class AppLogger {
  const AppLogger._();

  /// Logs a debug-level message in debug builds only.
  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  /// Logs an informational message.
  static void info(String message) => debugPrint('[INFO] $message');

  /// Logs a warning with optional error/context.
  static void warn(String message, [Object? error]) {
    debugPrint('[WARN] $message${error != null ? ' ($error)' : ''}');
  }

  /// Logs an error. The error type is recorded, never sensitive payloads.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message${error != null ? ' ($error)' : ''}');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
