---
description: Orchestrated E2E testing with main instance owning feedback loop
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Orchestrated End-to-End Testing

**Feature**: $1
**Description**: $2

## Objective

Verify that all implemented components work together correctly. The **main instance runs ralph-loop** and owns the feedback loop, spawning subagents to fix specific issues.

---

## PREREQUISITES

All components should be implemented:
- Read `docs/workflow-$1/plans/$1-implementation-plan.md` for component list
- Verify all components have passing unit tests
- Verify integration layer is complete

---

## E2E TEST PROCESS

### Step 1: Identify E2E Test Scenarios

Based on `docs/workflow-$1/specs/$1-specs.md`, identify end-to-end scenarios:

1. **Happy path scenarios** - Primary user workflows
2. **Error scenarios** - How errors propagate through the system
3. **Edge cases** - Boundary conditions across components
4. **External integration scenarios** - Full paths involving external services

### Step 2: Write E2E Tests

Spawn a **test-designer subagent** to write E2E tests:

Use Task tool with subagent_type='dev-workflow:test-designer':
```
Feature: $1
Context: docs/workflow-$1/specs/$1-specs.md, docs/workflow-$1/plans/$1-implementation-plan.md

Write END-TO-END integration tests covering:
- Happy path scenarios (primary user workflows)
- Error scenarios (how errors propagate through the system)
- Edge cases (boundary conditions across components)
- External integration scenarios (full paths involving external services)

Read the playwright skill in the playwright plugin to understand how to use Playwright to test the application end-to-end if the application has a frontend/UI that needs to be tested, otherwise stick to other testing frameworks more suitable for end-to-end backend-only testing.

If the application does have a frontend/UI that needs to be tested, use Playwright to ensure end-to-end functionality as expected across the frontend/UI and the backend. Take screen shots with playwright and iterate until the frontend/UI looks as expected and functions as expected.

Be sure to also follow the test patterns established in the codebase.
Return list of E2E test files created.
```

### Step 3: Run E2E Tests

Execute the full E2E test suite and capture results.

### Step 4: Fix Failures with Orchestrated Ralph-Loop

If E2E tests fail, the **main instance runs ralph-loop** to fix:

```
/ralph-loop:ralph-loop "Fix E2E test failures for $1 using orchestrated approach.

## Your Role
You are the E2E test orchestrator. You run tests and spawn subagents to fix issues.

## Context Files
- docs/workflow-$1/specs/$1-specs.md (expected behavior)
- docs/workflow-$1/plans/$1-implementation-plan.md (architecture)

## Process

### 1. Run E2E Tests Yourself
Execute the E2E test suite and observe results.

### 2. For Each Failure - Diagnose and Spawn Subagent
Use Task tool with subagent_type='dev-workflow:implementer':

'''
E2E Test Failure: [test name]
Error: [error message]
Stack trace: [relevant trace]

Diagnose and fix this failure:
- Trace through the system
- Identify which component interaction is failing
- Fix the root cause (data flow, interface mismatch, etc.)
Return the fix and files modified.
'''

### 3. Validate Fix
After subagent returns:
- RUN THE E2E TESTS YOURSELF
- RUN ALL UNIT TESTS (regression check)
- If still failing, provide more context to subagent
- If passing, commit: git commit -m 'fix: e2e [test name]'

### 4. Repeat
Continue until ALL E2E tests pass.

## Completion
When ALL E2E tests pass:
1. Run full test suite (unit + integration + E2E)
2. Verify everything passes
3. Output: E2E_$1_COMPLETE
" --max-iterations 30 --completion-promise "E2E_$1_COMPLETE"
```

### Key Points

1. **Main instance runs tests** - Sees actual failures
2. **Subagents fix one issue** - Focused, stateless fixes
3. **Main validates after each fix** - Catches regressions immediately

---

## E2E TEST GUIDELINES

### Orchestrator Pattern
- **Main instance runs tests** - Observes actual failures
- **Subagents fix specific issues** - Do one fix and return
- **Main validates after each fix** - Catches regressions immediately
- **Context managed at orchestrator level** - hooks handle state preservation automatically

### Test Real Integrations
- E2E tests should use real external services where possible
- Use actual API credentials
- Connect to real databases (test instances)

### Test Full Paths
- Start from user input / API request
- Go through all layers
- Verify final output / state changes

### Isolate E2E Tests
- Each E2E test should be independent
- Clean up after each test
- Don't depend on other tests' state

### Handle Flakiness
- If tests are flaky, fix the flakiness first
- Add appropriate waits/retries for async operations
- Don't mask flakiness with excessive retries

---

## OUTPUT

When E2E testing is complete:

```markdown
## E2E Testing Complete: $1

### Scenarios Tested
- ✅ [Scenario 1]: Passed
- ✅ [Scenario 2]: Passed
- ✅ [Scenario 3]: Passed

### Test Coverage
- E2E scenarios: [count]
- Integration tests: [count]
- Unit tests: [count]

### External Integrations Verified
- [Service 1]: ✅ Working
- [Service 2]: ✅ Working

### Issues Fixed During E2E
- [Issue 1]: [How it was fixed]
- [Issue 2]: [How it was fixed]

### Full Test Suite Status
All [N] tests passing
```

---

## Next Step

E2E testing complete. Proceed automatically to **Phase 9: Review, Fixes & Completion**.
