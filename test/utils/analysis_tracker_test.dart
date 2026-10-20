import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/gemini_service.dart';
import 'package:kalorat/utils/analysis_tracker.dart';

void main() {
  test('moves through the stages on real events only', () {
    final tracker = AnalysisTracker()..start(estimates: 3, hasPhoto: true);
    expect(tracker.stage, AnalysisStage.reading);

    tracker.handle(const ComponentsSeen(['Reis']));
    tracker.handle(const ComponentsSeen(['Reis', 'Brokkoli']));
    expect(tracker.stage, AnalysisStage.components);
    expect(tracker.components.map((c) => c.name), ['Reis', 'Brokkoli']);

    // Fewer names later on do not move it back.
    tracker.handle(const ComponentsSeen(['Reis']));
    expect(tracker.components, hasLength(2));

    tracker.handle(const EstimateReady(1, 3, 640));
    tracker.handle(const EstimateReady(2, 3, 700));
    expect(tracker.stage, AnalysisStage.estimates);
    expect(tracker.estimates, [640, 700]);
    expect(tracker.total, 3);
  });

  test('finish shows the calories and the amounts', () async {
    final tracker = AnalysisTracker()..start(estimates: 1, hasPhoto: true);
    await tracker.finish({
      'meal_name': 'Reis',
      'calories': 260,
      'protein': 5,
      'carbs': 56,
      'fats': 1,
      'detected_quantity': 1,
      'detected_unit': 'serving',
      'items': [
        {
          'name': 'Reis',
          'grams': 200,
          'kcal_per_100g': 130,
          'protein_per_100g': 2.7,
          'carbs_per_100g': 28,
          'fats_per_100g': 0.3,
        },
      ],
    });
    expect(tracker.stage, AnalysisStage.done);
    expect(tracker.calories, closeTo(260, 0.5));
    expect(tracker.components.single.grams, closeTo(200, 0.01));
  });

  test('a meal without a photo is told by its description', () {
    final tracker = AnalysisTracker()
      ..start(estimates: 1, hasPhoto: false, description: ' Zwei Brote ');
    expect(tracker.textOnly, isTrue);
    expect(tracker.description, 'Zwei Brote');
  });
}
