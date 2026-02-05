---
description: Add targeted instrumentation to test debug hypotheses
model: opus
argument-hint: <bug-name>
---

# Debug Instrumentation

Adding instrumentation for: **$ARGUMENTS**

## STEP 1: LOAD WORKFLOW CONTEXT

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:debug-workflow-guide` to load the workflow source of truth.

---

## STEP 2: VALIDATE PREREQUISITES

### 2.1 Check hypotheses exist

Verify `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md` exists. If not:

**ERROR**: Output the following message and STOP:

```
Error: Hypotheses not found

The file docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md does not exist.
Hypotheses must be generated before adding instrumentation.

Run: /dev-workflow:3-hypothesize $ARGUMENTS
```

### 2.2 Read context

Read:
- `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`
- `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md` (for file paths)
- `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md` (if exists)

---

## STEP 3: ADD INSTRUMENTATION

Use the Task tool with `subagent_type: "dev-workflow:instrumenter"` to add targeted logging.

Provide the agent with:
- The full hypotheses file
- File paths from the exploration
- Bug description for context

### Instrumentation Rules

The instrumenter must follow these rules:

1. **Tag every log** with hypothesis ID: `[DEBUG-H1]`, `[DEBUG-H2]`
2. **Mark for cleanup**: Every debug statement needs TWO markers:
   - `HYPOTHESIS: Hx - description` (explains purpose)
   - `DEBUG: Remove after fix` (marks for cleanup)
3. **Log at decision points**, not every line
4. **Include context**: Variable names AND values
5. **Use structured format** for complex data

---

## STEP 4: VERIFY INSTRUMENTATION

After the instrumenter agent completes, verify the work:

### 4.1 Check tagging

Confirm all logs are tagged with hypothesis IDs. Search for:
- `[DEBUG-H1]`, `[DEBUG-H2]`, `[DEBUG-H3]` markers
- `DEBUG: Remove after fix` cleanup markers

### 4.2 Check coverage

For each hypothesis, verify logs will capture the evidence needed:
- [ ] **Entry point**: Function called with what arguments
- [ ] **Decision points**: Which branch was taken and why
- [ ] **State changes**: Before and after mutations
- [ ] **External calls**: Request and response data
- [ ] **Exit point**: Return value or error

### 4.3 Check safety

Verify instrumentation does NOT:
- Change program behavior
- Introduce side effects
- Break existing functionality

---

## STEP 5: CREATE REPRODUCTION INSTRUCTIONS

Write clear instructions for the user:

```markdown
## Reproduction Instructions

1. **Start the application**:
   [command to start with debug logging enabled]

2. **Trigger the bug**:
   - [Step 1]
   - [Step 2]
   - [Step 3]

3. **Capture logs**:
   - Check `logs/debug/` directory if configured
   - Or capture console/stderr output

4. **Log markers to look for**:
   - `[DEBUG-H1]`: Tests [hypothesis 1 summary]
   - `[DEBUG-H2]`: Tests [hypothesis 2 summary]
   - `[DEBUG-H3]`: Tests [hypothesis 3 summary]

Share the log output and I'll analyze it against the hypotheses.
```

---

## STEP 6: UPDATE STATE FILE

Update `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`:
- Mark Phase 4 complete
- Update current phase to Phase 5 (Reproduce)
- Note which files were instrumented

---

## LANGUAGE-SPECIFIC PATTERNS

### Python

```python
import logging
logging.basicConfig(level=logging.DEBUG, format='%(levelname)s: %(message)s')

# HYPOTHESIS: H1 - Variable state incorrect
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] var={var}, expected={expected}")
```

### JavaScript/TypeScript

```javascript
// HYPOTHESIS: H1 - Promise rejection not handled
// DEBUG: Remove after fix
console.log('[DEBUG-H1]', { var, expected, timestamp: Date.now() });
```

### Go

```go
// HYPOTHESIS: H1 - Nil pointer dereference
// DEBUG: Remove after fix
log.Printf("[DEBUG-H1] user=%+v config=%+v", user, config)
```

### Rust

```rust
// HYPOTHESIS: H1 - Ownership issue
// DEBUG: Remove after fix
eprintln!("[DEBUG-H1] data={:?} state={:?}", data, state);
```

### Java

```java
// HYPOTHESIS: H1 - Null pointer exception
// DEBUG: Remove after fix
System.out.println("[DEBUG-H1] object=" + object + " field=" + object.getField());
```

---

## ADVANCED TECHNIQUES

### Conditional Logging (Hard to Reproduce)

```python
# DEBUG: Remove after fix - only log for specific conditions
if user_id == "problem_user_123":
    logging.debug(f"[DEBUG-H1] conditional capture: state={state}")
```

### State Snapshots

```python
import json

# DEBUG: Remove after fix
with open('/tmp/debug-state.json', 'w') as f:
    json.dump({
        'user': user.__dict__,
        'order': order.__dict__,
        'timestamp': str(datetime.now())
    }, f, default=str)
```

### Timing Measurements

```python
import time

# DEBUG: Remove after fix
start = time.time()
result = slow_operation()
elapsed = time.time() - start
logging.debug(f"[DEBUG-H2] slow_operation took {elapsed:.3f}s")
```

---

## NEXT STEPS

After user captures logs:
```
/dev-workflow:5-analyze $ARGUMENTS
```
