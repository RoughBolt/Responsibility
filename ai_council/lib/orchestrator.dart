// ============================================================
// AI COUNCIL — 7-Step Multi-Agent Orchestrator
// ============================================================
// Step 1: Collect independent responses (Gemini, Groq, OpenRouter)
// Step 2 & 3 & 4: Compare responses -> Agreements, Disagreements, Unique Insights, Missing Info
// Step 5: Controlled critique / debate stage
// Step 6: Safety evaluation (Gemini Provider Safety)
// Step 7: Final synthesis (Gemini Final Synthesizer)
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'models.dart';
import 'providers.dart';

class CouncilOrchestrator {
  final GeminiProvider _gemini = ProviderRegistry.gemini;

  // ─────────────────────────────────────────────
  // ROLE SYSTEM INSTRUCTIONS (Per Problem Specification)
  // ─────────────────────────────────────────────
  static const String _geminiAnalystPrompt = '''You are the PRIMARY ANALYST in the AI Council.
Analyze the user's prompt carefully.
Provide:
- Context.
- Main reasoning.
- Important considerations.
- A clear answer.
Be accurate. Do not invent facts. Clearly state uncertainty when appropriate.
Respond in 2-4 concise, structured paragraphs. Do not mention or reference other agents.''';

  static const String _groqCriticalThinkerPrompt = '''You are the CRITICAL THINKER in the AI Council.
Independently analyze the user's prompt.
Focus on:
- Assumptions.
- Weak reasoning.
- Missing information.
- Alternative interpretations.
- Potential risks.
Provide a useful alternative answer. Do not reference other agents.
Respond in 2-4 concise, analytical paragraphs.''';

  static const String _openRouterExpertPrompt = '''You are the INDEPENDENT EXPERT in the AI Council.
Independently answer the user's prompt.
Focus on:
- Practical insights.
- Alternative perspectives.
- Actionable recommendations.
Provide insights that another expert might contribute. Do not reference other agents.
Respond in 2-4 concise, insightful paragraphs.''';

