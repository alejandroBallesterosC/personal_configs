---
description: Continue an in-progress TDD implementation or debug workflow from saved state
model: opus
argument-hint: <feature-or-bug-name>
---

# Continue Workflow

**Name**: $1

This command continues an in-progress workflow by detecting whether it's a TDD implementation workflow or debug session, then reading the saved state and artifacts.

---

## STEP 1: DETECT AND VALIDATE WORKFLOW EXISTS

### 1.1 Check for TDD implementation workflow

Check if the `docs/workflow-$1/` directory exists AND contains `docs/workflow-$1/$1-state.md`.

### 1.2 Check for debug session

Check if the `docs/debug/$1/` directory exists AND contains `docs/debug/$1/$1-state.md`.

### 1.3 Handle results

- **Neither found**: Output error and STOP:

```
Error: No workflow or debug session found for '$1'

No matching directory found in:
- docs/workflow-$1/ (TDD implementation workflow)
- docs/debug/$1/ (debug session)

Available workflows:
[List all docs/workflow-* directories found, or "None"]

Available debug sessions:
[List all docs/debug/*/ directories found, or "None"]

To start a TDD implementation workflow:
  /dev-workflow:1-start-tdd-implementation <name> "<description>"

To start a debug session:
  /dev-workflow:1-start-debug <bug description>
```

- **TDD found**: Continue with **TDD Implementation Continuation** (Step 2A)
- **Debug found**: Continue with **Debug Continuation** (Step 2B)
- **Both found**: Continue with **TDD Implementation Continuation** first, then mention the debug session exists

---

## STEP 2A: TDD IMPLEMENTATION WORKFLOW CONTINUATION

### Check if complete

If `docs/workflow-$1/$1-state.md` contains "Current Phase" with "COMPLETE" or "Status: COMPLETE":

```
Error: TDD implementation workflow for '$1' is already complete

The workflow at docs/workflow-$1/$1-state.md shows status COMPLETE.

To start a fresh workflow:
1. Archive: mkdir -p docs/archive && mv docs/workflow-$1 docs/archive/workflow-$1
2. Run: /dev-workflow:1-start-tdd-implementation $1 "<description>"
```

### Load context

1. **REQUIRED**: Use the Skill tool to invoke `dev-workflow:tdd-implementation-workflow-guide` to load workflow context
2. Output: `Continuing TDD implementation workflow for '$1'`

### Read all context restoration files (in order)

1. **State file**: `docs/workflow-$1/$1-state.md`
2. **Original prompt**: `docs/workflow-$1/$1-original-prompt.md` (if exists)
3. **Exploration context**: `docs/workflow-$1/codebase-context/$1-exploration.md` (if exists)
4. **Domain research**: `docs/workflow-$1/codebase-context/$1-domain-research.md` (if exists)
5. **Specification**: `docs/workflow-$1/specs/$1-specs.md` (if exists)
6. **Architecture research**: `docs/workflow-$1/plans/$1-architecture-research.md` (if exists)
7. **Architecture**: `docs/workflow-$1/plans/$1-architecture-plan.md` (if exists)
8. **Implementation research**: `docs/workflow-$1/plans/$1-implementation-research.md` (if exists)
9. **Implementation plan**: `docs/workflow-$1/plans/$1-implementation-plan.md` (if exists)
10. **Test strategy**: `docs/workflow-$1/plans/$1-tests.md` (if exists)
11. **Validation research**: `docs/workflow-$1/plans/$1-review-research.md` (if exists)
12. **Review findings**: `docs/workflow-$1/$1-review.md` (if exists)
13. **Project conventions**: `CLAUDE.md`

### Summarize and continue

Output a summary of current state, loaded artifacts, and continue from the current phase.

### Phase continuation mapping

