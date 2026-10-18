import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:camera/camera.dart';

import 'live_barcode_scanner.dart';

LiveBarcodeScanner createLiveBarcodeScanner() => _WebBarcodeScanner();

@JS('kaloratBarcode')
external _BarcodeApi? get _api;

extension type _BarcodeApi(JSObject _) implements JSObject {
  external void prewarm();
  external void start(JSFunction onCode);
  external JSPromise<JSUint8Array?> takeFrame();
  external JSPromise<_StillResult?> decodeImage(JSUint8Array bytes);
  external void stop();
}

extension type _StillResult(JSObject _) implements JSObject {
  external String get text;
  external String get format;
  external JSArray<JSNumber>? get box;
  external double get aspect;
}

/// [left, top, right, bottom] as fractions; -1 or missing means unknown.
Rect? _bounds(List<double>? box) {
  if (box == null || box.length != 4 || box.any((v) => v < 0)) return null;
  return Rect.fromLTRB(box[0], box[1], box[2], box[3]);
}

/// Drives web/barcode_scanner.js, which finds the preview <video> itself.
class _WebBarcodeScanner implements LiveBarcodeScanner {
  bool _running = false;

  @override
  void prewarm() => _api?.prewarm();

  @override
  Future<void> start(
    CameraController controller,
    BarcodeCallback onCode,
  ) async {
    final api = _api;
    if (api == null || _running) return;
    _running = true;
    api.start(
      ((
            JSString code,
            JSString format,
            JSNumber left,
            JSNumber top,
            JSNumber right,
            JSNumber bottom,
            JSNumber aspect,
          ) {
            if (!_running) return;
            onCode(
              ScannedBarcode(
                code.toDart,
                format.toDart,
                bounds: _bounds([
                  left.toDartDouble,
                  top.toDartDouble,
                  right.toDartDouble,
                  bottom.toDartDouble,
                ]),
                frameAspect: aspect.toDartDouble,
              ),
            );
          })
          .toJS,
    );
  }

  @override
  Future<Uint8List?> takeFrame() async {
    final api = _api;
    if (api == null) return null;
    try {
      return (await api.takeFrame().toDart)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScannedBarcode?> decodeImage(XFile image) async {
    final api = _api;
    if (api == null) return null;
    try {
      final bytes = await image.readAsBytes();
      final result = await api.decodeImage(bytes.toJS).toDart;
      if (result == null) return null;
      return ScannedBarcode(
        result.text,
        result.format,
        bounds: _bounds(result.box?.toDart.map((v) => v.toDartDouble).toList()),
        frameAspect: result.aspect,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _api?.stop();
  }

  @override
  Future<void> dispose() => stop();
}
