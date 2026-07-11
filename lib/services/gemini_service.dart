import 'dart:async';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import '../utils/platform_utils.dart';
import 'gemini_stream_client.dart';

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

/// Marks which pass of the analysis pipeline is currently active.
class AnalysisPhaseChanged extends AnalysisProgress {
  final AnalysisPhase phase;
  const AnalysisPhaseChanged(this.phase);
}

enum AnalysisPhase { drafting, verifying }

/// The final JSON analysis result.
class AnalysisResult extends AnalysisProgress {
  final Map<String, dynamic> data;
  const AnalysisResult(this.data);
}

String _sanitizeVisibleThoughtText(String text) {
  if (text.isEmpty) return text;

  final withoutFences = text
      .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
      .replaceAll('```', '');
  final lines = withoutFences.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final filtered = lines
      .split('\n')
      .where((line) {
        final lower = line.toLowerCase();
        return !lower.contains('json') &&
            !lower.contains('schema') &&
            !lower.contains('response format') &&
            !lower.contains('roh-json') &&
            !lower.contains('raw json');
      })
      .join('\n');

  return filtered;
}

class _StreamedJsonThoughtSplitter {
  static final RegExp _jsonStartRegExp = RegExp(
    r'```(?:json)?\s*\{|\{\s*"(?:analysis_note|meal_name|calories)"',
  );

  static final RegExp _pendingFenceRegExp = RegExp(
    r'(?:`{1,2}|```(?:j(?:s(?:o(?:n)?)?)?)?\s*)$',
  );

  final StringBuffer answerBuffer = StringBuffer();
  final StringBuffer _pendingThought = StringBuffer();
  bool _jsonStarted = false;

  Iterable<ThoughtChunk> addText(String text) sync* {
    answerBuffer.write(text);

    if (_jsonStarted) return;

    final candidate = _pendingThought.toString() + text;
    _pendingThought.clear();

    final match = _jsonStartRegExp.firstMatch(candidate);
    if (match != null) {
      _jsonStarted = true;
      final thoughtText = candidate.substring(0, match.start);
      final visibleThoughtText = _sanitizeVisibleThoughtText(thoughtText);
      if (visibleThoughtText.isNotEmpty) {
        yield ThoughtChunk(visibleThoughtText);
      }
      return;
    }

    final pendingMatch = _pendingFenceRegExp.firstMatch(candidate);
    final safeText = pendingMatch == null
        ? candidate
        : candidate.substring(0, pendingMatch.start);
    final pendingText = pendingMatch == null
        ? ''
        : candidate.substring(pendingMatch.start);

    final visibleSafeText = _sanitizeVisibleThoughtText(safeText);
    if (visibleSafeText.isNotEmpty) {
      yield ThoughtChunk(visibleSafeText);
    }
    if (pendingText.isNotEmpty) {
      _pendingThought.write(pendingText);
    }
  }
}

