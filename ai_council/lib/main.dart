import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'providers.dart';
import 'orchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await ApiConfig.loadEnv();
  runApp(const AiCouncilApp());
}

// ─────────────────────────────────────────────
// CONSTANTS & THEME
// ─────────────────────────────────────────────
const kBg = Color(0xFF080816);
const kSurface = Color(0xFF101026);
const kCard = Color(0xFF151532);
const kPrimary = Color(0xFF7C6EFF);
const kAccent = Color(0xFF00D4AA);
const kDanger = Color(0xFFFF4757);
const kWarning = Color(0xFFFFB020);
const kSuccess = Color(0xFF00E676);

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────
class AiCouncilApp extends StatelessWidget {
  const AiCouncilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Council',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kPrimary,
          secondary: kAccent,
          surface: kSurface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _promptCtrl = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  static const _samplePrompts = [
    ('🤖 Will AI replace software engineers?', 'Will AI replace software engineers?'),
    ('📈 Growth vs Profitability', 'Should startups prioritize growth or profitability?'),
    ('🧠 Multi-Agent AI Benefits & Risks', 'Explain the benefits and risks of multi-agent AI systems.'),
    ('📱 Learn Flutter in 30 Days', 'Create a practical plan to learn Flutter in 30 days.'),
    ('⚠️ Reliance on AI Hallucinations', 'What are the biggest risks of relying on AI-generated information?'),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question for the council.'),
          backgroundColor: kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final agents = ProviderRegistry.buildAgentConfigs();
    final hasConfigured = agents.any((a) => a.status == ProviderStatus.available);
    if (!hasConfigured) {
      _showKeyConfigDialog();
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, sec) => ProcessingScreen(userPrompt: prompt),
        transitionsBuilder: (ctx, anim, sec, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => setState(() => _isSubmitting = false));
  }

