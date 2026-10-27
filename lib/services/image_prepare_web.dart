import 'dart:convert';
import 'dart:typed_data';

/// On the web the browser resizes photos (see downscaleForAnalysis); this
/// only runs when it could not decode one. The pure Dart decoder reads no
/// format the browser cannot, and it added about 450 KB to the web app that
/// every start had to load, so the photo goes as it is.
Map<String, String> prepareImageInIsolate(Map<String, dynamic> input) {
  final bytes = Uint8List.fromList((input['bytes'] as List).cast<int>());
  return {
    'data': base64Encode(bytes),
    'mimeType': input['mimeType']?.toString() ?? 'image/jpeg',
  };
}
