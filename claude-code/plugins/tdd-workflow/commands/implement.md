---
description: Orchestrated TDD implementation with main instance owning feedback loop
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Orchestrated TDD Implementation

**Feature**: $1
**Description**: $2

## Objective

Implement the feature using **orchestrated TDD** where the **main instance runs ralph-loop** and owns the feedback loop, spawning subagents for discrete tasks.

---

## PREREQUISITES CHECK

Before implementation, verify:

### 1. Planning Artifacts Exist
- `docs/specs/$1.md` (specification)
- `docs/plans/$1-plan.md` (implementation plan with components)
- `docs/plans/$1-arch.md` (architecture)
- `docs/context/$1-exploration.md` (codebase context)

If any are missing, run the planning workflow first.

### 2. API Keys Available
Check the exploration document for API key status. If external integrations are needed:

Using AskUserQuestionTool, verify:
- Are all required API keys available in environment?
- For any missing keys, can the user provide them?
- As a TRUE FALLBACK ONLY: Should mocks be used for unavailable integrations?

**Prefer real implementations. Only mock when real integration is truly impossible.**

---

## IMPLEMENTATION PROCESS

### Step 1: Create Foundation

Before parallel implementation, create shared foundation:
- Shared types/interfaces
- Common utilities
- Configuration setup

This must complete before parallel components begin.

### Step 2: Identify Parallel Components

Read `docs/plans/$1-plan.md` and identify:
- Independent components that can be implemented in parallel
- Dependencies between components
- Integration points

### Step 3: Orchestrated TDD Implementation

For each component, the **main instance runs ralph-loop** and owns the feedback loop:

```
/ralph-loop:ralph-loop "Implement [Component Name] for feature: $1 using orchestrated TDD.

## Your Role
You are the TDD orchestrator. You own the feedback loop and spawn subagents for discrete tasks.

## Context Files
- docs/specs/$1.md (full specification)
- docs/plans/$1-plan.md (implementation plan)
- docs/plans/$1-arch.md (architecture)
- docs/context/$1-exploration.md (codebase context)

## Component Details
- **Component**: [Component Name]
- **Purpose**: [From plan]
- **Interface**: [Inputs/Outputs from plan]
- **Requirements**: [List from spec]

## TDD Cycle (Repeat for each requirement)

### 1. RED PHASE - Spawn test-designer subagent
Use Task tool with subagent_type='tdd-workflow:test-designer':

'''
Component: [Component Name]
Feature: $1
Requirement: [Current requirement]
Interface: [Expected interface]

Write ONE failing test for this requirement.
Follow existing test patterns in the codebase.
Return the test file path and test name.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm RED (failure)
- If test passes unexpectedly, ask subagent to write a more specific test
- Commit: git commit -m 'red: [$1][Component] test for [requirement]'

### 2. GREEN PHASE - Spawn implementer subagent
Use Task tool with subagent_type='tdd-workflow:implementer':

'''
Component: [Component Name]
Feature: $1
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
- Commit: git commit -m 'green: [$1][Component] [requirement]'

### 3. REFACTOR PHASE - Spawn refactorer subagent (if needed)
Use Task tool with subagent_type='tdd-workflow:refactorer':

'''
Component: [Component Name]
Feature: $1
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
- Commit: git commit -m 'refactor: [$1][Component] [description]'

### 4. Move to Next Requirement
Continue TDD cycle for next requirement.

## Completion
When ALL requirements for this component pass:
1. Run component tests one final time
2. Verify all pass
3. Output: COMPONENT_[$1]_[Component]_COMPLETE
" --max-iterations 50 --completion-promise "COMPONENT_[$1]_[Component]_COMPLETE"
```

### Step 4: Implement Each Component

For **each component** from the plan:
1. Run the ralph-loop above
2. Wait for completion
3. Move to next component

For **truly independent** components (no shared state):
- Can run separate ralph-loop instances in parallel
- Each ralph-loop orchestrates its own TDD cycle

### Step 5: Integration Layer

After all components complete, implement integration using orchestrated TDD:

```
/ralph-loop:ralph-loop "Implement integration layer for $1 using orchestrated TDD.

## Your Role
You are the TDD orchestrator for integration.

## Context
All components are implemented:
[List completed components]

## TDD Cycle

### 1. RED - Spawn test-designer for integration test
'''
Write ONE integration test that verifies component interaction.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm RED

### 2. GREEN - Spawn implementer for wiring
'''
Wire components together to make integration test pass.
'''

After subagent returns:
- RUN THE TESTS YOURSELF to confirm GREEN

### 3. Continue
Repeat for each integration point.

## Completion
When integration is complete and tests pass:
Output: INTEGRATION_$1_COMPLETE
" --max-iterations 20 --completion-promise "INTEGRATION_$1_COMPLETE"
```

---

## IMPLEMENTATION GUIDELINES

### Orchestrator Pattern
- **Main instance runs ralph-loop** - owns the feedback loop
- **Subagents do discrete tasks** - write ONE test, implement ONE fix, refactor
- **Main instance runs tests** - validates results between subagent calls
- **Context managed at orchestrator level** - can checkpoint if needed

### Use Real Implementations
- External APIs: Use real API calls with actual credentials
- Databases: Use real database connections
- Services: Connect to real services

### Mock Fallback (Only When Necessary)
Only use mocks when:
- API keys are truly unavailable (user confirmed)
- External service is down/inaccessible

When mocking:
- Document clearly that it's mocked
- Create interface that real implementation can replace
- Add TODO to switch to real implementation

### TDD Discipline
- NEVER skip the RED phase
- NEVER write more code than tests require
- NEVER refactor while tests are red
- ALWAYS commit at phase transitions
- ALWAYS run tests after every subagent task (main instance validates)

---

## OUTPUT

When all components and integration are complete:

```markdown
## Implementation Complete: $1

### Components Implemented
- [Component 1]: ✅ Complete ([N] tests passing)
- [Component 2]: ✅ Complete ([N] tests passing)
- ...

### Integration Layer
- ✅ Complete ([N] integration tests passing)

### External Integrations
- [Service]: Real implementation / Mocked (reason)

### Test Summary
- Unit tests: [count]
- Integration tests: [count]

### Git Commits
[Summary of commits created]
```

---

## Next Step

Implementation complete. Proceed automatically to **Phase 7: End-to-End Testing**.
