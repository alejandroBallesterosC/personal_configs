---
description: Analyze log output against debug hypotheses
model: opus
argument-hint: <bug-name>
---

# Log Analysis

Analyzing logs for: **$ARGUMENTS**

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
Hypotheses must be generated before analyzing logs.

Run: /dev-workflow:3-hypothesize $ARGUMENTS
```

### 2.2 Read debug log output

Read `logs/debug-output.log` from the repository root. This file contains the debug output from the user's latest bug reproduction run (overwritten on each application run, so only the latest logs are present).

If the file is empty or missing, ask the user to confirm they reproduced the bug and check that the application ran correctly.

### 2.3 Read context

Read:
- `logs/debug-output.log` (the debug output)
- `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`
- `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md` (if exists, to check for previous analysis rounds)

---

## STEP 3: ANALYZE LOGS

Use the Task tool with `subagent_type: "dev-workflow:log-analyzer"` to analyze the log output against hypotheses.

Provide the agent with:
- The contents of `logs/debug-output.log`
- The full hypotheses file
- Any previous analysis results (for loopback rounds)

The agent should:
1. Extract all debug markers (`[DEBUG-H1]`, `[DEBUG-H2]`, etc.)
2. Map evidence to each hypothesis
3. Evaluate each hypothesis against expected evidence
4. Determine verdicts: CONFIRMED / REJECTED / INCONCLUSIVE

---

## STEP 4: SAVE ANALYSIS

Write to: `docs/debug/$ARGUMENTS/$ARGUMENTS-analysis.md`

Use this template:

```markdown
# Log Analysis: $ARGUMENTS

## Log Summary
Total debug lines captured: [N]
- [DEBUG-H1]: [count] lines
- [DEBUG-H2]: [count] lines
- [DEBUG-H3]: [count] lines

---

## H1: [Hypothesis Summary]

**Expected if true**: [what logs should show]

**Actual logs**:
[relevant log lines]

**Verdict**: CONFIRMED / REJECTED / INCONCLUSIVE

**Reasoning**: [detailed explanation]

---

## H2: [Hypothesis Summary]
...

---

## Overall Conclusion

**Root Cause**: [If confirmed, explain the bug]
**Confidence**: High / Medium / Low
**Evidence Summary**:
1. [Key evidence]
2. [Key evidence]
```

---

## STEP 5: HANDLE ANALYSIS RESULTS

### 5.1 If a hypothesis is CONFIRMED

Proceed to the fix phase:

```markdown
## Root Cause Analysis

**The Bug**: [clear one-sentence description]
**Why It Happens**: [technical explanation]
**Key Evidence**: [critical log lines]
**The Fix**: [proposed code change]
**Why This Fixes It**: [how fix addresses root cause]
```

Update state file: mark hypothesis as CONFIRMED, advance to Phase 7.

### 5.2 If all hypotheses are REJECTED

Generate new hypotheses from unexpected log findings:

1. Review what the logs DID reveal (unexpected values, paths, timing)
2. Generate new hypotheses H4, H5 based on these findings
3. Inform the user: "All initial hypotheses were rejected. The logs revealed: [findings]. Generating new hypotheses."
4. Loop back to Phase 3 (hypothesize) with the new context

Update state file: mark rejected hypotheses, note unexpected findings, set phase back to Phase 3.

### 5.3 If INCONCLUSIVE

Identify what additional instrumentation is needed:

1. What evidence is missing?
2. Where should new logs be added?
3. Loop back to Phase 4 (instrument) to add more targeted logging

Update state file: note what's inconclusive, set phase back to Phase 4.

---

## STEP 6: UPDATE STATE FILE

Update `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`:
- Update hypothesis verdicts
- Record key findings from log analysis
- Update current phase based on results (Phase 7, or loopback to 3/4)
- Update next action

---

## COMMON LOG ANALYSIS PATTERNS

### Null/Undefined Detection
```
[DEBUG-H1] user=null  <- H1 CONFIRMED: user is null when expected
```

### Wrong Branch Taken
```
[DEBUG-H2] condition=false, taking else branch  <- H2 CONFIRMED: wrong path
```

### State Not Updated
```
[DEBUG-H3] before save: status=pending
[DEBUG-H3] after save: status=pending  <- H3 CONFIRMED: save didn't work
```

### Timing Issue
```
[DEBUG-H1] request sent at 12:00:00.000
[DEBUG-H1] response received at 12:00:05.001  <- Timeout confirmed
```

---

## NEXT STEPS

**If root cause found:**
```
Proceed to fix phase, then verify:
/dev-workflow:8-verify $ARGUMENTS
```

**If more investigation needed:**
```
Add instrumentation for new hypotheses:
/dev-workflow:4-instrument $ARGUMENTS
```
