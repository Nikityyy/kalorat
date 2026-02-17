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

        // Sort to prefer lite models first (fastest), then newer models
        supportedModels.sort((a, b) {
          final aLower = a.toLowerCase();
          final bLower = b.toLowerCase();
          final aIsLite = aLower.contains('lite');
          final bIsLite = bLower.contains('lite');
          // Lite models first
          if (aIsLite && !bIsLite) return -1;
          if (!aIsLite && bIsLite) return 1;
          // Within same category, prefer newer (Z->A heuristic)
          return b.compareTo(a);
        });

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
        'temperature': 0.0,
        'maxOutputTokens':
            1024, // Reduced from 1536 since we removed verbose examples
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
    final unitString = useGrams ? 'gram' : 'serving';
    // Removed verbose examples to save tokens as requested

    if (language == 'de') {
      return '''Du bist KI-Ernährungsberater. Analysiere das Bild präzise.

LOGIK:
1. **Kurze Analyse ("analysis_note")**:
   - Identifiziere Zutaten.
   ${useGrams ? '- Schätze Gewicht in Gramm.' : '- Schätze Portionen (Teller=1.0).'}
   - Nutze Referenzwerte (Reis ~28g KH/100g, Hähnchen ~31g P/100g).
   - Verifiziere: (P*4 + C*4 + F*9) ≈ kcal.
2. **Einheit**: IMMER "$unitString" für `detected_unit`.
3. **Objektivität**: ${useGrams ? 'Volle Pfanne ~800-1200g. Teller ~300-500g.' : 'Teller ~1.0 Portionen. Pfanne ~2-4.'}

ANTWORTE NUR ALS JSON. 'analysis_note' ZUERST.
''';
    } else {
      final unitStringEn = useGrams ? 'gram' : 'serving';
      return '''You are an AI Nutritionist. Analyze the image precisely.

LOGIC:
1. **Short Analysis ("analysis_note")**:
   - Identify ingredients.
   ${useGrams ? '- Estimate weight in grams.' : '- Estimate servings (plate=1.0).'}
   - Use references (Rice ~28g C/100g, Chicken ~31g P/100g).
   - Verify: (P*4 + C*4 + F*9) ≈ Calories.
2. **Unit**: ALWAYS use "$unitStringEn" for `detected_unit`.
3. **Volume**: ${useGrams ? 'Full pan ~800-1200g. Plate ~300-500g.' : 'Standard plate ~1.0. Full pan ~2-4.'}

RESPONSE FORMAT: JSON ONLY. 'analysis_note' MUST BE FIRST.
''';
    }
  }
}
