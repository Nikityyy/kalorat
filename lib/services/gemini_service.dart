import 'dart:async';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import '../utils/platform_utils.dart';
import 'gemini_stream_client.dart';

/// Decode, resize, recompress, and optionally crop an image off the UI isolate.
/// The crop is only generated when the user note suggests a nutrition/ingredient
/// label is present; ordinary meal photos send one resized image part.
Map<String, String> _prepareImageInIsolate(Map<String, dynamic> input) {
  final bytes = Uint8List.fromList((input['bytes'] as List).cast<int>());
  final decoded = img.decodeImage(bytes);
  final sourceMimeType = input['mimeType']?.toString() ?? 'image/jpeg';
  if (decoded == null) {
    return {'data': base64Encode(bytes), 'mimeType': sourceMimeType};
  }

  final maxDimension = input['labelHint'] == true ? 1536 : 1024;
  final longest = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = longest > maxDimension
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? maxDimension
              : (decoded.width * maxDimension / decoded.height).round(),
          height: decoded.height > decoded.width
              ? maxDimension
              : (decoded.height * maxDimension / decoded.width).round(),
          interpolation: img.Interpolation.average,
        )
      : decoded;

  return {
    'data': base64Encode(img.encodeJpg(resized, quality: 82)),
    'mimeType': 'image/jpeg',
  };
}

String _mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

String _sanitizeVisibleThoughtText(String text) {
  if (text.isEmpty) return text;

  final withoutFences = text
      .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
      .replaceAll('```', '');
  final lines = withoutFences.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return lines
      .split('\n')
      .where((line) {
        final lower = line.toLowerCase();
        return !lower.contains('json') &&
            !lower.contains('schema') &&
            !lower.contains('response format') &&
            !lower.contains('raw json');
      })
      .join('\n');
}

/// Error types for structured error handling
enum GeminiErrorType {
  rateLimited,
  noFood,
  networkError,
  parseError,
  invalidApiKey,
  timedOut,
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

/// Sealed-style base class for streaming analysis progress events.
abstract class AnalysisProgress {
  const AnalysisProgress();
}

/// A chunk of the model's live thought summary text.
class ThoughtChunk extends AnalysisProgress {
  final String text;
  const ThoughtChunk(this.text);
}

/// The final JSON analysis result.
class AnalysisResult extends AnalysisProgress {
  final Map<String, dynamic> data;
  const AnalysisResult(this.data);
}

class _ModelCapabilityCacheEntry {
  final List<String> models;
  final DateTime expiresAt;

  const _ModelCapabilityCacheEntry(this.models, this.expiresAt);
}

class GeminiService {
  static const String _baseUrlBase =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _analysisBackendUrl = String.fromEnvironment(
    'KALORAT_ANALYSIS_BACKEND_URL',
    defaultValue: '',
  );
  static const String _analysisBackendToken = String.fromEnvironment(
    'KALORAT_ANALYSIS_BACKEND_TOKEN',
    defaultValue: '',
  );
  static const Duration _modelCapabilityTtl = Duration(minutes: 30);
  static final Map<String, _ModelCapabilityCacheEntry> _modelCache = {};
  static final Map<String, DateTime> _modelUnavailableUntil = {};
  static final http.Client _sharedClient = http.Client();

  // Use Google's stable aliases so the app automatically follows the newest
  // Flash and Flash Lite releases without a code change or per-meal model
  // discovery request.
  static const List<String> _preferredFlashModels = ['gemini-flash-latest'];

  static const List<String> _preferredFlashLiteModels = [
    'gemini-flash-lite-latest',
  ];

  final String apiKey;
  final String language;

  final http.Client _client;

  GeminiService({
    required this.apiKey,
    this.language = 'de',
    http.Client? client,
  }) : _client = client ?? _sharedClient;

  String get _modelCacheKey => '${apiKey.length}:${apiKey.hashCode}';

  String get _backendBaseUrl => _analysisBackendUrl.endsWith('/')
      ? _analysisBackendUrl.substring(0, _analysisBackendUrl.length - 1)
      : _analysisBackendUrl;

