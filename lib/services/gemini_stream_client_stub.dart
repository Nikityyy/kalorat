import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Stream<String> makeStreamRequestPlatform({
  required http.Client client,
  required String url,
  required Map<String, String> headers,
  required String body,
  required Duration timeout,
}) async* {
  final request = http.Request('POST', Uri.parse(url));
  request.headers.addAll(headers);
  request.body = body;

  final streamedResponse = await client.send(request).timeout(timeout);

  if (streamedResponse.statusCode != 200) {
    final responseBody = await streamedResponse.stream.bytesToString();
    throw Exception('HTTP ${streamedResponse.statusCode}: $responseBody');
  }

  yield* streamedResponse.stream.transform(utf8.decoder);
}
