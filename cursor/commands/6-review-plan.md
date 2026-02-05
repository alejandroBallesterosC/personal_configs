
# Plan Review

You are critically reviewing the plan for: **$ARGUMENTS**

This follows Mo Bitar's interrogation method: pushback on idealistic ideas, find gaps before implementation.

## Prerequisites

Read ALL planning artifacts:
- `docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md` (codebase context)
- `docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md` (specification)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md` (architecture)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md` (implementation plan)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-tests.md` (test cases)

If any are missing, recommend running the previous workflow steps first.

## Process

### Spawn Plan-Reviewer Subagent

Use the Task tool to spawn a `plan-reviewer` agent:

```
Use Task tool with subagent_type: "plan-reviewer"

Prompt:
Feature: $ARGUMENTS

Critically review the implementation plan for this feature.

Context files to read:
- docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md (codebase context)
- docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md (specification)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md (architecture)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md (implementation plan)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-tests.md (test cases)

Review Focus:
1. Evaluate each planning artifact against the checklist below
2. Identify gaps and unstated assumptions
3. Challenge architectural decisions
4. Verify parallel implementation viability
5. Check for security, performance, and integration risks
6. Verify API key requirements are identified

For each finding, report:
- Area: [Completeness/Feasibility/Edge Cases/etc.]
- Rating: ✅ Good / ⚠️ Concern / ❌ Blocker
- Details: [What the issue is]
- Suggestion: [How to address it]

Return a comprehensive review report with all findings.
```

### After Subagent Returns

The main instance should:
1. Present findings to user via AskUserQuestionTool
2. Ask follow-up questions for any ⚠️ or ❌ items
3. Update plan files based on user's decisions
4. Get explicit user approval before proceeding to implementation

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
- docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md (if modified)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md (if modified)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md (if modified)

Next step:
obtain explicit user approval to start implementation.

You may optionally run /clear to reset context before implementation - hooks will preserve and restore state automatically.

/7-implement $ARGUMENTS "[description]"

Or continue the full workflow:
/1-start $ARGUMENTS "[description]"
```
