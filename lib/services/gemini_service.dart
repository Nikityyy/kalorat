import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';
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
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Cache for available models to avoid fetching on every request
  List<String>? _cachedModels;
  DateTime? _lastModelFetchTime;

  // Track rate limited models: Model Name -> Time when it will be available again
  final Map<String, DateTime> _rateLimitedModels = {};

  // Cooldown duration for a rate-limited model
  static const Duration _rateLimitCooldown = Duration(minutes: 1);

  static const String _settingsBoxName = 'gemini_settings_box';
  static const String _lastModelKey = 'last_used_model_name';

  final String apiKey;
  final String language;

  final http.Client _client;

  GeminiService({
    required this.apiKey,
    this.language = 'de',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetches available models from the API, filtering for Flash.
  Future<List<String>> _getAvailableModels() async {
    // Return cached models if valid (e.g., fetched within last hour)
    if (_cachedModels != null &&
        _lastModelFetchTime != null &&
        DateTime.now().difference(_lastModelFetchTime!) <
            const Duration(hours: 1)) {
      return _cachedModels!;
    }

    try {
      final url = '$_baseUrlBase?key=$apiKey';
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = data['models'] as List<dynamic>?;

        if (modelsList == null) return [];

        final supportedModels = modelsList
            .map((m) => m['name'] as String)
            // Filter only names, remove 'models/' prefix if present for clean comparison
            .map(
              (name) => name.startsWith('models/') ? name.substring(7) : name,
            )
            // Filter for Flash models
            .where((name) {
              final lower = name.toLowerCase();
              return lower.contains('flash');
            })
            .toList();

        // Sort to prefer newer/better models if possible (optional, but good for consistency)
        supportedModels.sort(
          (a, b) => b.compareTo(a),
        ); // Z->A purely heuristic or customize

        _cachedModels = supportedModels;
        _lastModelFetchTime = DateTime.now();

        AppLogger.info('GeminiService', 'Discovered models: $_cachedModels');
        return _cachedModels!;
      } else {
        AppLogger.error(
          'GeminiService',
          'Failed to list models: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      AppLogger.error('GeminiService', 'Error fetching models', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> analyzeMeal(
    List<String> imagePaths, {
    bool useGrams = false,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiError(GeminiErrorType.invalidApiKey, 'API key is not set');
    }

    // Get fresh list of models
    List<String> candidates = await _getAvailableModels();

    // Filter out currently rate-limited models
    final now = DateTime.now();
    final availableModels = candidates.where((model) {
      if (_rateLimitedModels.containsKey(model)) {
        if (now.isBefore(_rateLimitedModels[model]!)) {
          return false; // Still in cooldown
        } else {
          _rateLimitedModels.remove(model); // Cooldown expired
          return true;
        }
      }
      return true;
    }).toList();

    if (availableModels.isEmpty) {
      // If all models are rate limited, clear one to try anyway or throw specific error
      throw GeminiError(
        GeminiErrorType.rateLimited,
        'All available models are currently rate limited. Please try again later.',
      );
    }

    // Prioritize the last successfully used model if it's in the available list
    final box = await Hive.openBox(_settingsBoxName);
    final lastUsedModel = box.get(_lastModelKey) as String?;

    if (lastUsedModel != null && availableModels.contains(lastUsedModel)) {
      availableModels.remove(lastUsedModel);
      availableModels.insert(0, lastUsedModel);
    }

    // Try models in sequence
    for (final model in availableModels) {
      try {
        final result = await _makeRequest(
          model,
          imagePaths,
          useGrams: useGrams,
        );

        // Success! Save this model as preferred
        await box.put(_lastModelKey, model);
        return result;
      } catch (e) {
        // Check if this was a rate limit error
        if (e is GeminiError && e.type == GeminiErrorType.rateLimited) {
          AppLogger.warning(
            'GeminiService',
            'Model $model rate limited. Backing off for ${_rateLimitCooldown.inSeconds}s.',
          );
          _rateLimitedModels[model] = DateTime.now().add(_rateLimitCooldown);
          // Continue to next model
          continue;
        }

        // For other errors (network, parsing), we might want to retry or just log
        AppLogger.warning(
          'GeminiService',
          'Model $model failed: $e. Trying next...',
        );
        continue;
      }
    }

    // If we get here, all models failed
    throw GeminiError(
      GeminiErrorType.unknown,
      'Failed to analyze image with any available model.',
    );
  }

  Future<Map<String, dynamic>?> _makeRequest(
    String modelName,
    List<String> imagePaths, {
    bool useGrams = false,
  }) async {
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
          AppLogger.error('GeminiService', 'Error reading image $path', e);
        }
      }

      if (imageParts.isEmpty) {
        throw GeminiError(GeminiErrorType.noFood, 'No valid images found');
      }

      // Build prompt based on language
      final prompt = _getPrompt(language, useGrams: useGrams);

      // Build config
      final Map<String, dynamic> generationConfig = {
        'temperature': 0.0,
        'maxOutputTokens': 1536,
      };

      // Apply thinking config only for specific reasoning models
      // Build request body
      final Map<String, dynamic> requestBody;

      // Standard Gemini models support system_instruction
      requestBody = {
        'system_instruction': {
          'parts': [
            {'text': prompt},
          ],
        },
        'contents': [
          {'parts': imageParts},
        ],
        'generationConfig': generationConfig,
      };

      final url = '$_baseUrlBase/$modelName:generateContent?key=$apiKey';

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text != null) {
          AppLogger.debug(
            'GeminiService',
            'Gemini Response ($modelName): ${text.substring(0, text.length.clamp(0, 200))}...',
          );
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

                  AppLogger.info(
                    'GeminiService',
                    'Atwater Check: Reported=$cal, Calculated=$calculated, Diff=$diff',
                  );
                }

                if (jsonResponse.containsKey('confidence_score')) {
                  AppLogger.info(
                    'GeminiService',
                    'Confidence Score: ${jsonResponse['confidence_score']}',
                  );
                }
                // ----------------------------------

                return jsonResponse;
              } catch (e2) {
                throw GeminiError(
                  GeminiErrorType.parseError,
                  'Failed to decode extracted JSON',
                  technicalDetails: e2.toString(),
                );
              }
            }
            throw GeminiError(
              GeminiErrorType.parseError,
              'Failed to parse JSON response',
              technicalDetails:
                  'Raw: ${text.substring(0, text.length.clamp(0, 200))}',
            );
          }
        } else {
          throw GeminiError(
            GeminiErrorType.unknown,
            'Empty response from Gemini',
          );
        }
      } else {
        // Throw exception with status code to catch it in analyzeMeal
        AppLogger.error('GeminiService', 'API error ${response.statusCode}');
        final errorType = response.statusCode == 429
            ? GeminiErrorType.rateLimited
            : response.statusCode == 401 || response.statusCode == 403
            ? GeminiErrorType.invalidApiKey
            : GeminiErrorType.networkError;
        throw GeminiError(
          errorType,
          'API error: ${response.statusCode}',
          technicalDetails: response.body,
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      // client.close(); // Do not close injected client
    }
  }

  Future<bool> validateApiKey(String key) async {
    if (key.isEmpty) return false;

    // Use models list endpoint for validation as it's the fastest way to check key validity
    // without triggering model inference.
    final url = '$_baseUrlBase?key=$key';

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
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
      case 'avif':
        return 'image/avif';
      default:
        return 'image/jpeg';
    }
  }

  String _getPrompt(String language, {bool useGrams = false}) {
    final unitString = useGrams ? 'gram' : 'serving';
    final example1Note = useGrams
        ? 'Reasoning: [Hähnchenbrust, gegart]: Ca. 35-40 Stücke. Schätzung ~500g gegart -> ~155g Protein, ~18g Fett, 0g KH. [Brokkoli]: Nimmt die Hälfte der Pfanne ein. Schätzung ~250g -> ~6g Protein, ~17g KH, ~1g Fett. [Sauce & Öl]: Glanz deutet auf Öl/Zucker-Glasur hin. 2 EL Öl (30g Fett) und ~45g Zucker/Stärke (45g KH). Gesamt: (161g P * 4) + (62g C * 4) + (49g F * 9) = 1333 kcal. Verifikation: Passt zur Gesamtschätzung.'
        : 'Reasoning: Analyse einer großen Pfannenportion (ca. 800g). Komponenten: Viel mageres Hähnchen, Brokkoli, dunkle Sauce. Proteinreich (~160g), mäßig Kohlenhydrate aus der Sauce (~60g), Fett hauptsächlich durch Öl (~50g). Gesamtschätzung: ~1330 kcal.';

    final example1Name = useGrams
        ? 'Honey Garlic Chicken Brokkoli Pfanne'
        : 'Große Hähnchen-Brokkoli Pfanne';
    final example1Qty = useGrams ? 825.0 : 1.0;

    final example2Note = useGrams
        ? 'Reasoning: Analyse einer Standardportion (300g). [Weißer Reis]: 100g -> 130 kcal, 28g KH, 2.7g P, 0.3g F. [Hähnchen]: 85g -> 140 kcal, 0g KH, 26g P, 3g F. [Brokkoli]: 60g -> 20 kcal, 4g KH, 2g P, 0.2g F. [Saucenbasis]: 45g (Cheddar/Creme) -> 120 kcal, 4g KH, 4g P, 9g F. [Topping]: 10g -> 50 kcal, 6g KH, 1g P, 3.5g F. Gesamt: 460 kcal. Verifikation: (35.7*4) + (42*4) + (16*9) = 454.8 kcal (nahezu identisch).'
        : 'Reasoning: Typische Einzelportion (ca. 300-350g). Hauptbestandteile: Reis, gezupftes Hähnchen, Brokkoli, Käsesauce. Moderate Kaloriendichte durch Sauce. Makroberteilung: 35g P, 40g C, 15g F. Gesamt: ~450 kcal.';
    final example2Qty = useGrams ? 300.0 : 1.0;

    if (language == 'de') {
      return '''Du bist ein fachkundiger KI-Ernährungsberater. Deine Aufgabe ist die hochpräzise Analyse von Mahlzeiten-Bildern.

LOGIK-REGELN:
1.  **Zuerst Denken (Chain of Thought)**: Beschreibe im Feld "analysis_note" zuerst deine Analyse.
    - Identifiziere jede Zutat.
    ${useGrams ? '- Schätze das Gewicht in Gramm (sei realistisch!).' : '- Schätze die Anzahl der Portionen (meist 1.0 für einen Teller, oder mehr für Pfannen/Töpfe).'}
    - Benutze wissenschaftliche Referenzwerte:
        * Hähnchenbrust (gegart): ~31g Protein / 100g.
        * Reis (gekocht): ~28g KH / 100g.
        * Öl/Fett: ~90-100% Fettanteil.
    - Berechne die Makros pro Zutat.
    - Summiere alles auf und verifiziere mit der Atwater-Formel: (P*4 + C*4 + F*9) ≈ Kalorien.
2.  **Standard-Einheit**: Verwende IMMER "$unitString" für die `detected_unit`.
3.  **Genauigkeit & Volumen**: Sei objektiv. ${useGrams ? 'Eine volle Pfanne (10-12 inch) wiegt meist 800-1200g. Ein Einzelteller wiegt meist 300-500g.' : 'Ein Standardteller ist normalerweise 1.0 Portionen. Eine volle Pfanne kann 2-4 Portionen sein.'}

BEISPIEL 1 (Pfanne/Große Portion):
{
  "analysis_note": "$example1Note",
  "meal_name": "$example1Name",
  "calories": 1333.0,
  "protein": 161.0,
  "carbs": 62.0,
  "fats": 49.0,
  "detected_quantity": $example1Qty,
  "detected_unit": "$unitString",
  "confidence_score": 0.95
}

BEISPIEL 2 (Teller/Einzelportion):
{
  "analysis_note": "$example2Note",
  "meal_name": "Chicken Brokkoli Reis Auflauf",
  "calories": 460.0,
  "protein": 35.7,
  "carbs": 42.0,
  "fats": 16.0,
  "detected_quantity": $example2Qty,
  "detected_unit": "$unitString",
  "confidence_score": 0.9
}

ANTWORTE NUR ALS JSON. DAS FELD 'analysis_note' MUSS ZUERST ERSCHEINEN.
''';
    } else {
      final unitStringEn = useGrams ? 'gram' : 'serving';
      final example1NoteEn = useGrams
          ? 'Reasoning: [Chicken Breast, cooked]: The pan contains approx. 35-40 bite-sized cubes. Estimating ~500g cooked weight -> ~155g Protein, ~18g Fat, 0g Carbs. [Broccoli, cooked]: Approx. ~250g -> ~6g Protein, ~17g Carbs, ~1g Fat. [Sauce & Oil]: Glossy sheen indicates oil/sugar glaze. 2 tbsp oil (30g Fat) and ~45g sugars/starch (45g Carbs). Total calculated: (161g P * 4) + (62g C * 4) + (49g F * 9) = 1333 kcal. Verification: Matches total estimate.'
          : 'Reasoning: Large skillet portion (approx. 800g). Components: Plenty of lean chicken, broccoli, dark sauce. High in protein (~160g), moderate carbs from sauce (~60g), fat mostly from oil (~50g). Total estimate: ~1330 kcal.';
      final example2NoteEn = useGrams
          ? 'Reasoning: Analyzed as a standard 300g serving. [White Rice]: 100g -> 130 kcal, 28g carbs, 2.7g protein, 0.3g fat. [Shredded Chicken Breast]: 85g -> 140 kcal, 0g carbs, 26g protein, 3g fat. [Broccoli Florets]: 60g -> 20 kcal, 4g carbs, 2g protein, 0.2g fat. [Cheese & Cream Sauce]: 45g -> 120 kcal, 4g carbs, 4g protein, 9g fat. [Crispy Topping]: 10g -> 50 kcal, 6g carbs, 1g protein, 3.5g fat. Total calculated: 460 kcal. Verification: (35.7*4) + (42*4) + (16*9) = 454.8 kcal (matches closely).'
          : 'Reasoning: Typical single serving (approx. 300-350g). Main ingredients: rice, shredded chicken, broccoli, cheese sauce. Moderate calorie density due to sauce. Macros: 35g P, 40g C, 15g F. Total: ~450 kcal.';

      return '''You are a master AI Nutritionist. Analyze the attached image with scientific precision.

LOGIC RULES:
1.  **Think First (Chain of Thought)**: Use the "analysis_note" field to show your reasoning step-by-step.
    - Identify every ingredient.
    ${useGrams ? '- Estimate weights realistically in grams.' : '- Estimate the number of servings (usually 1.0 for a single plate, or more for shared pans/pots).'}
    - Use scientific reference densities:
        * Chicken Breast (cooked): ~31g Protein / 100g.
        * Rice (cooked): ~28g Carbs / 100g.
        * Oil/Fat: ~90-100% Fat.
    - Calculate macros per ingredient.
    - Sum them up and verify with the Atwater formula: (P*4 + C*4 + F*9) ≈ Calories.
2.  **Standardize**: ALWAYS use "$unitStringEn" for the `detected_unit`.
3.  **Precision & Volume**: Be objective. ${useGrams ? 'A full 10-12 inch skillet weighs approx. 800-1200g. A single plate weighs approx. 300-500g.' : 'A standard plate is usually 1.0 servings. A full pan might be 2-4 servings.'}

EXAMPLE 1:
{
  "analysis_note": "$example1NoteEn",
  "meal_name": "$example1Name",
  "calories": 1333.0,
  "protein": 161.0,
  "carbs": 62.0,
  "fats": 49.0,
  "detected_quantity": $example1Qty,
  "detected_unit": "$unitStringEn",
  "confidence_score": 0.95
}

EXAMPLE 2:
{
  "analysis_note": "$example2NoteEn",
  "meal_name": "Chicken Broccoli Rice Casserole",
  "calories": 460.0,
  "protein": 35.7,
  "carbs": 42.0,
  "fats": 16.0,
  "detected_quantity": $example2Qty,
  "detected_unit": "$unitStringEn",
  "confidence_score": 0.9
}

RESPONSE FORMAT: JSON ONLY. The field 'analysis_note' MUST appear first.
''';
    }
  }
}
