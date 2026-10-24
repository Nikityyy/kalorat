import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalorat/l10n/app_localizations_de.dart';
import 'package:kalorat/l10n/app_localizations_en.dart';
import 'package:kalorat/utils/meal_time_label.dart';
import 'package:kalorat/utils/photo_time.dart';

/// A small JPEG whose camera wrote [original] (and [plain] as the file time).
Uint8List jpeg({String? original, String? plain}) {
  final image = img.Image(width: 8, height: 8);
  if (original != null) image.exif.exifIfd['DateTimeOriginal'] = original;
  if (plain != null) image.exif.imageIfd['DateTime'] = plain;
  return img.encodeJpg(image);
}

void main() {
  final now = DateTime(2026, 10, 24, 19, 4);

  group('photoTakenAt', () {
    test('reads the capture time the camera wrote', () {
      expect(
        photoTakenAt(jpeg(original: '2026:10:24 12:41:07'), now: now),
        DateTime(2026, 10, 24, 12, 41, 7),
      );
    });

    test('falls back to the file time when there is no capture time', () {
      expect(
        photoTakenAt(jpeg(plain: '2026:10:23 08:12:30'), now: now),
        DateTime(2026, 10, 23, 8, 12, 30),
      );
    });

    test('prefers the capture time over the file time', () {
      final bytes = jpeg(
        original: '2026:10:23 08:12:30',
        plain: '2026:10:24 09:00:00',
      );
      expect(photoTakenAt(bytes, now: now), DateTime(2026, 10, 23, 8, 12, 30));
    });

    test('is null for a photo that does not say', () {
      expect(photoTakenAt(jpeg(), now: now), isNull);
    });

    test('is null for a time no meal can have', () {
      expect(
        photoTakenAt(jpeg(original: '2026:10:25 08:00:00'), now: now),
        isNull,
      );
      expect(
        photoTakenAt(jpeg(original: '1980:01:01 00:00:00'), now: now),
        isNull,
      );
      expect(
        photoTakenAt(jpeg(original: '0000:00:00 00:00:00'), now: now),
        isNull,
      );
    });

    test('is null for bytes that are not a JPEG', () {
      expect(photoTakenAt(Uint8List.fromList([1, 2, 3, 4]), now: now), isNull);
      expect(
        photoTakenAt(img.encodePng(img.Image(width: 2, height: 2))),
        isNull,
      );
    });
  });

  test('parseExifDateTime reads the camera format and rejects the rest', () {
    expect(
      parseExifDateTime('2026:10:24 12:41:07\u0000'),
      DateTime(2026, 10, 24, 12, 41, 7),
    );
    expect(
      parseExifDateTime('2026:10:24 12:41'),
      DateTime(2026, 10, 24, 12, 41),
    );
    expect(parseExifDateTime('2026-10-24 12:41:07'), isNull);
    expect(parseExifDateTime('2026:13:24 12:41:07'), isNull);
    expect(parseExifDateTime('    :  :     :  :  '), isNull);
  });

  test('mealTimeLabel names today and yesterday, else the date', () async {
    await initializeDateFormatting();
    final en = AppLocalizationsEn();
    final de = AppLocalizationsDe();
    expect(
      mealTimeLabel(en, 'en', DateTime(2026, 10, 24, 12, 41), now: now),
      'Today, 12:41',
    );
    expect(
      mealTimeLabel(de, 'de', DateTime(2026, 10, 23, 8, 12), now: now),
      'Gestern, 08:12',
    );
    expect(
      mealTimeLabel(en, 'en', DateTime(2026, 10, 20, 19, 5), now: now),
      'Oct 20, 2026, 19:05',
    );
  });
}