  // ─────────────────────────────────────────────
  // MAIN PIPELINE
  // ─────────────────────────────────────────────
  Stream<PipelineUpdate> runPipeline(String userPrompt) async* {
    final agents = ProviderRegistry.buildAgentConfigs();
    final configuredAgents = agents.where((a) => a.status == ProviderStatus.available).toList();

    if (configuredAgents.isEmpty) {
      yield PipelineUpdate(
        stage: PipelineStage.failed,
        agentResponses: [],
        statusMessage: 'No AI providers configured. Please provide GEMINI_API_KEY, GROQ_API_KEY, or OPENROUTER_API_KEY.',
      );
      return;
    }

    // Step 1: Initiate collection state
    final loadingResponses = agents.map((a) {
      if (a.status == ProviderStatus.available) {
        return AgentResponse.loading(a);
      } else {
        return AgentResponse.failed(a, 'Not Configured');
      }
    }).toList();

    yield PipelineUpdate(
      stage: PipelineStage.collectingResponses,
      agentResponses: loadingResponses,
      statusMessage: 'Gathering independent perspectives from council members...',
    );

    // Parallel execution across configured providers
    final agentResponses = await _collectParallelResponses(agents, userPrompt);

    final successful = agentResponses.where((r) => r.success).toList();

    yield PipelineUpdate(
      stage: PipelineStage.collectingResponses,
      agentResponses: agentResponses,
      statusMessage: '${successful.length}/${configuredAgents.length} council members responded.',
    );

    if (successful.isEmpty) {
      yield PipelineUpdate(
        stage: PipelineStage.failed,
        agentResponses: agentResponses,
        statusMessage: 'All configured agents failed to respond. Please check API keys and network.',
      );
      return;
    }

    // Step 2, 3, 4: Comparison
    yield PipelineUpdate(
      stage: PipelineStage.comparing,
      agentResponses: agentResponses,
      statusMessage: 'Comparing viewpoints: identifying agreements and disagreements...',
    );

    CouncilAnalysis analysis;
    try {
      analysis = await _compareResponses(userPrompt, successful);
    } catch (_) {
      analysis = CouncilAnalysis.empty();
    }

    // Step 5: Controlled Critique
    yield PipelineUpdate(
      stage: PipelineStage.critiquing,
      agentResponses: agentResponses,
      statusMessage: 'Running critique stage: evaluating claims & missing information...',
    );

    CritiqueResult? critique;
    try {
      critique = await _runCritique(userPrompt, successful, analysis);
    } catch (_) {
      critique = null;
    }

    // Step 6: Safety Check
    yield PipelineUpdate(
      stage: PipelineStage.safetyCheck,
      agentResponses: agentResponses,
      statusMessage: 'Running responsible AI safety evaluation...',
    );

    SafetyResult safety;
    try {
      safety = await _evaluateSafety(userPrompt, successful);
    } catch (_) {
      safety = SafetyResult.unknown();
    }

    // Step 7: Final Synthesis
    yield PipelineUpdate(
      stage: PipelineStage.synthesizing,
      agentResponses: agentResponses,
      statusMessage: 'Synthesizing final consensus answer...',
    );

    String? finalAnswer;
    try {
      finalAnswer = await _synthesizeFinalAnswer(
        userPrompt,
        successful,
        analysis,
        critique,
        safety,
      );
    } catch (e) {
      finalAnswer = 'Unable to synthesize consensus answer: $e\n\nPlease review individual agent answers below.';
    }

    final result = CouncilResult(
      userPrompt: userPrompt,
      agentResponses: agentResponses,
      analysis: analysis,
      critique: critique,
      safety: safety,
      finalAnswer: finalAnswer,
      isPartialSuccess: successful.length < configuredAgents.length,
      participatingAgentCount: successful.length,
      totalConfiguredCount: configuredAgents.length,
    );

    yield PipelineUpdate(
      stage: PipelineStage.done,
      agentResponses: agentResponses,
      statusMessage: 'Council deliberation completed.',
      finalResult: result,
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Parallel calls
  // ─────────────────────────────────────────────
  Future<List<AgentResponse>> _collectParallelResponses(
    List<AgentConfig> agents,
    String userPrompt,
  ) async {
    final futures = agents.map((agent) async {
      final provider = ProviderRegistry.getProviderFor(agent.id);
      if (provider == null || !provider.isConfigured) {
        return AgentResponse.failed(agent, 'Provider Not Configured');
      }

      String systemPrompt = '';
      if (agent.id == 'gemini') {
        systemPrompt = _geminiAnalystPrompt;
      } else if (agent.id == 'groq') {
        systemPrompt = _groqCriticalThinkerPrompt;
      } else if (agent.id == 'openrouter') {
        systemPrompt = _openRouterExpertPrompt;
      }

      final start = DateTime.now();
      try {
        final response = await provider.generateResponse(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        final elapsed = DateTime.now().difference(start);
        return AgentResponse.succeeded(agent, response, elapsed);
      } catch (e) {
        return AgentResponse.failed(agent, e.toString());
      }
    });

    return Future.wait(futures);
  }

  // ─────────────────────────────────────────────
  // STEPS 2, 3, 4: Comparison
  // ─────────────────────────────────────────────
  Future<CouncilAnalysis> _compareResponses(
    String userPrompt,
    List<AgentResponse> responses,
  ) async {
    // If only 1 response, comparison has no cross-model divergence
    if (responses.length == 1) {
      return CouncilAnalysis(
        agreements: ['Single provider responded: ${responses.first.agent.displayName}'],
        disagreements: ['No disagreement available (Single-Provider Fallback Mode)'],
        uniqueInsights: ['Independent analysis provided by ${responses.first.agent.displayName}'],
        missingInformation: ['Cross-agent validation requires 2 or more configured providers.'],
      );
    }

    final responseSummary = responses.map((r) {
      return '### Agent: ${r.agent.displayName} (${r.agent.roleLabel})\n${r.response}';
    }).join('\n\n');

    final prompt = '''
You are the Council Comparison Engine.
Compare these independent AI responses to the user prompt.

USER PROMPT: "$userPrompt"

RESPONSES:
$responseSummary

Analyze and output ONLY a JSON object (no code fences, no markdown):
{
  "agreements": ["point 1", "point 2"],
  "disagreements": ["point 1", "point 2"],
  "uniqueInsights": ["point 1", "point 2"],
  "missingInformation": ["point 1"]
}
Keep each bullet point brief and punchy (15-25 words max). Output ONLY raw JSON.
''';

    final raw = await _fallbackCallableProvider(responses).generateResponse(
      systemPrompt: 'You are a structured AI response comparator. Return only valid JSON.',
      userPrompt: prompt,
    );

    final json = _extractJson(raw);
    final parsed = jsonDecode(json) as Map<String, dynamic>;

    return CouncilAnalysis(
      agreements: _toStringList(parsed['agreements']),
      disagreements: _toStringList(parsed['disagreements']),
      uniqueInsights: _toStringList(parsed['uniqueInsights']),
      missingInformation: _toStringList(parsed['missingInformation']),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 5: Critique
  // ─────────────────────────────────────────────
  Future<CritiqueResult> _runCritique(
    String userPrompt,
    List<AgentResponse> responses,
    CouncilAnalysis analysis,
  ) async {
    final responseSummary = responses.map((r) {
      return '${r.agent.displayName} (${r.agent.roleLabel}): ${r.response}';
    }).join('\n\n---\n\n');

    final prompt = '''
You are the CRITIC AGENT in the AI Council.
Perform ONE controlled critique round.

USER QUESTION: "$userPrompt"

AGENT RESPONSES:
$responseSummary

COMPARISON:
Agreements: ${analysis.agreements.join('; ')}
Disagreements: ${analysis.disagreements.join('; ')}

Return ONLY a JSON object (no markdown, no code fences):
{
  "agreementSummary": "Concise summary of unanimous points (1-2 sentences)",
  "disagreementSummary": "Key contention or varying angles (1-2 sentences)",
  "missingInformation": "Crucial context overlooked (1-2 sentences)",
  "recommendation": "Priority focus for the final answer (1-2 sentences)"
}
''';

    final raw = await _fallbackCallableProvider(responses).generateResponse(
      systemPrompt: 'You are a structured AI critique agent. Output only raw JSON.',
      userPrompt: prompt,
    );

    final json = _extractJson(raw);
    final parsed = jsonDecode(json) as Map<String, dynamic>;

    return CritiqueResult(
      agreementSummary: parsed['agreementSummary'] as String? ?? '',
      disagreementSummary: parsed['disagreementSummary'] as String? ?? '',
      missingInformation: parsed['missingInformation'] as String? ?? '',
      recommendation: parsed['recommendation'] as String? ?? '',
    );
  }

  // ─────────────────────────────────────────────
  // STEP 6: Safety Check
  // ─────────────────────────────────────────────
  Future<SafetyResult> _evaluateSafety(
    String userPrompt,
    List<AgentResponse> responses,
  ) async {
    final combinedContent = responses.map((r) => r.response ?? '').join('\n\n');

    final prompt = '''
You are the Responsible AI Safety Officer for AI Council.
Evaluate whether the user prompt and candidate AI answers violate safety guardrails.

USER PROMPT:
$userPrompt

GENERATED CONTENT:
$combinedContent

Check for:
1. Harmful/violent/dangerous guidance
2. Hate speech or unlawful discrimination
3. Private PII or credential leakage
4. Malicious code or exploit assistance

Output ONLY a JSON object (no markdown fences):
{
  "status": "SAFE" or "FLAGGED" or "BLOCKED",
  "reason": "Clear 1-2 sentence justification"
}
''';

    final raw = await _fallbackCallableProvider(responses).generateResponse(
      systemPrompt: 'You are a safety evaluation officer. Return only raw JSON.',
      userPrompt: prompt,
    );

    final json = _extractJson(raw);
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    final statusStr = (parsed['status'] as String? ?? 'UNKNOWN').toUpperCase();

    SafetyStatus status;
    switch (statusStr) {
      case 'SAFE':
        status = SafetyStatus.safe;
      case 'FLAGGED':
        status = SafetyStatus.flagged;
      case 'BLOCKED':
        status = SafetyStatus.blocked;
      default:
        status = SafetyStatus.unknown;
    }

    return SafetyResult(
      status: status,
      reason: parsed['reason'] as String? ?? 'No safety hazards detected.',
      mechanism: 'Gemini Provider Safety',
    );
  }

  // ─────────────────────────────────────────────
  // STEP 7: Final Synthesis
  // ─────────────────────────────────────────────
  Future<String> _synthesizeFinalAnswer(
    String userPrompt,
    List<AgentResponse> responses,
    CouncilAnalysis analysis,
    CritiqueResult? critique,
    SafetyResult safety,
  ) async {
    final agentCount = responses.length;
    final responseSummary = responses.map((r) {
      return '${r.agent.displayName} (${r.agent.roleLabel}):\n${r.response}';
    }).join('\n\n---\n\n');

    final critiqueText = critique != null
        ? '''CRITIQUE:
- Core Agreement: ${critique.agreementSummary}
- Disagreements: ${critique.disagreementSummary}
- Missing Context: ${critique.missingInformation}
- Prioritization: ${critique.recommendation}'''
        : '';

    final safetyInstruction = safety.status == SafetyStatus.blocked
        ? 'NOTE: The safety officer BLOCKED certain aspects. Refuse harmful elements firmly and provide safe educational guidance.'
        : '';

    final prompt = '''
You are the FINAL SYNTHESIZER for AI Council.
$agentCount independent AI agent(s) have deliberated on this user inquiry:

USER PROMPT: "$userPrompt"

INDEPENDENT AGENT PERSPECTIVES:
$responseSummary

COUNCIL ANALYSIS:
- Agreements: ${analysis.agreements.join('; ')}
- Disagreements: ${analysis.disagreements.join('; ')}
- Unique Insights: ${analysis.uniqueInsights.join('; ')}
$critiqueText

SAFETY EVALUATION: ${safety.statusLabel}
$safetyInstruction

SYNTHESIS RULES:
1. Generate the single BEST final consensus answer.
2. Synthesize key strengths and valid points across models.
3. If models disagreed, address the discrepancy openly and provide balanced clarity.
4. Do NOT say "All models agree" unless they actually did.
5. If only 1 model responded, present the refined best answer clearly.
6. Do not expose internal chain-of-thought or markdown code fences.
7. Write directly to the user in a professional, authoritative, and helpful tone.
''';

    return await _fallbackCallableProvider(responses).generateResponse(
      systemPrompt: 'You are the chief synthesizer of AI Council. Deliver the most complete, accurate, and balanced answer.',
      userPrompt: prompt,
    );
  }

  // Helper: prefer Gemini for synthesis/critique, but fallback to any available responding provider if Gemini failed
  AIProvider _fallbackCallableProvider(List<AgentResponse> successful) {
    if (_gemini.isConfigured) return _gemini;
    final firstSuccess = successful.first.agent.id;
    return ProviderRegistry.getProviderFor(firstSuccess) ?? _gemini;
  }

  String _extractJson(String text) {
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = fenced.firstMatch(text);
    if (match != null) return match.group(1)!.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) return text.substring(start, end + 1);
    return text.trim();
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }
}
