---
description: Start systematic hypothesis-driven debugging workflow
model: opus
argument-hint: <bug description or error message>
---

# Debug Workflow

Debugging: **$ARGUMENTS**

This command initiates a systematic, hypothesis-driven debugging workflow. Based on Cursor's Debug Mode, practices from Boris Cherny, Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

---

## STEP 1: LOAD WORKFLOW CONTEXT

**REQUIRED**: Use the Skill tool to invoke `dev-workflow:debug-workflow-guide` to load the workflow source of truth.

Then output:
```
Starting debug workflow for: $ARGUMENTS
```

---

## STEP 2: CREATE DEBUG SESSION

### 2.1 Create artifact directory

Create the directory structure for this debug session:

```
docs/debug/$ARGUMENTS/
```

### 2.2 Create state file

Write the initial state file to `docs/debug/$ARGUMENTS/$ARGUMENTS-state.md`:

```markdown
---
workflow_type: debug
name: $ARGUMENTS
status: in_progress
current_phase: "Phase 1: Explore"
fix_attempts: 0
max_fix_attempts: 3
---

# Debug Session State: $ARGUMENTS

## Current Phase
Phase 1: Explore

## Bug
- **Name**: $ARGUMENTS
- **Description**: [From user's bug description]

## Completed Phases
- [ ] Phase 1: Explore
- [ ] Phase 2: Describe
- [ ] Phase 3: Hypothesize
- [ ] Phase 4: Instrument
- [ ] Phase 5: Reproduce
- [ ] Phase 6: Analyze
- [ ] Phase 7: Fix
- [ ] Phase 8: Verify
- [ ] Phase 9: Clean

## Hypotheses Status
[Not yet generated]

## Failed Fix Attempts
Count: 0/3

## Key Findings
[None yet]

## Session Progress (Auto-saved)
- **Phase**: Phase 1: Explore
- **Hypothesis**: N/A
- **Next Action**: Explore codebase for context on the bug

## Context Restoration Files
Read these files to restore context:
1. Use the debug-workflow-guide skill if needed
2. docs/debug/$ARGUMENTS/$ARGUMENTS-state.md (this file)
3. docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md
4. docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md
5. docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md
6. docs/debug/$ARGUMENTS/$ARGUMENTS-analysis.md
7. CLAUDE.md
```

### 2.3 Save original prompt

Write the user's bug description to `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md` with what is known so far. This file will be enriched in Phase 2.

---

## STEP 3: PHASE 1 - EXPLORE (Codebase Understanding)

Before debugging, understand the relevant systems.

### 3.1 Launch exploration

Use the Task tool with `subagent_type: "dev-workflow:debug-explorer"` to explore the codebase for context on: **$ARGUMENTS**

Provide the agent with:
- The bug description
- Any error messages or stack traces mentioned
- Any file paths or function names referenced

### 3.2 Save exploration findings

Write exploration output to: `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md`

### 3.3 Update state file

Mark Phase 1 complete. Update current phase to Phase 2.

---

## STEP 4: PHASE 2 - DESCRIBE (Gather Bug Context)

**HUMAN GATE**: Collect complete information about the bug from the user.

### 4.1 Ask clarifying questions

Use AskUserQuestionTool to gather any missing information:

1. **Expected vs Actual**: What should happen? What happens instead?
2. **Reproduction**: What are the exact steps to trigger this?
3. **Timing**: When did this start? What changed recently?
4. **Environment**: What conditions trigger it? (user, data, config)
5. **Error Messages**: Exact error text, stack traces, log output

Skip questions where the answer is already known from the bug description.

### 4.2 Update bug description

Enrich `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md` with the user's answers:

```markdown
# Bug Report: $ARGUMENTS

## Expected Behavior
[description]

## Actual Behavior
[description]

## Reproduction Steps
1. [step]
2. [step]

## Error Messages
[exact error output]

## Recent Changes
[git log of relevant files]

## Environment
- [relevant conditions]
```

### 4.3 Update state file

Mark Phase 2 complete. Update current phase to Phase 3.

---

## STEP 5: PHASE 3 - HYPOTHESIZE (Generate Theories)

### 5.1 Generate hypotheses

Use the Task tool with `subagent_type: "dev-workflow:hypothesis-generator"` to generate 3-5 ranked hypotheses.

Provide the agent with:
- Bug description from `docs/debug/$ARGUMENTS/$ARGUMENTS-bug.md`
- Exploration findings from `docs/debug/$ARGUMENTS/$ARGUMENTS-exploration.md`

### 5.2 Review hypotheses

Present the hypotheses to the user. Ask via AskUserQuestionTool:
- "Do these hypotheses make sense given what you know about the bug?"
- Allow user to add context that could refine hypotheses

### 5.3 Save hypotheses

Write to: `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`

### 5.4 Update state file

Mark Phase 3 complete. Update hypotheses status (all PENDING). Update current phase to Phase 4.

---

## STEP 6: PHASE 4 - INSTRUMENT (Add Targeted Logging)

### 6.1 Add instrumentation

Use the Task tool with `subagent_type: "dev-workflow:instrumenter"` to add targeted logging.

Provide the agent with:
- Hypotheses from `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`
- Relevant file paths from exploration

### 6.2 Verify instrumentation

After the agent adds logs, verify:
- Every log is tagged with hypothesis ID (`[DEBUG-H1]`, `[DEBUG-H2]`, etc.)
- Every log has cleanup markers (`DEBUG: Remove after fix`)
- Logs are at decision points, not every line
- No behavior changes introduced

### 6.3 Update state file

Mark Phase 4 complete. Update current phase to Phase 5.

---

