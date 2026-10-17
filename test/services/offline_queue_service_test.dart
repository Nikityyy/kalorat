import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/services/database_service.dart';
import 'package:kalorat/services/gemini_service.dart';
import 'package:kalorat/services/offline_queue_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockGeminiService extends Mock implements GeminiService {}

class _QueueDatabase extends DatabaseService {
  MealModel? meal;

  @override
  List<MealModel> getPendingMeals() => meal?.isPending == true ? [meal!] : [];

  @override
  MealModel? getMealById(String mealId) => meal?.id == mealId ? meal : null;

  @override
  bool hasMeal(String mealId) => meal?.id == mealId;

  @override
  Future<MealModel> saveMeal(MealModel meal) async {
    this.meal = meal;
    return meal;
  }
}

void main() {
  test('offline queue replaces a pending meal with analyzed data', () async {
    final database = _QueueDatabase()
      ..meal = MealModel(
        id: 'pending',
        timestamp: DateTime(2026, 7, 10),
        photoPaths: const ['photo'],
        isPending: true,
      );
    final gemini = _MockGeminiService();
    when(
      () => gemini.analyzeMealStream(
        any(),
        useGrams: any(named: 'useGrams'),
        useAccurateMode: any(named: 'useAccurateMode'),
        mealContext: any(named: 'mealContext'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        const AnalysisResult({
          'meal_name': 'Soup',
          'calories': 120,
          'protein': 5,
          'carbs': 18,
          'fats': 3,
          'detected_quantity': 1,
          'detected_unit': 'serving',
        }),
      ),
    );
    final queue = OfflineQueueService(
      database,
      onlineCheck: () async => true,
      geminiFactory: (_, _) => gemini,
    );

    await queue.processQueue('key', 'en');

    expect(database.meal?.isPending, isFalse);
    expect(database.meal?.mealName, 'Soup');
    expect(database.meal?.calories, 120);
  });

  test('offline queue skips a meal claimed by a foreground analysis', () async {
    final database = _QueueDatabase()
      ..meal = MealModel(
        id: 'foreground',
        timestamp: DateTime(2026, 7, 10),
        photoPaths: const ['photo'],
        isPending: true,
        analysisStatus: 'queued',
      );
    final gemini = _MockGeminiService();
    when(
      () => gemini.analyzeMealStream(
        any(),
        useGrams: any(named: 'useGrams'),
        useAccurateMode: any(named: 'useAccurateMode'),
        mealContext: any(named: 'mealContext'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        const AnalysisResult({'meal_name': 'Soup', 'calories': 120}),
      ),
    );
    final queue = OfflineQueueService(
      database,
      onlineCheck: () async => true,
      geminiFactory: (_, _) => gemini,
    );

    expect(OfflineQueueService.claim('foreground'), isTrue);
    expect(OfflineQueueService.claim('foreground'), isFalse);
    await queue
        .processQueue('key', 'en')
        .timeout(const Duration(seconds: 2)); // must not spin
    verifyNever(
      () => gemini.analyzeMealStream(
        any(),
        useGrams: any(named: 'useGrams'),
        useAccurateMode: any(named: 'useAccurateMode'),
        mealContext: any(named: 'mealContext'),
      ),
    );
    expect(database.meal?.isPending, isTrue);

    // If the app closed mid-analysis, the next run still analyzes the meal.
    OfflineQueueService.release('foreground');
    await queue.processQueue('key', 'en');
    expect(database.meal?.mealName, 'Soup');
  });
}
