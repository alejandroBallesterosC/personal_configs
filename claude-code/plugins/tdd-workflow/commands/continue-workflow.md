---
description: Continue an in-progress TDD workflow from saved state
model: opus
argument-hint: <feature-name>
---

# Continue TDD Workflow

**Feature**: $1

This command continues an in-progress TDD workflow by reading the saved workflow state and artifacts from the `docs/` directory.

---

## STEP 1: VALIDATE WORKFLOW EXISTS

### Check for `docs/workflow/` directory

First, check if the `docs/workflow/` directory exists. If it does not exist:

**ERROR**: Output the following message and STOP:

```
❌ Error: No workflows are in progress

The docs/workflow/ directory does not exist in this repository.

To start a workflow, use:
  /tdd-workflow:1-start <feature-name> "<feature description>"
```

### Check for workflow state file

If `docs/workflow/` exists, check for `docs/workflow/$1-state.md`. If this file does not exist:

**ERROR**: Output the following message and STOP:

```
❌ Error: No workflow found for feature '$1'

The file docs/workflow/$1-state.md does not exist.

Available workflows in docs/workflow/:
[List all *-state.md files found, or "None" if directory is empty]

To start a workflow for '$1', use:
  /tdd-workflow:1-start $1 "<feature description>"
```

### Check if workflow is complete

If `docs/workflow/$1-state.md` exists, read its contents and check if the workflow is already complete.

The workflow is complete if either:
- The "Current Phase" section contains "COMPLETE"
- The file contains "Status: ✅ COMPLETE"

If the workflow is complete:

**ERROR**: Output the following message and STOP:

```
❌ Error: Workflow for '$1' is already complete

The workflow at docs/workflow/$1-state.md shows status COMPLETE.

To start a fresh workflow with the same feature name:
1. Archive or delete the existing workflow files in docs/
2. Run: /tdd-workflow:1-start $1 "<feature description>"
```

---

## STEP 2: LOAD CONTEXT FOR CONTINUATION

If validation passes, the workflow is in progress. Now restore full context.

### 2.1 Announce Skill Usage

Output:
```
📋 Continuing TDD workflow for '$1'

I'm using the **tdd-workflow-guide** skill to help navigate this workflow.
```

### 2.2 Read All Context Restoration Files

Read the following files (in order) to fully restore context:

1. **State file** (already read in validation): `docs/workflow/$1-state.md`
2. **Exploration context**: `docs/context/$1-exploration.md` (if exists)
3. **Specification**: `docs/specs/$1.md` (if exists)
4. **Architecture**: `docs/plans/$1-arch.md` (if exists)
5. **Implementation plan**: `docs/plans/$1-plan.md` (if exists)
6. **Test strategy**: `docs/plans/$1-tests.md` (if exists)
7. **Review findings**: `docs/workflow/$1-review.md` (if exists)
8. **Project conventions**: `CLAUDE.md`

For each file that exists, read it completely. Skip files that don't exist (they may not have been created yet depending on the current phase).

### 2.3 Summarize Current State

After reading all files, output a summary:

```markdown
## Workflow Context Restored

**Feature**: $1

### Current State (from state file)
- **Phase**: [Current phase from state file]
- **Component**: [If applicable, from state file]
- **Last Action**: [From state file]
- **Next Action**: [From state file]

### Artifacts Loaded
- [x] State file: docs/workflow/$1-state.md
- [x/blank] Exploration: docs/context/$1-exploration.md
- [x/blank] Specification: docs/specs/$1.md
- [x/blank] Architecture: docs/plans/$1-arch.md
- [x/blank] Implementation plan: docs/plans/$1-plan.md
- [x/blank] Test strategy: docs/plans/$1-tests.md
- [x/blank] Review findings: docs/workflow/$1-review.md
- [x] Project conventions: CLAUDE.md

### Key Decisions (from state file)
[List any key decisions recorded in the state file]

### Blockers (if any)
[List any blockers recorded in the state file]
```

---

## STEP 3: CONTINUE THE WORKFLOW

Based on the current phase from the state file, continue the workflow using the appropriate approach.

### Phase Continuation Mapping

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

### Continuation Instructions

Based on the **Current Phase** and **Next Action** from the state file:

1. **Understand the full context** from all loaded artifacts
2. **Identify exactly where we left off** from the state file's "Session Progress" or "Next Action" section
3. **Continue the workflow** following the instructions in `1-start.md` for that phase

### For Implementation Phases (7, 8, 9)

If the current phase involves ralph-loop (Phases 7, 8, or 9):

1. Read `docs/plans/$1-plan.md` to identify components and their status
2. Check which components are complete (from state file or git history)
3. Resume ralph-loop for the current/next incomplete component:

```
/ralph-loop:ralph-loop "Continue implementing [Next Component] for $1 using orchestrated TDD.

## Context
[Include relevant context from loaded artifacts]

## Component Details
- **Component**: [From plan]
- **Status**: Resuming from [where we left off]
- **Remaining Requirements**: [List from plan/state]

## TDD Cycle
[Follow same TDD cycle as defined in 1-start.md]

## Completion
Output: COMPONENT_$1_[Component]_COMPLETE
" --max-iterations 50 --completion-promise "COMPONENT_$1_[Component]_COMPLETE"
```

### For Planning Phases (2-6)

If the current phase is a planning phase:

1. Review what has been completed for that phase (from state file)
2. Continue from where we left off
3. For Phase 3 (Interview): Continue asking questions from where we stopped
4. For Phases 4-6: Complete the current analysis/design/review task

---

## IMPORTANT NOTES

### Automatic Context Preservation

The TDD workflow uses hooks for automatic context preservation:
- **PreCompact hook**: Saves state before any compaction
- **SessionStart hook**: Restores context after compaction

This command (`/continue-workflow`) is for **manual continuation** in scenarios where:
- You're starting a fresh session (not triggered by compaction)
- The automatic hooks didn't fire
- You want to explicitly resume a specific workflow by name

### ralph-loop Dependency

Phases 7, 8, and 9 require the `ralph-loop` plugin. Ensure it's installed:

```
/plugin marketplace add anthropics/claude-code
/plugin install ralph-wiggum
```

**Safety**: Always set `--max-iterations` to prevent runaway costs (50 iterations ≈ $50-100+).

### Maintaining State

As you continue the workflow:
- The state file will be automatically updated by the PreCompact hook
- If making significant progress, you can manually update `docs/workflow/$1-state.md`
- Key decisions should be recorded in the "Key Decisions" section

---

## BEGIN CONTINUATION

Now execute the steps above:

1. ✅ Validate workflow exists (check docs/workflow/$1-state.md)
2. ✅ Load all context restoration files
3. ✅ Continue workflow from current phase

Starting validation...
