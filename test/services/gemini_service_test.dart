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

      test('accurate mode still uses Flash Lite by default', () async {
        // Create a real temp file for the image so XFile.readAsBytes works on non-web
        final testFile = File('${tempDir.path}/test_image.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));

        // Accurate Mode changes thinking depth, while the default model remains Flash Lite.
        String? firstModelCalled;
        final trackingClient = MockClient((request) async {
          final path = request.url.path;
          // Track the single analysis request.
          firstModelCalled ??= path;
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
          final chunks = [
            _sseTextEvent('```json\n'),
            _sseTextEvent('$resultJson\n```'),
          ];
          return http.StreamedResponse(
            Stream.fromIterable(chunks.map(utf8.encode)),
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
            reason: 'Accurate mode should use Flash Lite by default',
          );
        }
      });

      test(
        'aggregates complete item nutrition and preserves uncertainty range',
        () async {
          final testFile = File('${tempDir.path}/aggregation_test.jpg');
          await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
          var getCount = 0;
          Map<String, dynamic>? requestPayload;
          final client = MockClient((request) async {
            if (request.method == 'GET') getCount++;
            if (request is http.Request && request.method == 'POST') {
              requestPayload = jsonDecode(request.body) as Map<String, dynamic>;
            }
            final resultJson = jsonEncode({
              'analysis_note': 'test',
              'uncertainty_note': 'Oil amount is not fully visible.',
              'meal_name': 'Rice bowl',
              'calories': 999,
              'protein': 99,
              'carbs': 99,
              'fats': 99,
              'calories_per_100g': 999,
              'protein_per_100g': 99,
              'carbs_per_100g': 99,
              'fats_per_100g': 99,
              'detected_quantity': 2,
              'detected_unit': 'serving',
              'photo_interpretation': 'clear',
              'confidence_score': 0.8,
              'items': [
                {
                  'name': 'Rice',
                  'estimated_quantity': 1,
                  'unit': 'serving',
                  'calories': 300,
                  'protein': 6,
                  'carbs': 60,
                  'fats': 2,
                  'calories_min': 300,
                  'calories_max': 300,
                  'confidence': 0.9,
                  'assumption': '',
                },
                {
                  'name': 'Cooking oil',
                  'estimated_quantity': 1,
                  'unit': 'tsp',
                  'calories': 90,
                  'protein': 0,
                  'carbs': 0,
                  'fats': 10,
                  'calories_min': 20,
                  'calories_max': 120,
                  'confidence': 0.4,
                  'assumption': 'Amount hidden by the food.',
                },
              ],
            });
            return http.StreamedResponse(
              Stream.value(utf8.encode(_sseTextEvent(resultJson))),
              200,
            );
          });

          final result = await GeminiService(
            apiKey: 'aggregation_key',
            client: client,
          ).analyzeMeal([testFile.path]);

          expect(
            getCount,
            0,
            reason: 'Stable aliases must avoid model discovery',
          );
          expect(result, isNotNull);
          expect(result!['calories'], 195);
          expect(result['protein'], 3);
          expect(result['carbs'], 30);
          expect(result['fats'], 6);
          expect(result['calories_min'], 160);
          expect(result['calories_max'], 210);
          expect(result['uncertainty_note'], contains('Oil'));
          final generationConfig =
              requestPayload!['generationConfig'] as Map<String, dynamic>;
          final thinkingConfig =
              generationConfig['thinkingConfig'] as Map<String, dynamic>;
          expect(thinkingConfig['thinkingLevel'], 'medium');
          expect(thinkingConfig['includeThoughts'], true);
          expect(generationConfig['maxOutputTokens'], 3072);
        },
      );

      test('fast mode uses low thinking level', () async {
        final testFile = File('${tempDir.path}/fast_mode_image.jpg');
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
        Map<String, dynamic>? requestPayload;
        final modelPaths = <String>[];
        final client = MockClient((request) async {
          final concreteRequest = request as http.Request;
          modelPaths.add(concreteRequest.url.path);
          requestPayload =
              jsonDecode(concreteRequest.body) as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(resultJson))),
            200,
          );
        });

        final result = await GeminiService(
          apiKey: 'fast_mode_key',
          client: client,
        ).analyzeMeal([testFile.path], useAccurateMode: false);

        expect(result, isNotNull);
        expect(modelPaths.first, contains('gemini-flash-lite-latest'));
        final generationConfig =
            requestPayload!['generationConfig'] as Map<String, dynamic>;
        final thinkingConfig =
            generationConfig['thinkingConfig'] as Map<String, dynamic>;
        expect(thinkingConfig['thinkingLevel'], 'low');
        expect(generationConfig['maxOutputTokens'], 2048);
      });

      test('structured output does not expose thought transcript', () async {
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

        await for (final event in service.analyzeMealStream([testFile.path])) {
          if (event is ThoughtChunk) {
            thoughts.add(event.text);
          }
        }

        final visibleThoughtText = thoughts.join();
        expect(visibleThoughtText, isEmpty);
        expect(streamRequestCount, 1);
      });

      test('structured output exposes thought summaries', () async {
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

        await for (final event in service.analyzeMealStream([testFile.path])) {
          if (event is ThoughtChunk) {
            thoughts.add(event.text);
          }
        }

        final visibleThoughtText = thoughts.join();
        expect(visibleThoughtText, contains('Ich erkenne Brot'));
        expect(streamRequestCount, 1);
      });
    });
  });
}
