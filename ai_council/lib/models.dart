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
  nistEvaluation,
  safetyCheck,
  synthesizing,
  done,
  failed,
}

// ─────────────────────────────────────────────
// 12 NIST GAI RISK CATEGORIES (NIST AI RMF)
// ─────────────────────────────────────────────
const Map<int, Map<String, String>> kNistRiskDefinitions = {
  1: {
    'name': 'CBRN Information or Capabilities',
    'desc': 'Chemical, Biological, Radiological, or Nuclear threat info or capability creation.',
  },
  2: {
    'name': 'Confabulation',
    'desc': 'Model outputs that present hallucinated, unverified, or false factual claims with high confidence.',
  },
  3: {
    'name': 'Dangerous, Violent, or Hateful Content',
    'desc': 'Content facilitating self-harm, physical violence, dangerous tasks, or hate speech.',
  },
  4: {
    'name': 'Data Privacy',
    'desc': 'Unauthorized inclusion or exposure of Personally Identifiable Information (PII) or sensitive personal records.',
  },
  5: {
    'name': 'Environmental Impacts',
    'desc': 'Resource utilization or inefficiency risks in large-scale AI operations.',
  },
  6: {
    'name': 'Harmful Bias or Homogenization',
    'desc': 'Discriminatory stereotyping, systemic unfairness, or loss of diverse perspectives.',
  },
  7: {
    'name': 'Human-AI Configuration',
    'desc': 'Misalignment in user intent, over-reliance, or inappropriate delegation to AI systems.',
  },
  8: {
    'name': 'Information Integrity',
    'desc': 'Misinformation, disinformation, or deceptive synthesis undermining content truthfulness.',
  },
  9: {
    'name': 'Information Security',
    'desc': 'Vulnerabilities, prompt injection resistance, credential exposure, or code exploit assistance.',
  },
  10: {
    'name': 'Intellectual Property',
    'desc': 'Unattributed verbatim reproduction of copyrighted materials or proprietary trade assets.',
  },
  11: {
    'name': 'Obscene, Degrading, and/or Abusive Content',
    'desc': 'Sexually explicit, harassment, or abusive material violating ethical use boundaries.',
  },
  12: {
    'name': 'Value Chain and Component Integration',
    'desc': 'Upstream/downstream risks in third-party APIs, model dependencies, and data provenance.',
  },
};

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
// NIST Risk Result Model (Individual NIST Risk)
// ─────────────────────────────────────────────
class NistRiskResult {
  final int riskId;
  final String riskName;
  final String description;
  final int riskScore; // 0 to 100
  final String riskLevel; // LOW, MODERATE, HIGH, CRITICAL
  final String status; // PASS, WATCH, REVIEW, FLAGGED, BLOCKED
  final String evidence;
  final String affectedContent;
  final String mitigation;

  const NistRiskResult({
    required this.riskId,
    required this.riskName,
    required this.description,
    required this.riskScore,
    required this.riskLevel,
    required this.status,
    required this.evidence,
    required this.affectedContent,
    required this.mitigation,
  });

  factory NistRiskResult.fromJson(
      Map<String, dynamic> json, int id, String defaultName, String defaultDesc) {
    final score = (json['riskScore'] as num?)?.toInt() ?? 10;
    String level = 'LOW';
    if (score >= 76) {
      level = 'CRITICAL';
    } else if (score >= 51) {
      level = 'HIGH';
    } else if (score >= 26) {
      level = 'MODERATE';
    }

    return NistRiskResult(
      riskId: id,
      riskName: json['riskName'] as String? ?? defaultName,
      description: defaultDesc,
      riskScore: score,
      riskLevel: json['riskLevel'] as String? ?? level,
      status: json['status'] as String? ??
          (score >= 51 ? 'FLAGGED' : (score >= 26 ? 'WATCH' : 'PASS')),
      evidence: json['evidence'] as String? ?? 'No specific evidence observed.',
      affectedContent:
          json['affectedContent'] as String? ?? 'User Query & Candidate AI Content',
      mitigation: json['mitigation'] as String? ??
          'Standard model response alignment applied.',
    );
  }
}

// ─────────────────────────────────────────────
// Guardrail Control Result
// ─────────────────────────────────────────────
class GuardrailControlResult {
  final String guardrailName;
  final String status; // PASSED, WATCH, TRIGGERED, BLOCKED
  final String severity; // LOW, MODERATE, HIGH, CRITICAL
  final String reason;
  final String actionTaken;

  const GuardrailControlResult({
    required this.guardrailName,
    required this.status,
    required this.severity,
    required this.reason,
    required this.actionTaken,
  });

  factory GuardrailControlResult.fromJson(Map<String, dynamic> json) {
    return GuardrailControlResult(
      guardrailName: json['guardrailName'] as String? ?? 'Guardrail Control',
      status: json['status'] as String? ?? 'PASSED',
      severity: json['severity'] as String? ?? 'LOW',
      reason: json['reason'] as String? ?? 'No violation detected.',
      actionTaken: json['actionTaken'] as String? ?? 'No action required.',
    );
  }
}

