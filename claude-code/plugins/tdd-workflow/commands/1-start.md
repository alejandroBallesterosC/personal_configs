---
description: Start the fully orchestrated TDD workflow with parallel subagents
model: opus
argument-hint: <feature-name> "<feature description>"
---

# TDD Workflow - Fully Orchestrated

**Feature**: $1
**Description**: $2

This command orchestrates a complete, planning-heavy TDD workflow that runs automatically from start to finish. You only need to respond when asked questions or approve plans.

Before continuing with the workflow ensure the user has the ralph-loop plugin (specifically, /ralph-loop:ralph-loop) installed and available as it is a dependency.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: PARALLEL EXPLORATION (5 subagents) - /2-explore                    │
│   Architecture │ Patterns │ Boundaries │ Tests │ Dependencies              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: SPECIFICATION INTERVIEW - /3-user-specification-interview          │
│   (40+ questions via AskUserQuestionTool)                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: ARCHITECTURE DESIGN - /4-plan-architecture                         │
│   (technical design from spec + exploration)                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: IMPLEMENTATION PLAN - /5-plan-implementation                       │
│   (parallelizable components from architecture)                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: PLAN REVIEW & APPROVAL - /6-review-plan                            │
│   (clarifying questions + suggestions + user approval)                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: ORCHESTRATED TDD - /7-implement                                    │
│   ralph-loop → test-designer → RUN TESTS → implementer → RUN TESTS → ...   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: ORCHESTRATED E2E - /8-e2e-test                                     │
│   (main instance runs tests, subagents fix issues)                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 9: REVIEW, FIXES & COMPLETION - /9-review                             │
│   Security │ Performance │ Code Quality │ Test Coverage │ Spec Compliance  │
│   (parallel review → orchestrated fixes → completion summary)               │
└─────────────────────────────────────────────────────────────────────────────┘

Context is managed automatically via hooks - state is preserved before any
compaction and restored seamlessly. No manual commands needed.
```

---

## CONTEXT MANAGEMENT STRATEGY

Context is managed **automatically via hooks** throughout the workflow:

1. **PreCompact hook** saves session progress to `docs/workflow/$1-state.md` before any compaction
2. **SessionStart hook** reads the state file and injects full context after compaction
3. **Workflow continues automatically** from where it left off

### Why Clear Context?

> "Clear at 60k tokens or 30% context... The automatic compaction is opaque, error-prone, and not well-optimized." - Community Best Practices

Long workflows degrade in quality as context fills. The hooks ensure state is preserved automatically whether context is cleared manually or by auto-compaction.

### Workflow State File

All progress is tracked in `docs/workflow/$1-state.md`:

```markdown
# Workflow State: $1

## Current Phase
[Phase number and name]

## Feature
- **Name**: $1
- **Description**: $2

## Completed Phases
- [x] Phase 2: Exploration
- [ ] Phase 3: Interview
...

## Key Decisions
- [Decision 1]
- [Decision 2]

## Session Progress (Auto-saved before compaction)
- **Phase**: [current phase]
- **Component**: [if applicable]
- **Requirement**: [if applicable]
- **Next Action**: [specific next step]

## Context Restoration Files
Read these files to restore context:
1. Use the tdd-workflow-guide skill if needed
2. docs/workflow/$1-state.md (this file)
3. docs/context/$1-exploration.md
4. docs/specs/$1.md
5. docs/plans/$1-plan.md
6. docs/plans/$1-arch.md
7. CLAUDE.md
```

---

## AUTOMATIC EXECUTION BEGINS

The workflow will now execute automatically. You'll be prompted only when:
- Questions need your answers (AskUserQuestionTool)
- Plan needs your approval
- Decisions require your input

Context is managed automatically via hooks - no manual intervention needed.

---

## PHASE 2: PARALLEL CODEBASE EXPLORATION

**Objective**: Understand the codebase from multiple angles simultaneously.

Launch **5 parallel `code-explorer` agents** using the Task tool. Each uses **Sonnet with 1M context window** for comprehensive analysis.

Use `subagent_type: "tdd-workflow:code-explorer"` for all 5 agents, each with a different focus:

### Agent 1: Architecture Focus
```
Feature: $1
Description: $2

EXPLORATION FOCUS: Architecture

