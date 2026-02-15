import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kalorat/services/gemini_service.dart';

// Simple mock client implementation to avoid mockito codegen dependency
class MockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;
  MockClient(this._handler);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

void main() {
  group('GeminiService', () {
    test('validateApiKey returns true for 200 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['key'], 'test_key');
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      });

      final service = GeminiService(apiKey: 'dummy', client: client);
      final result = await service.validateApiKey('test_key');
      expect(result, true);
    });

    test('validateApiKey returns false for error response', () async {
      final client = MockClient((request) async {
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 400);
      });

      final service = GeminiService(apiKey: 'dummy', client: client);
      final result = await service.validateApiKey('bad_key');
      expect(result, false);
    });
  });
}
