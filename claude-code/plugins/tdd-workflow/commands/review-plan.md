---
description: Critical review of plan before implementation
model: opus
argument-hint: <feature-name>
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
4. **Verify parallel implementation viability**
5. Ask follow-up questions via AskUserQuestionTool
6. Provide suggestions and feedback to user
7. Update plan files based on user's decisions

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
| **Parallelization** | Are components truly independent? |
| **API Dependencies** | Are required API keys identified? |

## Parallel Implementation Review

Specifically verify:
- Are component boundaries clear?
- Can components be implemented without knowing each other's internals?
- Are shared interfaces well-defined?
- Is the integration approach clear?
- What happens if one component fails?

## Ratings

Each area gets a rating:
- ✅ **Good** - No concerns
- ⚠️ **Concern** - Needs clarification
- ❌ **Blocker** - Must resolve before implementation

## Output

For any ⚠️ or ❌ findings:
1. Ask follow-up questions using AskUserQuestionTool
2. Present suggestions and concerns to the user
3. Wait for user decisions on each suggestion
4. Update the relevant plan files based on user input

Update the relevant plan files with:
- Clarified requirements
- Additional edge cases
- Security considerations
- Performance constraints
- Refined component boundaries

## Completion Criteria

The review is complete when:
- All checklist areas are ✅ Good or addressed
- No ❌ Blockers remain
- User has answered all follow-up questions
- User has approved or modified suggestions
- Plan files are updated with feedback
- Components are verified as parallelizable

## Completion Message

```
Plan review complete for: $ARGUMENTS

All blockers resolved. Plan is ready for implementation.

## Summary
- Components for parallel implementation: [N]
- External integrations: [N]
- API keys required: [list]

## User Decisions
[Summary of suggestions and user's decisions]

## Updated Artifacts
- docs/specs/$ARGUMENTS.md (if modified)
- docs/plans/$ARGUMENTS-plan.md (if modified)
- docs/plans/$ARGUMENTS-arch.md (if modified)

Next step:
/tdd-workflow:implement $ARGUMENTS "[description]"

Or continue the full workflow:
/tdd-workflow:start $ARGUMENTS "[description]"
```
