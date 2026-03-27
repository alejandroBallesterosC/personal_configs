---
name: research-report-guide
description: "Autonomous research report workflow guide. ALWAYS invoke this skill when starting, navigating, or continuing a research-report workflow, after compaction/clear, or when asking about phases, strategies, or state formats. Do not proceed with research-report commands without loading this skill first."
---

# ABOUTME: Source of truth skill for the research-report plugin workflow.
# ABOUTME: Covers Phase R (Research) and Phase S (Synthesis) with 9 research strategies, learnings system, and artifact structure.

# Research Report Workflow Guide

Announce at start: "I'm using the research-report-guide skill for reference on autonomous research report workflows."

## When to Activate

- Starting a research-report workflow command
- Resuming a research-report workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about research-report phases, strategies, or artifacts
- When checking state file format or phase transition logic

## Workflow Overview

```
Research Report Workflow
┌──────────────────┐
│   Phase R:       │
│   Research       │
│        │         │
│   Phase S:       │
│   Synthesis      │
│   (3 iterations) │
│                  │
│   LaTeX Report   │
└──────────────────┘
```

## Key Principles

1. **Subagents absorb ALL raw data.** Main Opus instance gets only compressed summaries.
2. **Artifact files ARE persistent memory.** Every iteration reads current report.
3. **Every claim must be cited** with `\cite{key}` and evidence gap rating.
4. **Internal consistency enforced every iteration.** Deep audit every 5th.
5. **Synthesis in Phase S only.** Phase R uses placeholder.
6. **One iteration per invocation.** Stop hook re-feeds the command.
7. **Never mock, never slop.** Quality over speed.

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

### Phase R: Research -> Phase S: Synthesis
Phase R transitions to Phase S (4 synthesis iterations) when `total_iterations_research >= research_budget`.

### Phase S: Synthesis (4 iterations)
- **Iteration 1 — Read and Outline**: Absorb full report, produce synthesis outline
- **Iteration 2 — Write**: Write full Synthesis section into LaTeX report
- **Iteration 3 — Edit and Polish**: Quality-check, tighten prose, verify citations
- **Iteration 4 — Compile and Verify PDF**: Spawn latex-compiler, verify formatting quality, set `status: complete`

## Commands Reference

| Command | Description |
|---------|-------------|
| `/research-report:research` | Deep research producing a LaTeX report |
| `/research-report:help` | Show help for the research-report plugin |
| `/research-report:record-feedback` | Record user feedback about a completed report |
| `/research-report:review-learnings` | Review accumulated learnings from past workflows |

## Agents Reference

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Strategy-aware research with evidence gap ratings |
| methodological-critic | Opus | Evaluates source methodology vs claims |
| repo-analyst | Sonnet | Codebase analysis |
| latex-compiler | Sonnet | LaTeX compilation |

## Artifact Directory Tree

```
.claude/
├── research-report-<topic>-state.md
└── research-report.local.md          (plugin settings)

docs/research-report/<topic>/
├── <topic>-report.tex
├── <topic>-report.pdf
├── sources.bib
├── research-progress.md
├── synthesis-outline.md
└── transcripts/
```

## Learnings System

The research-report plugin writes learnings at key workflow points to help improve future research runs.

### Learnings Directory Resolution
1. Read `.claude/research-report.local.md` for a `learnings_dir` YAML field
2. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/research-report/`
3. Run `mkdir -p` on first write

### Learning Write Points

| Trigger | File Pattern | Content |
|---------|-------------|---------|
| Strategy rotation (low contributions) | `YYYY-MM-DD-<topic>-strategy-rotation.md` | Which strategy underperformed and why |
| FLAG_FOR_REMOVAL verdict | `YYYY-MM-DD-<topic>-source-quality.md` | Source quality pattern that led to removal |
| Phase S completion | `YYYY-MM-DD-<topic>-completion-review.md` | Retrospective: intent alignment, what worked, what to improve |

### Learning File Format
All learning files use YAML frontmatter with fields: `type: learning`, `plugin: research-report`, `workflow_topic`, `phase`, `date`. Body sections: Observation, Learning, Suggestion (rotation/source-quality) or Observation, Intent Alignment, What Worked Well, What Produced Lower Quality, Improvement Suggestions (completion-review).

## Dependencies

- **yq + jq**: hooks (hard dependency)
- **MacTeX**: PDF output (optional)
- **exa MCP server**: deep research (optional)
