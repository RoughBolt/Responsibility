import 'package:flutter_test/flutter_test.dart';
import 'package:ai_council/models.dart';
import 'package:ai_council/providers.dart';

void main() {
  test('AgentConfig role and presentation test', () {
    final agent = AgentConfig(
      id: 'gemini',
      displayName: 'Gemini',
      role: AgentRole.analyst,
      status: ProviderStatus.available,
      modelName: 'gemini-1.5-flash',
    );
    expect(agent.roleLabel, 'Primary Analyst');
    expect(agent.displayName, 'Gemini');
  });

  test('ProviderRegistry builds configs with expected initial statuses', () {
    final configs = ProviderRegistry.buildAgentConfigs();
    expect(configs.length, 3);
    expect(configs[0].id, 'gemini');
    expect(configs[1].id, 'groq');
    expect(configs[2].id, 'openrouter');
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
