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

String _sseTextEvent(String text) {
  return 'data: ${jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  })}\n\n';
}

String _sseThoughtEvent(String text) {
  return 'data: ${jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text, 'thought': true},
          ],
        },
      },
    ],
  })}\n\n';
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

      test('lite Flash model comes before full Flash model', () async {
        // Create a real temp file for the image so XFile.readAsBytes works on non-web
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));

        // Simulate the API returning a mixed list: non-lite first, then lite.
        // The service should sort them so lite model is first.
        final modelsResponse = jsonEncode({
          'models': [
            {'name': 'models/gemini-flash-latest'},
            {'name': 'models/gemini-flash-lite-latest'},
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
        await trackingService.analyzeMeal([testFile.path]);
        if (firstModelCalled != null) {
          expect(
            firstModelCalled!.toLowerCase().contains('lite'),
            isTrue,
            reason: 'First model tried should not be a non-Lite model',
          );
        }
      });

      test(
        'streaming thoughts do not expose split JSON fence marker',
        () async {
          final testFile = File('${tempDir.path}/stream_test_image.jpg');
          await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));

          final resultJson = jsonEncode({
            'analysis_note': 'test',
            'meal_name': 'Test',
            'calories': 100,
            'protein': 10,
            'carbs': 10,
            'fats': 5,
            'detected_quantity': 1,
            'detected_unit': 'serving',
          });

          var streamRequestCount = 0;
          final client = MockClient((request) async {
            if (request.method == 'GET') {
              return http.StreamedResponse(
                Stream.value(
                  utf8.encode(
                    jsonEncode({
                      'models': [
                        {'name': 'models/gemini-flash-lite-latest'},
                      ],
                    }),
                  ),
                ),
                200,
              );
            }

            streamRequestCount += 1;
            final chunks = streamRequestCount == 1
                ? [
                    _sseTextEvent('### Analyse der Mahlzeit\n'),
                    _sseTextEvent('```json\n'),
                    _sseTextEvent('$resultJson\n```'),
                  ]
                : [_sseTextEvent(resultJson)];

            return http.StreamedResponse(
              Stream.fromIterable(chunks.map(utf8.encode)),
              200,
            );
          });

          final service = GeminiService(apiKey: 'test_key', client: client);
          final thoughts = <String>[];

          await for (final event in service.analyzeMealStream([
            testFile.path,
          ])) {
            if (event is ThoughtChunk) {
              thoughts.add(event.text);
            }
          }

          final visibleThoughtText = thoughts.join();
          expect(visibleThoughtText, contains('Analyse der Mahlzeit'));
          expect(visibleThoughtText, isNot(contains('```json')));
          expect(visibleThoughtText, isNot(contains('```')));
        },
      );

      test(
        'streaming thoughts hide format chatter from visible summary',
        () async {
          final testFile = File('${tempDir.path}/stream_thought_image.jpg');
          await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));

          final resultJson = jsonEncode({
            'analysis_note': 'test',
            'meal_name': 'Test',
            'calories': 100,
            'protein': 10,
            'carbs': 10,
            'fats': 5,
            'detected_quantity': 1,
            'detected_unit': 'serving',
          });

          var streamRequestCount = 0;
          final client = MockClient((request) async {
            if (request.method == 'GET') {
              return http.StreamedResponse(
                Stream.value(
                  utf8.encode(
                    jsonEncode({
                      'models': [
                        {'name': 'models/gemini-flash-lite-latest'},
                      ],
                    }),
                  ),
                ),
                200,
              );
            }

            streamRequestCount += 1;
            final chunks = streamRequestCount == 1
                ? [
                    _sseThoughtEvent('- Ich erkenne Brot und Kaese.\n'),
                    _sseThoughtEvent('- JSON wird vorbereitet.\n'),
                    _sseTextEvent(resultJson),
                  ]
                : [_sseTextEvent(resultJson)];

            return http.StreamedResponse(
              Stream.fromIterable(chunks.map(utf8.encode)),
              200,
            );
          });

          final service = GeminiService(apiKey: 'test_key', client: client);
          final thoughts = <String>[];

          await for (final event in service.analyzeMealStream([
            testFile.path,
          ])) {
            if (event is ThoughtChunk) {
              thoughts.add(event.text);
            }
          }

          final visibleThoughtText = thoughts.join();
          expect(visibleThoughtText, contains('Brot und Kaese'));
          expect(visibleThoughtText.toLowerCase(), isNot(contains('json')));
        },
      );
    });
  });
}
