---
description: "Show autonomous workflow plugin help"
model: haiku
---

# ABOUTME: Help command that displays modes, agents, hooks, strategies, dependencies, and cost estimates.
# ABOUTME: Uses haiku model for minimal token usage.

# Autonomous Workflow Plugin — Help (v3.0.0)

## Modes

| Mode | Command | Description |
|------|---------|-------------|
| 1 | `/autonomous-workflow:research` | Deep research producing a LaTeX report |
| 2 | `/autonomous-workflow:research-and-plan` | Research + scoping interview + 4 rigorous planning artifacts with cross-examination |
| 3 | `/autonomous-workflow:implement` | TDD implementation from an approved plan with anti-slop escalation |

## Design Philosophy

**No full-auto mode.** Modes 1 and 2 produce artifacts. Between Mode 2 and Mode 3, a human reviews, edits, and approves the plans. Mode 3 implements with strict anti-slop rules — escalates instead of mocking.

## Invocation

Modes 1-2 use the Stop hook for iteration:
```
/autonomous-workflow:research 'topic' 'prompt' --research-iterations 50
/autonomous-workflow:research-and-plan 'project' 'prompt' --research-iterations 30 --plan-iterations 20
```

Mode 3 uses ralph-loop:
```
/ralph-loop:ralph-loop "/autonomous-workflow:implement 'project'" --completion-promise "All features passing or resolved."
```

### Budget Arguments

| Mode | Flag | Default | Description |
|------|------|---------|-------------|
| 1 | `--research-iterations N` | 50 | Total research iteration budget |
| 2 | `--research-iterations N` | 30 | Research iterations before planning |
| 2 | `--plan-iterations N` | 20 | Total planning iterations (split across B1-B4) |

### Mode 2 Planning Sub-Phases

| Sub-Phase | Budget | Purpose |
|-----------|--------|---------|
| B0: Scoping Interview | 1 iteration (pauses) | Generate research-informed questions, wait for human answers |
| B1: Functional Requirements | 20% of plan budget | Derive testable requirements from research + answers |
| B2: Architecture | 30% of plan budget | Component design, tech stack, interfaces |
| B3: Test Plan + Implementation Plan | 25% of plan budget | Test cases, feature list, build order |
| B4: Cross-Examination | 25% of plan budget | Validate all artifacts against each other |

## Research Strategies

Research cycles through 9 strategies. Rotates on low contributions after 3 consecutive iterations. After all 9, restarts.

| # | Strategy | Focus |
|---|----------|-------|
| 1 | `wide-exploration` | Broad search |
| 2 | `source-verification` | Verify/refute claims |
| 3 | `methodological-critique` | Evaluate source methodologies |
| 4 | `contradiction-resolution` | Resolve conflicts |
| 5 | `deep-dive` | Primary sources (800-word) |
| 6 | `adversarial-challenge` | Counter-arguments |
| 7 | `gaps-and-blind-spots` | Uncovered areas |
| 8 | `temporal-analysis` | Historical evolution |
| 9 | `cross-domain-synthesis` | Analogous problems |

## Agents

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| researcher | Sonnet | Modes 1, 2 | Strategy-aware parallel research with evidence gap ratings |
| methodological-critic | Opus | Mode 1, 2 | Evaluates source methodology vs claims |
| repo-analyst | Sonnet | Modes 1, 2 | Codebase analysis |
| latex-compiler | Sonnet | Phase boundaries | LaTeX compilation |
| requirements-analyst | Opus | Mode 2 (B1) | Derives functional requirements |
| plan-architect | Opus | Mode 2 (B2-B3) | Plan improvement proposals |
| plan-critic | Opus | Modes 2, 3 | Plan scrutiny with evidence-to-decision audit |
| plan-reviewer | Opus | Mode 2 (B4) | Cross-examines all artifacts |
| autonomous-coder | Opus | Mode 3 | TDD with anti-slop escalation |

## Mode 3 Escalation Types

`MISSING_CREDENTIAL`, `SERVICE_UNAVAILABLE`, `MOCK_PREVENTION`, `AMBIGUOUS_REQUIREMENT`, `PLAN_MISMATCH`, `MISSING_DEPENDENCY`, `SCOPE_EXPANSION`

## Dependencies

| Dependency | Required | Install |
|------------|----------|---------|
| yq + jq | Yes (hooks) | `brew install yq jq` |
| MacTeX | For PDF output | `brew install --cask mactex-no-gui` |
| exa MCP server | For deep research | Configure with `EXA_API_KEY` |
| ralph-loop plugin | For Mode 3 | Install from plugin marketplace |

## Cost Estimates

~$0.50-$3.00 per iteration. 50 iterations ≈ $25-$150.
