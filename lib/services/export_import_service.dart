import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_service.dart';
import '../models/models.dart';

// Conditional imports for web vs mobile
import 'export_import_web.dart' if (dart.library.io) 'export_import_native.dart';

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
      sb.writeln('${l10n.reportGeneratedOn}: ${DateTime.now().toIso8601String().split('T').first}');
      sb.writeln();

      if (user != null) {
        sb.writeln('## ${l10n.reportUserProfile}');
        sb.writeln('- **${l10n.reportGoal}:** ${user.goal.name}');
        sb.writeln('- **${l10n.reportActivityLevel}:** ${user.activityLevel.name}');
        sb.writeln('- **${l10n.reportDailyCalories}:** ${user.dailyCalorieTarget.round()} kcal');
        sb.writeln('- **${l10n.reportDailyProtein}:** ${user.dailyProteinTarget.toStringAsFixed(1)} g');
        sb.writeln('- **${l10n.reportDailyCarbs}:** ${user.dailyCarbTarget.toStringAsFixed(1)} g');
        sb.writeln('- **${l10n.reportDailyFats}:** ${user.dailyFatTarget.toStringAsFixed(1)} g');
        sb.writeln();
      }

      sb.writeln('## ${l10n.reportMealsLog}');
      sb.writeln();

      if (meals.isEmpty) {
        sb.writeln('${l10n.reportNoMeals}');
      } else {
        // Group meals by date (YYYY-MM-DD)
        final Map<String, List<MealModel>> mealsByDate = {};
        for (final meal in meals) {
          // Adjust for user dayStartHour
          final adjusted = meal.timestamp.subtract(Duration(hours: user?.dayStartHour ?? 0));
          final dateStr = '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
          mealsByDate.putIfAbsent(dateStr, () => []).add(meal);
        }

        // Sort dates ascending (oldest first)
        final sortedDates = mealsByDate.keys.toList()..sort();

        for (final date in sortedDates) {
          // Sort daily meals chronologically (oldest meal first)
          final dailyMeals = mealsByDate[date]!..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          double dailyCals = 0;
          double dailyProtein = 0;
          double dailyCarbs = 0;
          double dailyFats = 0;

          for (final m in dailyMeals) {
            dailyCals += m.calories;
            dailyProtein += m.protein;
            dailyCarbs += m.carbs;
            dailyFats += m.fats;
          }

          sb.writeln('### $date');
          sb.writeln('**${l10n.reportDailyTotal}:** ${dailyCals.round()} kcal | P: ${dailyProtein.toStringAsFixed(1)}g | C: ${dailyCarbs.toStringAsFixed(1)}g | F: ${dailyFats.toStringAsFixed(1)}g');
          sb.writeln();

          for (final m in dailyMeals) {
            final timeStr = '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';
            sb.writeln('- **[$timeStr] ${m.mealName.isEmpty ? l10n.reportUnnamedMeal : m.mealName}**');
            sb.writeln('  - ${m.calories.round()} kcal | P: ${m.protein.toStringAsFixed(1)}g | C: ${m.carbs.toStringAsFixed(1)}g | F: ${m.fats.toStringAsFixed(1)}g');
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
