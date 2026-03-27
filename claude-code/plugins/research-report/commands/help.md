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
- Continues until the `--research-iterations` budget is exhausted. Strategies rotate when consecutive iterations produce fewer than 2 contributions.

**Phase S — Synthesis (4 iterations)**

- Runs after Phase R completes.
- Iteration 1: Read and Outline. Iteration 2: Write Synthesis. Iteration 3: Edit and Polish. Iteration 4: Compile PDF and verify formatting.
- The `latex-compiler` agent compiles the final PDF. The orchestrator verifies formatting quality.

### Research Strategies

| # | Strategy | Focus |
|---|---|---|
| 1 | `wide-exploration` | Wide landscape coverage |
| 2 | `source-verification` | Cross-validate key claims |
| 3 | `methodological-critique` | Evaluate source methodology vs claims |
| 4 | `contradiction-resolution` | Resolve conflicting information |
| 5 | `deep-dive` | Focused subtopic investigation |
| 6 | `adversarial-challenge` | Challenge current findings |
| 7 | `gaps-and-blind-spots` | Under-researched areas |
| 8 | `temporal-analysis` | Topic evolution over time |
| 9 | `cross-domain-synthesis` | Analogous problems from other fields |

### Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Executes strategies, writes LaTeX sections |
| `methodological-critic` | opus | Reviews bias, gaps, source quality |
| `repo-analyst` | sonnet | Analyzes code repositories |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF |

### Budget Flag

```
/research-report:research --research-iterations 20
```

Default: 30 iterations. Cost: ~$0.50–$3.00/iteration.

### Commands

| Command | Description |
|---|---|
| `research-report:research` | Start or continue a research session |
| `research-report:help` | Show this reference |
| `research-report:record-feedback` | Record feedback about a completed report |
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
