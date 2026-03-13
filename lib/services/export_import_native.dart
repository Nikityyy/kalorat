// Native (mobile/desktop) implementation for file read/write
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void triggerWebDownload(String content, String fileName) {
  // Not used on native
  throw UnsupportedError('Web download not available on native');
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
