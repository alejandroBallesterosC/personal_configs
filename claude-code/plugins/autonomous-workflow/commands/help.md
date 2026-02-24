---
description: "Show autonomous workflow plugin help"
model: haiku
---

# ABOUTME: Help command that displays modes, agents, hooks, dependencies, and cost estimates.
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
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic-name' 'Your detailed research prompt...'" --max-iterations 30 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:research-and-plan 'project-name' 'Your detailed prompt...'" --max-iterations 40 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:full-auto 'project-name' 'Your detailed prompt...'" --max-iterations 100 --completion-promise "WORKFLOW_COMPLETE"

/ralph-loop:ralph-loop "/autonomous-workflow:implement 'project-name'" --max-iterations 80 --completion-promise "WORKFLOW_COMPLETE"
```

Commands can also be run once without ralph-loop for testing (single iteration).

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Parallel internet research, returns structured summaries |
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

- **Research → Planning** (Modes 2+3): When fewer than 2 new findings for 3 consecutive iterations
- **Planning → Implementation** (Mode 3): When no blocker issues for 2 consecutive iterations
- **Implementation complete** (Modes 3+4): When all features have `passes: true` or `failed: true`

## Artifacts

All artifacts live in `docs/research-<topic>/`:

| File | Modes | Purpose |
|------|-------|---------|
| `<topic>-state.md` | All | Workflow state (YAML frontmatter + markdown) |
| `<topic>-report.tex` | All | Research report (LaTeX) |
| `<topic>-report.pdf` | All | Compiled report (at phase boundaries) |
| `<topic>-plan.tex` | 2, 3, 4 | Implementation plan (LaTeX) |
| `<topic>-plan.pdf` | 2, 3, 4 | Compiled plan |
| `sources.bib` | All | BibTeX bibliography |
| `feature-list.json` | 3, 4 | Implementation tracker (JSON) |
| `progress.txt` | 3, 4 | Human-readable progress log |
| `transcripts/` | All | PreCompact transcript backups |

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| ralph-loop plugin | Yes | `/plugin install ralph-loop` |
| jq | Yes (hooks) | `brew install jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |

## Cost Estimates

| Mode | Typical Iterations | Estimated Cost |
|------|-------------------|----------------|
| Research (Mode 1) | 20-30 | $15-$90 |
| Research + Plan (Mode 2) | 30-40 | $25-$120 |
| Full Auto (Mode 3) | 50-100+ | $50-$300+ |
| Implement Only (Mode 4) | 20-80 | $20-$240 |

Costs depend on subagent count, Opus vs Sonnet usage, and context size per iteration.
