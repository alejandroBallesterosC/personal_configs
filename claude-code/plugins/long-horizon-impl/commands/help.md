<!-- ABOUTME: Help command for the long-horizon-impl plugin. -->
<!-- ABOUTME: Displays complete reference for commands, agents, strategies, escalation types, dependencies, and usage. -->

---
description: Show complete reference for the long-horizon-impl plugin (commands, agents, strategies, escalation types, dependencies, learnings system, cost estimates)
model: haiku
---

Display the following reference documentation for the long-horizon-impl plugin.

---

# long-horizon-impl Plugin — Complete Reference

Long-horizon implementation plugin for research-driven planning followed by TDD implementation. Designed for multi-day, high-investment engineering tasks.

---

## Commands

### 1-research-and-plan

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
/long-horizon-impl:1-research-and-plan "topic or project description"
/long-horizon-impl:1-research-and-plan "topic" --research-iterations 20 --plan-iterations 15
```

---

### 2-implement

TDD feature-by-feature implementation driven by ralph-loop. Each iteration implements one feature, runs tests, and escalates if blocked.

**Invoke via ralph-loop:**
```
/ralph-loop:ralph-loop "/long-horizon-impl:2-implement 'project'" --completion-promise "All features passing or resolved."
```

Always set `--max-iterations` to control cost. 50 iterations = $50–100+ in API costs.

---

## Agents

| Agent | Model | Role |
|-------|-------|------|
| long-horizon-impl:researcher | sonnet | Strategy-aware research with evidence gap ratings (Phase A) |
| long-horizon-impl:methodological-critic | opus | Evaluates source methodology vs claims (Phase A) |
| long-horizon-impl:repo-analyst | sonnet | Codebase analysis (1-research-and-plan) |
| long-horizon-impl:latex-compiler | sonnet | LaTeX PDF compilation at phase boundaries |
| long-horizon-impl:requirements-analyst | opus | Derives functional requirements (Phase B1) |
| long-horizon-impl:plan-architect | opus | Plan improvement (Phases B2-B3) |
| long-horizon-impl:plan-critic | opus | Plan scrutiny with evidence-to-decision audit (1-research-and-plan and 2-implement) |
| long-horizon-impl:plan-reviewer | opus | Cross-examines all artifacts (Phase B4) |
| long-horizon-impl:autonomous-coder | opus | TDD with anti-slop escalation (2-implement) |

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

## Escalation Types (2-implement)

| Type | Trigger |
|------|---------|
| `MISSING_CREDENTIAL` | API key or credential not available in environment or config |
| `SERVICE_UNAVAILABLE` | External service returns errors or is unreachable |
| `MOCK_PREVENTION` | Plan requires real integration but real service is inaccessible |
| `AMBIGUOUS_REQUIREMENT` | Requirement can be interpreted multiple ways or contradicts codebase |
| `PLAN_MISMATCH` | Architecture plan interface differs from actual code |
| `MISSING_DEPENDENCY` | Package does not exist, is deprecated, or has a breaking change |
| `SCOPE_EXPANSION` | Implementing feature requires changes outside its declared scope |

---

## Commands Summary

| Command | Description |
|---------|-------------|
| `/long-horizon-impl:1-research-and-plan` | Start research + planning workflow |
| `/long-horizon-impl:2-implement` | Start TDD implementation (use via ralph-loop) |
| `/long-horizon-impl:help` | Show this reference |
| `/long-horizon-impl:review-learnings` | Synthesize accumulated workflow learnings |
| `/long-horizon-impl:record-feedback` | Record user feedback about a completed workflow |

---

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| yq | Required | `brew install yq` |
| jq | Required | `brew install jq` |
| MacTeX | Optional | For LaTeX PDF compilation |
| exa MCP | Optional | Web and academic search in Phase A |
| ralph-loop plugin | Required for 2-implement | `/plugin install ralph-loop` |

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

| Command | Iterations | Estimated Cost |
|---------|-----------|----------------|
| 1-research-and-plan (30 research + 20 plan) | 50 total | $30–80 |
| 2-implement (per feature, via ralph-loop) | varies | $1–5 per feature |
