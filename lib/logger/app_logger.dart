import 'package:flutter/foundation.dart';

/// Structured logging for the entire application
class AppLogger {
  static const String _tag = 'APP';

  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('🟢 [$timestamp] $logTag: $message');
      if (error != null) {
        debugPrint('🔴 ERROR: $error');
        if (stackTrace != null) {
          debugPrint('📝 STACKTRACE: $stackTrace');
        }
      }
    }
    // In production, you might want to send to Crashlytics or similar
  }

  static void info(String message, {String? tag}) {
    // Info logs should appear in debug mode, and potentially release
    // if you have a non-debugPrint logger (like 'logger' package).
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('🔵 [$timestamp] $logTag: $message');
    }
  }

  static void warning(String message, {String? tag, dynamic error}) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('🟡 [$timestamp] $logTag: $message');
      if (error != null) {
        debugPrint('🟠 WARNING: $error');
      }
    }
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String();

    // Always print errors, even in release builds, via debugPrint
    // A production logger (Firebase Crashlytics) is still preferred
    debugPrint('🔴 [$timestamp] $logTag: $message');
    if (error != null) {
      debugPrint('💥 ERROR: $error');
    }
    if (stackTrace != null) {
      debugPrint('📝 STACKTRACE: $stackTrace');
    }

    // TODO: Integrate with crash reporting service
    // if (!kDebugMode) {
    //   Crashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }

  static void performance(String message, {String? tag, int? executionTimeMs}) {
    if (kDebugMode) {
      final logTag = tag ?? 'PERF';
      final timestamp = DateTime.now().toIso8601String();
      final timeInfo = executionTimeMs != null ? ' (${executionTimeMs}ms)' : '';
      debugPrint('⚡ [$timestamp] $logTag: $message$timeInfo');
    }
  }
}