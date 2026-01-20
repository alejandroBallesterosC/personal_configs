---
description: Start systematic hypothesis-driven debugging workflow
model: opus
argument-hint: <bug description or error message>
---

# Debug Workflow

Debugging: **$ARGUMENTS**

This command initiates a systematic, hypothesis-driven debugging workflow inspired by Cursor's Debug Mode and practices from Boris Cherny and Anthropic's engineering team.

## Workflow Overview

```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

## Phase 1: EXPLORE (Codebase Understanding)

Before debugging, I need to understand the relevant systems. Use the debug-explorer agent to:

1. **Identify relevant files** based on the bug description
2. **Map the execution flow** through affected components
3. **Understand dependencies** between modules
4. **Review recent changes** that might have introduced the bug

```
Task: Use the debug-explorer agent to explore the codebase for context on: $ARGUMENTS
```

## Phase 2: DESCRIBE (Gather Bug Context)

Collect complete information about the bug using AskUserQuestionTool:

### Questions to Ask

1. **Expected vs Actual**: What should happen? What happens instead?
2. **Reproduction**: What are the exact steps to trigger this?
3. **Timing**: When did this start? What changed recently?
4. **Environment**: What conditions trigger it? (user, data, config)
5. **Error Messages**: Exact error text, stack traces, log output

### Output

Write bug description to: `docs/debug/$ARGUMENTS-bug.md`

```markdown
# Bug Report: [title]

## Expected Behavior
[description]

## Actual Behavior
[description]

## Reproduction Steps
1. [step]
2. [step]

## Error Messages
```
[exact error output]
```

## Recent Changes
[git log of relevant files]

## Environment
- [relevant conditions]
```

## Phase 3: HYPOTHESIZE (Generate Theories)

Generate **3-5 hypotheses** ranked by likelihood. For each:

1. **Theory**: What you think is wrong
2. **Evidence needed**: What logs/data would confirm this
3. **Confidence**: High/Medium/Low
4. **How to test**: Specific instrumentation needed

Write hypotheses to: `docs/debug/$ARGUMENTS-hypotheses.md`

## Phase 4: INSTRUMENT (Add Targeted Logging)

Add surgical instrumentation to test hypotheses:

### Rules

1. **Tag every log** with hypothesis ID: `[DEBUG-H1]`, `[DEBUG-H2]`
2. **Mark for cleanup**: `// DEBUG: Remove after fix`
3. **Log at decision points**, not every line
4. **Include context**: Variable names AND values
5. **Use structured format** for complex data

### Instrumentation Locations

- Function entry/exit
- Conditional branches
- Loop iterations with state
- Error handling paths
- Return values

## Phase 5: REPRODUCE

Guide the user to reproduce the bug:

1. Provide exact commands to run
2. Specify which log output to capture
3. Explain what log markers to look for
4. Handle cases where user cannot reproduce

If reproduction is difficult:
- Add conditional instrumentation for specific users/data
- Enable persistent logging
- Consider adding metrics/counters

## Phase 6: ANALYZE

Match log output against hypotheses:

For each hypothesis:
- Extract relevant log lines
- Determine verdict: CONFIRMED / REJECTED / INCONCLUSIVE
- Explain reasoning

If all hypotheses rejected:
- Generate new hypotheses from log findings
- Add more instrumentation
- Repeat the loop

## Phase 7: FIX

Once root cause is identified:

1. **Explain clearly** to the user
2. **Propose minimal fix** - don't over-engineer
3. **Keep instrumentation** until verified
4. **Write regression test** (TDD approach)

## Phase 8: VERIFY

1. Apply the fix
2. Reproduce original scenario
3. Confirm expected behavior
4. Check for regressions
5. If not fixed, return to HYPOTHESIZE

## Phase 9: CLEAN

Remove all debug instrumentation:

```bash
# Find all debug logs
grep -rn "DEBUG-H[0-9]" --include="*.py" --include="*.js" --include="*.ts"
```

Cleanup checklist:
- Remove all `[DEBUG-Hx]` statements
- Remove debug imports
- Run tests
- Commit fix (not debug logs)

## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Hypothesis-first**: Never fix without understanding
2. **Evidence-driven**: Let logs decide, not intuition
3. **Minimal changes**: Fix the bug, don't refactor
4. **Verify always**: Confirm fix with reproduction
5. **Clean up**: Never commit debug code

## Related Commands

- `/debug-workflow:explore <area>` - Deep dive into specific code area
- `/debug-workflow:hypothesize` - Generate hypotheses for current bug
- `/debug-workflow:instrument` - Add instrumentation to test hypotheses
- `/debug-workflow:analyze <logs>` - Analyze log output against hypotheses
- `/debug-workflow:help` - Show all debug workflow commands
