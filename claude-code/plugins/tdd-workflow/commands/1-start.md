---
description: Start the fully orchestrated TDD workflow with parallel subagents
model: opus
argument-hint: <feature-name> "<feature description>"
---

# TDD Workflow - Fully Orchestrated

**Feature**: $1
**Description**: $2

This command orchestrates a complete, planning-heavy TDD workflow (8 phases) that runs automatically from start to finish. You only need to respond when asked questions or approve plans.

---

## PREREQUISITES

Before starting, complete these steps:

1. **Load workflow context**: Use the Skill tool to invoke `tdd-workflow:tdd-workflow-guide`
   - This loads the workflow overview, phase diagram, key principles, and context management details
   - **REQUIRED**: Do this before proceeding

2. **Verify ralph-loop plugin** is installed (required for Phases 7, 8, 9)
   - Check that the `ralph-loop` plugin is available
   - If not installed, inform the user and stop

---

## CONTEXT MANAGEMENT

Context is managed **automatically via hooks** - no manual intervention needed:
- **PreCompact hook** saves progress to `docs/workflow-$1/$1-state.md` before compaction
- **SessionStart hook** restores context after compaction (and instructs to load the skill)

---

## WORKFLOW EXECUTION

Execute each phase in sequence. Each phase has its own command with detailed instructions.

### Initialize Workflow Directory and Files

Create the workflow directory structure and initial files:

#### 1. Create Directory Structure
```
docs/workflow-$1/
├── codebase-context/
├── plans/
├── specs/
├── $1-state.md
└── $1-original-prompt.md
```

#### 2. Save Original Prompt

Create `docs/workflow-$1/$1-original-prompt.md`:

```markdown
# Original Prompt: $1

## Feature Request
**Feature Name**: $1
**Description**: $2

## Timestamp
[Current date/time]

## Context
[Any additional context from the user's request]
```

#### 3. Create State File

Create `docs/workflow-$1/$1-state.md`:

```markdown
# Workflow State: $1

## Current Phase
Phase 2: Exploration

## Feature
- **Name**: $1
- **Description**: $2

## Completed Phases
- [ ] Phase 2: Exploration
- [ ] Phase 3: Interview
- [ ] Phase 4: Architecture
- [ ] Phase 5: Implementation Plan
- [ ] Phase 6: Plan Review
- [ ] Phase 7: Implementation
- [ ] Phase 8: E2E Testing
- [ ] Phase 9: Review & Completion

## Key Decisions
(To be filled as workflow progresses)

## Context Restoration Files
1. docs/workflow-$1/$1-state.md (this file)
2. docs/workflow-$1/$1-original-prompt.md
3. docs/workflow-$1/codebase-context/$1-exploration.md
4. docs/workflow-$1/specs/$1-specs.md
5. docs/workflow-$1/plans/$1-architecture-plan.md
6. docs/workflow-$1/plans/$1-implementation-plan.md
7. CLAUDE.md
```

---

## PHASE 2: PARALLEL CODEBASE EXPLORATION

**What**: 5 parallel agents explore Architecture, Patterns, Boundaries, Testing, Dependencies
**Output**: `docs/workflow-$1/codebase-context/$1-exploration.md`
**Agents**: 5x `code-explorer` (Sonnet with 1M context)

Execute by following the instructions in the `2-explore` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 2 complete
- Ask user to continue to Phase 3

---

## PHASE 3: SPECIFICATION INTERVIEW

**What**: 40+ questions across 9 domains via AskUserQuestionTool
**Output**: `docs/workflow-$1/specs/$1-specs.md`
**Prerequisite**: `docs/workflow-$1/codebase-context/$1-exploration.md` exists

Execute by following the instructions in the `3-user-specification-interview` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 3 complete
- Continue to Phase 4

---

## PHASE 4: ARCHITECTURE DESIGN

**What**: Technical architecture with independent components for parallel implementation
**Output**: `docs/workflow-$1/plans/$1-architecture-plan.md`
**Prerequisites**: Exploration and specification exist

Execute by following the instructions in the `4-plan-architecture` command with feature: $1

After completion:
- Update state file: mark Phase 4 complete
- Continue to Phase 5

---

## PHASE 5: IMPLEMENTATION PLAN

**What**: Detailed implementation tasks mapped from architecture
**Output**: `docs/workflow-$1/plans/$1-implementation-plan.md`, `docs/workflow-$1/plans/$1-tests.md`
**Prerequisite**: Architecture exists

Execute by following the instructions in the `5-plan-implementation` command with feature: $1

After completion:
- Update state file: mark Phase 5 complete
- Continue to Phase 6

---

## PHASE 6: PLAN REVIEW & APPROVAL

**What**: Critical review of plan, challenge assumptions, get user approval
**Output**: Updated plans + explicit user approval
**Agent**: `plan-reviewer`

Execute by following the instructions in the `6-review-plan` command with feature: $1

**CRITICAL**: Do NOT proceed to Phase 7 without explicit user approval.

After completion:
- Update state file: mark Phase 6 complete
- Ask user to continue to Phase 7 (implementation)

---

## PHASE 7: ORCHESTRATED TDD IMPLEMENTATION

**What**: TDD implementation with main instance owning feedback loop via ralph-loop
**Output**: Working code with test coverage
**Agents**: `test-designer`, `implementer`, `refactorer` (via ralph-loop)
**Prerequisites**: All planning artifacts exist, user has approved

Execute by following the instructions in the `7-implement` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 7 complete
- Continue to Phase 8

---

## PHASE 8: ORCHESTRATED E2E TESTING

**What**: End-to-end testing with main instance owning feedback loop via ralph-loop
**Output**: Passing E2E test suite
**Agents**: `test-designer`, `implementer` (via ralph-loop)

Execute by following the instructions in the `8-e2e-test` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 8 complete
- Continue to Phase 9

---

## PHASE 9: REVIEW, FIXES & COMPLETION

**What**: 5 parallel reviewers, fix critical issues, generate completion report
**Output**: `docs/workflow-$1/$1-review.md`, completion report
**Agents**: 5x `code-reviewer` (parallel), then `implementer`/`refactorer` (via ralph-loop for fixes)

Execute by following the instructions in the `9-review` command with feature: $1

After completion:
- Update state file: mark Phase 9 complete, set status to COMPLETE
- Generate completion summary
- Offer to create PR

---

## COMPLETION

When all phases are complete, update `docs/workflow-$1/$1-state.md`:

```markdown
## Current Phase
COMPLETE

## Status
✅ COMPLETE
```

Generate a completion report summarizing:
- Components implemented
- Test coverage (unit, integration, E2E)
- External integrations (real vs mocked)
- Review findings addressed
- Files changed
- Next steps

---

## BEGINNING WORKFLOW NOW

Starting **Phase 2: Parallel Codebase Exploration** for "$1"

Follow the instructions in the `2-explore` command to launch 5 parallel exploration subagents...
