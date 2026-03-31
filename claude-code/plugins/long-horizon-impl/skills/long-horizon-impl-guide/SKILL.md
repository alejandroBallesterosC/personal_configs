---
name: long-horizon-impl-guide
description: "Long-horizon implementation workflow guide covering research-driven planning and TDD implementation. ALWAYS invoke this skill when starting, navigating, or continuing a long-horizon-impl workflow, after compaction/clear, or when asking about phases, strategies, state formats, or phase transitions. Do not proceed with long-horizon-impl commands without loading this skill first."
---

<!-- ABOUTME: Skill reference for the long-horizon-impl plugin covering research-driven planning (1-research-and-plan) -->
<!-- ABOUTME: and TDD implementation (2-implement) workflows with phase transitions, agents, and artifacts. -->

# Long-Horizon Implementation Guide

Announce at start: "I'm using the long-horizon-impl-guide skill for reference on research-driven planning and TDD implementation workflows."

## When to Activate

- Starting any long-horizon-impl command (1-research-and-plan, 2-implement)
- Resuming a workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about long-horizon-impl phases or artifacts
- When checking state file format or phase transition logic

## Workflow Overview

```
1-research-and-plan
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

2-implement (from approved plan)
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
5. **One iteration per invocation.** Stop hook (1-research-and-plan) or ralph-loop (2-implement) re-feeds.
6. **Never mock, never slop.** 2-implement escalates on external blockers.
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

### 1-research-and-plan: Research -> Planning (5 sub-phases)

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

### 2-implement: Implementation (ralph-loop)

1. **Plan validation**: Verify approved planning artifacts exist and are consistent.
2. **Feature list extraction**: Parse implementation plan into ordered feature list (`lhi-<topic>-feature-list.json`).
3. **Feature loop**: Iterate through features via ralph-loop TDD. Feature states: `passes`, `failed`, `blocked`.

**Escalation flow:** Coder -> `escalations.json` -> orchestrator -> human -> resolution -> unblock -> re-attempt.

## Anti-Slop Escalation Types (2-implement)

| Type | Trigger | Action |
|------|---------|--------|
| `MISSING_CREDENTIAL` | API key or credential not available | Stop, request credentials |
| `SERVICE_UNAVAILABLE` | External service returns errors or is unreachable | Stop, request service access |
| `MOCK_PREVENTION` | Plan requires real integration but real service is inaccessible | Stop, request real access |
| `AMBIGUOUS_REQUIREMENT` | Requirement can be interpreted multiple ways or contradicts codebase | Stop, request clarification |
| `PLAN_MISMATCH` | Architecture plan interface differs from actual code | Stop, request architecture decision |
| `MISSING_DEPENDENCY` | Package does not exist, is deprecated, or has breaking change | Stop, request dependency resolution |
| `SCOPE_EXPANSION` | Implementing feature requires changes outside its declared scope | Stop, request scope clarification |

## Commands Reference

| Command | Description |
|---------|-------------|
| `/long-horizon-impl:1-research-and-plan` | Research -> scoping -> 4 planning artifacts |
| `/long-horizon-impl:2-implement` | TDD implementation with escalation |
| `/long-horizon-impl:help` | Show help |
| `/long-horizon-impl:review-learnings` | Review accumulated workflow learnings |
| `/long-horizon-impl:record-feedback` | Record user feedback about a completed workflow |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| long-horizon-impl:researcher | Sonnet | 1-research-and-plan | Strategy-aware research with evidence gap ratings |
| long-horizon-impl:methodological-critic | Opus | 1-research-and-plan | Evaluates source methodology vs claims |
| long-horizon-impl:repo-analyst | Sonnet | 1-research-and-plan | Codebase analysis |
| long-horizon-impl:latex-compiler | Sonnet | Phase boundaries | LaTeX compilation |
| long-horizon-impl:requirements-analyst | Opus | 1-research-and-plan (B1) | Derives functional requirements |
| long-horizon-impl:plan-architect | Opus | 1-research-and-plan (B2-B3) | Plan improvement |
| long-horizon-impl:plan-critic | Opus | 1-research-and-plan, 2-implement | Plan scrutiny with evidence-to-decision audit |
| long-horizon-impl:plan-reviewer | Opus | 1-research-and-plan (B4) | Cross-examines all artifacts |
| long-horizon-impl:autonomous-coder | Opus | 2-implement | TDD with anti-slop escalation |

## Artifacts

```
.claude/
|-- lhi-<topic>-research-state.md
|-- lhi-<topic>-implementation-state.md
|-- lhi-<topic>-feature-list.json         (2-implement)
|-- lhi-<topic>-escalations.json          (2-implement)
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

- **Storage**: `~/.claude/plugin-learnings/long-horizon-impl/` (a directory of Markdown files)
- **Override config**: Set custom path via `learnings_dir` in `.claude/long-horizon-impl.local.md` YAML frontmatter
- **Review**: Use `/long-horizon-impl:review-learnings` to inspect accumulated learnings
- Learnings persist across sessions and are consulted during research and implementation phases

## Workflow Types

- `lhi-research-plan` -- 1-research-and-plan: Research + Planning
- `lhi-implement` -- 2-implement: TDD Implementation

## Dependencies

- **yq + jq**: hooks (hard dependency)
- **MacTeX**: PDF output (optional)
- **exa MCP server**: deep research (optional)
- **ralph-loop plugin**: 2-implement iteration (required for 2-implement)
