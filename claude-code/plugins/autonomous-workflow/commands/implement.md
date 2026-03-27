---
description: "Mode 3: TDD implementation from an approved plan with intelligent escalation (no mocks, no slop)"
model: opus
argument-hint: <project-name>
---

# ABOUTME: Mode 3 command that implements features from an approved plan using ralph-loop driven TDD.
# ABOUTME: Features that hit external blockers are set to BLOCKED (not FAILED) and escalated to the human via the orchestrator.
# ABOUTME: Uses ralph-loop for iteration (not stop-hook) to allow human intervention between features.

# Autonomous Implementation

**Project**: $1

## Objective

Implement features from an approved plan using strict TDD. Each iteration picks the next unblocked feature from `feature-list.json` and spawns an `autonomous-coder` agent. Features that hit external blockers (missing API keys, unavailable services, unclear requirements) are set to BLOCKED and escalated — never mocked or worked around.

**This command is designed to be run inside a ralph-loop.** The ralph-loop drives iteration, which allows the human orchestrator to inject corrections, provide API keys, and steer the implementation between iterations.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `.claude/autonomous-$1-implementation-state.md` exists.

### If state file does NOT exist (first run):

#### Plan Detection

Check for planning artifacts at these paths:
- `docs/autonomous/$1/planning/$1-implementation-plan.md` (Mode 2 output)
- `docs/autonomous/$1/planning/$1-functional-requirements.md`
- `docs/autonomous/$1/planning/$1-architecture-plan.md`
- `docs/autonomous/$1/planning/$1-test-plan.md`

Also check legacy path:
- `docs/autonomous/$1/implementation/$1-implementation-plan.md`

If NO implementation plan found, output error and stop.

#### Initialize State

1. Create `docs/autonomous/$1/implementation/` and `transcripts/` subdirectory
2. Create escalation file `.claude/autonomous-$1-escalations.json`:
   ```json
   { "project": "$1", "escalations": [] }
   ```
3. Create `docs/autonomous/$1/implementation/progress.txt`
4. Create state file `.claude/autonomous-$1-implementation-state.md` with `workflow_type: autonomous-implement`, `features_blocked: 0`

### If state file EXISTS:

1. Read state file
2. Check `.claude/autonomous-$1-escalations.json` for newly resolved escalations
3. If `feature-list.json` exists: skip to STEP 3
4. If not: proceed to STEP 2

---

## STEP 2: Validate Plan and Generate Feature List

### Step 2a: Validate Plan

Spawn 2 parallel plan-critic agents to validate the plan is implementable.

### Step 2b: Handle Critic Results

**If BLOCKER issues found**: Write escalations, output `PLAN_BLOCKED`, exit.
**If NO BLOCKER issues**: Proceed to feature list generation.

### Step 2c: Generate Feature List

Decompose plan into features:
```json
{
  "features": [{
    "id": "F001", "name": "<name>", "description": "<desc with acceptance criteria>",
    "component": "<component>", "requirements": ["REQ-001"],
    "tests": ["T-001"], "dependencies": [],
    "external_services": [],
    "passes": false, "failed": false, "blocked": false, "block_reason": null
  }]
}
```

Write to `.claude/autonomous-$1-feature-list.json`.

---

## STEP 3: Implementation Iteration

### Check for Resolved Escalations

Read `.claude/autonomous-$1-escalations.json`. For each `resolved: true` escalation where feature is still `blocked: true`: unblock the feature, log to progress.txt.

### Find Next Feature

1. **Cascade dependency failures**: If a dep has `failed: true`, mark dependent features as `failed: true`
2. **Find first feature** where: `passes: false`, `failed: false`, `blocked: false`, all deps have `passes: true`
3. If none: check if all resolved → All Features Resolved. If some blocked → Blocked Features Remaining.

### Spawn Autonomous Coder

```
Task tool with subagent_type='autonomous-workflow:autonomous-coder'
prompt: "Implement feature using TDD:
- Feature spec from feature-list.json
- Read all 4 planning artifacts
- Escalation file: .claude/autonomous-$1-escalations.json
CRITICAL: If you need an API key or hit any external blocker — DO NOT mock it. Escalate."
```

### Process Result

**PASSING**: Set `passes: true`, log, notify.
**FEATURE_BLOCKED**: Set `blocked: true`, log, verify escalation written, notify, continue to next feature.
**FEATURE_FAILED**: Set `failed: true`, log, notify.

### All Features Resolved

When all features passed or failed (none blocked): set `status: complete`, output summary.

### Blocked Features Remaining

When non-blocked features done but some still blocked: output summary, do NOT set complete. Ralph-loop continues; next iteration checks for resolutions. After 3+ consecutive iterations with same blocked features: output STALLED warning.

---

## OUTPUT

```
## Iteration N Complete — Phase C: Implementation

### Feature: <id> - <name>
- Status: PASSING | FEATURE_FAILED | FEATURE_BLOCKED
- Tests added: N
- Files changed: N

### Overall Progress
- Features: N/M passing, F failed, B blocked

### Blocked Features (if any)
| Feature | Block Reason | What's Needed |

### Next: [next feature | all resolved | waiting for escalation resolution]
```
