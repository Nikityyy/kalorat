import 'dart:typed_data';

/// Native captures stay full size as files.
Future<Uint8List> downscaleForStorage(Uint8List bytes) async => bytes;
