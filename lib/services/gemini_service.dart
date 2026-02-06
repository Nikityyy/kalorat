import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GeminiService {
  static const String _baseUrlBase =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  static const List<String> _primaryModels = [
    'gemini-flash-lite-latest',
    'gemini-flash-latest',
  ];

  static const String _fallbackModel = 'gemma-3-27b-it';
  static const String _settingsBoxName = 'gemini_settings_box';
  static const String _lastModelIndexKey = 'last_used_model_index';

  final String apiKey;
  final String language;

  GeminiService({required this.apiKey, this.language = 'de'});

  Future<Map<String, dynamic>?> analyzeMeal(List<String> imagePaths) async {
    if (apiKey.isEmpty) {
      throw Exception('API key is not set');
    }

    final box = await Hive.openBox(_settingsBoxName);
    int lastIndex = box.get(_lastModelIndexKey, defaultValue: 0) as int;

    // Start with the model AFTER the last used one to ensure rotation
    int startIndex = (lastIndex + 1) % _primaryModels.length;

    // Try primary models in sequence
    for (int i = 0; i < _primaryModels.length; i++) {
      int currentIndex = (startIndex + i) % _primaryModels.length;
      String model = _primaryModels[currentIndex];

      try {
        print('Attempting analysis with primary model: $model');
        final result = await _makeRequest(model, imagePaths);

        // If successful, save this index as the last used one
        await box.put(_lastModelIndexKey, currentIndex);
        return result;
      } catch (e) {
        // Check for rate limit (429) or other errors to decide whether to continue
        // We'll proceed to next model on 429.
        if (e.toString().contains('429')) {
          print('Model $model rate limited (429). Switching to next option...');
          continue; // Try next primary model
        } else {
          // For other errors, we might want to fail fast or try others.
          // Given the requirement is specifically about rate limits, we'll rethrow others for now
          // unless we want to be very resilient.
          rethrow;
        }
      }
    }

    // specific fallback
    print(
      'All primary models failed or rate limited. Attempting fallback: $_fallbackModel',
    );
    try {
      return await _makeRequest(_fallbackModel, imagePaths);
    } catch (e) {
      print('Fallback model also failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _makeRequest(
    String modelName,
    List<String> imagePaths,
  ) async {
    // Use a custom client with longer timeouts
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(minutes: 2)
      ..idleTimeout = const Duration(minutes: 2);
    final client = IOClient(httpClient);

    try {
      // Prepare image parts
      final List<Map<String, dynamic>> imageParts = [];
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = _getMimeType(path);
          imageParts.add({
            'inline_data': {'mime_type': mimeType, 'data': base64Image},
          });
        }
      }

      if (imageParts.isEmpty) {
        throw Exception('No valid images found');
      }

      // Build prompt based on language
      final prompt = _getPrompt(language);

      // Build config
      final Map<String, dynamic> generationConfig = {
        'temperature': 0.4,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 1280,
      };

      // Apply thinking config only for Gemini models
      if (modelName.contains('gemini')) {
        generationConfig['thinkingConfig'] = {'thinkingBudget': 1024};
      }

      // Build request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              ...imageParts,
            ],
          },
        ],
        'generationConfig': generationConfig,
      };

      final url = '$_baseUrlBase$modelName:generateContent?key=$apiKey';

      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text != null) {
          print('Gemini Response ($modelName): $text');
          String cleanedText = text.trim();
          if (cleanedText.startsWith('```json')) {
            cleanedText = cleanedText.substring(7);
          } else if (cleanedText.startsWith('```')) {
            cleanedText = cleanedText.substring(3);
          }
          if (cleanedText.endsWith('```')) {
            cleanedText = cleanedText.substring(0, cleanedText.length - 3);
          }
          cleanedText = cleanedText.trim();

          try {
            return jsonDecode(cleanedText) as Map<String, dynamic>;
          } catch (e) {
            // Try to extract JSON from the text
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedText);
            if (jsonMatch != null) {
              try {
                final jsonResponse =
                    jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

                // --- Client-Side Validation Log ---
                if (jsonResponse.containsKey('calories') &&
                    jsonResponse.containsKey('protein') &&
                    jsonResponse.containsKey('carbs') &&
                    jsonResponse.containsKey('fats')) {
                  final double cal = (jsonResponse['calories'] as num)
                      .toDouble();
                  final double p = (jsonResponse['protein'] as num).toDouble();
                  final double c = (jsonResponse['carbs'] as num).toDouble();
                  final double f = (jsonResponse['fats'] as num).toDouble();

                  final double calculated = (p * 4) + (c * 4) + (f * 9);
                  final double diff = (cal - calculated).abs();

                  print(
                    'Atwater Check: Reported=$cal, Calculated=$calculated, Diff=$diff',
                  );
                  if (diff > (cal * 0.15)) {
                    print(
                      'WARNING: Significant discrepancy in macro calculation!',
                    );
                  }
                }

                if (jsonResponse.containsKey('confidence_score')) {
                  print(
                    'Confidence Score: ${jsonResponse['confidence_score']}',
                  );
                }
                // ----------------------------------

                return jsonResponse;
              } catch (e2) {
                throw Exception('Failed to decode extracted JSON: $e2');
              }
            }
            throw Exception('Failed to parse JSON response. Raw text: $text');
          }
        } else {
          throw Exception('Empty response from Gemini');
        }
      } else {
        // Throw exception with status code to catch it in analyzeMeal
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<bool> validateApiKey(String key) async {
    if (key.isEmpty) return false;

    // Use Flash Lite for validation as it's cheaper/quicker
    final url =
        '${_baseUrlBase}gemini-flash-lite-latest:generateContent?key=$key';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 1},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _getPrompt(String language) {
    if (language == 'de') {
      return '''Du bist ein professioneller Ernährungsberater (AI Nutritionist). Analysiere dieses Bild (Essen oder Nährwerttabelle) und antworte NUR mit einem validen JSON-Objekt ohne Markdown-Formatierung.

REGELN:
1. KEIN Markdown (kein ```json ... ```), nur das reine JSON-Objekt.
2. Wenn KEIN Essen/Nährwerttabelle zu sehen ist: {"error": "no_food_detected"}
3. VALIDIERUNG (Atwater-System): Prüfe deine Schätzung mathematisch!
   Kalorien ≈ (Protein * 4) + (Kohlenhydrate * 4) + (Fett * 9).
   Stelle sicher, dass die "calories" Summe zu den Makros passt (Toleranz ±10%).
4. MENGENSCHÄTZUNG:
   - Verpackung: Extrahiere exakte Werte für 100g oder Portion.
   - Gericht: Schätze das VOLUMEN basierend auf Standard-Portionsgrößen (Tellergröße, Besteck als Referenz). Berechne das Gewicht: Masse = Volumen * Dichte.
5. SPRACHE:
   - Der "meal_name" MUSS auf DEUTSCH sein, auch wenn das Essen international ist (z.B. "Gebratenes Hühnchen" statt "Fried Chicken").
   - "analysis_note" MUSS auf DEUTSCH sein.

FORMAT:
{
  "meal_name": "Präziser Name des Gerichts",
  "calories": 0.0 (Zahl, valide Kalorien),
  "protein": 0.0 (Zahl in Gramm),
  "carbs": 0.0 (Zahl in Gramm),
  "fats": 0.0 (Zahl in Gramm),
  "vitamins": {"A": 0.0, "C": 0.0},
  "minerals": {"Calcium": 0.0},
  "confidence_score": 0.0 (0.0 bis 1.0, wie sicher bist du?),
  "analysis_note": "Kurze Notiz zur Schätzung (z.B. 'Basierend auf 400g Lasagne')"
}''';
    } else {
      return '''You are a professional AI Nutritionist. Analyze this image (food or nutrition label) and respond ONLY with a valid JSON object without Markdown formatting.

RULES:
1. NO Markdown (no ```json ... ```), just the raw JSON object.
2. If NO food/label is detected: {"error": "no_food_detected"}
3. VALIDATION (Atwater System): Mathematically verify your estimate!
   Calories ≈ (Protein * 4) + (Carbs * 4) + (Fat * 9).
   Ensure "calories" sum aligns with macros (Tolerance ±10%).
4. VOLUMETRIC ESTIMATION:
   - Packaging: Extract exact values for 100g or serving.
   - Plated Meal: Estimate VOLUME based on standard serving sizes (plate size, cutlery as reference). Calculate weight: Mass = Volume * Density.

FORMAT:
{
  "meal_name": "Precise name of the meal",
  "calories": 0.0 (number, valid calories),
  "protein": 0.0 (number in grams),
  "carbs": 0.0 (number in grams),
  "fats": 0.0 (number in grams),
  "vitamins": {"A": 0.0, "C": 0.0},
  "minerals": {"Calcium": 0.0},
  "confidence_score": 0.0 (0.0 to 1.0, how confident are you?),
  "analysis_note": "Short note on estimation (e.g., 'Based on 400g Lasagne')"
}''';
    }
  }
}
