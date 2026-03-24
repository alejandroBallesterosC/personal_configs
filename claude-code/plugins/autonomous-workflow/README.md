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

## Installation

```bash
# Register marketplace
/plugin marketplace add alejandroBallesterosC/personal_configs

# Install the plugin
/plugin install autonomous-workflow
```

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| yq + jq | Yes (hooks) | `brew install yq jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |

## Quick Start

The Stop hook drives iteration automatically — run the command once and it loops until budget is reached:

```bash
# Mode 1: Research only (50 iterations)
/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...' --research-iterations 50

# Mode 2: Research + Planning (research: 40, planning: 20 iterations)
/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...' --research-iterations 40 --plan-iterations 20

# Mode 3: Full autonomous (research: 50, planning: 20 iterations)
/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...' --research-iterations 50 --plan-iterations 20

# Mode 4: Implement from existing plan
/autonomous-workflow:implement 'project-name'
```

Commands can also be run once for testing (single iteration, set `status: complete` to stop).

## Architecture

```
commands/          5 commands (research, research-and-plan, full-auto, implement, help)
agents/            7 agents (researcher, methodological-critic, repo-analyst, latex-compiler, plan-architect, plan-critic, autonomous-coder)
skills/            1 skill (autonomous-workflow-guide — source of truth loaded by all commands)
hooks/             2 hooks (Stop shell for iteration + verification, SessionStart shell for context resume)
templates/         1 LaTeX template (report)
```

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Strategy-aware parallel internet research |
| methodological-critic | Opus | Evaluates whether sources' methodologies support their claims |
| repo-analyst | Sonnet | Parallel codebase analysis |
| latex-compiler | Sonnet | LaTeX formatting and compilation |
| plan-architect | Opus | Proposes plan improvements grounded in research |
| plan-critic | Opus | Scrutinizes plan for conflicts and feasibility gaps |
| autonomous-coder | Opus | Full RED-GREEN-REFACTOR TDD cycle for one feature |

### Hooks

| Event | Type | Hook | Purpose |
|-------|------|------|---------|
| Stop | command | stop-hook.sh | Iteration engine + completion verifier |
| SessionStart | command | auto-resume-after-compact-or-clear.sh | Restores context after compact/clear |

## Research Strategies

Research cycles through 9 strategies. When a strategy produces low contributions for 3 consecutive iterations, it rotates to the next. After all 9 are exhausted, the cycle restarts.

1. `wide-exploration` - Broad search across many facets
2. `source-verification` - Verify/refute existing claims
3. `methodological-critique` - Evaluate whether sources' methodologies support their claims
4. `contradiction-resolution` - Resolve conflicting information
5. `deep-dive` - Thorough primary source investigation
6. `adversarial-challenge` - Find counter-arguments
7. `gaps-and-blind-spots` - Investigate uncovered areas
8. `temporal-analysis` - Historical evolution and trajectory
9. `cross-domain-synthesis` - Learnings from analogous fields

## Artifacts

**State files** (`.claude/`):

| File | Modes | Purpose |
|------|-------|---------|
| `autonomous-<topic>-research-state.md` | 1, 2, 3 | Research phase state |
| `autonomous-<topic>-implementation-state.md` | 2, 3, 4 | Implementation phase state |
| `autonomous-<topic>-feature-list.json` | 3, 4 | Implementation feature tracker |
| `autonomous-stop-hook-debug.log` | All | Stop hook debug log |

**Work artifacts** (`docs/autonomous/<topic>/`):

| File | Modes | Purpose |
|------|-------|---------|
| `research/<topic>-report.tex` | All | Research report (LaTeX) |
| `research/sources.bib` | All | BibTeX bibliography |
| `research/transcripts/` | All | Transcript backups |
| `implementation/<topic>-implementation-plan.md` | 2, 3, 4 | Implementation plan (Markdown) |
| `implementation/progress.txt` | 3, 4 | Human-readable progress log |
| `implementation/transcripts/` | 2, 3, 4 | Transcript backups |

## Phase Transitions

- **Research (Mode 1)**: Stops when `total_iterations_research >= research_budget`.
- **Research -> Planning** (Modes 2, 3): Budget-based. Transitions when `total_iterations_research >= research_budget`.
- **Planning (Mode 2)**: Stops when `total_iterations_planning >= planning_budget`.
- **Planning -> Implementation** (Mode 3): Budget-based. Transitions when `total_iterations_planning >= planning_budget`.
- **Implementation** (Modes 3, 4): Each iteration implements one feature. Stops when all features have `passes: true` or `failed: true`.

## Cost Estimates

~$0.50-$3.00 per iteration. Costs scale linearly with `--research-iterations`/`--plan-iterations`.

| Iterations | Approx. Cost |
|-----------|--------------|
| 50 | $25-$150 |
| 100 | $50-$300 |
| 200 | $100-$600 |

## More Information

Run `/autonomous-workflow:help` for the full reference.
