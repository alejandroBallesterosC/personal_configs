---
description: Add targeted instrumentation to test debug hypotheses
model: opus
argument-hint: [bug-name]
---

# Debug Instrumentation

Adding instrumentation for: **$ARGUMENTS**

## Prerequisites

Ensure hypotheses exist:
- `docs/debug/$ARGUMENTS-hypotheses.md` exists

## Instrumentation Rules

### 1. Tag Every Log

```python
# HYPOTHESIS: H1 - Variable state incorrect
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] user_id={user_id}, status={status}")
```

### 2. Mark for Cleanup

Every debug statement must have:
- `HYPOTHESIS: Hx` comment explaining purpose
- `DEBUG: Remove after fix` marker

### 3. Log at Decision Points

Focus on:
- Function entry/exit with parameters
- Conditional branches (which path taken)
- Loop iterations with relevant state
- Return values
- Error handling paths

### 4. Include Full Context

Bad:
```python
print("here")  # Useless
```

Good:
```python
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] process_order entry: order_id={order.id}, status={order.status}, items={len(order.items)}")
```

## Language-Specific Patterns

### Python

```python
import logging
logging.basicConfig(level=logging.DEBUG)

# HYPOTHESIS: H1 - Order status not updated
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] before save: order.status={order.status}")
order.save()
logging.debug(f"[DEBUG-H1] after save: order.status={order.status}")
```

### JavaScript/TypeScript

```javascript
// HYPOTHESIS: H1 - Promise rejection not handled
// DEBUG: Remove after fix
console.log('[DEBUG-H1] entering fetchUser', { userId, options });

try {
  const result = await fetchUser(userId);
  console.log('[DEBUG-H1] fetchUser success', { result });
} catch (error) {
  console.log('[DEBUG-H1] fetchUser error', { error: error.message, stack: error.stack });
}
```

### Go

```go
// HYPOTHESIS: H1 - Nil pointer dereference
// DEBUG: Remove after fix
log.Printf("[DEBUG-H1] user=%+v config=%+v", user, config)

if user != nil {
    log.Printf("[DEBUG-H1] user.Name=%s", user.Name)
}
```

### Rust

```rust
// HYPOTHESIS: H1 - Borrow checker issue
// DEBUG: Remove after fix
eprintln!("[DEBUG-H1] data before mutation: {:?}", data);
data.mutate();
eprintln!("[DEBUG-H1] data after mutation: {:?}", data);
```

## Instrumentation Checklist

For each hypothesis, add logs to capture:

- [ ] **Entry point**: Function called with what arguments
- [ ] **Decision points**: Which branch was taken and why
- [ ] **State changes**: Before and after mutations
- [ ] **External calls**: Request and response data
- [ ] **Exit point**: Return value or error

## Output

After adding instrumentation, provide reproduction instructions:

```markdown
## Reproduction Instructions

1. Start the application:
   ```bash
   [command to start with debug logging enabled]
   ```

2. Trigger the bug:
   - [Step 1]
   - [Step 2]
   - [Step 3]

3. Capture logs:
   ```bash
   [command to capture relevant logs]
   ```

4. Look for these markers:
   - `[DEBUG-H1]`: Tests [hypothesis 1 description]
   - `[DEBUG-H2]`: Tests [hypothesis 2 description]
   - `[DEBUG-H3]`: Tests [hypothesis 3 description]

Share the log output and I'll analyze it against the hypotheses.
```

## Advanced Techniques

### Conditional Logging (Hard to Reproduce)

```python
# DEBUG: Remove after fix - only log for specific user
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

## Next Steps

After user captures logs:
```
/debug-workflow:analyze $ARGUMENTS
```
