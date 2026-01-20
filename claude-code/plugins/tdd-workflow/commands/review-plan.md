---
description: Critical review of plan before implementation
model: opus
argument-hint: <feature>
---

# Plan Review

You are critically reviewing the plan for: **$ARGUMENTS**

This follows Mo Bitar's interrogation method: pushback on idealistic ideas, find gaps before implementation.

## Prerequisites

Read ALL planning artifacts:
- `docs/context/$ARGUMENTS-exploration.md` (codebase context)
- `docs/specs/$ARGUMENTS.md` (specification)
- `docs/plans/$ARGUMENTS-arch.md` (architecture)
- `docs/plans/$ARGUMENTS-plan.md` (implementation plan)
- `docs/plans/$ARGUMENTS-tests.md` (test cases)

If any are missing, recommend running the previous workflow steps first.

## Process

Use the `plan-reviewer` agent to:
1. Evaluate each planning artifact against the checklist
2. Identify gaps and unstated assumptions
3. Challenge architectural decisions
4. Ask follow-up questions via AskUserQuestionTool
5. Update plan files with feedback

## Review Checklist

The plan-reviewer will evaluate:

| Area | Question |
|------|----------|
| Completeness | Are all requirements addressed? |
| Feasibility | Is the architecture realistic? |
| Edge Cases | What hasn't been considered? |
| Integration Risk | Will this break existing code? |
| Testing Gaps | Are test cases comprehensive? |
| Security | Any overlooked vulnerabilities? |
| Performance | Will this scale? |
| Assumptions | What's unstated but assumed? |

## Ratings

Each area gets a rating:
- ✅ **Good** - No concerns
- ⚠️ **Concern** - Needs clarification
- ❌ **Blocker** - Must resolve before implementation

## Output

For any ⚠️ or ❌ findings, ask follow-up questions using AskUserQuestionTool.

Update the relevant plan files with:
- Clarified requirements
- Additional edge cases
- Security considerations
- Performance constraints

## Completion Criteria

The review is complete when:
- All checklist areas are ✅ Good or addressed
- No ❌ Blockers remain
- User has answered all follow-up questions
- Plan files are updated with feedback

## Completion Message

```
Plan review complete for: $ARGUMENTS

All blockers resolved. Plan is ready for implementation.

Next step (recommend starting fresh session):
/tdd-workflow:implement $ARGUMENTS --max-iterations N

Suggested iteration count:
- Small feature (1-3 files): 10-15 iterations
- Medium feature (4-10 files): 20-30 iterations
- Large feature (10+ files): 40-50 iterations
```
