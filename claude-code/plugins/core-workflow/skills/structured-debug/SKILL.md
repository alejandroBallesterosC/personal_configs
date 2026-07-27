---
name: structured-debug
description: Hypothesis-driven debugging methodology with instrumentation and log tracing. Use when debugging errors, investigating bugs, diagnosing unexpected behavior, performing root cause analysis, adding debug logging, writing regression tests after fixes, or when tests fail for unclear reasons. Covers hypothesis generation, tagged instrumentation ([DEBUG-H1]), the 3-Fix Rule, and anti-patterns to avoid.
effort: high
---

# Structured Debugging

Hypothesis-driven debugging: form theories from evidence, instrument to test them, and fix only once the root cause is proven.

## The Iron Law

**No fixes without root cause proven first.**

A fix applied before the cause is proven is a guess. It may coincidentally pass the test and leave the real defect in place.

## The 3-Fix Rule

If three fixes have failed, stop and question the architecture. The problem is structural, not a detail of the implementation.

## Red flags

These thoughts mean you have left the method and are guessing:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run the tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"

## The loop

```
EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> CLEAN
```

Apply it as a checklist for the bug at hand. Generate several hypotheses rather than committing to the first, and let the evidence eliminate them:

```markdown
### H1: [Most likely cause]
- **Theory**: [what you think is wrong]
- **Evidence needed**: [what logs or data would confirm it]
- **Confidence**: High/Medium/Low
- **Instrumentation**: [where to add logs]
```

A hypothesis ends as CONFIRMED (the logs prove it, proceed to fix), REJECTED (the logs disprove it, move to the next), or INCONCLUSIVE (add more instrumentation). Do not treat INCONCLUSIVE as confirmation.

Root cause categories worth walking when generating hypotheses:

| Category | Examples |
|----------|----------|
| **Data** | Null/undefined, wrong type, encoding, whitespace |
| **State** | Race condition, stale cache, mutation side effect |
| **Logic** | Off-by-one, wrong operator, missing case |
| **Integration** | API contract, timeout, auth, serialization |
| **Environment** | Config, permissions, resources, versions |
| **Timing** | Async ordering, timeout, debounce |

## Instrumentation

The conventions that matter here:

1. **Tag every log with its hypothesis ID**, e.g. `[DEBUG-H1]`, so log lines map back to the theory they test.
2. **Mark each one** with a `DEBUG: Remove after fix` comment so cleanup is greppable.
3. **Log at decision points**, not every line. Include variable names *and* values.
4. **Write all debug output to `logs/debug-output.log`** at the repo root. The file is opened in overwrite mode at application startup, so it holds only the latest run. Read it directly after reproducing — never ask the user to copy and paste logs.

Instrument function entries (parameters and relevant state), conditionals (which branch and why), loop iterations, return values, error paths (exception type and context), and external calls (request, response, timing).

The non-obvious part is the one-time entry point setup: create the `logs/` directory and open the file in overwrite mode (`w`), then have every instrumentation point append to it.

**Python** — entry point adds a `FileHandler` with `mode="w"`; instrumentation points use the logger:
```python
# HYPOTHESIS: H1 - User object is null
# DEBUG: Remove after fix
logging.getLogger("debug_hypotheses").debug(f"[DEBUG-H1] user={user}, user_id={user_id}")
```

**JavaScript/TypeScript** — entry point creates the file and a `globalThis._debugLog` helper:
```javascript
// HYPOTHESIS: H1 - Promise rejection not handled
// DEBUG: Remove after fix
globalThis._debugLog(`[DEBUG-H1] ${JSON.stringify({ userId, status, timestamp: Date.now() })}`);
```

Other languages follow the same shape: open the log file in overwrite mode once at the entry point (`log.New` with `os.Create` in Go, `File::create` in Rust), then write tagged lines at instrumentation points.

For a bug that reproduces only under specific conditions, guard the log on those conditions rather than logging every call.

## Anti-patterns

- **Shotgun debugging** — logs everywhere hoping something shows up. Hypothesize first, then instrument surgically.
- **Fixing without understanding** — random changes until the symptom disappears. That leaves the cause in place.
- **A single hypothesis** — assuming the first guess is right. Generate several and let evidence decide.
- **Leaving debug code** — instrumentation must come out before the work is committed.
- **Stating a guess as a cause** — "it's probably a race condition" is a hypothesis, not a finding. Add timing logs and confirm it.

## After the fix

Write a regression test that would have caught the bug, and add it before applying the fix so you watch it fail first. Commit the test and the fix together. Name the root cause in the test's docstring, since that is what makes the test legible a year later.

If a bug class recurs, record it under a "Gotchas" heading in the project's AGENTS.md so the next session starts with it.
