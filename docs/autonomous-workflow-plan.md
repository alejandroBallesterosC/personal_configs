# Autonomous Workflow Plugin — Implementation Plan

> Created: 2026-02-23
> Updated: 2026-02-24

## Problem Statement

Current dev-workflow workflows (TDD implementation, debug) are human-in-the-loop by design — specification interviews, user verification gates, plan approval. This is the right design for targeted development work. But there is a different class of work: **autonomous long-running research, planning, and execution** where Claude grinds for hours/days without supervision. These need a separate workflow.

### Use Cases

1. **Deep Research Only** — 10+ hours of internet research producing a LaTeX report. Scouring credible sources, reasoning through conflicts, verifying claims.
2. **Research + Plan** — Research thoroughly, then generate and iteratively refine an implementation plan for an ambitious software project.
3. **Research + Plan + Code** — Full autonomous execution: research, plan, then implement for 10-96+ hours without supervision.
4. **Implementation Only** — An existing research report and/or plan already exists (from a previous Mode 2 run, or written manually). Jump straight to TDD implementation for 2-96+ hours.

### Why Current Workflows Don't Fit

- TDD implementation has 6 human-gated phases before any code (explore, interview, architecture, plan, review, approval)
- Debug workflow has 3 human gates (describe, reproduce, verify)
- Both enforce single-active-workflow guards
- Neither supports LaTeX output
- Neither has phased research with diminishing-returns detection
- Neither supports multi-day autonomous execution without human interaction

## Dependencies

| Dependency | Required By | Install | Notes |
|---|---|---|---|
| ralph-loop plugin | All modes | `/plugin marketplace add alejandroBallesterosC/personal_configs && /plugin install ralph-loop` | Hard dependency. Drives iteration loop via Stop hook. |
| jq | Hooks, state parsing | `brew install jq` | Hard dependency. Hooks fail loudly if missing. |
| MacTeX | LaTeX compilation | `brew install --cask mactex-no-gui` | Required for PDF output. Install provides `pdflatex` and `bibtex`. Without it, `.tex` files are still generated but PDF compilation is skipped. |
| exa MCP server | Researcher agents | Configure in `.claude/settings.json` with `EXA_API_KEY` | Provides `web_search_exa`, `deep_researcher_start`, `crawling_exa`. Falls back to `WebSearch`/`WebFetch` if unavailable. |

**Cost awareness**: Autonomous workflows are expensive. Each ralph-loop iteration costs roughly $0.50-$3.00 depending on subagent count and model usage. A 30-iteration research run may cost $15-$90. A 100-iteration full-auto run may cost $50-$300. The state file tracks iteration counts per phase so you can estimate spend.

## Architecture

### Plugin Structure

```
claude-code/plugins/autonomous-workflow/
├── .claude-plugin/plugin.json
├── commands/
│   ├── research.md              # Mode 1: Research only → LaTeX report
│   ├── research-and-plan.md     # Mode 2: Research → Plan → LaTeX report
│   ├── full-auto.md             # Mode 3: Research → Plan → Code
│   ├── implement.md             # Mode 4: Code from existing plan
│   ├── continue-auto.md         # Resume any mode after interruption
│   └── help.md
├── agents/
│   ├── researcher.md            # Parallel internet research (Sonnet)
│   ├── repo-analyst.md          # Parallel repo analysis (Sonnet)
│   ├── latex-compiler.md        # LaTeX formatting + compilation (Sonnet)
│   ├── plan-architect.md        # Architecture/plan design (Opus)
│   ├── plan-critic.md           # Plan scrutiny/validation (Opus)
│   └── autonomous-coder.md      # Feature-by-feature TDD implementation (Opus)
├── skills/
│   └── autonomous-workflow-guide/SKILL.md
├── hooks/
│   ├── hooks.json
│   ├── auto-checkpoint.sh       # PreCompact hook: save transcript + state
│   ├── auto-resume.sh           # SessionStart hook: restore context after compact/clear
│   └── verify-state.sh          # Stop hook: verify state file accuracy
└── templates/
    ├── report-template.tex      # Base LaTeX template for research reports
    └── plan-template.tex        # Base LaTeX template for plans
```

