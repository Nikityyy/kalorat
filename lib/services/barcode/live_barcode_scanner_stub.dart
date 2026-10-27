import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'live_barcode_scanner.dart';

LiveBarcodeScanner createLiveBarcodeScanner() => _NoBarcodeScanner();

class _NoBarcodeScanner implements LiveBarcodeScanner {
  @override
  void prewarm() {}

  @override
  Future<void> start(
    CameraController controller,
    BarcodeCallback onCode,
  ) async {}

  @override
  ValueListenable<double?> get backdrop => ValueNotifier<double?>(null);

  @override
  void setBackdrop(Rect region, double viewAspect) {}

  @override
  void setRegion(Rect? guide, Size view, {bool mirrored = false}) {}

  @override
  Future<Uint8List?> takeFrame() async => null;

  @override
  void holdPreview(bool hold) {}

  @override
  Future<ScannedBarcode?> decodeImage(XFile image) async => null;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
