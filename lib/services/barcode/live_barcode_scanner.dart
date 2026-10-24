import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import 'live_barcode_scanner_stub.dart'
    if (dart.library.js_interop) 'live_barcode_scanner_web.dart'
    if (dart.library.io) 'live_barcode_scanner_native.dart';

/// A code read from a camera frame or a photo.
class ScannedBarcode {
  final String code;

  /// e.g. 'EAN13' or 'UPCE'.
  final String format;

  /// Where the code is, as fractions of the upright frame; null when the
  /// decoder did not say. For a 1D code this can be the scan line only.
  final Rect? bounds;

  /// Width / height of the upright frame; 0 when unknown.
  final double frameAspect;

  const ScannedBarcode(
    this.code,
    this.format, {
    this.bounds,
    this.frameAspect = 0,
  });
}

typedef BarcodeCallback = void Function(ScannedBarcode barcode);

/// Reads retail barcodes from the live camera preview in the background.
///
/// Web: zxing-cpp (WebAssembly) in a worker reads frames of the preview
/// video (web/barcode_scanner.js). Android and iOS: ML Kit reads the camera
/// image stream. Either way at most about ten frames a second, one at a
/// time, never on the UI thread.
abstract class LiveBarcodeScanner {
  factory LiveBarcodeScanner() => createLiveBarcodeScanner();

  /// Loads the decoder ahead of the first scan.
  void prewarm();

  /// Starts reading from [controller]; calls [onCode] for each frame with a
  /// code. Calling it again with the same controller does nothing.
  Future<void> start(CameraController controller, BarcodeCallback onCode);

  /// Reads only around [guide], a rectangle of the [view] the preview covers
  /// (like `BoxFit.cover`), when the scanner can crop; null reads the whole
  /// frame. [mirrored] for a front camera.
  void setRegion(Rect? guide, Size view, {bool mirrored = false});

  /// How bright the camera picture is behind the [setBackdrop] region, 0 to 1,
  /// a few times a second while scanning; null when not known. It lets the
  /// logo over the preview turn dark over a bright picture.
  ValueListenable<double?> get backdrop;

  /// The part of the preview to measure for [backdrop]: [region] as fractions
  /// of the view, whose width / height is [viewAspect].
  void setBackdrop(Rect region, double viewAspect);

  /// A JPEG of the frame the last code was read from, upright, or null.
  /// Call it from the [BarcodeCallback]: stopping the scanner drops the
  /// frame.
  Future<Uint8List?> takeFrame();

  /// Reads the first retail code in a photo; null when there is none.
  Future<ScannedBarcode?> decodeImage(XFile image);

  Future<void> stop();

  Future<void> dispose();
}
