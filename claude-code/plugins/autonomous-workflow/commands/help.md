---
description: "Show autonomous workflow plugin help"
model: haiku
---

# ABOUTME: Help command that displays modes, agents, hooks, strategies, dependencies, and cost estimates.
# ABOUTME: Uses haiku model for minimal token usage.

# Autonomous Workflow Plugin — Help

## Modes

| Mode | Command | Description |
|------|---------|-------------|
| 1 | `/autonomous-workflow:research` | Deep research producing a LaTeX report |
| 2 | `/autonomous-workflow:research-and-plan` | Research + iteratively refined implementation plan |
| 3 | `/autonomous-workflow:full-auto` | Research + plan + autonomous TDD implementation |
| 4 | `/autonomous-workflow:implement` | TDD implementation from an existing plan |

## Invocation

The Stop hook drives iteration automatically — run the command once and it loops until completion:

```
/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...' --research-iterations 50

/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...' --research-iterations 40 --plan-iterations 20

/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...' --research-iterations 50 --plan-iterations 20

/autonomous-workflow:implement 'project-name'
```

### Budget Arguments

| Mode | Flag | Default | Description |
|------|------|---------|-------------|
| 1 | `--research-iterations N` | 50 | Total research iteration budget |
| 2 | `--research-iterations N` | 30 | Iterations of research before transitioning to planning |
| 2 | `--plan-iterations N` | 15 | Iterations of planning |
| 3 | `--research-iterations N` | 30 | Iterations of research before transitioning to planning |
| 3 | `--plan-iterations N` | 15 | Iterations of planning before transitioning to implementation |

Commands can also be run once for testing (single iteration, set `status: complete` to stop).

## Research Strategies

Research cycles through 8 strategies to stay productive. When a strategy produces low contributions for 3 consecutive iterations, it rotates to the next strategy. After all 8 are exhausted, the cycle restarts.

| # | Strategy | Focus |
|---|----------|-------|
| 1 | `wide-exploration` | Broad search across many facets |
| 2 | `source-verification` | Verify/refute existing claims with independent sources |
| 3 | `contradiction-resolution` | Resolve conflicting information with authoritative evidence |
| 4 | `deep-dive` | Thorough investigation of primary sources (800-word output) |
| 5 | `adversarial-challenge` | Find strongest counter-arguments to conclusions |
| 6 | `gaps-and-blind-spots` | Investigate uncovered areas and missing perspectives |
| 7 | `temporal-analysis` | Historical evolution, recent developments, trajectory |
| 8 | `cross-domain-synthesis` | Learnings from analogous problems in other fields |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Strategy-aware parallel internet research, returns structured summaries |
| repo-analyst | Sonnet | Parallel codebase analysis, returns structured analysis |
| latex-compiler | Sonnet | LaTeX formatting and pdflatex/bibtex compilation |
| plan-architect | Opus | Proposes plan section improvements grounded in research |
| plan-critic | Opus | Scrutinizes plan for conflicts, unsupported claims, gaps |
| autonomous-coder | Opus | Full RED-GREEN-REFACTOR TDD cycle for one feature |

## Hooks

| Event | Type | Hook | Purpose |
|-------|------|------|---------|
| Stop | command | stop-hook.sh | Iteration engine + completion verifier |
| SessionStart | command | auto-resume-after-compact-or-clear.sh | Restores context after compact/clear |

## Phase Transitions

- **Research (Mode 1)**: Strategy rotation keeps research productive. Stops when `total_iterations_research >= research_budget`.
- **Research -> Planning** (Modes 2+3): Budget-based. Transitions when `total_iterations_research >= research_budget`.
- **Planning (Mode 2)**: Stops when `total_iterations_planning >= planning_budget`.
- **Planning -> Implementation** (Mode 3): Budget-based. Transitions when `total_iterations_planning >= planning_budget`.
- **Implementation** (Modes 3+4): Each iteration implements one feature. Stops when all features have `passes: true` or `failed: true`.

## Artifacts

**State files** (`.claude/`):

| File | Modes | Purpose |
|------|-------|---------|
| `autonomous-<topic>-research-state.md` | 1, 2, 3 | Research phase state (YAML frontmatter + markdown) |
| `autonomous-<topic>-implementation-state.md` | 2, 3, 4 | Implementation phase state (YAML frontmatter + markdown) |
| `autonomous-<topic>-feature-list.json` | 3, 4 | Implementation tracker (JSON) |
| `autonomous-stop-hook-debug.md` | All | Stop hook debug log (append-only) |

**Work artifacts** (`docs/autonomous/<topic>/`):

| File | Modes | Purpose |
|------|-------|---------|
| `research/<topic>-report.tex` | All | Research report (LaTeX) |
| `research/<topic>-report.pdf` | All | Compiled report (at phase boundaries) |
| `research/sources.bib` | All | BibTeX bibliography |
| `research/transcripts/` | All | Transcript backups (research phase) |
| `implementation/<topic>-implementation-plan.md` | 2, 3, 4 | Implementation plan (Markdown) |
| `implementation/progress.txt` | 3, 4 | Human-readable progress log |
| `implementation/transcripts/` | 2, 3, 4 | Transcript backups (implementation phase) |

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| yq + jq | Yes (hooks) | `brew install yq jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |

## Cost Estimates

Costs scale linearly with `--research-iterations`/`--plan-iterations`. ~$0.50-$3.00 per iteration.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |
