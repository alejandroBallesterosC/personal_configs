---
description: Start the fully orchestrated TDD implementation workflow with parallel subagents
model: opus
argument-hint: <feature-name> "<feature description>"
---

# TDD Implementation Workflow - Fully Orchestrated

**Feature**: $1
**Description**: $2

This command orchestrates a complete, planning-heavy TDD implementation workflow (8 phases) that runs automatically from start to finish. You only need to respond when asked questions or approve plans.

---

## PREREQUISITES

Before starting, complete these steps:

1. **Load workflow context**: Use the Skill tool to invoke `dev-workflow:tdd-implementation-workflow-guide`
   - This loads the workflow overview, phase diagram, key principles, and context management details
   - **REQUIRED**: Do this before proceeding

---

## GUARD: SINGLE ACTIVE WORKFLOW

Before creating a workflow, check if one is already active:

1. Search for any existing `.plugin-state/workflow-*/*-state.md` files
2. For each found, read the YAML frontmatter `status` field
3. If any has `status: in_progress`, output the following error and **STOP**:

```
Error: An active TDD workflow already exists

Active workflow found: .plugin-state/workflow-<name>/<name>-state.md
Status: in_progress
Current phase: <phase from state file>

Only one TDD workflow can be active at a time. To proceed, either:
1. Continue the existing workflow: /dev-workflow:continue-workflow <name>
2. Complete or archive it first, then start a new one
```

If no active workflow is found (no state files, or all have `status: complete`), proceed.

---

## CONTEXT MANAGEMENT

Context is managed **automatically via hooks** - no manual intervention needed:
- **TDD implementation gate Stop hook** (command) blocks Claude from stopping during Phases 7-9 and re-feeds the current phase command after context compaction
- **SessionStart hook** (command) restores context after compaction or clear

The main Claude instance is responsible for keeping `.plugin-state/workflow-$1/$1-state.md` current, including the `command` field in the YAML frontmatter which the gate hook uses for re-feeding.

---

## WORKFLOW EXECUTION

Execute each phase in sequence. Each phase has its own command with detailed instructions.

### Ensure Project CLAUDE.md

Before creating workflow artifacts, ensure the project has a CLAUDE.md at the repository root for durable project knowledge.

#### If CLAUDE.md does NOT exist

Create a CLAUDE.md at the repository root with:

```markdown
# [Project Name]

[Brief project description - infer from codebase or leave as TODO]

## Development Workflows

- TDD implementation: `/dev-workflow:1-start-tdd-implementation <feature> "<description>"`
- Debug: `/dev-workflow:1-start-debug <bug description>`
- Continue workflow: `/dev-workflow:continue-workflow <name>`
- Workflow guides: `dev-workflow:tdd-implementation-workflow-guide` and `dev-workflow:debug-workflow-guide` skills
- Workflow artifacts: `.plugin-state/workflow-*/` and `.plugin-state/debug/*/`

## Testing

- For TDD practices and test optimization, load the `dev-workflow:testing` skill
- The `.tdd-test-scope` file (written to repo root) controls which tests the dev-workflow stop hook runs
- Framework: [to be filled after Phase 2 exploration]

## Gotchas

[To be filled as workflows discover patterns]
```

#### If CLAUDE.md already exists

Read it and check for these sections. Append any that are missing without overwriting existing content:
- **Development Workflows** section with dev-workflow commands and guide skill references
- **Testing** section with `dev-workflow:testing` skill reference, `.tdd-test-scope` mention, and framework
- **Gotchas** section for workflow-discovered patterns

---

### Initialize Workflow Directory and Files

Create the workflow directory structure and initial files:

#### 1. Create Directory Structure
```
.plugin-state/workflow-$1/
├── codebase-context/
├── plans/
├── specs/
├── $1-state.md
└── $1-original-prompt.md
```

#### 2. Save Original Prompt

Create `.plugin-state/workflow-$1/$1-original-prompt.md`:

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

Create `.plugin-state/workflow-$1/$1-state.md`:

```markdown
---
workflow_type: tdd-implementation
name: $1
description: $2
status: in_progress
current_phase: "Phase 2: Exploration"
command: "/dev-workflow:1-start-tdd-implementation $1 \"$2\""
---

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
1. .plugin-state/workflow-$1/$1-state.md (this file)
2. .plugin-state/workflow-$1/$1-original-prompt.md
3. .plugin-state/workflow-$1/codebase-context/$1-exploration.md
4. .plugin-state/workflow-$1/codebase-context/$1-domain-research.md (if exists)
5. .plugin-state/workflow-$1/specs/$1-specs.md
6. .plugin-state/workflow-$1/plans/$1-architecture-research.md (if exists)
7. .plugin-state/workflow-$1/plans/$1-architecture-plan.md
8. .plugin-state/workflow-$1/plans/$1-implementation-research.md (if exists)
9. .plugin-state/workflow-$1/plans/$1-implementation-plan.md
10. .plugin-state/workflow-$1/plans/$1-review-research.md (if exists)
11. CLAUDE.md
```

---

## PHASE 2: PARALLEL CODEBASE EXPLORATION

**What**: 5 parallel agents explore Architecture, Patterns, Boundaries, Testing, Dependencies
**Output**: `.plugin-state/workflow-$1/codebase-context/$1-exploration.md`
**Agents**: 5x `code-explorer` (Sonnet with 1M context)

Execute by following the instructions in the `2-explore` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 2 complete
- **Update CLAUDE.md Testing section** with the test framework discovered during exploration (if not already populated)
- Ask user to continue to Phase 3

---

## PHASE 3: SPECIFICATION INTERVIEW

**What**: Domain research via 5 parallel researcher agents, then 40+ questions across 9 domains via AskUserQuestionTool
**Output**: `.plugin-state/workflow-$1/codebase-context/$1-domain-research.md`, `.plugin-state/workflow-$1/specs/$1-specs.md`
**Agents**: 5x `researcher` (Sonnet)
**Prerequisite**: `.plugin-state/workflow-$1/codebase-context/$1-exploration.md` exists

Execute by following the instructions in the `3-user-specification-interview` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 3 complete
- Continue to Phase 4

---

## PHASE 4: ARCHITECTURE DESIGN

**What**: Architecture research via 5 parallel researcher agents, then technical architecture with independent components for parallel implementation
**Output**: `.plugin-state/workflow-$1/plans/$1-architecture-research.md`, `.plugin-state/workflow-$1/plans/$1-architecture-plan.md`
**Agents**: 5x `researcher` (Sonnet), optionally `code-architect` (Opus)
**Prerequisites**: Exploration and specification exist

Execute by following the instructions in the `4-plan-architecture` command with feature: $1

After completion:
- Update state file: mark Phase 4 complete
- Continue to Phase 5

---

## PHASE 5: IMPLEMENTATION PLAN

**What**: Implementation research via 4 parallel researcher agents, then detailed implementation tasks mapped from architecture
**Output**: `.plugin-state/workflow-$1/plans/$1-implementation-research.md`, `.plugin-state/workflow-$1/plans/$1-implementation-plan.md`, `.plugin-state/workflow-$1/plans/$1-tests.md`
**Agents**: 4x `researcher` (Sonnet)
**Prerequisite**: Architecture exists

Execute by following the instructions in the `5-plan-implementation` command with feature: $1

After completion:
- Update state file: mark Phase 5 complete
- Continue to Phase 6

---

## PHASE 6: PLAN REVIEW & APPROVAL

**What**: Validation research via 5 parallel researcher agents, then critical review of plan, challenge assumptions, get user approval
**Output**: `.plugin-state/workflow-$1/plans/$1-review-research.md`, updated plans + explicit user approval
**Agents**: 5x `researcher` (Sonnet), `plan-reviewer`

Execute by following the instructions in the `6-review-plan` command with feature: $1

**CRITICAL**: Do NOT proceed to Phase 7 without explicit user approval.

After completion:
- Update state file: mark Phase 6 complete
- Ask user to continue to Phase 7 (implementation)

---

## PHASE 7: ORCHESTRATED TDD IMPLEMENTATION

**What**: TDD implementation with main instance owning feedback loop directly
**Output**: Working code with test coverage
**Agents**: `test-designer`, `implementer`, `refactorer` (spawned by orchestrator)
**Prerequisites**: All planning artifacts exist, user has approved

Before starting Phase 7, update the state file YAML frontmatter:
- Set `current_phase: "Phase 7: Implementation"`
- Set `command: "/dev-workflow:7-implement $1 \"$2\""`

Execute by following the instructions in the `7-implement` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 7 complete
- Continue to Phase 8

---

## PHASE 8: ORCHESTRATED E2E TESTING

**What**: End-to-end testing with main instance owning feedback loop directly
**Output**: Passing E2E test suite
**Agents**: `test-designer`, `implementer` (spawned by orchestrator)

Before starting Phase 8, update the state file YAML frontmatter:
- Set `current_phase: "Phase 8: E2E Testing"`
- Set `command: "/dev-workflow:8-e2e-test $1 \"$2\""`

Execute by following the instructions in the `8-e2e-test` command with feature: $1 and description: $2

After completion:
- Update state file: mark Phase 8 complete
- Continue to Phase 9

---

## PHASE 9: REVIEW, FIXES & COMPLETION

**What**: 5 parallel reviewers, fix critical issues, generate completion report
**Output**: `.plugin-state/workflow-$1/$1-review.md`, completion report
**Agents**: 5x `code-reviewer` (parallel), then `implementer`/`refactorer` (spawned by orchestrator for fixes)

Before starting Phase 9, update the state file YAML frontmatter:
- Set `current_phase: "Phase 9: Review & Completion"`
- Set `command: "/dev-workflow:9-review $1"`

Execute by following the instructions in the `9-review` command with feature: $1

After completion:
- Update state file: mark Phase 9 complete, set status to COMPLETE
- Generate completion summary
- Offer to create PR

---

## COMPLETION

When all phases are complete:

### 1. Update YAML frontmatter in `.plugin-state/workflow-$1/$1-state.md`

Update the YAML frontmatter at the top of the state file to set completion status:

```yaml
---
workflow_type: tdd-implementation
name: $1
status: complete
current_phase: "COMPLETE"
---
```

### 2. Update markdown body in `.plugin-state/workflow-$1/$1-state.md`

```markdown
## Current Phase
COMPLETE

## Status
✅ COMPLETE
```

### 3. Generate completion report

Summarize:
- Components implemented
- Test coverage (unit, integration, E2E)
- External integrations (real vs mocked)
- Review findings addressed
- Files changed
- Next steps

### 4. Update CLAUDE.md with workflow learnings

Distill any durable project knowledge discovered during this workflow into the project's CLAUDE.md:
- Add new entries to the **Gotchas** section for patterns, pitfalls, or constraints discovered
- Update the **Testing** section if test infrastructure changed (markers added, config updated, etc.)
- Do NOT add workflow-specific or ephemeral information - only durable project knowledge

### 4b. Write holistic completion retrospective

Write a workflow-level learning file capturing observations about the full TDD run.

1. Resolve learnings directory: check `.plugin-state/dev-workflow.local.md` for `learnings_dir` frontmatter field, else use `~/.claude/plugin-learnings/dev-workflow/`
2. Create the directory with `mkdir -p` if it doesn't exist
3. Read all workflow artifacts (exploration, specs, architecture plan, implementation plan, review findings)
4. Write `YYYY-MM-DD-$1-tdd-completion.md` with this structure:

```markdown
---
type: learning
plugin: dev-workflow
workflow_type: tdd
workflow_topic: $1
phase: tdd-completion
date: YYYY-MM-DD
---

## Observation
<Overall outcome: was the implementation correct, complete, well-tested? Factual summary of what happened.>

## Learning
<What worked well across the full workflow. What produced friction or lower quality output — noted as hypotheses, not assertions. Specific observations about plan quality, implementation surprises, review findings patterns, visual verification results (if applicable).>

## Suggestion
<Actionable suggestions for future TDD workflow runs based on this experience.>
```

### 5. Archive workflow directory

Move the workflow directory to the archive:

```bash
mkdir -p docs/archive
mv .plugin-state/workflow-$1 .plugin-state/archive/workflow-$1
```

---

## BEGINNING WORKFLOW NOW

Starting **Phase 2: Parallel Codebase Exploration** for "$1"

Follow the instructions in the `2-explore` command to launch 5 parallel exploration subagents...
