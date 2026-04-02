<!-- ABOUTME: Documentation for the long-horizon-impl plugin. -->
<!-- ABOUTME: Covers both commands (1-research-and-plan, 2-implement), all agents, strategies, escalation types, and usage. -->

# long-horizon-impl Plugin

Long-horizon implementation plugin — research-driven planning followed by TDD implementation. Designed for multi-day, high-investment engineering tasks that require deep research before a single line of code is written.

## Overview

The plugin operates in two sequential steps:

### 1-research-and-plan

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

**What to do at the B0 pause:**

1. Find the scoping questions file at `docs/long-horizon-impl/<project>/planning/<project>-scoping-questions.md`
2. Read the questions the workflow generated from Phase A research findings
3. Write your answers directly into that file, below each question
4. Resume the workflow — the stop hook will re-feed the command automatically on the next iteration

**Budget allocation across B-phases:**

| Phase | Budget Share |
|-------|-------------|
| B1 Requirements | 20% |
| B2 Architecture | 30% |
| B3 Test + Impl Plan | 25% |
| B4 Cross-Examination | 25% |

### 2-implement

TDD feature-by-feature implementation driven by ralph-loop. Each iteration implements one feature, runs tests, and escalates if blocked.

**Invocation:**
```
/ralph-loop:ralph-loop "/long-horizon-impl:2-implement 'project'" --completion-promise "All features passing or resolved."
```

Anti-slop escalation detects low-quality or stalled output and triggers one of 7 escalation types before continuing.

**Resolving BLOCKED features:**

When a feature is set to `BLOCKED`, the workflow writes an entry to `.plugin-state/lhi-<project>-escalations.json` describing what is needed. To resolve:

1. Read `.plugin-state/lhi-<project>-escalations.json` to find escalations where `"resolved": false`
2. Provide the required resource (API key, clarification, dependency, architecture decision)
3. Update the escalation entry: set `"resolved": true` and add a `"resolution"` field describing what you provided
4. The next ralph-loop iteration will detect the resolved escalation, unblock the feature, and re-attempt it

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

## Research Strategies (Phase A)

Used by researcher agent instances in parallel during Phase A:

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

## Escalation Types (2-implement)

When the autonomous-coder agent detects slop, stall, or ambiguity, it triggers one of:

| Type | Trigger |
|------|---------|
| `MISSING_CREDENTIAL` | API key or credential not available in environment or config |
| `SERVICE_UNAVAILABLE` | External service returns errors or is unreachable |
| `MOCK_PREVENTION` | Plan requires real integration but real service is inaccessible |
| `AMBIGUOUS_REQUIREMENT` | Requirement can be interpreted multiple ways or contradicts codebase |
| `PLAN_MISMATCH` | Architecture plan interface differs from actual code |
| `MISSING_DEPENDENCY` | Package does not exist, is deprecated, or has a breaking change |
| `SCOPE_EXPANSION` | Implementing feature requires changes outside its declared scope |

## Commands

| Command | Description |
|---------|-------------|
| `/long-horizon-impl:1-research-and-plan` | Start research + planning workflow |
| `/long-horizon-impl:2-implement` | Start TDD implementation (use via ralph-loop) |
| `/long-horizon-impl:help` | Show full plugin reference |
| `/long-horizon-impl:review-learnings` | Synthesize accumulated workflow learnings |
| `/long-horizon-impl:record-feedback` | Record user feedback about a completed workflow |

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
| ralph-loop plugin | Required for 2-implement | Iteration engine for TDD implementation |

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

Override the directory per-project by adding to `.plugin-state/long-horizon-impl.local.md`:

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

| Command | Iterations | Estimated Cost |
|---------|-----------|----------------|
| 1-research-and-plan (30 research + 20 plan) | 50 total | $30–80 |
| 2-implement (per feature, via ralph-loop) | varies | $1–5 per feature |

Always set `--max-iterations` when invoking ralph-loop for 2-implement. 50 iterations can cost $50–100+ in API costs.

## 2-implement Invocation

```
/ralph-loop:ralph-loop "/long-horizon-impl:2-implement 'project'" --completion-promise "All features passing or resolved."
```