  /// Resolves stable aliases once per key and reuses the routing list.
  /// A short cooldown removes aliases that recently returned a provider error.
  Future<List<String>> _getAvailableModels() async {
    final cacheKey = _modelCacheKey;
    final cached = _modelCache[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return List<String>.of(cached.models);
    }

    final aliases = <String>[
      ..._preferredFlashModels,
      ..._preferredFlashLiteModels,
    ];
    _modelCache[cacheKey] = _ModelCapabilityCacheEntry(
      List<String>.unmodifiable(aliases),
      DateTime.now().add(_modelCapabilityTtl),
    );
    final now = DateTime.now();
    final usable = aliases.where((model) {
      final unavailableUntil = _modelUnavailableUntil['$cacheKey:$model'];
      return unavailableUntil == null || !unavailableUntil.isAfter(now);
    }).toList();
    return usable.isNotEmpty ? usable : aliases;
  }

  void _coolDownModel(String model, Duration duration) {
    _modelUnavailableUntil['$_modelCacheKey:$model'] = DateTime.now().add(
      duration,
    );
  }

  List<String> _orderedModelsForMode(
    List<String> candidates, {
    required bool useAccurateMode,
  }) {
    final seen = <String>{};
    final uniqueCandidates = <String>[
      for (final model in candidates)
        if (seen.add(model)) model,
    ];

    List<String> prioritizeAliases(List<String> models, List<String> aliases) {
      final ordered = <String>[];
      for (final alias in aliases) {
        if (models.contains(alias)) ordered.add(alias);
      }
      ordered.addAll(models.where((model) => !ordered.contains(model)));
      return ordered;
    }

    final liteModels = uniqueCandidates
        .where((model) => model.toLowerCase().contains('lite'))
        .toList();
    final fullFlashModels = uniqueCandidates
        .where((model) => !model.toLowerCase().contains('lite'))
        .toList();

    final preferredLite = prioritizeAliases(
      liteModels,
      _preferredFlashLiteModels,
    );
    final preferredFull = prioritizeAliases(
      fullFlashModels,
      _preferredFlashModels,
    );

    // Flash Lite is the default model in both modes. Accurate Mode changes
    // thinking depth and output budget, not the model alias.
    return [...preferredLite, ...preferredFull];
  }

  Future<Map<String, dynamic>?> analyzeMeal(
    List<String> imagePaths, {
    bool useGrams = false,
    String? mealContext,
    bool useAccurateMode = true,
    bool allowEstimateVariation = false,
    Map<String, dynamic>? previousAnalysis,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiError(GeminiErrorType.invalidApiKey, 'API key is not set');
    }
    Map<String, dynamic>? lastResult;
    await for (final progress in analyzeMealStream(
      imagePaths,
      useGrams: useGrams,
      mealContext: mealContext,
      useAccurateMode: useAccurateMode,
      allowEstimateVariation: allowEstimateVariation,
      previousAnalysis: previousAnalysis,
    )) {
      if (progress is AnalysisResult) {
        lastResult = progress.data;
      }
    }
    return lastResult;
  }

