import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kalorat/services/barcode/frame_jpeg.dart';

void main() {
  group('encodeStreamFrame', () {
    test('converts padded NV21 and turns it upright', () {
      const width = 16;
      const height = 8;
      const stride = 20;
      final bytes = Uint8List(stride * height + stride * height ~/ 2);
      // Pure red is Y 81, U 90, V 240 in video range.
      bytes.fillRange(0, stride * height, 81);
      for (var i = stride * height; i < bytes.length; i += 2) {
        bytes[i] = 240;
        bytes[i + 1] = 90;
      }
      final jpeg = encodeStreamFrame(
        StreamFrame(
          format: StreamFrameFormat.nv21,
          bytes: bytes,
          width: width,
          height: height,
          bytesPerRow: width,
          rotationDegrees: 90,
        ),
      );
      final image = img.decodeJpg(jpeg)!;
      expect(image.width, height);
      expect(image.height, width);
      final pixel = image.getPixel(4, 8);
      expect(pixel.r, greaterThan(220));
      expect(pixel.g, lessThan(40));
      expect(pixel.b, lessThan(40));
    });

    test('converts BGRA with row padding', () {
      const width = 8;
      const height = 8;
      const stride = 40;
      final bytes = Uint8List(stride * height);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * stride + x * 4;
          bytes[i] = 255; // blue
          bytes[i + 3] = 255;
        }
      }
      final jpeg = encodeStreamFrame(
        StreamFrame(
          format: StreamFrameFormat.bgra8888,
          bytes: bytes,
          width: width,
          height: height,
          bytesPerRow: stride,
          rotationDegrees: 0,
        ),
      );
      final pixel = img.decodeJpg(jpeg)!.getPixel(4, 4);
      expect(pixel.b, greaterThan(220));
      expect(pixel.r, lessThan(40));
    });
  });
}
