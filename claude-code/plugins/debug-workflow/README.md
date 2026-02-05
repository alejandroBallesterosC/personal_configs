# Debug Workflow Plugin

A systematic, hypothesis-driven debugging workflow for Claude Code. Based on Cursor's Debug Mode, practices from Boris Cherny (Claude Code creator), Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

## Overview

This plugin transforms debugging from guesswork into a systematic 9-phase process:

1. **Explore** the codebase to understand relevant systems
2. **Describe** the bug with complete context (human gate)
3. **Hypothesize** about root causes (3-5 theories)
4. **Instrument** code with targeted logging
5. **Reproduce** the bug and capture logs (human gate)
6. **Analyze** logs against hypotheses
7. **Fix** with minimal changes (3-Fix Rule)
8. **Verify** the fix works (human gate)
9. **Clean** up debug instrumentation

## Quick Start

```bash
# Start full debug workflow
/debug-workflow:debug "API returns 500 error when user has emoji in name"

# Or use individual commands
/debug-workflow:explore user-api
/debug-workflow:hypothesize emoji-bug
/debug-workflow:instrument emoji-bug
# [user reproduces and shares logs]
/debug-workflow:analyze emoji-bug
/debug-workflow:verify emoji-bug

# Resume after context reset
/debug-workflow:continue-workflow emoji-bug
```

## Commands

| Command | Description |
|---------|-------------|
| `/debug-workflow:debug <bug>` | Start full debug workflow |
| `/debug-workflow:explore <area>` | Phase 1: Explore codebase for context |
| `/debug-workflow:hypothesize <name>` | Phase 3: Generate ranked hypotheses |
| `/debug-workflow:instrument <name>` | Phase 4: Add debug logging |
| `/debug-workflow:analyze <name>` | Phase 6: Analyze log output |
| `/debug-workflow:verify <name>` | Phases 8-9: Verify fix and cleanup |
| `/debug-workflow:continue-workflow <name>` | Resume in-progress session |
| `/debug-workflow:help` | Show help |

## Agents

| Agent | Purpose |
|-------|---------|
| `debug-explorer` | Codebase exploration and context gathering |
| `hypothesis-generator` | Generate testable theories about root cause |
| `instrumenter` | Add surgical debug logging |
| `log-analyzer` | Match logs to hypotheses |

## Skills

| Skill | Description |
|-------|-------------|
| `debug-workflow-guide` | Source of truth for the workflow. Covers phases, context management, state file format, and navigation guidance. |
| `structured-debug` | Debugging methodology: instrumentation patterns, anti-patterns, advanced techniques. Activates automatically when debugging. |

## Key Principles

Based on insights from Boris Cherny, Anthropic engineering, and Cursor's Debug Mode:

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Hypothesis-first**: Never fix without understanding root cause
2. **Evidence-driven**: Let logs decide, not intuition
3. **Minimal changes**: Fix the bug, don't refactor the world
4. **Verify always**: Confirm fix by reproducing original scenario
5. **Clean up**: Never commit debug code
6. **3-Fix Rule**: After 3 failed fixes, question the architecture
7. **Human in the loop**: Three verification gates at Phases 2, 5, and 8

## Instrumentation Pattern

All debug logs follow this pattern:

```python
# HYPOTHESIS: H1 - User object is null when accessed
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] user={user}, user_id={user_id}")
```

This enables:
- Easy identification in log output
- Clear mapping to hypotheses
- Simple cleanup after debugging

## Hooks

Debug sessions use 3 hooks for automatic context management and test verification:

| Hook | Type | Event | Purpose |
|------|------|-------|---------|
| `run-scoped-tests.sh` | command | Stop | Runs tests if `.tdd-test-scope` exists (Phases 7-9 only) |
| State verifier | agent | Stop | Verifies state file is up to date; blocks stopping if stale |
| `auto-resume-after-compact-or-clear.sh` | command | SessionStart | Restores full context after `/compact` or `/clear` |

- **Manual resume**: `/debug-workflow:continue-workflow <bug-name>`

The state file at `docs/debug/<bug-name>/<bug-name>-state.md` tracks:
- Current phase
- Hypothesis verdicts (PENDING/CONFIRMED/REJECTED/INCONCLUSIVE)
- Failed fix attempt count
- Key findings
- Context restoration file list

## Output Files

Debug artifacts are stored in `docs/debug/<bug-name>/`:

```
docs/debug/<bug-name>/
├── <bug-name>-state.md          # Session state (auto-managed by hooks)
├── <bug-name>-bug.md            # Bug description and repro steps
├── <bug-name>-exploration.md    # Codebase exploration findings
├── <bug-name>-hypotheses.md     # Ranked hypotheses
├── <bug-name>-analysis.md       # Log analysis results
└── <bug-name>-resolution.md     # Final resolution summary
```

Completed sessions are archived to `docs/debug/archive/`.

## Human Verification Gates

Three explicit gates where the workflow pauses for human input:

1. **Phase 2 (DESCRIBE)**: User provides bug context
2. **Phase 5 (REPRODUCE)**: User triggers bug, captures and shares logs
3. **Phase 8 (VERIFY)**: User confirms bug is fixed

## The 3-Fix Rule

Track failed fix attempts in the state file. After 3 failed fixes:
1. STOP - Do not attempt fix #4
2. Question the architecture - the problem may be structural
3. Ask the user - "Should we question our fundamental approach?"

## Loopback Flows

The workflow is not always linear:

- **All hypotheses rejected**: Phase 6 loops back to Phase 3 with new findings
- **Fix failed**: Phase 8 loops back to Phase 6 for re-analysis
- **Inconclusive analysis**: Phase 6 loops back to Phase 4 for more instrumentation

## Integration with TDD

After fixing a bug:

1. Write a regression test that catches the bug
2. Ensure test fails without the fix
3. Apply fix, verify test passes
4. Commit both test and fix

## Philosophy

Traditional debugging often devolves into "try random things until it works." This plugin enforces the **Iron Law**: no fixes until root cause is proven.

The workflow mirrors how expert debuggers approach problems:
- Understand the system first
- Form multiple hypotheses
- Gather evidence systematically
- Let data drive conclusions

## Sources

- [Boris Cherny's Claude Code Workflow](https://howborisusesclaudecode.com/)
- [Anthropic Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Cursor Debug Mode](https://cursor.com/blog/debug-mode)
- [Systematic Debugging Skill (@obra/superpowers)](https://claude-plugins.dev/skills/@obra/superpowers/systematic-debugging)
- [Nathan Onn: Stop Arguing With Your AI](https://www.nathanonn.com/claude-code-debugging-visibility-methods/)
