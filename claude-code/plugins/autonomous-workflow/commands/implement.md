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

Check if `docs/research-$1/$1-state.md` exists.

### If state file does NOT exist (first run):

#### Plan Detection

Search for an existing plan in this order:
1. `docs/research-$1/$1-plan.tex`
2. `docs/research-$1/$1-plan.md`
3. `docs/$1-plan.tex`
4. `docs/$1-plan.md`

If NONE found, output this error and stop:
```
ERROR: No plan found for project '$1'.

Searched:
- docs/research-$1/$1-plan.tex
- docs/research-$1/$1-plan.md
- docs/$1-plan.tex
- docs/$1-plan.md

Create a plan first using /autonomous-workflow:research-and-plan, or place a plan at one of the above paths.
```

#### Initialize State

1. Create directory `docs/research-$1/` and `docs/research-$1/transcripts/` (if they don't exist)

2. Create state file `docs/research-$1/$1-state.md`:
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
   plan_source: "<path to plan found above>"
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
   1. docs/research-$1/$1-state.md (this file)
   2. <plan_source path>
   3. docs/research-$1/feature-list.json (after first iteration)
   4. docs/research-$1/progress.txt (after first iteration)
   5. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file
2. Check if `docs/research-$1/feature-list.json` exists
3. If feature-list.json exists: skip to STEP 3 (resume implementation)
4. If feature-list.json does NOT exist: proceed to STEP 2 (validate plan and generate features)

---

## STEP 2: Validate Plan and Generate Feature List

This step runs on the first iteration when no `feature-list.json` exists yet.

### Step 2a: Validate Plan

Read the plan source identified in state file's `plan_source` field.

Spawn 2 parallel plan-critic agents:
```
Task tool with subagent_type='autonomous-workflow:plan-critic'
prompt: "Validate whether this plan is implementable.

Plan: <plan_source path>

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

Write to `docs/research-$1/feature-list.json`.

**Feature decomposition rules**:
- Each feature should be independently testable
- Order by dependencies (features with no deps first)
- Include infrastructure/project setup as F001 if needed
- Each feature description must have clear acceptance criteria

Create `docs/research-$1/progress.txt`:
```
# Implementation Progress: $1
# Plan source: <plan_source>

[<timestamp>] Phase C started. Total features: N
```

Update state: set `features_total`, increment iteration.

---

## STEP 3: Implementation Iteration

Same as Phase C in `/autonomous-workflow:full-auto`:

### Find Next Feature

Read `docs/research-$1/feature-list.json` and find the first feature where:
- `passes` is `false`
- `failed` is `false`
- ALL features in `dependencies` have `passes: true`

If no such feature (all passed or failed): go to Completion.

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
- Plan: <plan_source> (read the relevant component section)
- Codebase: Explore existing code for patterns and conventions
- CLAUDE.md: Read for coding standards

Implement using strict RED-GREEN-REFACTOR. Commit at each phase. Run the full test suite after refactoring."
```

### Process Result

**If PASSING**: Update `feature-list.json` (`passes: true`), log to `progress.txt`, send notification.

**If FEATURE_FAILED**: Update `feature-list.json` (set `"failed": true`), log failure to `progress.txt`, send notification, move on.

### Update State

Increment `iteration`, `total_iterations_coding`, update `features_complete`, `features_failed`.

### Completion

When all features resolved (all `passes: true` or `failed: true`):
1. Send notification: `osascript -e 'display notification "Implementation complete: N/M features passing" with title "Autonomous Workflow" subtitle "$1"'`
2. Update state: `status: complete`, mark Phase C complete
3. Output `<promise>WORKFLOW_COMPLETE</promise>` so ralph-loop stops iterating

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
- [Next feature to implement, or "Complete"]
```
