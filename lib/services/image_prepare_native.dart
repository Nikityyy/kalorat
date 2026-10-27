import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Decode, resize and recompress an image off the UI isolate.
Map<String, String> prepareImageInIsolate(Map<String, dynamic> input) {
  final bytes = Uint8List.fromList((input['bytes'] as List).cast<int>());
  final decoded = img.decodeImage(bytes);
  final sourceMimeType = input['mimeType']?.toString() ?? 'image/jpeg';
  if (decoded == null) {
    return {'data': base64Encode(bytes), 'mimeType': sourceMimeType};
  }

  final maxDimension = input['maxDimension'] as int;
  final longest = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = longest > maxDimension
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? maxDimension
              : (decoded.width * maxDimension / decoded.height).round(),
          height: decoded.height > decoded.width
              ? maxDimension
              : (decoded.height * maxDimension / decoded.width).round(),
          interpolation: img.Interpolation.average,
        )
      : decoded;

  return {
    'data': base64Encode(img.encodeJpg(resized, quality: 82)),
    'mimeType': 'image/jpeg',
  };
}
