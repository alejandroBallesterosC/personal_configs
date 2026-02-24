---
description: "Mode 3: Autonomous research, planning, and TDD implementation without human interaction"
model: opus
argument-hint: <project-name> "Your detailed prompt..."
---

# ABOUTME: Mode 3 command that runs research, planning, and TDD implementation autonomously.
# ABOUTME: One iteration per invocation across three phases; ralph-loop drives continuation.

# Full Autonomous Workflow

**Project**: $1
**Prompt**: $2

## Objective

Run ONE ITERATION of research (Phase A), planning (Phase B), or implementation (Phase C). The workflow transitions automatically between phases. Ralph-loop calls this command repeatedly for multi-day execution.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `docs/research-$1/$1-state.md` exists.

### If state file does NOT exist (first iteration):

Same as `/autonomous-workflow:research-and-plan` initialization, but with:
- `workflow_type: autonomous-full-auto`
- Add `## Implementation Progress` section to state file
- Add `features_total: 0`, `features_complete: 0`, `features_failed: 0` to YAML frontmatter
- Add Phase C to the Completed Phases checklist

### If state file EXISTS:

1. Read state file and extract `current_phase`
2. Read relevant documents based on phase
3. Proceed to the appropriate phase below

---

## PHASE A: Research

**You MUST read `/autonomous-workflow:research` (Steps 2-8) AND `/autonomous-workflow:research-and-plan` (Phase A) before executing this phase.** The full iteration logic lives in those commands. This phase follows the same logic with research focused on: technical feasibility, competitive landscape, architecture patterns, defensibility, technology stack.

Phase transition trigger: `consecutive_low_findings >= phase_transition_threshold`.

On transition: compile report, create plan `.tex` from template (replace `PLACEHOLDER_TITLE` with project name), send notification, update state to Phase B, continue to Phase B in this same iteration.

---

## PHASE B: Planning

**You MUST read `/autonomous-workflow:research-and-plan` (Phase B) before executing this phase.** The full planning iteration logic lives in that command.

Planning stability trigger: `consecutive_no_blockers >= 2`.

### Phase B → C Transition (differs from Mode 2)

When planning is stable, instead of marking complete:

1. **Generate feature-list.json**:
   Read the plan `.tex` and decompose it into implementable features:
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
   Write to `docs/research-$1/feature-list.json`.

   **Feature decomposition rules**:
   - Each feature should be independently testable
   - Order by dependencies (features with no deps first)
   - Include infrastructure setup as F001 if needed
   - Each feature description must have clear acceptance criteria
   - Aim for 5-30 features depending on project scope

2. **Create progress.txt**:
   ```
   # Implementation Progress: $1
   # Generated from plan at docs/research-$1/$1-plan.tex

   [<timestamp>] Phase C started. Total features: N
   ```

3. **Create init.sh** (if the plan mentions databases, servers, or infrastructure):
   A shell script that sets up the development environment. If the plan is purely library code, skip this.

4. **Compile both LaTeX documents** (phase boundary):
   Spawn `autonomous-workflow:latex-compiler`

5. **Send notification**:
   ```
   Run via Bash: osascript -e 'display notification "Planning complete — starting implementation" with title "Autonomous Workflow" subtitle "$1"'
   ```

6. **Update state**:
   - Mark Phase B as complete
   - Set `current_phase: "Phase C: Implementation"`
   - Set `features_total` to the count of features in JSON
   - Reset counters

---

## PHASE C: Implementation

### Step C1: Find Next Feature

Read `docs/research-$1/feature-list.json` and find the first feature where:
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
- Plan: docs/research-$1/$1-plan.tex (read the relevant component section)
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

1. **Compile final LaTeX documents**:
   Spawn `autonomous-workflow:latex-compiler` for both report and plan

2. **Send completion notification**:
   ```
   Run via Bash: osascript -e 'display notification "Implementation complete: N/M features passing" with title "Autonomous Workflow" subtitle "$1"'
   ```

3. **Update state**:
   - Mark Phase C as complete
   - Set `status: complete`

4. **Signal completion to ralph-loop**:
   Output `<promise>WORKFLOW_COMPLETE</promise>` so ralph-loop stops iterating.

5. **Output final summary** (see OUTPUT section)

---

## OUTPUT

```
## Iteration N Complete — [Phase A | Phase B | Phase C]

### [Phase-specific summary]
- [Phase A: New findings count and summaries]
- [Phase B: Plan updates and blocker count]
- [Phase C: Feature implemented/failed, test results]

### Overall Progress
- Research iterations: N
- Planning iterations: N
- Coding iterations: N
- Features: N/M passing, F failed

### Next Iteration Focus:
- [What happens next]
```
