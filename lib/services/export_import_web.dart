// Web implementation for file export
import 'dart:js_interop';

@JS('kaloratSaveFile')
external JSPromise<JSString> _saveFile(
  String content,
  String fileName,
  String mime,
);

/// Offers [content] as a file: through the share sheet where the browser has
/// one, otherwise as a download. Returns 'shared', 'cancelled' or 'downloaded'.
Future<String> saveWebFile(
  String content,
  String fileName,
  String mime,
) async => (await _saveFile(content, fileName, mime).toDart).toDart;

Future<String> readNativeFile(String path) async {
  // Not used on web
  throw UnsupportedError('Native file reading not available on web');
}

Future<String?> writeNativeFile(String content, String fileName) async {
  // Not used on web
  throw UnsupportedError('Native file writing not available on web');
}
