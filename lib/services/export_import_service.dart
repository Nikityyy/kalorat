import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_service.dart';

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
