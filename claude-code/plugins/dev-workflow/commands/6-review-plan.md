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
- `docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md` (codebase context)
- `docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md` (specification)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md` (architecture)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md` (implementation plan)
- `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-tests.md` (test cases)

If any are missing, recommend running the previous workflow steps first.

## Validation Research

Before the plan review, spawn **5 parallel `researcher` subagents** to validate planning decisions against external knowledge.

```
Use Task tool with subagent_type: "dev-workflow:researcher" (5 parallel instances)

Each instance receives:
Feature: $ARGUMENTS
Architecture: docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md
Implementation Plan: docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md

Instance 1 - Architecture Validation:
Research focus: Validate the architecture decisions for "$ARGUMENTS" against current best practices. Look for whether the chosen patterns are still recommended, if better alternatives have emerged, and whether the component decomposition follows established guidelines.

Instance 2 - Technology Risk Assessment:
Research focus: Technology risk assessment for the libraries and frameworks chosen in "$ARGUMENTS". Check for deprecation notices, CVEs, upcoming breaking changes, maintenance status, and community health of each dependency.

Instance 3 - Known Issues:
Research focus: Known bugs and issues in the libraries chosen for "$ARGUMENTS". Search GitHub issues, Stack Overflow, and community forums for unresolved problems, workarounds, and version-specific gotchas.

Instance 4 - Alternative Approaches:
Research focus: Alternative approaches to implementing "$ARGUMENTS" that might be simpler, more maintainable, or more performant. Look for different architectural patterns, alternative libraries, and approaches the current plan might have missed.

Instance 5 - Security Validation:
Research focus: Security validation for "$ARGUMENTS" against current threat models. Check for OWASP top 10 risks, authentication/authorization best practices for the chosen stack, and known security anti-patterns.
```

### Synthesize Research

After all 5 researcher agents return, synthesize their findings into:

Write to `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-review-research.md`:

```markdown
# Validation Research: $ARGUMENTS

## Sources Summary
[Total sources consulted, date of research]

## Architecture Validation
[Synthesized findings from Instance 1]

## Technology Risk Assessment
[Synthesized findings from Instance 2]

## Known Issues
[Synthesized findings from Instance 3]

## Alternative Approaches
[Synthesized findings from Instance 4]

## Security Validation
[Synthesized findings from Instance 5]

## Key Concerns for Plan Review
[3-5 bullet points highlighting areas that need scrutiny during the review]
```

Include the review research in the plan-reviewer's context below.

---

## Process

### Spawn Plan-Reviewer Subagent

Use the Task tool to spawn a `plan-reviewer` agent:

```
Use Task tool with subagent_type: "dev-workflow:plan-reviewer"

Prompt:
Feature: $ARGUMENTS

Critically review the implementation plan for this feature.

Context files to read:
- docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md (codebase context)
- docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-domain-research.md (domain research, if exists)
- docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md (specification)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-research.md (architecture research, if exists)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md (architecture)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-research.md (implementation research, if exists)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md (implementation plan)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-tests.md (test cases)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-review-research.md (validation research)

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
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-review-research.md (validation research)
- docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md (if modified)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-implementation-plan.md (if modified)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md (if modified)

Next step:
obtain explicit user approval to start implementation.

You may optionally run /clear to reset context before implementation - hooks will preserve and restore state automatically.

/dev-workflow:7-implement $ARGUMENTS "[description]"

Or continue the full workflow:
/dev-workflow:1-start-tdd-implementation $ARGUMENTS "[description]"
```
