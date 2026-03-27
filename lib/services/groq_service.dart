import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey =String.fromEnvironment('GROQ_API_KEY'); // 🔑 KEY GROQ
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama-3.1-8b-instant",
        "messages": [
          {
            "role": "system",
            "content":
            "Bạn là trợ lý AI cho hệ thống đặt phòng khách sạn. "
                "Trả lời ngắn gọn, thân thiện, dễ hiểu."
          },
          {
            "role": "user",
            "content": userMessage
          }
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        'Groq API error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
