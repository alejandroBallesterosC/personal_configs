
# User Specification Interview

**Feature**: $1
**Description**: $2

This is **Phase 3** of the TDD workflow. It follows Thariq Shihab's spec-based development approach: interview first, then plan, then code.

## Before Starting

Check if exploration exists at `docs/workflow-$1/codebase-context/$1-exploration.md`. If not, recommend running `/2-explore $1 "$2"` first.

## Execution

The **main instance conducts the interview** directly using AskUserQuestionTool. This phase does not spawn subagents because:
- The interview requires real-time user interaction
- Questions build on previous answers
- The main instance needs to maintain conversation context

---

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

When the specification interview is complete (you have clarity on ALL domains):

Write specification to `docs/workflow-$1/specs/$1-specs.md`:
- Complete requirements
- Acceptance criteria
- Non-functional requirements
- Out of scope items

## Completion

End with this message:

```
Specification interview complete for: $1

Artifact created:
- docs/workflow-$1/specs/$1-specs.md (specification)

Next step:
/4-plan-architecture $1 (create technical architecture from spec)
```
