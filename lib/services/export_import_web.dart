// Web implementation for file download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void triggerWebDownload(String content, String fileName) {
  final bytes = html.Blob([content], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  (html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click());
  html.Url.revokeObjectUrl(url);
}

Future<String> readNativeFile(String path) async {
  // Not used on web
  throw UnsupportedError('Native file reading not available on web');
}

Future<String?> writeNativeFile(String content, String fileName) async {
  // Not used on web
  throw UnsupportedError('Native file writing not available on web');
}
