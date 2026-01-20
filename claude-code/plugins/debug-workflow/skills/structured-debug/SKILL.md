---
name: structured-debug
description: Hypothesis-driven debugging with instrumentation and tracing. Use when debugging errors, unexpected behavior, or investigating bugs.
---

# Structured Debugging Skill

Hypothesis-driven debugging using systematic exploration, instrumentation, and log tracing. Based on practices from Boris Cherny, Anthropic's engineering team, and Cursor's Debug Mode.

## When to Activate

Activate when:
- User reports a bug or unexpected behavior
- Error messages appear in logs or output
- Tests fail for unclear reasons
- Runtime behavior differs from expected
- User asks to debug, trace, or investigate an issue

**Announce at start:** "I'm using the structured-debug skill to debug this."

## Core Philosophy

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

> "The systematic-debugging skill enforces a disciplined 'Iron Law': no fixes are attempted until a root cause is proven." - Claude Skills Community

## The Debugging Loop

```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

### Phase 1: EXPLORE

Before debugging, understand the relevant systems:

1. **Find relevant files** based on error/bug description
2. **Map execution flow** from entry to failure
3. **Check recent changes** via git history
4. **Review test coverage** for gaps

```bash
# Recent changes to relevant files
git log --oneline -10 -- path/to/relevant/

# Who touched this code
git blame path/to/file.py -L 50,70
```

### Phase 2: DESCRIBE

Gather complete bug context:

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

### Phase 3: HYPOTHESIZE

Generate **3-5 hypotheses** about root cause BEFORE writing any code:

```markdown
## Hypotheses

### H1: [Most likely cause]
- **Theory**: [What you think is wrong]
- **Evidence needed**: [What logs/data would confirm this]
- **Confidence**: High/Medium/Low
- **Instrumentation**: [Where to add logs]

### H2: [Second most likely]
...
```

**Key principle**: Generate hypotheses by reading code, not guessing.

### Phase 4: INSTRUMENT

Add targeted logging to test hypotheses.

#### Instrumentation Rules

1. **Tag every log with hypothesis ID** (e.g., `[DEBUG-H1]`)
2. **Mark as DEBUG** in comment for easy cleanup
3. **Log at decision points**, not every line
4. **Include context**: variable names AND values
5. **Use structured format** for complex data

#### Language Examples

**Python:**
```python
# HYPOTHESIS: H1 - User object is null
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] user={user}, user_id={user_id}")
```

**JavaScript/TypeScript:**
```javascript
// HYPOTHESIS: H1 - Promise rejection not handled
// DEBUG: Remove after fix
console.log('[DEBUG-H1]', { userId, status, timestamp: Date.now() });
```

**Go:**
```go
// HYPOTHESIS: H1 - Nil pointer dereference
// DEBUG: Remove after fix
log.Printf("[DEBUG-H1] user=%+v config=%+v", user, config)
```

#### What to Log

| Location | What to Capture |
|----------|----------------|
| Function entry | Parameters, relevant state |
| Conditionals | Which branch taken and why |
| Loop iterations | Item being processed, state |
| Return values | Result being returned |
| Error paths | Exception type, context |

### Phase 5: REPRODUCE

Provide clear reproduction instructions:

```markdown
## Reproduction Steps

1. Start the application: `[command]`
2. Trigger the bug: [exact steps]
3. Capture output from: [log file/console/stderr]

**Log markers to look for:**
- [DEBUG-H1]: Tests [hypothesis 1]
- [DEBUG-H2]: Tests [hypothesis 2]
```

### Phase 6: ANALYZE

Match logs against each hypothesis:

```markdown
## Log Analysis

