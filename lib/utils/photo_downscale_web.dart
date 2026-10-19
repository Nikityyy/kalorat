import 'dart:js_interop';
import 'dart:typed_data';

import 'app_logger.dart';

@JS('kaloratDownscaleJpeg')
external JSPromise<JSUint8Array> _downscaleJpeg(
  JSUint8Array bytes,
  int maxDimension,
  double quality,
);

/// Longest side of stored web photos. Analysis uses at most 1536 px.
const _maxDimension = 1600;

/// Re-encodes a photo with the browser's decoder (fast, applies EXIF rotation,
/// drops metadata). Falls back to the original bytes if the browser can't
/// decode the format or the result would not be smaller.
Future<Uint8List> downscaleForStorage(Uint8List bytes) async {
  try {
    final result = (await _downscaleJpeg(
      bytes.toJS,
      _maxDimension,
      0.85,
    ).toDart).toDart;
    return result.isNotEmpty && result.length < bytes.length ? result : bytes;
  } catch (e) {
    AppLogger.warning('PhotoDownscale', 'Keeping original photo: $e');
    return bytes;
  }
}

/// A JPEG of at most [maxDimension] px for the analysis, made by the browser
/// off the main thread. On the web `compute` runs on the main thread, where
/// the pure-Dart decoder froze the app for most of a second per photo.
/// Null when the browser can't decode the photo.
Future<Uint8List?> downscaleForAnalysis(
  Uint8List bytes,
  int maxDimension,
) async {
  try {
    final result = (await _downscaleJpeg(
      bytes.toJS,
      maxDimension,
      0.82,
    ).toDart).toDart;
    return result.isEmpty ? null : result;
  } catch (e) {
    AppLogger.warning('PhotoDownscale', 'Browser resize failed: $e');
    return null;
  }
}
