import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

/// Stores meal photos outside the meal records.
///
/// Web builds used to inline photos as base64 in `meals_box`, which Hive loads
/// completely at startup. Photos now live in a lazy box and meals keep
/// `kphoto:<id>` references, so a photo's bytes load only when it is shown.
/// Native captures keep using file paths; [read] handles every format.
class PhotoStore {
  static const boxName = 'photos_box';
  static const _refPrefix = 'kphoto:';

  /// Orphans younger than this are kept: they may belong to a capture that
  /// has not been attached to a meal yet.
  static const orphanMinAge = Duration(hours: 1);

  static PhotoStore instance = PhotoStore(null);

  final LazyBox<Uint8List>? _box;
  final Random _random = Random();

  PhotoStore(this._box);

  static Future<PhotoStore> open() async =>
      PhotoStore(await Hive.openLazyBox<Uint8List>(boxName));

  static bool isRef(String path) => path.startsWith(_refPrefix);

  /// A legacy web photo stored directly in the meal as base64. File paths
  /// always contain a `.` (extension) and URLs a `:`; base64 has neither.
  /// Note JPEG base64 starts with `/9j/`, so a leading `/` proves nothing.
  static bool isInlineBase64(String path) =>
      path.length > 256 &&
      !isRef(path) &&
      !path.contains('.') &&
      !path.contains(':');

  Future<String> save(Uint8List bytes) async {
    final box = _box;
    if (box == null) throw StateError('Photo store is not open.');
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(0x7FFFFFFF).toRadixString(36)}';
    await box.put(id, bytes);
    return '$_refPrefix$id';
  }

  Future<Uint8List?> read(String path) async {
    if (path.isEmpty) return null;
    if (isRef(path)) return _box?.get(path.substring(_refPrefix.length));
    if (isInlineBase64(path)) return base64Decode(path);
    return XFile(path).readAsBytes();
  }

  Future<void> delete(String path) async {
    if (isRef(path)) await _box?.delete(path.substring(_refPrefix.length));
  }

  /// Deletes stored photos that no meal, pending capture or backup references.
  Future<int> deleteOrphans(Set<String> referencedPaths) async {
    final box = _box;
    if (box == null) return 0;
    final cutoff = DateTime.now().subtract(orphanMinAge).millisecondsSinceEpoch;
    final orphans = box.keys.where((key) {
      if (referencedPaths.contains('$_refPrefix$key')) return false;
      final createdAt = int.tryParse(key.toString().split('-').first);
      return createdAt != null && createdAt < cutoff;
    }).toList();
    await box.deleteAll(orphans);
    return orphans.length;
  }

  /// Image for [path]; [cacheWidth] decodes thumbnails small.
  ImageProvider imageProvider(String path, {int? cacheWidth}) {
    final ImageProvider provider = kIsWeb || isRef(path) || isInlineBase64(path)
        ? StoredPhotoImage(this, path)
        : FileImage(File(path));
    return ResizeImage.resizeIfNeeded(cacheWidth, null, provider);
  }
}

class StoredPhotoImage extends ImageProvider<StoredPhotoImage> {
  final PhotoStore store;
  final String path;

  const StoredPhotoImage(this.store, this.path);

  @override
  Future<StoredPhotoImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    StoredPhotoImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1.0);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await store.read(path);
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'Photo not found: ${path.length > 40 ? '${path.substring(0, 40)}…' : path}',
      );
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is StoredPhotoImage && other.path == path && other.store == store;

  @override
  int get hashCode => Object.hash(path, store);
}
