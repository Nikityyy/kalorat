import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'frame_jpeg.dart';
import 'live_barcode_scanner.dart';

LiveBarcodeScanner createLiveBarcodeScanner() => _MlKitBarcodeScanner();

/// ML Kit on the camera image stream. ML Kit decodes on its own native
/// thread and reads codes at any angle. Frames that arrive while one is
/// being decoded, or sooner than [_minInterval], are skipped.
class _MlKitBarcodeScanner implements LiveBarcodeScanner {
  static const _minInterval = Duration(milliseconds: 100);

  BarcodeScanner? _scanner;
  CameraController? _controller;
  BarcodeCallback? _onCode;
  bool _busy = false;

  /// The last frame a code was read from.
  StreamFrame? _hitFrame;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  BarcodeScanner get _mlKit => _scanner ??= BarcodeScanner(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
    ],
  );

  @override
  void prewarm() => _mlKit;

  @override
  Future<void> start(
    CameraController controller,
    BarcodeCallback onCode,
  ) async {
    _onCode = onCode;
    if (identical(_controller, controller) &&
        controller.value.isStreamingImages) {
      return;
    }
    await stop();
    if (!controller.value.isInitialized) return;
    _controller = controller;
    try {
      await controller.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Barcode stream failed to start: $e');
      _controller = null;
    }
  }

  void _onFrame(CameraImage image) {
    final now = DateTime.now();
    if (_busy || now.difference(_lastFrame) < _minInterval) return;
    final input = _inputImage(image);
    if (input == null) return;
    _busy = true;
    _lastFrame = now;
    unawaited(_decode(input, image));
  }

  Future<void> _decode(InputImage input, CameraImage image) async {
    try {
      final barcodes = await _mlKit.processImage(input);
      final onCode = _onCode;
      if (onCode == null || _controller == null) return;
      for (final barcode in barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          _hitFrame = _streamFrame(image, input);
          onCode(
            ScannedBarcode(
              value,
              _formatName(barcode.format),
              bounds: _uprightBounds(barcode.boundingBox, image),
              frameAspect: _uprightAspect(image),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Barcode decode failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Android streams NV21 and iOS BGRA, each in one plane, as requested by
  /// the camera's image format group.
  InputImage? _inputImage(CameraImage image) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    final valid = Platform.isAndroid
        ? format == InputImageFormat.nv21
        : format == InputImageFormat.bgra8888;
    if (!valid || image.planes.length != 1) return null;
    final controller = _controller;
    if (controller == null) return null;
    final rotation =
        InputImageRotationValue.fromRawValue(
          controller.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Clockwise turn that makes a stream frame upright in the portrait app.
  /// Android delivers frames as the sensor sees them (landscape); iOS
  /// delivers them already turned to the preview's orientation.
  int _uprightRotation(CameraImage image) {
    if (image.height >= image.width) return 0;
    return (_controller?.description.sensorOrientation ?? 90) % 360;
  }

  double _uprightAspect(CameraImage image) {
    final turned = _uprightRotation(image) % 180 != 0;
    return turned ? image.height / image.width : image.width / image.height;
  }

  /// ML Kit's box as fractions of the upright frame. Android reports boxes
  /// in the rotated (upright) image, iOS in the frame as delivered.
  Rect? _uprightBounds(Rect box, CameraImage image) {
    final rotation = _uprightRotation(image);
    final turned = rotation % 180 != 0;
    if (Platform.isAndroid || !turned) {
      final w = (turned ? image.height : image.width).toDouble();
      final h = (turned ? image.width : image.height).toDouble();
      return Rect.fromLTRB(
        box.left / w,
        box.top / h,
        box.right / w,
        box.bottom / h,
      );
    }
    final l = box.left / image.width;
    final t = box.top / image.height;
    final r = box.right / image.width;
    final b = box.bottom / image.height;
    return rotation == 90
        ? Rect.fromLTRB(1 - b, l, 1 - t, r)
        : Rect.fromLTRB(t, 1 - r, b, 1 - l);
  }

  /// The plane bytes belong to Dart (the plugin copies each frame), so the
  /// frame can be kept without copying it again.
  StreamFrame _streamFrame(CameraImage image, InputImage input) {
    final metadata = input.metadata!;
    return StreamFrame(
      format: metadata.format == InputImageFormat.nv21
          ? StreamFrameFormat.nv21
          : StreamFrameFormat.bgra8888,
      bytes: image.planes.first.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: metadata.bytesPerRow,
      rotationDegrees: _uprightRotation(image),
    );
  }

  @override
  Future<Uint8List?> takeFrame() async {
    final frame = _hitFrame;
    if (frame == null) return null;
    try {
      return await compute(encodeStreamFrame, frame);
    } catch (e) {
      debugPrint('Barcode frame not converted: $e');
      return null;
    }
  }

  @override
  Future<ScannedBarcode?> decodeImage(XFile image) async {
    try {
      final barcodes = await _mlKit.processImage(
        InputImage.fromFilePath(image.path),
      );
      for (final barcode in barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          return ScannedBarcode(value, _formatName(barcode.format));
        }
      }
    } catch (e) {
      debugPrint('Barcode photo decode failed: $e');
    }
    return null;
  }

  static String _formatName(BarcodeFormat format) => switch (format) {
    BarcodeFormat.ean13 => 'EAN13',
    BarcodeFormat.ean8 => 'EAN8',
    BarcodeFormat.upca => 'UPCA',
    BarcodeFormat.upce => 'UPCE',
    _ => format.name.toUpperCase(),
  };

  @override
  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    _onCode = null;
    _hitFrame = null;
    if (controller == null) return;
    try {
      if (controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // The controller may already be disposed.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _scanner?.close();
    _scanner = null;
  }
}
