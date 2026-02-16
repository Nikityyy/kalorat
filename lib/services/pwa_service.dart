import 'dart:async';
import 'pwa_service_mobile.dart' if (dart.library.html) 'pwa_service_web.dart';

/// Service to handle PWA-specific lifecycle events, especially updates.
abstract class PwaService {
  Stream<bool> get updateAvailableStream;
  bool get updateAvailable;
  void init();
  void performUpdate();
  void dispose();

  factory PwaService() => createService();
}