Explore the codebase architecture relevant to implementing this feature:
1. Identify architectural layers (presentation, business logic, data access, infrastructure)
2. Map the component/module structure and organization
3. Document data flow patterns - how data enters, transforms, and exits
4. Identify entry points (main files, routers, handlers, CLI)
5. Note key architectural decisions and their rationale

Produce a comprehensive architecture exploration report.
```

### Agent 2: Patterns & Conventions Focus
```
Feature: $1
Description: $2

EXPLORATION FOCUS: Patterns & Conventions

Explore coding patterns and conventions relevant to implementing this feature:
1. Document naming conventions (files, classes, functions, variables)
2. Identify code organization patterns within files and modules
3. Find common abstractions (base classes, interfaces, utilities)
4. Note error handling patterns used throughout
5. Find similar existing features that can serve as templates

Produce a comprehensive patterns exploration report.
```

### Agent 3: Boundaries & Interfaces Focus
```
Feature: $1
Description: $2

EXPLORATION FOCUS: Boundaries & Interfaces

Explore module boundaries and interfaces relevant to implementing this feature:
1. Map module boundaries and their contracts
2. Identify public APIs and internal interfaces
3. Document integration points with external systems
4. Analyze coupling between components
5. Note dependency directions and any circular dependencies

Produce a comprehensive boundaries exploration report.
```

### Agent 4: Testing Strategy Focus
```
Feature: $1
Description: $2

EXPLORATION FOCUS: Testing Strategy

Explore the testing approach relevant to implementing this feature:
1. Identify test frameworks and tools in use
2. **IDENTIFY THE EXACT TEST COMMAND** (e.g., `pytest`, `npm test`, `go test ./...`)
3. Analyze existing test coverage and gaps
4. Document testing conventions (naming, structure, organization)
5. Find example tests for similar features to follow
6. Note mocking patterns and test data approaches

Produce a comprehensive testing exploration report.
IMPORTANTLY: Report the exact command to run tests (this is critical for TDD).
```

### Agent 5: Dependencies & Environment Focus
```
Feature: $1
Description: $2

EXPLORATION FOCUS: Dependencies & Environment

Explore dependencies and environment requirements for implementing this feature:
1. Identify required packages/libraries and their versions
2. Document external service integrations (APIs, databases, queues)
3. List required environment variables and configuration
4. CHECK IF API KEYS ARE AVAILABLE for any required external services
5. Note any infrastructure or deployment requirements

Produce a comprehensive dependencies exploration report. IMPORTANTLY: Report which API keys are available and which are missing.
```

**All 5 agents run IN PARALLEL using a single message with 5 Task tool calls.**

### Synthesis

After all 5 agents complete, synthesize their findings into:
- `docs/context/$1-exploration.md` (comprehensive context document)
- Update `CLAUDE.md` if key project info is missing

Include these critical sections:
- **Test Command**: The exact command to run tests (e.g., `pytest`, `npm test`)
- **API Keys Status**: Which required services have keys available

---

## Phase 2 Complete

**Exploration complete.**

### Verify Artifacts

Ensure these files exist before continuing:
- `docs/context/$1-exploration.md` (exploration synthesis)
- `docs/workflow/$1-state.md` (workflow state - updated automatically by hooks)
- `CLAUDE.md` (updated if needed)

### Continue Workflow

Using AskUserQuestionTool, ask:

```
Phase 2 (Exploration) is complete.

