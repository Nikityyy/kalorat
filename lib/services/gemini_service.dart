import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';
import '../utils/platform_utils.dart';

// import 'dart:ui' as ui; // Unused since we removed _resizeImage

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

  // Preferred model order: gemini-flash-latest first (auto-redirects to latest
  // Flash), gemini-flash-lite-latest as fallback on rate limit.
  static const String _preferredModel = 'gemini-flash-latest';

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

        // Sort: non-lite (full Flash) before lite, then newer first within each group.
        // This ensures gemini-2.0-flash is tried before gemini-2.0-flash-lite.
        supportedModels.sort((a, b) {
          final aLower = a.toLowerCase();
          final bLower = b.toLowerCase();
          final aIsLite = aLower.contains('lite');
          final bIsLite = bLower.contains('lite');
          // Non-lite (full Flash) first — higher quality
          if (!aIsLite && bIsLite) return -1;
          if (aIsLite && !bIsLite) return 1;
          // Within same category, prefer newer (Z->A heuristic)
          return b.compareTo(a);
        });

        // Ensure our preferred model (gemini-flash-latest) is first,
        // lite models (gemini-flash-lite-latest) are last as fallback.
        final preferred = supportedModels
            .where((m) => !m.toLowerCase().contains('lite'))
            .toList();
        final fallbackLite = supportedModels
            .where((m) => m.toLowerCase().contains('lite'))
            .toList();
        supportedModels
          ..clear()
          ..addAll([...preferred, ...fallbackLite]);

        // If the API doesn't list our alias models (they're discovery aliases),
        // inject them explicitly at the front.
        if (!supportedModels.contains(_preferredModel)) {
          supportedModels.insert(0, _preferredModel);
        }

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
    String? mealContext,
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
          mealContext: mealContext,
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
    String? mealContext,
  }) async {
    try {
      // Prepare image parts in background to avoid UI jank
      // Prepare image parts in parallel
      final futures = imagePaths.map((path) async {
        try {
          final List<int> bytes;
          String mimeType = 'image/jpeg';

          if (PlatformUtils.isWeb) {
            if (path.startsWith('blob:')) {
              final file = XFile(path);
              bytes = await file.readAsBytes();
              mimeType = _getMimeType(path);
            } else {
              bytes = base64Decode(path);
            }
          } else {
            final file = XFile(path);
            bytes = await file.readAsBytes();
            mimeType = _getMimeType(path);
          }

          if (bytes.isNotEmpty) {
            // Resize if possible to reduce payload
            // final resizedBytes = await _resizeImage(bytes);
            // NOTE: dart:ui usage in background isolate is tricky/unsupported in some Flutter versions
            // For now, relies on HomeScreen imageQuality: 40.

            // Encode in background isolate
            final base64Image = await compute(_encodeImageBytes, bytes);
            return {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            };
          }
        } catch (e) {
          AppLogger.error('GeminiService', 'Error reading image $path', e);
        }
        return null;
      });

      final results = await Future.wait(futures);
      final imageParts = results.whereType<Map<String, dynamic>>().toList();

      if (imageParts.isEmpty) {
        throw GeminiError(GeminiErrorType.noFood, 'No valid images found');
      }

      // Build prompt based on language
      final prompt = _getPrompt(language, useGrams: useGrams);

      // Build config
      final Map<String, dynamic> generationConfig = {
        'temperature': 0.1,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'analysis_note': {'type': 'STRING'},
            'meal_name': {'type': 'STRING'},
            'calories': {'type': 'NUMBER'},
            'protein': {'type': 'NUMBER'},
            'carbs': {'type': 'NUMBER'},
            'fats': {'type': 'NUMBER'},
            'detected_quantity': {'type': 'NUMBER'},
            'detected_unit': {'type': 'STRING'},
            'confidence_score': {'type': 'NUMBER'},
          },
          'required': [
            'analysis_note',
            'meal_name',
            'calories',
            'protein',
            'carbs',
            'fats',
            'detected_quantity',
            'detected_unit',
            'confidence_score',
          ],
        },
      };

      // Apply thinking config only for specific reasoning models
      // Build request body
      final Map<String, dynamic> requestBody;

      // Build content parts: images + optional user context note
      final List<Map<String, dynamic>> contentParts = [...imageParts];
      if (mealContext != null && mealContext.trim().isNotEmpty) {
        contentParts.add({'text': 'User note: ${mealContext.trim()}'});
      }

      // Standard Gemini models support system_instruction
      requestBody = {
        'system_instruction': {
          'parts': [
            {'text': prompt},
          ],
        },
        'contents': [
          {'parts': contentParts},
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
          .timeout(const Duration(seconds: 45));

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
    if (language == 'de') {
      final unitString = useGrams ? 'gram' : 'serving';
      return '''Du bist ein präziser KI-Ernährungsberater. Analysiere das/die Bild(er) und jeden Nutzerhinweis Schritt für Schritt.

DENKPROZESS (in analysis_note dokumentieren):
1. Identifiziere ALLE sichtbaren Lebensmittel und Zutaten einzeln.
2. Schätze Menge/Gewicht jeder Komponente anhand visueller Hinweise (Tellergröße, Verpackung, Vergleichsobjekte).
3. Wende Referenzwerte an:
   - Reis gekocht ~28g KH/100g, ~130 kcal/100g
   - Hähnchenbrust ~31g P/100g, ~165 kcal/100g
   - Nudeln gekocht ~25g KH/100g, ~130 kcal/100g
   - Rindfleisch (mager) ~26g P/100g, ~215 kcal/100g
   - Lachs ~20g P/100g, ~208 kcal/100g
   - Ei (L) ~6g P, ~70 kcal
   - Avocado ~15g F/100g, ~160 kcal/100g
   - Broccoli ~2.8g P/100g, ~34 kcal/100g
   - Olivenöl ~14g F/EL, ~120 kcal/EL
4. Summiere alle Komponenten.
5. Verifiziere: (Protein×4 + KH×4 + Fett×9) ≈ kcal (max. 10% Abweichung erlaubt).

SKALIERUNG – KRITISCH:
- Wenn Bilder ein Produkt UND sein Nährwertetikett zeigen: MULTIPLIZIERE Etikettwerte mit (Gesamtmenge/Referenzmenge).
  Beispiel: 750g Produkt × (350 kcal/100g) = 2625 kcal.
- `detected_quantity` = GESAMTE Produktmenge (z.B. 750), NICHT Portionsgröße.
- Alle Ausgabewerte bereits für GESAMTE Menge skalieren.

kJ vs. kcal – KRITISCH:
- Europäische Etiketten zeigen oft kJ UND kcal. Verwende IMMER kcal. 1 kcal ≈ 4,18 kJ.

EINHEIT (detected_unit):
- Flüssigkeiten → "ml" | Feste Speisen (Gramm-Modus) → "gram" | Sonst → "$unitString"

NAME: `meal_name` IMMER auf Deutsch.

MENGEN-REFERENZ: ${useGrams ? 'Volle Pfanne ~800–1200g. Normaler Teller ~350–500g. Glas ~200–300ml. Schüssel ~400–600g.' : 'Normaler Teller ~1.0 Portion. Volle Pfanne ~2–4 Portionen. Getränk: Menge in ml.'}

ANTWORTE NUR ALS JSON. "analysis_note" MUSS ZUERST KOMMEN.
''';
    } else {
      final unitString = useGrams ? 'gram' : 'serving';
      return '''You are a precise AI Nutritionist. Analyze the image(s) and any user notes step by step.

THINKING PROCESS (document in analysis_note):
1. List ALL visible food items and ingredients individually.
2. Estimate quantity/weight of each component using visual cues (plate size, packaging, reference objects).
3. Apply reference values:
   - Cooked rice ~28g carbs/100g, ~130 kcal/100g
   - Chicken breast ~31g protein/100g, ~165 kcal/100g
   - Cooked pasta ~25g carbs/100g, ~130 kcal/100g
   - Lean beef ~26g protein/100g, ~215 kcal/100g
   - Salmon ~20g protein/100g, ~208 kcal/100g
   - Egg (L) ~6g protein, ~70 kcal
   - Avocado ~15g fat/100g, ~160 kcal/100g
   - Broccoli ~2.8g protein/100g, ~34 kcal/100g
   - Olive oil ~14g fat/tbsp, ~120 kcal/tbsp
4. Sum all components.
5. Verify: (Protein×4 + Carbs×4 + Fat×9) ≈ Calories (max 10% deviation allowed).

SCALING – CRITICAL:
- If images show a product AND its nutrition label: MULTIPLY label values by (total_qty / reference_qty).
  Example: 750g product × (350 kcal/100g) = 2625 kcal total.
- `detected_quantity` = TOTAL product quantity (e.g. 750), NOT serving size.
- All output values must already be scaled for the TOTAL quantity.

kJ vs kcal – CRITICAL:
- European labels show BOTH kJ and kcal. ALWAYS use kcal. 1 kcal ≈ 4.18 kJ.

UNIT (detected_unit):
- Liquids → "ml" | Solid foods (gram mode) → "gram" | Otherwise → "$unitString"

NAME: `meal_name` ALWAYS in English.

QUANTITY REFERENCE: ${useGrams ? 'Full pan ~800–1200g. Standard plate ~350–500g. Glass ~200–300ml. Bowl ~400–600g.' : 'Standard plate ~1.0 serving. Full pan ~2–4 servings. Drink: quantity in ml.'}

RESPONSE FORMAT: JSON ONLY. "analysis_note" MUST BE FIRST.
''';
    }
  }
}
