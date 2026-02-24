---
name: autonomous-workflow-guide
description: "Source of truth for the autonomous workflow plugin (Modes 1-4). Use when starting, navigating, or continuing autonomous research, planning, or implementation workflows, understanding mode differences, checking state file format, managing context after compaction or clear, understanding phase transitions and diminishing returns detection, or asking about autonomous workflow commands, agents, artifacts, or cost estimates. Covers Mode 1 research-only, Mode 2 research-and-plan, Mode 3 full-auto (research+plan+code), and Mode 4 implement-only workflows."
---

# Autonomous Workflow Guide

Announce at start: "I'm using the autonomous-workflow-guide skill for reference on autonomous research, planning, and implementation workflows."

## When to Activate

- Starting any autonomous workflow command (research, research-and-plan, full-auto, implement)
- Resuming an autonomous workflow after interruption (continue-auto)
- After context compaction or clear (SessionStart hook injects this)
- When asked about autonomous workflow modes, phases, or artifacts
- When checking state file format or phase transition logic
- When estimating costs for autonomous workflows

## Mode Overview

```
Mode 1: Research Only          Mode 2: Research + Plan
┌──────────────────┐          ┌──────────────────┐
│   Phase A:       │          │   Phase A:       │
│   Research       │          │   Research       │
│   (10-30 iter)   │          │   (10-25 iter)   │
│                  │          │        │         │
│   LaTeX Report   │          │   Phase B:       │
└──────────────────┘          │   Planning       │
                              │   (5-15 iter)    │
                              │                  │
                              │   LaTeX Report   │
                              │   + LaTeX Plan   │
                              └──────────────────┘

Mode 3: Full Auto              Mode 4: Implement Only
┌──────────────────┐          ┌──────────────────┐
│   Phase A:       │          │   (Plan exists)  │
│   Research       │          │        │         │
│        │         │          │   Phase C:       │
│   Phase B:       │          │   Implementation │
│   Planning       │          │   (20-80 iter)   │
│        │         │          │                  │
│   Phase C:       │          │   Working Code   │
│   Implementation │          └──────────────────┘
│   (20-80 iter)   │
│                  │
│   LaTeX Report   │
│   + LaTeX Plan   │
│   + Working Code │
└──────────────────┘
```

## Key Principles

1. **Subagents absorb ALL raw data.** Web searches, file reads, document analysis happen exclusively in Sonnet subagents. The main Opus instance receives only compressed 200-500 word summaries. This prevents context bloat.

2. **The LaTeX file IS the persistent memory.** Every iteration reads the current `.tex` file to understand what's been done. The LaTeX document is the canonical state, not conversation history.

3. **State file tracks gaps.** Open questions, unverified claims, sections needing expansion — all tracked in the state file so each iteration knows where to focus.

4. **Compile LaTeX at phase boundaries only.** Mid-phase, `.tex` files are updated every iteration but not compiled to PDF. Compilation happens at phase transitions and on `continue-auto` invocations.

5. **One iteration per command invocation.** Ralph-loop handles continuation. Each command invocation does one cycle of work, updates state, and exits.

6. **Completion signals stop ralph-loop.** All modes output `<promise>WORKFLOW_COMPLETE</promise>` when done. Use `--completion-promise "WORKFLOW_COMPLETE"` in ralph-loop invocations.

## Phase Transitions

### Research to Planning (Modes 2+3)

The state file tracks `new_findings_last_iteration` and `consecutive_low_findings`.

- Each iteration: if `new_findings_last_iteration < 2`, increment `consecutive_low_findings`; else reset to 0
- When `consecutive_low_findings >= phase_transition_threshold` (default: 3), transition triggers
- On transition: compile report PDF, create plan `.tex` from template, send macOS notification

### Planning to Implementation (Mode 3)

The state tracks `consecutive_no_blockers` (iterations where plan-critic agents find zero BLOCKER issues).

- When `consecutive_no_blockers >= 2`, planning is stable
- On transition: generate `feature-list.json` from plan, create `progress.txt`, compile PDFs, send notification

### Implementation Complete (Modes 3+4)

All features in `feature-list.json` have been resolved:
- `passes: true` — feature implemented and tests pass
- `failed: true` — feature failed after 3 attempts inside autonomous-coder
- When no features remain with `passes: false` AND `failed: false`: implementation is complete
- On completion: compile final documents, send notification, set `status: complete`, output `<promise>WORKFLOW_COMPLETE</promise>`

