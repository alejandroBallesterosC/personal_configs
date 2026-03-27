<!-- ABOUTME: Documentation for the long-horizon-impl plugin. -->
<!-- ABOUTME: Covers both modes (research-and-plan, implement), all agents, strategies, escalation types, and usage. -->

# long-horizon-impl Plugin

Long-horizon implementation plugin — research-driven planning followed by TDD implementation. Designed for multi-day, high-investment engineering tasks that require deep research before a single line of code is written.

## Overview

The plugin operates in two sequential modes:

### Mode 1: research-and-plan

Autonomous multi-phase research and planning workflow. Produces a LaTeX research report and a detailed implementation plan.

| Phase | Name | Description |
|-------|------|-------------|
| A | Research | Parallel subagents execute N research iterations across 9 strategies |
| B0 | Scoping Interview | Human pause — clarifies scope, constraints, priorities before planning |
| B1 | Requirements | Derives formal requirements from research findings |
| B2 | Architecture | Designs technical architecture aligned to requirements |
| B3 | Test + Impl Plan | Produces TDD test plan and feature-by-feature implementation sequence |
| B4 | Cross-Examination | Adversarial review of plan — identifies gaps, contradictions, risks |

**Human gate at B0**: The workflow pauses after Phase A and presents research findings. The human reviews and approves before planning proceeds.

**Budget allocation across B-phases:**

| Phase | Budget Share |
|-------|-------------|
| B1 Requirements | 20% |
| B2 Architecture | 30% |
| B3 Test + Impl Plan | 25% |
| B4 Cross-Examination | 25% |

### Mode 2: implement

TDD feature-by-feature implementation driven by ralph-loop. Each iteration implements one feature, runs tests, and escalates if blocked.

**Invocation:**
```
/ralph-loop:ralph-loop "/long-horizon-impl:implement 'project'" --completion-promise "All features passing or resolved."
```

Anti-slop escalation detects low-quality or stalled output and triggers one of 7 escalation types before continuing.

## Agents

| Agent | Model | Role |
|-------|-------|------|
| research-orchestrator | opus | Coordinates Phase A research, dispatches parallel subagents |
| research-subagent | sonnet | Executes individual research iterations using assigned strategy |
| synthesis-writer | opus | Writes Phase S synthesis section of the LaTeX report |
| scoping-interviewer | opus | Conducts Phase B0 human interview, surfaces key decisions |
| requirements-analyst | opus | Phase B1 — derives requirements from research + scoping |
| architecture-designer | opus | Phase B2 — produces technical architecture |
| plan-writer | opus | Phase B3 — writes TDD test plan and implementation sequence |
| cross-examiner | opus | Phase B4 — adversarial review of the full plan |
| impl-orchestrator | opus | Mode 2 — drives per-feature TDD loops, detects slop, triggers escalation |

## Research Strategies (Phase A)

Used by research-subagent instances in parallel during Phase A:

| # | Strategy | Description |
|---|----------|-------------|
| 1 | Web search | Broad web search for recent, credible sources |
| 2 | Academic search | Search for papers, preprints, technical reports |
| 3 | Code search | Search GitHub, docs, and reference implementations |
| 4 | Expert opinion | Seek practitioner blogs, talks, interviews |
| 5 | Adversarial search | Search for counter-evidence, failure cases, criticisms |
| 6 | Trend analysis | Identify emerging patterns, versioning, adoption curves |
| 7 | Comparative analysis | Compare competing approaches or tools head-to-head |
| 8 | Depth drill | Follow a single thread deep into primary sources |
| 9 | Gap identification | Explicitly search for what is NOT known or documented |

## Escalation Types (Mode 2)

When impl-orchestrator detects slop, stall, or ambiguity, it triggers one of:

| # | Type | Trigger |
|---|------|---------|
| 1 | Plan mismatch | Implementation diverges from the agreed plan |
| 2 | Test evasion | Tests written to pass trivially rather than validate behavior |
| 3 | Scope creep | Implementation exceeds or reshapes agreed feature boundary |
| 4 | Circular failure | Same test failure repeating across 3+ iterations without progress |
| 5 | Ambiguous requirement | Feature spec is insufficient to implement correctly |
| 6 | Architecture conflict | Implementation contradicts architectural constraints |
| 7 | Human decision needed | Blocking decision requires human input to resolve |

## Commands

| Command | Description |
|---------|-------------|
| `/long-horizon-impl:research-and-plan` | Start Mode 1: research + planning workflow |
| `/long-horizon-impl:implement` | Start Mode 2: TDD implementation (use via ralph-loop) |
| `/long-horizon-impl:help` | Show full plugin reference |
| `/long-horizon-impl:review-learnings` | Synthesize accumulated workflow learnings |

### Budget Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--research-iterations N` | 30 | Number of research iterations in Phase A |
| `--plan-iterations N` | 20 | Number of planning refinement iterations across B1-B4 |

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| yq | Required | YAML parsing in hooks |
| jq | Required | JSON parsing in hooks |
| MacTeX | Optional | LaTeX PDF compilation of research report |
| exa MCP | Optional | Web and academic search in Phase A |
| ralph-loop plugin | Required for Mode 2 | Iteration engine for TDD implementation |

Install yq and jq: `brew install yq jq`

Install ralph-loop:
```
/plugin marketplace add alejandroBallesterosC/personal_configs
/plugin install ralph-loop
```

## Learnings System

The plugin persists learnings after each workflow run. Learnings are stored as Markdown files at:

```
~/.claude/plugin-learnings/long-horizon-impl/
```

Override the directory per-project by adding to `.claude/long-horizon-impl.local.md`:

```yaml
---
learnings_dir: /path/to/custom/learnings/dir
---
```

Review and synthesize all accumulated learnings:
```
/long-horizon-impl:review-learnings
```

## Cost Estimate

| Mode | Iterations | Estimated Cost |
|------|-----------|----------------|
| Mode 1 (30 research + 20 plan) | 50 total | $30–80 |
| Mode 2 (per feature, via ralph-loop) | varies | $1–5 per feature |

Always set `--max-iterations` when invoking ralph-loop for Mode 2. 50 iterations can cost $50–100+ in API costs.

## Mode 2 Invocation

```
/ralph-loop:ralph-loop "/long-horizon-impl:implement 'project'" --completion-promise "All features passing or resolved."
```
