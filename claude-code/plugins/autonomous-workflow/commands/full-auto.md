---
description: "Mode 3: Autonomous research, planning, and TDD implementation without human interaction"
model: opus
argument-hint: <project-name> "Your detailed prompt..." [research-budget] [planning-budget]
---

# ABOUTME: Mode 3 command that runs research, planning, and TDD implementation autonomously.
# ABOUTME: Budget-based phase transitions for A->B and B->C; implementation completes naturally.

# Full Autonomous Workflow

**Project**: $1
**Prompt**: $2
**Research Budget**: $3 (optional — number of research iterations before transitioning to planning. Default: 30)
**Planning Budget**: $4 (optional — number of planning iterations before transitioning to implementation. Default: 15)

## Objective

Run ONE ITERATION of research (Phase A), planning (Phase B), or implementation (Phase C). The workflow transitions between phases based on iteration budgets. Ralph-loop calls this command repeatedly for multi-day execution.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `docs/autonomous/$1/research/$1-state.md` exists.

### If state file does NOT exist (first iteration):

Same as `/autonomous-workflow:research-and-plan` initialization, but with:
- `workflow_type: autonomous-full-auto`
- Parse research budget: if $3 is provided and is a number, use it; otherwise default to 30
- Parse planning budget: if $4 is provided and is a number, use it; otherwise default to 15
- Add `research_budget` and `planning_budget` to YAML frontmatter
- Add `## Implementation Progress` section to state file
- Add `features_total: 0`, `features_complete: 0`, `features_failed: 0`, `total_iterations_coding: 0` to YAML frontmatter
- Add Phase C to the Completed Phases checklist

### If state file EXISTS:

1. Read state file and extract `current_phase`
2. Read relevant documents based on phase
3. Proceed to the appropriate phase below

---

## PHASE A: Research

**You MUST read `/autonomous-workflow:research` (Steps 2-8) AND `/autonomous-workflow:research-and-plan` (Phase A) before executing this phase.** The full iteration logic lives in those commands. This phase follows the same logic with research focused on: technical feasibility, competitive landscape, architecture patterns, defensibility, technology stack.

Uses strategy rotation from `/autonomous-workflow:research` Step 7 (never auto-terminates within Phase A).

Phase transition trigger: `total_iterations_research >= research_budget`.

On transition: compile report, create implementation directory and Markdown plan at `docs/autonomous/$1/implementation/$1-implementation-plan.md`, set research state to `complete`, create implementation state file at `docs/autonomous/$1/implementation/$1-state.md` with `current_phase: "Phase B: Planning"`, send notification, continue to Phase B in this same iteration. Follow the same Phase A->B transition logic from `/autonomous-workflow:research-and-plan`.

---

## PHASE B: Planning

**You MUST read `/autonomous-workflow:research-and-plan` (Phase B) before executing this phase.** The full planning iteration logic lives in that command.

Phase transition trigger: `total_iterations_planning >= planning_budget`.

### Phase B -> C Transition (differs from Mode 2)

When planning budget is exhausted:

