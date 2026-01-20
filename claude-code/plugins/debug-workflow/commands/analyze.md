---
description: Analyze log output against debug hypotheses
model: opus
argument-hint: [bug-name]
---

# Log Analysis

Analyzing logs for: **$ARGUMENTS**

## Prerequisites

- `docs/debug/$ARGUMENTS-hypotheses.md` exists
- User has provided log output from reproduction

## Analysis Process

### 1. Parse Log Output

Extract all debug markers:
- `[DEBUG-H1]` lines → Hypothesis 1 evidence
- `[DEBUG-H2]` lines → Hypothesis 2 evidence
- `[DEBUG-H3]` lines → Hypothesis 3 evidence

### 2. Evaluate Each Hypothesis

For each hypothesis, determine verdict:

```markdown
## Log Analysis Results

### H1: [Hypothesis summary]

**Expected if true**: [what logs should show]

**Actual logs**:
```
[relevant log lines]
```

**Verdict**: CONFIRMED / REJECTED / INCONCLUSIVE

**Reasoning**: [why the logs lead to this verdict]

---

### H2: [Hypothesis summary]
...
```

### 3. Verdict Definitions

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| **CONFIRMED** | Logs prove this hypothesis | Proceed to FIX |
| **REJECTED** | Logs disprove this hypothesis | Eliminate, try next |
| **INCONCLUSIVE** | Logs don't provide enough evidence | Add more instrumentation |

### 4. Handle Results

**If CONFIRMED hypothesis found:**
- Proceed to fix phase
- Explain root cause clearly
- Propose minimal fix

**If all hypotheses REJECTED:**
- Generate new hypotheses from log insights
- What did the logs reveal that was unexpected?
- Add instrumentation for new theories

**If INCONCLUSIVE:**
- Identify what additional logs are needed
- Add targeted instrumentation
- Request another reproduction

## Root Cause Template

When hypothesis is confirmed:

```markdown
## Root Cause Analysis

### The Bug
[Clear one-sentence description of what's wrong]

### Why It Happens
[Technical explanation of the cause]

### Evidence
```
[Key log lines that prove this]
```

### The Fix
[Proposed code change]

### Why This Fixes It
[Explanation of how the fix addresses the root cause]

### Regression Test
[Test case that would catch this bug]
```

## Analysis Checklist

- [ ] All log markers extracted and categorized
- [ ] Each hypothesis evaluated against evidence
- [ ] Verdicts have clear reasoning
- [ ] Unexpected findings noted
- [ ] Root cause identified (if confirmed)
- [ ] Fix proposed (if confirmed)

## Common Log Analysis Patterns

### Null/Undefined Detection
```
[DEBUG-H1] user=null  ← H1 CONFIRMED: user is null when expected
```

### Wrong Branch Taken
```
[DEBUG-H2] condition=false, taking else branch  ← H2 CONFIRMED: wrong path
```

### State Not Updated
```
[DEBUG-H3] before save: status=pending
[DEBUG-H3] after save: status=pending  ← H3 CONFIRMED: save didn't work
```

### Timing Issue
```
[DEBUG-H1] request sent at 12:00:00.000
[DEBUG-H1] response received at 12:00:05.001  ← Timeout confirmed
```

## Next Steps

**If root cause found:**
```
Apply the fix, then verify:
/debug-workflow:verify $ARGUMENTS
```

**If more investigation needed:**
```
Add instrumentation for new hypotheses:
/debug-workflow:instrument $ARGUMENTS
```