### Completion Signal

All modes output `<promise>WORKFLOW_COMPLETE</promise>` when the workflow reaches `status: complete`. Ralph-loop invocations should use `--completion-promise "WORKFLOW_COMPLETE"` to stop automatically on completion instead of running to `--max-iterations`.

## State File Format

Located at `docs/research-<topic>/<topic>-state.md`:

```yaml
---
workflow_type: autonomous-research | autonomous-research-plan | autonomous-full-auto | autonomous-implement
name: <topic>
status: in_progress | complete
current_phase: "Phase A: Research" | "Phase B: Planning" | "Phase C: Implementation"
iteration: 15
total_iterations_research: 15
total_iterations_planning: 0
total_iterations_coding: 0
sources_cited: 47
findings_count: 23
new_findings_last_iteration: 2
consecutive_low_findings: 0
consecutive_no_blockers: 0
phase_transition_threshold: 3
features_total: 0
features_complete: 0
features_failed: 0
plan_source: "docs/research-<topic>/<topic>-plan.tex"
---

# Autonomous Workflow State: <topic>

## Current Phase
<phase name>

## Original Prompt
<full user prompt>

## Completed Phases
- [ ] Phase A: Research
- [ ] Phase B: Planning
- [ ] Phase C: Implementation

## Research Progress
...

## Planning Progress
...

## Implementation Progress
...

## Open Questions
...

## Context Restoration Files
...
```

## Commands Reference

| Command | Mode | Description |
|---------|------|-------------|
| `/autonomous-workflow:research` | 1 | Deep research → LaTeX report |
| `/autonomous-workflow:research-and-plan` | 2 | Research → plan → both as LaTeX |
| `/autonomous-workflow:full-auto` | 3 | Research → plan → TDD implementation |
| `/autonomous-workflow:implement` | 4 | TDD implementation from existing plan |
| `/autonomous-workflow:continue-auto` | Any | Resume interrupted workflow |
| `/autonomous-workflow:help` | - | Show plugin help |

## Agents Reference

| Agent | Model | Used In | Purpose |
|-------|-------|---------|---------|
| researcher | Sonnet | Phase A | Internet research, returns structured summaries |
| repo-analyst | Sonnet | Phase A | Codebase analysis (skipped if repo is empty) |
| latex-compiler | Sonnet | Phase boundaries | LaTeX formatting + pdflatex compilation |
| plan-architect | Opus | Phase B | Plan section improvement proposals |
| plan-critic | Opus | Phase B, Mode 4 init | Plan scrutiny and validation |
| autonomous-coder | Opus | Phase C | Full TDD cycle for one feature |

## Hooks

| Event | Script | Purpose |
|-------|--------|---------|
| PreCompact | auto-checkpoint.sh | Save transcript + state snapshot before compaction |
| SessionStart | auto-resume.sh | Restore context after compact/clear |
| Stop | verify-state.sh | Verify state file accuracy before allowing exit |

## Artifacts Directory

```
docs/research-<topic>/
├── <topic>-state.md           # Workflow state
├── <topic>-report.tex         # Research report (LaTeX)
├── <topic>-report.pdf         # Compiled report (at phase boundaries)
├── <topic>-plan.tex           # Plan (Modes 2+3+4)
├── <topic>-plan.pdf           # Compiled plan
├── sources.bib                # BibTeX bibliography
├── feature-list.json          # Implementation tracker (Modes 3+4)
├── progress.txt               # Human-readable progress log (Modes 3+4)
├── init.sh                    # Project setup script (if needed)
└── transcripts/               # PreCompact transcript backups
```

## Cost Estimates

| Mode | Typical Iterations | Approx. Cost |
|------|-------------------|--------------|
| Research (Mode 1) | 20-30 | $15-$90 |
| Research + Plan (Mode 2) | 30-40 | $25-$120 |
| Full Auto (Mode 3) | 50-100+ | $50-$300+ |
| Implement Only (Mode 4) | 20-80 | $20-$240 |

Each iteration: ~$0.50-$3.00 depending on subagent count and model usage.

## Dependencies

- **ralph-loop plugin**: Drives iteration loop (hard dependency)
- **jq**: JSON parsing in hooks (hard dependency)
- **MacTeX**: PDF output via pdflatex (optional — `.tex` files work without it)
- **exa MCP server**: Deep research via `deep_researcher_start` (optional — falls back to `WebSearch`)
