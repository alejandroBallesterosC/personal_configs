---
name: autonomous-workflow-guide
description: "Source of truth for the autonomous workflow plugin (Modes 1-4). Use when starting, navigating, or continuing autonomous research, planning, or implementation workflows, understanding mode differences, checking state file format, managing context after compaction or clear, understanding phase transitions and strategy rotation, or asking about autonomous workflow commands, agents, artifacts, or cost estimates. Covers Mode 1 research-only, Mode 2 research-and-plan, Mode 3 full-auto (research+plan+code), and Mode 4 implement-only workflows."
---

# Autonomous Workflow Guide

Announce at start: "I'm using the autonomous-workflow-guide skill for reference on autonomous research, planning, and implementation workflows."

## When to Activate

- Starting any autonomous workflow command (research, research-and-plan, full-auto, implement)
- Resuming an autonomous workflow after interruption (continue-auto)
- After context compaction or clear (SessionStart hook injects this)
- When asked about autonomous workflow modes, phases, or artifacts
- When checking state file format or phase transition logic
- When estimating costs for autonomous workflows

## Mode Overview

```
Mode 1: Research Only          Mode 2: Research + Plan
┌──────────────────┐          ┌──────────────────┐
│   Phase A:       │          │   Phase A:       │
│   Research       │          │   Research       │
│   (budget: N/A)  │          │   (budget: $3)   │
│   Runs until     │          │        │         │
│   ralph-loop     │          │   Phase B:       │
│   stops it       │          │   Planning       │
│                  │          │   Runs until     │
│   LaTeX Report   │          │   ralph-loop     │
└──────────────────┘          │   stops it       │
                              │                  │
                              │   LaTeX Report   │
                              │   + MD Plan      │
                              └──────────────────┘

Mode 3: Full Auto              Mode 4: Implement Only
┌──────────────────┐          ┌──────────────────┐
│   Phase A:       │          │   (Plan exists)  │
│   Research       │          │        │         │
│   (budget: $3)   │          │   Phase C:       │
│        │         │          │   Implementation │
│   Phase B:       │          │   Runs until     │
│   Planning       │          │   ralph-loop     │
│   (budget: $4)   │          │   stops it       │
│        │         │          │                  │
│   Phase C:       │          │   Working Code   │
│   Implementation │          └──────────────────┘
│   Runs until     │
│   ralph-loop     │
│   stops it       │
│                  │
│   LaTeX Report   │
│   + MD Plan      │
│   + Working Code │
└──────────────────┘
```

## Key Principles

1. **Subagents absorb ALL raw data.** Web searches, file reads, document analysis happen exclusively in Sonnet subagents. The main Opus instance receives only compressed 200-500 word summaries. This prevents context bloat.

2. **The artifact files ARE the persistent memory.** Every iteration reads the current `.tex` report or `.md` plan to understand what's been done. The artifact documents are the canonical state, not conversation history.

3. **State file tracks gaps.** Open questions, unverified claims, sections needing expansion — all tracked in the state file so each iteration knows where to focus.

4. **Compile LaTeX at phase boundaries only.** Mid-phase, `.tex` files are updated every iteration but not compiled to PDF. Compilation happens at phase transitions and on `continue-auto` invocations.

5. **One iteration per command invocation.** Ralph-loop handles continuation. Each command invocation does one cycle of work, updates state, and exits.

6. **No auto-termination.** Every phase runs for its iteration budget. Research rotates through strategies. Planning refines the plan. Implementation works through features. `ralph-loop --max-iterations` is the only stopping mechanism for all modes. When all features are resolved in Phase C, remaining iterations detect `status: complete` and skip work.

## Research Strategies

Research cycles through 8 strategies to stay productive. When a strategy produces fewer than 2 contributions for `strategy_rotation_threshold` (default: 3) consecutive iterations, it rotates to the next strategy. After all 8 strategies are exhausted, the cycle restarts from `wide-exploration`.

| # | Strategy | Focus | Agent Count | Output |
|---|----------|-------|-------------|--------|
| 1 | `wide-exploration` | Broad search across many facets | 3-5 | Standard 200-500 words |
| 2 | `source-verification` | Verify/refute existing claims with independent sources | 3-4 | + Verification Results (CONFIRMED/REFUTED/INCONCLUSIVE) |
| 3 | `contradiction-resolution` | Resolve conflicting information with authoritative evidence | 2-3 | + Resolution Analysis |
| 4 | `deep-dive` | Thorough investigation of primary sources | 2-3 | Expanded 800 words |
| 5 | `adversarial-challenge` | Find strongest counter-arguments to conclusions | 3-4 | + Counter-Argument Strength (STRONG/MODERATE/WEAK) |
| 6 | `gaps-and-blind-spots` | Investigate uncovered areas and missing perspectives | 3-4 | + Relevance Assessment (HIGH/MEDIUM/LOW) |
| 7 | `temporal-analysis` | How understanding evolved, latest developments, trajectory | 3-4 | + Timeline section |
| 8 | `cross-domain-synthesis` | Learnings from analogous problems in other fields | 3-4 | + Cross-Domain Mapping section |

### Contribution Types

Each iteration counts 5 types of productive contributions:
- **New findings** — information not already in the report
- **Claims verified or refuted** — existing findings confirmed/refuted by new sources
- **Contradictions resolved** — conflicting information settled with evidence
- **Depth additions** — existing findings expanded with non-redundant detail/nuance
- **Source quality upgrades** — weak sources replaced with stronger ones

## Phase Transitions

### Research (Mode 1)
No phase transitions. Strategy rotation keeps research productive. Only `ralph-loop --max-iterations` stops Mode 1.