Continue with Specification Interview?
```

**After user responds, continue with Phase 3.**

---

## PHASE 3: SPECIFICATION INTERVIEW

**Context Restoration** (if resuming after /clear):
- Ensure you fully understand the tdd workflow by using the tdd-workflow-guide skill in the tdd-workflow plugin, and reading through the commands in the tdd-workflow plugin.
- Read `docs/workflow/$1-state.md`
- Read `docs/context/$1-exploration.md`
- Read `CLAUDE.md`

**Objective**: Achieve complete clarity on requirements through exhaustive questioning.

Using AskUserQuestionTool, conduct a thorough interview. Ask questions **ONE AT A TIME** across these domains:

### Core Functionality (5-10 questions)
- What exactly should "$1" do?
- What is the primary user goal?
- What inputs does it accept? What outputs does it produce?
- What is the happy path flow?
- What variations/modes should be supported?

### Technical Constraints (5-8 questions)
- What technologies must be used or avoided?
- What are the performance requirements (latency, throughput)?
- What scale must this handle (concurrent users, data volume)?
- Are there backwards compatibility requirements?

### Integration Points (5-8 questions)
- What existing systems does this interact with?
- What APIs will be called? Are API keys available?
- What data stores are involved?
- What events does this emit or consume?

### Edge Cases & Error Handling (5-8 questions)
- What happens with invalid input?
- What happens when external services fail?
- What are the boundary conditions (0, 1, many, max)?
- How should errors be communicated to users?

### Security Requirements (3-5 questions)
- What authentication/authorization is needed?
- What data needs protection?
- What audit logging is required?

### Testing Requirements (3-5 questions)
- What defines "working correctly"?
- What scenarios must have automated tests?
- Are there E2E testing requirements?

### External Dependencies (3-5 questions)
- What external APIs or services are required?
- Are API keys available? (Check environment or ask user to provide)
- If integration isn't possible, can mocks be used as fallback?

**Interview Attitude**: Be a skeptical senior engineer. Challenge vague answers. Push back on idealistic assumptions. Probe for unstated requirements.

### Output

Write comprehensive specification to: `docs/specs/$1.md`

---

## PHASE 4: ARCHITECTURE DESIGN

**Objective**: Design the technical architecture based on specification and exploration findings.

This phase corresponds to `/4-plan-architecture`. The architecture design defines the system structure that will guide the implementation plan.

### Architecture Requirements

The architecture MUST:

1. **Define independent components** for parallel implementation
   - Each component should be self-contained
   - Components should have clear interfaces
   - No circular dependencies
   - Shared types/interfaces defined upfront

2. **Specify component contracts**
   - Input/output for each component
   - How components will integrate
   - Data flow between components

3. **Define the build sequence**
   - Foundation components first (shared types, interfaces)
   - Independent components can be parallelized
   - Integration layer last

4. **Identify external integrations**
   - APIs required
   - API keys needed (check availability)
   - Service dependencies

### Architecture Structure

Write to `docs/plans/$1-arch.md`:

```markdown
# $1 Architecture

## Component Overview
[ASCII diagram showing component relationships]

## Foundation + Contracts (Build First)
- Shared types/interfaces
- Shared contracts at boundaries/interfaces between components
- Common utilities

## Independent Components (Build in Parallel)

### Component 1: [Name]
- **Purpose**: [What it does]
- **File**: [path/to/file]
- **Dependencies**: [External deps only]
- **Interface**: [Inputs/Outputs]
- **Can parallel with**: [Other components]

### Component 2: [Name]
... (repeat for each component)

## Integration Layer (Build After Components)
- How components connect
- Coordination logic
- Entry points

## Data Flow
1. [Step 1]
2. [Step 2]
3. [Step 3]

## External Integrations
| Service | Purpose | API Key Required |
|---------|---------|------------------|
| [Service] | [Why] | Yes/No |

## Build Sequence
1. Foundation Phase (sequential)
2. Component Phase (parallel)
3. Integration Phase (sequential)
```

---

## PHASE 5: IMPLEMENTATION PLAN

**Objective**: Create detailed implementation plan based on the architecture.

This phase corresponds to `/5-plan-implementation`. The implementation plan maps architecture components to concrete implementation tasks.

**Execution**: The plan is created from the architecture design, defining parallelizable tasks for each component.

---

## PHASE 6: PLAN REVIEW & APPROVAL

**Objective**: Challenge the plan and ensure completeness before implementation.

This phase corresponds to `/6-review-plan`. The plan-reviewer subagent critically analyzes the plan, then findings are presented to the user for approval.

### Step 1: Spawn Plan-Reviewer Subagent

Use the Task tool to spawn a `plan-reviewer` agent:

```
Use Task tool with subagent_type: "tdd-workflow:plan-reviewer"

Prompt:
Feature: $1

Critically review the implementation plan for this feature.

Context files to read:
- docs/context/$1-exploration.md (codebase context)
- docs/specs/$1.md (specification)
- docs/plans/$1-arch.md (architecture)
- docs/plans/$1-plan.md (implementation plan)
- docs/plans/$1-tests.md (test cases)

Review Focus:
1. Challenge assumptions - What might be wrong? Are boundaries correct?
2. Identify gaps - Missing requirements, error handling, test scenarios?
3. Verify parallel implementation viability - Are components truly independent?
4. Check for security, performance, and integration risks
5. Verify API key requirements are identified

For each finding, report:
- Area: [Completeness/Feasibility/Edge Cases/etc.]
- Rating: ✅ Good / ⚠️ Concern / ❌ Blocker
- Details: [What the issue is]
- Suggestion: [How to address it]

Return a comprehensive review report with all findings.
```

### Step 2: After Subagent Returns

The main instance should:

1. **Present findings to user** via AskUserQuestionTool
2. **Ask follow-up questions** for any ⚠️ Concern or ❌ Blocker items
3. **Update plan files** based on user's decisions

### Step 3: Plan Approval

Using AskUserQuestionTool:

1. **Present summary** - Proposed architecture and components
2. **Address feedback** - Ask which suggestions to incorporate
3. **Request explicit approval** - Confirm user is ready to proceed

If user requests changes:
- Update `docs/plans/$1-plan.md`
- Update `docs/plans/$1-arch.md`
- Re-validate with user

**Continue only when user explicitly approves.**

---

## Phases 3-6 Complete

**Planning complete and approved.**

### Verify Artifacts

Ensure these files exist before continuing:
- `docs/context/$1-exploration.md`
- `docs/specs/$1.md`
- `docs/plans/$1-plan.md`
- `docs/plans/$1-arch.md`
- `docs/workflow/$1-state.md` (workflow state - updated automatically by hooks)

### Continue Workflow

Using AskUserQuestionTool, ask:

```
Planning phases (3-6) are complete and approved.

Continue with TDD Implementation?
```

**After user responds, continue with Phase 7.**

---

## PHASE 7: COMPONENT IMPLEMENTATION (Orchestrated TDD)

**Context Restoration** (if resuming after context clear/compact):
- Read `docs/workflow/$1-state.md` (hooks inject this automatically)
- Read `docs/specs/$1.md`
- Read `docs/plans/$1-plan.md`
- Read `docs/plans/$1-arch.md`
- Read `CLAUDE.md`

**Objective**: Implement all components using TDD with the **main instance owning the feedback loop**.

### Why This Architecture?

The **main Claude Code instance runs ralph-loop** so that:
- The feedback loop is visible and controllable
- Context can be managed at the orchestrator level
- Subagents are lightweight workers that do one task and return
- The TDD cycle (RED → GREEN → REFACTOR) happens at the right level

### Pre-Implementation Checks

1. **Identify test command** from exploration
   - Check `docs/context/$1-exploration.md` for test framework
   - Common commands: `pytest`, `npm test`, `go test ./...`, `cargo test`
   - Verify the command works before starting TDD

2. **Verify API keys** for external integrations
   - Check environment variables
   - Ask user if any are missing
   - Only use mocks if real integration is truly impossible

3. **Create foundation and contracts first**
   - Shared types/interfaces
   - Shared contracts at boundaries/interfaces between components
   - Common utilities
   - Must complete before component implementation


### Implementation Process

For **each component** in the plan (sequentially, or parallel for truly independent components):

```
/ralph-loop:ralph-loop "Implement [Component Name] for $1 using orchestrated TDD.

## Your Role
You are the TDD orchestrator. You own the feedback loop and spawn subagents for discrete tasks.

## Context Files
- docs/specs/$1.md (requirements)
- docs/plans/$1-plan.md (implementation plan)
- docs/plans/$1-arch.md (architecture)
- CLAUDE.md (conventions)

## Component Details
- **Component**: [Component Name]
- **Interface**: [Defined interface from plan]
- **Requirements**: [List from spec]

## TDD Cycle (Repeat for each requirement)

### 1. RED PHASE - Spawn test-designer subagent
Use Task tool with subagent_type='tdd-workflow:test-designer':

