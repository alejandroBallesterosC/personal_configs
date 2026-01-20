---
description: Show debug workflow plugin help
model: haiku
---

# Debug Workflow Plugin Help

A systematic, hypothesis-driven debugging workflow inspired by Cursor's Debug Mode and practices from Boris Cherny (Claude Code creator) and Anthropic's engineering team.

## Commands

| Command | Purpose | Usage |
|---------|---------|-------|
| `/debug-workflow:debug` | Start full debug workflow | `/debug-workflow:debug <bug description>` |
| `/debug-workflow:explore` | Explore codebase for context | `/debug-workflow:explore <area>` |
| `/debug-workflow:hypothesize` | Generate hypotheses for bug | `/debug-workflow:hypothesize [bug-name]` |
| `/debug-workflow:instrument` | Add debug logging | `/debug-workflow:instrument [bug-name]` |
| `/debug-workflow:analyze` | Analyze log output | `/debug-workflow:analyze [bug-name]` |
| `/debug-workflow:verify` | Verify fix and cleanup | `/debug-workflow:verify [bug-name]` |
| `/debug-workflow:help` | Show this help | `/debug-workflow:help` |

## Workflow Overview

```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

### 1. EXPLORE
Understand the relevant systems before debugging. Map execution flow, check recent changes, identify test coverage gaps.

### 2. DESCRIBE
Gather complete bug context: expected vs actual behavior, reproduction steps, error messages, environment conditions.

### 3. HYPOTHESIZE
Generate 3-5 ranked hypotheses about root cause. Each must be specific, testable, and have an instrumentation plan.

### 4. INSTRUMENT
Add targeted logging to test hypotheses. Tag all logs with hypothesis ID (`[DEBUG-H1]`) for easy analysis and cleanup.

### 5. REPRODUCE
User triggers the bug with instrumentation in place. Capture log output for analysis.

### 6. ANALYZE
Match log output against hypotheses. Determine which is CONFIRMED, REJECTED, or INCONCLUSIVE.

### 7. FIX
Once root cause is confirmed, propose minimal fix. Keep instrumentation until verified.

### 8. VERIFY
Confirm the fix works by reproducing original scenario. Check for regressions.

### 9. CLEAN
Remove all debug instrumentation. Commit fix (not debug logs).

## Agents

| Agent | Purpose |
|-------|---------|
| `debug-explorer` | Explore codebase for bug context |
| `hypothesis-generator` | Generate ranked hypotheses |
| `instrumenter` | Add targeted debug logging |
| `log-analyzer` | Analyze logs against hypotheses |

## Skills

| Skill | Activates When |
|-------|----------------|
| `structured-debug` | Debugging errors, investigating bugs, unexpected behavior |

## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Hypothesis-first**: Never fix without understanding
2. **Evidence-driven**: Let logs decide, not intuition
3. **Minimal changes**: Fix the bug, don't refactor
4. **Verify always**: Confirm fix with reproduction
5. **Clean up**: Never commit debug code

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
```

## Output Files

Debug artifacts are written to `docs/debug/`:

```
docs/debug/
├── <bug-name>-exploration.md   # Codebase exploration findings
├── <bug-name>-bug.md           # Bug description and repro steps
├── <bug-name>-hypotheses.md    # Ranked hypotheses
└── archive/                    # Completed debug sessions
```

## Related

- Based on Cursor's Debug Mode approach
- Integrates with TDD workflow for regression tests
- Follows Anthropic's recommended debugging practices
