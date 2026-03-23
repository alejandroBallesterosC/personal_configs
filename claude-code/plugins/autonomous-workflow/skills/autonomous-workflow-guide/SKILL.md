---
name: autonomous-workflow-guide
description: "Source of truth for the autonomous workflow plugin (Modes 1-4). Use when starting, navigating, or continuing autonomous research, planning, or implementation workflows, understanding mode differences, checking state file format, managing context after compaction or clear, understanding phase transitions and strategy rotation, or asking about autonomous workflow commands, agents, artifacts, or cost estimates. Covers Mode 1 research-only, Mode 2 research-and-plan, Mode 3 full-auto (research+plan+code), and Mode 4 implement-only workflows."
---

# Autonomous Workflow Guide

Announce at start: "I'm using the autonomous-workflow-guide skill for reference on autonomous research, planning, and implementation workflows."

## When to Activate

- Starting any autonomous workflow command (research, research-and-plan, full-auto, implement)
- Resuming an autonomous workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about autonomous workflow modes, phases, or artifacts
- When checking state file format or phase transition logic
- When estimating costs for autonomous workflows

## Mode Overview

```
Mode 1: Research Only          Mode 2: Research + Plan
┌──────────────────┐          ┌──────────────────┐
│   Phase R:       │          │   Phase A:       │
│   Research       │          │   Research       │
│   (budget: $3)   │          │   (budget: $3)   │
│        │         │          │        │         │
│   Phase S:       │          │   Phase B:       │
│   Synthesis      │          │   Planning       │
│   (3 iterations) │          │   (budget: $4)   │
│                  │          │                  │
│   LaTeX Report   │          │   LaTeX Report   │
└──────────────────┘          │   + MD Plan      │
                              └──────────────────┘

Mode 3: Full Auto              Mode 4: Implement Only
┌──────────────────┐          ┌──────────────────┐
│   Phase A:       │          │   (Plan exists)  │
│   Research       │          │        │         │
│   (budget: $3)   │          │   Phase C:       │
│        │         │          │   Implementation │
│   Phase B:       │          │   Stops when all │
│   Planning       │          │   features done  │
│   (budget: $4)   │          │                  │
│        │         │          │   Working Code   │
│   Phase C:       │          └──────────────────┘
│   Implementation │
│   Stops when all │
│   features done  │
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

4. **Every claim must be cited.** All factual claims in the report must have in-line `\cite{key}` references. Researcher agents return structured source entries with BibTeX keys. The main instance converts these to BibTeX entries in `sources.bib` (with deduplication) and places `\cite{}` references in-line throughout the report. No orphan references allowed — every `sources.bib` entry must appear as a `\cite{}` somewhere.

5. **Internal consistency is enforced every iteration.** Before updating the report, new findings are checked against existing sections for contradictions. Contradictions are resolved by keeping the stronger evidence and updating the weaker claim. Every 5th iteration, a deep consistency audit re-reads the entire report checking all claims pairwise.

6. **The Synthesis section is written in Phase S, not during research.** During Phase R (research iterations), the Synthesis section contains only a placeholder. After the research budget is exhausted, Phase S runs 3 dedicated synthesis iterations: (1) Read and Outline, (2) Write, (3) Edit and Polish. This prevents drift from per-iteration rewrites and produces a coherent 1500-2500 word standalone summary with: Summary, Key Takeaways (5-7 ranked), Conclusions & Recommendations, and Confidence & Limitations. A `research-progress.md` file tracks high-level themes during Phase R to inform the synthesis.

7. **Compile LaTeX at phase boundaries only.** Mid-phase, `.tex` files are updated every iteration but not compiled to PDF. Compilation happens at phase transitions.

8. **One iteration per command invocation.** The Stop hook re-feeds the command for continuation. Each command invocation does one cycle of work, updates state, and exits.

9. **Budget-based termination.** Every phase runs for its iteration budget. Research rotates through strategies. Planning refines the plan. Implementation works through features. The Stop hook blocks exit while `status: in_progress`, verifies completion criteria when `status: complete`, and allows stop only when all criteria are met.

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

### Research → Synthesis (Mode 1)
When `total_iterations_research >= research_budget`, Phase R transitions to Phase S (Synthesis). Phase S runs 3 dedicated iterations:
- **Iteration 1 — Read and Outline**: Reads the entire report and research-progress.md, produces `synthesis-outline.md`
- **Iteration 2 — Write**: Writes the full Synthesis section into the `.tex` report from the outline
- **Iteration 3 — Edit and Polish**: Quality-checks, tightens prose, verifies citations, confirms word count (1500-2500 words)

After Phase S iteration 3, the command sets `status: complete`. The Stop hook verifies `synthesis_iteration >= 3` and `total_iterations_research >= research_budget` before allowing stop. Total workflow: N research iterations + 3 synthesis iterations.

### Research to Planning (Modes 2+3)
Budget-based. The user specifies a `research_budget` (default: 30) via the `--research-iterations` flag. When `total_iterations_research >= research_budget`, Phase A transitions to Phase B.

On transition: compile report PDF, set research state to `complete`, create implementation directory with Markdown plan and implementation state file, send macOS notification.

### Planning (Modes 2+3)
Each planning iteration conducts targeted technical research before spawning planning agents. Every iteration spawns 2-3 technical researchers focused on architecture, best practices, dependencies, tech stack, and reference implementations. For technically complex domains (AI/ML, statistical methods, cryptography, etc.), 1-2 additional academic researchers are spawned for literature review. Research findings are fed directly to plan-architect and plan-critic agents to ground their proposals in credible sources. New sources are added to `sources.bib`.

When `total_iterations_planning >= planning_budget`, the command sets `status: complete`. The Stop hook verifies both research and planning budgets are fulfilled before allowing stop.

### Planning to Implementation (Mode 3)
Budget-based. The user specifies a `planning_budget` (default: 15) via the `--plan-iterations` flag. When `total_iterations_planning >= planning_budget`, Phase B transitions to Phase C.

On transition: generate `feature-list.json` from plan, create `progress.txt`, compile report PDF, send notification.

### Implementation (Modes 3+4)
Each iteration picks the next unblocked feature and spawns an autonomous-coder. Features are tracked in `feature-list.json`:
- `passes: true` — feature implemented and tests pass
- `failed: true` — feature failed after 3 attempts inside autonomous-coder
- When no features remain with `passes: false` AND `failed: false`: set `status: complete`, compile final documents, send notification
- The Stop hook verifies `status: complete` AND all features resolved (and budgets fulfilled for Mode 3) before allowing stop.

## State File Format

There are two state files in `.claude/`. Research state lives at `.claude/autonomous-<topic>-research-state.md`, implementation state lives at `.claude/autonomous-<topic>-implementation-state.md`. Work artifacts (reports, plans, progress logs) live in `docs/autonomous/<topic>/`.

| Mode | Research state | Implementation state |
|------|---------------|---------------------|
| 1 (research) | Created at init, `in_progress` throughout | Never created |
| 2 (research+plan) | Created at init, `complete` at Phase A->B | Created at Phase A->B, `in_progress` |
| 3 (full-auto) | Created at init, `complete` at Phase A->B | Created at Phase A->B, `in_progress` |
| 4 (implement) | Never created | Created at init, `in_progress` |

### Research State (Phase R / Phase S)

```yaml
---
workflow_type: autonomous-research | autonomous-research-plan | autonomous-full-auto
name: <topic>
status: in_progress | complete
current_phase: "Phase R: Research" | "Phase S: Synthesis"
iteration: 15
total_iterations_research: 15
synthesis_iteration: 0  # 0 during Phase R, 1-3 during Phase S
sources_cited: 47
findings_count: 23
current_research_strategy: wide-exploration
research_strategies_completed: []
strategy_rotation_threshold: 3
contributions_last_iteration: 2
consecutive_low_contributions: 0
research_budget: <from --research-iterations flag>
command: |
  /autonomous-workflow:research '<topic>' '<prompt>' --research-iterations N
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
command: |
  /autonomous-workflow:full-auto '<topic>' '<prompt>' --research-iterations N --plan-iterations N