'''
Component: [Component Name]
Requirement: [Current requirement]
Interface: [Expected interface]

Write ONE failing test for this requirement.
Follow existing test patterns in the codebase.
Return the test file path and test name.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm RED (failure)
- If test passes unexpectedly, ask subagent to write a more specific test
- Commit: git commit -m 'red: [component] test for [requirement]'

### 2. GREEN PHASE - Spawn implementer subagent
Use Task tool with subagent_type='tdd-workflow:implementer':

'''
Component: [Component Name]
Failing test: [test file:test name]
Requirement: [Current requirement]

Write MINIMAL code to make this ONE test pass.
- Use REAL API implementations (not mocks)
- API keys are in environment variables
- Only mock if explicitly approved by user
Return the implementation file path.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm GREEN (pass)
- If test still fails, spawn implementer again with error context
- Commit: git commit -m 'green: [component] [requirement]'

### 3. REFACTOR PHASE - Spawn refactorer subagent (if needed)
Use Task tool with subagent_type='tdd-workflow:refactorer':

'''
Component: [Component Name]
Files: [implementation files]

Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Simplify logic
- Follow CLAUDE.md conventions
Return list of changes made.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm still GREEN
- If tests fail, revert and try smaller refactor
- Commit: git commit -m 'refactor: [component] [description]'

### 4. Move to Next Requirement
- Update progress in docs/workflow/$1-state.md
- Continue TDD cycle for next requirement

## Completion
When ALL requirements for this component pass tests:
- Run full test suite one more time
- Output COMPONENT_COMPLETE
" --max-iterations 50 --completion-promise "COMPONENT_COMPLETE"
```

### Key Points

1. **Main instance runs tests** - Not the subagents
2. **Subagents do ONE task** - Write a test, write code, or refactor
3. **Feedback loop is visible** - Main instance sees test results
4. **Context managed at orchestrator** - Hooks preserve state automatically

### Parallel Components

For **truly independent** components (no shared state, no integration dependencies):
- Run separate ralph-loop instances in parallel
- Each ralph-loop orchestrates its own TDD cycle
- Merge results after all complete

Wait for all components to complete before proceeding.

---

## PHASE 8: END-TO-END TESTING (Orchestrated)

**Objective**: Verify all components work together correctly, with main instance owning the feedback loop.

### Write Integration Tests

First, spawn a test-designer subagent for E2E tests:

Use Task tool with subagent_type='tdd-workflow:test-designer':
```
Feature: $1
Context: docs/specs/$1.md, docs/plans/$1-plan.md

Write END-TO-END integration tests covering:
- Component interactions (full data flow)
- External API integrations (real calls)
- Error propagation across components
- Happy path scenarios from spec
- Edge cases from spec

Return list of E2E test files created.
```

### Run and Fix E2E Tests

The **main instance runs ralph-loop** to iterate until E2E tests pass:

```
/ralph-loop:ralph-loop "Fix E2E test failures for $1.

## Your Role
You are the E2E test orchestrator. You run tests and spawn subagents to fix issues.

## Context Files
- docs/specs/$1.md (expected behavior)
- docs/plans/$1-plan.md (architecture)

## Process

### 1. Run E2E Tests Yourself
Execute the E2E test suite and observe results.

### 2. For Each Failure - Spawn implementer subagent
Use Task tool with subagent_type='tdd-workflow:implementer':

'''
E2E Test Failure: [test name]
Error: [error message]
Stack trace: [relevant trace]

