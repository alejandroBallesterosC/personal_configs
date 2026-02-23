# Autonomous Workflow Plugin — Implementation Plan

> Created: 2026-02-23

## Problem Statement

Current dev-workflow workflows (TDD implementation, debug) are human-in-the-loop by design — specification interviews, user verification gates, plan approval. This is the right design for targeted development work. But there is a different class of work: **autonomous long-running research, planning, and execution** where Claude grinds for hours/days without supervision. These need a separate workflow.

### Use Cases

1. **Deep Research Only** — 10+ hours of internet research producing a LaTeX report. Scouring credible sources, reasoning through conflicts, verifying claims.
2. **Research + Plan** — Research thoroughly, then generate and iteratively refine an implementation plan for an ambitious project.
3. **Research + Plan + Code** — Full autonomous execution: research, plan, then implement for 10-72+ hours without supervision.

### Why Current Workflows Don't Fit

- TDD implementation has 6 human-gated phases before any code (explore, interview, architecture, plan, review, approval)
- Debug workflow has 3 human gates (describe, reproduce, verify)
- Both enforce single-active-workflow guards
- Neither supports LaTeX output
- Neither has phased research with diminishing-returns detection

## Architecture

### Plugin Structure

```
claude-code/plugins/autonomous-workflow/
├── .claude-plugin/plugin.json
├── commands/
│   ├── research.md              # Mode 1: Research only → LaTeX report
│   ├── research-and-plan.md     # Mode 2: Research → Plan → LaTeX report
│   ├── full-auto.md             # Mode 3: Research → Plan → Code
│   ├── continue-auto.md         # Resume any mode after interruption
│   └── help.md
├── agents/
│   ├── researcher.md            # Parallel internet research (Sonnet)
│   ├── repo-analyst.md          # Parallel repo analysis (Sonnet)
│   ├── latex-compiler.md        # LaTeX formatting + compilation (Sonnet)
│   ├── plan-architect.md        # Architecture/plan design (Opus)
│   ├── plan-critic.md           # Plan scrutiny/validation (Opus)
│   └── autonomous-coder.md      # Feature-by-feature implementation (Opus)
├── skills/
│   └── autonomous-workflow-guide/SKILL.md
├── hooks/
│   ├── hooks.json
│   └── auto-checkpoint.sh       # PreCompact hook: save transcript + state
└── templates/
    ├── report-template.tex      # Base LaTeX template for research reports
    └── plan-template.tex        # Base LaTeX template for plans
```

### Relationship to Existing Plugins

- **Standalone plugin** — does not extend dev-workflow; installed independently
- **Uses ralph-loop** — same hard dependency as TDD workflow (Phases 7-9)
- **Shares conventions** — YAML frontmatter state files, ABOUTME comments, parallel subagent patterns
- **No conflicts** — different state file locations (`docs/research-*` vs `docs/workflow-*` vs `docs/debug/*`)

## Mode 1: Deep Research (`/autonomous-workflow:research`)

### Invocation

```bash
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...'
" --max-iterations 30
```

### Each Iteration Cycle

1. **Read state** — Check `docs/research-<topic>/<topic>-state.md` for what's been done, what gaps remain
2. **Spawn 3-5 parallel Sonnet researcher agents** — each searches different facets of the topic via web search (exa, context7, WebSearch). Each returns a structured findings summary (200-500 words). Main instance never touches raw web content.
3. **Spawn 1-2 parallel Sonnet repo-analyst agents** (if in existing repo) — analyze relevant code/docs in the repo
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
4. The existing `.vscode/scripts/compile_latex.sh` can be adapted as a base

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

**Phase C (Implementation)** — Borrows from the existing TDD workflow but removes all human gates.

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
2. Creates `init.sh` script for project setup (dev server, database, etc.)
3. Creates `progress.txt` for human-readable progress tracking

**Why JSON instead of markdown**: Anthropic's research found that models are less likely to inappropriately modify or overwrite JSON files compared to markdown. For a tracking artifact that must maintain integrity across 50+ iterations, JSON is safer.

### Phase C: Each Iteration

1. Read `feature-list.json` — find first feature where `passes: false` and all dependencies have `passes: true`
2. Read `progress.txt` and recent git log for context
3. Spawn **autonomous-coder** agent (Opus, in worktree for isolation):
   - Reads the feature spec from JSON
   - Reads relevant plan sections
   - Writes tests first (TDD discipline preserved)
   - Implements minimally to pass tests
   - Runs full test suite
   - Returns: files changed, tests added, test results
4. If tests pass: mark feature as `"passes": true` in JSON, commit, update progress
5. If tests fail: attempt fix (up to 3 attempts), then skip and log failure
6. Move to next feature

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

## Shared Infrastructure

### State File Format

```yaml
---
workflow_type: autonomous-research | autonomous-research-plan | autonomous-full-auto
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
phase_transition_threshold: 3
features_total: 0
features_complete: 0
---

# Autonomous Workflow State: <topic>

## Current Phase
Phase A: Research

## Original Prompt
<The full user prompt>

## Completed Phases
- [ ] Phase A: Research
- [ ] Phase B: Planning (Modes 2+3 only)
- [ ] Phase C: Implementation (Mode 3 only)

## Research Progress
- Sources consulted: 47
- Key findings: 23
- Open questions: 5
- Sections in report: 8

## Planning Progress (Modes 2+3)
- Components designed: 0
- Critic issues resolved: 0
- Open design decisions: 0

## Implementation Progress (Mode 3)
- Features total: 0
- Features complete: 0
- Features failed: 0

## Context Restoration Files
1. docs/research-<topic>/<topic>-state.md (this file)
2. docs/research-<topic>/<topic>-report.tex
3. docs/research-<topic>/<topic>-plan.tex (Modes 2+3)
4. docs/research-<topic>/feature-list.json (Mode 3)
5. docs/research-<topic>/progress.txt (Mode 3)
6. CLAUDE.md
```

