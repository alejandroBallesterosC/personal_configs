---
description: Orchestrated TDD implementation with main instance owning feedback loop
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Orchestrated TDD Implementation

**Feature**: $1
**Description**: $2

## Objective

Implement the feature using **orchestrated TDD** where the **main instance owns the feedback loop directly**, spawning subagents for discrete tasks. The TDD implementation gate Stop hook keeps this session alive until the workflow completes. If context is compacted, the hook re-feeds this command.

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:tdd-implementation-workflow-guide` to load the workflow source of truth.

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:testing` to load TDD testing guidance and `.tdd-test-scope` usage.

---

## PREREQUISITES CHECK

Before implementation, verify:

### 1. Planning Artifacts Exist
- `docs/workflow-$1/specs/$1-specs.md` (specification)
- `docs/workflow-$1/plans/$1-implementation-plan.md` (implementation plan with components)
- `docs/workflow-$1/plans/$1-architecture-plan.md` (architecture)
- `docs/workflow-$1/codebase-context/$1-exploration.md` (codebase context)

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

### Step 1: Create Foundation + Contracts

Before parallel implementation, create the shared foundation and make the contracts at the interfaces explicit:
- Shared types/interfaces
- Explicit contracts at interfaces
- Common utilities
- Configuration setup

This must complete before parallel components begin.

### Step 2: Categorize Components by Dependencies

Read `docs/workflow-$1/plans/$1-implementation-plan.md` and categorize:
- **Independent components** (no shared state, no dependencies on other components) → implement in PARALLEL
- **Dependent components** (requires another component to be complete first) → implement SEQUENTIALLY after dependency

### Step 3: Orchestrated TDD Implementation

**For independent components**: Implement in PARALLEL using multiple Task tool calls in a single message. Each task orchestrates its own TDD cycle for one component.

**For dependent components**: Implement SEQUENTIALLY, waiting for each dependency to complete before starting the next.

**CRITICAL**: Always use subagents (test-designer, implementer, refactorer) for ALL implementation work, even when implementing sequentially. The main orchestrator should NEVER write code directly - it runs tests and coordinates. This preserves context in the orchestrator for the full workflow lifecycle.

For each component, the **main instance owns the feedback loop** directly:

**Context Files** (read these for each component):
- `docs/workflow-$1/specs/$1-specs.md` (full specification)
- `docs/workflow-$1/plans/$1-implementation-plan.md` (implementation plan)
- `docs/workflow-$1/plans/$1-architecture-plan.md` (architecture)
- `docs/workflow-$1/codebase-context/$1-exploration.md` (codebase context)

**TDD Cycle** (repeat for each requirement of the component):

#### 1. RED PHASE - Spawn test-designer subagent
Use Task tool with subagent_type='dev-workflow:test-designer':

```
Component: [Component Name]
Feature: $1
Requirement: [Current requirement]
Interface: [Expected interface]

Write ONE failing test for this requirement.
Follow existing test patterns in the codebase.
Return the test file path and test name.
```

After subagent returns:
- Write the test code returned by the test-designer to the test file path it specified
- Write a `.tdd-test-scope` file to the repository root containing the test file path(s) to run
- RUN THE TESTS YOURSELF to confirm RED (failure)
- If test passes unexpectedly, ask subagent to write a more specific test
- Commit: git commit -m 'red: [$1][Component] test for [requirement]'

#### 2. GREEN PHASE - Spawn implementer subagent
Use Task tool with subagent_type='dev-workflow:implementer':

```
Component: [Component Name]
Feature: $1
Failing test: [test file:test name]
Requirement: [Current requirement]

Write MINIMAL code to make this ONE test pass.
- Use REAL API implementations (not mocks)
- API keys are in environment variables
- Only mock if explicitly approved by user
Return the implementation file path.
```

After subagent returns:
- Write a `.tdd-test-scope` file to the repository root containing the test file path(s) to run
- RUN THE TESTS YOURSELF to confirm GREEN (pass)
- If test still fails, spawn implementer again with error context
- Commit: git commit -m 'green: [$1][Component] [requirement]'

#### VISUAL VERIFICATION (Frontend/UI Changes Only — Skip for Backend-Only Work)

Skip this entire section if the feature being implemented does not involve any frontend/UI work (e.g., API endpoints, database changes, CLI tools, libraries, infrastructure). Only perform visual verification when the implementation requires building a new frontend/UI or changing an existing one.

If this iteration modified UI code (templates, components, styles, layouts):

1. Ensure the dev server is running (check with `lsof -i :<port> | grep LISTEN`)
2. Use playwright-cli to verify the visual result:
   - `playwright-cli open http://localhost:<port>/affected-page` (or `goto` if session already open)
   - `playwright-cli screenshot` → Read the saved PNG via Read tool to evaluate visually
   - Evaluate against visual quality criteria:
     - Layout: consistent spacing, proper alignment, no overlapping elements
     - Typography: readable sizes, proper hierarchy, adequate line height
     - Functionality: interactive elements respond, no console errors
   - Resize to mobile (375x812): `playwright-cli run-code "await page.setViewportSize({width: 375, height: 812})"` → `playwright-cli screenshot` → Read and evaluate
   - `playwright-cli console` to check for JS errors
3. If visual issues found:
   - Fix the code (this counts as part of the current GREEN cycle)
   - Re-run tests to confirm they still pass
   - Re-screenshot to confirm the visual fix
   - Repeat until visually acceptable (max 5 fix iterations per visual issue)
4. Only proceed to REFACTOR when both tests pass AND visual quality is acceptable
5. `playwright-cli close-all` when done with visual verification for this iteration

If `playwright-cli` is not installed, skip visual verification and log a warning: "playwright-cli not installed — skipping visual verification. Install with: npm install -g @playwright/cli@latest"

#### 3. REFACTOR PHASE - Spawn refactorer subagent (if needed)
Use Task tool with subagent_type='dev-workflow:refactorer':

```
Component: [Component Name]
Feature: $1
Files: [implementation files]

Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Simplify logic
- Follow CLAUDE.md conventions
Return list of changes made.
```

After subagent returns:
- Write a `.tdd-test-scope` file to the repository root containing the test file path(s) to run
- RUN THE TESTS YOURSELF to confirm still GREEN
- If tests fail, revert and try smaller refactor
- Commit: git commit -m 'refactor: [$1][Component] [description]'

#### 4. Move to Next Requirement
Continue TDD cycle for next requirement.

When ALL requirements for this component pass, run component tests one final time and verify all pass.

### Step 4: Integration Layer

After all components complete, implement integration using orchestrated TDD:

1. Spawn a **test-designer subagent** to write integration tests verifying component interaction
2. After subagent returns, write a `.tdd-test-scope` file and RUN THE TESTS YOURSELF to confirm RED
3. Spawn an **implementer subagent** to wire components together
4. After subagent returns, RUN THE TESTS YOURSELF to confirm GREEN
5. Repeat for each integration point until all integration tests pass

---

## IMPLEMENTATION GUIDELINES

### Orchestrator Pattern
- **Main instance owns the feedback loop directly** - orchestrates the TDD cycle
- **Subagents do discrete tasks** - write ONE test, implement ONE fix, refactor
- **Main instance runs tests** - validates results between subagent calls
- **Context managed at orchestrator level** - hooks handle state preservation automatically
- **TDD implementation gate Stop hook** - blocks stop during Phases 7-9 and re-feeds the command after context compaction

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

Implementation complete. Proceed automatically to **Phase 8: E2E Testing**.
