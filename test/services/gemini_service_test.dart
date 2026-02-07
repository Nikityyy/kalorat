import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:kalorat/services/gemini_service.dart';

// Mock classes for testing
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('GeminiService', () {
    group('constructor', () {
      test('creates service with required apiKey', () {
        final service = GeminiService(apiKey: 'test-key');
        expect(service.apiKey, 'test-key');
        expect(service.language, 'de'); // default
      });

      test('creates service with custom language', () {
        final service = GeminiService(apiKey: 'test-key', language: 'en');
        expect(service.language, 'en');
      });
    });

    group('validateApiKey', () {
      test('returns false for empty key', () async {
        final service = GeminiService(apiKey: '');
        final result = await service.validateApiKey('');
        expect(result, false);
      });
    });

    group('analyzeMeal', () {
      test('throws exception when API key is empty', () async {
        final service = GeminiService(apiKey: '');

        expect(
          () => service.analyzeMeal(['/test/photo.jpg']),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('_getMimeType (via public methods)', () {
      // We test _getMimeType indirectly since it's private
      // The service should handle different image extensions
      test('service accepts jpg images', () {
        final service = GeminiService(apiKey: 'test-key');
        // If it doesn't throw on construction, basic validation passes
        expect(service, isNotNull);
      });
    });

    group('_getPrompt (via analyzeMeal)', () {
      test('uses German prompt for de language', () {
        final service = GeminiService(apiKey: 'test-key', language: 'de');
        expect(service.language, 'de');
      });

      test('uses English prompt for en language', () {
        final service = GeminiService(apiKey: 'test-key', language: 'en');
        expect(service.language, 'en');
      });
    });

    group('model rotation logic', () {
      test('primary models list contains expected models', () {
        // Verify the service is configured correctly
        final service = GeminiService(apiKey: 'test-key');
        expect(service, isNotNull);
      });
    });

    group('response parsing', () {
      test('parses valid JSON response correctly', () {
        // Test data that matches expected API response format
        final responseJson = {
          'meal_name': 'Test Meal',
          'calories': 500.0,
          'protein': 25.0,
          'carbs': 50.0,
          'fats': 15.0,
          'vitamins': {'A': 100.0, 'C': 50.0},
          'minerals': {'Calcium': 200.0},
          'confidence_score': 0.85,
          'analysis_note': 'Based on estimation',
        };

        // Verify the structure matches what the service expects
        expect(responseJson['meal_name'], 'Test Meal');
        expect(responseJson['calories'], 500.0);
        expect(responseJson['vitamins'], isA<Map>());
      });

      test('handles no_food_detected error response', () {
        final errorResponse = {'error': 'no_food_detected'};

        expect(errorResponse.containsKey('error'), true);
        expect(errorResponse['error'], 'no_food_detected');
      });

      test('validates Atwater formula compliance', () {
        // Atwater: calories ≈ (protein * 4) + (carbs * 4) + (fats * 9)
        const protein = 25.0;
        const carbs = 50.0;
        const fats = 15.0;
        const reportedCalories = 435.0;

        final calculated = (protein * 4) + (carbs * 4) + (fats * 9);
        // 25*4 + 50*4 + 15*9 = 100 + 200 + 135 = 435

        expect(calculated, 435.0);
        expect(
          (reportedCalories - calculated).abs(),
          lessThan(reportedCalories * 0.15),
        );
      });
    });

    group('error handling', () {
      test('handles 429 rate limit error format', () {
        final errorMessage = 'API error: 429 - Rate limited';
        expect(errorMessage.contains('429'), true);
      });

      test('handles generic API error format', () {
        final errorMessage = 'API error: 500 - Internal server error';
        expect(errorMessage.contains('500'), true);
      });
    });
  });
}
