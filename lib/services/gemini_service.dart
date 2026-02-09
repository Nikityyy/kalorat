import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/platform_utils.dart';

/// Encodes image bytes to base64 in a background isolate
/// This prevents UI jank when processing large images
String _encodeImageBytes(List<int> bytes) {
  return base64Encode(bytes);
}

/// Error types for structured error handling
enum GeminiErrorType {
  rateLimited,
  noFood,
  networkError,
  parseError,
  invalidApiKey,
  unknown,
}

/// Structured error for Gemini API failures
class GeminiError implements Exception {
  final GeminiErrorType type;
  final String message;
  final String? technicalDetails;

  GeminiError(this.type, this.message, {this.technicalDetails});

  @override
  String toString() => message;
}

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
        final result = await _makeRequest(model, imagePaths);

        // If successful, save this index as the last used one
        await box.put(_lastModelIndexKey, currentIndex);
        return result;
      } catch (e) {
        // If one model fails (rate limit, empty response, etc.), try the next one
        print('Model $model failed: $e. Trying next...');
        if (i == _primaryModels.length - 1) {
          // If this was the last primary model, we don't 'continue',
          // we exit the loop and move to fallback.
        } else {
          continue;
        }
      }
    }

    // specific fallback
    try {
      return await _makeRequest(_fallbackModel, imagePaths);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _makeRequest(
    String modelName,
    List<String> imagePaths,
  ) async {
    // Use standard client which works on both mobile and web
    final client = http.Client();

    try {
      // Prepare image parts in background to avoid UI jank
      final List<Map<String, dynamic>> imageParts = [];
      for (final path in imagePaths) {
        // Use XFile for cross-platform file reading (works with paths and blob URLs)
        try {
          final List<int> bytes;
          String mimeType = 'image/jpeg';

          if (PlatformUtils.isWeb) {
            // On Web, imagePaths are Base64 strings (unless blob URL from old session)
            if (path.startsWith('blob:')) {
              final file = XFile(path);
              bytes = await file.readAsBytes();
              mimeType = _getMimeType(path);
            } else {
              bytes = base64Decode(path);
              // Default to jpeg for base64
            }
          } else {
            final file = XFile(path);
            bytes = await file.readAsBytes();
            mimeType = _getMimeType(path);
          }

          if (bytes.isNotEmpty) {
            // Encode in background isolate for large images
            final base64Image = await compute(_encodeImageBytes, bytes);
            imageParts.add({
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            });
          }
        } catch (e) {
          print('Error reading image $path: $e');
        }
      }

      if (imageParts.isEmpty) {
        throw Exception('No valid images found');
      }

      // Build prompt based on language
      final prompt = _getPrompt(language);

      // Build config
      final Map<String, dynamic> generationConfig = {
        'temperature': 0.1,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 1280,
      };

      // Apply thinking config only for specific reasoning models
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
        print('Gemini API Error (${response.statusCode}): ${response.body}');
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
    final url = '${_baseUrlBase}gemma-3-27b-it:generateContent?key=$key';

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
      return '''Du bist ein professioneller Ernährungsberater (AI Nutritionist) und Kalorien-Experte. Analysiere dieses Bild mit höchster Präzision.

DENKPROZESS (Interne Analyse):
1. WAS SEHE ICH? (Mahlzeit auf Teller/Pfanne, Nährwerttabelle?)
2. PORTIONS-LOGIK: 
   - Ein Foto zeigt meistens GENAU das, was der Nutzer tracken möchte.
   - SOWOHL ein Teller, als AUCH eine Pfanne oder Bowl entsprechen in der Regel 1.0 Portion (detected_quantity: 1.0).
   - Schätze die Kalorien für den GESAMTEN sichtbaren Inhalt des Behältners.
3. MENGEN-MATHEMATIK:
   - Wenn Nährwerttabelle sichtbar: Werte für 100g/ml extrahieren. detected_quantity = 100.0.

BEISPIELE:
- Teller Nudeln -> 1.0 Portion.
- Kleine Pfanne mit Hähnchen -> 1.0 Portion.
- 2 ganze Bananen -> 2.0 Portionen (Stückgut).

REGELN FÜR DIE ANTWORT:
1. IDENTIFIKATION & PORTIONIERUNG:
   - Der Standardwert für ein Foto einer Mahlzeit (egal ob Teller, Pfanne, Bowl) ist IMMER 1.0 Portion.
   - Nur mehr als 1.0 schätzen, wenn offensichtlich mehrere separate Einheiten/Stücke (z.B. "3 Äpfel") oder ein riesiges Blech/Vorratstopf zu sehen ist.
   - Nährwerttabelle sichtbar -> IMMER 100.0 (detected_quantity) und 'gram'/'ml' (detected_unit).
   - Benutze nur dann Dezimalzahlen (z.B. 0.5), wenn wirklich nur ein Bruchteil einer Portion zu sehen ist.
   - Nährwerttabelle sichtbar -> IMMER 100.0 (detected_quantity) und 'gram'/'ml' (detected_unit).
2. VALIDIERUNG (Atwater-System):
   - Prüfe deine Schätzung mathematisch! Kalorien ≈ (Protein * 4) + (Kohlenhydrate * 4) + (Fett * 9).
   - Die "calories" müssen die GESAMT-Kalorien für die "detected_quantity" sein.
3. SPRACHE & FORMAT:
   - "meal_name" und "analysis_note" auf DEUTSCH.
   - NUR JSON antworten, KEIN Markdown.

FORMAT:
{
  "meal_name": "Präziser Name",
  "calories": 0.0,
  "protein": 0.0,
  "carbs": 0.0,
  "fats": 0.0,
  "detected_quantity": 0.0,
  "detected_unit": "serving" | "gram" | "ml",
  "confidence_score": 0.0,
  "analysis_note": "Kurze Begründung (z.B. 'Ein Teller erkannt = 1.0 Portion. Kalorien für den gesamten Inhalt geschätzt.')"
}''';
    } else {
      return '''You are a professional AI Nutritionist and calorie expert. Analyze this image with extreme precision.

THINKING PROCESS (Internal Analysis):
1. WHAT DO I SEE? (Meal on plate/pan, nutrition label?)
2. PORTION LOGIC: 
   - A photo usually shows EXACTLY what the user wants to track.
   - BOTH a plate AND a pan or bowl usually correspond to 1.0 portion (detected_quantity: 1.0).
   - Estimate calories for the ENTIRE visible content of the container.
3. QUANTITY MATH:
   - If nutrition label visible: Extract values for 100g/ml. Set detected_quantity to 100.0.

EXAMPLES:
- Plate of pasta -> 1.0 portion.
- Small pan with chicken -> 1.0 portion.
- 2 whole bananas -> 2.0 portions (discrete items).

RULES FOR RESPONSE:
1. IDENTIFICATION & PORTIONING:
   - The default for a meal photo (regardless of plate, pan, bowl) is ALWAYS 1.0 portion.
   - Only estimate more than 1.0 if there are clearly multiple separate units (e.g., "3 apples") or a massive bulk container/tray.
   - Nutrition label visible -> ALWAYS 100.0 (detected_quantity) and 'gram'/'ml' (detected_unit).
   - Only use decimals (e.g. 0.5) if only a fraction of a portion is visible.
   - Nutrition label visible -> ALWAYS 100.0 (detected_quantity) and 'gram'/'ml' (detected_unit).
2. VALIDATION (Atwater System):
   - Mathematically verify your estimate! Calories ≈ (Protein * 4) + (Carbs * 4) + (Fat * 9).
   - "calories" MUST be the TOTAL calories for the "detected_quantity".
3. FORMAT:
   - ONLY respond with JSON, NO Markdown.

FORMAT:
{
  "meal_name": "Precise name",
  "calories": 0.0,
  "protein": 0.0,
  "carbs": 0.0,
  "fats": 0.0,
  "detected_quantity": 0.0,
  "detected_unit": "serving" | "gram" | "ml",
  "confidence_score": 0.0,
  "analysis_note": "Short reason (e.g., 'One plate detected = 1.0 portion. Estimated calories for the entire plate content.')"
}''';
    }
  }
}
