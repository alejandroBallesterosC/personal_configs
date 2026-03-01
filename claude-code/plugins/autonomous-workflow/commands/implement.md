---
description: "Mode 4: Autonomous TDD implementation from an existing plan"
model: opus
argument-hint: <project-name>
---

# ABOUTME: Mode 4 command that runs TDD implementation from an existing plan without research.
# ABOUTME: Detects plan files, generates feature-list.json, and implements via autonomous-coder agent.

# Autonomous Implementation

**Project**: $1

## Objective

Run ONE ITERATION of TDD implementation from an existing plan. Skips research (Phase A) and planning (Phase B) entirely. If a `feature-list.json` already exists, resumes from where it left off. Ralph-loop calls this command repeatedly.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `docs/autonomous/$1/implementation/$1-state.md` exists.

### If state file does NOT exist (first run):

#### Plan Detection

Check for an existing plan at the canonical path:
- `docs/autonomous/$1/implementation/$1-implementation-plan.md`

If NOT found, output this error and stop:
```
ERROR: No plan found for project '$1'.

Searched:
- docs/autonomous/$1/implementation/$1-implementation-plan.md

Create a plan first using /autonomous-workflow:research-and-plan, or place a plan at the path above.
```

#### Initialize State

1. Create directory `docs/autonomous/$1/implementation/` and `docs/autonomous/$1/implementation/transcripts/` (if they don't exist)

2. Create `docs/autonomous/$1/implementation/progress.txt`:
   ```
   # Implementation Progress: $1
   # Plan: docs/autonomous/$1/implementation/$1-implementation-plan.md

   [<timestamp>] Workflow initialized.
   ```

3. Create state file `docs/autonomous/$1/implementation/$1-state.md`:
   ```yaml
   ---
   workflow_type: autonomous-implement
   name: $1
   status: in_progress
   current_phase: "Phase C: Implementation"
   iteration: 1
   total_iterations_coding: 0
   features_total: 0
   features_complete: 0
   features_failed: 0
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase C: Implementation

   ## Completed Phases
   - [x] Phase A: Research (skipped — using existing plan)
   - [x] Phase B: Planning (skipped — using existing plan)
   - [ ] Phase C: Implementation

   ## Implementation Progress
   - Features total: 0
   - Features complete: 0
   - Features failed: 0

   ## Context Restoration Files
   1. docs/autonomous/$1/implementation/$1-state.md (this file)
   2. docs/autonomous/$1/implementation/$1-implementation-plan.md
   3. docs/autonomous/$1/implementation/feature-list.json (after first iteration)
   4. docs/autonomous/$1/implementation/progress.txt
   5. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file
2. Check if `docs/autonomous/$1/implementation/feature-list.json` exists
3. If feature-list.json exists: skip to STEP 3 (resume implementation)
4. If feature-list.json does NOT exist: proceed to STEP 2 (validate plan and generate features)

---

## STEP 2: Validate Plan and Generate Feature List

This step runs on the first iteration when no `feature-list.json` exists yet.

### Step 2a: Validate Plan

Read the plan at `docs/autonomous/$1/implementation/$1-implementation-plan.md`.

Spawn 2 parallel plan-critic agents:
```
Task tool with subagent_type='autonomous-workflow:plan-critic'
prompt: "Validate whether this plan is implementable.

Plan: docs/autonomous/$1/implementation/$1-implementation-plan.md

Check for:
1. Are components clearly defined with interfaces?
2. Is the implementation sequence dependency-ordered?
3. Are there any obvious blockers or ambiguities?

Output BLOCKER issues for anything that would prevent implementation."
```

### Step 2b: Handle Critic Results

**If BLOCKER issues found**:
1. Log blockers to state file under a `## Plan Validation Issues` section
2. Log to `progress.txt`: `[<timestamp>] PLAN VALIDATION: N blockers found. See state file.`
3. Spawn 1-2 researcher agents to investigate resolutions for the blockers
4. Update state: increment iteration
5. Exit this iteration — next iteration will re-validate after the main instance addresses the blockers in the plan

**If NO BLOCKER issues** (all critics return `NO_BLOCKER_ISSUES`):
1. Proceed to feature list generation

### Step 2c: Generate Feature List

Read the plan and decompose into features:
```json
{
  "features": [
    {
      "id": "F001",
      "name": "<feature name>",
      "description": "<detailed description with acceptance criteria>",
      "component": "<component>",
      "dependencies": [],
      "passes": false,
      "failed": false
    }
  ]
}
```

Write to `docs/autonomous/$1/implementation/feature-list.json`.

**Feature decomposition rules**:
- Each feature should be independently testable
- Order by dependencies (features with no deps first)
- Include infrastructure/project setup as F001 if needed
- Each feature description must have clear acceptance criteria

Append to `docs/autonomous/$1/implementation/progress.txt`:
```
[<timestamp>] Phase C started. Total features: N
```

Update state: set `features_total`, increment iteration.

---

## STEP 3: Implementation Iteration

Same as Phase C in `/autonomous-workflow:full-auto`:

### Find Next Feature

Read `docs/autonomous/$1/implementation/feature-list.json`.

**First**, cascade dependency failures: for each feature where `passes` is `false` and `failed` is `false`, check if ANY feature in its `dependencies` has `failed: true`. If so, immediately mark that feature as `failed: true` in `feature-list.json` and log to `progress.txt`: `[<timestamp>] DEPENDENCY_FAILED: <feature.id> - <feature.name> — dependency <dep.id> failed`. Do NOT stop the workflow — continue scanning remaining features.

**Then**, find the first feature where:
- `passes` is `false`
- `failed` is `false`
- ALL features in `dependencies` have `passes: true`

If no such feature (all passed or failed): go to All Features Resolved.

### Spawn Autonomous Coder

```
Task tool with subagent_type='autonomous-workflow:autonomous-coder'
prompt: "Implement the following feature using TDD:

## Feature Spec
- ID: <feature.id>
- Name: <feature.name>
- Description: <feature.description>
- Component: <feature.component>
- Dependencies: <feature.dependencies> (already implemented and passing)

## Context
- Plan: docs/autonomous/$1/implementation/$1-implementation-plan.md (read the relevant component section)
- Codebase: Explore existing code for patterns and conventions
- CLAUDE.md: Read for coding standards

Implement using strict RED-GREEN-REFACTOR. Commit at each phase. Run the full test suite after refactoring."
```

### Process Result

**If PASSING**: Update `feature-list.json` (`passes: true`), log to `progress.txt`, send notification.

**If FEATURE_FAILED**: Update `feature-list.json` (set `"failed": true`), log failure to `progress.txt`, send notification, move on.

### Update State

Increment `iteration`, `total_iterations_coding`, update `features_complete`, `features_failed`.

### All Features Resolved

When all features resolved (all `passes: true` or `failed: true`):
1. Send notification: `osascript -e 'display notification "All features resolved: N/M passing" with title "Autonomous Workflow" subtitle "$1"'`
2. Update state: `status: complete`, mark Phase C in checklist

Note: The workflow does NOT signal ralph-loop to stop. `--max-iterations` is the only stopping mechanism. Remaining iterations after all features are resolved will detect `status: complete` and skip work.

---

## OUTPUT

```
## Iteration N Complete — Phase C: Implementation

### Feature: <id> - <name>
- Status: PASSING | FAILED
- Tests added: N
- Files changed: N

### Overall Progress
- Features: N/M passing, F failed
- Iterations: N

### Next:
- [Next feature to implement, or "All features resolved"]
```
