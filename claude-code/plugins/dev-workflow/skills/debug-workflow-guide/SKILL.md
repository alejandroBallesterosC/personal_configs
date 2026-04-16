---
name: debug-workflow-guide
description: Source of truth for the debug workflow (9 phases - explore, describe, hypothesize, instrument, reproduce, analyze, fix, verify, clean). Use when starting, navigating, or continuing a debug session, understanding debug phase transitions, checking debug state file format, managing context after /compact or /clear, or asking about debug workflow commands, agents, human gates, or loopback flows.
---

# Debug Workflow Guide Skill

This skill provides **navigation guidance** for the debug workflow plugin's 9 phases. Based on practices from Boris Cherny (Claude Code creator), Cursor's Debug Mode, Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

**Important:** This skill is the **source of truth** for understanding the workflow (overview, principles, context management, state file format). The command files (`1-start-debug.md`, `2-explore-debug.md`, etc.) contain the **execution instructions** only.

## When to Activate

Activate when:
- User asks about the debug workflow process
- User seems lost in the debugging workflow
- Navigating between debug phases
- User needs help understanding debug phases

**Note:** When executing the workflow via `/dev-workflow:1-start-debug`, follow the instructions in that command directly - this skill is supplementary guidance.

**Announce at start:** "I'm using the debug-workflow-guide skill to help navigate this workflow."


## Workflow Overview (9 Phases)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: EXPLORE - /2-explore-debug                                        │
│   File Discovery │ Execution Flow │ Dependencies │ Git History │ Tests     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: DESCRIBE - (main instance, user input)                            │
│   Expected vs Actual │ Reproduction │ Timing │ Environment │ Errors       │
│   HUMAN GATE: User provides bug context via AskUserQuestionTool            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: HYPOTHESIZE - /4-hypothesize                                      │
│   Generate 3-5 ranked theories │ Evidence needed │ Instrumentation plan    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: INSTRUMENT - /5-instrument                                        │
│   Tagged logging ([DEBUG-H1]) │ Cleanup markers │ Decision points          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: REPRODUCE - (main instance, user action)                          │
│   Provide reproduction steps │ Specify log capture │ Explain markers       │
│   HUMAN GATE: User triggers bug, captures logs, shares output              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: ANALYZE - /7-analyze                                              │
│   Match logs to hypotheses │ CONFIRMED/REJECTED/INCONCLUSIVE verdicts      │
│   If all rejected → loop back to Phase 4 with new findings                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: FIX - (main instance)                                             │
│   Root cause explanation │ Minimal code change │ Keep instrumentation       │
│   3-FIX RULE: After 3 failed fixes, STOP and question architecture         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 9: VERIFY - /9-verify                                                │
│   Reproduce original scenario │ Run tests │ Write regression test          │
│   HUMAN GATE: User confirms bug is fixed                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 10: CLEAN - /9-verify (continued)                                    │
│   Remove DEBUG markers │ Remove debug imports │ Run tests │ Commit         │
│   Archive debug artifacts                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

