---
description: Explore codebase to understand systems relevant to a bug
model: opus
argument-hint: <area or bug description>
---

# Debug Exploration

Exploring codebase for: **$ARGUMENTS**

## STEP 1: LOAD WORKFLOW CONTEXT

**REQUIRED**: Use the Skill tool to invoke `debug-workflow:debug-workflow-guide` to load the workflow source of truth.

---

## STEP 2: VALIDATE PREREQUISITES

Check if a debug session directory exists at `docs/debug/$ARGUMENTS/`. If it does, read the state file to understand the current context.

If no session exists yet, this is a standalone exploration. Proceed directly to Step 3.

---

## STEP 3: LAUNCH EXPLORATION

Use the Task tool with `subagent_type: "debug-workflow:debug-explorer"` to investigate the codebase.

The debug-explorer agent should cover these 5 areas:

### 3.1 File Discovery

Find all files potentially related to the bug:
- Entry points (routes, handlers, CLI commands)
- Core logic (services, models, utilities)
- Configuration (env, config files, constants)
- Tests (existing test coverage for this area)

### 3.2 Execution Flow Mapping

Trace the code path from trigger to failure:
- Where does user input enter the system?
- What functions process the data?
- Where are external calls made?
- Where could failures occur?

### 3.3 Dependency Analysis

Understand what this code depends on:
- Internal modules imported
- External libraries used
- Database/API interactions
- Shared state or globals

### 3.4 Recent Changes

Check git history for potential regression:

```bash
# Recent commits to relevant files
git log --oneline -20 -- <relevant-paths>

# What changed in the last week
git diff HEAD~7 -- <relevant-paths>

# Who touched these files recently
git log --format='%an' -- <relevant-paths> | sort | uniq -c | sort -rn
```

### 3.5 Test Coverage

Understand existing test coverage:
- What tests exist for this area?
- What scenarios are covered?
- What's NOT tested?

---

## STEP 4: SAVE EXPLORATION FINDINGS

Write exploration findings to: `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md`

Use this template:

```markdown
# Exploration: $ARGUMENTS

## Relevant Files

| File | Purpose | Risk Level |
|------|---------|------------|
| `path/to/file.py` | [what it does] | High/Medium/Low |

## Execution Flow

```
[entry point] -> [function] -> [function] -> [potential failure]
```

## Dependencies

- **Internal**: [list]
- **External**: [list]
- **State**: [shared state accessed]

## Recent Changes

[summary of git history]

## Test Coverage

- **Covered**: [scenarios]
- **Gaps**: [missing tests]

## Initial Observations

[anything suspicious or noteworthy]
```

---

## STEP 5: UPDATE STATE FILE

If a debug session exists, update the state file:
- Mark Phase 1 complete
- Update current phase to Phase 2
- Record any key findings from exploration

---

## NEXT STEPS

After exploration, proceed to:

**If running full workflow:**
The orchestrator (`/debug-workflow:debug`) will continue to Phase 2 automatically.

**If running standalone:**
```
/debug-workflow:hypothesize $ARGUMENTS
```
