---
name: long-horizon-impl-guide
description: "Long-horizon implementation workflow guide covering research-driven planning and TDD implementation. ALWAYS invoke this skill when starting, navigating, or continuing a long-horizon-impl workflow, after compaction/clear, or when asking about phases, strategies, state formats, or phase transitions. Do not proceed with long-horizon-impl commands without loading this skill first."
---

<!-- ABOUTME: Skill reference for the long-horizon-impl plugin covering research-driven planning (Mode 1) -->
<!-- ABOUTME: and TDD implementation (Mode 2) workflows with phase transitions, agents, and artifacts. -->

# Long-Horizon Implementation Guide

Announce at start: "I'm using the long-horizon-impl-guide skill for reference on research-driven planning and TDD implementation workflows."

## When to Activate

- Starting any long-horizon-impl command (research-and-plan, implement)
- Resuming a workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about long-horizon-impl modes, phases, or artifacts
- When checking state file format or phase transition logic

## Mode Overview

```
Mode 1: Research + Plan
+---------------------------------+
|   Phase A: Research             |
|          |                      |
|   Phase B0: Scoping             |
|   (pauses for human)            |
|          |                      |
|   Phase B1: Requirements        |
|   Phase B2: Architecture        |
|   Phase B3: Test + Impl Plan    |
|   Phase B4: Cross-Examination   |
|                                 |
|   LaTeX Report                  |
|   + 4 Planning Artifacts        |
+---------------------------------+

      Human reviews & approves plans

Mode 2: Implement (from approved plan)
+---------------------------------+
|   Plan validation               |
|          |                      |
|   Feature list extraction       |
|          |                      |
|   Feature loop (ralph-loop)     |
|   TDD with anti-slop escalation |
|   BLOCKED -> human input        |
|   Working Code                  |
+---------------------------------+
```

## Key Principles

1. **Subagents absorb ALL raw data.** Main Opus instance gets only compressed summaries.
2. **Artifact files ARE persistent memory.** Every iteration reads current report/plan.
3. **Every claim must be cited** with `\cite{key}` and evidence gap rating.
4. **Internal consistency enforced every iteration.** Deep audit every 5th.
5. **One iteration per invocation.** Stop hook (Mode 1) or ralph-loop (Mode 2) re-feeds.
6. **Never mock, never slop.** Mode 2 escalates on external blockers.
7. **Phase transitions are gated.** Prerequisites must be met before advancing phases.

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

### Mode 1: Research -> Planning (5 sub-phases)

Phase A -> Phase B when `total_iterations_research >= research_budget`.

Phase B sub-phases with budget allocation:
| Sub-Phase | Budget | Purpose | Artifact |
|-----------|--------|---------|----------|
| B0 | 1 iteration (pauses) | Scoping interview -- generates questions, pauses for human | `<project>-scoping-questions.md` |
| B1 | 20% | Functional Requirements | `<project>-functional-requirements.md` |
| B2 | 30% | Architecture | `<project>-architecture-plan.md` |
| B3 | 25% | Test Plan + Implementation Plan | `<project>-test-plan.md` + `<project>-implementation-plan.md` |
| B4 | 25% | Cross-Examination | All artifacts validated against each other |

**B0 flow:** Generate questions -> `waiting_for_input` -> stop hook allows exit -> orchestrator relays to human -> human answers -> orchestrator sets `in_progress` + `B1` -> nudge to resume.

### Mode 2: Implementation (ralph-loop)

1. **Plan validation**: Verify approved planning artifacts exist and are consistent.
2. **Feature list extraction**: Parse implementation plan into ordered feature list (`lhi-<topic>-feature-list.json`).
3. **Feature loop**: Iterate through features via ralph-loop TDD. Feature states: `passes`, `failed`, `blocked`.

**Escalation flow:** Coder -> `escalations.json` -> orchestrator -> human -> resolution -> unblock -> re-attempt.

## Anti-Slop Escalation Types (Mode 2)

| Type | Trigger | Action |
|------|---------|--------|
| `mock_detected` | Test uses mock when real API available | Stop, request real integration guidance |
| `test_quality` | Test does not meaningfully verify behavior | Stop, request clearer acceptance criteria |
| `scope_creep` | Implementation exceeds feature boundary | Stop, request scope clarification |
| `dependency_missing` | Required package/service unavailable | Stop, request dependency resolution |
| `api_auth` | Authentication/authorization failure | Stop, request credentials/config |
| `architecture_conflict` | Implementation contradicts architecture plan | Stop, request architecture decision |
| `blocked_by_feature` | Feature depends on unimplemented feature | Reorder feature list or request guidance |

## Commands Reference

| Command | Mode | Description |
|---------|------|-------------|
| `/long-horizon-impl:research-and-plan` | 1 | Research -> scoping -> 4 planning artifacts |
| `/long-horizon-impl:implement` | 2 | TDD implementation with escalation |
| `/long-horizon-impl:help` | - | Show help |
| `/long-horizon-impl:review-learnings` | - | Review accumulated workflow learnings |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| long-horizon-impl:researcher | Sonnet | Mode 1 | Strategy-aware research with evidence gap ratings |
| long-horizon-impl:methodological-critic | Opus | Mode 1 | Evaluates source methodology vs claims |
| long-horizon-impl:repo-analyst | Sonnet | Mode 1 | Codebase analysis |
| long-horizon-impl:latex-compiler | Sonnet | Phase boundaries | LaTeX compilation |
| long-horizon-impl:requirements-analyst | Opus | Mode 1 (B1) | Derives functional requirements |
| long-horizon-impl:plan-architect | Opus | Mode 1 (B2-B3) | Plan improvement |
| long-horizon-impl:plan-critic | Opus | Modes 1, 2 | Plan scrutiny with evidence-to-decision audit |
| long-horizon-impl:plan-reviewer | Opus | Mode 1 (B4) | Cross-examines all artifacts |
| long-horizon-impl:coder | Opus | Mode 2 | TDD with anti-slop escalation |

## Artifacts

```
.claude/
|-- lhi-<topic>-research-state.md
|-- lhi-<topic>-implementation-state.md
|-- lhi-<topic>-feature-list.json         (Mode 2)
|-- lhi-<topic>-escalations.json          (Mode 2)
+-- lhi-stop-hook-debug.log

docs/long-horizon-impl/<topic>/
|-- research/
|   |-- <topic>-report.tex, .pdf, sources.bib
|   +-- transcripts/
|-- planning/
|   |-- <topic>-scoping-questions.md
|   |-- <topic>-functional-requirements.md
|   |-- <topic>-architecture-plan.md
|   |-- <topic>-test-plan.md
|   |-- <topic>-implementation-plan.md
|   |-- cross-examination-log.md
|   +-- transcripts/
+-- implementation/
    |-- progress.txt
    +-- transcripts/
```

## Learnings System

- **Storage**: `.claude/lhi-learnings.md` in the project root
- **Override config**: Set custom path via `learnings_file` in state file YAML frontmatter
- **Review**: Use `/long-horizon-impl:review-learnings` to inspect accumulated learnings
- Learnings persist across sessions and are consulted during research and implementation phases

## Workflow Types

- `lhi-research-plan` -- Mode 1: Research + Planning
- `lhi-implement` -- Mode 2: TDD Implementation

## Dependencies

- **yq + jq**: hooks (hard dependency)
- **MacTeX**: PDF output (optional)
- **exa MCP server**: deep research (optional)
- **ralph-loop plugin**: Mode 2 iteration (required for Mode 2)
