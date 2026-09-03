// ============================================================
// AI COUNCIL — Real AI API Providers (Gemini, Groq, OpenRouter)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

// ─────────────────────────────────────────────
// Secure API Key Configuration via environment
// ─────────────────────────────────────────────
class ApiConfig {
  static String geminiKey = '';
  static String groqKey = '';
  static String openRouterKey = '';

  static Future<void> loadEnv() async {
    try {
      final content = await Stream.fromFuture(
        Future.value(
          // Primary fallback loading
          String.fromEnvironment('GEMINI_API_KEY'),
        ),
      ).first;

      if (content.isNotEmpty) {
        geminiKey = content;
      }
    } catch (_) {}

    // Hardcode fallback from local .env if dart-define isn't passed
    _loadLocalEnvFallback();
  }

  static void _loadLocalEnvFallback() {
    // In Flutter, we can read runtime environment from asset or hardcoded safe setup
    if (geminiKey.isEmpty) {
      geminiKey = const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: '',
      );
    }
    if (groqKey.isEmpty) {
      groqKey = const String.fromEnvironment(
        'GROQ_API_KEY',
        defaultValue: '',
      );
    }
  }
}

// ─────────────────────────────────────────────
// Abstract provider interface
// ─────────────────────────────────────────────
abstract class AIProvider {
  String get id;
  String get displayName;
  String get modelName;
  bool get isConfigured;

  Future<String> generateResponse({
    required String systemPrompt,
    required String userPrompt,
  });
}

// ─────────────────────────────────────────────
// 1. GEMINI PROVIDER — Primary Analyst
// ─────────────────────────────────────────────
class GeminiProvider implements AIProvider {
  static const List<String> _candidateModels = [
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-3.5-flash',
  ];

  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Gemini';

  @override
  String get modelName => _candidateModels.first;

  @override
  bool get isConfigured => ApiConfig.geminiKey.isNotEmpty;

  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key is not configured.');
    }

    String lastError = 'No models responded.';

    for (final model in _candidateModels) {
      try {
        final url =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${ApiConfig.geminiKey}';

        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'system_instruction': {
                  'parts': [
                    {'text': systemPrompt},
                  ],
                },
                'contents': [
                  {
                    'parts': [
                      {'text': userPrompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.6,
                  'maxOutputTokens': 1024,
                },
                'safetySettings': [
                  {
                    'category': 'HARM_CATEGORY_HARASSMENT',
                    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                  },
                  {
                    'category': 'HARM_CATEGORY_HATE_SPEECH',
                    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                  },
                  {
                    'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String? ?? '';
            }
          }
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          lastError = 'Gemini ($model 503 high demand): ${response.body}';
          continue; // Try next candidate model on 503 or 429
        } else {
          lastError = 'Gemini API Error (${response.statusCode}): ${response.body}';
          continue;
        }
      } catch (e) {
        lastError = 'Gemini model $model failed: $e';
        continue;
      }
    }

    throw Exception(lastError);
  }
}

// ─────────────────────────────────────────────
// 2. GROQ PROVIDER — Critical Thinker
// ─────────────────────────────────────────────
class GroqProvider implements AIProvider {
  static const List<String> _candidateModels = [
    'openai/gpt-oss-20b',
    'llama-3.3-70b-versatile',
    'llama3-8b-8192',
    'mixtral-8x7b-32768',
  ];

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  String get id => 'groq';

  @override
  String get displayName => 'Groq';

  @override
  String get modelName => _candidateModels.first;

  @override
  bool get isConfigured => ApiConfig.groqKey.isNotEmpty;

  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      throw Exception('Groq API key is not configured.');
    }

    String lastError = 'No Groq models responded.';

    for (final model in _candidateModels) {
      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer ${ApiConfig.groqKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userPrompt},
                ],
                'temperature': 0.6,
                'max_tokens': 1024,
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final message = choices[0]['message'];
            return message['content'] as String? ?? '';
          }
        } else {
          lastError = 'Groq API Error ($model ${response.statusCode}): ${response.body}';
          continue;
        }
      } catch (e) {
        lastError = 'Groq model $model failed: $e';
        continue;
      }
    }

    throw Exception(lastError);
  }
}

// ─────────────────────────────────────────────
// 3. OPENROUTER PROVIDER — Independent Expert
// ─────────────────────────────────────────────
class OpenRouterProvider implements AIProvider {
  static const String _model = 'meta-llama/llama-3.1-8b-instruct:free';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  String get id => 'openrouter';

  @override
  String get displayName => 'OpenRouter';

  @override
  String get modelName => _model;

  @override
  bool get isConfigured => ApiConfig.openRouterKey.isNotEmpty;

  @override
  Future<String> generateResponse({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      throw Exception('OpenRouter API key is not configured.');
    }

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer ${ApiConfig.openRouterKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://ai-council.app',
            'X-Title': 'AI Council Mobile',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.6,
            'max_tokens': 1024,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        return message['content'] as String? ?? '';
      }
      throw Exception('OpenRouter returned empty choices.');
    } else {
      throw Exception('OpenRouter API Error (${response.statusCode}): ${response.body}');
    }
  }
}

// ─────────────────────────────────────────────
// REGISTRY
// ─────────────────────────────────────────────
class ProviderRegistry {
  static final GeminiProvider gemini = GeminiProvider();
  static final GroqProvider groq = GroqProvider();
  static final OpenRouterProvider openRouter = OpenRouterProvider();

  static AIProvider? getProviderFor(String id) {
    switch (id) {
      case 'gemini':
        return gemini;
      case 'groq':
        return groq;
      case 'openrouter':
        return openRouter;
      default:
        return null;
    }
  }

  static List<AgentConfig> buildAgentConfigs() {
    return [
      AgentConfig(
        id: 'gemini',
        displayName: 'Gemini',
        role: AgentRole.analyst,
        status: gemini.isConfigured ? ProviderStatus.available : ProviderStatus.unavailable,
        modelName: gemini.modelName,
      ),
      AgentConfig(
        id: 'groq',
        displayName: 'Groq',
        role: AgentRole.criticalThinker,
        status: groq.isConfigured ? ProviderStatus.available : ProviderStatus.unavailable,
        modelName: groq.modelName,
      ),
    ];
  }
}
