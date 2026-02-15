import 'dart:developer' as developer;

/// Lightweight structured logger using dart:developer.
/// Provides level-based logging with tag filtering.
class AppLogger {
  static const _name = 'Kalorat';

  static void debug(String tag, String message) {
    developer.log(message, name: '$_name.$tag', level: 500);
  }

  static void info(String tag, String message) {
    developer.log(message, name: '$_name.$tag', level: 800);
  }

  static void warning(String tag, String message) {
    developer.log(message, name: '$_name.$tag', level: 900);
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      message,
      name: '$_name.$tag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
