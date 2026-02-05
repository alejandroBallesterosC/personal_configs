---
description: Show debug workflow plugin help
model: haiku
---

# Debug Workflow Plugin Help

A systematic, hypothesis-driven debugging workflow for Claude Code. Based on Cursor's Debug Mode, practices from Boris Cherny (Claude Code creator), Anthropic's engineering team, and the @obra/superpowers systematic debugging skill.

## Commands

| Command | Purpose | Usage |
|---------|---------|-------|
| `/debug-workflow:debug` | Start full debug workflow | `/debug-workflow:debug <bug description>` |
| `/debug-workflow:explore` | Phase 1: Explore codebase for context | `/debug-workflow:explore <area>` |
| `/debug-workflow:hypothesize` | Phase 3: Generate hypotheses for bug | `/debug-workflow:hypothesize <bug-name>` |
| `/debug-workflow:instrument` | Phase 4: Add debug logging | `/debug-workflow:instrument <bug-name>` |
| `/debug-workflow:analyze` | Phase 6: Analyze log output | `/debug-workflow:analyze <bug-name>` |
| `/debug-workflow:verify` | Phases 8-9: Verify fix and cleanup | `/debug-workflow:verify <bug-name>` |
| `/debug-workflow:continue-workflow` | Resume in-progress session | `/debug-workflow:continue-workflow <bug-name>` |
| `/debug-workflow:help` | Show this help | `/debug-workflow:help` |

## Workflow Overview (9 Phases)

```
EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> VERIFY -> CLEAN
```

### Phase 1: EXPLORE
Understand the relevant systems before debugging. Map execution flow, check recent changes, identify test coverage gaps.

### Phase 2: DESCRIBE
Gather complete bug context: expected vs actual behavior, reproduction steps, error messages, environment conditions.
**Human gate**: User provides bug context.

### Phase 3: HYPOTHESIZE
Generate 3-5 ranked hypotheses about root cause. Each must be specific, testable, and have an instrumentation plan.

### Phase 4: INSTRUMENT
Add targeted logging to test hypotheses. Tag all logs with hypothesis ID (`[DEBUG-H1]`) for easy analysis and cleanup.

### Phase 5: REPRODUCE
User triggers the bug with instrumentation in place. Capture log output for analysis.
**Human gate**: User reproduces bug and shares logs.

### Phase 6: ANALYZE
Match log output against hypotheses. Determine which is CONFIRMED, REJECTED, or INCONCLUSIVE.
If all rejected, loop back to Phase 3 with new findings.

### Phase 7: FIX
Once root cause is confirmed, propose minimal fix. Keep instrumentation until verified.
**3-Fix Rule**: After 3 failed attempts, question the architecture.

### Phase 8: VERIFY
Confirm the fix works by reproducing original scenario. Write regression test. Check for regressions.
**Human gate**: User confirms fix.

### Phase 9: CLEAN
Remove all debug instrumentation. Commit fix (not debug logs). Archive debug artifacts.

## Agents

| Agent | Purpose |
|-------|---------|
| `debug-explorer` | Explore codebase for bug context |
| `hypothesis-generator` | Generate ranked hypotheses |
| `instrumenter` | Add targeted debug logging |
| `log-analyzer` | Analyze logs against hypotheses |

## Skills

| Skill | Purpose |
|-------|---------|
| `debug-workflow-guide` | Source of truth for workflow navigation, phases, state file format, and context management |
| `structured-debug` | Debugging methodology: instrumentation patterns, anti-patterns, advanced techniques |

## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Hypothesis-first**: Never fix without understanding root cause
2. **Evidence-driven**: Let logs decide, not intuition
3. **Minimal changes**: Fix the bug, don't refactor
4. **Verify always**: Confirm fix with reproduction
5. **Clean up**: Never commit debug code
6. **3-Fix Rule**: After 3 failed fixes, question the architecture
7. **Human in the loop**: Three verification gates at Phases 2, 5, and 8

## Context Management

Debug sessions persist across context resets:
- **Stop hook**: Verifies state file is up to date before Claude stops
- **SessionStart hook**: Restores context after `/compact` or `/clear`
- **Manual resume**: `/debug-workflow:continue-workflow <bug-name>`

## Quick Start

```bash
# Start debugging a bug
/debug-workflow:debug "Login fails with 500 error for users with special characters in email"

# Or step through manually
/debug-workflow:explore authentication
/debug-workflow:hypothesize login-bug
/debug-workflow:instrument login-bug
# [user reproduces and shares logs]
/debug-workflow:analyze login-bug
/debug-workflow:verify login-bug

# Resume after context reset
/debug-workflow:continue-workflow login-bug
```

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

## Related

- Integrates with TDD workflow for regression tests
- Based on Cursor's Debug Mode approach
- Follows Anthropic's recommended debugging practices
