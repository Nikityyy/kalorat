import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// When a photo was taken, from the capture time its camera wrote into it.
/// Null when the photo does not say (screenshots, most shared images) or says
/// something no meal can have: a time in the future or before digital
/// cameras. Only the header is read, never the pixels.
DateTime? photoTakenAt(Uint8List bytes, {DateTime? now}) {
  final img.ExifData? exif;
  try {
    exif = img.decodeJpgExif(bytes);
  } catch (_) {
    return null;
  }
  if (exif == null) return null;

  DateTime? read(img.IfdValue? value) =>
      value == null ? null : parseExifDateTime(value.toString());

  DateTime? taken;
  try {
    final camera = exif.exifIfd;
    taken =
        read(camera[0x9003]) ?? // DateTimeOriginal
        read(camera[0x9004]) ?? // DateTimeDigitized
        read(exif.imageIfd[0x0132]); // DateTime
  } catch (_) {
    return null;
  }
  if (taken == null) return null;

  final limit = (now ?? DateTime.now()).add(const Duration(minutes: 5));
  if (taken.isAfter(limit) || taken.year < 2000) return null;
  return taken;
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
