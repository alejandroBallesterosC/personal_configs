<!-- ABOUTME: Help command for the long-horizon-impl plugin. -->
<!-- ABOUTME: Displays complete reference for both modes, all agents, strategies, escalation types, dependencies, and usage. -->

---
description: Show complete reference for the long-horizon-impl plugin (modes, agents, strategies, escalation types, dependencies, learnings system, cost estimates)
model: haiku
---

Display the following reference documentation for the long-horizon-impl plugin.

---

# long-horizon-impl Plugin — Complete Reference

Long-horizon implementation plugin for research-driven planning followed by TDD implementation. Designed for multi-day, high-investment engineering tasks.

---

## Modes

### Mode 1: research-and-plan

Autonomous multi-phase research and planning workflow. Produces a LaTeX research report and a detailed implementation plan.

**Phases:**

| Phase | Name | Description |
|-------|------|-------------|
| A | Research | Parallel subagents execute N research iterations across 9 strategies |
| B0 | Scoping Interview | Human pause — clarifies scope, constraints, priorities |
| B1 | Requirements | Derives formal requirements from research findings |
| B2 | Architecture | Designs technical architecture aligned to requirements |
| B3 | Test + Impl Plan | Produces TDD test plan and feature-by-feature implementation sequence |
| B4 | Cross-Examination | Adversarial review of plan — identifies gaps, contradictions, risks |

**Human gate at B0**: Workflow pauses after Phase A. Human reviews research and approves before planning proceeds.

**B-phase budget allocation:**

| Phase | Budget Share |
|-------|-------------|
| B1 Requirements | 20% |
| B2 Architecture | 30% |
| B3 Test + Impl Plan | 25% |
| B4 Cross-Examination | 25% |

**Budget flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--research-iterations N` | 30 | Number of Phase A research iterations |
| `--plan-iterations N` | 20 | Number of B1–B4 refinement iterations |

**Invoke:**
```
/long-horizon-impl:research-and-plan "topic or project description"
/long-horizon-impl:research-and-plan "topic" --research-iterations 20 --plan-iterations 15
```

---

### Mode 2: implement

TDD feature-by-feature implementation driven by ralph-loop. Each iteration implements one feature, runs tests, and escalates if blocked.

**Invoke via ralph-loop:**
```
/ralph-loop:ralph-loop "/long-horizon-impl:implement 'project'" --completion-promise "All features passing or resolved."
```

Always set `--max-iterations` to control cost. 50 iterations = $50–100+ in API costs.

---

## Agents

| Agent | Model | Role |
|-------|-------|------|
| research-orchestrator | opus | Coordinates Phase A, dispatches parallel subagents |
| research-subagent | sonnet | Executes individual research iterations using assigned strategy |
| synthesis-writer | opus | Writes Phase S synthesis section of the LaTeX report |
| scoping-interviewer | opus | Conducts Phase B0 human interview |
| requirements-analyst | opus | Phase B1 — derives requirements from research + scoping |
| architecture-designer | opus | Phase B2 — produces technical architecture |
| plan-writer | opus | Phase B3 — writes TDD test plan and implementation sequence |
| cross-examiner | opus | Phase B4 — adversarial review of the full plan |
| impl-orchestrator | opus | Mode 2 — drives per-feature TDD loops, detects slop, triggers escalation |

---

## Research Strategies (Phase A)

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

---

## Escalation Types (Mode 2)

| # | Type | Trigger |
|---|------|---------|
| 1 | Plan mismatch | Implementation diverges from the agreed plan |
| 2 | Test evasion | Tests written to pass trivially rather than validate behavior |
| 3 | Scope creep | Implementation exceeds or reshapes agreed feature boundary |
| 4 | Circular failure | Same test failure repeating across 3+ iterations without progress |
| 5 | Ambiguous requirement | Feature spec is insufficient to implement correctly |
| 6 | Architecture conflict | Implementation contradicts architectural constraints |
| 7 | Human decision needed | Blocking decision requires human input to resolve |

---

## Commands

| Command | Description |
|---------|-------------|
| `/long-horizon-impl:research-and-plan` | Start Mode 1: research + planning workflow |
| `/long-horizon-impl:implement` | Start Mode 2: TDD implementation (use via ralph-loop) |
| `/long-horizon-impl:help` | Show this reference |
| `/long-horizon-impl:review-learnings` | Synthesize accumulated workflow learnings |

---

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| yq | Required | `brew install yq` |
| jq | Required | `brew install jq` |
| MacTeX | Optional | For LaTeX PDF compilation |
| exa MCP | Optional | Web and academic search in Phase A |
| ralph-loop plugin | Required for Mode 2 | `/plugin install ralph-loop` |

---

## Learnings System

Learnings are stored as Markdown files at `~/.claude/plugin-learnings/long-horizon-impl/`.

Override per-project by adding to `.claude/long-horizon-impl.local.md`:
```yaml
---
learnings_dir: /path/to/custom/learnings/dir
---
```

Review and synthesize all learnings:
```
/long-horizon-impl:review-learnings
```

---

## Cost Estimates

| Mode | Iterations | Estimated Cost |
|------|-----------|----------------|
| Mode 1 (30 research + 20 plan) | 50 total | $30–80 |
| Mode 2 (per feature, via ralph-loop) | varies | $1–5 per feature |