  /// Streaming version of analyzeMeal that yields [AnalysisProgress] events.
  ///
  /// The normal path is one compact structured Gemini call.
  Stream<AnalysisProgress> analyzeMealStream(
    List<String> imagePaths, {
    bool useGrams = false,
    String? mealContext,
    bool useAccurateMode = true,
    bool allowEstimateVariation = false,
    Map<String, dynamic>? previousAnalysis,
  }) async* {
    if (apiKey.isEmpty) {
      throw GeminiError(GeminiErrorType.invalidApiKey, 'API key is not set');
    }

    final stopwatch = Stopwatch()..start();
    final imageParts = await _prepareImageParts(imagePaths, mealContext);
    final candidates = _orderedModelsForMode(
      await _getAvailableModels(),
      useAccurateMode: useAccurateMode,
    );
    final model = candidates.isNotEmpty
        ? candidates.first
        : 'gemini-flash-lite-latest';

    try {
      Map<String, dynamic>? result;
      await for (final event in _makeStreamRequest(
        model,
        imageParts,
        imageCount: imagePaths.length,
        useGrams: useGrams,
        mealContext: mealContext,
        useAccurateMode: useAccurateMode,
        allowEstimateVariation: allowEstimateVariation,
        previousAnalysis: previousAnalysis,
      )) {
        if (event is AnalysisResult) {
          result = event.data;
        } else {
          yield event;
        }
      }

      if (result == null) {
        throw GeminiError(GeminiErrorType.parseError, 'Empty analysis result');
      }
      final normalized = _normalizeAnalysisResult(result);
      AppLogger.info(
        'GeminiService',
        'analysis_complete model=$model latency_ms=${stopwatch.elapsedMilliseconds}',
      );
      yield AnalysisResult(normalized);
    } catch (e) {
      AppLogger.warning(
        'GeminiService',
        'Model $model failed after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      final errorText = e.toString();
      if (errorText.contains('429')) {
        _coolDownModel(model, const Duration(seconds: 30));
        throw GeminiError(
          GeminiErrorType.rateLimited,
          'Gemini rate limit reached. Please retry shortly.',
          technicalDetails: errorText,
        );
      }
      if (errorText.contains('404')) {
        _coolDownModel(model, const Duration(minutes: 10));
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _prepareImageParts(
    List<String> imagePaths,
    String? mealContext,
  ) async {
    final note = mealContext?.toLowerCase() ?? '';
    final labelHint = RegExp(
      r'label|etikett|nutrition|naehr|nähr|ingredient|zutaten|package|packung|verpack',
    ).hasMatch(note);

    final preparedPerImage = await Future.wait(
      imagePaths.map((path) async {
        try {
          final List<int> bytes;
          if (PlatformUtils.isWeb && path.startsWith('blob:')) {
            bytes = await XFile(path).readAsBytes();
          } else if (PlatformUtils.isWeb) {
            bytes = base64Decode(path);
          } else {
            bytes = await XFile(path).readAsBytes();
          }
          if (bytes.isEmpty) return <Map<String, dynamic>>[];

          final prepared =
              await compute<Map<String, dynamic>, Map<String, String>>(
                _prepareImageInIsolate,
                {
                  'bytes': bytes,
                  'labelHint': labelHint,
                  'mimeType': _mimeTypeForPath(path),
                },
              );
          return <Map<String, dynamic>>[
            {
              'inline_data': {
                'mime_type': prepared['mimeType'] ?? 'image/jpeg',
                'data': prepared['data'],
              },
            },
          ];
        } catch (e) {
          AppLogger.warning('GeminiService', 'Image preprocessing failed: $e');
          return <Map<String, dynamic>>[];
        }
      }),
    );
    final parts = <Map<String, dynamic>>[
      for (final imageParts in preparedPerImage) ...imageParts,
    ];

    if (parts.isEmpty) {
      throw GeminiError(GeminiErrorType.noFood, 'No valid images found');
    }
    return parts;
  }

  /// Performs one compact structured streaming request. The public API
  /// yields thought summaries and then the final structured result.
  Stream<AnalysisProgress> _makeStreamRequest(
    String modelName,
    List<Map<String, dynamic>> imageParts, {
    required int imageCount,
    bool useGrams = false,
    String? mealContext,
    bool useAccurateMode = true,
    bool allowEstimateVariation = false,
    Map<String, dynamic>? previousAnalysis,
  }) async* {
    final prompt = _getPrompt(
      language,
      useGrams: useGrams,
      allowEstimateVariation: allowEstimateVariation,
    );

    final contentParts = <Map<String, dynamic>>[
      ...imageParts,
      {'text': _analysisContextNote(imageCount)},
      if (mealContext != null && mealContext.trim().isNotEmpty)
        {'text': 'User note: ${mealContext.trim()}'},
      if (previousAnalysis != null)
        {
          'text':
              'Previous estimate to challenge and revise if needed: ${jsonEncode(previousAnalysis)}',
        },
    ];

    final thinkingLevel = useAccurateMode ? 'medium' : 'low';
    final requestBody = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': prompt},
        ],
      },
      'contents': [
        {'parts': contentParts},
      ],
      'generationConfig': {
        // Accurate mode gets more reasoning headroom while Fast mode keeps
        // the same compact structured response with a lower thinking level.
        // maxOutputTokens includes hidden thinking tokens, so these budgets
        // avoid truncating multi-item JSON when thinking is enabled.
        'maxOutputTokens': useAccurateMode ? 3072 : 2048,
        'thinkingConfig': {
          'thinkingLevel': thinkingLevel,
          'includeThoughts': true,
        },
        'responseMimeType': 'application/json',
        'responseSchema': _analysisResponseSchema(),
      },
    };

    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}-${modelName.hashCode}';
    final usingBackend = _backendBaseUrl.isNotEmpty;
    final directUrl =
        '$_baseUrlBase/$modelName:streamGenerateContent?alt=sse&key=$apiKey';
    final url = usingBackend ? '$_backendBaseUrl/v1/analyze' : directUrl;
    // Streaming keeps the analysis panel responsive by delivering the model's
    // short thought summaries before the final structured JSON. The outer
    // The request timeout still bounds the total analysis duration.
    final timeout = useAccurateMode
        ? const Duration(seconds: 30)
        : const Duration(seconds: 20);

    final requestHeaders = {
      'Content-Type': 'application/json',
      'x-kalorat-request-id': requestId,
      if (usingBackend && _analysisBackendToken.isNotEmpty)
        'x-kalorat-relay-token': _analysisBackendToken,
    };

    Future<Stream<String>> sendRequest(Map<String, dynamic> payload) async {
      final body = usingBackend
          ? jsonEncode({
              'apiKey': apiKey,
              'model': modelName,
              'stream': true,
              'request': payload,
            })
          : jsonEncode(payload);
      return makeStreamRequestPlatform(
        client: _client,
        url: url,
        headers: requestHeaders,
        body: body,
        timeout: timeout,
      );
    }

    final answerBuffer = StringBuffer();
    final sseBuffer = StringBuffer();
    final rawResponseBuffer = StringBuffer();
    var sawSse = false;

    Stream<ThoughtChunk> processSseEvent(String event) async* {
      for (final line in event.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        sawSse = true;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final thoughtBuffer = StringBuffer();
          _appendCandidateText(
            jsonDecode(data),
            answerBuffer,
            thoughtOutput: thoughtBuffer,
          );
          final thought = _sanitizeVisibleThoughtText(
            thoughtBuffer.toString(),
          ).trim();
          if (thought.isNotEmpty) yield ThoughtChunk('$thought\n');
        } catch (error) {
          AppLogger.debug('GeminiService', 'Failed to parse SSE chunk: $error');
        }
      }
    }