1. **Generate feature-list.json**:
   Read the plan `.md` and decompose it into implementable features:
   ```json
   {
     "features": [
       {
         "id": "F001",
         "name": "<feature name>",
         "description": "<detailed description with acceptance criteria>",
         "component": "<component from plan>",
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
   - Include infrastructure setup as F001 if needed
   - Each feature description must have clear acceptance criteria
   - Aim for 5-30 features depending on project scope

2. **Create progress.txt**:
   ```
   # Implementation Progress: $1
   # Generated from plan at docs/autonomous/$1/implementation/$1-implementation-plan.md

   [<timestamp>] Phase C started. Total features: N
   ```
   Write to `docs/autonomous/$1/implementation/progress.txt`.

3. **Create init.sh** (if the plan mentions databases, servers, or infrastructure):
   A shell script that sets up the development environment. If the plan is purely library code, skip this.

4. **Compile research report** (phase boundary):
   Spawn `autonomous-workflow:latex-compiler` to compile `docs/autonomous/$1/research/$1-report.tex`

5. **Send notification**:
   ```
   Run via Bash: osascript -e 'display notification "Planning budget reached — starting implementation" with title "Autonomous Workflow" subtitle "$1"'
   ```

6. **Update state**:
   - Mark Phase B as complete
   - Set `current_phase: "Phase C: Implementation"`
   - Set `features_total` to the count of features in JSON
   - Reset counters

---

## PHASE C: Implementation

### Step C1: Find Next Feature

Read `docs/autonomous/$1/implementation/feature-list.json`.

**First**, cascade dependency failures: for each feature where `passes` is `false` and `failed` is `false`, check if ANY feature in its `dependencies` has `failed: true`. If so, immediately mark that feature as `failed: true` in `feature-list.json` and log to `progress.txt`: `[<timestamp>] DEPENDENCY_FAILED: <feature.id> - <feature.name> — dependency <dep.id> failed`. Do NOT stop the workflow — continue scanning remaining features.

**Then**, find the first feature where:
- `passes` is `false`
- `failed` is `false`
- ALL features listed in `dependencies` have `passes: true`

If no such feature exists:
- If all features have `passes: true` or `failed: true`: implementation is COMPLETE
- In this case: go to Step C5 (Completion)

### Step C2: Spawn Autonomous Coder

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

### Step C3: Process Result

Read the autonomous-coder agent's output:

**If PASSING** (tests pass):
1. Update `feature-list.json`: set `"passes": true` for this feature
2. Append to `progress.txt`: `[<timestamp>] PASS: <feature.id> - <feature.name>`
3. Send notification:
   ```
   Run via Bash: osascript -e 'display notification "Feature <feature.id> complete" with title "Autonomous Workflow" subtitle "$1"'
   ```

**If FEATURE_FAILED**:
1. Update `feature-list.json`: set `"failed": true` for this feature (leave `passes` as `false`)
2. Append to `progress.txt`: `[<timestamp>] FAIL: <feature.id> - <feature.name> - Reason: <reason>`
3. Send notification:
   ```
   Run via Bash: osascript -e 'display notification "Feature <feature.id> FAILED after 3 attempts" with title "Autonomous Workflow" subtitle "$1"'
   ```

### Step C4: Update State

1. Increment `iteration` and `total_iterations_coding`
2. Update `features_complete` (count of `passes: true` in JSON)
3. Update `features_failed` (count of `failed: true` in feature-list.json)

### Step C5: Completion Check

If all features are resolved (passed or failed):

1. **Compile final research report**:
   Spawn `autonomous-workflow:latex-compiler` for the report at `docs/autonomous/$1/research/$1-report.tex`

2. **Send completion notification**:
   ```
   Run via Bash: osascript -e 'display notification "Implementation complete: N/M features passing" with title "Autonomous Workflow" subtitle "$1"'
   ```

3. **Update state**:
   - Mark Phase C as complete
   - Set `status: complete`

4. **Signal completion to ralph-loop**:
   Output `<promise>WORKFLOW_COMPLETE</promise>` so ralph-loop stops iterating.
   (Both Mode 3 and Mode 4 emit WORKFLOW_COMPLETE on Phase C completion. Research and planning never emit it.)

5. **Output final summary** (see OUTPUT section)

---

## OUTPUT

```
## Iteration N Complete — [Phase A | Phase B | Phase C]

### [Phase-specific summary]
- [Phase A: Strategy, contributions, strategy progress]
- [Phase B: Plan updates, blocker count]
- [Phase C: Feature implemented/failed, test results]

### Overall Progress
- Research iterations: N/budget
- Planning iterations: N/budget
- Coding iterations: N
- Features: N/M passing, F failed

### Next Iteration Focus:
- [What happens next]
```
