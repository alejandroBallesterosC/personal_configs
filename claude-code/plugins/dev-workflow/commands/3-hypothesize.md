---
description: Generate hypotheses for current bug based on exploration
model: opus
argument-hint: <bug-name>
---

# Hypothesis Generation

Generating hypotheses for: **$ARGUMENTS**

## STEP 1: LOAD WORKFLOW CONTEXT

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:debug-workflow-guide` to load the workflow source of truth.

---

## STEP 2: VALIDATE PREREQUISITES

### 2.1 Check exploration exists

Verify `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md` exists. If not:

**ERROR**: Output the following message and STOP:

```
Error: Exploration not found

The file docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md does not exist.
Exploration must be completed before generating hypotheses.

Run: /dev-workflow:1-explore-debug $ARGUMENTS
```

### 2.2 Check bug description exists

Verify `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md` exists. If not, inform the user that bug context will need to be gathered during hypothesis generation.

### 2.3 Read existing context

Read:
- `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md`
- `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md` (if exists)
- `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md` (if exists)

---

## STEP 3: GENERATE HYPOTHESES

Use the Task tool with `subagent_type: "dev-workflow:hypothesis-generator"` to generate 3-5 ranked hypotheses.

Provide the agent with:
- Bug description and reproduction steps
- Exploration findings
- Recent code changes
- Error messages and stack traces

Each hypothesis must include:

```markdown
### H[N]: [Descriptive Title]

**Theory**: [Detailed explanation of what's wrong and why]

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
```

---

## STEP 4: PRIORITIZE HYPOTHESES

### 4.1 Rank by testability

Reorder hypotheses if needed:
- Easiest to test first (if equal likelihood)
- Most likely first (if equal effort)
- Consider "quick wins" - easy to confirm/reject

### 4.2 Identify shared instrumentation

Look for logs that can test multiple hypotheses:
- Common code paths
- Shared data structures
- Central decision points

---

## STEP 5: REVIEW WITH USER

Present the hypotheses to the user. Use AskUserQuestionTool:
- "Do these hypotheses make sense given what you know about the bug?"
- Allow user to add context, suggest alternatives, or reprioritize

---

## STEP 6: SAVE HYPOTHESES

Write to: `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`

Include:
- Summary with ranked list
- Detailed hypothesis entries
- Shared instrumentation section
- Recommended investigation order

---

## STEP 7: UPDATE STATE FILE

Update `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`:
- Mark Phase 3 complete
- Add hypotheses status (all PENDING)
- Update current phase to Phase 4
- Record any key findings

---

## HYPOTHESIS QUALITY CHECKLIST

Before saving, verify:
- [ ] Each hypothesis is specific and testable (not "something in this file")
- [ ] Evidence needed is concrete (not vague)
- [ ] Instrumentation plan is actionable with file paths and line numbers
- [ ] Confidence is justified with reasoning
- [ ] Alternative explanations are considered
- [ ] At least 3 hypotheses generated

## Common Hypothesis Categories

| Category | Examples |
|----------|----------|
| **Data issues** | Null/undefined, wrong type, encoding, whitespace |
| **State issues** | Race condition, stale cache, mutation side effect |
| **Logic issues** | Off-by-one, wrong operator, missing case |
| **Integration** | API contract, timeout, auth, serialization |
| **Environment** | Config, permissions, resources, versions |
| **Timing** | Async ordering, timeout, debounce |

---

## NEXT STEPS

After generating hypotheses:
```
/dev-workflow:4-instrument $ARGUMENTS
```
