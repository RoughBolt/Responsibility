# 🏛️ AI COUNCIL

**Multiple AI Perspectives. One Better Answer.**

AI Council is a multi-agent AI collaboration and deliberation system built with Flutter. It submits user queries to independent frontier AI models (Gemini & Groq), compares their insights, evaluates responses against the **NIST GAI Risk-Informed Assessment Board (12 Risk Categories)**, performs safety checks, and synthesizes a unified consensus answer.

---

## 🗺️ User Flow Chart

The following diagram illustrates the complete user journey and interactive pipeline within the application:

```mermaid
flowchart TD
    %% Styling
    classDef startEnd fill:#7C6EFF,stroke:#fff,stroke-width:2px,color:#fff;
    classDef process fill:#151532,stroke:#7C6EFF,stroke-width:1px,color:#fff;
    classDef decision fill:#101026,stroke:#00D4AA,stroke-width:2px,color:#fff;
    classDef pipeline fill:#1B104F,stroke:#00D4AA,stroke-width:1px,color:#fff;
    classDef result fill:#00D4AA,stroke:#fff,stroke-width:2px,color:#000;

    A([🚀 Launch AI Council App]):::startEnd --> B{API Keys Configured?}:::decision
    
    B -- No --> C[🔑 Open Key Setup Dialog]:::process
    C --> D[Input Gemini / Groq API Keys]:::process
    D --> E[Save Keys to App State / .env]:::process
    E --> F[📱 Home Screen Dashboard]:::process

    B -- Yes --> F

    F --> G[✍️ Select Sample Prompt OR Type Question]:::process
    G --> H[⚡ Tap 'CONSULT THE COUNCIL']:::process

    H --> I[⏳ Processing / Deliberation Screen]:::process

    subgraph Pipeline ["⚙️ 7-Step Multi-Agent Pipeline"]
        direction TB
        P1["1️⃣ Parallel Agent Queries (Gemini & Groq)"]:::pipeline
        P2["2️⃣ Compare Viewpoints (Agreements & Gaps)"]:::pipeline
        P3["3️⃣ Controlled Critique & Debate Round"]:::pipeline
        P4["4️⃣ NIST AI Evaluation Board (12 GAI Risks)"]:::pipeline
        P5["5️⃣ Responsible AI Safety Check"]:::pipeline
        P6["6️⃣ Consensus Synthesis Engine"]:::pipeline

        P1 --> P2 --> P3 --> P4 --> P5 --> P6
    end

    I --> Pipeline
    Pipeline --> J[📊 Result Screen Dashboard]:::result

    J --> K["📑 Tab 1: Final Consensus Answer (One-Tap Copy)"]:::process
    J --> L["🛡️ Tab 2: NIST Evaluation Board (12 Risk Categories)"]:::process
    J --> M["🤖 Tab 3: Individual Perspectives (Gemini & Groq)"]:::process

    K & L & M --> N[🔄 Tap 'Ask Another Question']:::process
    N --> F
```

---

## ⚡ Multi-Agent Pipeline Architecture

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Flutter UI
    participant Orchestrator
    participant Gemini (Analyst)
    participant Groq (Critical Thinker)

    User->>Flutter UI: Input Query & Submit
    Flutter UI->>Orchestrator: Dispatch Prompt
    
    par Parallel Execution
        Orchestrator->>Gemini (Analyst): Fetch Independent Perspective
        Orchestrator->>Groq (Critical Thinker): Fetch Independent Perspective
    end
    
    Gemini (Analyst)-->>Orchestrator: Perspective Output
    Groq (Critical Thinker)-->>Orchestrator: Perspective Output
    
    Orchestrator->>Gemini (Analyst): Compare Viewpoints (Agreements & Disagreements)
    Gemini (Analyst)-->>Orchestrator: Structured Comparison JSON
    
    Orchestrator->>Groq (Critical Thinker): Critique & Debate Round
    Groq (Critical Thinker)-->>Orchestrator: Structured Critique JSON

    Orchestrator->>Gemini (Analyst): NIST GAI Evaluation (12 Risk Categories)
    Gemini (Analyst)-->>Orchestrator: Risk Assessment Scores & Mitigation
    
    Orchestrator->>Gemini (Analyst): Responsible AI Safety Validation
    Gemini (Analyst)-->>Orchestrator: Safety Check Status (SAFE/FLAGGED)

    Orchestrator->>Gemini (Analyst): Synthesize Final Consensus
    Gemini (Analyst)-->>Orchestrator: Unified Synthesis Output

    Orchestrator-->>Flutter UI: Stream Deliberation Steps & Render Results
    Flutter UI-->>User: Display Consensus, NIST Board, & Perspectives
```

---

## 🌟 Key Features

1. **Multi-Agent Diversity:** Integrates Google Gemini (`gemini-1.5-flash`) as the Primary Analyst & Synthesizer, and Groq (`llama-3.3-70b-versatile`) as the Critical Thinker.
2. **NIST AI Evaluation Board:** Vets AI outputs against the 12 NIST GAI Risk-Informed Categories (Confabulation, Information Integrity, Information Security, Data Privacy, Harmful Bias, CBRN, etc.).
3. **Response Comparison & Critique:** Identifies common ground, surfaces conflicting perspectives, and executes controlled critique loops to eliminate blind spots.
4. **Single-Provider Fallback:** Seamlessly operates with a single provider if only one key is available without fabricating consensus.
5. **Modern Dark Glassmorphism UI:** Built with Material 3, Google Fonts (Inter), smooth animations, tabbed results, and one-tap copy functionality.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (>=3.13.2)
- Google Chrome or Android Studio / Emulator

### 1. Clone & Set Up Environment
Create a `.env` file in the project root:
```env
GEMINI_API_KEY=your_gemini_api_key_here
GROQ_API_KEY=your_groq_api_key_here
```

### 2. Install Dependencies
```bash
cd ai_council
flutter pub get
```

### 3. Run on Chrome
```bash
flutter run -d chrome
```

---

## 🧪 Testing & Code Quality

Run tests and static analysis:
```bash
flutter test
flutter analyze
```

---

## 📜 License
Developed for Hackathon MVP demonstration.
