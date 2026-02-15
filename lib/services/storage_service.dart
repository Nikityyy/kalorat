import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _apiKeyKey = 'gemini_api_key';

  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey);
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to read API key', e);
      return null;
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyKey, value: apiKey);
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to save API key', e);
    }
  }

  Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _apiKeyKey);
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to delete API key', e);
    }
  }
}
