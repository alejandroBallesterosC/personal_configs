<!-- ABOUTME: README for the research-report plugin. -->
<!-- ABOUTME: Describes autonomous iterative deep research producing LaTeX reports via parallel subagents and strategy rotation. -->

# research-report plugin

Autonomous iterative deep research producing a structured LaTeX report. The plugin runs parallel subagents across configurable research iterations (Phase R), then performs a dedicated synthesis phase (Phase S) to produce a polished, publication-ready PDF.

## Overview

The plugin operates in two phases:

**Phase R — Research iterations**

Each iteration deploys a `researcher` subagent that executes one of 9 rotating strategies, harvesting findings and appending citations to the LaTeX report. A `methodological-critic` subagent reviews findings after each iteration for bias, coverage gaps, and source quality. Iterations always run until the configured budget is exhausted — the stop hook re-feeds the command each iteration and verifies completion criteria at the end.

**Strategy rotation (convergence proxy):** Within Phase R, the command tracks `consecutive_low_contributions` — if an iteration adds fewer than 2 contributions, a counter increments. When it hits the `strategy_rotation_threshold` (default: 3), the current strategy is retired and the next one begins. This prevents grinding on a depleted research angle but does not stop the workflow early — all budgeted iterations run.

**Phase S — Synthesis (4 iterations)**

After Phase R completes, 4 dedicated synthesis iterations consolidate all findings into the `Synthesis` section of the report and produce a verified PDF. Iterations: (1) Read and Outline, (2) Write Synthesis section, (3) Edit and Polish, (4) Compile PDF and verify formatting quality. A `latex-compiler` subagent compiles the final PDF and the orchestrator verifies the output is well-formatted and human-readable. The synthesis is self-contained — a reader can understand the core findings without reading the full body sections.

## Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Executes research strategies, harvests findings, writes LaTeX sections |
| `methodological-critic` | opus | Reviews each iteration for bias, gaps, source credibility |
| `repo-analyst` | sonnet | Analyzes code repositories when research involves software projects |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF, fixes compilation errors, validates output |

## Research Strategies (Phase R)

| # | Strategy | Description |
|---|---|---|
| 1 | `wide-exploration` | Wide coverage of the topic landscape, key players, and definitions |
| 2 | `source-verification` | Cross-validate key claims across independent, high-credibility sources |
| 3 | `methodological-critique` | Evaluate whether cited sources support the claims made from them |
| 4 | `contradiction-resolution` | Resolve conflicting information with authoritative evidence |
| 5 | `deep-dive` | Focused investigation of the highest-priority subtopic from prior iterations |
| 6 | `adversarial-challenge` | Actively seek evidence that challenges current findings |
| 7 | `gaps-and-blind-spots` | Identify what is not known or under-researched |
| 8 | `temporal-analysis` | Track how understanding of the topic has evolved over time |
| 9 | `cross-domain-synthesis` | Seek analogous problems and applicable frameworks from other fields |

Strategies rotate automatically when consecutive iterations produce fewer than 2 contributions. The command manages rotation logic; the stop hook only handles re-feeding and completion verification.

## Commands

| Command | Description |
|---|---|
| `/research-report:research` | Start or continue an autonomous iterative research session |
| `/research-report:help` | Show plugin reference (invocation, phases, strategies, costs) |
| `/research-report:record-feedback` | Record user feedback about a completed report as a learning entry |
| `/research-report:review-learnings` | Review and synthesize accumulated learnings from past research sessions |

## Budget Flag

```
/research-report:research --research-iterations N
```

Default: `30` iterations. Each iteration runs one research strategy plus one critic review.

**Cost estimate:** ~$0.50–$3.00 per iteration depending on source volume and report length. A 30-iteration run costs approximately $15–$90. Always set `--research-iterations` explicitly to control spend.

## Learnings System

After each session the plugin writes a structured learnings file capturing:

- Which strategies produced the highest-quality findings
- Source quality patterns (domains, publication types)
- Topic-specific research heuristics
- Suggested improvements to future sessions on the same topic

**Storage location:** `~/.claude/plugin-learnings/research-report/`

**Per-project override:** Create `.plugin-state/research-report.local.md` in the project root with YAML frontmatter:

```yaml
---
learnings_dir: /path/to/custom/learnings/dir
---
```

Use `/research-report:review-learnings` to synthesize accumulated learnings into actionable patterns.

## Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `yq` | Required | YAML parsing in stop hook and auto-resume hook |
| `jq` | Required | JSON parsing in stop hook |
| `MacTeX` / `texlive` | Optional | PDF compilation via `latex-compiler` agent |
| `exa` MCP server | Optional | Web search for `researcher` agent |

Install required tools on macOS:

```bash
brew install yq jq
```

If MacTeX is not installed, the plugin produces a `.tex` source file but skips PDF compilation.
