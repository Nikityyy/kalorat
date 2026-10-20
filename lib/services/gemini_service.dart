import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../utils/analysis_parser.dart';
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import '../utils/photo_downscale.dart';
import 'gemini_stream_client.dart';
import 'nutrition_reference.dart';
import 'photo_store.dart';

/// Longest side of a photo sent for analysis. Large enough for label text
/// and small items such as a glaze or a drizzle of oil; a 1536 px JPEG is
/// still only a few hundred KB.
const int _analysisMaxDimension = 1536;

/// Decode, resize and recompress an image off the UI isolate.
Map<String, String> _prepareImageInIsolate(Map<String, dynamic> input) {
  final bytes = Uint8List.fromList((input['bytes'] as List).cast<int>());
  final decoded = img.decodeImage(bytes);
  final sourceMimeType = input['mimeType']?.toString() ?? 'image/jpeg';
  if (decoded == null) {
    return {'data': base64Encode(bytes), 'mimeType': sourceMimeType};
  }

  final maxDimension = input['maxDimension'] as int;
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

/// Outcome of checking an API key. [unreachable] means the key could not be
/// checked (network, quota or server problem), which says nothing about it.
enum ApiKeyStatus { valid, invalid, unreachable }

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

/// The names of the meal's components the answer has named so far.
class ComponentsSeen extends AnalysisProgress {
  final List<String> names;
  const ComponentsSeen(this.names);
}

/// One of [total] parallel estimates is done; [calories] is its total.
class EstimateReady extends AnalysisProgress {
  final int count;
  final int total;
  final double calories;
  const EstimateReady(this.count, this.total, this.calories);
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

    // Flash Lite in both modes, Flash only when Flash Lite fails. On the
    // free tier Flash allows 20 requests a day against 500 for Flash Lite,
    // and in a test on weighed meals it was not more accurate, but took
    // about 40 s instead of 16 s.
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
  /// Accurate Mode runs [ensembleSize] independent estimates in parallel
  /// and keeps the median one: a single estimate of the same photo varies by
  /// about 9 % from run to run, the median of three by about 4 %. They run at
  /// the same time, so it takes about as long as one. Fast Mode runs one.
  Stream<AnalysisProgress> analyzeMealStream(
    List<String> imagePaths, {
    bool useGrams = false,
    String? mealContext,
    bool useAccurateMode = true,
    bool allowEstimateVariation = false,
    Map<String, dynamic>? previousAnalysis,
    List<String> leftoverPaths = const [],
  }) async* {
    if (apiKey.isEmpty) {
      throw GeminiError(GeminiErrorType.invalidApiKey, 'API key is not set');
    }

    final stopwatch = Stopwatch()..start();
    final textOnly = imagePaths.isEmpty;
    if (textOnly && (mealContext == null || mealContext.trim().isEmpty)) {
      throw GeminiError(GeminiErrorType.noFood, 'Nothing to analyze');
    }
    final leftoverParts = textOnly || leftoverPaths.isEmpty
        ? <Map<String, dynamic>>[]
        : await _prepareImageParts(leftoverPaths);
    final imageParts = [
      if (!textOnly) ...await _prepareImageParts(imagePaths),
      // Photos of what was left on the plate come after the meal, behind a
      // note that names them, so the answer counts only what was eaten.
      if (leftoverParts.isNotEmpty) ...[
        {'text': _leftoverNote(leftoverParts.length)},
        ...leftoverParts,
      ],
    ];
    final candidates = _orderedModelsForMode(
      await _getAvailableModels(),
      useAccurateMode: useAccurateMode,
    );
    final runs = useAccurateMode ? ensembleSize : 1;

    final controller = StreamController<AnalysisProgress>();
    final results = <Map<String, dynamic>>[];
    Object? firstError;
    var finished = 0;
    // Component names come from one run, so the analysis view tells one
    // story instead of three interleaved ones.
    int? storyRun;
    Timer? straggler;

    void close() {
      straggler?.cancel();
      if (!controller.isClosed) controller.close();
    }

    // The parallel estimates use Flash Lite only. If one of them fails, the
    // others still give the result, and a slow Flash stand-in would only
    // spend Flash's small daily quota and hold the meal up. Flash steps in
    // below when every estimate failed.
    final ensembleModels = runs > 1 ? candidates.take(1).toList() : candidates;
    for (var run = 0; run < runs; run++) {
      unawaited(() async {
        try {
          await for (final event in _runWithFallback(
            ensembleModels,
            imageParts,
            imageCount: imagePaths.length,
            leftovers: leftoverParts.isNotEmpty,
            useGrams: useGrams,
            mealContext: mealContext,
            useAccurateMode: useAccurateMode,
            allowEstimateVariation: allowEstimateVariation,
            previousAnalysis: previousAnalysis,
          )) {
            if (controller.isClosed) return;
            if (event is AnalysisResult) {
              final normalized = _normalizeAnalysisResult(
                event.data,
                subtractLeftovers: leftoverParts.isNotEmpty,
              );
              results.add(normalized);
              controller.add(
                EstimateReady(
                  results.length,
                  runs,
                  mealTotalCalories(normalized),
                ),
              );
            } else {
              storyRun ??= run;
              if (storyRun == run) controller.add(event);
            }
          }
        } catch (e) {
          AppLogger.warning('GeminiService', 'Estimate $run failed: $e');
          firstError ??= e;
        }
        finished++;
        if (finished == runs) {
          close();
        } else if (results.length >= 2 && straggler == null) {
          // Two estimates are enough for a result; a slow third one must
          // not hold up the meal for long.
          straggler = Timer(_stragglerWait, close);
        }
      }());
    }

    yield* controller.stream;

    final fallbackModels = candidates.skip(ensembleModels.length).toList();
    final ensembleError = firstError;
    if (results.isEmpty &&
        fallbackModels.isNotEmpty &&
        ensembleError is GeminiError &&
        _isRetryable(ensembleError)) {
      AppLogger.warning('GeminiService', 'All estimates failed, next model');
      try {
        await for (final event in _runWithFallback(
          fallbackModels,
          imageParts,
          imageCount: imagePaths.length,
          leftovers: leftoverParts.isNotEmpty,
          useGrams: useGrams,
          mealContext: mealContext,
          useAccurateMode: useAccurateMode,
          allowEstimateVariation: allowEstimateVariation,
          previousAnalysis: previousAnalysis,
        )) {
          if (event is AnalysisResult) {
            final normalized = _normalizeAnalysisResult(
              event.data,
              subtractLeftovers: leftoverParts.isNotEmpty,
            );
            results.add(normalized);
            yield EstimateReady(1, 1, mealTotalCalories(normalized));
          } else {
            yield event;
          }
        }
      } catch (e) {
        firstError = e;
      }
    }

    if (results.isEmpty) {
      final error = firstError;
      AppLogger.warning(
        'GeminiService',
        'Analysis failed after ${stopwatch.elapsedMilliseconds}ms: $error',
      );
      if (error is GeminiError) throw error;
      throw GeminiError(
        GeminiErrorType.unknown,
        'Analysis failed',
        technicalDetails: error?.toString(),
      );
    }
    AppLogger.info(
      'GeminiService',
      'analysis_complete runs=${results.length}/$runs '
          'latency_ms=${stopwatch.elapsedMilliseconds}',
    );
    yield AnalysisResult(medianEstimate(results));
  }

  /// How many estimates Accurate Mode runs.
  static const int ensembleSize = 3;

  /// The third estimate usually lands within two seconds of the second.
  static const Duration _stragglerWait = Duration(seconds: 2);

  /// One estimate: Flash Lite first. When it is rate limited, overloaded or
  /// gone, the next model takes over, so a busy Flash Lite still gives an
  /// answer.
  Stream<AnalysisProgress> _runWithFallback(
    List<String> candidates,
    List<Map<String, dynamic>> imageParts, {
    required int imageCount,
    bool leftovers = false,
    required bool useGrams,
    required String? mealContext,
    required bool useAccurateMode,
    required bool allowEstimateVariation,
    required Map<String, dynamic>? previousAnalysis,
  }) async* {
    final models = candidates.isNotEmpty
        ? candidates
        : const ['gemini-flash-lite-latest'];
    for (var i = 0; i < models.length; i++) {
      final model = models[i];
      try {
        // await for, not yield*: an error inside yield* goes straight to the
        // listener and never reaches this catch.
        await for (final event in _makeStreamRequest(
          model,
          imageParts,
          imageCount: imageCount,
          leftovers: leftovers,
          useGrams: useGrams,
          mealContext: mealContext,
          useAccurateMode: useAccurateMode,
          allowEstimateVariation: allowEstimateVariation,
          previousAnalysis: previousAnalysis,
        )) {
          yield event;
        }
        return;
      } catch (e) {
        final error = _mapError(e, model);
        final last = i == models.length - 1;
        if (last || !_isRetryable(error)) throw error;
        AppLogger.warning('GeminiService', '$model failed, next model: $e');
      }
    }
  }

  /// Whether another model may succeed where this one failed.
  static bool _isRetryable(GeminiError error) =>
      error.type == GeminiErrorType.rateLimited ||
      RegExp(r'HTTP (404|500|503)').hasMatch(error.technicalDetails ?? '');

  /// Turns a request failure into a [GeminiError] and rests the model when
  /// it is out of quota or gone.
  GeminiError _mapError(Object e, String model) {
    if (e is GeminiError) return e;
    final errorText = e.toString();
    if (e is TimeoutException) {
      return GeminiError(
        GeminiErrorType.timedOut,
        'Gemini did not answer in time',
        technicalDetails: errorText,
      );
    }
    if (errorText.contains('HTTP 429')) {
      // A spent daily quota comes back after Google's reset at midnight
      // Pacific time; a per-minute limit after a short pause.
      _coolDownModel(
        model,
        errorText.contains('PerDay')
            ? _untilQuotaReset(DateTime.now().toUtc())
            : const Duration(seconds: 30),
      );
      return GeminiError(
        GeminiErrorType.rateLimited,
        'Gemini rate limit reached. Please retry shortly.',
        technicalDetails: errorText,
      );
    }
    if (errorText.contains('HTTP 401') || errorText.contains('HTTP 403')) {
      return GeminiError(
        GeminiErrorType.invalidApiKey,
        'Gemini refused the API key',
        technicalDetails: errorText,
      );
    }
    // The browser's fetch fails with these when there is no connection.
    if (e is http.ClientException ||
        RegExp(
          r'Failed to fetch|Load failed|NetworkError',
        ).hasMatch(errorText)) {
      return GeminiError(
        GeminiErrorType.networkError,
        'No connection to Gemini',
        technicalDetails: errorText,
      );
    }
    if (errorText.contains('HTTP 404')) {
      _coolDownModel(model, const Duration(minutes: 10));
    }
    return GeminiError(
      GeminiErrorType.unknown,
      'Gemini request failed',
      technicalDetails: errorText,
    );
  }

  /// Time until 08:00 UTC, which is midnight Pacific time in winter and one
  /// hour after it in summer, so the quota is always back by then.
  static Duration _untilQuotaReset(DateTime nowUtc) {
    var reset = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 8);
    if (!reset.isAfter(nowUtc)) reset = reset.add(const Duration(days: 1));
    return reset.difference(nowUtc);
  }

  Future<List<Map<String, dynamic>>> _prepareImageParts(
    List<String> imagePaths,
  ) async {
    final preparedPerImage = await Future.wait(
      imagePaths.map((path) async {
        try {
          final bytes = await PhotoStore.instance.read(path);
          if (bytes == null || bytes.isEmpty) return <Map<String, dynamic>>[];

          final browserJpeg = await downscaleForAnalysis(
            bytes,
            _analysisMaxDimension,
          );
          final prepared = browserJpeg != null
              ? {'data': base64Encode(browserJpeg), 'mimeType': 'image/jpeg'}
              : await compute<Map<String, dynamic>, Map<String, String>>(
                  _prepareImageInIsolate,
                  {
                    'bytes': bytes,
                    'maxDimension': _analysisMaxDimension,
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

  /// Performs one compact structured streaming request. It yields the
  /// component names as the answer names them, then the structured result.
  Stream<AnalysisProgress> _makeStreamRequest(
    String modelName,
    List<Map<String, dynamic>> imageParts, {
    required int imageCount,
    bool leftovers = false,
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
        'maxOutputTokens': useAccurateMode ? 6144 : 4096,
        'thinkingConfig': {
          'thinkingLevel': thinkingLevel,
          // The app shows no thought summaries; leaving them out saves
          // their generation time.
          'includeThoughts': false,
        },
        'responseMimeType': 'application/json',
        'responseSchema': _analysisResponseSchema(leftovers: leftovers),
      },
    };

    // The key travels in a header, never in the URL: URLs end up in browser
    // history, proxies and logs.
    final url = '$_baseUrlBase/$modelName:streamGenerateContent?alt=sse';
    // Streaming lets the analysis view show the components while the answer
    // is written. The timeout bounds each wait for the next chunk; a whole
    // analysis with several photos often takes longer than one such wait.
    final timeout = useAccurateMode
        ? const Duration(seconds: 45)
        : const Duration(seconds: 30);

    final requestHeaders = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    Future<Stream<String>> sendRequest(Map<String, dynamic> payload) async {
      final body = jsonEncode(payload);
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
    var namesSeen = 0;

    void processSseEvent(String event) {
      for (final line in event.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        sawSse = true;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          _appendCandidateText(jsonDecode(data), answerBuffer);
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
      events.forEach(processSseEvent);
      final names = _streamedItemNames(answerBuffer.toString());
      if (names.length > namesSeen) {
        namesSeen = names.length;
        yield ComponentsSeen(names);
      }
    }
    if (sseBuffer.isNotEmpty) processSseEvent(sseBuffer.toString());

    if (!sawSse && answerBuffer.isEmpty) {
      final rawResponse = rawResponseBuffer.toString().trim();
      if (rawResponse.isNotEmpty) {
        final decoded = jsonDecode(rawResponse);
        if (decoded is Map && decoded.containsKey('candidates')) {
          _appendCandidateText(decoded, answerBuffer);
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

  /// Item names in a JSON answer that is still arriving: a name counts once
  /// its closing quote is there.
  static List<String> _streamedItemNames(String partialJson) => [
    for (final match in RegExp(
      r'"name"\s*:\s*"((?:[^"\\]|\\.)*)"',
    ).allMatches(partialJson))
      _unescapeJsonString(match.group(1)!),
  ];

  static String _unescapeJsonString(String raw) {
    try {
      return jsonDecode('"$raw"') as String;
    } catch (_) {
      return raw;
    }
  }

  /// Appends the answer text of a response chunk. Thought parts are left
  /// out: the app does not show them.
  void _appendCandidateText(dynamic value, StringBuffer output) {
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
        if (part['thought'] != true) output.write(text);
      }
    }
  }

  String _leftoverNote(int count) =>
      'LEFTOVERS. The next $count photo(s), after this note, were taken after '
      'the meal: they show what was left on the plate and was not eaten. They '
      'are not another angle of the meal and do not count in the photo count. '
      'List the items as served in the meal photos, with grams, grams_min and '
      'grams_max for the served amount, as usual. For each item, left_grams '
      'is how much of it is still on the plate in the leftover photos, 0 when '
      'none is left. Do not subtract anything yourself: the app subtracts '
      'left_grams from grams. Name the meal after what was eaten and say in '
      'uncertainty_note that leftovers were subtracted.';

  String _analysisContextNote(int imageCount) {
    if (imageCount == 0) {
      return 'No photo. The meal is described only in the user note. Estimate it from that description; use the quantity stated there, otherwise a typical single serving. If the note describes neither food nor drink, return calories 0 and an empty items list.';
    }
    return 'Photo count: $imageCount. Decide whether photos are the same meal from different angles or separate meals to sum; never double-count duplicate angles.';
  }

  Map<String, dynamic> _analysisResponseSchema({bool leftovers = false}) => {
    'type': 'OBJECT',
    'properties': {
      'meal_name': {'type': 'STRING'},
      'uncertainty_note': {'type': 'STRING'},
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
            // A key of the reference list in the prompt, or "other". Not an
            // enum: Gemini rejects enums this long.
            'ref': {'type': 'STRING'},
            'grams': {'type': 'NUMBER'},
            'grams_min': {'type': 'NUMBER'},
            'grams_max': {'type': 'NUMBER'},
            // With leftover photos: how much of the item is still on the
            // plate. The app subtracts it, so the model never has to.
            if (leftovers) 'left_grams': {'type': 'NUMBER'},
            'kcal_per_100g': {'type': 'NUMBER'},
            'protein_per_100g': {'type': 'NUMBER'},
            'carbs_per_100g': {'type': 'NUMBER'},
            'fats_per_100g': {'type': 'NUMBER'},
            'confidence': {'type': 'NUMBER'},
            'assumption': {'type': 'STRING'},
          },
          'required': [
            'name',
            'ref',
            'grams',
            'grams_min',
            'grams_max',
            if (leftovers) 'left_grams',
            'kcal_per_100g',
            'protein_per_100g',
            'carbs_per_100g',
            'fats_per_100g',
            'confidence',
            'assumption',
          ],
        },
      },
      // Only for a photo without food: then items is empty and these are 0.
      'calories': {'type': 'NUMBER'},
      'protein': {'type': 'NUMBER'},
      'carbs': {'type': 'NUMBER'},
      'fats': {'type': 'NUMBER'},
    },
    'required': [
      'meal_name',
      'uncertainty_note',
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

  /// Per-100-g values for an item: the USDA reference when the model named
  /// one, else the model's own values with their kcal made to agree with
  /// the macros (4/4/9 kcal per gram of protein/carbs/fat).
  Map<String, double>? _itemDensity(Map raw) {
    final reference = referenceFoods[raw['ref']?.toString()];
    if (reference != null) {
      return {
        'kcal': reference.kcal,
        'protein': reference.protein,
        'carbs': reference.carbs,
        'fats': reference.fats,
      };
    }
    final protein = _finiteNonNegative(raw['protein_per_100g']);
    final carbs = _finiteNonNegative(raw['carbs_per_100g']);
    final fats = _finiteNonNegative(raw['fats_per_100g']);
    final kcal = _finiteNonNegative(raw['kcal_per_100g']);
    if (protein == null || carbs == null || fats == null || kcal == null) {
      return null;
    }
    return {
      'kcal': atwaterConsistentKcal(
        kcal,
        protein: protein,
        carbs: carbs,
        fats: fats,
        liquid: RegExp(
          r'beer|bier|wine|wein|cocktail|spritz|schnaps|liq',
          caseSensitive: false,
        ).hasMatch(raw['name']?.toString() ?? ''),
      ),
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  /// With [subtractLeftovers], an item's grams are what was served and
  /// left_grams what is still on the plate: the item becomes what was eaten,
  /// and an item left completely is dropped.
  List<Map<String, dynamic>> _normalizeItems(
    dynamic rawItems, {
    bool subtractLeftovers = false,
  }) {
    if (rawItems is! List) return <Map<String, dynamic>>[];

    const macroKeys = ['calories', 'protein', 'carbs', 'fats'];
    final normalized = <Map<String, dynamic>>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final name = decodeHtmlEntities(raw['name']?.toString().trim() ?? '');
      if (name.isEmpty) continue;
      if (normalized.length >= 20) break;

      final item = <String, dynamic>{
        'name': name,
        'confidence': (_finiteNonNegative(raw['confidence']) ?? 0.5).clamp(
          0.0,
          1.0,
        ),
        'assumption': decodeHtmlEntities(
          raw['assumption']?.toString().trim() ?? '',
        ),
      };

      final served = _finiteNonNegative(raw['grams']);
      final left = subtractLeftovers
          ? (_finiteNonNegative(raw['left_grams']) ?? 0)
          : 0.0;
      if (served != null) {
        final grams = served - left;
        if (left > 0 && grams < 1) continue;
        // Grams times per-100-g values: the app does the arithmetic, so
        // every total matches its parts.
        final density = _itemDensity(raw);
        if (density == null) continue;
        final low = math.max(
          0.0,
          (_finiteNonNegative(raw['grams_min']) ?? served) - left,
        );
        final high = (_finiteNonNegative(raw['grams_max']) ?? served) - left;
        final ref = raw['ref']?.toString();
        item
          ..['grams'] = grams
          ..['ref'] = referenceFoods.containsKey(ref) ? ref : null
          ..['kcal_per_100g'] = density['kcal']
          ..['protein_per_100g'] = density['protein']
          ..['carbs_per_100g'] = density['carbs']
          ..['fats_per_100g'] = density['fats']
          ..['calories'] = density['kcal']! * grams / 100
          ..['protein'] = density['protein']! * grams / 100
          ..['carbs'] = density['carbs']! * grams / 100
          ..['fats'] = density['fats']! * grams / 100
          ..['calories_min'] =
              density['kcal']! * (low < grams ? low : grams) / 100
          ..['calories_max'] =
              density['kcal']! * (high > grams ? high : grams) / 100;
        normalized.add(item);
        continue;
      }

      // Older answers (and retries of them) carry item totals instead.
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

  Map<String, dynamic> _normalizeAnalysisResult(
    Map<String, dynamic> result, {
    bool subtractLeftovers = false,
  }) {
    final normalized = Map<String, dynamic>.from(result);
    final detectedPortion = normalizeDetectedPortion(normalized);
    normalized['detected_unit'] = detectedPortion.unit;
    normalized['detected_quantity'] = detectedPortion.quantity;

    final items = _normalizeItems(
      normalized['items'],
      subtractLeftovers: subtractLeftovers,
    );
    normalized['items'] = items;
    var portion = detectedPortion;
    if (portion.unit != portionUnitServing &&
        items.isNotEmpty &&
        items.every((item) => item['grams'] is num)) {
      // Weighed mode: the amount is what the items add up to.
      final total = items.fold<double>(
        0,
        (sum, item) => sum + (item['grams'] as num).toDouble(),
      );
      if (total > 0) {
        portion = NormalizedPortion(unit: portion.unit, quantity: total);
        normalized['detected_quantity'] = total;
      }
    }
    _aggregateItemNutrition(normalized, items, portion);

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
    for (final key in const ['meal_name', 'uncertainty_note']) {
      normalized[key] = decodeHtmlEntities(normalized[key]?.toString() ?? '');
    }
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

  Future<ApiKeyStatus> validateApiKey(String key) async {
    if (key.isEmpty) return ApiKeyStatus.invalid;

    try {
      final response = await _client
          .get(
            Uri.parse(_baseUrlBase),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
          )
          .timeout(const Duration(seconds: 15));
      final status = response.statusCode;
      if (status == 200) return ApiKeyStatus.valid;
      // Google answers 400 for a malformed or unknown key, 401/403 for a key
      // that is rejected. Anything else (429, 5xx) is not about the key.
      if (status == 400 || status == 401 || status == 403) {
        return ApiKeyStatus.invalid;
      }
      return ApiKeyStatus.unreachable;
    } catch (_) {
      return ApiKeyStatus.unreachable;
    }
  }

  String _getPrompt(
    String language, {
    bool useGrams = false,
    bool allowEstimateVariation = false,
  }) {
    final outputLanguage = language == 'de' ? 'German' : 'English';
    final unitRule = useGrams
        ? 'detected_unit: gram for food, ml for a drink on its own. detected_quantity is the total amount.'
        : 'detected_unit: serving. detected_quantity is the number of servings in the photo, usually 1. Only a visible label may force gram or ml.';
    final retryRule = allowEstimateVariation
        ? '\nThe user asked for a new estimate, so the previous one (given below) looked wrong to them. Re-check each component, its grams and its hidden fat, and correct what is most likely wrong; do not just repeat it.'
        : '';
    return '''You estimate the nutrition of a meal for a calorie tracker. Answer only with one JSON object matching the schema.

Method:
1. Components: list every component on its own: each meat or fish, side, vegetable, sauce, dressing, topping, spread, drink, and the cooking fat. Several photos of the same plate from different angles show one meal; count it once. Genuinely different meals are summed.
2. Grams: estimate the edible grams of each component as served. Use scale cues: dinner plate about 27 cm across, side plate 20 cm, bowl 15 cm, fork 19 cm, glass 250 ml, can 330 ml, hands, packaging. Judge height and density, not only the area seen from above: piled rice, meat and pasta weigh more than they look. A full plate of a main meal is usually 400 to 700 g. grams_min and grams_max give the plausible range.
3. Nutrition per 100 g: set ref to the matching key from the reference list below when the component is that food (the app then uses USDA values for it); use "other" otherwise. Always also fill kcal/protein/carbs/fats_per_100g with values for the food as served.
4. Hidden fat: reference foods are plain, without added fat. Anything roasted, pan-fried, sautéed, grilled, glazed or stir-fried was cooked with fat: add it as its own item with ref oil or butter, about 5 to 10 g per 100 g of roasted or sautéed vegetables or potatoes, and 4 to 8 g per 100 g of pan-fried meat or fish. Breaded or deep-fried foods: use a breaded or fried reference instead of extra oil. A salad that looks glossy, or has dressing on it, gets a dressing item (usually 20 to 40 g). Restaurant, canteen and takeaway food uses more fat than home cooking. Leave out cooking fat only for food that is clearly raw, steamed or boiled.
5. Brands and chains: when packaging, a logo, a menu or the user note shows a branded product or a restaurant chain item, set ref to "other" and give that product's published per-100-g nutrition and weight (European version unless the note says otherwise); say so in assumption. The reference list is for generic foods only.
6. A visible nutrition label or the user note beats a visual guess.
7. Be unbiased: give the most likely amount, not a cautious low one. Calorie trackers tend to underestimate portions and fat.
$unitRule$retryRule

meal_name and item names in $outputLanguage. assumption: a few words on what is uncertain about that item, in $outputLanguage. uncertainty_note: the main uncertainty of the whole meal, at most 200 characters, in $outputLanguage. confidence_score and confidence are 0 to 1. If the photo shows no food or drink, return an empty items list and calories 0.

Reference list (USDA, per 100 g as eaten): ${referenceFoods.keys.join(', ')}''';
  }
}
