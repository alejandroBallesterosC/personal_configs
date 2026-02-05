---
description: Continue an in-progress debug session from saved state
model: opus
argument-hint: <bug-name>
---

# Continue Debug Workflow

**Bug**: $1

This command continues an in-progress debug session by reading the saved state and artifacts from the `docs/debug/` directory.

---

## STEP 1: VALIDATE SESSION EXISTS

### 1.1 Check for debug session directory

Check if the `docs/debug/$1/` directory exists. If it does not exist:

**ERROR**: Output the following message and STOP:

```
Error: No debug session found

The docs/debug/$1/ directory does not exist in this repository.

To start a debug session, use:
  /debug-workflow:debug <bug description or error message>
```

### 1.2 Check for state file

If `docs/debug/$1/` exists, check for `docs/debug/$1/$1-state.md`. If this file does not exist:

**ERROR**: Output the following message and STOP:

```
Error: No state file found for '$1'

The file docs/debug/$1/$1-state.md does not exist.

Available debug sessions in docs/debug/:
[List all docs/debug/*/ directories found, or "None" if none exist]

To start a debug session for '$1', use:
  /debug-workflow:debug <bug description or error message>
```

### 1.3 Check if session is complete

If `docs/debug/$1/$1-state.md` exists, read its contents and check if the session is already complete.

The session is complete if either:
- The "Current Phase" section contains "COMPLETE"
- All 9 phases are checked in "Completed Phases"

If the session is complete:

**ERROR**: Output the following message and STOP:

```
Error: Debug session for '$1' is already complete

The session at docs/debug/$1/$1-state.md shows status COMPLETE.

To start a fresh debug session:
1. Archive or delete the existing session directory: docs/debug/$1/
2. Run: /debug-workflow:debug <bug description or error message>
```

---

## STEP 2: LOAD CONTEXT FOR CONTINUATION

If validation passes, the session is in progress. Now restore full context.

### 2.1 Load workflow context

**REQUIRED**: Use the Skill tool to invoke `debug-workflow:debug-workflow-guide` to load workflow context.

Then output:
```
Continuing debug session for '$1'
```

### 2.2 Read all context restoration files

Read the following files (in order) to fully restore context:

1. **State file** (already read in validation): `docs/debug/$1/$1-state.md`
2. **Bug description**: `docs/debug/$1/$1-bug.md` (if exists)
3. **Exploration findings**: `docs/debug/$1/$1-exploration.md` (if exists)
4. **Hypotheses**: `docs/debug/$1/$1-hypotheses.md` (if exists)
5. **Log analysis**: `docs/debug/$1/$1-analysis.md` (if exists)
6. **Resolution**: `docs/debug/$1/$1-resolution.md` (if exists)
7. **Project conventions**: `CLAUDE.md`

For each file that exists, read it completely. Skip files that don't exist (they may not have been created yet depending on the current phase).

### 2.3 Summarize current state

After reading all files, output a summary:

```markdown
## Debug Session Context Restored

**Bug**: $1

### Current State (from state file)
- **Phase**: [Current phase from state file]
- **Hypothesis**: [If applicable, which hypothesis is being tested]
- **Last Action**: [From state file]
- **Next Action**: [From state file]

### Hypotheses Status
- H1: [summary] - [status]
- H2: [summary] - [status]
- H3: [summary] - [status]

### Failed Fix Attempts
[Count from state file]

### Artifacts Loaded
- [x] State file: docs/debug/$1/$1-state.md
- [x/blank] Bug description: docs/debug/$1/$1-bug.md
- [x/blank] Exploration: docs/debug/$1/$1-exploration.md
- [x/blank] Hypotheses: docs/debug/$1/$1-hypotheses.md
- [x/blank] Analysis: docs/debug/$1/$1-analysis.md
- [x] Project conventions: CLAUDE.md

### Key Findings (from state file)
[List any key findings recorded in the state file]
```

---

## STEP 3: CONTINUE THE SESSION

Based on the current phase from the state file, continue the workflow.

### Phase Continuation Mapping

| Current Phase | How to Continue |
|---------------|-----------------|
| Phase 1: Explore | Continue exploration, then Phase 2 |
| Phase 2: Describe | Continue gathering bug context from user |
| Phase 3: Hypothesize | Continue hypothesis generation |
| Phase 4: Instrument | Continue adding instrumentation |
| Phase 5: Reproduce | Ask user to reproduce and share logs |
| Phase 6: Analyze | Continue log analysis |
| Phase 7: Fix | Apply fix (check 3-Fix Rule) |
| Phase 8: Verify | Guide user through verification |
| Phase 9: Clean | Complete cleanup and archival |

### Continuation Instructions

Based on the **Current Phase** and **Next Action** from the state file:

1. **Understand the full context** from all loaded artifacts
2. **Identify exactly where we left off** from the state file's "Session Progress" section
3. **Continue the workflow** following the instructions in `debug.md` for that phase step

### For Loopback Phases

If the state file indicates a loopback (e.g., "all hypotheses rejected, generating new ones"):

1. Read the analysis file to understand what was rejected and why
2. Use the unexpected findings to generate new hypotheses
3. Continue from Phase 3 with the new context

---

## IMPORTANT NOTES

### Automatic Context Preservation

The debug workflow uses hooks for automatic context preservation:
- **Stop hook** (agent): Verifies state file is up to date before Claude stops; blocks stopping if outdated
- **SessionStart hook** (command): Restores context after compaction or clear

This command (`/continue-workflow`) is for **manual continuation** in scenarios where:
- You're starting a fresh session (not triggered by compaction/clear)
- You want to explicitly resume a specific debug session by name

### Maintaining State

As you continue the workflow:
- The Stop hook will verify the state file is up to date before Claude stops responding
- If the state file is outdated, Claude is blocked from stopping until it updates the state file
- Key findings should be recorded in the "Key Findings" section
- Hypothesis verdicts should be updated as they are determined

---

## BEGIN CONTINUATION

Now execute the steps above:

1. Validate session exists (check docs/debug/$1/$1-state.md)
2. Load all context restoration files
3. Continue workflow from current phase

Starting validation...
