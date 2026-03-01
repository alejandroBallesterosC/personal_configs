# ABOUTME: Plugin README for the autonomous-workflow plugin providing installation and usage overview.
# ABOUTME: Covers modes, invocation, dependencies, architecture, and cost estimates.

# Autonomous Workflow Plugin

Long-running autonomous research, planning, and TDD implementation workflows with LaTeX output, parallel subagents, and multi-day execution.

## Modes

| Mode | Command | Description |
|------|---------|-------------|
| 1 | `/autonomous-workflow:research` | Deep research producing a LaTeX report |
| 2 | `/autonomous-workflow:research-and-plan` | Research + iteratively refined implementation plan |
| 3 | `/autonomous-workflow:full-auto` | Research + plan + autonomous TDD implementation |
| 4 | `/autonomous-workflow:implement` | TDD implementation from an existing plan |
| - | `/autonomous-workflow:continue-auto` | Resume any interrupted workflow |

## Installation

```bash
# Register marketplace
/plugin marketplace add alejandroBallesterosC/personal_configs

# Install this plugin and its required dependency
/plugin install ralph-loop
/plugin install autonomous-workflow
```

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| ralph-loop plugin | Yes | `/plugin install ralph-loop` |
| jq | Yes (hooks) | `brew install jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |

## Quick Start

All modes run inside ralph-loop for multi-iteration autonomous execution:

```bash
# Mode 1: Research only (runs until --max-iterations)
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...'" --max-iterations 50 --completion-promise "WORKFLOW_COMPLETE"

# Mode 2: Research + Planning (research budget: 40 iterations)
/ralph-loop:ralph-loop "/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...' 40" --max-iterations 60 --completion-promise "WORKFLOW_COMPLETE"

# Mode 3: Full autonomous (research budget: 50, planning budget: 20)
/ralph-loop:ralph-loop "/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...' 50 20" --max-iterations 150 --completion-promise "WORKFLOW_COMPLETE"

# Mode 4: Implement from existing plan
/ralph-loop:ralph-loop "/autonomous-workflow:implement 'project-name'" --max-iterations 80 --completion-promise "WORKFLOW_COMPLETE"
```

Commands can also be run once without ralph-loop for testing (single iteration).

## Architecture

```
commands/          6 commands (research, research-and-plan, full-auto, implement, continue-auto, help)
agents/            6 agents (researcher, repo-analyst, latex-compiler, plan-architect, plan-critic, autonomous-coder)
skills/            1 skill (autonomous-workflow-guide — source of truth loaded by all commands)
hooks/             3 hooks (PreCompact checkpoint, SessionStart resume, Stop state verification)
templates/         1 LaTeX template (report)
```

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Strategy-aware parallel internet research |
| repo-analyst | Sonnet | Parallel codebase analysis |
| latex-compiler | Sonnet | LaTeX formatting and compilation |
| plan-architect | Opus | Proposes plan improvements grounded in research |
| plan-critic | Opus | Scrutinizes plan for conflicts and feasibility gaps |
| autonomous-coder | Opus | Full RED-GREEN-REFACTOR TDD cycle for one feature |

### Hooks

| Event | Hook | Purpose |
|-------|------|---------|
| PreCompact | auto-checkpoint.sh | Saves transcript + state snapshot before compaction |
| SessionStart | auto-resume.sh | Restores context after compact/clear |
| Stop | verify-state.sh | Verifies state file accuracy before allowing exit |

## Research Strategies

Research cycles through 8 strategies. When a strategy produces low contributions for 3 consecutive iterations, it rotates to the next. After all 8 are exhausted, the cycle restarts.

1. `wide-exploration` - Broad search across many facets
2. `source-verification` - Verify/refute existing claims
3. `contradiction-resolution` - Resolve conflicting information
4. `deep-dive` - Thorough primary source investigation
5. `adversarial-challenge` - Find counter-arguments
6. `gaps-and-blind-spots` - Investigate uncovered areas
7. `temporal-analysis` - Historical evolution and trajectory
8. `cross-domain-synthesis` - Learnings from analogous fields

## Artifacts

Artifacts live in `docs/autonomous/<topic>/` with separate research and implementation directories:

**Research** (`docs/autonomous/<topic>/research/`):

| File | Modes | Purpose |
|------|-------|---------|
| `<topic>-state.md` | 1, 2, 3 | Research phase state |
| `<topic>-report.tex` | All | Research report (LaTeX) |
| `sources.bib` | All | BibTeX bibliography |
| `transcripts/` | All | PreCompact transcript backups |

**Implementation** (`docs/autonomous/<topic>/implementation/`):

| File | Modes | Purpose |
|------|-------|---------|
| `<topic>-state.md` | 2, 3, 4 | Implementation phase state |
| `<topic>-implementation-plan.md` | 2, 3, 4 | Implementation plan (Markdown) |
| `feature-list.json` | 3, 4 | Implementation feature tracker (JSON) |
| `progress.txt` | 3, 4 | Human-readable progress log |
| `transcripts/` | 2, 3, 4 | PreCompact transcript backups |

## Phase Transitions

- **Research (Mode 1)**: Runs until `ralph-loop --max-iterations` stops it.
- **Research -> Planning** (Modes 2, 3): Budget-based. Transitions when `total_iterations_research >= research_budget`.
- **Planning (Mode 2)**: Runs until `ralph-loop --max-iterations` stops it.
- **Planning -> Implementation** (Mode 3): Budget-based. Transitions when `total_iterations_planning >= planning_budget`.
- **Implementation complete** (Modes 3, 4): When all features have `passes: true` or `failed: true`.

## Cost Estimates

~$0.50-$3.00 per iteration. Costs scale linearly with `--max-iterations`.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |

## More Information

Run `/autonomous-workflow:help` for the full reference.