### Relationship to Existing Plugins

- **Standalone plugin** — does not extend dev-workflow; installed independently
- **Uses ralph-loop** — same hard dependency as TDD workflow (Phases 7-9)
- **Shares conventions** — YAML frontmatter state files, ABOUTME comments, parallel subagent patterns
- **No conflicts** — different state file locations (`docs/research-*` vs `docs/workflow-*` vs `docs/debug/*`)
- **Own Stop hook** — cannot rely on dev-workflow's state verifier (it only scans `docs/workflow-*` and `docs/debug/*`)

## Mode 1: Deep Research (`/autonomous-workflow:research`)

### Invocation

```bash
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...'
" --max-iterations 30
```

### Each Iteration Cycle

1. **Read state** — Check `docs/research-<topic>/<topic>-state.md` for what's been done, what gaps remain
2. **Spawn 3-5 parallel Sonnet researcher agents** — each searches different facets of the topic via web search (exa, context7, WebSearch). Each returns a structured findings summary (200-500 words). Main instance never touches raw web content.
3. **Spawn 1-2 parallel Sonnet repo-analyst agents** (if repo has meaningful content) — analyze relevant code/docs in the repo. **Skip if the repo is empty or only contains the research artifacts themselves.** The command checks for non-research files before spawning repo-analysts.
4. **Synthesize** — Main Opus instance integrates new findings into the running report, resolves conflicts between sources, identifies gaps and contradictions
5. **Update LaTeX document** — Write/update `docs/research-<topic>/<topic>-report.tex` incrementally
6. **Update state file** — Track iteration count, sources cited, sections completed, open questions, new findings this iteration
7. **Identify next research directions** — What gaps remain? What claims need verification? What contradictions need resolution?

### Context Management Strategy

This is the hardest part of long-running research. After 30 iterations, the main context will be enormous without discipline.

**Principle: Subagents absorb ALL raw data.** Web searches, file reads, document analysis happen exclusively in Sonnet subagents. The main Opus instance receives only compressed summaries.

**Principle: The LaTeX file IS the persistent memory.** Every iteration reads the current `.tex` file to understand what's been done. The LaTeX document is the canonical state, not conversation history.

**Principle: State file tracks gaps.** Open questions, unverified claims, sections needing expansion — all tracked in the state file so each iteration knows where to focus.

### Researcher Agent Design

```yaml
---
name: researcher
description: "Parallel internet research agent. Searches credible sources, reads content, returns structured summary."
tools: [WebSearch, WebFetch, Read, Grep, Glob]
model: sonnet
---
```

**Input**: A specific research question or facet to investigate
**Output**: Structured summary (200-500 words) with:
- Key findings (3-5 bullet points)
- Sources cited (URLs + credibility assessment)
- Confidence level (high/medium/low)
- Contradictions or caveats found
- Suggested follow-up questions

**The main instance never searches the web directly.** All web interaction happens in researcher subagents that return compressed findings. This prevents context bloat from raw web content.

**Hybrid search strategy**: Researcher agents use parallel web searches (`web_search_exa`, `WebSearch`) for breadth — scanning many sources quickly. For complex multi-faceted sub-questions that need deep synthesis across many sources, they use exa's `deep_researcher_start` + `deep_researcher_check`. The agent decides which approach to use based on query complexity.

### Repo-Analyst Agent Design

```yaml
---
name: repo-analyst
description: "Parallel repo analysis agent. Reads code, docs, and config to extract relevant context."
tools: [Read, Grep, Glob]
model: sonnet
---
```

**Input**: A specific aspect of the codebase to analyze (e.g., "How is authentication currently implemented?")
**Output**: Structured analysis (200-500 words) with file paths, patterns found, and relevance to the research topic.

**Empty repo detection**: Before spawning repo-analyst agents, the command runs a quick heuristic: check if there are any non-markdown, non-JSON, non-config files in the repo root (excluding `docs/research-*`). If the repo only contains research artifacts or is freshly initialized, repo-analysts are skipped entirely.