Context is managed automatically via hooks - no manual checkpoints needed.
```


## The Iron Laws

> **NO FIXES WITHOUT ROOT CAUSE PROVEN FIRST**

If you catch yourself thinking any of these, STOP and return to Phase 3:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "It's probably X, let me fix that"

> **QUESTION THE FRAMING BEFORE QUESTIONING THE CODE**

If you catch yourself thinking any of these, STOP and re-evaluate whether you're debugging the right thing:
- "All my hypotheses were wrong, let me try more of the same"
- "The logs don't show what I expected, the instrumentation must be wrong"
- "This doesn't make sense" (this is your signal that the framing may be wrong)
- "Let me just add more logging everywhere" (shotgun debugging = lost framing)

## The 3-Fix Rule

Track failed fix attempts in the state file. If 3+ fixes have failed:
1. **STOP** - Do not attempt fix #4
2. **Question the architecture** - The problem may be structural, not implementation
3. **Ask the user** - "We've tried 3 fixes. Should we question our approach entirely?"
4. **Consider**: Are we debugging the wrong thing? Is the architecture itself flawed?


## Automatic Context Management

### How It Works

Context and verification are managed via three hooks (same system as TDD implementation workflow):

1. **Stop hook - Test runner** (command): Runs scoped tests if a `.tdd-test-scope` file exists. Active during Phases 8-10 when Claude writes the scope file for verification. No-op during investigation phases (2-7).
2. **SessionStart hook** (command): After context reset (`/compact` or `/clear`), reads the state file and injects full context for seamless resume.

**The key insight**: The main Claude instance is responsible for keeping `.plugin-state/debug/<bug-name>/<bug-name>-state.md` current. The command prompts instruct Claude to update the state file after each phase transition.

### Test Scope File

The `.tdd-test-scope` file (shared contract with the TDD implementation workflow) controls which tests the Stop hook runs. Claude writes this file to the **repository root** when it needs test verification:

- During Phase 9 (VERIFY): Run the regression test
- During Phase 10 (CLEAN): Confirm cleanup didn't break tests
- During investigation phases (2-7): File doesn't exist, hook is a no-op

See the `testing` skill for `.tdd-test-scope` format details.

### State File Verification Criteria

The Stop hook verifies the state file against these criteria:
- **Phase accuracy**: Current phase matches actual work done
- **Hypothesis status accuracy**: Hypothesis verdicts are current
- **Next action accuracy**: Next action reflects what should actually be done
- **No stale progress**: Session progress doesn't describe work from a previous session
- **Fix attempt count**: Failed fix attempts are accurately tracked

### What Happens After Context Reset

After `/compact` or `/clear`:
1. **SessionStart hook** detects active debug session from `.plugin-state/debug/*/<bug-name>-state.md`
2. Reads the entire state file and injects it into context
3. Lists all relevant artifact files to read
4. Claude continues the debug workflow automatically

### Manual Continuation

For fresh sessions (not triggered by compaction/clear):
```bash
/dev-workflow:continue-workflow <bug-name>
```

No specific phase or "checkpoint" required - works at any point in the workflow.

---

## Phase Details

**Note:** These summaries explain what each phase does. For **execution instructions**, see the individual phase commands (`2-explore-debug.md`, `4-hypothesize.md`, etc.). The `1-start-debug.md` command orchestrates all phases in sequence.

### Phase 2: EXPLORE
**Purpose**: Understand the relevant systems before debugging begins

**What happens**:
- debug-explorer agent investigates the codebase
- Maps execution flow from entry to failure
- Analyzes dependencies and recent git changes
- Identifies test coverage gaps

**Output**: `.plugin-state/debug/<bug-name>/<bug-name>-exploration.md`

**Command**: `/dev-workflow:2-explore-debug <bug description>`

---

### Phase 3: DESCRIBE
**Purpose**: Gather complete bug context from the user

**What happens**:
- Ask clarifying questions via AskUserQuestionTool
- Cover: expected vs actual, reproduction steps, timing, environment, errors
- Document all findings

**Output**: `.plugin-state/debug/<bug-name>/<bug-name>-bug.md`

**Human gate**: User provides essential bug context

---

### Phase 4: HYPOTHESIZE
**Purpose**: Assess debugging framing, then generate testable theories about root cause

**What happens**:
- hypothesis-generator agent first performs a **framing assessment**:
  - Is the reported bug the actual problem, or a downstream symptom?
  - Could this be an architectural/design issue rather than an implementation bug?
  - Is the "expected behavior" actually correct per the specification?
- Then produces 3-5 ranked theories (at least one must be structural/architectural)
- Each includes: theory, evidence needed, confidence, instrumentation plan, **disconfirming evidence**
- Prioritized by likelihood and testability

**Key addition**: The framing assessment catches the case where we're debugging the wrong thing entirely. If framing confidence is LOW, the workflow should pause for user input before proceeding.

**Output**: `.plugin-state/debug/<bug-name>/<bug-name>-hypotheses.md`

**Command**: `/dev-workflow:4-hypothesize <bug-name>`

---

### Phase 5: INSTRUMENT
**Purpose**: Add surgical logging to test hypotheses

**What happens**:
- instrumenter agent adds targeted logs
- Every log tagged with hypothesis ID (`[DEBUG-H1]`)
- Every log marked for cleanup (`DEBUG: Remove after fix`)
- Logs at decision points, not every line

**Output**: Modified source files with instrumentation

**Command**: `/dev-workflow:5-instrument <bug-name>`

---

### Phase 6: REPRODUCE
**Purpose**: User triggers the bug with instrumentation in place

**What happens**:
- Clear reproduction instructions provided
- User runs application and triggers the bug
- Debug output is captured automatically to `logs/debug-output.log` (overwritten on each run)
- User confirms reproduction, Claude reads the log file directly

**Human gate**: User reproduces bug and confirms it's done

---

### Phase 7: ANALYZE
**Purpose**: Match log output against hypotheses to determine root cause

**What happens**:
- Claude reads `logs/debug-output.log` from the repository root
- log-analyzer agent extracts debug markers and matches to hypotheses
- Each hypothesis evaluated: CONFIRMED / REJECTED / INCONCLUSIVE
- If CONFIRMED → proceed to Phase 8
- If all REJECTED → loop back to Phase 4 with new findings
- If INCONCLUSIVE → add more instrumentation and loop back to Phase 6

**Output**: `.plugin-state/debug/<bug-name>/<bug-name>-analysis.md`

**Command**: `/dev-workflow:7-analyze <bug-name>`

---

### Phase 8: FIX
**Purpose**: Apply minimal code change to address confirmed root cause

**What happens**:
- Explain root cause clearly to user
- Propose minimal fix (not a refactor)
- Keep instrumentation until verified
- Track fix attempts in state file

**3-Fix Rule**: After 3 failed attempts, STOP and question architecture

---

### Phase 9: VERIFY
**Purpose**: Confirm the fix works

**What happens**:
- Reproduce original scenario
- Check for regressions
- Write regression test (TDD approach)

**Human gate**: User confirms bug is fixed

**Command**: `/dev-workflow:9-verify <bug-name>`

---

### Phase 10: CLEAN
**Purpose**: Remove all debug instrumentation and finalize

**What happens**:
- Remove all `[DEBUG-Hx]` log statements
- Remove debug imports
- Run tests to ensure cleanup didn't break anything
- Commit fix + regression test (not debug logs)
- Archive debug artifacts

**Note**: CLEAN runs as the second stage of `/dev-workflow:9-verify` after user confirmation at the Phase 9 gate. It is not a separate command — the `9-verify` command handles both verification and cleanup in sequence.

---


## Commands Reference

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-debug <bug>` | Start full orchestrated debug workflow |
| `/dev-workflow:2-explore-debug <area>` | Phase 2: Explore codebase for context |
| `/dev-workflow:4-hypothesize <bug-name>` | Phase 4: Generate ranked hypotheses |
| `/dev-workflow:5-instrument <bug-name>` | Phase 5: Add targeted instrumentation |
| `/dev-workflow:7-analyze <bug-name>` | Phase 7: Analyze logs against hypotheses |
| `/dev-workflow:9-verify <bug-name>` | Phases 9-10: Verify fix and cleanup |
| `/dev-workflow:continue-workflow <bug-name>` | **Continue an in-progress debug session** |
| `/dev-workflow:help` | Show help |


## Agents by Phase

| Phase | Agent Used | How to Invoke |
|-------|------------|---------------|
| Phase 2: Explore | `debug-explorer` | `Task tool with subagent_type: "dev-workflow:debug-explorer"` |
| Phase 3: Describe | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 4: Hypothesize | `hypothesis-generator` | `Task tool with subagent_type: "dev-workflow:hypothesis-generator"` |
| Phase 5: Instrument | `instrumenter` | `Task tool with subagent_type: "dev-workflow:instrumenter"` |
| Phase 6: Reproduce | None (user action) | User triggers bug |
| Phase 7: Analyze | `log-analyzer` | `Task tool with subagent_type: "dev-workflow:log-analyzer"` |
| Phase 8: Fix | None (main instance) | Main instance applies fix |
| Phase 9: Verify | None (main instance) | Main instance + user verification |
| Phase 10: Clean | None (main instance) | Main instance cleans up |


## Human Verification Gates

Three explicit gates where the workflow pauses for human input:

1. **Phase 3 (DESCRIBE)**: User provides bug context - expected behavior, reproduction steps, error messages
2. **Phase 6 (REPRODUCE)**: User triggers the bug with instrumentation active, captures and shares log output
3. **Phase 9 (VERIFY)**: User confirms the bug is fixed by reproducing the original scenario

At each gate, use AskUserQuestionTool to collect input and confirm readiness to proceed.


## Loopback Flows

The workflow is not always linear. Two loopback flows exist:

### Hypotheses Rejected Loop
```
Phase 7 (all REJECTED) → Framing Re-evaluation → Phase 4 (new hypotheses) → Phase 5 → Phase 6 → Phase 7
```
When all hypotheses are rejected:
1. **Re-evaluate the framing**: Before generating new hypotheses, explicitly ask:
   - Are we debugging the right thing? The fact that all hypotheses were rejected may mean we're looking in the wrong place.
   - Should we re-examine the bug description with the user? The original report may be misleading.
   - Is this a symptom of a deeper architectural issue?
2. If framing seems suspect, pause for user input via AskUserQuestionTool before generating new hypotheses.
3. Generate new hypotheses (H4, H5, etc.) with findings from the rejected analysis AND the framing re-evaluation.

### Fix Failed Loop
```
Phase 9 (fix failed) → Phase 7 (re-analyze with new evidence) → Phase 8 (refined fix)
```
When a fix doesn't work, capture new log output and re-analyze. The 3-Fix Rule applies across all iterations.


## Key Principles

1. **Hypothesis-first** - Never fix without understanding root cause
2. **Evidence-driven** - Let logs decide verdicts, not intuition
3. **Minimal changes** - Fix the bug, don't refactor the world
4. **Verify always** - Confirm fix by reproducing original scenario
5. **Clean up** - Never commit debug code
6. **Automatic context management** - Stop hook enforces state file accuracy, SessionStart hook restores context after reset
7. **Human in the loop** - Three verification gates ensure alignment between Claude and user

---

## State File Format

All progress is tracked in `.plugin-state/debug/<bug-name>/<bug-name>-state.md`:

```markdown
---
workflow_type: debug
name: <bug-name>
status: in_progress
current_phase: "Phase [N]: [Phase Name]"
fix_attempts: 0
max_fix_attempts: 3
---

# Debug Session State: <bug-name>

## Current Phase
Phase [N]: [Phase Name]

## Bug
- **Name**: <bug-name>
- **Description**: <description>

## Completed Phases
- [ ] Phase 2: Explore
- [ ] Phase 3: Describe
- [ ] Phase 4: Hypothesize
- [ ] Phase 5: Instrument
- [ ] Phase 6: Reproduce
- [ ] Phase 7: Analyze
- [ ] Phase 8: Fix
- [ ] Phase 9: Verify
- [ ] Phase 10: Clean

## Hypotheses Status
- H1: [summary] - PENDING / CONFIRMED / REJECTED / INCONCLUSIVE
- H2: [summary] - PENDING / CONFIRMED / REJECTED / INCONCLUSIVE
- H3: [summary] - PENDING / CONFIRMED / REJECTED / INCONCLUSIVE

## Failed Fix Attempts
Count: 0/3

## Key Findings
- [Finding 1]
- [Finding 2]

## Session Progress (Auto-saved)
- **Phase**: [current phase]
- **Hypothesis**: [if applicable, which hypothesis is being tested]
- **Next Action**: [specific next step]

## Context Restoration Files
Read these files to restore context:
1. Use the debug-workflow-guide skill if needed
2. .plugin-state/debug/<bug-name>/<bug-name>-state.md (this file)
3. .plugin-state/debug/<bug-name>/<bug-name>-bug.md
4. .plugin-state/debug/<bug-name>/<bug-name>-exploration.md
5. .plugin-state/debug/<bug-name>/<bug-name>-hypotheses.md
6. .plugin-state/debug/<bug-name>/<bug-name>-analysis.md
7. CLAUDE.md
```

---

## Artifacts Created

All artifacts for a debug session are stored in `.plugin-state/debug/<bug-name>/`:

```
.plugin-state/debug/<bug-name>/
├── <bug-name>-state.md          # Session state (auto-managed by hooks)
├── <bug-name>-bug.md            # Bug description and reproduction steps
├── <bug-name>-exploration.md    # Codebase exploration findings
├── <bug-name>-hypotheses.md     # Ranked hypotheses
├── <bug-name>-analysis.md       # Log analysis results
└── <bug-name>-resolution.md     # Final resolution summary
```

Completed sessions are archived to `.plugin-state/archive/debug-<bug-name>/`.

---

## Learnings System

- **Storage**: `~/.claude/plugin-learnings/dev-workflow/` (standalone Markdown files)
- **Override**: Set custom path via `learnings_dir` in `.plugin-state/dev-workflow.local.md` YAML frontmatter
- **Automatic write**: A holistic completion retrospective (`debug-completion`) is written when the debug session completes (after CLAUDE.md Gotchas update, step 11.5b)
- **Manual feedback**: `/dev-workflow:record-feedback <workflow-name>` records user feedback with artifact metrics
- **Review**: `/dev-workflow:review-learnings` synthesizes all accumulated learnings across TDD and debug sessions
- Learnings persist across sessions and projects. Only `review-learnings` reads them — they are write-only during workflow execution.

## Integration with TDD Workflow

If a debug session is initiated from a TDD implementation workflow:

```
TDD Phase 7 (tests fail unexpectedly)
  -> /dev-workflow:1-start-debug "test failure description"
  → Debug workflow completes
  → Return to TDD with: /dev-workflow:continue-workflow <feature>
```

After fixing a bug, the VERIFY phase writes a regression test following TDD principles:
1. Write test that catches the bug (should fail without fix)
2. Confirm test passes with fix applied
3. Commit test + fix together

---

## Key Quotes

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

> "AI doesn't fail because it's not smart enough. It fails because it can't see what you see." - Nathan Onn

> "The difference between Claude guessing for 20 minutes and Claude solving it instantly was 30 seconds of logging." - Nathan Onn

> "If you catch yourself thinking 'quick fix for now, investigate later' - STOP. Return to investigation." - Systematic Debugging Skill
