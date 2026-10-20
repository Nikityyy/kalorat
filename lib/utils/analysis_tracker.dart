import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/gemini_service.dart';
import 'analysis_parser.dart';

/// Where an analysis is, as far as the app can tell from the stream.
enum AnalysisStage { reading, components, estimates, done }

/// A component named so far; [grams] is known once the analysis is done.
class TrackedComponent {
  final String name;
  final double? grams;
  const TrackedComponent(this.name, [this.grams]);
}

/// Follows an analysis stream for the analysing view: the stage, the
/// components the answer has named, the estimates that are in, and in the
/// end the calories. Only real events move it on; the view eases its
/// progress line between them.
class AnalysisTracker extends ChangeNotifier {
  /// How long the finished number stays on screen before the result opens.
  static const finishHold = Duration(milliseconds: 900);

  AnalysisStage _stage = AnalysisStage.reading;
  List<TrackedComponent> _components = const [];
  final List<double> _estimates = [];
  int _total = 1;
  double? _calories;
  bool _textOnly = false;
  String? _description;
  int _stageSerial = 0;

  AnalysisStage get stage => _stage;
  List<TrackedComponent> get components => _components;
  List<double> get estimates => List.unmodifiable(_estimates);

  /// How many estimates run in parallel.
  int get total => _total;

  /// The meal's calories once done.
  double? get calories => _calories;
  bool get textOnly => _textOnly;

  /// What was typed for a meal analysed from words alone.
  String? get description => _description;

  /// Changes every time the stage does, so the view can time its easing.
  int get stageSerial => _stageSerial;

  void start({
    required int estimates,
    required bool hasPhoto,
    String? description,
  }) {
    _stage = AnalysisStage.reading;
    _components = const [];
    _estimates.clear();
    _total = estimates < 1 ? 1 : estimates;
    _calories = null;
    _description = description?.trim();
    _textOnly = !hasPhoto;
    _stageSerial++;
    notifyListeners();
  }

  void _moveTo(AnalysisStage stage) {
    if (stage.index > _stage.index) {
      _stage = stage;
      _stageSerial++;
    }
  }

  void handle(AnalysisProgress event) {
    switch (event) {
      case ComponentsSeen(:final names):
        if (names.length <= _components.length ||
            _stage.index > AnalysisStage.components.index) {
          return;
        }
        _components = [for (final name in names) TrackedComponent(name)];
        _moveTo(AnalysisStage.components);
      case EstimateReady(:final calories, :final total):
        _total = total;
        _estimates.add(calories);
        _moveTo(AnalysisStage.estimates);
        _stageSerial++;
      case AnalysisResult():
        return;
    }
    notifyListeners();
  }

  /// Shows the result's calories and components with their amounts, then
  /// waits [finishHold] so the number can land before the result opens.
  Future<void> finish(Map<String, dynamic> result) {
    final parsed = parseAnalysisResult(result);
    _calories = parsed.calories * parsed.multiplier;
    final items = parsed.components;
    if (items != null) {
      _components = [
        for (final c in items)
          TrackedComponent(c.name, c.grams * parsed.multiplier),
      ];
    }
    _moveTo(AnalysisStage.done);
    notifyListeners();
    return Future<void>.delayed(finishHold);
  }
}