Trace this failure to its root cause and fix it.
- Check component interactions
- Check data flow
- Check external API calls
- Return the fix and files modified.
'''

### 3. Validate Fix
After subagent returns:
- RUN THE E2E TESTS YOURSELF
- If still failing, provide more context to subagent
- If passing, commit: git commit -m 'fix: e2e [test name]'

### 4. Repeat
Continue until ALL E2E tests pass.

## Completion
When ALL E2E tests pass:
- Run full test suite (unit + integration + E2E)
- Output E2E_COMPLETE
" --max-iterations 30 --completion-promise "E2E_COMPLETE"
```

### Key Points

1. **Main instance runs tests** - Sees actual failures
2. **Subagents fix one issue** - Focused, stateless fixes
3. **Feedback loop at orchestrator** - Can track progress and intervene

---

## Phases 7-8 Complete

**Implementation and E2E testing complete.**

### Verify Tests Pass

Before continuing to review:
- Run full test suite
- Confirm E2E tests pass

State file `docs/workflow/$1-state.md` is updated automatically by hooks.

### Continue Workflow

Using AskUserQuestionTool, ask:

```
Implementation and E2E testing (Phases 7-8) complete.

Continue with Review phase?
```

**After user responds, continue with Phase 9.**

---

## PHASE 9: REVIEW, FIXES & COMPLETION

This final phase includes parallel review, orchestrated fixes, and completion summary.

### Part A: PARALLEL MULTI-ASPECT REVIEW

**Context Restoration** (if resuming after context clear/compact):
- Read `docs/workflow/$1-state.md` (hooks inject this automatically)
- Read `docs/specs/$1.md`
- Read `docs/plans/$1-plan.md`
- Read `CLAUDE.md`

**Objective**: Comprehensive review from multiple specialized perspectives.

Launch **5 parallel review subagents** using `subagent_type: "tdd-workflow:code-reviewer"`:

### Subagent 1: Security Reviewer
```
Feature: $1

REVIEW FOCUS: Security

## Files to Review
1. Read docs/workflow/$1-state.md for list of implementation files
2. Read docs/specs/$1.md for requirements
3. Read docs/plans/$1-plan.md for architecture
4. Review ALL implementation files listed in the state file

Review the implementation for security concerns:
- Input validation
- Authentication/authorization
- Data protection
- Injection vulnerabilities
- Secrets handling

Report findings with severity (Critical/Warning/Suggestion).
Only report findings with ≥80% confidence.
Include file paths and line numbers for each finding.
```

### Subagent 2: Performance Reviewer
```
Feature: $1

REVIEW FOCUS: Performance

## Files to Review
1. Read docs/workflow/$1-state.md for list of implementation files
2. Read docs/specs/$1.md for requirements
3. Read docs/plans/$1-plan.md for architecture
4. Review ALL implementation files listed in the state file

Review the implementation for performance:
- Algorithmic complexity
- Database query efficiency
- Memory usage
- API call patterns
- Caching opportunities

Report findings with impact assessment.
Only report findings with ≥80% confidence.
Include file paths and line numbers for each finding.
```

### Subagent 3: Code Quality Reviewer
```
Feature: $1

REVIEW FOCUS: Code Quality

## Files to Review
1. Read docs/workflow/$1-state.md for list of implementation files
2. Read CLAUDE.md for conventions
3. Read docs/plans/$1-plan.md for architecture
4. Review ALL implementation files listed in the state file

Review the implementation for code quality:
- CLAUDE.md compliance
- Code organization
- Naming conventions
- Error handling
- Documentation

Report findings with confidence scores.
Only report findings with ≥80% confidence.
Include file paths and line numbers for each finding.
```

### Subagent 4: Test Coverage Reviewer
```
Feature: $1

REVIEW FOCUS: Test Coverage

## Files to Review
1. Read docs/workflow/$1-state.md for list of implementation and test files
2. Read docs/specs/$1.md for requirements
3. Review ALL test files and implementation files listed in the state file

Review the tests:
- Code path coverage
- Edge case coverage
- Error scenario coverage
- Integration test completeness
- E2E test adequacy

Report gaps and missing tests.
Only report findings with ≥80% confidence.
Include file paths for each finding.
```

### Subagent 5: Spec Compliance Reviewer
```
Feature: $1

REVIEW FOCUS: Spec Compliance

## Files to Review
1. Read docs/workflow/$1-state.md for list of implementation files
2. Read docs/specs/$1.md for requirements (ESSENTIAL)
3. Review ALL implementation files listed in the state file

Review implementation against docs/specs/$1.md:
- All requirements addressed?
- Behavior matches specification?
- Edge cases handled as specified?
- Non-functional requirements met?

Report any deviations from spec.
Only report findings with ≥80% confidence.
Include file paths and specific requirement references for each finding.
```

**All 5 review subagents run IN PARALLEL.**

### Consolidate Findings

Merge all review findings into categories:
- **Critical** (must fix before completion)
- **Warnings** (should fix)
- **Suggestions** (nice to have)

Write consolidated review to `docs/workflow/$1-review.md`.

---

### Part B: FINAL FIXES (Orchestrated)

**Objective**: Address review feedback with main instance owning the verification loop.

### Fix Critical Issues

The **main instance runs ralph-loop** to address each critical finding:

```
/ralph-loop:ralph-loop "Fix critical review findings for $1.

## Your Role
You are the fix orchestrator. You verify fixes and spawn subagents to implement them.

## Context Files
- docs/specs/$1.md (requirements)
- docs/workflow/$1-review.md (review findings)

## Critical Issues to Fix
[List from review - include all Critical findings]

## Process for Each Issue

### 1. Spawn implementer/refactorer subagent
Use Task tool with appropriate subagent_type:

'''
Critical Issue: [Description from review]
Location: [File and line if known]
Review context: [Why this is critical]

