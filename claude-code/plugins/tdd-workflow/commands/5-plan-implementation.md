---
description: Create implementation plan from architecture (Phase 5)
model: opus
argument-hint: <feature-name>
---

# Implementation Plan Creation

**Feature**: $1

This is **Phase 5** of the TDD workflow. It creates a detailed implementation plan with parallelizable components based on the architecture design.

## Before Starting

1. **Check architecture exists** at `docs/workflow-$1/plans/$1-architecture-plan.md`
   - If not, recommend running `/tdd-workflow:4-plan-architecture $1` first

2. **Check specification exists** at `docs/workflow-$1/specs/$1-specs.md`
   - If not, recommend running `/tdd-workflow:3-user-specification-interview $1 "<description>"` first

3. **Read the architecture** thoroughly to understand:
   - Component breakdown and responsibilities
   - Independent components for parallel implementation
   - Integration points and data flow
   - External integrations and API requirements

4. **Read the specification** to understand:
   - All requirements
   - Acceptance criteria
   - Non-functional requirements
   - Out of scope items

5. **Read exploration** at `docs/workflow-$1/codebase-context/$1-exploration.md` for:
   - Codebase patterns to follow
   - Existing interfaces to use
   - Test framework and conventions

## Execution

The **main instance creates the implementation plan** directly. This phase does not spawn subagents because:
- The main instance has full context from the architecture and specification phases
- Planning benefits from the conversation history with the user
- The plan needs to be coherent and consistent

---

## Plan Requirements

The implementation plan MUST:

1. **Define implementation tasks for each component** from the architecture
   - Map architecture components to concrete implementation tasks
   - Specify what code to write for each component
   - Identify which components can be implemented in parallel

2. **Specify component contracts**
   - Input/output for each component (from architecture)
   - How components will integrate
   - Shared types/interfaces needed first

3. **Order tasks by dependency**
   - Foundation tasks first (shared types, interfaces)
   - Independent component tasks can be parallelized
   - Integration layer last

4. **Define test strategy per component**
   - Unit tests for each component
   - Integration tests for component interactions
   - E2E tests for full workflow

5. **Handle external integrations**
   - Prefer real API implementations
   - Document required API keys/credentials
   - Define mock fallbacks only when real integration isn't possible

## Output

Create these artifacts:

### 1. Implementation Plan (`docs/workflow-$1/plans/$1-implementation-plan.md`)

```markdown
# Implementation Plan: $1

## Architecture Reference
See docs/workflow-$1/plans/$1-architecture-plan.md for component architecture.

## Implementation Tasks

### Foundation Tasks (Sequential)

#### Task F1: Shared Types
- **From Architecture**: [Component reference]
- **Files to create**: [paths]
- **Implementation details**: [what to write]
- **Tests**: [what to test]

#### Task F2: Common Utilities
- **From Architecture**: [Component reference]
- **Files to create**: [paths]
- **Implementation details**: [what to write]
- **Tests**: [what to test]

### Component Tasks (Parallel)

#### Task C1: [Component Name]
- **From Architecture**: [Component reference]
- **Files to create**: [paths]
- **Interface**: [Inputs/Outputs from architecture]
- **Implementation details**: [what to write]
- **Tests**: [what to test]
- **Estimated complexity**: [S/M/L]
- **Can run in parallel with**: [Task C2, Task C3]

#### Task C2: [Component Name]
...

### Integration Tasks (Sequential, after components)

#### Task I1: Wire Components
- **From Architecture**: [Integration layer reference]
- **Files to create/modify**: [paths]
- **Implementation details**: [what to wire]
- **Integration tests**: [what to test]

## Build Order

1. **Foundation** (must complete first):
   - Task F1: Shared types/interfaces
   - Task F2: Common utilities

2. **Parallel Components** (can implement simultaneously):
   - Task C1: [Component 1]
   - Task C2: [Component 2]
   - Task C3: [Component 3]

3. **Integration Layer** (after parallel components):
   - Task I1: Wire components together
   - Task I2: Coordination logic

## External Integrations
- APIs required (from architecture)
- API keys needed (check availability)
- Mock fallback strategy (if needed)
```

### 2. Test Cases (`docs/workflow-$1/plans/$1-tests.md`)

```markdown
# Test Cases: $1

## Unit Tests

### [Component 1] Tests
- [Test case 1]: [description]
- [Test case 2]: [description]

### [Component 2] Tests
- [Test case 1]: [description]
- [Test case 2]: [description]

## Integration Tests
- [Test case for component interactions]

## E2E Tests
- [Happy path scenarios]
- [Error scenarios]
- [Edge cases]
```

## Completion

End with this message:

```
Implementation plan complete for: $1

Artifacts created:
- docs/workflow-$1/plans/$1-implementation-plan.md (implementation plan with parallel tasks)
- docs/workflow-$1/plans/$1-tests.md (test cases)

References:
- docs/workflow-$1/plans/$1-architecture-plan.md (architecture design from Phase 4)

Next step:
/tdd-workflow:6-review-plan $1 (challenge the plan before implementation)
```
