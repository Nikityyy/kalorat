import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/photo_time.dart';

Uint8List _u16(int v) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.big);

Uint8List _u32(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.big);

Uint8List _box(String type, List<int> payload) {
  final out = BytesBuilder();
  out.add(_u32(8 + payload.length));
  out.add(ascii.encode(type));
  out.add(payload);
  return out.toBytes();
}

Uint8List _fullBox(String type, int version, int flags, List<int> payload) {
  final body = BytesBuilder();
  body.addByte(version);
  body.addByte((flags >> 16) & 0xFF);
  body.addByte((flags >> 8) & 0xFF);
  body.addByte(flags & 0xFF);
  body.add(payload);
  return _box(type, body.toBytes());
}

Uint8List _syntheticHeicWithDate(String exifDate) {
  // Build TIFF payload with IFD0 -> ExifIFD(0x8769) -> DateTimeOriginal(0x9003).
  final dateBytes = [...ascii.encode(exifDate), 0];
  final tiff = BytesBuilder();
  // Little-endian header: 'II', 42, offset 8
  tiff.add(ascii.encode('II'));
  tiff.add([0x2A, 0x00, 0x08, 0x00, 0x00, 0x00]);
  // IFD0 at offset 8: 1 entry (14 bytes + 4 bytes next=0 -> ends at 26)
  tiff.add([0x01, 0x00]);
  // Tag 0x8769 (ExifIFDPointer), LONG (4), count 1, value offset 26
  tiff.add([0x69, 0x87, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 26, 0, 0, 0]);
  tiff.add([0x00, 0x00, 0x00, 0x00]);
  // ExifIFD at offset 26: 1 entry -> string stored at offset 44
  tiff.add([0x01, 0x00]);
  tiff.add([
    0x03, 0x90, // DateTimeOriginal
    0x02, 0x00, // ASCII
    dateBytes.length, 0x00, 0x00, 0x00,
    44, 0x00, 0x00, 0x00,
  ]);
  tiff.add([0x00, 0x00, 0x00, 0x00]);
  tiff.add(dateBytes);

  // ISOBMFF Exif item data: 4-byte offset to TIFF header (6 skips 'Exif\0\0') + 'Exif\0\0' + TIFF
  final exifPayload = BytesBuilder();
  exifPayload.add(_u32(6));
  exifPayload.add(ascii.encode('Exif'));
  exifPayload.add([0x00, 0x00]);
  exifPayload.add(tiff.toBytes());
  final mdatData = exifPayload.toBytes();

  final ftyp = _box('ftyp', [
    ...ascii.encode('heic'),
    0, 0, 0, 0,
    ...ascii.encode('mif1heic'),
  ]);
  final infe = _fullBox('infe', 2, 0, [
    ..._u16(42),
    ..._u16(0),
    ...ascii.encode('Exif'),
    0,
  ]);
  final iinf = _fullBox('iinf', 0, 0, [..._u16(1), ...infe]);
  // placeholder iloc offset patched once mdat payload start is known
  List<int> buildIloc(int offset) => _fullBox('iloc', 0, 0, [
    0x44, // offsetSize=4, lengthSize=4
    0x00, // baseOffsetSize=0, reserved=0
    ..._u16(1), // itemCount=1
    ..._u16(42), // itemID=42
    ..._u16(0), // dataRefIndex=0
    ..._u16(1), // extentCount=1
    ..._u32(offset),
    ..._u32(mdatData.length),
  ]);

  final mdatHeaderLen = 8;
  final dummyMeta = _fullBox('meta', 0, 0, [...iinf, ...buildIloc(0)]);
  final dataOffset = ftyp.length + dummyMeta.length + mdatHeaderLen;
  final meta = _fullBox('meta', 0, 0, [...iinf, ...buildIloc(dataOffset)]);
  final mdat = _box('mdat', mdatData);

  return Uint8List.fromList([...ftyp, ...meta, ...mdat]);
}

Uint8List _syntheticHeicWith64BitFreeBox(String exifDate) {
  final base = _syntheticHeicWithDate(exifDate);
  // Insert a 16-byte 64-bit-size 'free' box after ftyp; shift iloc's offset by +16.
  final ftypLen = base[3];
  final freeExt = Uint8List(16)
    ..buffer.asByteData().setUint32(0, 1, Endian.big)
    ..setRange(4, 8, ascii.encode('free'))
    ..buffer.asByteData().setUint32(12, 16, Endian.big);
  final shifted = Uint8List.fromList([
    ...base.sublist(0, ftypLen),
    ...freeExt,
    ...base.sublist(ftypLen),
  ]);
  // Locate 'mdat' box header; the preceding 8 bytes are iloc's extOffset + extLength.
  var mdatPos = ftypLen + 16;
  final view = shifted.buffer.asByteData();
  while (mdatPos + 8 <= shifted.length) {
    final len = view.getUint32(mdatPos, Endian.big);
    if (ascii.decode(shifted.sublist(mdatPos + 4, mdatPos + 8)) == 'mdat') break;
    mdatPos += len;
  }
  // Last 8 bytes of meta are extOffset (4B) + extLength (4B).
  final extOffsetPos = mdatPos - 8;
  view.setUint32(extOffsetPos, view.getUint32(extOffsetPos, Endian.big) + 16, Endian.big);
  return shifted;
}

void main() {
  test('reads DateTimeOriginal from ISOBMFF HEIC Exif item', () {
    final heic = _syntheticHeicWithDate('2026:10:19 14:32:10');
    expect(photoTakenAt(heic), DateTime(2026, 10, 19, 14, 32, 10));
  });

  test('returns null for corrupted or truncated HEIC bytes', () {
    final heic = _syntheticHeicWithDate('2026:10:19 14:32:10');
    expect(photoTakenAt(heic.sublist(0, 32)), isNull);
    expect(photoTakenAt(Uint8List.fromList([0, 1, 2, 3])), isNull);
    expect(isIsobmffBytes(heic), isTrue);
    expect(isIsobmffBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF])), isFalse);
  });

  test('supports 64-bit extended ISOBMFF box sizes safely', () {
    final heic = _syntheticHeicWith64BitFreeBox('2026:10:19 14:32:10');
    expect(photoTakenAt(heic), DateTime(2026, 10, 19, 14, 32, 10));

    final over4Gb = Uint8List.fromList([
      ...heic.sublist(0, heic[3]),
      0, 0, 0, 1,
      ...ascii.encode('free'),
      0, 0, 0, 1,
      0, 0, 0, 32,
      ...heic.sublist(heic[3]),
    ]);
    expect(photoTakenAt(over4Gb), isNull);
  });
}
