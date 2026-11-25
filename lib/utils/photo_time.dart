import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// When a photo was taken, from the capture time its camera wrote into it.
/// Supports both JPEG (APP1 EXIF) and Apple HEIC/HEIF (ISOBMFF `Exif` box).
/// Null when the photo does not say (screenshots, most shared images) or says
/// something no meal can have: a time in the future or before digital
/// cameras. Only container/header metadata is read, never the pixels.
DateTime? photoTakenAt(Uint8List bytes, {DateTime? now}) {
  DateTime? taken;
  if (_isJpeg(bytes)) {
    taken = _readJpegTakenAt(bytes);
  } else if (isIsobmffBytes(bytes)) {
    taken = _readHeicTakenAt(bytes);
  }
  if (taken == null) return null;

  final limit = (now ?? DateTime.now()).add(const Duration(minutes: 5));
  if (taken.isAfter(limit) || taken.year < 2000) return null;
  return taken;
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8;

/// True when [bytes] starts with an ISOBMFF `ftyp` header (`.heic` / `.heif`).
bool isIsobmffBytes(Uint8List bytes) =>
    bytes.length >= 12 &&
    bytes[4] == 0x66 && // f
    bytes[5] == 0x74 && // t
    bytes[6] == 0x79 && // y
    bytes[7] == 0x70; // p

DateTime? _readJpegTakenAt(Uint8List bytes) {
  final img.ExifData? exif;
  try {
    exif = img.decodeJpgExif(bytes);
  } catch (_) {
    return null;
  }
  if (exif == null) return null;

  DateTime? read(img.IfdValue? value) =>
      value == null ? null : parseExifDateTime(value.toString());

  try {
    final camera = exif.exifIfd;
    return read(camera[0x9003]) ?? // DateTimeOriginal
        read(camera[0x9004]) ?? // DateTimeDigitized
        read(exif.imageIfd[0x0132]); // DateTime
  } catch (_) {
    return null;
  }
}

/// Reads DateTimeOriginal / DateTimeDigitized / DateTime from an ISOBMFF
/// (`heic`/`heif`) container's `meta` -> `iinf`/`iloc` Exif item without decoding.
DateTime? _readHeicTakenAt(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  final len = bytes.length;
  var pos = 0;

  int? metaStart;
  int? metaEnd;
  while (pos + 8 <= len) {
    final box = _readBox(view, pos, len);
    if (box == null) break;
    if (box.type == 0x6D657461 /* 'meta' */ ) {
      metaStart = box.payload + 4; // FullBox: 4-byte version+flags
      metaEnd = box.end;
      break;
    }
    pos = box.end;
  }
  if (metaStart == null || metaEnd == null || metaStart >= metaEnd) {
    return null;
  }

  int? exifItemId;
  int? ilocStart;
  int? ilocEnd;

  var p = metaStart;
  while (p + 8 <= metaEnd) {
    final sub = _readBox(view, p, metaEnd);
    if (sub == null) break;
    if (sub.type == 0x69696E66 /* 'iinf' */ ) {
      exifItemId = _findExifItemId(view, bytes, sub.payload, sub.end);
    } else if (sub.type == 0x696C6F63 /* 'iloc' */ ) {
      ilocStart = sub.payload;
      ilocEnd = sub.end;
    }
    if (exifItemId != null && ilocStart != null) break;
    p = sub.end;
  }
  if (exifItemId == null || ilocStart == null || ilocEnd == null) {
    return null;
  }

  final extent = _findItemExtent(view, ilocStart, ilocEnd, exifItemId);
  if (extent == null || extent.offset + 4 >= len) return null;

  final exifBase = extent.offset;
  final exifLimit = (exifBase + extent.length).clamp(0, len);
  if (exifBase + 4 > exifLimit) return null;

  // ISOBMFF Exif item starts with a 4-byte big-endian offset before TIFF header.
  final tiffPrefixOffset = view.getUint32(exifBase, Endian.big);
  var tiffStart = exifBase + 4 + tiffPrefixOffset;
  if (tiffStart + 8 > exifLimit) return null;
  if (bytes[tiffStart] == 0x45 &&
      bytes[tiffStart + 1] == 0x78 &&
      bytes[tiffStart + 2] == 0x69 &&
      bytes[tiffStart + 3] == 0x66 &&
      tiffStart + 14 <= exifLimit) {
    tiffStart += 6;
  }

  return _readTiffDate(view, bytes, tiffStart, exifLimit);
}

({int type, int payload, int end})? _readBox(
  ByteData view,
  int pos,
  int limit,
) {
  if (pos + 8 > limit) return null;
  final size32 = view.getUint32(pos, Endian.big);
  final type = view.getUint32(pos + 4, Endian.big);
  int header = 8;
  int size;
  if (size32 == 1) {
    if (pos + 16 > limit) return null;
    // Read via 32-bit chunks: ByteData.getUint64 is unsupported in dart2js.
    final hi = view.getUint32(pos + 8, Endian.big);
    final lo = view.getUint32(pos + 12, Endian.big);
    if (hi != 0) return null;
    size = lo;
    header = 16;
  } else if (size32 == 0) {
    size = limit - pos;
  } else {
    size = size32;
  }
  if (size < header || pos + size > limit) return null;
  return (type: type, payload: pos + header, end: pos + size);
}

int? _findExifItemId(ByteData view, Uint8List bytes, int start, int end) {
  if (start + 6 > end) return null;
  final version = bytes[start];
  var cursor = start + 4;
  int count;
  if (version == 0) {
    if (cursor + 2 > end) return null;
    count = view.getUint16(cursor, Endian.big);
    cursor += 2;
  } else {
    if (cursor + 4 > end) return null;
    count = view.getUint32(cursor, Endian.big);
    cursor += 4;
  }

  for (var i = 0; i < count && cursor + 8 <= end; i++) {
    final infe = _readBox(view, cursor, end);
    if (infe == null) break;
    if (infe.type == 0x696E6665 /* 'infe' */ && infe.payload + 4 <= infe.end) {
      final v = bytes[infe.payload];
      if (v == 2 && infe.payload + 12 <= infe.end) {
        final itemId = view.getUint16(infe.payload + 4, Endian.big);
        final itemType = view.getUint32(infe.payload + 8, Endian.big);
        if (itemType == 0x45786966 /* 'Exif' */ ) return itemId;
      } else if (v == 3 && infe.payload + 14 <= infe.end) {
        final itemId = view.getUint32(infe.payload + 4, Endian.big);
        final itemType = view.getUint32(infe.payload + 10, Endian.big);
        if (itemType == 0x45786966 /* 'Exif' */ ) return itemId;
      }
    }
    cursor = infe.end;
  }
  return null;
}

({int offset, int length})? _findItemExtent(
  ByteData view,
  int start,
  int end,
  int targetId,
) {
  if (start + 8 > end) return null;
  final version = view.getUint8(start);
  if (version > 2) return null;
  final sizesA = view.getUint8(start + 4);
  final sizesB = view.getUint8(start + 5);
  final offsetSize = (sizesA >> 4) & 0xF;
  final lengthSize = sizesA & 0xF;
  final baseOffsetSize = (sizesB >> 4) & 0xF;
  final indexSize = (version == 1 || version == 2) ? (sizesB & 0xF) : 0;

  var cursor = start + 6;
  int itemCount;
  if (version < 2) {
    if (cursor + 2 > end) return null;
    itemCount = view.getUint16(cursor, Endian.big);
    cursor += 2;
  } else {
    if (cursor + 4 > end) return null;
    itemCount = view.getUint32(cursor, Endian.big);
    cursor += 4;
  }

  int readInt(int n) {
    if (n == 0 || cursor + n > end) return 0;
    var val = 0;
    for (var i = 0; i < n; i++) {
      // Multiply instead of << to avoid 32-bit truncation in dart2js.
      val = val * 256 + view.getUint8(cursor++);
    }
    return val;
  }

  for (var i = 0; i < itemCount && cursor < end; i++) {
    final itemId = version < 2 ? readInt(2) : readInt(4);
    final constructionMethod =
        (version == 1 || version == 2) ? (readInt(2) & 0xF) : 0;
    cursor += 2; // data_reference_index
    final baseOffset = readInt(baseOffsetSize);
    final extentCount = readInt(2);
    for (var j = 0; j < extentCount && cursor < end; j++) {
      if (indexSize > 0) cursor += indexSize;
      final extOffset = readInt(offsetSize);
      final extLength = readInt(lengthSize);
      if (j == 0 && itemId == targetId && constructionMethod == 0) {
        return (offset: baseOffset + extOffset, length: extLength);
      }
    }
  }
  return null;
}

DateTime? _readTiffDate(ByteData view, Uint8List bytes, int tiff, int limit) {
  final b0 = bytes[tiff];
  final b1 = bytes[tiff + 1];
  final Endian endian;
  if (b0 == 0x49 && b1 == 0x49) {
    endian = Endian.little;
  } else if (b0 == 0x4D && b1 == 0x4D) {
    endian = Endian.big;
  } else {
    return null;
  }
  if (view.getUint16(tiff + 2, endian) != 42) return null;
  final ifd0Rel = view.getUint32(tiff + 4, endian);

  String? dateTimePlain;
  String? dateTimeOriginal;
  String? dateTimeDigitized;

  void scanIfd(int ifdRel, {required bool isExif}) {
    final ifd = tiff + ifdRel;
    if (ifd < tiff || ifd + 2 > limit) return;
    final entries = view.getUint16(ifd, endian);
    for (var i = 0; i < entries; i++) {
      final entry = ifd + 2 + i * 12;
      if (entry + 12 > limit) break;
      final tag = view.getUint16(entry, endian);
      final type = view.getUint16(entry + 2, endian);
      final count = view.getUint32(entry + 4, endian);
      if (!isExif && tag == 0x8769 && (type == 4 || type == 13)) {
        final exifRel = view.getUint32(entry + 8, endian);
        scanIfd(exifRel, isExif: true);
      } else if (type == 2 &&
          count >= 16 &&
          count <= 64 &&
          ((isExif && (tag == 0x9003 || tag == 0x9004)) ||
              (!isExif && tag == 0x0132))) {
        final valOffset = tiff + view.getUint32(entry + 8, endian);
        if (valOffset >= tiff && valOffset + count <= limit) {
          final raw = String.fromCharCodes(bytes, valOffset, valOffset + count);
          if (tag == 0x9003) {
            dateTimeOriginal ??= raw;
          } else if (tag == 0x9004) {
            dateTimeDigitized ??= raw;
          } else {
            dateTimePlain ??= raw;
          }
        }
      }
    }
  }

  scanIfd(ifd0Rel, isExif: false);
  for (final candidate in [
    dateTimeOriginal,
    dateTimeDigitized,
    dateTimePlain,
  ]) {
    if (candidate == null) continue;
    final parsed = parseExifDateTime(candidate);
    if (parsed != null) return parsed;
  }
  return null;
}

/// "2026:10:24 12:41:07", the camera's local time.
DateTime? parseExifDateTime(String raw) {
  final match = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  final parts = [
    for (var i = 1; i <= 6; i++) int.tryParse(match.group(i) ?? '0') ?? 0,
  ];
  final [year, month, day, hour, minute, second] = parts;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  return DateTime(year, month, day, hour, minute, second);
}
