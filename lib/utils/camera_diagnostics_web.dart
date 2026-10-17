import 'dart:js_interop';

/// Defined in `web/camera_diagnostics.js`.
@JS('kaloratCameraDiagnostics')
external String _diagnostics();

/// Defined in `web/camera_canvas.js`.
@JS('kaloratCameraCanvasEnabled')
external bool _canvasEnabled();

@JS('kaloratSetCameraCanvas')
external void _setCanvas(bool on);

String browserCameraDiagnostics() {
  try {
    return _diagnostics();
  } catch (e) {
    return 'diagnostics unavailable: $e';
  }
}

bool cameraCanvasPreviewEnabled() {
  try {
    return _canvasEnabled();
  } catch (_) {
    return false;
  }
}

void setCameraCanvasPreview(bool enabled) {
  try {
    _setCanvas(enabled);
  } catch (_) {}
}
