import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

// Minimal 1×1 white JPEG in base64 (valid image so readAsBytes on web path succeeds)
const _dummyBase64Jpeg =
    '/9j/4AAQSkZJRgABAQEAYABgAAD/4QBoRXhpZgAATU0AKgAAAAgABAEaAAUAAAABAAAAPgEbAAUAAAABAAAARgEoAAMAAAABAAIAAAExAAIAAAARAAAATgAAAAAAAABgAAAAAQAAAGAAAAABUGFpbnQuTkVUIDUuMS4xMQAA/9sAQwABAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/9sAQwEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/8AAEQgAAQABAwESAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/aAAwDAQACEQMRAD8A/v4ooA//2Q==';

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

    group('model sort order', () {
      late Directory tempDir;

      setUpAll(() async {
        // GeminiService opens a Hive box internally; init with a temp dir.
        tempDir = await Directory.systemTemp.createTemp('hive_test_');
        Hive.init(tempDir.path);
      });

      tearDownAll(() async {
        await Hive.close();
        await tempDir.delete(recursive: true);
      });

      test('non-lite Flash model comes before lite Flash model', () async {
        // Create a real temp file for the image so XFile.readAsBytes works on non-web
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));

        // Simulate the API returning a mixed list: lite first, then non-lite.
        // The service should sort them so non-lite (full Flash) is first.
        final modelsResponse = jsonEncode({
          'models': [
            {'name': 'models/gemini-flash-lite-latest'},
            {'name': 'models/gemini-flash-latest'},
          ],
        });

        // trackingClient handles both model-list and generateContent requests.
        String? firstModelCalled;
        final trackingClient = MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/models') && !path.contains(':generateContent')) {
            return http.StreamedResponse(
              Stream.value(utf8.encode(modelsResponse)),
              200,
            );
          }
          // Track first generateContent call
          firstModelCalled ??= path;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'text': jsonEncode({
                              'analysis_note': 'test',
                              'meal_name': 'Test',
                              'calories': 100,
                              'protein': 10,
                              'carbs': 10,
                              'fats': 5,
                              'detected_quantity': 1,
                              'detected_unit': 'serving',
                            }),
                          },
                        ],
                      },
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        });

        final trackingService = GeminiService(
          apiKey: 'test_key',
          client: trackingClient,
        );
        // We can't inspect private model list directly, but we CAN verify
        // that 'lite' does NOT appear in the first model path called.
        await trackingService.analyzeMeal([testFile.path]);
        // The first generateContent URL should NOT contain 'lite'
        if (firstModelCalled != null) {
          expect(
            firstModelCalled!.toLowerCase().contains('lite'),
            isFalse,
            reason: 'First model tried should not be a Lite model',
          );
        }
      });
    });
  });
}
