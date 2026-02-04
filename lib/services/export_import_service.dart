import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class ExportImportService {
  final DatabaseService _databaseService;

  ExportImportService(this._databaseService);

  Future<String?> exportData() async {
    try {
      final data = _databaseService.exportAll();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'kalorat_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate data structure
      if (!_validateImportData(data)) {
        throw Exception('Invalid data format');
      }

      await _databaseService.importAll(data);
      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  bool _validateImportData(Map<String, dynamic> data) {
    // Check for required fields
    if (!data.containsKey('version')) return false;

    // User is optional but must be valid if present
    if (data['user'] != null && data['user'] is! Map) return false;

    // Meals must be a list if present
    if (data['meals'] != null && data['meals'] is! List) return false;

    // Weights must be a list if present
    if (data['weights'] != null && data['weights'] is! List) return false;

    return true;
  }
}
