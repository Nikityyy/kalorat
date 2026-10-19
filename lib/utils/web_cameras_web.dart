import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_web/camera_web.dart';
// The plugin keeps the device id of each camera it hands out in
// camerasMetadata; CameraMetadata is not exported.
// ignore: implementation_imports
import 'package:camera_web/src/types/camera_metadata.dart';

/// Defined in `web/camera_devices.js`.
@JS('kaloratCameraDevices')
external JSPromise<JSString?> _devices(bool fresh);

@JS('kaloratForgetCameraDevices')
external void _forget();

@JS('kaloratPreviewSnapshot')
external JSPromise<JSUint8Array?> _snapshot();

@JS('kaloratPreviewNextFrame')
external JSPromise<JSAny?> _nextFrame(int timeoutMs);

/// The back and front camera, found without the plugin's
/// `availableCameras()`, which opens every camera of the device one after
/// the other. Null when they cannot be found this way; then the plugin's
/// list is used.
Future<List<CameraDescription>?> quickWebCameras({bool fresh = false}) async {
  final plugin = CameraPlatform.instance;
  if (plugin is! CameraPlugin) return null;
  try {
    final json = (await _devices(fresh).toDart)?.toDart;
    if (json == null) return null;
    final cameras = <CameraDescription>[];
    for (final entry in jsonDecode(json) as List<dynamic>) {
      final id = entry['id'] as String;
      final facing = entry['facing'] as String?;
      final camera = CameraDescription(
        name: id,
        lensDirection: switch (facing) {
          'environment' => CameraLensDirection.back,
          'user' => CameraLensDirection.front,
          _ => CameraLensDirection.external,
        },
        sensorOrientation: 0,
      );
      // Marked for tests, but it is the only way to give the plugin a camera
      // it did not find itself. Checked against camera_web 0.3.5.
      // ignore: invalid_use_of_visible_for_testing_member
      plugin.camerasMetadata[camera] = CameraMetadata(
        deviceId: id,
        facingMode: facing,
      );
      cameras.add(camera);
    }
    return cameras.isEmpty ? null : cameras;
  } catch (_) {
    return null;
  }
}

/// Drops the kept camera ids, e.g. when one no longer opens.
void forgetQuickWebCameras() {
  try {
    _forget();
  } catch (_) {}
}

/// A soft PNG of what the camera preview shows now, or null.
Future<Uint8List?> previewSnapshot() async {
  try {
    return (await _snapshot().toDart)?.toDart;
  } catch (_) {
    return null;
  }
}

/// Completes once the playing preview shows a new frame, or after
/// [timeout].
Future<void> previewNextFrame({
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  try {
    await _nextFrame(timeout.inMilliseconds).toDart;
  } catch (_) {}
}
