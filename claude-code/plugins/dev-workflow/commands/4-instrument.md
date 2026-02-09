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
6. **Write to `logs/debug-output.log`**: All debug output MUST go to this file (relative to repo root). The file MUST be **overwritten** at application startup so only the latest run's logs are present. Add a one-time initialization block near the entry point that creates the `logs/` directory and truncates the file, then all debug logs append to it during that run. Add `logs/` to `.gitignore` if not already present.

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
   [command to start]

2. **Trigger the bug**:
   - [Step 1]
   - [Step 2]
   - [Step 3]

3. **Debug logs are captured automatically** to `logs/debug-output.log` (repo root).
   The file is overwritten on each run, so only your latest reproduction attempt is captured.

4. **When done**, just let me know and I'll read the log file directly.
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

**Entry point** (add once near app startup):
```python
# DEBUG: Remove after fix - debug log file setup
import os, logging
os.makedirs("logs", exist_ok=True)
_debug_handler = logging.FileHandler("logs/debug-output.log", mode="w")
_debug_handler.setFormatter(logging.Formatter("%(message)s"))
_debug_logger = logging.getLogger("debug_hypotheses")
_debug_logger.addHandler(_debug_handler)
_debug_logger.setLevel(logging.DEBUG)
```

**At instrumentation points:**
```python
# HYPOTHESIS: H1 - Variable state incorrect
# DEBUG: Remove after fix
logging.getLogger("debug_hypotheses").debug(f"[DEBUG-H1] var={var}, expected={expected}")
```

### JavaScript/TypeScript

**Entry point** (add once at app startup):
```javascript
// DEBUG: Remove after fix - debug log file setup
const fs = require('fs');
const path = require('path');
const _debugLogPath = path.join(process.cwd(), 'logs/debug-output.log');
fs.mkdirSync(path.dirname(_debugLogPath), { recursive: true });
fs.writeFileSync(_debugLogPath, '');
globalThis._debugLog = (msg) => fs.appendFileSync(_debugLogPath, msg + '\n');
```

**At instrumentation points:**
```javascript
// HYPOTHESIS: H1 - Promise rejection not handled
// DEBUG: Remove after fix
globalThis._debugLog(`[DEBUG-H1] ${JSON.stringify({ var, expected, timestamp: Date.now() })}`);
```

### Go

**Entry point** (add once in `main()`):
```go
// DEBUG: Remove after fix - debug log file setup
os.MkdirAll("logs", 0755)
debugFile, _ := os.Create("logs/debug-output.log")
debugLog := log.New(debugFile, "", log.Ltime)
```

**At instrumentation points:**
```go
// HYPOTHESIS: H1 - Nil pointer dereference
// DEBUG: Remove after fix
debugLog.Printf("[DEBUG-H1] user=%+v config=%+v", user, config)
```

### Rust

**Entry point** (add once in `main()`):
```rust
// DEBUG: Remove after fix - debug log file setup
std::fs::create_dir_all("logs").ok();
let debug_file = std::fs::File::create("logs/debug-output.log").unwrap();
```

**At instrumentation points:**
```rust
// HYPOTHESIS: H1 - Ownership issue
// DEBUG: Remove after fix
writeln!(debug_file, "[DEBUG-H1] data={:?} state={:?}", data, state).ok();
```

### Java

**Entry point** (add once in `main()`):
```java
// DEBUG: Remove after fix - debug log file setup
new java.io.File("logs").mkdirs();
java.io.PrintWriter debugLog = new java.io.PrintWriter(new java.io.FileWriter("logs/debug-output.log", false));
```

**At instrumentation points:**
```java
// HYPOTHESIS: H1 - Null pointer exception
// DEBUG: Remove after fix
debugLog.println("[DEBUG-H1] object=" + object + " field=" + object.getField());
debugLog.flush();
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
/dev-workflow:6-analyze $ARGUMENTS
```
