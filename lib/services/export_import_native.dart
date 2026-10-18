// Native (mobile/desktop) implementation for file read/write
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveWebFile(String content, String fileName, String mime) {
  // Not used on native
  throw UnsupportedError('Web file saving not available on native');
}

Future<String> readNativeFile(String path) async {
  final file = File(path);
  return file.readAsString();
}

Future<String?> writeNativeFile(String content, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}
