---
description: Resume TDD workflow after context clear from saved state
model: opus
argument-hint: <feature-name> [--phase N]
---

# Resume TDD Workflow

**Feature**: $ARGUMENTS

## Purpose

This command resumes the TDD workflow after a `/clear` by:
1. Validating phase prerequisites
2. Reading the saved workflow state
3. Restoring essential context from files
4. Continuing from the specified phase with explicit sequence

---

## STEP 0: Validate Phase Prerequisites

Before resuming, verify the state file shows all prerequisite phases are complete:

### Prerequisites by Phase

| Resume Phase | Required Completed Phases |
|--------------|--------------------------|
| Phase 2 | Phase 1: Exploration |
| Phase 6 | Phases 1-5 (including Review and Approval) |
| Phase 8 | Phases 1-7 |

**Validation Rules:**

If prerequisites are NOT met:
1. List which phases are missing from "Completed Phases" in state file
2. Recommend running the missing phases first
3. Ask user via AskUserQuestionTool if they want to proceed anyway (not recommended)

⚠️ **Critical**: Phases 4 (Plan Review) and 5 (Plan Approval) MUST be completed before Phase 6. These phases ensure the plan is vetted and user-approved before implementation begins.

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

### State File Validation

After reading the state file, verify prerequisites:

1. **Check "Completed Phases" section** matches expected prerequisites for the target phase
2. **If resuming Phase 6** and Phase 4 or Phase 5 not marked complete:
   - WARN: "⚠️ Phase 4 (Plan Review) and/or Phase 5 (Plan Approval) not completed"
   - ASK via AskUserQuestionTool: "Do you want to run the review/approval phases first? (Recommended)"
   - If user says no, proceed but note in state file that review was skipped
3. **If resuming Phase 8** and Phases 6-7 not marked complete:
   - WARN: "⚠️ Implementation phases not completed"
   - ASK via AskUserQuestionTool: "Do you want to complete implementation first?"

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

**Execution Sequence (complete ALL before next checkpoint):**

1. **Phase 2: Interview** - Conduct specification interview using AskUserQuestionTool
   - Ask about goals, constraints, edge cases, success criteria
   - Output: `docs/specs/$1.md`

2. **Phase 3: Planning** - Create implementation plan
   - Spawn `tdd-workflow:code-architect` agent for technical design
   - Output: `docs/plans/$1-plan.md` and `docs/plans/$1-arch.md`

3. **Phase 4: Review** - Invoke plan-reviewer agent to critically analyze the plan
   - Spawn `tdd-workflow:plan-reviewer` agent
   - Challenge assumptions, identify gaps
   - Ask clarifying questions via AskUserQuestionTool
   - Update plans based on feedback

4. **Phase 5: Approval** - Get explicit user approval
   - Present plan summary to user
   - Use AskUserQuestionTool to confirm user is ready to proceed
   - **DO NOT continue without explicit approval**

5. **Checkpoint** - Write updated state file, prompt user to `/clear`
   - Update `docs/workflow/$1-state.md` with completed phases 2-5
   - Tell user: "Context checkpoint reached. Run `/clear` then `/tdd-workflow:resume $1 --phase 6`"

⚠️ **DO NOT skip to implementation.** Complete Phases 2→3→4→5 in sequence.

### If Phase 6: Orchestrated TDD Implementation
- Context is restored from spec and plan
- Verify API keys are available
- Create foundation (shared types) first

**Execution Sequence (complete ALL before next checkpoint):**

1. **Phase 6: TDD Implementation** - Run ralph-loop for each component
   - Main instance owns feedback loop
   - Spawn subagents for discrete tasks:
     - `tdd-workflow:test-designer` - RED phase: write failing tests
     - `tdd-workflow:implementer` - GREEN phase: write minimal code to pass
     - `tdd-workflow:refactorer` - REFACTOR phase: improve while keeping green
   - Repeat for each component in the plan

2. **Phase 7: E2E Testing** - Run ralph-loop for E2E test iteration
   - Spawn `tdd-workflow:test-designer` for E2E tests
   - Run tests, fix failures until all pass
   - Verify integration between components

3. **Checkpoint** - Write updated state file, prompt user to `/clear`
   - Update `docs/workflow/$1-state.md` with completed phases 6-7
   - Tell user: "Implementation complete. Run `/clear` then `/tdd-workflow:resume $1 --phase 8`"

⚠️ **Complete Phase 6→7 before checkpoint.** Do not skip E2E testing.

### If Phase 8: Parallel Review
- Context is restored from spec, plan, and implementation

**Execution Sequence (complete ALL to finish workflow):**

1. **Phase 8: Parallel Review** - Launch 5 `tdd-workflow:code-reviewer` agents in parallel
   - Security reviewer: Check for vulnerabilities, injection risks
   - Performance reviewer: Identify bottlenecks, inefficiencies
   - Quality reviewer: Code style, maintainability, best practices
   - Coverage reviewer: Test coverage gaps, edge cases
   - Spec compliance reviewer: Verify implementation matches spec
   - Consolidate findings into `docs/workflow/$1-review.md`

2. **Phase 9: Final Fixes** - Run ralph-loop to address Critical findings
   - Fix Critical and High severity issues from review
   - Verify tests still pass after each fix
   - Re-run affected reviewers if needed

3. **Phase 10: Completion** - Generate summary report
   - Update final state file with all completed phases
   - Generate completion summary:
     - Features implemented
     - Tests passing
     - Review findings addressed
     - Files created/modified
   - Present completion summary to user

⚠️ **Complete Phase 8→9→10 to finish workflow.** All critical findings must be addressed.

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