Fix this issue:
- Maintain existing test coverage
- Follow CLAUDE.md conventions
- Return files modified and changes made.
'''

### 2. Validate Fix
After subagent returns:
- RUN THE FULL TEST SUITE YOURSELF
- RUN E2E TESTS YOURSELF
- If tests fail, provide error context and try again
- If tests pass, commit: git commit -m 'fix: [issue summary]'

### 3. Mark Issue Resolved
Update docs/workflow/$1-review.md to mark issue as resolved.

### 4. Next Issue
Continue until all Critical issues are resolved.

## Completion
When ALL Critical issues are fixed and ALL tests pass:
- Output FIX_COMPLETE
" --max-iterations 20 --completion-promise "FIX_COMPLETE"
```

### Final Verification

After ralph-loop completes:

1. **Run full test suite** - Unit, integration, E2E
2. **Verify all Critical issues resolved** - Check review document
3. **Document deferred items** - Any Warnings/Suggestions not addressed go in `docs/workflow/$1-state.md`

---

### Part C: COMPLETION SUMMARY

**Objective**: Provide comprehensive summary of what was accomplished.

### Update Final State

Update `docs/workflow/$1-state.md`:

```markdown
# Workflow State: $1

## Current Phase
COMPLETE

## Feature
- **Name**: $1
- **Description**: $2

## Completed Phases
- [x] Phase 2: Parallel Exploration
- [x] Phase 3: Specification Interview
- [x] Phase 4: Plan Creation
- [x] Phase 5: Architecture Design
- [x] Phase 6: Plan Review & Approval
- [x] Phase 7: Orchestrated TDD Implementation
- [x] Phase 8: E2E Testing
- [x] Phase 9: Review, Fixes & Completion

## Status
✅ COMPLETE
```

### Generate Summary

Output a completion report:

```markdown
# Implementation Complete: $1

## Summary
[Brief description of what was implemented]

## Components Implemented
- [Component 1]: [Status]
- [Component 2]: [Status]
- ...

## Test Coverage
- Unit tests: [count]
- Integration tests: [count]
- E2E tests: [count]

## External Integrations
- [API/Service]: [Real/Mock] implementation

## Review Status
- Critical issues: [count resolved]
- Warnings addressed: [count]
- Deferred items: [list]

## Files Changed
[List of modified/created files]

## Artifacts Created
- docs/context/$1-exploration.md
- docs/specs/$1.md
- docs/plans/$1-plan.md
- docs/plans/$1-arch.md
- docs/workflow/$1-state.md
- docs/workflow/$1-review.md

## Next Steps
- [Any follow-up items]
- [Documentation updates needed]
- [Deployment considerations]

## Commits
[Git log of implementation commits]
```

### Final Actions

1. Present summary to user
2. Offer to create PR: `/commit` then `/main-pr`
3. Document any lessons learned in CLAUDE.md

---

## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

> "Clear at 60k tokens or 30% context... don't wait for limits." - Community Best Practices

1. **Orchestrator owns the feedback loop** - Main instance runs ralph-loop and tests, subagents do discrete tasks
2. **Strategic parallelization** - Parallel for read-only work (exploration, review), sequential for implementation
3. **Real integrations first** - Only mock when real integration is truly impossible
4. **Verify continuously** - Main instance runs tests after every subagent task
5. **Front-load planning** - Thorough questioning eliminates implementation rework
6. **Automatic context management** - Hooks preserve state before compaction and restore it automatically
7. **Automatic orchestration** - User only provides input when needed

---

## BEGINNING WORKFLOW NOW

Starting **Phase 2: Parallel Codebase Exploration** for "$1"

Launching 5 parallel exploration subagents to analyze the codebase from multiple angles...