| Current Phase | How to Continue |
|---------------|-----------------|
| Phase 2: Exploration | Continue with exploration synthesis, then Phase 3 |
| Phase 3: Interview | Continue the specification interview |
| Phase 4: Architecture | Continue architecture design, then Phase 5 |
| Phase 5: Implementation Plan | Continue plan creation, then Phase 6 |
| Phase 6: Plan Review | Continue review process until approval |
| Phase 7: Implementation | Resume ralph-loop TDD implementation |
| Phase 8: E2E Testing | Resume ralph-loop E2E testing |
| Phase 9: Review | Continue review/fixes process |

### For Implementation Phases (7, 8, 9)

If the current phase involves ralph-loop:

1. Read `docs/workflow-$1/plans/$1-implementation-plan.md` to identify components and status
2. Check which components are complete (from state file or git history)
3. Resume ralph-loop for the current/next incomplete component

---

## STEP 2B: DEBUG SESSION CONTINUATION

### Check if complete

If `docs/debug/$1/$1-state.md` contains "Current Phase" with "COMPLETE" or all 9 phases checked:

```
Error: Debug session for '$1' is already complete

The session at docs/debug/$1/$1-state.md shows status COMPLETE.

To start a fresh debug session:
1. Archive: mkdir -p docs/archive && mv docs/debug/$1 docs/archive/debug-$1
2. Run: /dev-workflow:1-start-debug <bug description>
```

### Load context

1. **REQUIRED**: Use the Skill tool to invoke `dev-workflow:debug-workflow-guide` to load workflow context
2. Output: `Continuing debug session for '$1'`

### Read all context restoration files (in order)

1. **State file**: `docs/debug/$1/$1-state.md`
2. **Bug description**: `docs/debug/$1/$1-bug.md` (if exists)
3. **Exploration findings**: `docs/debug/$1/$1-exploration.md` (if exists)
4. **Hypotheses**: `docs/debug/$1/$1-hypotheses.md` (if exists)
5. **Log analysis**: `docs/debug/$1/$1-analysis.md` (if exists)
6. **Resolution**: `docs/debug/$1/$1-resolution.md` (if exists)
7. **Project conventions**: `CLAUDE.md`

### Summarize and continue

Output a summary of current state, hypotheses status, loaded artifacts, and continue from the current phase.

### Phase continuation mapping

| Current Phase | How to Continue |
|---------------|-----------------|
| Phase 1: Explore | Continue exploration, then Phase 2 |
| Phase 2: Describe | Continue gathering bug context from user |
| Phase 3: Hypothesize | Continue hypothesis generation |
| Phase 4: Instrument | Continue adding instrumentation |
| Phase 5: Reproduce | Ask user to reproduce and share logs |
| Phase 6: Analyze | Continue log analysis |
| Phase 7: Fix | Apply fix (check 3-Fix Rule) |
| Phase 8: Verify | Guide user through verification |
| Phase 9: Clean | Complete cleanup and archival |

### For Loopback Phases

If the state file indicates a loopback (e.g., "all hypotheses rejected"):

1. Read the analysis file to understand what was rejected and why
2. Use the unexpected findings to generate new hypotheses
3. Continue from Phase 3 with the new context

---

## IMPORTANT NOTES

### Automatic Context Preservation

The dev-workflow plugin uses hooks for automatic context preservation:
- **Stop hook** (agent): Verifies state file is up to date before Claude stops; blocks stopping if outdated
- **SessionStart hook** (command): Restores context after compaction or clear

This command (`/continue-workflow`) is for **manual continuation** in scenarios where:
- You're starting a fresh session (not triggered by compaction/clear)
- You want to explicitly resume a specific workflow by name

### ralph-loop Dependency (TDD only)

Phases 7, 8, and 9 of the TDD implementation workflow require the `ralph-loop` plugin:

```
/plugin marketplace add anthropics/claude-code
/plugin install ralph-wiggum
```

**Safety**: Always set `--max-iterations` to prevent runaway costs (50 iterations = $50-100+).

---

## BEGIN CONTINUATION

Now execute the steps above:

1. Detect workflow type (TDD implementation vs debug)
2. Validate workflow exists and is in progress
3. Load all context restoration files
4. Continue workflow from current phase

Starting detection...