### LaTeX Output Structure

```latex
\documentclass[11pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage{hyperref}
\usepackage{booktabs}
\usepackage{enumitem}
\usepackage{natbib}

\title{<Topic>}
\author{Research Report --- Generated via Autonomous Workflow}
\date{\today}

\begin{document}
\maketitle
\tableofcontents

\section{Executive Summary}
% 1-2 page summary of all findings

\section{Background \& Context}
% Problem domain, why this matters

\section{Key Findings}
\subsection{Finding 1: ...}
% Each finding has: claim, evidence, sources, confidence level
% Findings are organized thematically, not chronologically

\section{Analysis \& Synthesis}
% Cross-cutting analysis, patterns across findings
% Logical conflicts identified and resolved
% Novel insights from combining sources

\section{Open Questions}
% What couldn't be determined from available sources
% What would require primary research

\section{Methodology}
% How many iterations, how many sources consulted
% Source credibility criteria used

\bibliographystyle{plainnat}
\bibliography{sources}

\end{document}
```

### Compilation Pipeline

The latex-compiler agent handles:
1. Formatting edge cases (escaping special characters, table alignment)
2. Running `pdflatex` + `bibtex` + `pdflatex` (standard LaTeX build cycle)
3. Fixing compilation errors iteratively
4. Skipping compilation gracefully if `pdflatex` is not installed (`.tex` files are still valid output)

**Compilation timing**: LaTeX compilation happens only at phase boundaries to avoid disrupting research flow. Specifically:
- At the end of Phase A (research complete or transitioning to Phase B)
- At the end of Phase B (plan complete or transitioning to Phase C)
- On the final iteration of any mode
- When `continue-auto` is invoked (so the user can check progress as PDF)

Mid-phase, the `.tex` files are updated every iteration but not compiled. This avoids wasting iterations on compilation errors during active research.

## Mode 2: Research + Plan (`/autonomous-workflow:research-and-plan`)

### Invocation

```bash
/ralph-loop:ralph-loop "/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...'
" --max-iterations 40
```

### Two-Phase Iteration

**Phase A (Research)** — Same as Mode 1, but the prompt instructs researcher agents to focus on:
- Technical feasibility of the proposed approach
- Existing solutions and competitive landscape
- Architecture patterns used by similar systems
- Defensibility and moat analysis
- Technology stack evaluation

**Phase B (Planning)** — Automatically transitions when research reaches diminishing returns.

**Transition trigger**: The state file tracks `new_findings_last_iteration`. When this drops below a threshold (e.g., fewer than 2 new substantive findings for 3 consecutive iterations), the workflow transitions to Phase B.

### Phase B: Each Iteration

1. Read current plan + research report
2. Spawn 2 parallel **plan-architect** agents (Opus) — each proposes improvements or alternatives to a section of the plan
3. Spawn 2 parallel **plan-critic** agents (Opus) — each scrutinizes the plan against research findings, looking for:
   - Logical conflicts with research
   - Unsupported claims
   - Missing considerations
   - Feasibility concerns
   - Defensibility gaps
4. Synthesize architect proposals and critic feedback
5. Update plan LaTeX document with improvements
6. Spawn 1-2 **researcher** agents to validate any new claims introduced by architects
7. Update state file

### Plan Architect Agent Design

```yaml
---
name: plan-architect
description: "Designs and improves implementation plans based on research findings."
tools: [Read, Grep, Glob]
model: opus
---
```

**Input**: Current plan + research report + specific section to improve
**Output**: Proposed improvements with rationale grounded in research findings

### Plan Critic Agent Design

```yaml
---
name: plan-critic
description: "Scrutinizes plans against research, identifies logical conflicts and gaps."
tools: [Read, Grep, Glob]
model: opus
---
```

**Input**: Current plan + research report + specific aspect to scrutinize
**Output**: Issues found with severity (blocker/concern/suggestion), evidence from research, proposed resolution

### Plan LaTeX Document

Separate file: `docs/research-<project>/<project>-plan.tex`

