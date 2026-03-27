<!-- ABOUTME: Help command for the research-report plugin. -->
<!-- ABOUTME: Provides quick reference for invocation, phases, strategies, agents, budget, and costs. -->

---
description: Show research-report plugin reference covering invocation, Phase R/S, strategies, agents, budget flags, dependencies, learnings, and cost estimates
model: haiku
---

Print the following reference for the research-report plugin:

---

## research-report plugin — Quick Reference

### Invocation

```
/research-report:research [--research-iterations N]
```

Start or continue an autonomous iterative deep research session. The plugin manages iteration state automatically via its Stop hook. After a `/compact` or `/clear`, the SessionStart hook restores context so the session continues seamlessly.

### Phases

**Phase R — Research iterations**

- Each iteration deploys the `researcher` agent using one of 9 rotating strategies.
- After each iteration, the `methodological-critic` agent reviews findings for bias, coverage gaps, and source quality.
- Continues until `--research-iterations` budget is exhausted or convergence is detected.

**Phase S — Synthesis (3 iterations)**

- Runs after Phase R completes.
- Consolidates all findings into the `Synthesis` section of the LaTeX report.
- The `latex-compiler` agent compiles the final PDF.

### Research Strategies

| # | Strategy | Focus |
|---|---|---|
| 1 | Broad survey | Wide landscape coverage |
| 2 | Deep dive | Focused subtopic investigation |
| 3 | Contrarian | Challenge current findings |
| 4 | Source triangulation | Cross-validate key claims |
| 5 | Temporal | Topic evolution over time |
| 6 | Practitioner | Real-world implementations |
| 7 | Academic | Peer-reviewed literature |
| 8 | Gap analysis | Under-researched areas |
| 9 | Quantitative | Datasets, benchmarks, statistics |

### Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Executes strategies, writes LaTeX sections |
| `methodological-critic` | sonnet | Reviews bias, gaps, source quality |
| `repo-analyst` | sonnet | Analyzes code repositories |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF |

### Budget Flag

```
/research-report:research --research-iterations 20
```

Default: 50 iterations. Cost: ~$0.50–$3.00/iteration.

### Commands

| Command | Description |
|---|---|
| `research-report:research` | Start or continue a research session |
| `research-report:help` | Show this reference |
| `research-report:review-learnings` | Synthesize accumulated learnings |

### Learnings System

Learnings are stored at `~/.claude/plugin-learnings/research-report/` after each session. Override the directory per-project via `.claude/research-report.local.md` with YAML frontmatter field `learnings_dir`.

Use `research-report:review-learnings` to synthesize patterns across past sessions.

### Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `yq` | Required | YAML parsing in hooks |
| `jq` | Required | JSON parsing in hooks |
| MacTeX / texlive | Optional | PDF compilation |
| exa MCP server | Optional | Web search |

### Cost Estimates

- Per iteration: ~$0.50–$3.00
- 50-iteration run: ~$25–$150
- Always set `--research-iterations` explicitly to control spend.
