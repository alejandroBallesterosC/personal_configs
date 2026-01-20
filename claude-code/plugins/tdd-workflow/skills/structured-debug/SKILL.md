---
name: structured-debug
description: Hypothesis-driven debugging with instrumentation and tracing. Use when debugging errors, unexpected behavior, or investigating bugs.
---

# Structured Debugging Skill

Hypothesis-driven debugging using instrumentation and log tracing. Based on practices from expert debuggers and Cursor's Debug Mode approach.

## When to Activate

Activate when:
- User reports a bug or unexpected behavior
- Error messages appear in logs or output
- Tests fail for unclear reasons
- Runtime behavior differs from expected
- User asks to debug, trace, or investigate an issue

**Announce at start:** "I'm using the structured-debug skill to debug this."

## The Debugging Loop

```
DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

### Phase 1: DESCRIBE

Gather complete bug context before acting:

```markdown
## Bug Description Checklist
- [ ] What is the expected behavior?
- [ ] What is the actual behavior?
- [ ] What are the exact steps to reproduce?
- [ ] When did it start happening?
- [ ] What changed recently?
- [ ] What error messages appear (exact text)?
- [ ] What environment/conditions trigger it?
```

**Ask clarifying questions** using AskUserQuestionTool if any information is missing.

### Phase 2: HYPOTHESIZE

Generate **3-5 hypotheses** about root cause BEFORE writing any code:

```markdown
## Hypotheses

### H1: [Most likely cause]
- **Theory**: [What you think is wrong]
- **Evidence needed**: [What logs/data would confirm this]
- **Confidence**: [High/Medium/Low]

### H2: [Second most likely]
- **Theory**: [What you think is wrong]
- **Evidence needed**: [What logs/data would confirm this]
- **Confidence**: [High/Medium/Low]

### H3: [Alternative explanation]
- **Theory**: [What you think is wrong]
- **Evidence needed**: [What logs/data would confirm this]
- **Confidence**: [High/Medium/Low]
```

**Key principle**: Generate hypotheses by reading code, not guessing. Trace the relevant code paths mentally first.

### Phase 3: INSTRUMENT

Add targeted logging to test hypotheses. Use minimal, surgical instrumentation.

#### Instrumentation Patterns by Language

**Python:**
```python
# HYPOTHESIS: H1 - Variable state incorrect
# DEBUG: Remove after fix
import logging
logging.debug(f"[DEBUG-H1] user_id={user_id}, status={status}, timestamp={timestamp}")
```

**JavaScript/TypeScript:**
```javascript
// HYPOTHESIS: H1 - Variable state incorrect
// DEBUG: Remove after fix
console.log('[DEBUG-H1]', { userId, status, timestamp });
```

**Go:**
```go
// HYPOTHESIS: H1 - Variable state incorrect
// DEBUG: Remove after fix
log.Printf("[DEBUG-H1] user_id=%s status=%s timestamp=%v", userID, status, timestamp)
```

**Rust:**
```rust
// HYPOTHESIS: H1 - Variable state incorrect
// DEBUG: Remove after fix
eprintln!("[DEBUG-H1] user_id={} status={} timestamp={:?}", user_id, status, timestamp);
```

#### What to Log

| Data Type | Example |
|-----------|---------|
| Variable state | `[DEBUG-H1] user={:?}` |
| Function entry/exit | `[DEBUG-H2] entering process_order(id=123)` |
| Conditional branches | `[DEBUG-H3] taking else branch: condition=false` |
| Loop iterations | `[DEBUG-H1] iteration 3: item={:?}` |
| Return values | `[DEBUG-H2] returning result={:?}` |
| Timing | `[DEBUG-H3] elapsed={}ms` |

#### Instrumentation Rules

1. **Tag every log with hypothesis ID** (e.g., `[DEBUG-H1]`)
2. **Mark as DEBUG** in comment for easy cleanup
3. **Log at decision points**, not every line
4. **Include context**: variable names AND values
5. **Use structured format** for complex data (JSON, debug repr)

### Phase 4: REPRODUCE

Ask user to reproduce the bug and capture logs:

```markdown
## Reproduction Steps

1. Start the application: `[command]`
2. Trigger the bug: [exact steps]
3. Capture output from: [log file/console/stderr]
4. Share the log output with me

**Expected log markers to look for:**
- [DEBUG-H1]: Tests variable state hypothesis
- [DEBUG-H2]: Tests execution path hypothesis
- [DEBUG-H3]: Tests timing hypothesis
```

If user cannot easily reproduce:
- Add more instrumentation for rare conditions
- Suggest enabling persistent logging
- Consider adding metrics/counters

### Phase 5: ANALYZE

Analyze logs against each hypothesis:

```markdown
## Log Analysis