```latex
\documentclass[11pt]{article}
% ... preamble ...

\title{Implementation Plan: <Project>}
\author{Generated via Autonomous Workflow}
\date{\today}

\begin{document}
\maketitle
\tableofcontents

\section{Vision \& Objectives}
\section{Architecture Overview}
\section{Component Design}
\subsection{Component 1: ...}
% For each: purpose, interfaces, dependencies, implementation approach
\section{Technology Stack}
\section{Defensibility Analysis}
\section{Risk Assessment}
\section{Implementation Sequence}
% Dependency-ordered, no time estimates
\section{Open Design Decisions}

\end{document}
```

## Mode 3: Full Auto (`/autonomous-workflow:full-auto`)

### Invocation

```bash
/ralph-loop:ralph-loop "/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...'
" --max-iterations 100
```

### Three-Phase Iteration

**Phase A (Research)** and **Phase B (Planning)** — Same as Mode 2.

**Phase C (Implementation)** — Borrows from the existing TDD workflow but removes all human gates. Triggered automatically when planning phase stabilizes, or can be entered directly via Mode 4.

### Phase C: Initializer Step

When transitioning from Phase B to Phase C, the command:

1. Converts the plan into a `feature-list.json`:
```json
{
  "features": [
    {
      "id": "F001",
      "name": "Database schema for ontology",
      "description": "Create PostgreSQL schema for concept ontology...",
      "component": "ontology-engine",
      "dependencies": [],
      "passes": false
    },
    {
      "id": "F002",
      "name": "Ontology CRUD API",
      "description": "REST endpoints for managing ontology concepts...",
      "component": "ontology-engine",
      "dependencies": ["F001"],
      "passes": false
    }
  ]
}
```
2. Creates `init.sh` script for project setup (dev server, database, etc.) if the project needs infrastructure
3. Creates `progress.txt` for human-readable progress tracking

**Why JSON instead of markdown**: Anthropic's research found that models are less likely to inappropriately modify or overwrite JSON files compared to markdown. For a tracking artifact that must maintain integrity across 50+ iterations, JSON is safer.

### Phase C: Each Iteration

1. Read `feature-list.json` — find first feature where `passes: false` and all dependencies have `passes: true`
2. Read `progress.txt` and recent git log for context
3. Spawn **autonomous-coder** agent (Opus):
   - Reads the feature spec from JSON
   - Reads relevant plan sections
   - Writes tests first (TDD discipline preserved)
   - Implements minimally to pass tests
   - Runs full test suite
   - Returns: files changed, tests added, test results
4. If tests pass: mark feature as `"passes": true` in JSON, commit, update progress
5. If tests fail: attempt fix (up to 3 attempts), then skip and log failure in progress.txt
6. Move to next feature
7. Send macOS notification on: feature completion, feature failure after 3 attempts, all features complete

### Autonomous Coder Agent Design

```yaml
---
name: autonomous-coder
description: "Implements one feature at a time using TDD. No human gates."
tools: [Read, Write, Edit, Bash, Grep, Glob]
model: opus
---
```

**Input**: Feature spec from JSON + plan context + codebase context
**Output**: Implementation with tests, commit message, test results

**Key difference from dev-workflow implementer**: The autonomous-coder handles the full RED-GREEN-REFACTOR cycle itself rather than being a single-phase worker. It is self-contained per feature.

## Mode 4: Implementation Only (`/autonomous-workflow:implement`)

### Invocation

```bash
/ralph-loop:ralph-loop "/autonomous-workflow:implement 'project-name'
" --max-iterations 80
```

### Purpose

Mode 4 skips research and planning entirely. It reads an existing plan and jumps straight into Phase C (Implementation). Use when:
- A previous Mode 2 run produced a plan you're satisfied with
- You wrote a plan manually or in another tool
- You want to resume implementation from a partially-completed Mode 3 run

### Plan Detection

The command looks for an existing plan in this order:
1. `docs/research-<project>/<project>-plan.tex` — LaTeX plan from Mode 2/3
2. `docs/research-<project>/<project>-plan.md` — Markdown plan (manually written)
3. `docs/<project>-plan.tex` or `docs/<project>-plan.md` — Alternate locations
4. If a `feature-list.json` already exists in `docs/research-<project>/`, skip plan parsing and resume directly from the feature list (partially-completed Mode 3)