    final platformStream = await sendRequest(requestBody);
    await for (final chunk in platformStream) {
      rawResponseBuffer.write(chunk);
      sseBuffer.write(chunk.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
      final events = sseBuffer.toString().split('\n\n');
      sseBuffer
        ..clear()
        ..write(events.removeLast());
      for (final event in events) {
        yield* processSseEvent(event);
      }
    }
    if (sseBuffer.isNotEmpty) {
      yield* processSseEvent(sseBuffer.toString());
    }

    if (!sawSse && answerBuffer.isEmpty) {
      final rawResponse = rawResponseBuffer.toString().trim();
      if (rawResponse.isNotEmpty) {
        final decoded = jsonDecode(rawResponse);
        final thoughtBuffer = StringBuffer();
        if (decoded is Map && decoded.containsKey('candidates')) {
          _appendCandidateText(
            decoded,
            answerBuffer,
            thoughtOutput: thoughtBuffer,
          );
          final thought = _sanitizeVisibleThoughtText(
            thoughtBuffer.toString(),
          ).trim();
          if (thought.isNotEmpty) yield ThoughtChunk('$thought\n');
        } else {
          answerBuffer.write(rawResponse);
        }
      }
    }

    final rawAnswer = answerBuffer.toString().trim();
    if (rawAnswer.isEmpty) {
      throw GeminiError(GeminiErrorType.unknown, 'Empty response from Gemini');
    }
    final parsed = _parseJsonFromText(rawAnswer);
    if (parsed == null) {
      throw GeminiError(
        GeminiErrorType.parseError,
        'Failed to parse JSON response',
        technicalDetails: rawAnswer.substring(
          0,
          rawAnswer.length.clamp(0, 200),
        ),
      );
    }
    yield AnalysisResult(parsed);
  }

