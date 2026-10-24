import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'live_barcode_scanner.dart';

LiveBarcodeScanner createLiveBarcodeScanner() => _WebBarcodeScanner();

@JS('kaloratBarcode')
external _BarcodeApi? get _api;

extension type _BarcodeApi(JSObject _) implements JSObject {
  external void prewarm();
  external void start(JSFunction onCode);
  external JSPromise<JSUint8Array?> takeFrame();
  external JSPromise<_StillResult?> decodeImage(JSUint8Array bytes);
  external double luma(
    double left,
    double top,
    double right,
    double bottom,
    double viewAspect,
  );
  external void stop();
  external void setRegion([
    double left,
    double top,
    double right,
    double bottom,
    double viewAspect,
    bool mirrored,
  ]);
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

  final ValueNotifier<double?> _backdrop = ValueNotifier<double?>(null);
  Rect? _backdropRegion;
  double _backdropAspect = 0;
  Timer? _backdropTimer;

  @override
  ValueListenable<double?> get backdrop => _backdrop;

  @override
  void setBackdrop(Rect region, double viewAspect) {
    _backdropRegion = region;
    _backdropAspect = viewAspect;
  }

  void _measureBackdrop() {
    final region = _backdropRegion;
    final api = _api;
    if (!_running || region == null || api == null) return;
    try {
      final value = api.luma(
        region.left,
        region.top,
        region.right,
        region.bottom,
        _backdropAspect,
      );
      _backdrop.value = value < 0 ? null : value;
    } catch (_) {
      _backdrop.value = null;
    }
  }

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
    _backdropTimer?.cancel();
    _backdropTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _measureBackdrop(),
    );
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
  void setRegion(Rect? guide, Size view, {bool mirrored = false}) {
    final api = _api;
    if (api == null) return;
    if (guide == null || view.isEmpty) {
      api.setRegion();
      return;
    }
    api.setRegion(
      guide.left / view.width,
      guide.top / view.height,
      guide.right / view.width,
      guide.bottom / view.height,
      view.width / view.height,
      mirrored,
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
    _backdropTimer?.cancel();
    _backdrop.value = null;
    _api?.stop();
  }

  @override
  Future<void> dispose() => stop();
}