If no plan is found, the command exits with an error and instructions.

### First Iteration: Plan → Feature List

On the first iteration (no `feature-list.json` exists yet):

1. Read the plan document (LaTeX or markdown)
2. Spawn 2 parallel **plan-critic** agents (Opus) — validate the plan is implementable, flag any ambiguities
3. If critics find blockers: log them to state file and progress.txt, do NOT generate feature list yet. The next iteration will spawn researchers to resolve the blockers.
4. If no blockers: parse the plan into `feature-list.json` with dependency ordering
5. Create `init.sh` if needed (project scaffold, dev server, database setup)
6. Create `progress.txt`
7. Transition state to Phase C

### Subsequent Iterations

Same as Mode 3 Phase C — pick next unblocked feature, spawn autonomous-coder, TDD cycle, commit, update progress.

### State File

Uses `workflow_type: autonomous-implement` in YAML frontmatter. Skips Phase A and Phase B tracking entirely.

```yaml
---
workflow_type: autonomous-implement
name: <project>
status: in_progress
current_phase: "Phase C: Implementation"
iteration: 5
total_iterations_coding: 5
features_total: 12
features_complete: 3
features_failed: 0
plan_source: "docs/research-<project>/<project>-plan.tex"
---
```

## Shared Infrastructure

### State File Format

```yaml
---
workflow_type: autonomous-research | autonomous-research-plan | autonomous-full-auto | autonomous-implement
name: <topic>
status: in_progress
current_phase: "Phase A: Research" | "Phase B: Planning" | "Phase C: Implementation"
iteration: 15
total_iterations_research: 15
total_iterations_planning: 0
total_iterations_coding: 0
sources_cited: 47
findings_count: 23
new_findings_last_iteration: 2
consecutive_low_findings: 0
phase_transition_threshold: 3
features_total: 0
features_complete: 0
features_failed: 0
---

# Autonomous Workflow State: <topic>

## Current Phase
Phase A: Research

## Original Prompt
<The full user prompt>

## Completed Phases
- [ ] Phase A: Research
- [ ] Phase B: Planning (Modes 2+3 only)
- [ ] Phase C: Implementation (Modes 3+4 only)

## Research Progress
- Sources consulted: 47
- Key findings: 23
- Open questions: 5
- Sections in report: 8

## Planning Progress (Modes 2+3)
- Components designed: 0
- Critic issues resolved: 0
- Open design decisions: 0

## Implementation Progress (Modes 3+4)
- Features total: 0
- Features complete: 0
- Features failed: 0
- Last completed feature: <feature-id>

## Context Restoration Files
1. docs/research-<topic>/<topic>-state.md (this file)
2. docs/research-<topic>/<topic>-report.tex
3. docs/research-<topic>/<topic>-plan.tex (Modes 2+3+4)
4. docs/research-<topic>/feature-list.json (Modes 3+4)
5. docs/research-<topic>/progress.txt (Modes 3+4)
6. CLAUDE.md
```

### Artifact Directory

```
docs/research-<topic>/
├── <topic>-state.md           # Workflow state (YAML frontmatter + markdown)
├── <topic>-report.tex         # Research report (LaTeX)
├── <topic>-report.pdf         # Compiled report (generated at phase boundaries)
├── <topic>-plan.tex           # Plan (Modes 2+3+4)
├── <topic>-plan.pdf           # Compiled plan
├── sources.bib                # BibTeX bibliography
├── feature-list.json          # Implementation tracker (Modes 3+4)
├── progress.txt               # Human-readable progress log (Modes 3+4)
└── transcripts/               # PreCompact transcript backups
```

### Hooks

#### PreCompact Hook (auto-checkpoint.sh)

The single most important safety net for autonomous workflows. Currently missing from the entire plugin ecosystem (identified as critical gap in dev-workflow review).