class GeminiService {
  static const String _baseUrlBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

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
  }) : _client = client ?? http.Client();

  Map<String, dynamic> _generationControls({
    required bool allowEstimateVariation,
  }) {
    if (allowEstimateVariation) {
      return {
        'temperature': 0.28,
        'topP': 0.55,
        'topK': 8,
        'candidateCount': 1,
      };
    }

    return {'temperature': 0.12, 'topP': 0.35, 'topK': 4, 'candidateCount': 1};
  }

  /// Fetches available models from the API, filtering for Flash.
  Future<List<String>> _getAvailableModels() async {
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

        for (final model in [
          ..._preferredFlashModels,
          ..._preferredFlashLiteModels,
        ].reversed) {
          if (!supportedModels.contains(model)) {
            supportedModels.insert(0, model);
          }
        }

        AppLogger.info('GeminiService', 'Discovered models: $supportedModels');
        return supportedModels;
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
  /// - [ThoughtChunk] events fire as the model streams its thinking summaries.
  /// - A single [AnalysisResult] event fires when the full JSON is ready.
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

    // Get fresh list of models
    final candidates = _orderedModelsForMode(
      await _getAvailableModels(),
      useAccurateMode: useAccurateMode,
    );

    final availableModels = candidates.isNotEmpty ? candidates : ['gemini-flash-lite-latest'];

    for (final model in availableModels) {
      try {
        bool gotResult = false;
        yield const AnalysisPhaseChanged(AnalysisPhase.drafting);
        await for (final event in _makeStreamRequest(
          model,
          imagePaths,
          useGrams: useGrams,
          mealContext: mealContext,
          useAccurateMode: useAccurateMode,
          allowEstimateVariation: allowEstimateVariation,
          previousAnalysis: previousAnalysis,
        )) {
          if (event is AnalysisResult) {
            yield const AnalysisPhaseChanged(AnalysisPhase.verifying);
            bool gotVerifiedResult = false;
            await for (final verifyEvent in _verifyAnalysisStream(
              model,
              event.data,
              imageCount: imagePaths.length,
              useGrams: useGrams,
              mealContext: mealContext,
              useAccurateMode: useAccurateMode,
              allowEstimateVariation: allowEstimateVariation,
              previousAnalysis: previousAnalysis,
            )) {
              yield verifyEvent;
              if (verifyEvent is AnalysisResult) {
                gotVerifiedResult = true;
              }
            }
            if (!gotVerifiedResult) {
              yield AnalysisResult(_normalizeAnalysisResult(event.data));
            }
            gotResult = true;
          } else {
            yield event;
          }
        }
        if (gotResult) {
          return;
        }
      } catch (e) {
        AppLogger.warning(
          'GeminiService',
          'Stream: Model $model failed: $e. Trying next...',
        );
        continue;
      }
    }

    throw GeminiError(
      GeminiErrorType.unknown,
      'Failed to analyze image with any available model.',
    );
  }

  /// Internal streaming request using SSE (streamGenerateContent endpoint).
  Stream<AnalysisProgress> _makeStreamRequest(
    String modelName,
    List<String> imagePaths, {
    bool useGrams = false,
    String? mealContext,
    bool useAccurateMode = true,
    bool allowEstimateVariation = false,
    Map<String, dynamic>? previousAnalysis,
  }) async* {
    // Prepare image parts
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

    final prompt = _getPrompt(
      language,
      useGrams: useGrams,
      allowEstimateVariation: allowEstimateVariation,
    );

    final List<Map<String, dynamic>> contentParts = [...imageParts];
    contentParts.add({'text': _analysisContextNote(imageParts.length)});
    if (mealContext != null && mealContext.trim().isNotEmpty) {
      contentParts.add({'text': 'User note: ${mealContext.trim()}'});
    }
    if (previousAnalysis != null) {
      contentParts.add({
        'text':
            'Previous estimate to challenge and revise if needed: ${jsonEncode(previousAnalysis)}',
      });
    }

    // For streaming we use text output (not responseMimeType: application/json)
    // because streaming + responseSchema is not always supported.
    // We parse the JSON from the final text part ourselves.
    final Map<String, dynamic> generationConfig = {
      ..._generationControls(allowEstimateVariation: allowEstimateVariation),
      'maxOutputTokens': 3072,
      'thinkingConfig': {
        'includeThoughts': true,
        'thinkingLevel': useAccurateMode ? 'HIGH' : 'MINIMAL',
      },
    };

    final Map<String, dynamic> requestBody = {
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

    final url =
        '$_baseUrlBase/$modelName:streamGenerateContent?alt=sse&key=$apiKey';

    final timeout = useAccurateMode
        ? const Duration(seconds: 120)
        : const Duration(seconds: 60);

    // Swap standard StreamedResponse with platform-optimized streaming loader
    final headers = {'Content-Type': 'application/json'};

    Stream<String> platformStream;
    try {
      platformStream = makeStreamRequestPlatform(
        client: _client,
        url: url,
        headers: headers,
        body: jsonEncode(requestBody),
        timeout: timeout,
      );
    } catch (e) {
      AppLogger.error('GeminiService', 'Failed to initiate stream request', e);
      rethrow;
    }

    // SSE parsing state
    final thoughtSplitter = _StreamedJsonThoughtSplitter();
    final StringBuffer lineBuffer = StringBuffer();

    // Helper to process SSE events and separate live thoughts from final JSON.
    Stream<AnalysisProgress> processSseEvent(String event) async* {
      final dataLines = event
          .split('\n')
          .where((l) => l.startsWith('data: '))
          .map((l) => l.substring(6).trim())
          .toList();

      for (final dataStr in dataLines) {
        if (dataStr.isEmpty || dataStr == '[DONE]') continue;
        try {
          final json = jsonDecode(dataStr) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>? ?? [];
          for (final candidate in candidates) {
            final parts =
                (candidate['content']?['parts'] as List<dynamic>?) ?? [];
            for (final part in parts) {
              final text = part['text'] as String?;
              final isThought = part['thought'] as bool? ?? false;
              if (text == null || text.isEmpty) continue;

              if (isThought) {
                final visibleThoughtText = _sanitizeVisibleThoughtText(text);
                if (visibleThoughtText.isNotEmpty) {
                  yield ThoughtChunk(visibleThoughtText);
                }
              } else {
                for (final chunk in thoughtSplitter.addText(text)) {
                  yield chunk;
                }
              }
            }
          }
        } catch (e) {
          AppLogger.debug('GeminiService', 'Failed to parse SSE chunk: $e');
        }
      }
    }

    await for (final chunk in platformStream) {
      lineBuffer.write(chunk.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
      final raw = lineBuffer.toString();
      // SSE events are separated by double newlines
      final events = raw.split('\n\n');
      // Keep the last (potentially incomplete) part in the buffer
      lineBuffer.clear();
      lineBuffer.write(events.removeLast());

      for (final event in events) {
        yield* processSseEvent(event);
      }
    }

    // Process anything that was left over in the line buffer (prevent missing the final closing brace)
    if (lineBuffer.isNotEmpty) {
      yield* processSseEvent(lineBuffer.toString());
    }

    // Parse accumulated answer as JSON
    final rawAnswer = thoughtSplitter.answerBuffer.toString().trim();
    if (rawAnswer.isEmpty) {
      throw GeminiError(GeminiErrorType.unknown, 'Empty response from Gemini');
    }

    final parsed = _parseJsonFromText(rawAnswer);
    if (parsed != null) {
      AppLogger.info('GeminiService', 'Stream result: ${parsed['meal_name']}');
      yield AnalysisResult(parsed);
    } else {
      throw GeminiError(
        GeminiErrorType.parseError,
        'Failed to parse JSON response',
        technicalDetails:
            'Raw: ${rawAnswer.substring(0, rawAnswer.length.clamp(0, 200))}',
      );
    }
  }



  Stream<AnalysisProgress> _verifyAnalysisStream(
    String modelName,
    Map<String, dynamic>? draft, {
    required int imageCount,
    required bool useGrams,
    required bool useAccurateMode,
    required bool allowEstimateVariation,
    String? mealContext,
    Map<String, dynamic>? previousAnalysis,
  }) async* {
    if (draft == null || draft['error'] == 'no_food_detected') {
      yield AnalysisResult(draft ?? {'error': 'no_food_detected'});
      return;
    }

    final verificationPrompt = language == 'de'
        ? '''Pruefe den Analyse-Entwurf als zweiter, strenger Verifikationsschritt.

Aufgaben:
- Entscheide, ob $imageCount Foto(s) dieselbe Mahlzeit aus mehreren Winkeln zeigen oder mehrere unterschiedliche Mahlzeiten, die summiert werden muessen.
- Wenn es mehrere Mahlzeiten sind: summiere calories, protein, carbs, fats und setze einen passenden gemeinsamen meal_name.
- Wenn es dieselbe Mahlzeit ist: nutze die Fotos als zusaetzliche Winkel, nicht als doppelte Portion.
- Pruefe portion/detected_quantity/detected_unit und korrigiere unplausible Werte.
- Pruefe kcal grob gegen protein*4 + carbs*4 + fats*9.
- Gib per-100g Referenzwerte fuer die gesamte sichtbare Mahlzeit aus. Bei fluessigen Mahlzeiten entspricht per_100g per_100ml.
- Retry-Modus: ${allowEstimateVariation ? 'Challenge den vorherigen Wert und korrigiere die wahrscheinlichste falsche Annahme, aber bleibe plausibel.' : 'Bewahre stabile, konservative Schaetzungen.'}

Streame kurze Pruefnotizen als Gedanken und beende mit JSON im geforderten Schema.'''
        : '''Verify the draft as a strict second analysis pass.

Tasks:
- Decide whether the $imageCount photo(s) show the same meal from different angles or multiple different meals that must be summed.
- If they are multiple meals: sum calories, protein, carbs, fats and set a suitable combined meal_name.
- If they are the same meal: use the photos as extra angles, not duplicate portions.
- Check portion/detected_quantity/detected_unit and correct implausible values.
- Check kcal roughly against protein*4 + carbs*4 + fats*9.
- Return per-100g reference values for the whole visible meal. For liquid meals, per_100g means per_100ml.
- Retry mode: ${allowEstimateVariation ? 'Challenge the previous value and correct the most likely wrong assumption, while staying plausible.' : 'Keep estimates stable and conservative.'}

Stream short verification notes as thoughts and finish with JSON in the required schema.''';

    final content = <Map<String, dynamic>>[
      {'text': _analysisContextNote(imageCount)},
      if (mealContext != null && mealContext.trim().isNotEmpty)
        {'text': 'User note: ${mealContext.trim()}'},
      if (previousAnalysis != null)
        {'text': 'Previous estimate: ${jsonEncode(previousAnalysis)}'},
      {'text': 'Draft estimate to verify: ${jsonEncode(draft)}'},
    ];

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': verificationPrompt},
        ],
      },
      'contents': [
        {'parts': content},
      ],
      'generationConfig': {
        ..._generationControls(allowEstimateVariation: allowEstimateVariation),
        'maxOutputTokens': 1536,
        'thinkingConfig': {
          'includeThoughts': true,
          'thinkingLevel': useAccurateMode ? 'HIGH' : 'MINIMAL',
        },
      },
    };

    try {
      final url =
          '$_baseUrlBase/$modelName:streamGenerateContent?alt=sse&key=$apiKey';
      final timeout = useAccurateMode
          ? const Duration(seconds: 90)
          : const Duration(seconds: 45);
      final platformStream = makeStreamRequestPlatform(
        client: _client,
        url: url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
        timeout: timeout,
      );

      final thoughtSplitter = _StreamedJsonThoughtSplitter();
      final lineBuffer = StringBuffer();

      Stream<AnalysisProgress> processSseEvent(String event) async* {
        final dataLines = event
            .split('\n')
            .where((l) => l.startsWith('data: '))
            .map((l) => l.substring(6).trim())
            .toList();

        for (final dataStr in dataLines) {
          if (dataStr.isEmpty || dataStr == '[DONE]') continue;
          try {
            final json = jsonDecode(dataStr) as Map<String, dynamic>;
            final candidates = json['candidates'] as List<dynamic>? ?? [];
            for (final candidate in candidates) {
              final parts =
                  (candidate['content']?['parts'] as List<dynamic>?) ?? [];
              for (final part in parts) {
                final text = part['text'] as String?;
                final isThought = part['thought'] as bool? ?? false;
                if (text == null || text.isEmpty) continue;

                if (isThought) {
                  final visibleThoughtText = _sanitizeVisibleThoughtText(text);
                  if (visibleThoughtText.isNotEmpty) {
                    yield ThoughtChunk(visibleThoughtText);
                  }
                  continue;
                }

                for (final chunk in thoughtSplitter.addText(text)) {
                  yield chunk;
                }
              }
            }
          } catch (e) {
            AppLogger.debug(
              'GeminiService',
              'Failed to parse verification SSE chunk: $e',
            );
          }
        }
      }

      await for (final chunk in platformStream) {
        lineBuffer.write(chunk.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
        final events = lineBuffer.toString().split('\n\n');
        lineBuffer
          ..clear()
          ..write(events.removeLast());

        for (final event in events) {
          yield* processSseEvent(event);
        }
      }

      if (lineBuffer.isNotEmpty) {
        yield* processSseEvent(lineBuffer.toString());
      }

      final rawAnswer = thoughtSplitter.answerBuffer.toString().trim();
      final parsed = rawAnswer.isEmpty ? null : _parseJsonFromText(rawAnswer);
      yield AnalysisResult(_normalizeAnalysisResult(parsed ?? draft));
    } catch (e) {
      AppLogger.warning(
        'GeminiService',
        'Streaming verification failed: $e. Using draft.',
      );
      yield AnalysisResult(_normalizeAnalysisResult(draft));
    }
  }



  String _analysisContextNote(int imageCount) {
    return 'Photo count: $imageCount. Determine whether multiple photos are different angles of the same meal or different meals to sum.';
  }

  Map<String, dynamic> _normalizeAnalysisResult(Map<String, dynamic> result) {
    final detectedPortion = normalizeDetectedPortion(result);
    result['detected_unit'] = detectedPortion.unit;
    result['detected_quantity'] = detectedPortion.quantity;

    final isPer100Mode = isPer100Unit(detectedPortion.unit);
    if (isPer100Mode) {
      result['calories_per_100g'] ??= result['calories'];
      result['protein_per_100g'] ??= result['protein'];
      result['carbs_per_100g'] ??= result['carbs'];
      result['fats_per_100g'] ??= result['fats'];
      result['calories'] = result['calories_per_100g'];
      result['protein'] = result['protein_per_100g'];
      result['carbs'] = result['carbs_per_100g'];
      result['fats'] = result['fats_per_100g'];
    }
    result['photo_interpretation'] ??= 'single_meal_or_same_angle';
    return result;
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
    final analysisNoteIdx = cleaned.indexOf('"analysis_note"');
    final fallbackIdx = cleaned.indexOf('"meal_name"');
    final keyIdx = analysisNoteIdx != -1 ? analysisNoteIdx : fallbackIdx;

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

  String _getPrompt(
    String language, {
    bool useGrams = false,
    bool allowEstimateVariation = false,
  }) {
    if (language == 'de') {
      return '''Du bist ein präziser KI-Ernährungsberater. Analysiere das/die Bild(er) und jeden Nutzerhinweis mit einem stabilen, reproduzierbaren Verfahren.

EINHEITENMODUS – KRITISCH – STRIKTE REGELN:
${useGrams ? '''GRAMM-MODUS (aktiv): Du musst IMMER Gramm oder ml verwenden.
- detected_unit = "gram" (bei festen Speisen) oder "ml" (bei Flüssigkeiten/Getränken)
- Alle Nährwerte (calories, protein, carbs, fats) = IMMER pro 100g oder pro 100ml
- detected_quantity = geschätzte Gesamtmenge in Gramm oder ml''' : '''PORTIONS-MODUS (aktiv): Du musst IMMER Portionen verwenden – NIEMALS Gramm oder ml.
- detected_unit = "serving" – AUSNAHME: Nur wenn ein Nährwertetikett explizit "pro 100g" oder "pro 100ml" anzeigt, verwende "gram" oder "ml"
- Alle Nährwerte (calories, protein, carbs, fats) = IMMER pro 1 Portion
- detected_quantity = geschätzte Anzahl Portionen (z.B. 1.0, 2.0, 0.5)
- Auch wenn du Gramm einschätzt: Rechne in Portionen um und verwende "serving"'''}

STABILITÄT UND GENAUIGKEIT:
${allowEstimateVariation ? '- Dies ist eine erneute Analyse. Prüfe die Mengenannahmen neu und erlaube eine alternative realistische Schätzung, besonders wenn der Nutzerhinweis mehr Kontext liefert.' : '- Verwende bei gleicher Bildlage eine stabile konservative Schätzung. Nicht kreativ variieren.'}
- Priorität: sichtbares Nährwertetikett > Nutzerhinweis > klar erkennbare Standardportion > visuelle Gewichtsschätzung.
- Wenn kein Etikett sichtbar ist, nutze typische gekochte Lebensmittelwerte, nicht Restaurant-Spitzenwerte.
- Runden: calories auf ganze kcal, protein/carbs/fats auf 0.1g, detected_quantity auf 0.1.
- Wenn eine Komponente unsicher ist, wähle den mittleren realistischen Wert und dokumentiere die Unsicherheit in analysis_note.
- Bleibe innerhalb plausibler Nährwertbereiche. Eine erneute Analyse darf anders sein, aber nicht willkürlich.
- Für sichtbare Meal-Prep-Boxen: teile die Fläche in Komponenten, schätze jede Komponente separat, summiere danach.

MEHRERE FOTOS:
- Entscheide zuerst, ob mehrere Fotos dieselbe Mahlzeit aus unterschiedlichen Winkeln zeigen oder unterschiedliche Mahlzeiten.
- Gleiche Mahlzeit/andere Winkel: NICHT doppelt zählen. Nutze die Zusatzfotos nur zur besseren Mengen- und Zutatenbestimmung.
- Unterschiedliche Mahlzeiten: Summiere alle Mahlzeiten zu einem Eintrag und benenne ihn passend.
- Dokumentiere diese Entscheidung knapp in photo_interpretation.

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

NÄHRWERT-AUSGABE – KRITISCH:
- calories, protein, carbs, fats IMMER PRO 100g (Gramm-Modus) oder PRO 1 PORTION (Portions-Modus) angeben.
- NIEMALS die Werte für die Gesamtmenge skalieren. Die App übernimmt die Skalierung.
- detected_quantity = geschätzte GESAMTE Menge des Essens (z.B. 250g, 2 Portionen).
- Beispiel Gramm-Modus: 250g Reis → calories/protein/carbs/fats pro 100g angeben, detected_quantity=250.
- Beispiel Portions-Modus: 2 Portionen → Werte pro 1 Portion angeben, detected_quantity=2.
- Wenn ein Nährwertetikett sichtbar ist: Werte PRO 100g (oder pro Portion wie auf dem Etikett) direkt übernehmen. detected_quantity = geschätzte Gesamtmenge.
- calories_per_100g, protein_per_100g, carbs_per_100g, fats_per_100g IMMER für die sichtbare Gesamtmahlzeit angeben. Bei Flüssigkeiten bedeutet _per_100g pro 100ml.
- detected_unit darf NUR "gram", "ml" oder "serving" sein. Verwende NIEMALS "liter", "liters", "l", "grams" oder "servings".

kJ vs. kcal – KRITISCH:
- Europäische Etiketten zeigen oft kJ UND kcal. Verwende IMMER kcal. 1 kcal ≈ 4,18 kJ.

MENGEN-REFERENZ: ${useGrams ? 'Volle Pfanne ~800–1200g. Normaler Teller ~350–500g. Glas ~200–300ml. Schüssel ~400–600g.' : 'Normaler Teller ~1.0 Portion. Volle Pfanne ~2–4 Portionen. Getränk: Menge in Portionen (z.B. 1.0).'}

NAME: meal_name IMMER auf Deutsch.

SICHTBARE GEDANKEN-ZUSAMMENFASSUNG:
- Falls vor dem JSON eine sichtbare Denkzusammenfassung gestreamt wird, formatiere sie als kurzes Markdown.
- Nutze höchstens eine Überschrift und 2-4 Bulletpoints. Kein Roh-JSON in der Zusammenfassung.

ANTWORTE NUR ALS JSON. "analysis_note" MUSS ZUERST KOMMEN.
Pflichtfelder: analysis_note, meal_name, calories, protein, carbs, fats, calories_per_100g, protein_per_100g, carbs_per_100g, fats_per_100g, detected_quantity, detected_unit, photo_interpretation, confidence_score.
''';
    } else {
      return '''You are a precise AI nutritionist. Analyze the image(s) and any user notes with a stable, repeatable method.

UNIT MODE – CRITICAL – STRICT RULES:
${useGrams ? '''GRAMS MODE (active): You MUST always use grams or ml.
- detected_unit = "gram" (for solid foods) or "ml" (for liquids/drinks)
- All nutrients (calories, protein, carbs, fats) = ALWAYS per 100g or per 100ml
- detected_quantity = estimated total quantity in grams or ml''' : '''SERVING MODE (active): You MUST always use servings – NEVER grams or ml.
- detected_unit = "serving" – EXCEPTION: Only if a nutrition label explicitly shows "per 100g" or "per 100ml", use "gram" or "ml"
- All nutrients (calories, protein, carbs, fats) = ALWAYS per 1 serving
- detected_quantity = estimated number of servings (e.g. 1.0, 2.0, 0.5)
- Even if you estimate grams internally: convert to servings and use "serving"'''}

STABILITY AND ACCURACY:
${allowEstimateVariation ? '- This is a retry analysis. Re-check portion assumptions and allow one alternative realistic estimate, especially if the user note adds context.' : '- For the same image, use a stable conservative estimate. Do not vary creatively.'}
- Priority: visible nutrition label > user note > clearly recognized standard serving > visual weight estimate.
- If no label is visible, use typical cooked-food nutrition values, not restaurant outliers.
- Rounding: calories to whole kcal, protein/carbs/fats to 0.1g, detected_quantity to 0.1.
- If a component is uncertain, choose the middle realistic value and document the uncertainty in analysis_note.
- Stay inside plausible nutrition ranges. A retry may differ, but it must not be arbitrary.
- For visible meal-prep containers: divide the visible area into components, estimate each component separately, then sum.

MULTIPLE PHOTOS:
- First decide whether multiple photos show the same meal from different angles or different meals.
- Same meal/different angles: do NOT count it twice. Use extra photos only to improve portion and ingredient estimation.
- Different meals: sum all meals into one entry and choose a suitable combined meal_name.
- Document this decision briefly in photo_interpretation.

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

NUTRITION OUTPUT – CRITICAL:
- calories, protein, carbs, fats MUST ALWAYS be PER 100g (gram mode) or PER 1 SERVING (serving mode).
- NEVER scale values to the total quantity. The app handles scaling.
- detected_quantity = estimated TOTAL quantity of the food (e.g. 250g, 2 servings).
- Example gram mode: 250g rice → report calories/protein/carbs/fats per 100g, detected_quantity=250.
- Example serving mode: 2 servings → report values per 1 serving, detected_quantity=2.
- If a nutrition label is visible: use the values PER 100g (or per serving as shown on label) directly. detected_quantity = estimated total quantity.
- calories_per_100g, protein_per_100g, carbs_per_100g, fats_per_100g MUST always describe the whole visible meal. For liquids, _per_100g means per 100ml.
- detected_unit may ONLY be "gram", "ml", or "serving". NEVER output "liter", "liters", "l", "grams", or "servings".

kJ vs kcal – CRITICAL:
- European labels show BOTH kJ and kcal. ALWAYS use kcal. 1 kcal ≈ 4.18 kJ.

QUANTITY REFERENCE: ${useGrams ? 'Full pan ~800–1200g. Standard plate ~350–500g. Glass ~200–300ml. Bowl ~400–600g.' : 'Standard plate ~1.0 serving. Full pan ~2–4 servings. Drink: quantity in servings (e.g. 1.0).'}

NAME: meal_name ALWAYS in English.

VISIBLE THOUGHT SUMMARY:
- If a visible thought summary is streamed before the JSON, format it as concise Markdown.
- Use at most one heading and 2-4 bullets. Do not stream raw JSON in the summary.

RESPONSE FORMAT: JSON ONLY. "analysis_note" MUST BE FIRST.
Required fields: analysis_note, meal_name, calories, protein, carbs, fats, calories_per_100g, protein_per_100g, carbs_per_100g, fats_per_100g, detected_quantity, detected_unit, photo_interpretation, confidence_score.
''';
    }
  }
}
