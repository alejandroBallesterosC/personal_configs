---
name: debug-workflow-guide
description: Guide for using the debug workflow plugin. Activates when starting or navigating the debug workflow phases.
---

# Debug Workflow Guide Skill

This skill provides **navigation guidance** for the debug workflow plugin's 9 phases. Based on practices from Boris Cherny (Claude Code creator), Cursor's Debug Mode, Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

**Important:** This skill is the **source of truth** for understanding the workflow (overview, principles, context management, state file format). The command files (`debug.md`, `explore.md`, etc.) contain the **execution instructions** only.

## When to Activate

Activate when:
- User asks about the debug workflow process
- User seems lost in the debugging workflow
- Navigating between debug phases
- User needs help understanding debug phases

**Note:** When executing the workflow via `/debug-workflow:debug`, follow the instructions in that command directly - this skill is supplementary guidance.

**Announce at start:** "I'm using the debug-workflow-guide skill to help navigate this workflow."


## Workflow Overview (9 Phases)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: EXPLORE - /explore                                                │
│   File Discovery │ Execution Flow │ Dependencies │ Git History │ Tests     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: DESCRIBE - (main instance, user input)                            │
│   Expected vs Actual │ Reproduction │ Timing │ Environment │ Errors       │
│   HUMAN GATE: User provides bug context via AskUserQuestionTool            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: HYPOTHESIZE - /hypothesize                                        │
│   Generate 3-5 ranked theories │ Evidence needed │ Instrumentation plan    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: INSTRUMENT - /instrument                                          │
│   Tagged logging ([DEBUG-H1]) │ Cleanup markers │ Decision points          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: REPRODUCE - (main instance, user action)                          │
│   Provide reproduction steps │ Specify log capture │ Explain markers       │
│   HUMAN GATE: User triggers bug, captures logs, shares output              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: ANALYZE - /analyze                                                │
│   Match logs to hypotheses │ CONFIRMED/REJECTED/INCONCLUSIVE verdicts      │
│   If all rejected → loop back to Phase 3 with new findings                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: FIX - (main instance)                                             │
│   Root cause explanation │ Minimal code change │ Keep instrumentation       │
│   3-FIX RULE: After 3 failed fixes, STOP and question architecture         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: VERIFY - /verify                                                  │
│   Reproduce original scenario │ Run tests │ Write regression test          │
│   HUMAN GATE: User confirms bug is fixed                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 9: CLEAN - /verify (continued)                                       │
│   Remove DEBUG markers │ Remove debug imports │ Run tests │ Commit         │
│   Archive debug artifacts                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

