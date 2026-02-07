import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Cross-platform utility to detect the current platform.
/// Works on web without requiring dart:io imports.
class PlatformUtils {
  /// Returns true if running on web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if running on a mobile platform (iOS or Android)
  static bool get isMobile => !kIsWeb;

  /// Returns true if running on iOS
  /// Safely returns false on web without dart:io dependency
  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns true if running on Android
  /// Safely returns false on web without dart:io dependency
  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Get the health app name based on platform
  static String get healthAppName {
    if (isIOS) return 'Apple Health';
    if (isAndroid) return 'Health Connect';
    return 'Health'; // Fallback for web/other
  }
}