### H1: [Hypothesis name]
- **Expected if true**: [what logs should show]
- **Actual logs**: `[relevant lines]`
- **Verdict**: CONFIRMED / REJECTED / INCONCLUSIVE
- **Reasoning**: [explanation]
```

**If all hypotheses rejected:**
1. Generate new hypotheses from log findings
2. Add more instrumentation
3. Repeat the loop

### Phase 7: FIX

Once root cause is confirmed:

1. **Explain clearly** to the user
2. **Propose minimal fix** - don't over-engineer
3. **Keep instrumentation** until verified

```markdown
## Root Cause Analysis

**The bug**: [clear explanation]
**Why it happens**: [technical cause]
**The fix**: [proposed change]
```

### Phase 8: VERIFY

1. Apply the fix
2. Reproduce the original scenario
3. Confirm expected behavior occurs
4. Check for regressions

If not fixed, return to HYPOTHESIZE with new information.

### Phase 9: CLEAN

Remove all debug instrumentation:

```bash
# Find all debug logs
grep -rn "DEBUG-H[0-9]" --include="*.py" --include="*.js" --include="*.ts"
```

**Cleanup checklist:**
- [ ] Remove all `[DEBUG-Hx]` log statements
- [ ] Remove debug imports if no longer needed
- [ ] Run tests to ensure cleanup didn't break anything
- [ ] Commit the fix (not the debug logs)

## Quick Reference

| Phase | Action | Output |
|-------|--------|--------|
| EXPLORE | Understand relevant code | Context for hypotheses |
| DESCRIBE | Gather bug details | Clear reproduction steps |
| HYPOTHESIZE | Generate 3-5 theories | Ranked hypotheses |
| INSTRUMENT | Add targeted logs | Tagged debug statements |
| REPRODUCE | User triggers bug | Log output |
| ANALYZE | Match logs to hypotheses | Confirmed root cause |
| FIX | Minimal code change | Proposed fix |
| VERIFY | User confirms fix | Bug resolved |
| CLEAN | Remove instrumentation | Clean codebase |

## Anti-Patterns to Avoid

### 1. Shotgun Debugging
- **Bad**: Add logs everywhere and hope something shows up
- **Good**: Form hypotheses first, instrument surgically

### 2. Fixing Without Understanding
- **Bad**: Try random changes until it works
- **Good**: Understand root cause before changing code

### 3. Leaving Debug Code
- **Bad**: Commit code with debug logs
- **Good**: Always clean up instrumentation

### 4. Single Hypothesis
- **Bad**: Assume first guess is correct
- **Good**: Generate multiple hypotheses, let evidence decide

### 5. Skipping Verification
- **Bad**: Assume fix works after code change
- **Good**: Always reproduce and verify

## Advanced Techniques

### Git Bisect for Regressions

```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Test each commit until culprit found
```

### Conditional Instrumentation

For hard-to-reproduce bugs:
```python
if user_id == "problem_user":
    logging.debug(f"[DEBUG-H1] triggered: {state}")
```

### State Snapshots

```python
import json
# DEBUG: Remove after fix
with open('/tmp/debug-state.json', 'w') as f:
    json.dump({'user': user.__dict__}, f, default=str)
```

### Timing Measurement

```python
import time
start = time.time()
result = slow_operation()
logging.debug(f"[DEBUG-H2] elapsed={time.time()-start:.3f}s")
```

## Integration with TDD

After fixing a bug:

1. **Write a regression test** that would have caught this bug
2. **Add the test FIRST** (it should fail without the fix)
3. **Apply the fix** (test should pass)
4. **Commit both** test and fix together

```python
def test_regression_issue_123():
    """Regression test for bug where X happened.

    Root cause: [explanation]
    """
    # Arrange - reproduce exact conditions
    data = setup_bug_conditions()

    # Act
    result = function_that_was_buggy(data)

    # Assert - fix handles this case
    assert result == expected
```

## CLAUDE.md Integration

After fixing a recurring bug type, consider adding to CLAUDE.md:

```markdown
## Gotchas
- Always check for null before accessing user.profile
- API responses may have trailing whitespace in category field
```

This prevents the same bug class from recurring.
