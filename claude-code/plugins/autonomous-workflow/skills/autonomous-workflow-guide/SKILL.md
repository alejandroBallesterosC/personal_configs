---
name: autonomous-workflow-guide
description: "Source of truth for the autonomous workflow plugin v3.0.0 (Modes 1-3). Use when starting, navigating, or continuing autonomous research, planning, or implementation workflows, understanding mode differences, checking state file format, managing context after compaction or clear, understanding phase transitions and strategy rotation, or asking about autonomous workflow commands, agents, artifacts, or cost estimates. Covers Mode 1 research-only, Mode 2 research + scoping interview + rigorous 4-artifact planning with cross-examination, and Mode 3 TDD implementation with anti-slop escalation."
---

# Autonomous Workflow Guide (v3.0.0)

Announce at start: "I'm using the autonomous-workflow-guide skill for reference on autonomous research, planning, and implementation workflows."

## When to Activate

- Starting any autonomous workflow command (research, research-and-plan, implement)
- Resuming an autonomous workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about autonomous workflow modes, phases, or artifacts
- When checking state file format or phase transition logic

## Mode Overview (v3.0.0)

```
Mode 1: Research Only          Mode 2: Research + Plan
┌──────────────────┐          ┌──────────────────────────┐
│   Phase R:       │          │   Phase A: Research      │
│   Research       │          │          │               │
│        │         │          │   Phase B0: Scoping      │
│   Phase S:       │          │   (pauses for human)     │
│   Synthesis      │          │          │               │
│   (3 iterations) │          │   Phase B1: Requirements │
│                  │          │   Phase B2: Architecture │
│   LaTeX Report   │          │   Phase B3: Test + Impl  │
└──────────────────┘          │   Phase B4: Cross-Exam   │
                              │                          │
                              │   LaTeX Report           │
                              │   + 4 Planning Artifacts │
                              └──────────────────────────┘

      ⬇ Human reviews & approves plans ⬇

Mode 3: Implement (from approved plan)
┌──────────────────────────┐
│   Ralph-loop driven TDD  │
│   Anti-slop escalation   │
│   BLOCKED → human input  │
│   Working Code           │
└──────────────────────────┘
```

**No full-auto mode.** The gap between Mode 2 and Mode 3 is intentional.

## Key Principles

1. **Subagents absorb ALL raw data.** Main Opus instance gets only compressed summaries.
2. **Artifact files ARE persistent memory.** Every iteration reads current report/plan.
3. **Every claim must be cited** with `\cite{key}` and evidence gap rating.
4. **Internal consistency enforced every iteration.** Deep audit every 5th.
5. **Synthesis in Phase S only** (Mode 1). Phase R uses placeholder.
6. **One iteration per invocation.** Stop hook (Modes 1-2) or ralph-loop (Mode 3) re-feeds.
7. **Never mock, never slop.** Mode 3 escalates on external blockers.

## Research Strategies (9 total)

| # | Strategy | Focus | Agent |
|---|----------|-------|-------|
| 1 | `wide-exploration` | Broad search | researcher |
| 2 | `source-verification` | Verify/refute claims | researcher |
| 3 | `methodological-critique` | Evaluate source methodologies | methodological-critic |
| 4 | `contradiction-resolution` | Resolve conflicts | researcher |
| 5 | `deep-dive` | Primary sources (800 words) | researcher |
| 6 | `adversarial-challenge` | Counter-arguments | researcher |
| 7 | `gaps-and-blind-spots` | Uncovered areas | researcher |
| 8 | `temporal-analysis` | Historical evolution | researcher |
| 9 | `cross-domain-synthesis` | Analogous problems | researcher |

## Phase Transitions

### Mode 1: Research → Synthesis
Phase R → Phase S (3 synthesis iterations) when `total_iterations_research >= research_budget`.

### Mode 2: Research → Planning (5 sub-phases)
Phase A → Phase B when research budget reached.

Phase B sub-phases with budget allocation:
| Sub-Phase | Budget | Purpose | Artifact |
|-----------|--------|---------|----------|
| B0 | 1 iteration (pauses) | Scoping interview — generates questions, pauses for human | `<project>-scoping-questions.md` |
| B1 | 20% | Functional Requirements | `<project>-functional-requirements.md` |
| B2 | 30% | Architecture | `<project>-architecture-plan.md` |
| B3 | 25% | Test Plan + Implementation Plan | `<project>-test-plan.md` + `<project>-implementation-plan.md` |
| B4 | 25% | Cross-Examination | All artifacts validated against each other |

**B0 flow:** Generate questions → `waiting_for_input` → stop hook allows exit → orchestrator relays to human → human answers → orchestrator sets `in_progress` + `B1` → nudge to resume.

### Mode 3: Implementation (ralph-loop)
Runs until all features pass, fail, or are blocked. Feature states: `passes`, `failed`, `blocked`.

**Escalation flow:** Coder → `escalations.json` → orchestrator → human → resolution → unblock → re-attempt.

## Commands Reference

| Command | Mode | Description |
|---------|------|-------------|
| `/autonomous-workflow:research` | 1 | Deep research → LaTeX report |
| `/autonomous-workflow:research-and-plan` | 2 | Research → scoping → 4 planning artifacts |
| `/autonomous-workflow:implement` | 3 | TDD implementation with escalation |
| `/autonomous-workflow:help` | - | Show help |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| researcher | Sonnet | Modes 1, 2 | Strategy-aware research with evidence gap ratings |
| methodological-critic | Opus | Modes 1, 2 | Evaluates source methodology vs claims |
| repo-analyst | Sonnet | Modes 1, 2 | Codebase analysis |
| latex-compiler | Sonnet | Phase boundaries | LaTeX compilation |
| requirements-analyst | Opus | Mode 2 (B1) | Derives functional requirements |
| plan-architect | Opus | Mode 2 (B2-B3) | Plan improvement |
| plan-critic | Opus | Modes 2, 3 | Plan scrutiny with evidence-to-decision audit |
| plan-reviewer | Opus | Mode 2 (B4) | Cross-examines all artifacts |
| autonomous-coder | Opus | Mode 3 | TDD with anti-slop escalation |

## Artifacts

```
.claude/
├── autonomous-<topic>-research-state.md
├── autonomous-<topic>-implementation-state.md
├── autonomous-<topic>-feature-list.json    (Mode 3)
├── autonomous-<topic>-escalations.json     (Mode 3)
└── autonomous-stop-hook-debug.log

docs/autonomous/<topic>/
├── research/
│   ├── <topic>-report.tex, .pdf, sources.bib
│   ├── research-progress.md, synthesis-outline.md (Mode 1)
│   └── transcripts/
├── planning/                               (Mode 2)
│   ├── <topic>-scoping-questions.md
│   ├── <topic>-functional-requirements.md
│   ├── <topic>-architecture-plan.md
│   ├── <topic>-test-plan.md
│   ├── <topic>-implementation-plan.md
│   ├── cross-examination-log.md
│   └── transcripts/
└── implementation/                         (Mode 3)
    ├── progress.txt
    └── transcripts/
```

## Dependencies

- **yq + jq**: hooks (hard dependency)
- **MacTeX**: PDF output (optional)
- **exa MCP server**: deep research (optional)
- **ralph-loop plugin**: Mode 3 iteration (required for Mode 3)
