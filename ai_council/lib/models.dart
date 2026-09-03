// ============================================================
// AI COUNCIL — Data Models
// ============================================================

enum AgentRole { analyst, criticalThinker, independentExpert }

enum ProviderStatus { available, unavailable, checking }

enum SafetyStatus { safe, flagged, blocked, unknown }

enum PipelineStage {
  idle,
  collectingResponses,
  comparing,
  critiquing,
  safetyCheck,
  synthesizing,
  done,
  failed,
}

// ─────────────────────────────────────────────
// Per-agent configuration
// ─────────────────────────────────────────────
class AgentConfig {
  final String id; // 'gemini', 'groq', 'openrouter'
  final String displayName; // 'Gemini', 'Groq', 'OpenRouter'
  final AgentRole role;
  final ProviderStatus status;
  final String modelName;

  const AgentConfig({
    required this.id,
    required this.displayName,
    required this.role,
    required this.status,
    this.modelName = '',
  });

  String get roleLabel {
    switch (role) {
      case AgentRole.analyst:
        return 'Primary Analyst';
      case AgentRole.criticalThinker:
        return 'Critical Thinker';
      case AgentRole.independentExpert:
        return 'Independent Expert';
    }
  }

  String get roleDescription {
    switch (role) {
      case AgentRole.analyst:
        return 'Factual context · Comprehensive reasoning · Core accuracy';
      case AgentRole.criticalThinker:
        return 'Challenges assumptions · Weak spots · Risk awareness';
      case AgentRole.independentExpert:
        return 'Actionable guidance · Diverse lens · Practical solutions';
    }
  }

  AgentConfig copyWith({ProviderStatus? status, String? modelName}) {
    return AgentConfig(
      id: id,
      displayName: displayName,
      role: role,
      status: status ?? this.status,
      modelName: modelName ?? this.modelName,
    );
  }
}

// ─────────────────────────────────────────────
// Individual agent response
// ─────────────────────────────────────────────
class AgentResponse {
  final AgentConfig agent;
  final String? response;
  final String? error;
  final bool success;
  final Duration? responseTime;
  final bool isLoading;

  const AgentResponse({
    required this.agent,
    this.response,
    this.error,
    required this.success,
    this.responseTime,
    this.isLoading = false,
  });

  factory AgentResponse.loading(AgentConfig agent) =>
      AgentResponse(agent: agent, success: false, isLoading: true);

  factory AgentResponse.failed(AgentConfig agent, String error) =>
      AgentResponse(agent: agent, error: error, success: false);

  factory AgentResponse.succeeded(
    AgentConfig agent,
    String response,
    Duration time,
  ) => AgentResponse(
        agent: agent,
        response: response,
        success: true,
        responseTime: time,
      );
}

// ─────────────────────────────────────────────
// Council Analysis (Comparison + Gaps)
// ─────────────────────────────────────────────
class CouncilAnalysis {
  final List<String> agreements;
  final List<String> disagreements;
  final List<String> uniqueInsights;
  final List<String> missingInformation;

  const CouncilAnalysis({
    required this.agreements,
    required this.disagreements,
    required this.uniqueInsights,
    required this.missingInformation,
  });

  factory CouncilAnalysis.empty() => const CouncilAnalysis(
        agreements: [],
        disagreements: [],
        uniqueInsights: [],
        missingInformation: [],
      );
}

// ─────────────────────────────────────────────
// Critique result
// ─────────────────────────────────────────────
class CritiqueResult {
  final String agreementSummary;
  final String disagreementSummary;
  final String missingInformation;
  final String recommendation;

  const CritiqueResult({
    required this.agreementSummary,
    required this.disagreementSummary,
    required this.missingInformation,
    required this.recommendation,
  });
}

// ─────────────────────────────────────────────
// Safety result
// ─────────────────────────────────────────────
class SafetyResult {
  final SafetyStatus status;
  final String reason;
  final String mechanism; // e.g. 'Gemini Provider Safety'

  const SafetyResult({
    required this.status,
    required this.reason,
    required this.mechanism,
  });

  factory SafetyResult.unknown() => const SafetyResult(
        status: SafetyStatus.unknown,
        reason: 'Safety evaluation unavailable.',
        mechanism: 'Safety Evaluation Unavailable',
      );

  String get statusLabel {
    switch (status) {
      case SafetyStatus.safe:
        return 'SAFE';
      case SafetyStatus.flagged:
        return 'FLAGGED';
      case SafetyStatus.blocked:
        return 'BLOCKED';
      case SafetyStatus.unknown:
        return 'UNKNOWN';
    }
  }
}

// ─────────────────────────────────────────────
// Full council session result
// ─────────────────────────────────────────────
class CouncilResult {
  final String userPrompt;
  final List<AgentResponse> agentResponses;
  final CouncilAnalysis? analysis;
  final CritiqueResult? critique;
  final SafetyResult? safety;
  final String? finalAnswer;
  final bool isPartialSuccess;
  final int participatingAgentCount;
  final int totalConfiguredCount;

  const CouncilResult({
    required this.userPrompt,
    required this.agentResponses,
    this.analysis,
    this.critique,
    this.safety,
    this.finalAnswer,
    this.isPartialSuccess = false,
    required this.participatingAgentCount,
    required this.totalConfiguredCount,
  });

  List<AgentResponse> get successfulResponses =>
      agentResponses.where((r) => r.success).toList();

  List<AgentResponse> get failedResponses =>
      agentResponses.where((r) => !r.success && !r.isLoading).toList();

  bool get isSingleProviderMode => participatingAgentCount == 1;
}

// ─────────────────────────────────────────────
// Pipeline progress update (for live UI)
// ─────────────────────────────────────────────
class PipelineUpdate {
  final PipelineStage stage;
  final List<AgentResponse> agentResponses;
  final String statusMessage;
  final CouncilResult? finalResult;

  const PipelineUpdate({
    required this.stage,
    required this.agentResponses,
    required this.statusMessage,
    this.finalResult,
  });
}
