---
name: structured-debug
description: Hypothesis-driven debugging with instrumentation and tracing. Use when debugging errors, unexpected behavior, or investigating bugs.
---

# Structured Debugging Skill

Hypothesis-driven debugging methodology using systematic exploration, instrumentation, and log tracing. Based on practices from Boris Cherny, Cursor's Debug Mode, Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

**For workflow navigation and phase details**, see the `debug-workflow-guide` skill. This skill covers the **debugging methodology and technique**.

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

> "AI doesn't fail because it's not smart enough. It fails because it can't see what you see." - Nathan Onn

### The Iron Law

> **NO FIXES WITHOUT ROOT CAUSE PROVEN FIRST**

### The 3-Fix Rule

If 3+ fixes have failed, STOP and question the architecture. The problem is structural, not implementation.

### Red Flags (Return to Investigation)

If you catch yourself thinking any of these, STOP:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"


## The Debugging Loop

```
EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> VERIFY -> CLEAN
```

For the full 9-phase workflow with execution details, see the `debug-workflow-guide` skill or run `/dev-workflow:1-start-debug`.


## Hypothesis-Driven Approach

The core of this methodology is forming hypotheses BEFORE making changes.

### Generating Hypotheses

Read the code. Base hypotheses on evidence, not guessing.

```markdown
### H1: [Most likely cause]
- **Theory**: [What you think is wrong]
- **Evidence needed**: [What logs/data would confirm this]
- **Confidence**: High/Medium/Low
- **Instrumentation**: [Where to add logs]
```

### Common Root Cause Categories

| Category | Examples |
|----------|----------|
| **Data** | Null/undefined, wrong type, encoding, whitespace |
| **State** | Race condition, stale cache, mutation side effect |
| **Logic** | Off-by-one, wrong operator, missing case |
| **Integration** | API contract, timeout, auth, serialization |
| **Environment** | Config, permissions, resources, versions |
| **Timing** | Async ordering, timeout, debounce |

### Verdict Definitions

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| **CONFIRMED** | Logs prove this hypothesis | Proceed to fix |
| **REJECTED** | Logs disprove this hypothesis | Eliminate, try next |
| **INCONCLUSIVE** | Not enough evidence | Add more instrumentation |


## Instrumentation Rules

### The 5 Rules

1. **Tag every log with hypothesis ID** (e.g., `[DEBUG-H1]`)
2. **Mark as DEBUG** with `DEBUG: Remove after fix` for easy cleanup
3. **Log at decision points**, not every line
4. **Include context**: variable names AND values
5. **Use structured format** for complex data

### What to Log

| Location | What to Capture |
|----------|----------------|
| Function entry | Parameters, relevant state |
| Conditionals | Which branch taken and why |
| Loop iterations | Item being processed, state |
| Return values | Result being returned |
| Error paths | Exception type, context |
| External calls | Request data, response, timing |

### Language Examples

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

**Rust:**
```rust
// HYPOTHESIS: H1 - Ownership issue
// DEBUG: Remove after fix
eprintln!("[DEBUG-H1] data={:?} state={:?}", data, state);
```


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

### 6. Guessing Without Evidence
- **Bad**: "It's probably a race condition" → fix race condition
- **Good**: "It might be a race condition" → add timing logs → confirm/reject


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

### ASCII Diagrams for Complex Bugs

For multi-layer bugs where even the error message is misleading, use ASCII diagrams to map the error chain:

```
Error Chain:
  [Symptom: 500 error]
    <- [Trigger: null user profile]
      <- [Root: cache TTL expired during request]
```

Forcing systematic diagramming before proposing fixes helps identify the real root cause.


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


## Debug Workflow Commands

For the full orchestrated workflow:

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-debug <bug>` | Start full workflow |
| `/dev-workflow:2-explore-debug <area>` | Explore codebase |
| `/dev-workflow:3-hypothesize <name>` | Generate hypotheses |
| `/dev-workflow:4-instrument <name>` | Add logging |
| `/dev-workflow:5-analyze <name>` | Analyze logs |
| `/dev-workflow:6-verify <name>` | Verify fix + cleanup |
| `/dev-workflow:continue-workflow <name>` | Resume session |
| `/dev-workflow:help` | Show help |