---
```

## Commands Reference

| Command | Mode | Description |
|---------|------|-------------|
| `/autonomous-workflow:research` | 1 | Deep research -> LaTeX report |
| `/autonomous-workflow:research-and-plan` | 2 | Research -> plan -> both as LaTeX |
| `/autonomous-workflow:full-auto` | 3 | Research -> plan -> TDD implementation |
| `/autonomous-workflow:implement` | 4 | TDD implementation from existing plan |
| `/autonomous-workflow:help` | - | Show plugin help |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| researcher | Sonnet | Phase A, Phase B | Strategy-aware internet research, returns structured summaries. In Phase B: targeted technical and academic research for planning. |
| repo-analyst | Sonnet | Phase A | Codebase analysis (skipped if repo is empty) |
| latex-compiler | Sonnet | Phase boundaries | LaTeX formatting + pdflatex compilation |
| plan-architect | Opus | Phase B | Plan section improvement proposals |
| plan-critic | Opus | Phase B, Mode 4 init | Plan scrutiny and validation |
| autonomous-coder | Opus | Phase C | Full TDD cycle for one feature |

## Hooks

| Event | Type | Hook | Purpose |
|-------|------|------|---------|
| Stop | command | stop-hook.sh | Iteration engine + completion verifier |
| SessionStart | command | auto-resume-after-compact-or-clear.sh | Restore context after compact/clear |

## Artifacts

**State files** (`.claude/`):
```
.claude/
├── autonomous-<topic>-research-state.md         # Research phase state
├── autonomous-<topic>-implementation-state.md   # Implementation phase state
├── autonomous-<topic>-feature-list.json         # Feature tracker (Modes 3+4)
└── autonomous-stop-hook-debug.log                # Stop hook debug log (append-only)
```

**Work artifacts** (`docs/autonomous/<topic>/`):
```
docs/autonomous/<topic>/
├── research/
│   ├── <topic>-report.tex         # Research report (LaTeX)
│   ├── <topic>-report.pdf         # Compiled report
│   ├── sources.bib                # BibTeX bibliography
│   ├── research-progress.md       # Living research summary (Phase R, max 500 words)
│   ├── synthesis-outline.md       # Synthesis outline (created in Phase S iteration 1)
│   └── transcripts/               # Research phase transcript backups
└── implementation/
    ├── <topic>-implementation-plan.md  # Implementation plan (Markdown)
    ├── progress.txt               # Progress log (Modes 3+4)
    └── transcripts/               # Implementation phase transcript backups
```

## Cost Estimates

Costs scale linearly with `--research-iterations`/`--plan-iterations`. ~$0.50-$3.00 per iteration.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |

## Dependencies

- **yq + jq**: YAML/JSON parsing in hooks (hard dependency)
- **MacTeX**: PDF output via pdflatex (optional — `.tex` files work without it)
- **exa MCP server**: Deep research via `deep_researcher_start` (optional — falls back to `WebSearch`)
