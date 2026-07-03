---
name: adversarial-plan-review
description: Adversarial checklist for critiquing implementation plans before building — evidence-to-decision audit, assumption inversion, cross-artifact consistency, and external-dependency checks. Use when reviewing a plan (from Plan Mode or a written doc) before implementation begins.
---

# Adversarial Plan Review Skill

A critical-reviewer checklist for finding problems in a plan before implementation starts: unsupported decisions, contradictions between plan and requirements, feasibility gaps, and undocumented external dependencies. Apply this directly to whatever planning artifacts exist (a Plan Mode proposal, a written design doc, requirements + architecture + test plan, etc.) — no dedicated agent or state machine needed.

**Announce at start:** "I'm using the adversarial-plan-review skill to critique this plan."

## Step 1: Evidence-to-Decision Audit

For each major decision in the plan:

1. **What decision does the plan make?** (e.g., "Use Redis for caching")
2. **What evidence supports this?** (research finding, prior art, benchmark, or "asserted with no evidence")
3. **Does the evidence's context actually match ours?** Was it gathered under similar conditions? Does it prove the choice or merely assert it? Under what conditions would this decision be wrong?
4. **Rate the evidence-to-decision gap**: TIGHT | MODERATE | WIDE

Decisions with a WIDE gap should be flagged as CONCERN or BLOCKER depending on how consequential the decision is.

## Step 2: Assumption Inversion

For the 2-3 most consequential decisions, invert the underlying assumption and check if the plan survives:

| Decision | Underlying Assumption | Inverted Assumption | Plan Survives? |
|----------|----------------------|--------------------|-----------------|
| [decision] | [what it assumes] | [the opposite] | [Yes / No / Partial — why] |

Any "No" escalates to a BLOCKER.

## Step 3: Cross-Artifact Consistency

If multiple planning documents exist (requirements, architecture, test plan, implementation plan), cross-examine each pair:

- **Requirements ↔ Architecture**: Does the architecture support every MUST requirement? Any components that map to no requirement (over-engineering)? Any requirements with no owning component (gaps)?
- **Requirements ↔ Test Plan**: Does every MUST requirement have at least one test case? Do test cases cover the listed edge cases? Any tests covering behavior not in requirements (scope creep)?
- **Architecture ↔ Implementation Plan**: Does the build order respect the architecture's dependency graph? Are all components accounted for? Do file paths match the architecture?
- **Architecture ↔ Test Plan**: Do integration tests cover the interfaces between components? Does test infrastructure match the chosen technologies?
- **Implementation Plan ↔ Test Plan**: Does each implementation task have corresponding tests? Is test execution order consistent with build order?
- **All artifacts ↔ Evidence base**: Are technology choices supported by cited research/prior art? Does anything contradict that evidence? Are known risks addressed?

If only a single plan document exists (the common case), apply the spirit of these checks internally: does the plan's own stated approach cover its own stated requirements, with no orphaned pieces on either side?

## Step 4: External Dependencies Audit

This is critical — it is what prevents mock/slop implementations later. For every external service, API, or credential the plan implies:

- Is it documented?
- Is the credential/API key requirement identified?
- Is the integration plan concrete (not "figure this out during implementation")?

## Step 5: Practical Feasibility

- Are all external API/service dependencies identified with clear integration plans?
- Are API keys, credentials, or access requirements documented?
- Is the total scope realistic for the described timeline?
- Are there circular dependencies in the implementation sequence?

## Output

Present findings as:

**Issue N** [BLOCKER | CONCERN | SUGGESTION]
- *Problem*: what is wrong, missing, or contradictory
- *Evidence*: the specific finding, section, or artifact that supports this criticism (or "no supporting evidence found")
- *Resolution*: how to fix it, specific about what to change

Severity definitions:
- **BLOCKER**: Implementation will fail or produce incorrect results if not fixed.
- **CONCERN**: Implementation will be harder or riskier than necessary, but not fatal.
- **SUGGESTION**: Would improve the plan but isn't critical.

Close with a verdict: `NO_BLOCKER_ISSUES` or `BLOCKERS_FOUND: N` with a one-line summary of what must be resolved.

## Rules

- NEVER invent issues without concrete supporting evidence from the plan, requirements, or established engineering principles.
- Classify severity accurately — don't inflate CONCERN to BLOCKER or deflate BLOCKER to CONCERN.
- Be specific: vague criticism ("this seems risky") is not useful; name the exact decision and why.
- If you find no issues, say `NO_BLOCKER_ISSUES` explicitly. Don't invent problems to justify a thorough review.
