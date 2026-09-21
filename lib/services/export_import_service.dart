import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_service.dart';
import '../models/models.dart';

// Conditional imports for web vs mobile
import 'export_import_web.dart'
    if (dart.library.io) 'export_import_native.dart';

class ExportImportService {
  final DatabaseService _databaseService;

  ExportImportService(this._databaseService);

  Future<String?> exportData() async {
    try {
      final data = _databaseService.exportAll();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final fileName =
          'kalorat_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

      if (kIsWeb) {
        // On web: trigger a browser download directly
        triggerWebDownload(jsonString, fileName);
        return 'web_download'; // Non-null means success
      } else {
        return await writeNativeFile(jsonString, fileName);
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> exportMarkdownReport(dynamic l10n) async {
    try {
      final user = _databaseService.getUser();
      final meals = _databaseService.getAllMeals();

      final sb = StringBuffer();

      sb.writeln('# ${l10n.reportTitle}');
      sb.writeln(
        '${l10n.reportGeneratedOn}: ${DateTime.now().toIso8601String().split('T').first}',
      );
      sb.writeln();

      if (user != null) {
        sb.writeln('## ${l10n.reportUserProfile}');
        sb.writeln('- **${l10n.reportGoal}:** ${user.goal.name}');
        sb.writeln(
          '- **${l10n.reportActivityLevel}:** ${user.activityLevel.name}',
        );
        sb.writeln(
          '- **${l10n.reportDailyCalories}:** ${user.dailyCalorieTarget.round()} kcal',
        );
        sb.writeln(
          '- **${l10n.reportDailyProtein}:** ${user.dailyProteinTarget.toStringAsFixed(1)} g',
        );
        sb.writeln(
          '- **${l10n.reportDailyCarbs}:** ${user.dailyCarbTarget.toStringAsFixed(1)} g',
        );
        sb.writeln(
          '- **${l10n.reportDailyFats}:** ${user.dailyFatTarget.toStringAsFixed(1)} g',
        );
        sb.writeln();
      }

      sb.writeln('## ${l10n.reportDailyLog}');
      sb.writeln();

      // Group meals by date using the user's configured day boundary.
      final Map<String, List<MealModel>> mealsByDate = {};
      for (final meal in meals) {
        final adjusted = meal.timestamp.subtract(
          Duration(hours: user?.dayStartHour ?? 0),
        );
        final dateStr =
            '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
        mealsByDate.putIfAbsent(dateStr, () => []).add(meal);
      }

      // Weights belong to their actual calendar date; unlike meals, they are
      // not shifted by the user's day-start setting.
      final Map<String, List<WeightModel>> weightsByDate = {};
      for (final weight in _databaseService.getAllWeights()) {
        final dateStr =
            '${weight.date.year}-${weight.date.month.toString().padLeft(2, '0')}-${weight.date.day.toString().padLeft(2, '0')}';
        weightsByDate.putIfAbsent(dateStr, () => []).add(weight);
      }

      final dates = <String>{
        ...mealsByDate.keys,
        ...weightsByDate.keys,
      }.toList()..sort();

      if (dates.isEmpty) {
        sb.writeln('${l10n.reportNoMeals}');
      } else {
        for (final date in dates) {
          final dailyMeals = mealsByDate[date]
            ?..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final dailyWeights = weightsByDate[date]
            ?..sort((a, b) => a.date.compareTo(b.date));

          sb.writeln('### $date');

          if (dailyWeights != null && dailyWeights.isNotEmpty) {
            for (final weight in dailyWeights) {
              sb.writeln(
                '**${l10n.reportWeight}:** ${weight.weight.toStringAsFixed(1)} kg',
              );
            }
          }

          if (dailyMeals == null || dailyMeals.isEmpty) {
            sb.writeln('${l10n.reportNoMeals}');
            sb.writeln();
            continue;
          }

          double dailyCals = 0;
          double dailyProtein = 0;
          double dailyCarbs = 0;
          double dailyFats = 0;

          for (final meal in dailyMeals) {
            dailyCals += meal.calories;
            dailyProtein += meal.protein;
            dailyCarbs += meal.carbs;
            dailyFats += meal.fats;
          }

          sb.writeln(
            '**${l10n.reportDailyTotal}:** ${dailyCals.round()} kcal | P: ${dailyProtein.toStringAsFixed(1)}g | C: ${dailyCarbs.toStringAsFixed(1)}g | F: ${dailyFats.toStringAsFixed(1)}g',
          );
          sb.writeln();

          for (final meal in dailyMeals) {
            final timeStr =
                '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';
            sb.writeln(
              '- **[$timeStr] ${meal.mealName.isEmpty ? l10n.reportUnnamedMeal : meal.mealName}**',
            );
            sb.writeln(
              '  - ${meal.calories.round()} kcal | P: ${meal.protein.toStringAsFixed(1)}g | C: ${meal.carbs.toStringAsFixed(1)}g | F: ${meal.fats.toStringAsFixed(1)}g',
            );
          }
          sb.writeln();
        }
      }

      final fileName =
          'kalorat_report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.md';

      if (kIsWeb) {
        triggerWebDownload(sb.toString(), fileName);
        return 'web_download';
      } else {
        return await writeNativeFile(sb.toString(), fileName);
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb, // On web, read bytes directly
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      String jsonString;
      if (kIsWeb) {
        // On web, use bytes from the result
        final bytes = result.files.single.bytes;
        if (bytes == null) return false;
        jsonString = utf8.decode(bytes);
      } else {
        jsonString = await readNativeFile(result.files.single.path!);
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate data structure
      if (!_validateImportData(data)) {
        throw Exception('Invalid data format');
      }

      await _databaseService.importAll(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _validateImportData(Map<String, dynamic> data) {
    if (!data.containsKey('version')) return false;
    if (data['user'] != null && data['user'] is! Map) return false;
    if (data['meals'] != null && data['meals'] is! List) return false;
    if (data['weights'] != null && data['weights'] is! List) return false;
    return true;
  }
}
