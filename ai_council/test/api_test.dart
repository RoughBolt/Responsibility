import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync();
  String geminiKey = '';
  String groqKey = '';

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('GEMINI_API_KEY=')) {
      geminiKey = trimmed.substring('GEMINI_API_KEY='.length).trim();
    } else if (trimmed.startsWith('GROQ_API_KEY=')) {
      groqKey = trimmed.substring('GROQ_API_KEY='.length).trim();
    }
  }

  print('Testing Gemini (gemini-3.5-flash)...');
  final geminiFuture = http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$geminiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Say hello and confirm that the Gemini API connection is working.'}
          ]
        }
      ]
    }),
  ).timeout(const Duration(seconds: 15));

  print('Testing Groq (openai/gpt-oss-20b)...');
  final groqFuture = http.post(
    Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqKey',
    },
    body: jsonEncode({
      'model': 'openai/gpt-oss-20b',
      'messages': [
        {'role': 'user', 'content': 'Say hello and confirm that the Groq API connection is working.'}
      ],
      'max_tokens': 100,
    }),
  ).timeout(const Duration(seconds: 15));

  final results = await Future.wait([geminiFuture, groqFuture]);
  final geminiRes = results[0];
  final groqRes = results[1];

  print('\n=== RESULTS ===');
  if (geminiRes.statusCode == 200) {
    print('Gemini API Integration: WORKING');
    final data = jsonDecode(geminiRes.body);
    print('Gemini Response: ${data['candidates'][0]['content']['parts'][0]['text']}');
  } else {
    print('Gemini FAILED (${geminiRes.statusCode}): ${geminiRes.body}');
  }

  if (groqRes.statusCode == 200) {
    print('Groq API Integration: WORKING');
    final data = jsonDecode(groqRes.body);
    print('Groq Response: ${data['choices'][0]['message']['content']}');
  } else {
    print('Groq FAILED (${groqRes.statusCode}): ${groqRes.body}');
  }
}
