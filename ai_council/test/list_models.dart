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

  print('Listing Gemini models...');
  try {
    final res = await http.get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$geminiKey'));
    print('Gemini status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final models = (data['models'] as List).map((m) => m['name']).toList();
      print('Gemini Available Models:\n${models.join('\n')}');
    } else {
      print(res.body);
    }
  } catch (e) {
    print('Gemini list error: $e');
  }

  print('\nListing Groq models...');
  try {
    final res = await http.get(
      Uri.parse('https://api.groq.com/openai/v1/models'),
      headers: {'Authorization': 'Bearer $groqKey'},
    );
    print('Groq status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final models = (data['data'] as List).map((m) => m['id']).toList();
      print('Groq Available Models:\n${models.join('\n')}');
    } else {
      print(res.body);
    }
  } catch (e) {
    print('Groq list error: $e');
  }
}
