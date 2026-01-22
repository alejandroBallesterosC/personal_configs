---
description: Resume TDD workflow after context clear from saved state
model: opus
argument-hint: <feature-name> [--phase N]
---

# Resume TDD Workflow

**Feature**: $ARGUMENTS

## Purpose

This command resumes the TDD workflow after a `/clear` by:
1. Reading the saved workflow state
2. Restoring essential context from files
3. Continuing from the specified phase

---

## STEP 1: Read Workflow State

Read `docs/workflow/$1-state.md` to understand:
- Current phase
- Completed phases
- Key decisions made
- Files to read for context

If the state file doesn't exist, inform the user:
```
No workflow state found for "$1".

To start a new workflow, run:
/tdd-workflow:start $1 "description"

Or check if the feature name is correct.
```

---

## STEP 2: Restore Context

Based on the current phase, read the required context files:

### For Phase 2 (Specification Interview):
```
Read in order:
1. docs/workflow/$1-state.md
2. docs/context/$1-exploration.md
3. CLAUDE.md
```

### For Phase 6 (Orchestrated TDD Implementation):
```
Read in order:
1. docs/workflow/$1-state.md
2. docs/specs/$1.md (ESSENTIAL)
3. docs/plans/$1-plan.md (ESSENTIAL)
4. docs/plans/$1-arch.md
5. CLAUDE.md
```

### For Phase 8 (Parallel Review):
```
Read in order:
1. docs/workflow/$1-state.md
2. docs/specs/$1.md
3. docs/plans/$1-plan.md
4. CLAUDE.md
5. [Implementation files from state]
```

---

## STEP 3: Display Context Summary

After reading files, output a brief summary:

```markdown
## Context Restored for: $1

### Current Phase
[Phase N: Name]

### Completed
[List completed phases]

### Key Context
- Spec: [brief summary]
- Plan: [components to implement]
- Decisions: [key decisions]

### Resuming...
Continuing with Phase [N]...
```

---

## STEP 4: Continue Workflow

Based on the current phase from the state file, continue execution:

### If Phase 2: Specification Interview
- Context is restored from exploration
- Begin the interview process with AskUserQuestionTool
- Follow Phase 2 instructions from start.md

### If Phase 6: Orchestrated TDD Implementation
- Context is restored from spec and plan
- Verify API keys are available
- Create foundation (shared types) first
- Run ralph-loop for each component (main instance owns feedback loop)
- Follow Phase 6 instructions from start.md

### If Phase 8: Parallel Review
- Context is restored from spec, plan, and implementation
- Launch 5 parallel review subagents
- Follow Phase 8 instructions from start.md

---

## Phase Detection

If `--phase N` is provided, use that phase.

Otherwise, detect from `docs/workflow/$1-state.md`:
- Read "Current Phase" section
- Extract phase number
- Continue from that phase

---

## Error Handling

### Missing State File
```
Error: No workflow state found at docs/workflow/$1-state.md

Options:
1. Start new workflow: /tdd-workflow:start $1 "description"
2. Check feature name spelling
3. Manually create state file if resuming from crash
```

### Missing Context Files
```
Warning: Some context files are missing.

Missing:
- [list missing files]

Options:
1. Re-run previous phase to regenerate
2. Continue with partial context (may affect quality)
3. Start fresh: /tdd-workflow:start $1 "description"
```

### Invalid Phase
```
Error: Phase [N] is not a valid resume point.

Valid resume phases:
- Phase 2: After exploration
- Phase 6: After planning
- Phase 8: After implementation

Current workflow is at Phase [X].
```

---

## Output

After successful context restoration:

```markdown
## Workflow Resumed: $1

✅ State loaded from: docs/workflow/$1-state.md
✅ Context restored from [N] files
✅ Ready to continue Phase [X]

---

[Continue with phase instructions...]
```
