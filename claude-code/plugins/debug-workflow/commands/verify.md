---
description: Verify bug fix and clean up instrumentation
model: opus
argument-hint: [bug-name]
---

# Fix Verification

Verifying fix for: **$ARGUMENTS**

## Verification Process

### Step 1: Apply the Fix

Ensure the proposed fix has been applied to the codebase.

### Step 2: Reproduce Original Scenario

Guide the user through exact reproduction steps:

```markdown
## Verification Steps

1. **Start the application** (same as before):
   ```bash
   [command]
   ```

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

### Step 3: Confirm Fix

Ask user with AskUserQuestionTool:

1. Does the expected behavior now occur?
2. Are there any new errors or unexpected behavior?
3. Do related features still work correctly?

### Step 4: Check for Regressions

Run relevant tests:

```bash
# Run tests for affected area
pytest tests/test_[affected_module].py -v

# Run full test suite if changes are broad
pytest
```

### Step 5: Write Regression Test

**IMPORTANT**: Add a test that would have caught this bug.

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

## Verification Outcomes

### Fix Confirmed

If the bug is fixed and tests pass:

1. Proceed to cleanup
2. Commit the fix AND the regression test
3. Update any documentation if behavior changed

### Fix Failed

If the bug still occurs:

1. Capture new log output
2. Return to analysis phase with new evidence
3. Consider if fix was incomplete or wrong hypothesis

### New Bug Introduced

If fix caused new issues:

1. Revert the fix
2. Document the regression
3. Refine the fix approach

## Cleanup Phase

Once fix is verified:

### 1. Remove Debug Instrumentation

```bash
# Find all debug statements
grep -rn "DEBUG-H[0-9]" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.rs"
```

### 2. Cleanup Checklist

- [ ] Remove ALL `[DEBUG-Hx]` log statements
- [ ] Remove debug imports (if no longer needed)
- [ ] Remove temporary debug files (`/tmp/debug-*.json`)
- [ ] Run tests to ensure cleanup didn't break anything
- [ ] Run linter to catch any orphaned code

### 3. Commit Strategy

```bash
# Commit the fix + regression test (NOT debug logs)
git add [fixed files] [new test file]
git commit -m "fix: [bug description]

Root cause: [brief explanation]
Added regression test to prevent recurrence."
```

### 4. Archive Debug Documentation

Move debug docs to archive (or delete):

```bash
# Option A: Archive
mkdir -p docs/debug/archive
mv docs/debug/$ARGUMENTS-* docs/debug/archive/

# Option B: Delete
rm docs/debug/$ARGUMENTS-*
```

## Summary

```markdown
## Debug Session Complete

**Bug**: [description]
**Root Cause**: [explanation]
**Fix**: [what was changed]
**Verification**: [how it was confirmed]
**Regression Test**: [test added]
**Cleanup**: [completed/pending]
```

## Next Session

If you encounter a similar bug in the future:
```
/debug-workflow:debug <new bug description>
```
