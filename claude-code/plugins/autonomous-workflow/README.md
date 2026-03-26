# Autonomous Workflow Plugin (v3.0.0)

Long-running autonomous research, planning, and implementation workflows with LaTeX output, parallel subagents, and intelligent escalation.

## Design Philosophy

**No full-auto mode.** The plugin produces artifacts for human review, then implements with human-in-the-loop escalation. The gap between planning (Mode 2) and implementation (Mode 3) is intentional.

## Modes

| Mode | Command | What it does |
|------|---------|-------------|
| 1 | `research` | Deep research → LaTeX report (Phase R + Phase S synthesis) |
| 2 | `research-and-plan` | Research → scoping interview → 4 planning artifacts with cross-examination |
| 3 | `implement` | TDD implementation from approved plan with anti-slop escalation via ralph-loop |

### Mode 2 Planning Sub-Phases

0. **B0: Scoping Interview** (1 iteration, pauses) — Generates 15-30 research-informed questions, pauses for human answers
1. **B1: Functional Requirements** (20%) — Testable requirements from research + human answers
2. **B2: Architecture** (30%) — Component design, tech stack, interfaces
3. **B3: Test Plan + Implementation Plan** (25%) — Test cases + feature list with build order
4. **B4: Cross-Examination** (25%) — Validates ALL artifacts against each other

### Mode 3 Anti-Slop Escalation

Escalation types: `MISSING_CREDENTIAL`, `SERVICE_UNAVAILABLE`, `MOCK_PREVENTION`, `AMBIGUOUS_REQUIREMENT`, `PLAN_MISMATCH`, `MISSING_DEPENDENCY`, `SCOPE_EXPANSION`

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | Sonnet | Strategy-aware parallel research with evidence gap ratings |
| methodological-critic | Opus | Evaluates source methodology vs claims |
| repo-analyst | Sonnet | Codebase analysis |
| latex-compiler | Sonnet | LaTeX compilation |
| requirements-analyst | Opus | Derives functional requirements |
| plan-architect | Opus | Plan improvement proposals |
| plan-critic | Opus | Plan scrutiny with evidence-to-decision audit |
| plan-reviewer | Opus | Cross-examines all artifacts |
| autonomous-coder | Opus | TDD with strict anti-slop rules |

## Research Strategies (9)

1. wide-exploration → 2. source-verification → 3. methodological-critique → 4. contradiction-resolution → 5. deep-dive → 6. adversarial-challenge → 7. gaps-and-blind-spots → 8. temporal-analysis → 9. cross-domain-synthesis

## Dependencies

- `yq` + `jq` (hooks)
- MacTeX (optional, PDF output)
- exa MCP server (optional, deep research)
- ralph-loop plugin (Mode 3)