### H1: [Hypothesis name]
- **Log evidence**: `[relevant log lines]`
- **Verdict**: CONFIRMED / REJECTED / INCONCLUSIVE
- **Reasoning**: [why the logs confirm/reject this]

### H2: [Hypothesis name]
- **Log evidence**: `[relevant log lines]`
- **Verdict**: CONFIRMED / REJECTED / INCONCLUSIVE
- **Reasoning**: [why the logs confirm/reject this]
```

**If all hypotheses rejected:**
1. Generate new hypotheses based on log findings
2. Add more instrumentation
3. Repeat the loop

### Phase 6: FIX

Once root cause is identified:

1. **Explain the root cause** clearly to the user
2. **Propose the minimal fix** - don't over-engineer
3. **Keep instrumentation in place** until verified

```markdown
## Root Cause Analysis

**The bug**: [clear explanation]
**Why it happens**: [technical cause]
**The fix**: [what change is needed]

## Proposed Fix

[Code change with explanation]
```

### Phase 7: VERIFY

Ask user to verify the fix:

```markdown
## Verification Steps

1. Apply the fix
2. Reproduce the original bug scenario
3. Confirm the expected behavior now occurs
4. Check for regressions in related functionality

**Is the bug fixed?**
- If YES: Proceed to cleanup
- If NO: What behavior do you see now?
```

If not fixed, return to HYPOTHESIZE with new information.

### Phase 8: CLEAN

Remove all debug instrumentation:

```bash
# Find all debug logs
grep -rn "DEBUG-H[0-9]" --include="*.py" --include="*.js" --include="*.ts" --include="*.go"
```

**Cleanup checklist:**
- [ ] Remove all `[DEBUG-Hx]` log statements
- [ ] Remove debug imports if no longer needed
- [ ] Run tests to ensure cleanup didn't break anything
- [ ] Commit the fix (not the debug logs)

## Quick Reference

| Phase | Action | Output |
|-------|--------|--------|
| DESCRIBE | Gather bug details | Clear reproduction steps |
| HYPOTHESIZE | Generate 3-5 theories | Ranked hypotheses with evidence needed |
| INSTRUMENT | Add targeted logs | Tagged debug statements |
| REPRODUCE | User triggers bug | Log output |
| ANALYZE | Match logs to hypotheses | Confirmed root cause |
| FIX | Minimal code change | Proposed fix |
| VERIFY | User confirms fix | Bug resolved |
| CLEAN | Remove instrumentation | Clean codebase |

## Anti-Patterns to Avoid

### 1. Shotgun Debugging
❌ Add logs everywhere and hope something shows up
✅ Form hypotheses first, instrument surgically

### 2. Fixing Without Understanding
❌ Try random changes until it works
✅ Understand root cause before changing code

### 3. Leaving Debug Code
❌ Commit code with debug logs
✅ Always clean up instrumentation

### 4. Single Hypothesis
❌ Assume first guess is correct
✅ Generate multiple hypotheses, let evidence decide

### 5. Skipping Verification
❌ Assume fix works after code change
✅ Always reproduce and verify

## Advanced Techniques

### Bisection for Regression Bugs

If bug appeared recently:
```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Test each commit until culprit found
```

### Conditional Instrumentation

For hard-to-reproduce bugs:
```python
# Only log when condition is met
if user_id == "problem_user":
    logging.debug(f"[DEBUG-H1] Triggered for problem user: {state}")
```

### State Snapshots

Capture full state at key points:
```python
import json
# DEBUG: Remove after fix
with open('/tmp/debug-state.json', 'w') as f:
    json.dump({'user': user.__dict__, 'order': order.__dict__}, f, default=str)
```

### Diff Comparison

Compare behavior between working and broken:
```python
# DEBUG: Compare old vs new behavior
old_result = old_implementation(data)
new_result = new_implementation(data)
if old_result != new_result:
    logging.error(f"[DEBUG-H1] Mismatch: old={old_result} new={new_result}")
```

## Integration with TDD

After fixing a bug:

1. **Write a regression test** that would have caught this bug
2. **Add the test FIRST** (it should fail without the fix)
3. **Apply the fix** (test should pass)
4. **Commit both** test and fix together

```python
def test_regression_issue_123():
    """Regression test for bug where discount was not applied.

    Root cause: Whitespace in category field from database.
    """
    # Arrange - reproduce the exact conditions
    product = Product(category="FOOD ")  # trailing space

    # Act
    result = apply_discount(product)

    # Assert - the fix handles this case
    assert result.discount_applied == True
```
