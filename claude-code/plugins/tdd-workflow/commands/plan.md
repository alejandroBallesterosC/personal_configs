---
description: Deep planning through comprehensive user interview
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Feature Planning Interview

**Feature**: $1
**Description**: $2

This follows Thariq Shihab's spec-based development approach: interview first, then code.

## Before Starting

Check if exploration exists at `docs/context/$1-exploration.md`. If not, recommend running `/tdd-workflow:explore $1 "$2"` first.

## Interview Protocol

Ask questions **ONE AT A TIME** using AskUserQuestionTool.

Each question should:
- Be specific and non-obvious
- Challenge assumptions where appropriate
- Build on previous answers
- Avoid questions with obvious answers

For large features, expect to ask **40+ questions**.

## Domains to Cover (in order)

### 1. Core Functionality
- What exactly should this feature do?
- What is the primary user goal?
- What inputs does it accept?
- What outputs does it produce?
- What is the happy path?

### 2. Technical Constraints
- What technology stack must be used?
- Are there dependencies or libraries to prefer/avoid?
- What performance requirements exist?
- Are there API compatibility requirements?

### 3. UI/UX (if applicable)
- How will users interact with this feature?
- What feedback should users receive?
- What loading/error states are needed?
- What accessibility requirements exist?

### 4. Edge Cases
- What could go wrong?
- What happens with invalid input?
- What happens at scale (0, 1, many)?
- What are the boundary conditions?

### 5. Security
- What authentication/authorization is needed?
- What data needs protection?
- What inputs need validation?
- Are there audit/logging requirements?

### 6. Testing
- What defines "working correctly"?
- What are the critical paths to test?
- What edge cases must have tests?
- What integration points need testing?

### 7. Integration
- How does this connect to existing code?
- What existing APIs/interfaces should it use?
- What shared state does it touch?
- What events does it emit/consume?

### 8. Performance
- What scale must this handle?
- What latency is acceptable?
- What resource limits exist?
- What caching strategy makes sense?

### 9. Deployment
- How will this be rolled out?
- Does it need feature flags?
- What monitoring is needed?
- What rollback strategy exists?

## Interview Attitude

Be like a journalist or skeptical senior engineer:
- Ask follow-up questions for vague answers
- Challenge idealistic assumptions
- Push back on "it depends" responses
- Probe for unstated requirements

## Output

When the interview is complete (you have clarity on ALL domains):

1. **Write specification** to `docs/specs/$1.md`:
   - Complete requirements
   - Acceptance criteria
   - Non-functional requirements
   - Out of scope items

2. **Write implementation plan** to `docs/plans/$1-plan.md`:
   - Ordered implementation steps
   - **Components designed for parallel implementation**
   - Dependencies between steps
   - Independent components that can be implemented in parallel
   - Integration points between components

3. **Write test cases** to `docs/plans/$1-tests.md`:
   - Test cases for each requirement
   - Edge case tests
   - Integration tests
   - E2E test scenarios
   - Acceptance tests

## Plan Structure for Parallel Implementation

The implementation plan MUST identify:

```markdown
## Independent Components

### Component 1: [Name]
- **Purpose**: [What it does]
- **Dependencies**: [External deps only, not other components]
- **Interface**: [Inputs/Outputs]
- **Can run in parallel with**: [Other components]

### Component 2: [Name]
...

## Build Order

1. **Foundation** (must complete first):
   - Shared types/interfaces
   - Common utilities
   - Configuration

2. **Parallel Components** (can implement simultaneously):
   - Component 1
   - Component 2
   - Component 3

3. **Integration Layer** (after parallel components):
   - Wire components together
   - Coordination logic
```

## Completion

End with this message:

```
Planning complete for: $1

Artifacts created:
- docs/specs/$1.md (specification)
- docs/plans/$1-plan.md (implementation plan with parallel components)
- docs/plans/$1-tests.md (test cases)

Next steps:
1. /tdd-workflow:architect $1 (design technical approach)
2. /tdd-workflow:review-plan $1 (challenge the plan)

Or continue the full workflow:
/tdd-workflow:start $1 "$2"
```
