import 'dart:typed_data';

import 'package:camera/camera.dart';

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
  Future<Uint8List?> takeFrame() async => null;

  @override
  Future<ScannedBarcode?> decodeImage(XFile image) async => null;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
