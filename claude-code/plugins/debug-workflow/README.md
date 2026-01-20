# Debug Workflow Plugin

A systematic, hypothesis-driven debugging workflow for Claude Code. Inspired by Cursor's Debug Mode and practices from Boris Cherny (Claude Code creator) and Anthropic's engineering team.

## Overview

This plugin transforms debugging from guesswork into a systematic process:

1. **Explore** the codebase to understand relevant systems
2. **Describe** the bug with complete context
3. **Hypothesize** about root causes (3-5 theories)
4. **Instrument** code with targeted logging
5. **Reproduce** the bug and capture logs
6. **Analyze** logs against hypotheses
7. **Fix** with minimal changes
8. **Verify** the fix works
9. **Clean** up debug instrumentation

## Quick Start

```bash
# Start full debug workflow
/debug-workflow:debug "API returns 500 error when user has emoji in name"

# Or use individual commands
/debug-workflow:explore user-api
/debug-workflow:hypothesize emoji-bug
```

## Commands

| Command | Description |
|---------|-------------|
| `/debug-workflow:debug <bug>` | Start full debug workflow |
| `/debug-workflow:explore <area>` | Explore codebase for context |
| `/debug-workflow:hypothesize [name]` | Generate ranked hypotheses |
| `/debug-workflow:instrument [name]` | Add debug logging |
| `/debug-workflow:analyze [name]` | Analyze log output |
| `/debug-workflow:verify [name]` | Verify fix and cleanup |
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
| `structured-debug` | Activates automatically when debugging. Provides the full hypothesis-driven debugging methodology. |

## Key Principles

Based on insights from Boris Cherny and Anthropic engineering:

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."

1. **Hypothesis-first**: Never fix without understanding root cause
2. **Evidence-driven**: Let logs decide, not intuition
3. **Minimal changes**: Fix the bug, don't refactor the world
4. **Verify always**: Confirm fix by reproducing original scenario
5. **Clean up**: Never commit debug code

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

## Output Files

Debug artifacts are stored in `docs/debug/`:

```
docs/debug/
├── bug-name-exploration.md    # Codebase exploration
├── bug-name-bug.md            # Bug description
├── bug-name-hypotheses.md     # Ranked hypotheses
└── archive/                   # Completed sessions
```

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
- [Systematic Debugging Skill](https://claude-plugins.dev/skills/@liauw-media/CodeAssist/systematic-debugging)
- Cursor Debug Mode methodology
