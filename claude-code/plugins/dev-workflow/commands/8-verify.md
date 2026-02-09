---
description: Verify bug fix and clean up instrumentation
model: opus
argument-hint: <bug-name>
---

# Fix Verification and Cleanup

Verifying fix for: **$ARGUMENTS**

## STEP 1: LOAD WORKFLOW CONTEXT

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:debug-workflow-guide` to load the workflow source of truth.

---

## STEP 2: VALIDATE PREREQUISITES

### 2.1 Check session exists

Verify `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md` exists. If not:

**ERROR**: Output the following message and STOP:

```
Error: No debug session found for '$ARGUMENTS'

The file docs/debug/$ARGUMENTS/$ARGUMENTS-state.md does not exist.

To start a debug session, use:
  /dev-workflow:1-start-debug <bug description or error message>
```

### 2.2 Check analysis exists

Verify `docs/debug/$ARGUMENTS/$ARGUMENTS-analysis.md` exists and contains a CONFIRMED hypothesis. If not:

**WARNING**: "No confirmed root cause found in the analysis. Are you sure the fix is ready for verification?"

### 2.3 Read context

Read:
- `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`
- `docs/debug/$ARGUMENTS/$ARGUMENTS-analysis.md` (if exists)
- `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md` (if exists)
- `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md` (for reproduction steps)

---

## STEP 3: VERIFY THE FIX

**HUMAN GATE**: The user must verify the fix works.

### 3.1 Guide reproduction

Provide the user with verification steps:

```markdown
## Verification Steps

1. **Start the application** (same as before):
   [command]

2. **Perform the exact steps that triggered the bug**:
   - [Step 1]
   - [Step 2]
   - [Step 3]

3. **Observe the behavior**:
   - Expected: [what should happen now]
   - Look for: [specific indicators of success]

4. **Check logs** (instrumentation still in place):
   - Should see: [expected log output]
   - Should NOT see: [error indicators]
```

### 3.2 Confirm with user

Use AskUserQuestionTool to ask:
1. Does the expected behavior now occur?
2. Are there any new errors or unexpected behavior?
3. Do related features still work correctly?

### 3.3 Handle verification result

**If fix confirmed:** Proceed to Step 4.

**If fix failed:**
1. Capture new log output from the user
2. Check the 3-Fix Rule: read the fix attempt count from the state file
3. If count >= 3: STOP and ask "We've tried 3 fixes without success. Should we question our fundamental approach?"
4. If count < 3: Increment counter, loop back to analysis (`/dev-workflow:6-analyze $ARGUMENTS`)

---

## STEP 4: CHECK FOR REGRESSIONS

### 4.1 Run tests

Run relevant tests for the affected area:

```bash
# Run tests for the affected module
[test command for affected area]

# Run full test suite if changes are broad
[full test command]
```

### 4.2 Handle test results

**If tests pass:** Proceed to Step 5.

**If tests fail:** Investigate whether the fix introduced regressions. If so, refine the fix before proceeding.

---

## STEP 5: WRITE REGRESSION TEST

**IMPORTANT**: Write a test that would have caught this bug.

```python
def test_regression_bug_$ARGUMENTS():
    """Regression test for [bug description].

    Root cause: [explanation]
    """
    # Arrange - reproduce the exact conditions
    [setup that triggers the bug]

    # Act
    result = [action that was buggy]

    # Assert - the fix handles this case
    assert [expected behavior]
```

Verify:
- Test FAILS without the fix (revert temporarily to confirm if practical)
- Test PASSES with the fix

---

## STEP 6: CLEAN UP INSTRUMENTATION

### 6.1 Remove debug statements

Search for and remove all debug artifacts from source files:
- Find all `DEBUG-H[0-9]` markers
- Remove the tagged log statements
- Remove the `HYPOTHESIS:` and `DEBUG: Remove after fix` comment markers
- Remove the entry point debug log file initialization block
- Remove debug imports if no longer needed
- Delete `logs/debug-output.log` and remove temporary debug files (`/tmp/debug-*.json`)

### 6.2 Verify cleanup

- Run tests to ensure cleanup didn't break anything
- Run linter if available
- Confirm no `DEBUG-H` markers remain in the codebase

### 6.3 Cleanup checklist

- [ ] Remove ALL `[DEBUG-Hx]` log statements
- [ ] Remove entry point debug log file initialization block
- [ ] Remove debug imports (if no longer needed)
- [ ] Delete `logs/debug-output.log`
- [ ] Tests pass after cleanup
- [ ] No orphaned debug markers in codebase

---

## STEP 7: COMMIT

Commit the fix + regression test (NOT debug logs):

```bash
git add [fixed files] [new test file]
git commit -m "fix: [bug description]

Root cause: [brief explanation]
Added regression test to prevent recurrence."
```

---

## STEP 8: ARCHIVE AND FINALIZE

### 8.1 Write resolution summary

Write to `docs/debug/$ARGUMENTS/$ARGUMENTS-resolution.md`:

```markdown
# Debug Resolution: $ARGUMENTS

## Bug
[description]

## Root Cause
[explanation]

## Fix Applied
[what was changed, which files]

## Verification
[how it was confirmed - user verification + test results]

## Regression Test
[test file path and what it covers]

## Debug Session Stats
- Hypotheses generated: [N]
- Hypotheses confirmed: [which one]
- Hypotheses rejected: [which ones]
- Fix attempts: [N]
- Phases completed: [list]

## Lessons Learned
[anything to add to CLAUDE.md or document for future reference]
```

### 8.2 Consider CLAUDE.md update

If this bug reveals a recurring pattern, suggest adding a gotcha to the project's CLAUDE.md:

```markdown
## Gotchas
- [Pattern that caused this bug and how to avoid it]
```

### 8.3 Update state file

Update the YAML frontmatter at the top of `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`:

```yaml
---
workflow_type: debug
name: $ARGUMENTS
status: complete
current_phase: "COMPLETE"
---
```

Then update the markdown body - mark all phases complete and set current phase:

```markdown
## Current Phase
COMPLETE
```

### 8.4 Archive debug session directory

Move the debug session directory to the archive:

```bash
mkdir -p docs/archive
mv docs/debug/$ARGUMENTS docs/archive/debug-$ARGUMENTS
```

---

## SUMMARY

Output a final summary:

```markdown
## Debug Session Complete

**Bug**: $ARGUMENTS
**Root Cause**: [explanation]
**Fix**: [what was changed]
**Verification**: [confirmed by user + tests]
**Regression Test**: [test added]
**Cleanup**: Completed
```