### Research to Planning (Modes 2+3)
Budget-based. The user specifies a `research_budget` (default: 30) via the `--research-iterations` flag. When `total_iterations_research >= research_budget`, Phase A transitions to Phase B.

On transition: compile report PDF, set research state to `complete`, create implementation directory with Markdown plan and implementation state file, send macOS notification.

### Planning (Mode 2)
No auto-termination. Planning runs until `ralph-loop --max-iterations` stops the workflow.

### Planning to Implementation (Mode 3)
Budget-based. The user specifies a `planning_budget` (default: 15) via the `--plan-iterations` flag. When `total_iterations_planning >= planning_budget`, Phase B transitions to Phase C.

On transition: generate `feature-list.json` from plan, create `progress.txt`, compile report PDF, send notification.

### Implementation (Modes 3+4)
Each iteration picks the next unblocked feature and spawns an autonomous-coder. Features are tracked in `feature-list.json`:
- `passes: true` — feature implemented and tests pass
- `failed: true` — feature failed after 3 attempts inside autonomous-coder
- When no features remain with `passes: false` AND `failed: false`: set `status: complete`, compile final documents, send notification
- `--max-iterations` is the only stopping mechanism for all modes — workflows never signal ralph-loop to stop early. Remaining iterations after all features are resolved detect `status: complete` and skip work.

## State File Format

There are two state files — one per phase directory. Research state lives at `docs/autonomous/<topic>/research/<topic>-state.md`, implementation state lives at `docs/autonomous/<topic>/implementation/<topic>-state.md`.

| Mode | Research state | Implementation state |
|------|---------------|---------------------|
| 1 (research) | Created at init, `in_progress` throughout | Never created |
| 2 (research+plan) | Created at init, `complete` at Phase A->B | Created at Phase A->B, `in_progress` |
| 3 (full-auto) | Created at init, `complete` at Phase A->B | Created at Phase A->B, `in_progress` |
| 4 (implement) | Never created | Created at init, `in_progress` |

### Research State (Phase A)

```yaml
---
workflow_type: autonomous-research | autonomous-research-plan | autonomous-full-auto
name: <topic>
status: in_progress | complete
current_phase: "Phase A: Research"
iteration: 15
total_iterations_research: 15
sources_cited: 47
findings_count: 23
current_research_strategy: wide-exploration
research_strategies_completed: []
strategy_rotation_threshold: 3
contributions_last_iteration: 2
consecutive_low_contributions: 0
research_budget: <from --research-iterations flag, or 30>
---
```

### Implementation State (Phases B + C)

```yaml
---
workflow_type: autonomous-research-plan | autonomous-full-auto | autonomous-implement
name: <topic>
status: in_progress | complete
current_phase: "Phase B: Planning" | "Phase C: Implementation"
iteration: 15
total_iterations_research: <from research state>
total_iterations_planning: 0
total_iterations_coding: 0
sources_cited: <from research state>
findings_count: <from research state>
research_budget: <from research state>
planning_budget: <from --plan-iterations flag, or 15>
features_total: 0
features_complete: 0
features_failed: 0
---
```

## Commands Reference

| Command | Mode | Description |
|---------|------|-------------|
| `/autonomous-workflow:research` | 1 | Deep research -> LaTeX report |
| `/autonomous-workflow:research-and-plan` | 2 | Research -> plan -> both as LaTeX |
| `/autonomous-workflow:full-auto` | 3 | Research -> plan -> TDD implementation |
| `/autonomous-workflow:implement` | 4 | TDD implementation from existing plan |
| `/autonomous-workflow:continue-auto` | Any | Resume interrupted workflow |
| `/autonomous-workflow:help` | - | Show plugin help |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| researcher | Sonnet | Phase A | Strategy-aware internet research, returns structured summaries |
| repo-analyst | Sonnet | Phase A | Codebase analysis (skipped if repo is empty) |
| latex-compiler | Sonnet | Phase boundaries | LaTeX formatting + pdflatex compilation |
| plan-architect | Opus | Phase B | Plan section improvement proposals |
| plan-critic | Opus | Phase B, Mode 4 init | Plan scrutiny and validation |
| autonomous-coder | Opus | Phase C | Full TDD cycle for one feature |

## Hooks

| Event | Type | Hook | Purpose |
|-------|------|------|---------|
| Stop | agent | (inline prompt) | Verify state file accuracy before allowing exit |
| SessionStart | command | auto-resume-after-compact-or-clear.sh | Restore context after compact/clear |

## Artifacts Directory

```
docs/autonomous/<topic>/
├── research/
│   ├── <topic>-state.md           # Research phase state
│   ├── <topic>-report.tex         # Research report (LaTeX)
│   ├── <topic>-report.pdf         # Compiled report
│   ├── sources.bib                # BibTeX bibliography
│   └── transcripts/               # Research phase transcript backups
└── implementation/
    ├── <topic>-state.md           # Implementation phase state
    ├── <topic>-implementation-plan.md  # Implementation plan (Markdown)
    ├── feature-list.json          # Feature tracker (Modes 3+4)
    ├── progress.txt               # Progress log (Modes 3+4)
    └── transcripts/               # Implementation phase transcript backups
```

## Cost Estimates

Costs scale linearly with `--max-iterations`. ~$0.50-$3.00 per iteration.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |

## Dependencies

- **ralph-loop plugin**: Drives iteration loop (hard dependency)
- **yq + jq**: YAML/JSON parsing in hooks (hard dependency)
- **MacTeX**: PDF output via pdflatex (optional — `.tex` files work without it)
- **exa MCP server**: Deep research via `deep_researcher_start` (optional — falls back to `WebSearch`)
