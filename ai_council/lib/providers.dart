// ============================================================
// AI COUNCIL — AI Provider Abstraction & Implementations
// ============================================================
// Supports:
// 1. Gemini (Primary Analyst + Synthesizer) -> GEMINI_API_KEY
// 2. Groq (Critical Thinker) -> GROQ_API_KEY
// 3. OpenRouter (Independent Expert) -> OPENROUTER_API_KEY
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'models.dart';

// ─────────────────────────────────────────────
// API KEY CONFIGURATION
// Supports dynamic initialization from .env asset or String.fromEnvironment
// ─────────────────────────────────────────────
class ApiConfig {
  static String geminiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static String groqKey = const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static String openRouterKey = const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');

  /// Attempt to load from .env asset bundle if available
  static Future<void> loadEnv() async {
    try {
      final envString = await rootBundle.loadString('.env');
      for (final line in envString.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final val = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", '');
          if (key == 'GEMINI_API_KEY' && val.isNotEmpty && geminiKey.isEmpty) {
            geminiKey = val;
          } else if (key == 'GROQ_API_KEY' && val.isNotEmpty && groqKey.isEmpty) {
            groqKey = val;
          } else if (key == 'OPENROUTER_API_KEY' && val.isNotEmpty && openRouterKey.isEmpty) {
            openRouterKey = val;
          }
        }
      }
    } catch (_) {
      // .env not in assets or unreadable, fall back to default
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
  static const _model = 'gemini-3.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Gemini';

  @override
  String get modelName => _model;

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

    final response = await http
        .post(
          Uri.parse('$_baseUrl?key=${ApiConfig.geminiKey}'),
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
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final finishReason =
        data['candidates']?[0]?['finishReason'] as String? ?? '';
    if (finishReason == 'SAFETY') {
      throw Exception('SAFETY_BLOCK: Content blocked by Gemini safety filters');
    }

    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response received from Gemini');
    }
    return text.trim();
  }
}

// ─────────────────────────────────────────────
// 2. GROQ PROVIDER — Critical Thinker
// ─────────────────────────────────────────────
class GroqProvider implements AIProvider {
  static const _model = 'openai/gpt-oss-20b';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  String get id => 'groq';

  @override
  String get displayName => 'Groq';

  @override
  String get modelName => _model;

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

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.groqKey}',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'max_tokens': 1024,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Groq HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['choices']?[0]?['message']?['content'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response received from Groq');
    }
    return text.trim();
  }
}

// ─────────────────────────────────────────────
// 3. OPENROUTER PROVIDER — Independent Expert
// ─────────────────────────────────────────────
class OpenRouterProvider implements AIProvider {
  // Auto/free model or Mistral / Meta Llama free endpoints on OpenRouter
  static const _model = 'meta-llama/llama-3.3-70b-instruct:free';
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  String get id => 'openrouter';

  @override
  String get displayName => 'OpenRouter';

  @override
  String get modelName => 'Llama 3.3 Free';

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
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openRouterKey}',
            'HTTP-Referer': 'https://aicouncil.hackathon.app',
            'X-Title': 'AI Council',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'max_tokens': 1024,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('OpenRouter HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['choices']?[0]?['message']?['content'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response received from OpenRouter');
    }
    return text.trim();
  }
}

// ─────────────────────────────────────────────
// Provider Registry
// ─────────────────────────────────────────────
class ProviderRegistry {
  static final GeminiProvider gemini = GeminiProvider();
  static final GroqProvider groq = GroqProvider();
  static final OpenRouterProvider openRouter = OpenRouterProvider();

  /// Build status of all 3 council members
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
      AgentConfig(
        id: 'openrouter',
        displayName: 'OpenRouter',
        role: AgentRole.independentExpert,
        status: openRouter.isConfigured ? ProviderStatus.available : ProviderStatus.unavailable,
        modelName: openRouter.modelName,
      ),
    ];
  }

  /// Get active provider for an agent id
  static AIProvider? getProviderFor(String agentId) {
    if (agentId == 'gemini') return gemini;
    if (agentId == 'groq') return groq;
    if (agentId == 'openrouter') return openRouter;
    return null;
  }
}
