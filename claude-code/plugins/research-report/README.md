<!-- ABOUTME: README for the research-report plugin. -->
<!-- ABOUTME: Describes autonomous iterative deep research producing LaTeX reports via parallel subagents and strategy rotation. -->

# research-report plugin

Autonomous iterative deep research producing a structured LaTeX report. The plugin runs parallel subagents across configurable research iterations (Phase R), then performs a dedicated synthesis phase (Phase S) to produce a polished, publication-ready PDF.

## Overview

The plugin operates in two phases:

**Phase R — Research iterations**

Each iteration deploys a `researcher` subagent that executes one of 9 rotating strategies, harvesting findings and appending citations to the LaTeX report. A `methodological-critic` subagent reviews findings after each iteration for bias, coverage gaps, and source quality. Iterations continue until the configured budget is exhausted or the stop hook determines convergence.

**Phase S — Synthesis (3 iterations)**

After Phase R completes, 3 dedicated synthesis iterations consolidate all findings into the `Synthesis` section of the report. A `latex-compiler` subagent compiles the final PDF. The synthesis is self-contained — a reader can understand the core findings without reading the full body sections.

## Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Executes research strategies, harvests findings, writes LaTeX sections |
| `methodological-critic` | sonnet | Reviews each iteration for bias, gaps, source credibility |
| `repo-analyst` | sonnet | Analyzes code repositories when research involves software projects |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF, fixes compilation errors, validates output |

## Research Strategies (Phase R)

| # | Strategy | Description |
|---|---|---|
| 1 | Broad survey | Wide coverage of the topic landscape, key players, and definitions |
| 2 | Deep dive | Focused investigation of the highest-priority subtopic from prior iterations |
| 3 | Contrarian | Actively seek evidence that challenges current findings |
| 4 | Source triangulation | Cross-validate key claims across independent, high-credibility sources |
| 5 | Temporal | Track how understanding of the topic has evolved over time |
| 6 | Practitioner | Focus on real-world implementations, case studies, and practitioner accounts |
| 7 | Academic | Prioritize peer-reviewed literature, preprints, and systematic reviews |
| 8 | Gap analysis | Identify what is not known or under-researched |
| 9 | Quantitative | Seek datasets, statistics, benchmarks, and measurable evidence |

Strategies rotate automatically across iterations. The stop hook tracks which strategy was last used.

## Commands

| Command | Description |
|---|---|
| `/research-report:research` | Start or continue an autonomous iterative research session |
| `/research-report:help` | Show plugin reference (invocation, phases, strategies, costs) |
| `/research-report:review-learnings` | Review and synthesize accumulated learnings from past research sessions |

## Budget Flag

```
/research-report:research --research-iterations N
```

Default: `50` iterations. Each iteration runs one research strategy plus one critic review.

**Cost estimate:** ~$0.50–$3.00 per iteration depending on source volume and report length. A 50-iteration run costs approximately $25–$150. Always set `--research-iterations` explicitly to control spend.

## Learnings System

After each session the plugin writes a structured learnings file capturing:

- Which strategies produced the highest-quality findings
- Source quality patterns (domains, publication types)
- Topic-specific research heuristics
- Suggested improvements to future sessions on the same topic

**Storage location:** `~/.claude/plugin-learnings/research-report/`

**Per-project override:** Create `.claude/research-report.local.md` in the project root with YAML frontmatter:

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
