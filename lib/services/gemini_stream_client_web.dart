import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

@JS('fetch')
external JSPromise<JSObject> _fetch(String resource, JSObject options);

extension type FetchResponse(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSObject get body;
}

extension type ReadableStream(JSObject _) implements JSObject {
  external JSObject getReader();
}

extension type ReadableStreamDefaultReader(JSObject _) implements JSObject {
  external JSPromise<JSObject> read();
}

extension type ReadableStreamReadResult(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

Stream<String> makeStreamRequestPlatform({
  required http.Client client,
  required String url,
  required Map<String, String> headers,
  required String body,
  required Duration timeout,
}) {
  final controller = StreamController<String>();

  void runFetch() async {
    try {
      final jsHeaders = JSObject();
      headers.forEach((k, v) {
        jsHeaders[k] = v.toJS;
      });

      final fetchOptions = JSObject();
      fetchOptions['method'] = 'POST'.toJS;
      fetchOptions['headers'] = jsHeaders;
      fetchOptions['body'] = body.toJS;

      final responsePromise = _fetch(url, fetchOptions);
      final responseObj = await responsePromise.toDart.timeout(timeout);
      final response = FetchResponse(responseObj);

      if (!response.ok) {
        controller.addError(Exception('API HTTP error: ${response.status}'));
        controller.close();
        return;
      }

      final stream = ReadableStream(response.body);
      final reader = ReadableStreamDefaultReader(stream.getReader());

      while (true) {
        final readPromise = reader.read();
        final readResultObj = await readPromise.toDart.timeout(timeout);
        final readResult = ReadableStreamReadResult(readResultObj);

        if (readResult.done) {
          break;
        }

        final uint8Array = readResult.value;
        if (uint8Array != null) {
          final uint8List = uint8Array.toDart;
          final decoded = utf8.decode(uint8List);
          controller.add(decoded);
        }
      }
      controller.close();
    } catch (e, stack) {
      AppLogger.error('GeminiServiceWeb', 'Fetch streaming failed', e, stack);
      controller.addError(e);
      controller.close();
    }
  }

  runFetch();
  return controller.stream;
}
