import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> getResponse(List<Map<String, dynamic>> conversationHistory) async {
    try {
      if (_apiKey.isEmpty) {
        return 'API key not configured. Please add GEMINI_API_KEY to your .env file.';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': conversationHistory,
          'systemInstruction': {
            'parts': [
              {
                'text': 'You are a professional baby food and infant nutrition AI assistant. '
                        'Provide safe, healthy, and age-appropriate food advice, schedules, and recipes. '
                        'Always prioritize safety (e.g. choking hazards, food temperature) and infant health guidance. '
                        'Keep answers relatively concise and easy to read for busy parents.'
              }
            ]
          }
        }),
      );

      if (response.statusCode == 429) {
        return 'I\'m receiving too many requests right now. Please wait a moment and try again. 🕐';
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] ?? 'Sorry, I couldn\'t process that.';
          }
        }
      }
      return 'Sorry, I encountered an issue communicating with the AI. Status code: ${response.statusCode}';
    } catch (e) {
      return 'Network Error: $e';
    }
  }
}
