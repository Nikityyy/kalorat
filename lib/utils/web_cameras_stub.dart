import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Only the web build has a quicker way to find its cameras.
Future<List<CameraDescription>?> quickWebCameras({bool fresh = false}) async =>
    null;

void forgetQuickWebCameras() {}

/// The web build shows the last preview frame while the camera switches.
Future<Uint8List?> previewSnapshot() async => null;
