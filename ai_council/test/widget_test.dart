import 'package:flutter_test/flutter_test.dart';
import 'package:ai_council/models.dart';

void main() {
  test('AgentConfig role and presentation test', () {
    const agent = AgentConfig(
      id: 'gemini',
      displayName: 'Gemini',
      role: AgentRole.analyst,
      status: ProviderStatus.available,
      modelName: 'gemini-3.5-flash',
    );
    expect(agent.roleLabel, 'Primary Analyst');
    expect(agent.displayName, 'Gemini');
  });

  test('NistEvaluationResult empty factory initializes 12 GAI risks', () {
    final result = NistEvaluationResult.empty();
    expect(result.risks.length, 12);
    expect(result.risks.first.riskId, 1);
    expect(result.risks.first.riskName, 'CBRN Information or Capabilities');
    expect(result.risks[1].riskName, 'Confabulation');
    expect(result.overallRiskScore, 12);
    expect(result.overallStatus, 'LOW');
    expect(result.agreement.agreementLevel, 'HIGH AGREEMENT');
  });

  test('NistRiskResult custom score level calculation', () {
    final highRiskJson = {
      'riskName': 'Confabulation',
      'riskScore': 65,
      'evidence': 'Conflicting claims detected',
      'affectedContent': 'Candidate AI Responses',
      'mitigation': 'Cross-verify facts in final synthesizer',
    };
    final parsed = NistRiskResult.fromJson(highRiskJson, 2, 'Confabulation', 'Description');
    expect(parsed.riskScore, 65);
    expect(parsed.riskLevel, 'HIGH');
    expect(parsed.status, 'FLAGGED');
  });

  test('CouncilResult single vs multi-provider mode helper', () {
    final singleResult = CouncilResult(
      userPrompt: 'Test prompt',
      agentResponses: [
        AgentResponse.succeeded(
          const AgentConfig(
            id: 'gemini',
            displayName: 'Gemini',
            role: AgentRole.analyst,
            status: ProviderStatus.available,
          ),
          'Single response',
          const Duration(milliseconds: 500),
        ),
      ],
      participatingAgentCount: 1,
      totalConfiguredCount: 1,
    );
    expect(singleResult.isSingleProviderMode, isTrue);

    final multiResult = CouncilResult(
      userPrompt: 'Test prompt',
      agentResponses: [
        AgentResponse.succeeded(
          const AgentConfig(
            id: 'gemini',
            displayName: 'Gemini',
            role: AgentRole.analyst,
            status: ProviderStatus.available,
          ),
          'Resp 1',
          const Duration(milliseconds: 500),
        ),
        AgentResponse.succeeded(
          const AgentConfig(
            id: 'groq',
            displayName: 'Groq',
            role: AgentRole.criticalThinker,
            status: ProviderStatus.available,
          ),
          'Resp 2',
          const Duration(milliseconds: 400),
        ),
      ],
      participatingAgentCount: 2,
      totalConfiguredCount: 2,
    );
    expect(multiResult.isSingleProviderMode, isFalse);
  });
}
