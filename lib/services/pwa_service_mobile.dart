import 'dart:async';
import 'pwa_service.dart';

class MobilePwaService implements PwaService {
  @override
  Stream<bool> get updateAvailableStream => const Stream.empty();

  @override
  bool get updateAvailable => false;

  @override
  void init() {
    // No-op on mobile
  }

  @override
  void performUpdate() {
    // No-op on mobile
  }

  @override
  void dispose() {
    // No-op on mobile
  }
}

PwaService createService() => MobilePwaService();