  void _showKeyConfigDialog() {
    final geminiCtrl = TextEditingController(text: ApiConfig.geminiKey);
    final groqCtrl = TextEditingController(text: ApiConfig.groqKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: kPrimary, size: 22),
            const SizedBox(width: 8),
            Text('Configure AI Keys', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure your API key in .env or paste below.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _buildKeyField('Gemini API Key (Primary)', geminiCtrl, 'GEMINI_API_KEY'),
              const SizedBox(height: 12),
              _buildKeyField('Groq API Key (Critical Thinker)', groqCtrl, 'GROQ_API_KEY'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                ApiConfig.geminiKey = geminiCtrl.text.trim();
                ApiConfig.groqKey = groqCtrl.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API Keys saved! Ready to consult.'), backgroundColor: kCard),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Save Keys'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: kCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final agents = ProviderRegistry.buildAgentConfigs();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildAgentStatus(agents),
                    const SizedBox(height: 28),
                    _buildPromptSection(),
                    const SizedBox(height: 20),
                    _buildSamplePrompts(),
                    const SizedBox(height: 32),
                    _buildConsultButton(),
                    const SizedBox(height: 24),
                    _buildPipelinePreview(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: kBg,
      actions: [
        IconButton(
          icon: const Icon(Icons.key_rounded, color: Colors.white70),
          tooltip: 'Configure API Keys',
          onPressed: _showKeyConfigDialog,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B104F), kBg],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _CouncilIcon(size: 46),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI COUNCIL',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Multiple AI Perspectives + NIST Risk Evaluation Board',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white54,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentStatus(List<AgentConfig> agents) {
    // Only display Gemini and Groq per 2-Agent MVP specification
    final activeAgents = agents.where((a) => a.id == 'gemini' || a.id == 'groq').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('COUNCIL MEMBERS'),
            GestureDetector(
              onTap: _showKeyConfigDialog,
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 12, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Setup Keys',
                    style: GoogleFonts.inter(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: activeAgents.map((agent) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _AgentStatusChip(
                  name: agent.displayName,
                  role: agent.roleLabel,
                  available: agent.status == ProviderStatus.available,
                  icon: agent.id == 'gemini'
                      ? Icons.psychology_rounded
                      : Icons.bolt_rounded,
                ),
              ),
            );
          }).toList(),
        ),
        if (!activeAgents.any((a) => a.status == ProviderStatus.available))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kWarning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: kWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API keys loaded in .env or tap "Setup Keys" above to activate council.',
                      style: GoogleFonts.inter(fontSize: 12, color: kWarning),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('ASK THE COUNCIL'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            key: const Key('prompt_input'),
            controller: _promptCtrl,
            maxLines: 5,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Ask a question and let multiple AI agents analyze and evaluate it against NIST risk guardrails...',
              hintStyle: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSamplePrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('TRY A SAMPLE'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _samplePrompts.map(
            (p) => ActionChip(
              label: Text(
                p.$1,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              onPressed: () => setState(() => _promptCtrl.text = p.$2),
              backgroundColor: kCard,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildConsultButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimary, Color(0xFF00B8D9)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          key: const Key('consult_button'),
          onPressed: _isSubmitting ? null : _submitPrompt,
          icon: const Icon(Icons.account_balance_rounded, size: 22),
          label: Text(
            'CONSULT THE COUNCIL',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPipelinePreview() {
    final stages = [
      (Icons.psychology_outlined, 'Gathering independent perspectives (Gemini & Groq)'),
      (Icons.compare_arrows_rounded, 'Comparing viewpoints (agreements & gaps)'),
      (Icons.gavel_rounded, 'Controlled critique & debate round'),
      (Icons.shield_outlined, 'NIST AI Evaluation Board (12 GAI Risks & Guardrails)'),
      (Icons.verified_user_outlined, 'Responsible AI safety check'),
      (Icons.auto_awesome_rounded, 'Building final consensus answer with mitigation'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schema_outlined, color: kAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'THE COUNCIL PIPELINE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...stages.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.$1, color: kPrimary, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Step ${i + 1}  ·  ${s.$2}',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROCESSING SCREEN
// ─────────────────────────────────────────────
class ProcessingScreen extends StatefulWidget {
  final String userPrompt;
  const ProcessingScreen({super.key, required this.userPrompt});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _orchestrator = CouncilOrchestrator();
  PipelineUpdate? _currentUpdate;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  void _startPipeline() {
    _orchestrator.runPipeline(widget.userPrompt).listen(
      (update) {
        if (!mounted) return;
        setState(() => _currentUpdate = update);
        if (update.stage == PipelineStage.done && !_navigated) {
          _navigated = true;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (ctx, anim, sec) => ResultScreen(result: update.finalResult!),
              transitionsBuilder: (ctx, anim, sec, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _currentUpdate = PipelineUpdate(
              stage: PipelineStage.failed,
              agentResponses: [],
              statusMessage: 'Pipeline error: $e',
            );
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final update = _currentUpdate;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _CouncilIcon(size: 52),
              const SizedBox(height: 18),
              Text(
                'THE COUNCIL IS DELIBERATING',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                update?.statusMessage ?? 'Initializing pipeline...',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (update != null) ...[
                ...update.agentResponses.map((r) => _AgentProgressTile(response: r)),
                const SizedBox(height: 24),
                _StagePill(
                  label: 'Comparing Viewpoints (Agreements & Gaps)',
                  active: update.stage == PipelineStage.comparing,
                  done: update.stage.index > PipelineStage.comparing.index,
                ),
                const SizedBox(height: 8),
                _StagePill(
                  label: 'Controlled Critique Round',
                  active: update.stage == PipelineStage.critiquing,
                  done: update.stage.index > PipelineStage.critiquing.index,
                ),
                const SizedBox(height: 8),
                _StagePill(
                  label: 'NIST AI Evaluation Board (12 Risks & Guardrails)',
                  active: update.stage == PipelineStage.nistEvaluation,
                  done: update.stage.index > PipelineStage.nistEvaluation.index,
                ),
                const SizedBox(height: 8),
                _StagePill(
                  label: 'Responsible AI Safety Check',
                  active: update.stage == PipelineStage.safetyCheck,
                  done: update.stage.index > PipelineStage.safetyCheck.index,
                ),
                const SizedBox(height: 8),
                _StagePill(
                  label: 'Synthesizing Consensus Answer',
                  active: update.stage == PipelineStage.synthesizing,
                  done: update.stage.index > PipelineStage.synthesizing.index,
                ),
              ] else
                const CircularProgressIndicator(color: kPrimary),
              const Spacer(),
              if (update?.stage == PipelineStage.failed) ...[
                OutlinedButton.icon(
                  key: const Key('retry_button'),
                  onPressed: () {
                    setState(() {
                      _currentUpdate = null;
                      _navigated = false;
                    });
                    _startPipeline();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Deliberation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Return to Home', style: GoogleFonts.inter(color: Colors.white54)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RESULT SCREEN WITH NIST EVALUATION TAB SYSTEM
// ─────────────────────────────────────────────
class ResultScreen extends StatefulWidget {
  final CouncilResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _selectedTab = 0; // 0: Final Consensus, 1: NIST Evaluation Board, 2: Individual Perspectives
  final Set<String> _expandedAgents = {};
  final Set<int> _expandedNistRisks = {2, 8, 9}; // Expand Confabulation, Integrity, Security by default

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    if (widget.result.successfulResponses.isNotEmpty) {
      _expandedAgents.add(widget.result.successfulResponses.first.agent.id);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildResultAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  children: [
                    _buildMeta(r),
                    const SizedBox(height: 16),
                    _buildTabSelector(),
                    const SizedBox(height: 20),
                    if (_selectedTab == 0) _buildConsensusTab(r),
                    if (_selectedTab == 1) _buildNistEvaluationBoardTab(r),
                    if (_selectedTab == 2) _buildPerspectivesTab(r),
                    const SizedBox(height: 32),
                    _buildAskAnotherButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: kBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      title: Row(
        children: [
          _CouncilIcon(size: 28),
          const SizedBox(width: 10),
          Text(
            'AI COUNCIL RESULT',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(CouncilResult r) {
    final safetyStatus = r.safety?.status;
    Color safetyColor = kAccent;
    if (safetyStatus == SafetyStatus.flagged) safetyColor = kWarning;
    if (safetyStatus == SafetyStatus.blocked) safetyColor = kDanger;

    final nistScore = r.nistEvaluation?.overallRiskScore ?? 12;
    Color nistColor = kSuccess;
    if (nistScore >= 51) {
      nistColor = kDanger;
    } else if (nistScore >= 26) {
      nistColor = kWarning;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaBadge(
          icon: Icons.groups_rounded,
          label: '${r.participatingAgentCount} / 2 Agents Responded',
          color: kPrimary,
        ),
        _MetaBadge(
          icon: Icons.shield_rounded,
          label: 'NIST Risk Score: $nistScore/100',
          color: nistColor,
        ),
        if (safetyStatus != null)
          _MetaBadge(
            icon: Icons.verified_user_outlined,
            label: r.safety!.statusLabel,
            color: safetyColor,
          ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _TabButton(
            title: 'FINAL ANSWER',
            icon: Icons.auto_awesome_rounded,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _TabButton(
            title: 'NIST BOARD',
            icon: Icons.shield_outlined,
            isSelected: _selectedTab == 1,
            badge: '12 RISKS',
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _TabButton(
            title: 'AGENTS',
            icon: Icons.psychology_rounded,
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 0: FINAL CONSENSUS & INSIGHTS
  // ─────────────────────────────────────────────
  Widget _buildConsensusTab(CouncilResult r) {
    return Column(
      children: [
        _buildFinalAnswerCard(r),
        const SizedBox(height: 16),
        _buildNistQuickBanner(r),
        const SizedBox(height: 16),
        if (r.analysis != null) _buildCouncilInsights(r),
        const SizedBox(height: 16),
        if (r.safety != null) _buildSafetyCard(r.safety!),
      ],
    );
  }

  Widget _buildFinalAnswerCard(CouncilResult r) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withValues(alpha: 0.12),
            kAccent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPrimary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'FINAL CONSENSUS ANSWER',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.isSingleProviderMode ? 'Synthesized Perspective' : 'Consensus of ${r.participatingAgentCount} Models',
                    style: GoogleFonts.inter(fontSize: 11, color: kAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              r.finalAnswer ?? 'No final answer synthesized. Review individual responses below.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white,
                height: 1.75,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: r.finalAnswer == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: r.finalAnswer!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Final Consensus Answer copied to clipboard!'),
                            backgroundColor: kCard,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy_rounded, size: 14, color: kAccent),
                label: Text(
                  'Copy Answer',
                  style: GoogleFonts.inter(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: kAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNistQuickBanner(CouncilResult r) {
    final nist = r.nistEvaluation ?? NistEvaluationResult.empty();
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = 1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: kAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NIST GAI Risk-Informed Assessment',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Overall Risk: ${nist.overallRiskScore}/100 (${nist.overallStatus}) · 12 Categories Audited',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: kAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildCouncilInsights(CouncilResult r) {
    final analysis = r.analysis!;
    final critique = r.critique;

    return _ResultCard(
      title: 'COUNCIL INSIGHTS',
      icon: Icons.insights_rounded,
      iconColor: const Color(0xFF9C88FF),
      child: Column(
        children: [
          if (analysis.agreements.isNotEmpty) ...[
            _InsightSection(label: '✓ AGREEMENTS', color: kSuccess, items: analysis.agreements),
            const SizedBox(height: 14),
          ],
          if (analysis.disagreements.isNotEmpty) ...[
            _InsightSection(label: '↔ DISAGREEMENTS', color: kWarning, items: analysis.disagreements),
            const SizedBox(height: 14),
          ],
          if (analysis.uniqueInsights.isNotEmpty) ...[
            _InsightSection(label: '💡 UNIQUE INSIGHTS', color: kAccent, items: analysis.uniqueInsights),
            const SizedBox(height: 14),
          ],
          if (analysis.missingInformation.isNotEmpty) ...[
            _InsightSection(label: '⚠ MISSING INFORMATION', color: kWarning, items: analysis.missingInformation),
            const SizedBox(height: 14),
          ],
          if (critique != null && critique.recommendation.isNotEmpty)
            _InsightSection(label: '🎯 CRITIQUE RECOMMENDATION', color: kPrimary, items: [critique.recommendation]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: NIST AI EVALUATION BOARD
  // ─────────────────────────────────────────────
  Widget _buildNistEvaluationBoardTab(CouncilResult r) {
    final nist = r.nistEvaluation ?? NistEvaluationResult.empty();

    Color statusColor = kSuccess;
    if (nist.overallRiskScore >= 76) {
      statusColor = kDanger;
    } else if (nist.overallRiskScore >= 51) {
      statusColor = kWarning;
    } else if (nist.overallRiskScore >= 26) {
      statusColor = const Color(0xFFFF9F43);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disclaimer Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIST GAI Risk-Informed Assessment',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'AI-Assisted Prototype Evaluation — Not an official NIST certification.',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 1: Overall Risk Assessment Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed_rounded, color: kAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'OVERALL RISK ASSESSMENT',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1.2),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${nist.overallStatus} RISK',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${nist.overallRiskScore}',
                    style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                  Text(
                    ' / 100',
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white38, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    'AI Agreement: ${nist.agreement.agreementPercentage}%',
                    style: GoogleFonts.inter(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: nist.overallRiskScore / 100.0,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                nist.overallExplanation,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 2: Evaluation Scope Summary
        _ResultCard(
          title: 'EVALUATION SCOPE SUMMARY',
          icon: Icons.checklist_rtl_rounded,
          iconColor: kAccent,
          child: Column(
            children: [
              _ScopeRow('USER PROMPT EVALUATED', true),
              _ScopeRow('GEMINI RESPONSE EVALUATED', r.successfulResponses.any((s) => s.agent.id == 'gemini')),
              _ScopeRow('GROQ RESPONSE EVALUATED', r.successfulResponses.any((s) => s.agent.id == 'groq')),
              _ScopeRow('FINAL CONSENSUS EVALUATED', r.finalAnswer != null),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 3: 12 NIST GAI Risk Matrix
        _ResultCard(
          title: 'NIST GAI RISK MATRIX (12 CATEGORIES)',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF9C88FF),
          child: Column(
            children: nist.risks.map((risk) {
              final isExpanded = _expandedNistRisks.contains(risk.riskId);
              return _NistRiskCard(
                risk: risk,
                isExpanded: isExpanded,
                onToggle: () => setState(() {
                  if (isExpanded) {
                    _expandedNistRisks.remove(risk.riskId);
                  } else {
                    _expandedNistRisks.add(risk.riskId);
                  }
                }),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Section 4: Active Guardrail Checks
        _ResultCard(
          title: 'ACTIVE GUARDRAIL CHECKS',
          icon: Icons.verified_user_outlined,
          iconColor: kSuccess,
          child: Column(
            children: nist.guardrails.map((g) => _GuardrailTile(control: g)).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Section 5: AI Council Actions (Before / After Impact)
        _ResultCard(
          title: 'AI COUNCIL MITIGATION ACTIONS',
          icon: Icons.alt_route_rounded,
          iconColor: kWarning,
          child: Column(
            children: nist.actions.map((act) => _ActionTile(action: act)).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Section 6: Model Agreement Analysis
        _ResultCard(
          title: 'MODEL AGREEMENT ANALYSIS',
          icon: Icons.handshake_outlined,
          iconColor: kPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agreement Score: ${nist.agreement.agreementPercentage}%',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      nist.agreement.agreementLevel,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'AI-generated agreement estimate based on semantic cross-model comparison.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 7: Evaluation Transparency Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Evaluated by: ${nist.evaluatedBy} · Participating: ${nist.modelsParticipating}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: INDIVIDUAL AGENT PERSPECTIVES
  // ─────────────────────────────────────────────
  Widget _buildPerspectivesTab(CouncilResult r) {
    final responses = r.successfulResponses;
    if (responses.isEmpty) {
      return const Center(child: Text('No successful agent responses available.'));
    }

    return Column(
      children: responses.asMap().entries.map((entry) {
        final i = entry.key;
        final resp = entry.value;
        final isExpanded = _expandedAgents.contains(resp.agent.id);
        return Padding(
          padding: EdgeInsets.only(bottom: i < responses.length - 1 ? 12 : 0),
          child: _AgentResponseCard(
            response: resp,
            isExpanded: isExpanded,
            onToggle: () => setState(() {
              if (isExpanded) {
                _expandedAgents.remove(resp.agent.id);
              } else {
                _expandedAgents.add(resp.agent.id);
              }
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSafetyCard(SafetyResult safety) {
    Color statusColor;
    IconData statusIcon;
    switch (safety.status) {
      case SafetyStatus.safe:
        statusColor = kSuccess;
        statusIcon = Icons.check_circle_rounded;
      case SafetyStatus.flagged:
        statusColor = kWarning;
        statusIcon = Icons.warning_rounded;
      case SafetyStatus.blocked:
        statusColor = kDanger;
        statusIcon = Icons.block_rounded;
      case SafetyStatus.unknown:
        statusColor = Colors.white38;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '🛡 SAFETY CHECK',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      safety.statusLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            safety.reason,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                'Mechanism: ${safety.mechanism}',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAskAnotherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        key: const Key('ask_another_button'),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(
          'Ask Another Question',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE COMPONENTS FOR NIST BOARD & UI
// ─────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? kPrimary : Colors.white54;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? kPrimary.withValues(alpha: 0.4) : Colors.transparent),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Text(
                  badge!,
                  style: GoogleFonts.inter(fontSize: 8, color: kAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  final String label;
  final bool evaluated;
  const _ScopeRow(this.label, this.evaluated);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            evaluated ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: evaluated ? kSuccess : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: evaluated ? Colors.white : Colors.white38,
              fontWeight: evaluated ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _NistRiskCard extends StatelessWidget {
  final NistRiskResult risk;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _NistRiskCard({
    required this.risk,
    required this.isExpanded,
    required this.onToggle,
  });

  Color get _levelColor {
    switch (risk.riskLevel) {
      case 'CRITICAL':
        return kDanger;
      case 'HIGH':
        return kDanger;
      case 'MODERATE':
        return kWarning;
      case 'LOW':
      default:
        return kSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _levelColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _levelColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${risk.riskId}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _levelColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          risk.riskName,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${risk.riskScore}/100 · ${risk.riskLevel}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _levelColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: risk.riskScore / 100.0,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      color: _levelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 6),
                  _NistDetailField('DESCRIPTION', risk.description, Colors.white70),
                  const SizedBox(height: 8),
                  _NistDetailField('EVIDENCE', risk.evidence, kAccent),
                  const SizedBox(height: 8),
                  _NistDetailField('AFFECTED CONTENT', risk.affectedContent, Colors.white54),
                  const SizedBox(height: 8),
                  _NistDetailField('MITIGATION ACTION', risk.mitigation, _levelColor),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NistDetailField extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _NistDetailField(this.label, this.content, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
        ),
      ],
    );
  }
}

class _GuardrailTile extends StatelessWidget {
  final GuardrailControlResult control;
  const _GuardrailTile({required this.control});

  Color get _statusColor {
    switch (control.status) {
      case 'BLOCKED':
        return kDanger;
      case 'TRIGGERED':
        return kDanger;
      case 'WATCH':
        return kWarning;
      case 'PASSED':
      default:
        return kSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _statusColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      control.guardrailName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      control.status,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor),
                    ),
                  ],
                ),
                Text(
                  'Reason: ${control.reason} · Action: ${control.actionTaken}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final EvaluationAction action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: kWarning),
                const SizedBox(width: 6),
                Text(
                  'RISK: ${action.originalRisk}',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: kWarning),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Action Taken: ${action.actionTaken}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
            Text(
              'Final Output Impact: ${action.finalOutputImpact}',
              style: GoogleFonts.inter(fontSize: 11, color: kAccent, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouncilIcon extends StatelessWidget {
  final double size;
  const _CouncilIcon({this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _AgentStatusChip extends StatelessWidget {
  final String name;
  final String role;
  final bool available;
  final IconData icon;

  const _AgentStatusChip({
    required this.name,
    required this.role,
    required this.available,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? kAccent : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: available ? Colors.white : Colors.white38,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role,
            style: GoogleFonts.inter(fontSize: 9, color: color),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            available ? 'READY' : 'NOT CONFIGURED',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentProgressTile extends StatelessWidget {
  final AgentResponse response;
  const _AgentProgressTile({required this.response});

  @override
  Widget build(BuildContext context) {
    final r = response;
    IconData icon;
    Color color;
    String label;

    if (r.isLoading) {
      icon = Icons.hourglass_empty_rounded;
      color = kWarning;
      label = 'Analyzing...';
    } else if (r.success) {
      icon = Icons.check_circle_rounded;
      color = kSuccess;
      label = 'Response Received';
    } else {
      icon = Icons.cancel_rounded;
      color = kDanger;
      label = r.error == 'Provider Not Configured' ? 'Not Configured' : 'Failed';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          r.isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: color, strokeWidth: 2),
                )
              : Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(
            r.agent.displayName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${r.agent.roleLabel})',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;

  const _StagePill({
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? kSuccess
        : active
            ? kPrimary
            : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (active)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            )
          else
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: color,
              size: 14,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: done || active ? Colors.white : Colors.white38,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;

  const _InsightSection({
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentResponseCard extends StatelessWidget {
  final AgentResponse response;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AgentResponseCard({
    required this.response,
    required this.isExpanded,
    required this.onToggle,
  });

  Color get _roleColor {
    switch (response.agent.role) {
      case AgentRole.analyst:
        return kPrimary;
      case AgentRole.criticalThinker:
        return const Color(0xFFFF9F43);
      case AgentRole.independentExpert:
        return kAccent;
    }
  }

  IconData get _icon {
    if (response.agent.id == 'gemini') return Icons.psychology_rounded;
    if (response.agent.id == 'groq') return Icons.bolt_rounded;
    return Icons.public_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _roleColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_icon, size: 16, color: _roleColor),
                  const SizedBox(width: 8),
                  Text(
                    response.agent.displayName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _roleColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${response.agent.roleLabel}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  ),
                  const Spacer(),
                  Text(
                    isExpanded ? 'Collapse' : 'Expand',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  response.response ?? response.error ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.65,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