```bash
#!/bin/bash
# ABOUTME: PreCompact hook that saves transcript and state before context compaction.
# ABOUTME: Prevents loss of research context during long-running autonomous workflows.

# 1. Find active autonomous workflow state file
# 2. Save transcript to timestamped file in transcripts/ directory
# 3. Snapshot current state file (cp <topic>-state.md transcripts/<timestamp>-state.md)
# 4. Append compaction event to progress.txt (if exists)
```

#### SessionStart Hook (auto-resume.sh)

```bash
#!/bin/bash
# ABOUTME: SessionStart hook that restores autonomous workflow context after compact/clear.
# ABOUTME: Reads state file and outputs context restoration instructions.

# 1. Scan docs/research-*/*-state.md for status: in_progress
# 2. Read state file YAML frontmatter for current_phase and workflow_type
# 3. Output JSON with hookSpecificOutput containing:
#    - Full state file content
#    - Instructions to read the LaTeX report/plan at current state
#    - Instructions to continue from current phase
#    - List of context restoration files to read
```

#### Stop Hook (verify-state.sh)

```bash
#!/bin/bash
# ABOUTME: Stop hook that verifies autonomous workflow state file is accurate before allowing exit.
# ABOUTME: Prevents state drift across iterations in long-running autonomous workflows.

# 1. Scan docs/research-*/*-state.md for status: in_progress
# 2. If none found, exit 0 (allow stop)
# 3. Read state file YAML frontmatter
# 4. Cross-check iteration count, phase, features_complete against reality:
#    - If Phase C: verify feature-list.json passes count matches features_complete
#    - If Phase A/B: verify LaTeX file was updated this iteration
# 5. If mismatch: output JSON {"decision": "block", "reason": "State file is stale..."}
# 6. If valid: exit 0
```

**Hook registration** (hooks.json):
```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-checkpoint.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact|clear",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-resume.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/verify-state.sh"
          }
        ]
      }
    ]
  }
}
```

### Phase Transition Logic

**Research → Planning** (Modes 2+3):
- State file tracks `new_findings_last_iteration` and `consecutive_low_findings`
- Each iteration: if `new_findings_last_iteration < 2`, increment `consecutive_low_findings`; otherwise reset to 0
- When `consecutive_low_findings >= phase_transition_threshold` (default 3), transition triggers
- Main instance writes a synthesis section to the research report
- Compiles LaTeX to PDF (phase boundary)
- Sends macOS notification: "Phase A complete — transitioning to planning"
- Updates state: `current_phase: "Phase B: Planning"`

**Planning → Implementation** (Mode 3):
- State file tracks critic issues with severity "blocker"
- When no blockers remain and plan has been stable for 2 iterations, transition triggers
- Main instance generates `feature-list.json` from plan
- Compiles LaTeX to PDF (phase boundary)
- Sends macOS notification: "Phase B complete — transitioning to implementation"
- Updates state: `current_phase: "Phase C: Implementation"`

**Implementation complete** (Modes 3+4):
- All features in `feature-list.json` have `passes: true` or have failed after 3 attempts
- Compile final LaTeX reports
- Sends macOS notification: "Implementation complete — N/M features passing"
- Updates state: `status: complete`

### Continue Command (`/autonomous-workflow:continue-auto`)

Detects active autonomous workflow and resumes:
1. Searches `docs/research-*/*-state.md` for `status: in_progress`
2. Reads state file to determine current phase and mode
3. Compiles any un-compiled LaTeX documents (so user can check progress as PDF)
4. Invokes the appropriate mode command with restored context
5. Can be wrapped in ralph-loop for continued iteration

### Notifications

Phase completions and significant events trigger macOS notifications via `osascript`:

```bash
osascript -e 'display notification "Phase A complete — transitioning to planning" with title "Autonomous Workflow" subtitle "<project-name>"'
```

Events that trigger notifications:
- Phase transitions (A→B, B→C)
- Feature completion (Phase C)
- Feature failure after 3 attempts (Phase C)
- All features complete (end of Phase C)
- Workflow complete (all phases done)

Zero external dependencies — `osascript` ships with macOS. Notification events are also logged to `progress.txt` for auditability.

