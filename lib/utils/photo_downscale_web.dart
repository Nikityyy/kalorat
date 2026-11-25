import 'dart:js_interop';
import 'dart:typed_data';

import 'app_logger.dart';
import 'photo_time.dart';

@JS('kaloratDownscaleJpeg')
external JSPromise<JSUint8Array> _downscaleJpeg(
  JSUint8Array bytes,
  int maxDimension,
  double quality,
);

@JS('kaloratCapturePreview')
external JSPromise<JSUint8Array?> _capturePreview(
  int maxDimension,
  double quality,
  bool mirrored,
);

/// Longest side of stored web photos, aligned with Gemini's 1536 px limit so
/// stored photos do not need a second decode + re-encode before upload.
const _maxDimension = 1536;
const _storageQuality = 0.85;
const _passthroughMaxBytes = 350 * 1024;

/// True when [bytes] is an ISOBMFF container (e.g. Apple `.HEIC`/`.HEIF`)
/// that the current browser failed to transcode into a web image format.
bool isUnreadableWebImage(Uint8List bytes) =>
    bytes.length < 12 || isIsobmffBytes(bytes);

int _readTiffOrientation(Uint8List bytes, int tiff, int end) {
  if (tiff + 8 > end) return 1;
  final le = bytes[tiff] == 0x49 && bytes[tiff + 1] == 0x49;
  final be = bytes[tiff] == 0x4D && bytes[tiff + 1] == 0x4D;
  if (!le && !be) return 1;

  final view = ByteData.sublistView(bytes);
  final endian = le ? Endian.little : Endian.big;
  if (view.getUint16(tiff + 2, endian) != 42) return 1;
  final ifd = tiff + view.getUint32(tiff + 4, endian);
  if (ifd < tiff || ifd + 2 > end) return 1;

  final count = view.getUint16(ifd, endian);
  for (var i = 0; i < count; i++) {
    final entry = ifd + 2 + i * 12;
    if (entry + 12 > end) break;
    if (view.getUint16(entry, endian) == 0x0112) {
      return view.getUint16(entry + 8, endian);
    }
  }
  return 1;
}

({int maxDim, int orientation})? _readJpegHeaderInfo(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var pos = 2;
  final len = bytes.length;
  var orientation = 1;
  int? maxDim;

  while (pos + 4 <= len) {
    if (bytes[pos] != 0xFF) break;
    while (pos < len && bytes[pos] == 0xFF) {
      pos++;
    }
    if (pos >= len) break;
    final marker = bytes[pos++];
    if (marker == 0xD9 || marker == 0xDA) break; // EOI or SOS (image stream)
    if (marker == 0x00 ||
        marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      continue;
    }
    if (pos + 2 > len) break;
    final segLen = (bytes[pos] << 8) | bytes[pos + 1];
    if (segLen < 2 || pos + segLen > len) break;

    if (marker == 0xE1 && segLen >= 16) {
      final d = pos + 2;
      if (bytes[d] == 0x45 &&
          bytes[d + 1] == 0x78 &&
          bytes[d + 2] == 0x69 &&
          bytes[d + 3] == 0x66 &&
          bytes[d + 4] == 0x00 &&
          bytes[d + 5] == 0x00) {
        orientation = _readTiffOrientation(bytes, d + 6, pos + segLen);
      }
    } else if ((marker == 0xC0 || marker == 0xC1 || marker == 0xC2) &&
        segLen >= 7) {
      final h = (bytes[pos + 3] << 8) | bytes[pos + 4];
      final w = (bytes[pos + 5] << 8) | bytes[pos + 6];
      if (w > 0 && h > 0) {
        maxDim = w > h ? w : h;
      }
    }
    pos += segLen;
  }

  return maxDim == null ? null : (maxDim: maxDim, orientation: orientation);
}

/// The frame the camera preview shows now, as a photo the size it is stored
/// at; null when there is no playing preview. The camera plugin's
/// takePicture encodes the full camera frame, which [downscaleForStorage]
/// then decoded and encoded again while the shutter spun. [mirrored] when
/// the preview is mirrored, as the plugin's pictures are.
Future<Uint8List?> capturePreviewForStorage({required bool mirrored}) async {
  try {
    return (await _capturePreview(
      _maxDimension,
      _storageQuality,
      mirrored,
    ).toDart)?.toDart;
  } catch (e) {
    AppLogger.warning('PhotoDownscale', 'Preview capture failed: $e');
    return null;
  }
}

/// Re-encodes a photo with the browser's decoder (fast, applies EXIF rotation,
/// drops metadata). Skips worker round-trip when already an upright JPEG within
/// [_maxDimension] and [_passthroughMaxBytes]. Falls back to original bytes if
/// the browser can't decode the format or the result would not be smaller.
Future<Uint8List> downscaleForStorage(Uint8List bytes) async {
  final info = _readJpegHeaderInfo(bytes);
  if (info != null &&
      info.orientation <= 1 &&
      info.maxDim <= _maxDimension &&
      bytes.length <= _passthroughMaxBytes) {
    return bytes;
  }
  try {
    final result = (await _downscaleJpeg(
      bytes.toJS,
      _maxDimension,
      _storageQuality,
    ).toDart).toDart;
    return result.isNotEmpty && result.length < bytes.length ? result : bytes;
  } catch (e) {
    AppLogger.warning('PhotoDownscale', 'Keeping original photo: $e');
    return bytes;
  }
}

/// A JPEG of at most [maxDimension] px for the analysis, made by the browser
/// off the main thread. Skips decode/re-encode when the photo is already an
/// upright JPEG within [maxDimension]. Null when the browser can't decode.
Future<Uint8List?> downscaleForAnalysis(
  Uint8List bytes,
  int maxDimension,
) async {
  final info = _readJpegHeaderInfo(bytes);
  if (info != null && info.orientation <= 1 && info.maxDim <= maxDimension) {
    return bytes;
  }
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