### Artifact Directory

```
docs/research-<topic>/
├── <topic>-state.md           # Workflow state (YAML frontmatter + markdown)
├── <topic>-report.tex         # Research report (LaTeX)
├── <topic>-report.pdf         # Compiled report
├── <topic>-plan.tex           # Plan (Modes 2+3)
├── <topic>-plan.pdf           # Compiled plan
├── sources.bib                # BibTeX bibliography
├── feature-list.json          # Implementation tracker (Mode 3)
├── progress.txt               # Human-readable progress log (Mode 3)
└── transcripts/               # PreCompact transcript backups
```

### PreCompact Hook (auto-checkpoint.sh)

This is the single most important safety net for autonomous workflows. Currently missing from the entire plugin ecosystem (identified as critical gap in dev-workflow review).

```bash
#!/bin/bash
# ABOUTME: PreCompact hook that saves transcript and state before context compaction.
# ABOUTME: Prevents loss of research context during long-running autonomous workflows.

# Save transcript to timestamped file in transcripts/ directory
# Save current state file snapshot
# Log compaction event to progress.txt
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
    ]
  }
}
```

### Phase Transition Logic

**Research → Planning** (Modes 2+3):
- State file tracks `new_findings_last_iteration`
- When this drops below 2 for 3 consecutive iterations, transition triggers
- Main instance writes a synthesis section to the research report
- Updates state: `current_phase: "Phase B: Planning"`

**Planning → Implementation** (Mode 3):
- State file tracks critic issues with severity "blocker"
- When no blockers remain and plan has been stable for 2 iterations, transition triggers
- Main instance generates `feature-list.json` from plan
- Updates state: `current_phase: "Phase C: Implementation"`

### Continue Command (`/autonomous-workflow:continue-auto`)

Detects active autonomous workflow and resumes:
1. Searches `docs/research-*/*-state.md` for `status: in_progress`
2. Reads state file to determine current phase and mode
3. Invokes the appropriate mode command with restored context
4. Can be wrapped in ralph-loop for continued iteration

## How Ralph-Loop Integrates

The autonomous workflow command is invoked **inside** a ralph-loop call. The command handles one iteration of work. Ralph-loop handles the continuation. This is the same pattern as Phase 7 TDD implementation — the ralph-loop prompt wraps the command invocation.

```
ralph-loop feeds prompt → command runs one iteration → command exits →
Stop hook intercepts → ralph-loop re-feeds prompt → command runs next iteration
```

Each iteration, the command reads the state file to understand where it is, does one cycle of work (research/plan/code), updates the state file, and exits. Ralph-loop ensures the next iteration happens.

## Key Design Decisions

| Decision | Chosen | Alternative | Rationale |
|----------|--------|-------------|-----------|
| Standalone plugin | New plugin | Extend dev-workflow | Dev-workflow is already large (18 commands, 12 agents). Autonomous workflows have fundamentally different interaction model (no human gates). Separation of concerns. |
| LaTeX output | LaTeX files | Markdown | User requirement for human-readable typeset reports. LaTeX compiles to PDF. Markdown can't produce the same quality. |
| JSON feature list | JSON | Markdown checklist | Anthropic's research: models are less likely to inappropriately modify JSON. Critical for implementation tracking integrity across 50+ iterations. |
| Subagents for all research | Sonnet subagents | Main instance searches | Context management. 30 iterations of web searching in the main context would cause severe context rot. Subagents return compressed summaries. |
| Phase transition by diminishing returns | Automatic threshold | Fixed iteration count | Different topics need different amounts of research. A topic with abundant sources may finish research in 10 iterations; a niche topic may need 25. |
| PreCompact hook | New hook | Rely on auto-compaction | Auto-compaction loses detail. For 10+ hour workflows, transcript backups are essential for recovery. |

## Implementation Sequence

1. Plugin scaffold (plugin.json, directory structure)
2. State file management (creation, reading, updating, phase transitions)
3. Researcher agent + Mode 1 research command
4. LaTeX templates + latex-compiler agent
5. PreCompact hook (auto-checkpoint.sh)
6. SessionStart hook (auto-resume.sh)
7. Plan-architect + plan-critic agents + Mode 2 command
8. Autonomous-coder agent + Mode 3 command
9. Continue-auto command
10. Help command
11. Skill (autonomous-workflow-guide)

## Open Design Questions

- Should the autonomous-workflow plugin have its own Stop hook for state verification, or rely on dev-workflow's existing one?
- Should Phase C (implementation) use git worktrees for isolation, or work directly in the repo?
- Should there be a notification mechanism (macOS notification, Slack) when phases complete or errors occur?
- Should the researcher agent use exa's deep_researcher_start for complex sub-questions, or stick to parallel web searches?
- Should there be a cost tracking mechanism (approximate token usage per iteration)?
- Should the LaTeX compilation happen every iteration or only at phase boundaries (compilation takes time and could fail)?
