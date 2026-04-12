---
description: Orchestrated E2E testing with main instance owning feedback loop
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Orchestrated End-to-End Testing

**Feature**: $1
**Description**: $2

## Objective

Verify that all implemented components work together correctly. The **main instance owns the feedback loop directly**, spawning subagents to fix specific issues. The TDD implementation gate Stop hook keeps this session alive until the workflow completes. If context is compacted, the hook re-feeds this command.

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:testing` to load TDD testing guidance and `.tdd-test-scope` usage.

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

If the application has a frontend/UI, read the playwright skill in the playwright plugin and use @playwright/test to write formal E2E test files that verify end-to-end functionality across the frontend/UI and the backend. For backend-only applications, use testing frameworks more suitable for end-to-end backend testing.

Be sure to follow the test patterns established in the codebase.
Return list of E2E test files created.
```

### Step 3: Run E2E Tests

Execute the full E2E test suite and capture results.

### Step 4: Fix Failures

If E2E tests fail, the **main instance owns the fix loop** directly:

**Context Files** (read for diagnosis):
- `docs/workflow-$1/specs/$1-specs.md` (expected behavior)
- `docs/workflow-$1/plans/$1-implementation-plan.md` (architecture)

**Fix Loop** (repeat until ALL E2E tests pass):

1. **Run E2E Tests** — Execute the E2E test suite and observe results
2. **For Each Failure** — Diagnose and spawn an **implementer subagent**:

```
E2E Test Failure: [test name]
Error: [error message]
Stack trace: [relevant trace]

Diagnose and fix this failure:
- Trace through the system
- Identify which component interaction is failing
- Fix the root cause (data flow, interface mismatch, etc.)
Return the fix and files modified.
```

3. **Validate Fix** — After subagent returns:
   - Write a `.tdd-test-scope` file to the repository root with `all` to run the full test suite
   - RUN THE E2E TESTS YOURSELF
   - RUN ALL UNIT TESTS (regression check)
   - If still failing, provide more context to subagent
   - If passing, commit: git commit -m 'fix: e2e [test name]'
4. **Repeat** until ALL E2E tests pass
5. **Final verification** — Run full test suite (unit + integration + E2E), verify everything passes

### Key Points

1. **Main instance runs tests** - Sees actual failures
2. **Subagents fix one issue** - Focused, stateless fixes
3. **Main validates after each fix** - Catches regressions immediately

---

## E2E TEST GUIDELINES

### Orchestrator Pattern
- **Main instance owns the feedback loop directly** - runs tests and observes actual failures
- **Subagents fix specific issues** - Do one fix and return
- **Main validates after each fix** - Catches regressions immediately
- **Context managed at orchestrator level** - hooks handle state preservation automatically
- **TDD implementation gate Stop hook** - blocks stop during Phases 7-9 and re-feeds the command after context compaction

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

## Visual Verification (Frontend/UI Changes Only — Skip for Backend-Only Work)

Skip this entire section if the feature does not involve any frontend/UI work (e.g., API endpoints, database changes, CLI tools, libraries, infrastructure). Only perform visual verification when the implementation required building a new frontend/UI or changing an existing one.

After E2E tests pass, perform visual verification using playwright-cli:

1. Navigate to each page/route affected by the feature:
   - `playwright-cli open http://localhost:<port>/page`
2. At each page, test three viewports:
   - Desktop (1280x800): `playwright-cli screenshot` → Read PNG via Read tool → evaluate
   - Tablet (768x1024): `playwright-cli run-code "await page.setViewportSize({width: 768, height: 1024})"` → `playwright-cli screenshot` → Read PNG → evaluate
   - Mobile (375x812): `playwright-cli run-code "await page.setViewportSize({width: 375, height: 812})"` → `playwright-cli screenshot` → Read PNG → evaluate
3. At each viewport, evaluate against visual quality criteria:
   - Layout: consistent spacing, proper alignment, no overlapping elements
   - Typography: readable sizes, proper hierarchy, adequate line height
   - Responsiveness: no horizontal scroll, no truncated content, touch targets >= 44px on mobile
   - Functionality: interactive elements respond, forms submit, navigation works
4. Check `playwright-cli console` for JS errors at each viewport
5. Test critical user flows end-to-end:
   - Use `playwright-cli snapshot` to get element refs
   - `playwright-cli click`, `fill`, `type` to interact
   - `playwright-cli screenshot` after each significant action to verify result
6. If issues found → fix → re-test → re-screenshot (max 5 iterations per page)
7. If visual quality fails after 5 iterations on same issue, stop and report to user with screenshot file paths
8. `playwright-cli close-all` when done

If `playwright-cli` is not installed, skip visual verification and log a warning: "playwright-cli not installed — skipping visual verification. Install with: npm install -g @playwright/cli@latest"

---

## Next Step

E2E testing complete. Proceed automatically to **Phase 9: Review, Fixes & Completion**.