## STEP 7: PHASE 5 - REPRODUCE (User Triggers Bug)

**HUMAN GATE**: The user must trigger the bug with instrumentation active.

### 7.1 Provide reproduction instructions

Give the user clear instructions:

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

### 7.2 Collect log output

Wait for the user to share log output. If the user cannot reproduce:
- Suggest conditional instrumentation for specific triggers
- Suggest enabling persistent logging
- Consider adding metrics/counters

### 7.3 Update state file

Mark Phase 5 complete. Update current phase to Phase 6.

---

## STEP 8: PHASE 6 - ANALYZE (Match Logs to Hypotheses)

### 8.1 Analyze logs

Use the Task tool with `subagent_type: "dev-workflow:log-analyzer"` to analyze the log output.

Provide the agent with:
- The log output from the user
- Hypotheses from `docs/debug/$ARGUMENTS/$ARGUMENTS-hypotheses.md`

### 8.2 Save analysis

Write to: `docs/debug/$ARGUMENTS/$ARGUMENTS-analysis.md`

### 8.3 Handle analysis results

**If a hypothesis is CONFIRMED:**
- Update hypothesis status in state file
- Proceed to Phase 7 (Fix)

**If all hypotheses are REJECTED:**
- Update hypothesis statuses in state file
- Note unexpected findings from the logs
- Loop back to STEP 5 (Phase 3) to generate new hypotheses (H4, H5, etc.)
- Inform the user: "All initial hypotheses were rejected. The logs revealed [findings]. Generating new hypotheses."

**If INCONCLUSIVE:**
- Identify what additional instrumentation is needed
- Loop back to STEP 6 (Phase 4) to add more logs
- Inform the user: "Need more evidence. Adding additional instrumentation."

### 8.4 Update state file

Mark Phase 6 complete (if proceeding to fix). Update current phase.

---

## STEP 9: PHASE 7 - FIX (Minimal Code Change)

### 9.1 Explain root cause

Present the confirmed root cause to the user:

```markdown
## Root Cause Analysis

**The Bug**: [clear one-sentence description]
**Why It Happens**: [technical explanation]
**Key Evidence**: [critical log lines that prove this]
**The Fix**: [proposed code change]
**Why This Fixes It**: [how the fix addresses the root cause]
```

### 9.2 Apply the fix

Make the minimal code change to fix the bug. Keep instrumentation in place until verification.

### 9.3 Track fix attempt

Increment the fix attempt counter in the state file.

**3-FIX RULE**: If this is the 3rd failed attempt, STOP and ask the user:
"We've tried 3 fixes without success. This suggests the issue may be architectural rather than a simple bug. Should we step back and question our fundamental assumptions about the problem?"

### 9.4 Update state file

Mark Phase 7 complete. Update current phase to Phase 8.

---

## STEP 10: PHASE 8 - VERIFY (Confirm Fix)

**HUMAN GATE**: The user must verify the fix works.

### 10.1 Guide verification

Ask the user to:
1. Reproduce the original scenario
2. Observe the behavior
3. Report whether the bug is fixed

### 10.2 Run tests

Run relevant tests to check for regressions.

### 10.3 Write regression test

Write a regression test that would have caught this bug:
- Test should fail without the fix
- Test should pass with the fix
- Follow TDD principles

### 10.4 Handle verification result

**If fix confirmed:**
- Ask user via AskUserQuestionTool to confirm
- Proceed to Phase 9 (Clean)

**If fix failed:**
- Capture new log output
- Increment fix attempt counter
- Check 3-Fix Rule
- Loop back to STEP 8 (Phase 6) to re-analyze with new evidence

### 10.5 Update state file

Mark Phase 8 complete. Update current phase to Phase 9.

---

## STEP 11: PHASE 9 - CLEAN (Remove Instrumentation)

### 11.1 Remove debug instrumentation

Search for and remove all debug artifacts:
- Find all `DEBUG-H[0-9]` markers in source files
- Remove debug log statements
- Remove debug imports if no longer needed
- Remove temporary debug files

### 11.2 Verify cleanup

- Run tests to ensure cleanup didn't break anything
- Run linter if available

### 11.3 Commit

Commit the fix + regression test (NOT debug logs):

```bash
git add [fixed files] [new test file]
git commit -m "fix: [bug description]

Root cause: [brief explanation]
Added regression test to prevent recurrence."
```

### 11.4 Archive debug session

Write resolution summary to `docs/debug/$ARGUMENTS/$ARGUMENTS-resolution.md`:

```markdown
# Debug Resolution: $ARGUMENTS

## Bug
[description]

## Root Cause
[explanation]

## Fix Applied
[what was changed]

## Verification
[how it was confirmed]

## Regression Test
[test file and description]

## Lessons Learned
[anything to add to CLAUDE.md or document for future reference]
```

### 11.5 Consider CLAUDE.md update

If this bug reveals a recurring pattern, suggest adding a gotcha to the project's CLAUDE.md:

```markdown
## Gotchas
- [Pattern that caused this bug and how to avoid it]
```

### 11.6 Update state file

Mark Phase 9 complete. Mark workflow as COMPLETE.

---

## KEY PRINCIPLES

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Hypothesis-first**: Never fix without understanding root cause
2. **Evidence-driven**: Let logs decide verdicts, not intuition
3. **Minimal changes**: Fix the bug, don't refactor the world
4. **Verify always**: Confirm fix by reproducing original scenario
5. **Clean up**: Never commit debug code
6. **3-Fix Rule**: After 3 failed fixes, question the architecture

## HELP

- `/dev-workflow:help` - Show all workflow commands
- `/dev-workflow:continue-workflow <bug-name>` - Resume an in-progress debug session