Context is managed automatically via hooks - no manual checkpoints needed.
```


## The Iron Law

> **NO FIXES WITHOUT ROOT CAUSE PROVEN FIRST**

If you catch yourself thinking any of these, STOP and return to Phase 3:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "It's probably X, let me fix that"

## The 3-Fix Rule

Track failed fix attempts in the state file. If 3+ fixes have failed:
1. **STOP** - Do not attempt fix #4
2. **Question the architecture** - The problem may be structural, not implementation
3. **Ask the user** - "We've tried 3 fixes. Should we question our approach entirely?"
4. **Consider**: Are we debugging the wrong thing? Is the architecture itself flawed?


## Automatic Context Management

### How It Works

Context and verification are managed via three hooks (same system as TDD workflow):

1. **Stop hook - Test runner** (command): Runs scoped tests if a `.tdd-test-scope` file exists. Active during Phases 7-9 when Claude writes the scope file for verification. No-op during investigation phases (1-6).
2. **Stop hook - State verifier** (agent): Before Claude stops responding, verifies the state file is up to date. If outdated, blocks Claude from stopping until the state file is updated.
3. **SessionStart hook** (command): After context reset (`/compact` or `/clear`), reads the state file and injects full context for seamless resume.

**The key insight**: The main Claude instance is responsible for keeping `docs/debug/<bug-name>/<bug-name>-state.md` current. The Stop hook enforces this by blocking Claude from stopping if the state file is stale.

### Test Scope File

The `.tdd-test-scope` file (shared contract with the TDD workflow) controls which tests the Stop hook runs. Claude writes this file to the **repository root** when it needs test verification:

- During Phase 8 (VERIFY): Run the regression test
- During Phase 9 (CLEAN): Confirm cleanup didn't break tests
- During investigation phases (1-6): File doesn't exist, hook is a no-op

See the `testing` skill in the TDD workflow plugin for `.tdd-test-scope` format details.

### State File Verification Criteria

The Stop hook verifies the state file against these criteria:
- **Phase accuracy**: Current phase matches actual work done
- **Hypothesis status accuracy**: Hypothesis verdicts are current
- **Next action accuracy**: Next action reflects what should actually be done
- **No stale progress**: Session progress doesn't describe work from a previous session
- **Fix attempt count**: Failed fix attempts are accurately tracked

### What Happens After Context Reset

After `/compact` or `/clear`:
1. **SessionStart hook** detects active debug session from `docs/debug/*/<bug-name>-state.md`
2. Reads the entire state file and injects it into context
3. Lists all relevant artifact files to read
4. Claude continues the debug workflow automatically

### Manual Continuation

For fresh sessions (not triggered by compaction/clear):
```bash
/debug-workflow:continue-workflow <bug-name>
```

No specific phase or "checkpoint" required - works at any point in the workflow.

---

## Phase Details

**Note:** These summaries explain what each phase does. For **execution instructions**, see the individual phase commands (`explore.md`, `hypothesize.md`, etc.). The `debug.md` command orchestrates all phases in sequence.

### Phase 1: EXPLORE
**Purpose**: Understand the relevant systems before debugging begins

**What happens**:
- debug-explorer agent investigates the codebase
- Maps execution flow from entry to failure
- Analyzes dependencies and recent git changes
- Identifies test coverage gaps

**Output**: `docs/debug/<bug-name>/<bug-name>-exploration.md`

**Command**: `/debug-workflow:explore <bug description>`

---

### Phase 2: DESCRIBE
**Purpose**: Gather complete bug context from the user

**What happens**:
- Ask clarifying questions via AskUserQuestionTool
- Cover: expected vs actual, reproduction steps, timing, environment, errors
- Document all findings

**Output**: `docs/debug/<bug-name>/<bug-name>-bug.md`

**Human gate**: User provides essential bug context

---

### Phase 3: HYPOTHESIZE
**Purpose**: Generate testable theories about root cause

**What happens**:
- hypothesis-generator agent produces 3-5 ranked theories
- Each includes: theory, evidence needed, confidence, instrumentation plan
- Prioritized by likelihood and testability
- Shared instrumentation identified

**Output**: `docs/debug/<bug-name>/<bug-name>-hypotheses.md`

**Command**: `/debug-workflow:hypothesize <bug-name>`

---

### Phase 4: INSTRUMENT
**Purpose**: Add surgical logging to test hypotheses

**What happens**:
- instrumenter agent adds targeted logs
- Every log tagged with hypothesis ID (`[DEBUG-H1]`)
- Every log marked for cleanup (`DEBUG: Remove after fix`)
- Logs at decision points, not every line

**Output**: Modified source files with instrumentation

**Command**: `/debug-workflow:instrument <bug-name>`

---

### Phase 5: REPRODUCE
**Purpose**: User triggers the bug with instrumentation in place

**What happens**:
- Clear reproduction instructions provided
- Log markers explained
- User runs application and captures output

**Human gate**: User reproduces bug and shares log output

---

### Phase 6: ANALYZE
**Purpose**: Match log output against hypotheses to determine root cause

**What happens**:
- log-analyzer agent extracts debug markers
- Each hypothesis evaluated: CONFIRMED / REJECTED / INCONCLUSIVE
- If CONFIRMED → proceed to Phase 7
- If all REJECTED → loop back to Phase 3 with new findings
- If INCONCLUSIVE → add more instrumentation and loop back to Phase 5

**Output**: `docs/debug/<bug-name>/<bug-name>-analysis.md`

**Command**: `/debug-workflow:analyze <bug-name>`

---

### Phase 7: FIX
**Purpose**: Apply minimal code change to address confirmed root cause

**What happens**:
- Explain root cause clearly to user
- Propose minimal fix (not a refactor)
- Keep instrumentation until verified
- Track fix attempts in state file

**3-Fix Rule**: After 3 failed attempts, STOP and question architecture

---

### Phase 8: VERIFY
**Purpose**: Confirm the fix works

**What happens**:
- Reproduce original scenario
- Check for regressions
- Write regression test (TDD approach)

**Human gate**: User confirms bug is fixed

**Command**: `/debug-workflow:verify <bug-name>`

---

### Phase 9: CLEAN
**Purpose**: Remove all debug instrumentation and finalize

**What happens**:
- Remove all `[DEBUG-Hx]` log statements
- Remove debug imports
- Run tests to ensure cleanup didn't break anything
- Commit fix + regression test (not debug logs)
- Archive debug artifacts

**Command**: `/debug-workflow:verify <bug-name>` (continued)

---


## Commands Reference

| Command | Purpose |
|---------|---------|
| `/debug-workflow:debug <bug>` | Start full orchestrated debug workflow |
| `/debug-workflow:explore <area>` | Phase 1: Explore codebase for context |
| `/debug-workflow:hypothesize <bug-name>` | Phase 3: Generate ranked hypotheses |
| `/debug-workflow:instrument <bug-name>` | Phase 4: Add targeted instrumentation |
| `/debug-workflow:analyze <bug-name>` | Phase 6: Analyze logs against hypotheses |
| `/debug-workflow:verify <bug-name>` | Phases 8-9: Verify fix and cleanup |
| `/debug-workflow:continue-workflow <bug-name>` | **Continue an in-progress debug session** |
| `/debug-workflow:help` | Show help |


## Agents by Phase

| Phase | Agent Used | How to Invoke |
|-------|------------|---------------|
| Phase 1: Explore | `debug-explorer` | `Task tool with subagent_type: "debug-workflow:debug-explorer"` |
| Phase 2: Describe | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 3: Hypothesize | `hypothesis-generator` | `Task tool with subagent_type: "debug-workflow:hypothesis-generator"` |
| Phase 4: Instrument | `instrumenter` | `Task tool with subagent_type: "debug-workflow:instrumenter"` |
| Phase 5: Reproduce | None (user action) | User triggers bug |
| Phase 6: Analyze | `log-analyzer` | `Task tool with subagent_type: "debug-workflow:log-analyzer"` |
| Phase 7: Fix | None (main instance) | Main instance applies fix |
| Phase 8: Verify | None (main instance) | Main instance + user verification |
| Phase 9: Clean | None (main instance) | Main instance cleans up |


## Human Verification Gates

Three explicit gates where the workflow pauses for human input:

1. **Phase 2 (DESCRIBE)**: User provides bug context - expected behavior, reproduction steps, error messages
2. **Phase 5 (REPRODUCE)**: User triggers the bug with instrumentation active, captures and shares log output
3. **Phase 8 (VERIFY)**: User confirms the bug is fixed by reproducing the original scenario

At each gate, use AskUserQuestionTool to collect input and confirm readiness to proceed.


## Loopback Flows

The workflow is not always linear. Two loopback flows exist:

### Hypotheses Rejected Loop
```
Phase 6 (all REJECTED) → Phase 3 (new hypotheses from findings) → Phase 4 → Phase 5 → Phase 6
```
When all hypotheses are rejected, the log analysis reveals unexpected findings. Use these findings to generate new hypotheses (H4, H5, etc.) and repeat the cycle.

### Fix Failed Loop
```
Phase 8 (fix failed) → Phase 6 (re-analyze with new evidence) → Phase 7 (refined fix)
```
When a fix doesn't work, capture new log output and re-analyze. The 3-Fix Rule applies across all iterations.


## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

> "AI doesn't fail because it's not smart enough. It fails because it can't see what you see." - Nathan Onn

1. **Hypothesis-first** - Never fix without understanding root cause
2. **Evidence-driven** - Let logs decide verdicts, not intuition
3. **Minimal changes** - Fix the bug, don't refactor the world
4. **Verify always** - Confirm fix by reproducing original scenario
5. **Clean up** - Never commit debug code
6. **Automatic context management** - Stop hook enforces state file accuracy, SessionStart hook restores context after reset
7. **Human in the loop** - Three verification gates ensure alignment between Claude and user

---

## State File Format

All progress is tracked in `docs/debug/<bug-name>/<bug-name>-state.md`:

```markdown
# Debug Session State: <bug-name>

## Current Phase
Phase [N]: [Phase Name]

## Bug
- **Name**: <bug-name>
- **Description**: <description>

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
2. docs/debug/<bug-name>/<bug-name>-state.md (this file)
3. docs/debug/<bug-name>/<bug-name>-bug.md
4. docs/debug/<bug-name>/<bug-name>-exploration.md
5. docs/debug/<bug-name>/<bug-name>-hypotheses.md
6. docs/debug/<bug-name>/<bug-name>-analysis.md
7. CLAUDE.md
```

---

## Artifacts Created

All artifacts for a debug session are stored in `docs/debug/<bug-name>/`:

```
docs/debug/<bug-name>/
├── <bug-name>-state.md          # Session state (auto-managed by hooks)
├── <bug-name>-bug.md            # Bug description and reproduction steps
├── <bug-name>-exploration.md    # Codebase exploration findings
├── <bug-name>-hypotheses.md     # Ranked hypotheses
├── <bug-name>-analysis.md       # Log analysis results
└── <bug-name>-resolution.md     # Final resolution summary
```

Completed sessions are archived to `docs/debug/archive/`.

---

## Integration with TDD Workflow

If a debug session is initiated from a TDD workflow:

```
TDD Phase 7 (tests fail unexpectedly)
  → /debug-workflow:debug "test failure description"
  → Debug workflow completes
  → Return to TDD with: /tdd-workflow:continue-workflow <feature>
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
