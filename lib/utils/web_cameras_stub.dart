import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Only the web build has a quicker way to find its cameras.
Future<List<CameraDescription>?> quickWebCameras({bool fresh = false}) async =>
    null;

void forgetQuickWebCameras() {}

/// The web build shows the last preview frame, softened, while the camera
/// starts again.
Future<Uint8List?> previewSnapshot() async => null;

Future<void> previewNextFrame({
  Duration timeout = const Duration(milliseconds: 1500),
}) async {}

/// Native previews are mirrored for the front camera only.
bool? previewMirrored() => null;

/// Native builds switch the torch through the camera plugin: null tells
/// the camera screen to use it.
bool? previewTorchAvailable() => null;

Future<bool?> setPreviewTorch(bool on) async => null;