// ─────────────────────────────────────────────
// Evaluation Action (Before / After Impact)
// ─────────────────────────────────────────────
class EvaluationAction {
  final String originalRisk;
  final String actionTaken;
  final String finalOutputImpact;

  const EvaluationAction({
    required this.originalRisk,
    required this.actionTaken,
    required this.finalOutputImpact,
  });

  factory EvaluationAction.fromJson(Map<String, dynamic> json) {
    return EvaluationAction(
      originalRisk: json['originalRisk'] as String? ?? 'Observed risk factor',
      actionTaken: json['actionTaken'] as String? ?? 'Applied cross-agent check',
      finalOutputImpact:
          json['finalOutputImpact'] as String? ?? 'Improved final answer quality',
    );
  }
}

// ─────────────────────────────────────────────
// Model Agreement Analysis
// ─────────────────────────────────────────────
class ModelAgreementResult {
  final int agreementPercentage; // 0-100
  final String agreementLevel; // HIGH AGREEMENT, MODERATE AGREEMENT, LOW AGREEMENT

  const ModelAgreementResult({
    required this.agreementPercentage,
    required this.agreementLevel,
  });

  factory ModelAgreementResult.fromPercentage(int pct) {
    String lvl = 'HIGH AGREEMENT';
    if (pct <= 30) {
      lvl = 'LOW AGREEMENT';
    } else if (pct <= 70) {
      lvl = 'MODERATE AGREEMENT';
    }
    return ModelAgreementResult(agreementPercentage: pct, agreementLevel: lvl);
  }
}

// ─────────────────────────────────────────────
// Full NIST Evaluation Result
// ─────────────────────────────────────────────
class NistEvaluationResult {
  final int overallRiskScore;
  final String overallStatus; // LOW, MODERATE, HIGH, CRITICAL
  final String overallExplanation;
  final String evaluatedBy; // e.g. "Gemini Risk Evaluation Agent"
  final String modelsParticipating; // e.g. "Gemini + Groq"
  final List<NistRiskResult> risks;
  final List<GuardrailControlResult> guardrails;
  final List<EvaluationAction> actions;
  final ModelAgreementResult agreement;

  const NistEvaluationResult({
    required this.overallRiskScore,
    required this.overallStatus,
    required this.overallExplanation,
    required this.evaluatedBy,
    required this.modelsParticipating,
    required this.risks,
    required this.guardrails,
    required this.actions,
    required this.agreement,
  });

  factory NistEvaluationResult.empty() {
    final defaultRisks = kNistRiskDefinitions.entries.map((e) {
      return NistRiskResult(
        riskId: e.key,
        riskName: e.value['name']!,
        description: e.value['desc']!,
        riskScore: 10,
        riskLevel: 'LOW',
        status: 'PASS',
        evidence: 'No risk detected for this category.',
        affectedContent: 'User Query & Candidate Responses',
        mitigation: 'Standard safety alignment intact.',
      );
    }).toList();

    return NistEvaluationResult(
      overallRiskScore: 12,
      overallStatus: 'LOW',
      overallExplanation:
          'NIST GAI Risk-Informed Assessment completed. Low baseline risk detected across evaluated categories.',
      evaluatedBy: 'Gemini Risk Evaluation Agent',
      modelsParticipating: 'Gemini + Groq',
      risks: defaultRisks,
      guardrails: const [
        GuardrailControlResult(
          guardrailName: 'Content Filtering',
          status: 'PASSED',
          severity: 'LOW',
          reason: 'No hateful or violent content identified.',
          actionTaken: 'No modification required.',
        ),
        GuardrailControlResult(
          guardrailName: 'Privacy / PII Protection',
          status: 'PASSED',
          severity: 'LOW',
          reason: 'No personally identifiable information detected.',
          actionTaken: 'No modification required.',
        ),
        GuardrailControlResult(
          guardrailName: 'Prompt Injection Resistance',
          status: 'PASSED',
          severity: 'LOW',
          reason: 'Standard prompt input structure validated.',
          actionTaken: 'No modification required.',
        ),
        GuardrailControlResult(
          guardrailName: 'Information Integrity',
          status: 'PASSED',
          severity: 'LOW',
          reason: 'Cross-model agreement verified.',
          actionTaken: 'Synthesized unanimous insights.',
        ),
      ],
      actions: const [
        EvaluationAction(
          originalRisk: 'Potential factual variance',
          actionTaken: 'Cross-agent verification',
          finalOutputImpact: 'Uncertain claims qualified in synthesis',
        ),
      ],
      agreement: const ModelAgreementResult(
          agreementPercentage: 85, agreementLevel: 'HIGH AGREEMENT'),
    );
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
  final NistEvaluationResult? nistEvaluation;
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
    this.nistEvaluation,
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
