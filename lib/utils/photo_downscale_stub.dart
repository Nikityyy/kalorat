import 'dart:typed_data';

/// Native captures stay full size as files.
Future<Uint8List> downscaleForStorage(Uint8List bytes) async => bytes;

/// Native builds resize for the analysis on a background isolate instead.
Future<Uint8List?> downscaleForAnalysis(
  Uint8List bytes,
  int maxDimension,
) async => null;
