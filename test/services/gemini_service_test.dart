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
    test('validateApiKey is valid for a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        // The key is sent as a header and never appears in the URL.
        expect(request.headers['x-goog-api-key'], 'test_key');
        expect(request.url.toString(), isNot(contains('test_key')));
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      });

      final service = GeminiService(apiKey: 'dummy', client: client);
      expect(await service.validateApiKey('test_key'), ApiKeyStatus.valid);
    });

    test('validateApiKey is invalid when the key is rejected', () async {
      for (final status in [400, 401, 403]) {
        final client = MockClient((request) async {
          return http.StreamedResponse(Stream.value(utf8.encode('{}')), status);
        });
        final service = GeminiService(apiKey: 'dummy', client: client);
        expect(
          await service.validateApiKey('bad_key'),
          ApiKeyStatus.invalid,
          reason: 'HTTP $status',
        );
      }
      final service = GeminiService(apiKey: 'dummy');
      expect(await service.validateApiKey(''), ApiKeyStatus.invalid);
    });

    test(
      'validateApiKey is unreachable on network and server errors',
      () async {
        for (final status in [429, 500, 503]) {
          final client = MockClient((request) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode('{}')),
              status,
            );
          });
          final service = GeminiService(apiKey: 'dummy', client: client);
          expect(
            await service.validateApiKey('key'),
            ApiKeyStatus.unreachable,
            reason: 'HTTP $status',
          );
        }
        final offline = MockClient((request) async {
          throw const SocketException('offline');
        });
        final service = GeminiService(apiKey: 'dummy', client: offline);
        expect(await service.validateApiKey('key'), ApiKeyStatus.unreachable);
      },
    );

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
          expect(thinkingConfig['includeThoughts'], false);
          expect(generationConfig['maxOutputTokens'], 6144);
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
        final requestUrls = <String>[];
        final requestKeys = <String?>[];
        final client = MockClient((request) async {
          final concreteRequest = request as http.Request;
          modelPaths.add(concreteRequest.url.path);
          requestUrls.add(concreteRequest.url.toString());
          requestKeys.add(concreteRequest.headers['x-goog-api-key']);
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
        expect(requestUrls, isNotEmpty);
        for (final url in requestUrls) {
          expect(url, isNot(contains('fast_mode_key')));
          expect(url, isNot(contains('key=')));
        }
        expect(requestKeys.toSet(), {'fast_mode_key'});
        expect(modelPaths.first, contains('gemini-flash-lite-latest'));
        final generationConfig =
            requestPayload!['generationConfig'] as Map<String, dynamic>;
        final thinkingConfig =
            generationConfig['thinkingConfig'] as Map<String, dynamic>;
        expect(thinkingConfig['thinkingLevel'], 'low');
        expect(generationConfig['maxOutputTokens'], 4096);
      });

      test('an answer in a json fence is parsed', () async {
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
        final events = await service.analyzeMealStream([
          testFile.path,
        ]).toList();

        expect((events.last as AnalysisResult).data['meal_name'], 'Test');
        // Accurate Mode: three estimates in parallel.
        expect(streamRequestCount, 3);
      });

      test('thought parts never reach the answer', () async {
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
        final events = await service.analyzeMealStream([
          testFile.path,
        ]).toList();

        final data = (events.last as AnalysisResult).data;
        expect(data['meal_name'], 'Test');
        expect(data['calories'], 100);
        expect(streamRequestCount, 3);
      });

      test('describes a meal in words without any photo', () async {
        final resultJson = jsonEncode({
          'analysis_note': 'test',
          'meal_name': 'Toast mit Butter',
          'calories': 180,
          'protein': 5,
          'carbs': 25,
          'fats': 7,
          'detected_quantity': 2,
          'detected_unit': 'serving',
        });
        Map<String, dynamic>? streamBody;
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
          streamBody =
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(resultJson))),
            200,
          );
        });
        final service = GeminiService(apiKey: 'test_key', client: client);

        Map<String, dynamic>? result;
        await for (final event in service.analyzeMealStream(
          const [],
          mealContext: 'two slices of toast with butter',
        )) {
          if (event is AnalysisResult) result = event.data;
        }

        expect(result?['meal_name'], 'Toast mit Butter');
        final parts =
            ((streamBody!['contents'] as List).single
                    as Map<String, dynamic>)['parts']
                as List;
        expect(
          parts.any((part) => (part as Map).containsKey('inline_data')),
          isFalse,
        );
        final texts = parts.map((part) => (part as Map)['text'] as String);
        expect(texts, contains('User note: two slices of toast with butter'));
        expect(texts.first, contains('No photo'));
      });

      Map<String, dynamic> gramsAnswer(List<Map<String, dynamic>> items) => {
        'meal_name': 'H&auml;hnchen mit Reis',
        'uncertainty_note': '',
        'detected_quantity': 1,
        'detected_unit': 'serving',
        'confidence_score': 0.7,
        'items': items,
      };

      Map<String, dynamic> item(
        String name,
        String ref,
        num grams, {
        num kcal = 0,
        num protein = 0,
        num carbs = 0,
        num fats = 0,
      }) => {
        'name': name,
        'ref': ref,
        'grams': grams,
        'grams_min': grams * 0.8,
        'grams_max': grams * 1.2,
        'kcal_per_100g': kcal,
        'protein_per_100g': protein,
        'carbs_per_100g': carbs,
        'fats_per_100g': fats,
        'confidence': 0.8,
        'assumption': '',
      };

      test('items in grams use USDA values and add up', () async {
        final testFile = File('${tempDir.path}/grams_test.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        final answer = gramsAnswer([
          // The model's own numbers for a reference food are ignored.
          item('Hähnchen', 'chicken_breast', 200, kcal: 100, protein: 10),
          item('Öl', 'oil', 10, kcal: 884, fats: 100),
          // No reference: kcal 300 disagrees with 4/4/9 (= 100), macros win.
          item('Soße', 'other', 50, kcal: 300, carbs: 25),
        ]);
        final client = MockClient(
          (request) async => http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(jsonEncode(answer)))),
            200,
          ),
        );

        final result = await GeminiService(
          apiKey: 'grams_key',
          client: client,
        ).analyzeMeal([testFile.path], useAccurateMode: false);

        // chicken 165 kcal/100 g * 2 + oil 88.4 + sauce 100 * 0.5
        expect(result!['calories'], closeTo(330 + 88.4 + 50, 0.01));
        expect(result['protein'], closeTo(62.04, 0.01));
        expect(result['fats'], closeTo(7.14 + 10, 0.01));
        expect(result['carbs'], closeTo(12.5, 0.01));
        expect(result['meal_name'], 'Hähnchen mit Reis');
        final items = result['items'] as List;
        expect(items.first['grams'], 200);
        expect(items.first['ref'], 'chicken_breast');
        expect(items.last['ref'], isNull);
        expect(result['calories_min'], closeTo((330 + 88.4 + 50) * 0.8, 0.01));
      });

      test('weighed mode takes the amount from the item grams', () async {
        final testFile = File('${tempDir.path}/weighed_test.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        final answer =
            gramsAnswer([
                item('Reis', 'rice_white_cooked', 300),
                item('Brokkoli', 'broccoli', 100),
              ])
              ..['detected_unit'] = 'gram'
              ..['detected_quantity'] = 250;
        final client = MockClient(
          (request) async => http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(jsonEncode(answer)))),
            200,
          ),
        );

        final result = await GeminiService(
          apiKey: 'weighed_key',
          client: client,
        ).analyzeMeal([testFile.path], useGrams: true, useAccurateMode: false);

        expect(result!['detected_quantity'], 400);
        // Per 100 g of the whole meal: (390 + 35) / 4
        expect(result['calories'], closeTo(106.25, 0.01));
      });

      test('accurate mode keeps the median of three estimates', () async {
        final testFile = File('${tempDir.path}/median_test.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        final grams = [100, 300, 200];
        var call = 0;
        final client = MockClient((request) async {
          final answer = gramsAnswer([
            item('Reis', 'rice_white_cooked', grams[call++]),
          ]);
          return http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(jsonEncode(answer)))),
            200,
          );
        });

        final estimates = <double>[];
        Map<String, dynamic>? result;
        await for (final event in GeminiService(
          apiKey: 'median_key',
          client: client,
        ).analyzeMealStream([testFile.path])) {
          if (event is EstimateReady) estimates.add(event.calories);
          if (event is AnalysisResult) result = event.data;
        }

        expect(call, 3);
        expect(estimates, unorderedEquals([130, 390, 260]));
        expect(result!['calories'], closeTo(260, 0.01));
      });

      test('a rate limited Flash Lite hands over to Flash', () async {
        final testFile = File('${tempDir.path}/fallback_test.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        final paths = <String>[];
        final client = MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.contains('lite')) {
            return http.StreamedResponse(
              Stream.value(utf8.encode('{"error": {"code": 429}}')),
              429,
            );
          }
          final answer = gramsAnswer([item('Reis', 'rice_white_cooked', 100)]);
          return http.StreamedResponse(
            Stream.value(utf8.encode(_sseTextEvent(jsonEncode(answer)))),
            200,
          );
        });

        final result = await GeminiService(
          apiKey: 'fallback_key',
          client: client,
        ).analyzeMeal([testFile.path], useAccurateMode: false);

        expect(result!['calories'], closeTo(130, 0.01));
        expect(paths.first, contains('gemini-flash-lite-latest'));
        expect(paths.last, contains('gemini-flash-latest'));
      });

      test(
        'accurate mode calls Flash only when every estimate failed',
        () async {
          final testFile = File('${tempDir.path}/ensemble_fallback.jpg');
          await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
          Future<List<String>> run({required int liteFailures}) async {
            final paths = <String>[];
            var lite = 0;
            final client = MockClient((request) async {
              paths.add(request.url.path);
              if (request.url.path.contains('lite') && lite++ < liteFailures) {
                return http.StreamedResponse(
                  Stream.value(utf8.encode('{"error": {"code": 429}}')),
                  429,
                );
              }
              final answer = gramsAnswer([
                item('Reis', 'rice_white_cooked', 100),
              ]);
              return http.StreamedResponse(
                Stream.value(utf8.encode(_sseTextEvent(jsonEncode(answer)))),
                200,
              );
            });
            final result = await GeminiService(
              apiKey: 'ensemble_fallback_$liteFailures',
              client: client,
            ).analyzeMeal([testFile.path]);
            expect(result!['calories'], closeTo(130, 0.01));
            return paths;
          }

          final oneFailed = await run(liteFailures: 1);
          expect(oneFailed.where((p) => !p.contains('lite')), isEmpty);

          final allFailed = await run(liteFailures: 3);
          expect(allFailed.where((p) => !p.contains('lite')), hasLength(1));
        },
      );

      test('streams component names as the answer arrives', () async {
        final testFile = File('${tempDir.path}/names_test.jpg');
        await testFile.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        final json = jsonEncode(
          gramsAnswer([
            item('Reis "Basmati"', 'rice_white_cooked', 100),
            item('Brokkoli', 'broccoli', 100),
          ]),
        );
        final cut = json.indexOf('Brokkoli');
        final client = MockClient(
          (request) async => http.StreamedResponse(
            Stream.fromIterable(
              [
                _sseTextEvent(json.substring(0, cut)),
                _sseTextEvent(json.substring(cut)),
              ].map(utf8.encode),
            ),
            200,
          ),
        );

        final seen = <List<String>>[];
        await for (final event in GeminiService(
          apiKey: 'names_key',
          client: client,
        ).analyzeMealStream([testFile.path], useAccurateMode: false)) {
          if (event is ComponentsSeen) seen.add(event.names);
        }

        expect(seen, [
          ['Reis "Basmati"'],
          ['Reis "Basmati"', 'Brokkoli'],
        ]);
      });

      test('leftover photos follow the meal behind a note', () async {
        final meal = File('${tempDir.path}/meal.jpg');
        final rest = File('${tempDir.path}/rest.jpg');
        await meal.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        await rest.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        List<dynamic>? parts;
        final client = MockClient((request) async {
          final body = jsonDecode(await request.finalize().bytesToString());
          parts = body['contents'][0]['parts'] as List<dynamic>;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                _sseTextEvent(
                  jsonEncode(
                    gramsAnswer([item('Reis', 'rice_white_cooked', 100)]),
                  ),
                ),
              ),
            ),
            200,
          );
        });

        await GeminiService(apiKey: 'rest_key', client: client)
            .analyzeMealStream(
              [meal.path],
              leftoverPaths: [rest.path],
              useAccurateMode: false,
            )
            .toList();

        final kinds = [
          for (final part in parts!)
            (part as Map).containsKey('inline_data') ||
                    part.containsKey('inlineData')
                ? 'image'
                : (part['text'] as String).startsWith('LEFTOVERS')
                ? 'leftover note'
                : 'text',
        ];
        expect(kinds.take(3), ['image', 'leftover note', 'image']);
      });

      test('leftovers are subtracted item by item', () async {
        final meal = File('${tempDir.path}/meal2.jpg');
        final rest = File('${tempDir.path}/rest2.jpg');
        await meal.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        await rest.writeAsBytes(base64Decode(_dummyBase64Jpeg));
        Map<String, dynamic>? schema;
        final client = MockClient((request) async {
          final body = jsonDecode(await request.finalize().bytesToString());
          schema = body['generationConfig']['responseSchema'];
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                _sseTextEvent(
                  jsonEncode(
                    gramsAnswer([
                      {
                        ...item('Reis', 'rice_white_cooked', 200),
                        'left_grams': 150,
                      },
                      {...item('Brokkoli', 'broccoli', 80), 'left_grams': 80},
                    ]),
                  ),
                ),
              ),
            ),
            200,
          );
        });

        final events = await GeminiService(apiKey: 'rest2_key', client: client)
            .analyzeMealStream(
              [meal.path],
              leftoverPaths: [rest.path],
              useAccurateMode: false,
            )
            .toList();
        final data = (events.last as AnalysisResult).data;
        final items = data['items'] as List<dynamic>;

        expect(
          (schema!['properties']['items']['items']['required'] as List),
          contains('left_grams'),
        );
        // The broccoli was left completely; 50 g of the rice was eaten.
        expect(items.map((i) => i['name']), ['Reis']);
        expect(items.single['grams'], 50);
        expect(data['calories'], closeTo(65, 0.5));
      });

      test('a text-only request needs a description', () async {
        final service = GeminiService(
          apiKey: 'test_key',
          client: MockClient((request) async => fail('no request expected')),
        );

        await expectLater(
          service.analyzeMealStream(const [], mealContext: '  ').toList(),
          throwsA(
            isA<GeminiError>().having(
              (e) => e.type,
              'type',
              GeminiErrorType.noFood,
            ),
          ),
        );
      });
    });
  });
}
