---
description: TDD implementation of a planned feature using ralph-loop
model: opus
argument-hint: <feature> --max-iterations <N>
---

# TDD Implementation

Implementing feature: **$ARGUMENTS**

This command uses the `ralph-loop` plugin for autonomous TDD iteration.

## Prerequisites

Verify all planning artifacts exist:
- `docs/specs/$ARGUMENTS.md` (specification)
- `docs/plans/$ARGUMENTS-arch.md` (architecture)
- `docs/plans/$ARGUMENTS-plan.md` (implementation plan)
- `docs/plans/$ARGUMENTS-tests.md` (test cases)

If any are missing, recommend running the planning workflow first.

## Arguments

**Required**: `--max-iterations N`

The `--max-iterations` flag is REQUIRED for safety. Suggested values:
- Small feature (1-3 files): 10-15
- Medium feature (4-10 files): 20-30
- Large feature (10+ files): 40-50

## Process

1. **Read all planning artifacts**
2. **Construct TDD prompt** from requirements
3. **Invoke ralph-loop** with the prompt

## Execution

Read the planning files, then invoke:

```
/ralph-loop:ralph-loop "Implement $ARGUMENTS following strict TDD.

Read these files for context:
- docs/specs/$ARGUMENTS.md (specification)
- docs/plans/$ARGUMENTS-arch.md (architecture)
- docs/plans/$ARGUMENTS-plan.md (implementation plan)
- docs/plans/$ARGUMENTS-tests.md (test cases)

For EACH requirement in the implementation plan:

## RED PHASE
1. Use the test-designer agent mindset: write ONE failing test
2. The test should define expected behavior for this requirement
3. Run tests and confirm failure
4. Commit: git commit -m 'red: test for [requirement]'

## GREEN PHASE
1. Use the implementer agent mindset: write MINIMAL code
2. Only write enough code to make THIS test pass
3. No extra features, no optimization
4. Run tests and confirm they pass
5. Commit: git commit -m 'green: [requirement]'

## REFACTOR PHASE (if needed)
1. Use the refactorer agent mindset: improve code quality
2. Make ONE small improvement at a time
3. Run tests after EACH change
4. If tests fail, undo immediately
5. Commit: git commit -m 'refactor: [description]'

## IMPORTANT RULES
- Never skip the RED phase - tests come first
- Never write more code than tests require
- Run tests after EVERY change
- Commit at each phase transition
- Follow existing code patterns from CLAUDE.md

## COMPLETION
When ALL requirements from the plan have passing tests:
1. Run full test suite one final time
2. Verify all tests pass
3. Output: TDD_COMPLETE

Continue until all requirements are implemented with passing tests." --max-iterations [N] --completion-promise "TDD_COMPLETE"
```

Replace `[N]` with the user's `--max-iterations` value.

## During Implementation

The ralph-loop will:
- Iterate autonomously through RED-GREEN-REFACTOR cycles
- Create git commits at each phase
- Run tests automatically via PostToolUse hook
- Stop when "TDD_COMPLETE" is output or max iterations reached

## Monitoring Progress

Watch for:
- Git commits appearing (red: ..., green: ..., refactor: ...)
- Test results after each code change
- Progress through the implementation plan

## Completion

When ralph-loop completes, you'll see:
- All requirements implemented
- Full test coverage for new code
- Clean git history showing TDD progression

Next step:
```
/tdd-workflow:review
```