  void _appendCandidateText(
    dynamic value,
    StringBuffer output, {
    StringBuffer? thoughtOutput,
  }) {
    if (value is! Map) return;
    final candidates = value['candidates'];
    if (candidates is! List) return;
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final parts = candidate['content']?['parts'];
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is! Map) continue;
        final text = part['text']?.toString();
        if (text == null || text.isEmpty) continue;
        if (part['thought'] == true) {
          thoughtOutput?.write(text);
        } else {
          output.write(text);
        }
      }
    }
  }

  String _analysisContextNote(int imageCount) {
    return 'Photo count: $imageCount. Decide whether photos are the same meal from different angles or separate meals to sum; never double-count duplicate angles.';
  }

  Map<String, dynamic> _analysisResponseSchema() => {
    'type': 'OBJECT',
    'properties': {
      'uncertainty_note': {'type': 'STRING'},
      'meal_name': {'type': 'STRING'},
      'calories': {'type': 'NUMBER'},
      'protein': {'type': 'NUMBER'},
      'carbs': {'type': 'NUMBER'},
      'fats': {'type': 'NUMBER'},
      'calories_per_100g': {'type': 'NUMBER'},
      'protein_per_100g': {'type': 'NUMBER'},
      'carbs_per_100g': {'type': 'NUMBER'},
      'fats_per_100g': {'type': 'NUMBER'},
      'detected_quantity': {'type': 'NUMBER'},
      'detected_unit': {
        'type': 'STRING',
        'enum': ['serving', 'gram', 'ml'],
      },
      'confidence_score': {'type': 'NUMBER'},
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'estimated_quantity': {'type': 'NUMBER'},
            'unit': {'type': 'STRING'},
            // Item nutrition is the total contribution of this component in
            // the photographed portion, never a per-100-g value.
            'calories': {'type': 'NUMBER'},
            'protein': {'type': 'NUMBER'},
            'carbs': {'type': 'NUMBER'},
            'fats': {'type': 'NUMBER'},
            'calories_min': {'type': 'NUMBER'},
            'calories_max': {'type': 'NUMBER'},
            'confidence': {'type': 'NUMBER'},
            'assumption': {'type': 'STRING'},
          },
          'required': [
            'name',
            'estimated_quantity',
            'unit',
            'calories',
            'protein',
            'carbs',
            'fats',
            'calories_min',
            'calories_max',
            'confidence',
            'assumption',
          ],
        },
      },
    },
    'required': [
      'uncertainty_note',
      'meal_name',
      'calories',
      'protein',
      'carbs',
      'fats',
      'detected_quantity',
      'detected_unit',
      'confidence_score',
      'items',
    ],
  };

  double? _finiteNonNegative(dynamic value) {
    if (value is! num) return null;
    final number = value.toDouble();
    return number.isFinite && number >= 0 ? number : null;
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic rawItems) {
    if (rawItems is! List) return <Map<String, dynamic>>[];

    const macroKeys = ['calories', 'protein', 'carbs', 'fats'];
    final normalized = <Map<String, dynamic>>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final name = raw['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      if (normalized.length >= 20) break;

      final item = <String, dynamic>{
        'name': name,
        'estimated_quantity':
            _finiteNonNegative(raw['estimated_quantity']) ?? 1.0,
        'unit': raw['unit']?.toString().trim() ?? 'serving',
        'confidence': (_finiteNonNegative(raw['confidence']) ?? 0.5).clamp(
          0.0,
          1.0,
        ),
        'assumption': raw['assumption']?.toString().trim() ?? '',
      };

      final parsedMacros = <String, double>{};
      for (final key in macroKeys) {
        final value = _finiteNonNegative(raw[key]);
        if (value == null) {
          parsedMacros.clear();
          break;
        }
        parsedMacros[key] = value;
      }
      // An incomplete item must not silently zero out a macro. The top-level
      // result remains the fallback when the model violates the item schema.
      if (parsedMacros.length != macroKeys.length) continue;
      item.addAll(parsedMacros);

      final exactCalories = (item['calories'] as num).toDouble();
      final low = _finiteNonNegative(raw['calories_min']) ?? exactCalories;
      final high = _finiteNonNegative(raw['calories_max']) ?? exactCalories;
      item['calories_min'] = low <= high ? low : high;
      item['calories_max'] = high >= low ? high : low;
      normalized.add(item);
    }
    return normalized;
  }

  void _aggregateItemNutrition(
    Map<String, dynamic> result,
    List<Map<String, dynamic>> items,
    NormalizedPortion detectedPortion,
  ) {
    if (items.isEmpty) return;

    const macroKeys = ['calories', 'protein', 'carbs', 'fats'];
    final complete = items.every(
      (item) => macroKeys.every((key) => item[key] is num),
    );
    if (!complete) return;

    final totals = <String, double>{
      for (final key in macroKeys)
        key: items.fold<double>(
          0,
          (sum, item) => sum + (item[key] as num).toDouble(),
        ),
    };
    final quantity = detectedPortion.quantity > 0
        ? detectedPortion.quantity
        : 1.0;
    final divisor = detectedPortion.unit == portionUnitServing
        ? quantity
        : quantity / 100.0;
    final safeDivisor = divisor > 0 ? divisor : 1.0;

    // The app stores the model's values as the base value for the selected
    // unit and applies the detected quantity exactly once in the UI/queue.
    // Summing item totals first prevents hidden oil/sauce from being lost and
    // prevents the model's top-level arithmetic from overriding its own list.
    for (final key in macroKeys) {
      final baseValue = totals[key]! / safeDivisor;
      result[key] = baseValue;
      if (detectedPortion.unit != portionUnitServing) {
        result['${key}_per_100g'] = baseValue;
      }
    }

    final rangeLow = items.fold<double>(
      0,
      (sum, item) => sum + (item['calories_min'] as num).toDouble(),
    );
    final rangeHigh = items.fold<double>(
      0,
      (sum, item) => sum + (item['calories_max'] as num).toDouble(),
    );
    result['calories_min'] = rangeLow / safeDivisor;
    result['calories_max'] = rangeHigh / safeDivisor;

    final assumptions = items
        .where((item) => (item['assumption'] as String).trim().isNotEmpty)
        .map((item) => '${item['name']}: ${item['assumption']}')
        .take(3)
        .join(' · ');
    final existingUncertainty = result['uncertainty_note']?.toString().trim();
    if ((existingUncertainty == null || existingUncertainty.isEmpty) &&
        assumptions.isNotEmpty) {
      result['uncertainty_note'] = assumptions;
    }
  }

  Map<String, dynamic> _normalizeAnalysisResult(Map<String, dynamic> result) {
    final normalized = Map<String, dynamic>.from(result);
    final detectedPortion = normalizeDetectedPortion(normalized);
    normalized['detected_unit'] = detectedPortion.unit;
    normalized['detected_quantity'] = detectedPortion.quantity;

    final items = _normalizeItems(normalized['items']);
    normalized['items'] = items;
    _aggregateItemNutrition(normalized, items, detectedPortion);

    for (final key in const ['calories', 'protein', 'carbs', 'fats']) {
      final value = _finiteNonNegative(normalized[key]);
      if (value == null) {
        throw GeminiError(
          GeminiErrorType.parseError,
          'Gemini returned invalid nutrition values',
        );
      }
      normalized[key] = value;
    }

    final isPer100Mode = isPer100Unit(detectedPortion.unit);
    if (isPer100Mode) {
      normalized['calories_per_100g'] ??= normalized['calories'];
      normalized['protein_per_100g'] ??= normalized['protein'];
      normalized['carbs_per_100g'] ??= normalized['carbs'];
      normalized['fats_per_100g'] ??= normalized['fats'];
      normalized['calories'] = normalized['calories_per_100g'];
      normalized['protein'] = normalized['protein_per_100g'];
      normalized['carbs'] = normalized['carbs_per_100g'];
      normalized['fats'] = normalized['fats_per_100g'];
    }
    normalized['uncertainty_note'] ??= '';
    final rawConfidence = _finiteNonNegative(normalized['confidence_score']);
    normalized['confidence_score'] = (rawConfidence ?? 0.5).clamp(0.0, 1.0);
    return normalized;
  }

  /// Parses a JSON [Map] from raw model text, filtering out reasoning chunks automatically.
  Map<String, dynamic>? _parseJsonFromText(String text) {
    String cleaned = text.trim();

    // 1. Try to find JSON inside markdown fences (most robust if present)
    final fenceRegExp = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
    final match = fenceRegExp.firstMatch(cleaned);
    if (match != null) {
      try {
        final result = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        _logValidation(result);
        return result;
      } catch (_) {}
    }

    // 2. Fallback: Find the last { ... } block containing expected keys
    // In case there are no fences and thoughts contain `{` or `}`.
    final keyIdx = cleaned.indexOf('"meal_name"');

    if (keyIdx != -1) {
      // Find the `{` immediately preceding our key
      final startIdx = cleaned.lastIndexOf('{', keyIdx);
      if (startIdx != -1) {
        // Find the last `}` in the string to close it
        final endIdx = cleaned.lastIndexOf('}');
        if (endIdx != -1 && endIdx > startIdx) {
          final possibleJson = cleaned.substring(startIdx, endIdx + 1);
          try {
            final result = jsonDecode(possibleJson) as Map<String, dynamic>;
            _logValidation(result);
            return result;
          } catch (_) {}
        }
      }
    }

    // 3. Simple Greedy Fallback
    final greedyMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (greedyMatch != null) {
      try {
        final result =
            jsonDecode(greedyMatch.group(0)!) as Map<String, dynamic>;
        _logValidation(result);
        return result;
      } catch (_) {}
    }

    return null;
  }

  void _logValidation(Map<String, dynamic> json) {
    if (json.containsKey('calories') &&
        json.containsKey('protein') &&
        json.containsKey('carbs') &&
        json.containsKey('fats')) {
      final double cal = (json['calories'] as num).toDouble();
      final double p = (json['protein'] as num).toDouble();
      final double c = (json['carbs'] as num).toDouble();
      final double f = (json['fats'] as num).toDouble();
      final double calculated = (p * 4) + (c * 4) + (f * 9);
      final double diff = (cal - calculated).abs();
      AppLogger.info(
        'GeminiService',
        'Atwater Check: Reported=$cal, Calculated=$calculated, Diff=$diff',
      );
    }
    if (json.containsKey('confidence_score')) {
      AppLogger.info(
        'GeminiService',
        'Confidence Score: ${json['confidence_score']}',
      );
    }
  }

  Future<bool> validateApiKey(String key) async {
    if (key.isEmpty) return false;

    final backend = _backendBaseUrl;
    if (backend.isNotEmpty) {
      try {
        final response = await _client.post(
          Uri.parse('$backend/v1/validate-key'),
          headers: {
            'Content-Type': 'application/json',
            if (_analysisBackendToken.isNotEmpty)
              'x-kalorat-relay-token': _analysisBackendToken,
          },
          body: jsonEncode({'apiKey': key}),
        );
        if (response.statusCode != 200) return false;
        final decoded = jsonDecode(response.body);
        return decoded is Map && decoded['valid'] == true;
      } catch (_) {
        return false;
      }
    }

    // Direct mode remains available for local/native BYOK use.
    final url = '$_baseUrlBase?key=$key';
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _getPrompt(
    String language, {
    bool useGrams = false,
    bool allowEstimateVariation = false,
  }) {
    final unitRules = useGrams
        ? (language == 'de'
              ? 'Verwende gram für feste Speisen und ml für Flüssigkeiten. Nährwerte calories/protein/carbs/fats sind pro 100 g bzw. 100 ml; detected_quantity ist die gesamte Menge.'
              : 'Use gram for solids and ml for liquids. calories/protein/carbs/fats are per 100 g or 100 ml; detected_quantity is the total amount.')
        : (language == 'de'
              ? 'Verwende serving. Nährwerte calories/protein/carbs/fats sind pro eine Portion; detected_quantity ist die Portionszahl. Nur ein sichtbares Etikett darf gram/ml erzwingen.'
              : 'Use serving. calories/protein/carbs/fats are per one serving; detected_quantity is the serving count. Only a visible label may force gram/ml.');
    final retryRule = allowEstimateVariation
        ? (language == 'de'
              ? 'Prüfe die vorherige Schätzung kritisch und korrigiere die wahrscheinlichste falsche Annahme.'
              : 'Challenge the previous estimate and correct the most likely wrong assumption.')
        : (language == 'de'
              ? 'Bleibe bei stabilen, konservativen Schätzungen.'
              : 'Keep estimates stable and conservative.');
    if (language == 'de') {
      return '''Analysiere die sichtbare Mahlzeit präzise. Antworte ausschließlich mit einem JSON-Objekt gemäß Schema; keine Markdown-Zäune und keine Denk- oder Verifikationsschritte.

$unitRules
$retryRule
- Erkenne alle sichtbaren Komponenten einzeln, einschließlich Getränke, Toppings und Sauce/Dressing. Verstecktes Öl nur als Annahme aufnehmen, wenn Bild oder Nutzerhinweis dafür sprechen; sonst nur die Unsicherheit in der Spanne berücksichtigen. Unsichtbare Zutaten nicht als sicher behaupten; Unsicherheit in assumption/uncertainty_note markieren.
- Mehrere Fotos derselben Mahlzeit aus anderen Winkeln nur einmal zählen. Verschiedene Mahlzeiten summieren.
- Nutze Etikett und Nutzerhinweis vor visueller Schätzung. Verwende typische gekochte Lebensmittelwerte.
- Schätze Portionen anhand Teller/Glas/Verpackung. Keine falsche Präzision: confidence_score zwischen 0 und 1.
- items enthält jede wesentliche sichtbare Komponente einzeln. Die Makros jedes items sind der Gesamtbeitrag dieser Komponente in der fotografierten Menge, niemals pro 100 g. calories/protein/carbs/fats auf oberster Ebene sind die Summe der items, umgerechnet auf die gewählte Basis-Einheit.
- Führe Öl, Butter, Dressing und Sauce nur dann als eigene items auf, wenn sie visuell oder durch den Nutzerhinweis gestützt sind; bei nicht sichtbaren Mengen nutze die Spanne statt eines scheinbar exakten Werts und schreibe die Annahme in assumption und uncertainty_note. Unsichtbare Zutaten nicht als sicher behaupten.
- calories/protein/carbs/fats sind die Basiswerte gemäß Einheit. Runde kcal ganz und Makros auf 0.1.
- meal_name auf Deutsch, uncertainty_note maximal 240 Zeichen.''';
    }
    return '''Analyze the visible meal precisely. Return only one JSON object matching the schema; no Markdown fences and no chain-of-thought or verification transcript.

$unitRules
$retryRule
- Identify every visible component, including drinks, toppings, and sauces/dressings. Add hidden oil only when the image or user note supports it; otherwise express it through the uncertainty range. Do not state invisible ingredients as certain; mark uncertainty in assumption/uncertainty_note.
- Count multiple photos from different angles only once. Sum genuinely different meals.
- Prefer visible labels and user notes over visual guesses. Use typical cooked-food nutrition values.
- Estimate portions using plates, glasses, packaging, and other scale cues. Avoid false precision: confidence_score is 0 to 1.
- items contains each material visible component separately. Each item's macros are that component's total contribution in the photographed amount, never per 100 g. Top-level calories/protein/carbs/fats are the item sum converted to the selected base unit.
- Represent oil, butter, dressing, and sauce as separate items only when visually or contextually supported. For hidden amounts, use calories_min/calories_max for a plausible low/high contribution and explain the assumption in assumption and uncertainty_note. Never claim invisible ingredients as certain.
- calories/protein/carbs/fats are the base values for the selected unit. Round kcal to whole numbers and macros to 0.1.
- meal_name in English, uncertainty_note maximum 240 characters.''';
  }
}
