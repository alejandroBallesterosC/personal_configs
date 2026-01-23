---
description: Reinitialize context after /clear and continue TDD workflow from saved state
model: opus
argument-hint: <feature-name> [--phase N]
---

# Reinitialize Context and Continue TDD Workflow

**Feature**: $ARGUMENTS

## Purpose

This command reinitializes context and continues the TDD workflow after a `/clear` by:
1. Validating phase prerequisites
2. Reading the saved workflow state
3. Restoring essential context from files
4. Continuing from the specified phase with explicit execution sequence

---

## STEP 0: Validate Phase Prerequisites

Before resuming, verify the state file shows all prerequisite phases are complete:

### Prerequisites by Phase

| Resume Phase | Required Completed Phases |
|--------------|--------------------------|
| Phase 3 | Phase 2: Exploration |
| Phase 7 | Phases 2-6 (including Review and Approval) |
| Phase 9 | Phases 2-8 |

**Validation Rules:**

If prerequisites are NOT met:
1. List which phases are missing from "Completed Phases" in state file
2. Recommend running the missing phases first
3. Ask user via AskUserQuestionTool if they want to proceed anyway (not recommended)

⚠️ **Critical**: Phase 6 (Plan Review & Approval) MUST be completed before Phase 7. This phase ensures the plan is vetted and user-approved before implementation begins.

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
/tdd-workflow:1-start $1 "description"

Or check if the feature name is correct.
```

### State File Validation

After reading the state file, verify prerequisites:

1. **Check "Completed Phases" section** matches expected prerequisites for the target phase
2. **If resuming Phase 7** and Phase 6 not marked complete:
   - WARN: "⚠️ Phase 6 (Plan Review & Approval) not completed"
   - ASK via AskUserQuestionTool: "Do you want to run the review/approval phase first? (Recommended)"
   - If user says no, proceed but note in state file that review was skipped
3. **If resuming Phase 9** and Phases 7-8 not marked complete:
   - WARN: "⚠️ Implementation phases not completed"
   - ASK via AskUserQuestionTool: "Do you want to complete implementation first?"

---

## STEP 2: Restore Context

Based on the current phase, read the required context files:

### For Phase 3 (Specification Interview):
```
Read in order:
1. docs/workflow/$1-state.md
2. docs/context/$1-exploration.md
3. CLAUDE.md
```

### For Phase 7 (Orchestrated TDD Implementation):
```
Read in order:
1. docs/workflow/$1-state.md
2. docs/specs/$1.md (ESSENTIAL)
3. docs/plans/$1-plan.md (ESSENTIAL)
4. docs/plans/$1-arch.md
5. CLAUDE.md
```

### For Phase 9 (Review, Fixes & Completion):
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

Based on the current phase from the state file, continue execution.

**Important:** For detailed execution instructions (agent prompts, ralph-loop invocations, interview questions), read the corresponding sections from:
`claude-code/plugins/tdd-workflow/commands/1-start.md`

---

### If Phase 3: Specification Interview

**Context restored. Execute Phases 3→4→5→6 in sequence.**

Read and execute these sections from `1-start.md`:

| Section to Find | What to Do | Standalone Command |
|-----------------|------------|-------------------|
| `## PHASE 3: SPECIFICATION INTERVIEW` | Conduct 40+ question interview | `/tdd-workflow:3-user-specification-interview` |
| `## PHASE 4: ARCHITECTURE DESIGN` | Create technical architecture | `/tdd-workflow:4-plan-architecture` |
| `## PHASE 5: IMPLEMENTATION PLAN` | Create implementation plan from architecture | `/tdd-workflow:5-plan-implementation` |
| `## ══════ CONTEXT CHECKPOINT 2 ══════` | Save state and prompt user to `/clear` | - |

**Outputs:**
- `docs/specs/$1.md` (specification from Phase 3)
- `docs/plans/$1-arch.md` (architecture from Phase 4)
- `docs/plans/$1-plan.md` (implementation plan from Phase 5)
- `docs/plans/$1-tests.md` (test cases from Phase 5)
- Updated `docs/workflow/$1-state.md`

**Next checkpoint command:**
```
/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow $1 --phase 7
```

⚠️ **DO NOT skip to implementation.** Complete Phases 3→4→5→6 in sequence. Phase 6 (Plan Review & Approval) requires explicit user approval.

---

### If Phase 7: Orchestrated TDD Implementation

**Context restored. Execute Phases 7→8 in sequence.**

Read and execute these sections from `1-start.md`:

| Section to Find | What to Do |
|-----------------|------------|
| `## PHASE 7: COMPONENT IMPLEMENTATION` | Run ralph-loop for TDD implementation of each component |
| `## PHASE 8: END-TO-END TESTING` | Run ralph-loop for E2E test iteration |
| `## ══════ CONTEXT CHECKPOINT 3 ══════` | Save state and prompt user to `/clear` |

**Key Points (from 1-start.md):**
- Main instance owns the feedback loop (runs ralph-loop and tests)
- Subagents do discrete tasks: test-designer (RED), implementer (GREEN), refactorer
- Use real API implementations, not mocks
- Verify API keys are available before starting

**Outputs:**
- Implementation files (per plan)
- Test files (unit + E2E)
- Updated `docs/workflow/$1-state.md`

**Next checkpoint command:**
```
/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow $1 --phase 9
```

⚠️ **Complete Phase 7→8 before checkpoint.** Do not skip E2E testing.

---

### If Phase 9: Review, Fixes & Completion

**Context restored. Execute Phase 9 to complete workflow.**

Read and execute these sections from `1-start.md`:

| Section to Find | What to Do |
|-----------------|------------|
| `## PHASE 9: REVIEW, FIXES & COMPLETION` | Launch 5 code-reviewer agents, fix critical issues, complete workflow |

**Review Focus Areas (5 parallel agents):**
1. Security - vulnerabilities, injection risks
2. Performance - bottlenecks, inefficiencies
3. Code Quality - style, maintainability
4. Test Coverage - gaps, edge cases
5. Spec Compliance - implementation matches spec

**Outputs:**
- `docs/workflow/$1-review.md` (consolidated findings)
- Final `docs/workflow/$1-state.md` (marked COMPLETE)
- Completion summary presented to user

⚠️ **Complete Phase 9 to finish workflow.** All critical findings must be addressed before completion.

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
1. Start new workflow: /tdd-workflow:1-start $1 "description"
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
3. Start fresh: /tdd-workflow:1-start $1 "description"
```

### Invalid Phase
```
Error: Phase [N] is not a valid resume point.

Valid resume phases:
- Phase 3: After exploration
- Phase 7: After planning
- Phase 9: After implementation

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
