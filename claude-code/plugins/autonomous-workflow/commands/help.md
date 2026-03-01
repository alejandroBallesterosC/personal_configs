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
| - | `/autonomous-workflow:continue-auto` | Resume any interrupted workflow |

## Invocation (via ralph-loop)

All modes are designed to run inside ralph-loop for multi-iteration autonomous execution:

```
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...'" --max-iterations 50 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...' 40" --max-iterations 60 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...' 50 20" --max-iterations 150 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:implement 'project-name'" --max-iterations 80 --completion-promise "WORKFLOW_COMPLETE"
```

### Budget Arguments

| Mode | Arg $3 | Arg $4 | Description |
|------|--------|--------|-------------|
| 2 | Research budget (default: 30) | — | Iterations of research before transitioning to planning |
| 3 | Research budget (default: 30) | Planning budget (default: 15) | Iterations before each phase transition |

Commands can also be run once without ralph-loop for testing (single iteration).

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

| Event | Hook | Purpose |
|-------|------|---------|
| PreCompact | auto-checkpoint.sh | Saves transcript + state snapshot before compaction |
| SessionStart | auto-resume.sh | Restores context after compact/clear |
| Stop | verify-state.sh | Verifies state file accuracy before allowing exit |

## Phase Transitions

- **Research (Mode 1)**: Strategy rotation keeps research productive. Only `ralph-loop --max-iterations` stops it.
- **Research -> Planning** (Modes 2+3): Budget-based. Transitions when `total_iterations_research >= research_budget`.
- **Planning (Mode 2)**: Runs until `ralph-loop --max-iterations` stops it.
- **Planning -> Implementation** (Mode 3): Budget-based. Transitions when `total_iterations_planning >= planning_budget`.
- **Implementation complete** (Modes 3+4): When all features have `passes: true` or `failed: true`.

## Artifacts

Artifacts live in `docs/autonomous/<topic>/` with separate research and implementation directories:

**Research directory** (`docs/autonomous/<topic>/research/`):

| File | Modes | Purpose |
|------|-------|---------|
| `<topic>-state.md` | 1, 2, 3 | Research phase state (YAML frontmatter + markdown) |
| `<topic>-report.tex` | All | Research report (LaTeX) |
| `<topic>-report.pdf` | All | Compiled report (at phase boundaries) |
| `sources.bib` | All | BibTeX bibliography |
| `transcripts/` | All | PreCompact transcript backups (research phase) |

**Implementation directory** (`docs/autonomous/<topic>/implementation/`):

| File | Modes | Purpose |
|------|-------|---------|
| `<topic>-state.md` | 2, 3, 4 | Implementation phase state (YAML frontmatter + markdown) |
| `<topic>-implementation-plan.md` | 2, 3, 4 | Implementation plan (Markdown) |
| `feature-list.json` | 3, 4 | Implementation tracker (JSON) |
| `progress.txt` | 3, 4 | Human-readable progress log |
| `transcripts/` | 2, 3, 4 | PreCompact transcript backups (implementation phase) |

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| ralph-loop plugin | Yes | `/plugin install ralph-loop` |
| jq | Yes (hooks) | `brew install jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |

## Cost Estimates

Costs scale linearly with `--max-iterations`. ~$0.50-$3.00 per iteration.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |
