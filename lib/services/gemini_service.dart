import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent';

  final String apiKey;
  final String language;

  GeminiService({required this.apiKey, this.language = 'de'});

  Future<Map<String, dynamic>?> analyzeMeal(List<String> imagePaths) async {
    if (apiKey.isEmpty) {
      throw Exception('API key is not set');
    }

    try {
      // Prepare image parts
      final List<Map<String, dynamic>> imageParts = [];
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = _getMimeType(path);
          imageParts.add({
            'inline_data': {'mime_type': mimeType, 'data': base64Image},
          });
        }
      }

      if (imageParts.isEmpty) {
        throw Exception('No valid images found');
      }

      // Build prompt based on language
      final prompt = language == 'de'
          ? '''Analysiere dieses Essen und antworte NUR mit einem validen JSON-Objekt ohne Markdown-Formatierung:
{
  "meal_name": "Name der Mahlzeit auf Deutsch",
  "calories": Kalorien als Zahl,
  "protein": Protein in Gramm als Zahl,
  "carbs": Kohlenhydrate in Gramm als Zahl,
  "fats": Fett in Gramm als Zahl,
  "vitamins": {"A": mg, "C": mg, "D": µg, ...},
  "minerals": {"Calcium": mg, "Eisen": mg, ...}
}
Schätze die Werte basierend auf dem Bild. Gib nur das JSON zurück, keine Erklärungen.'''
          : '''Analyze this food and respond ONLY with a valid JSON object without Markdown formatting:
{
  "meal_name": "Name of the meal",
  "calories": calories as number,
  "protein": protein in grams as number,
  "carbs": carbohydrates in grams as number,
  "fats": fat in grams as number,
  "vitamins": {"A": mg, "C": mg, "D": µg, ...},
  "minerals": {"Calcium": mg, "Iron": mg, ...}
}
Estimate the values based on the image. Return only the JSON, no explanations.''';

      // Build request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              ...imageParts,
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text != null) {
          print(text);
          String cleanedText = text.trim();
          if (cleanedText.startsWith('```json')) {
            cleanedText = cleanedText.substring(7);
          } else if (cleanedText.startsWith('```')) {
            cleanedText = cleanedText.substring(3);
          }
          if (cleanedText.endsWith('```')) {
            cleanedText = cleanedText.substring(0, cleanedText.length - 3);
          }
          cleanedText = cleanedText.trim();

          try {
            return jsonDecode(cleanedText) as Map<String, dynamic>;
          } catch (e) {
            // Try to extract JSON from the text
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedText);
            if (jsonMatch != null) {
              return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            }
          }
        }
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }

  Future<bool> validateApiKey(String key) async {
    if (key.isEmpty) return false;

    // We basically make a dummy request to check validity.
    // Using a cheap model or just empty prompt validation if possible.
    // We'll try to generate a simple "Ping" with the key.

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 1},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