## How Ralph-Loop Integrates

The autonomous workflow command is invoked **inside** a ralph-loop call. The command handles one iteration of work. Ralph-loop handles the continuation. This is the same pattern as Phase 7 TDD implementation — the ralph-loop prompt wraps the command invocation.

```
ralph-loop feeds prompt → command runs one iteration → command exits →
Stop hook intercepts → ralph-loop re-feeds prompt → command runs next iteration
```

Each iteration, the command reads the state file to understand where it is, does one cycle of work (research/plan/code), updates the state file, and exits. Ralph-loop ensures the next iteration happens.

**Hook execution order**: When the Stop event fires, hooks execute sequentially in plugin registration order. The autonomous-workflow Stop hook (verify-state) runs before ralph-loop's Stop hook (the iteration loop). If verify-state blocks because the state file is stale, Claude updates the state file and tries to stop again — at which point verify-state passes and ralph-loop's hook takes over to continue the loop.

## Key Design Decisions

| Decision | Chosen | Alternative | Rationale |
|----------|--------|-------------|-----------|
| Standalone plugin | New plugin | Extend dev-workflow | Dev-workflow is already large (18 commands, 12 agents). Autonomous workflows have fundamentally different interaction model (no human gates). Separation of concerns. |
| LaTeX output | LaTeX files | Markdown | User requirement for human-readable typeset reports. LaTeX compiles to PDF. Markdown can't produce the same quality. |
| JSON feature list | JSON | Markdown checklist | Anthropic's research: models are less likely to inappropriately modify JSON. Critical for implementation tracking integrity across 50+ iterations. |
| Subagents for all research | Sonnet subagents | Main instance searches | Context management. 30 iterations of web searching in the main context would cause severe context rot. Subagents return compressed summaries. |
| Phase transition by diminishing returns | Automatic threshold | Fixed iteration count | Different topics need different amounts of research. A topic with abundant sources may finish research in 10 iterations; a niche topic may need 25. |
| PreCompact hook | New hook | Rely on auto-compaction | Auto-compaction loses detail. For 10+ hour workflows, transcript backups are essential for recovery. |
| Own Stop hook | Plugin-specific | Reuse dev-workflow's | Dev-workflow's state verifier only scans `docs/workflow-*` and `docs/debug/*`. Different state file paths and schemas require a dedicated hook. |
| Work directly in repo | Main branch | Git worktrees per feature | Worktrees add complexity and the autonomous-coder needs to see previous features' code for dependencies. Feature-list.json + git commits provide sufficient rollback. Users who want isolation should start the whole session in a worktree. |
| macOS notifications | `osascript` | Slack webhook | Zero dependencies. `osascript` ships with macOS. Slack integration is a future enhancement requiring webhook URL configuration. |
| Hybrid search strategy | parallel web + exa deep researcher | Only parallel web | Parallel web searches provide breadth, exa `deep_researcher_start` provides depth for complex sub-questions. Researcher agent decides based on query complexity. |
| Compile at phase boundaries | Phase boundaries only | Every iteration | Mid-phase compilation wastes iterations on potential errors. `.tex` files update every iteration; PDF compilation only at phase boundaries, final iteration, and on `continue-auto`. |

## Implementation Sequence

1. Plugin scaffold (plugin.json, directory structure, templates/)
2. State file management (creation, reading, updating, phase transitions)
3. Researcher agent + repo-analyst agent (with empty repo detection)
4. Mode 1 research command
5. LaTeX templates + latex-compiler agent + compilation pipeline
6. PreCompact hook (auto-checkpoint.sh)
7. SessionStart hook (auto-resume.sh)
8. Stop hook (verify-state.sh)
9. Plan-architect + plan-critic agents
10. Mode 2 research-and-plan command
11. Autonomous-coder agent
12. Mode 3 full-auto command (Phase C implementation logic)
13. Mode 4 implement command (plan detection + Phase C entry)
14. Continue-auto command
15. Help command
16. Skill (autonomous-workflow-guide)
17. Notification integration (macOS `osascript` calls at phase transitions)
