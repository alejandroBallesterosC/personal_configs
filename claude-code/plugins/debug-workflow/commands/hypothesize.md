---
description: Generate hypotheses for current bug based on exploration
model: opus
argument-hint: [bug-name]
---

# Hypothesis Generation

Generating hypotheses for: **$ARGUMENTS**

## Prerequisites

Ensure exploration is complete:
- `docs/debug/$ARGUMENTS-exploration.md` exists
- `docs/debug/$ARGUMENTS-bug.md` exists (bug description)

## Process

### 1. Review Context

Read:
- Bug description and reproduction steps
- Exploration findings
- Recent code changes
- Error messages and stack traces

### 2. Generate Hypotheses

Create **3-5 hypotheses** ranked by likelihood:

```markdown
## Hypotheses

### H1: [Most likely - one-line summary]

**Theory**: [Detailed explanation of what you think is wrong]

**Why likely**:
- [Evidence from exploration]
- [Code pattern that suggests this]
- [Recent change that could cause this]

**Evidence needed**:
- Log showing [specific data/state]
- Confirmation that [condition] is true/false

**Confidence**: High/Medium/Low

**Instrumentation plan**:
- Add log at [location] to capture [data]
- Add log at [location] to track [flow]

---

### H2: [Second most likely]
...

### H3: [Alternative explanation]
...
```

### 3. Prioritize by Testability

Reorder hypotheses if needed:
- Easiest to test first (if equal likelihood)
- Most likely first (if equal effort)
- Consider "quick wins" - easy to confirm/reject

### 4. Identify Shared Instrumentation

Look for logs that can test multiple hypotheses:
- Common code paths
- Shared data structures
- Central decision points

## Output

Write to: `docs/debug/$ARGUMENTS-hypotheses.md`

## Hypothesis Quality Checklist

- [ ] Each hypothesis is specific and testable
- [ ] Evidence needed is concrete (not vague)
- [ ] Instrumentation plan is actionable
- [ ] Confidence is justified with reasoning
- [ ] Alternative explanations are considered

## Common Hypothesis Categories

| Category | Examples |
|----------|----------|
| **Data issues** | Null/undefined, wrong type, encoding, whitespace |
| **State issues** | Race condition, stale cache, mutation |
| **Logic issues** | Off-by-one, wrong operator, missing case |
| **Integration** | API contract, timeout, auth, serialization |
| **Environment** | Config, permissions, resources, versions |
| **Timing** | Async ordering, timeout, debounce |

## Next Steps

After generating hypotheses:
```
/debug-workflow:instrument $ARGUMENTS
```
