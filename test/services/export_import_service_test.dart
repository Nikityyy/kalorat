import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/services/database_service.dart';
import 'package:kalorat/services/export_import_service.dart';
import 'package:kalorat/l10n/app_localizations_en.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockDatabaseService extends Fake implements DatabaseService {
  UserModel? user;
  List<MealModel> meals = [];

  @override
  UserModel? getUser() => user;

  @override
  List<MealModel> getAllMeals() => meals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();

  test('ExportImportService generates correctly formatted and ordered markdown report', () async {
    final mockDb = MockDatabaseService();
    final service = ExportImportService(mockDb);
    final l10n = AppLocalizationsEn();

    mockDb.user = UserModel(
      name: 'Test',
      height: 180,
      weight: 75,
      goal: 1, // maintain
      gender: 0, // male
      birthdate: DateTime(1995, 1, 1),
    );

    mockDb.meals = [
      MealModel(
        id: '1',
        mealName: 'Dinner',
        calories: 800,
        protein: 50,
        carbs: 70,
        fats: 20,
        timestamp: DateTime(2026, 8, 20, 19, 30),
        photoPaths: [],
      ),
      MealModel(
        id: '2',
        mealName: 'Breakfast',
        calories: 400,
        protein: 30,
        carbs: 40,
        fats: 10,
        timestamp: DateTime(2026, 8, 20, 8, 0),
        photoPaths: [],
      ),
      MealModel(
        id: '3',
        mealName: 'Yesterday Lunch',
        calories: 600,
        protein: 40,
        carbs: 50,
        fats: 15,
        timestamp: DateTime(2026, 8, 19, 12, 0),
        photoPaths: [],
      ),
    ];

    final path = await service.exportMarkdownReport(l10n);
    expect(path, isNotNull);

    final file = File(path!);
    expect(await file.exists(), isTrue);

    final content = await file.readAsString();
    expect(content, contains('# Kalorat - Nutrition Report'));
    expect(content, contains('### 2026-08-19'));
    expect(content, contains('### 2026-08-20'));
    
    // Check that 2026-08-19 appears BEFORE 2026-08-20 in the content
    final idx19 = content.indexOf('### 2026-08-19');
    final idx20 = content.indexOf('### 2026-08-20');
    expect(idx19 < idx20, isTrue);

    // Check that Breakfast appears BEFORE Dinner for 2026-08-20
    final idxBreakfast = content.indexOf('[08:00] Breakfast');
    final idxDinner = content.indexOf('[19:30] Dinner');
    expect(idxBreakfast < idxDinner, isTrue);

    // Check macros math
    expect(content, contains('**Daily Total:** 1200 kcal | P: 80.0g | C: 110.0g | F: 30.0g'));
  });
}
