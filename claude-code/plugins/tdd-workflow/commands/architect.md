---
description: Technical architecture design for planned feature
model: opus
argument-hint: <feature-name>
---

# Technical Architecture Design

You are designing the technical architecture for: **$ARGUMENTS**

## Prerequisites

Read these files before designing:
- `docs/context/$ARGUMENTS-exploration.md` (codebase context)
- `docs/specs/$ARGUMENTS.md` (feature specification)
- `docs/plans/$ARGUMENTS-plan.md` (implementation plan)
- `CLAUDE.md` (project conventions)

If any are missing, recommend running the previous workflow steps first.

## Process

Use the `code-architect` agent to design:
1. Component breakdown and responsibilities
2. File structure and naming
3. API contracts and interfaces
4. Data flow and state management
5. Integration approach with existing code
6. **Parallel implementation strategy**

## Architecture for Parallel Implementation

The architecture MUST support parallel component implementation:

### Identify Independent Components
- Components that can be built by separate subagents
- Clear interfaces between components
- No circular dependencies
- Shared types/interfaces defined upfront

### Define Integration Points
- How components connect
- What the integration layer does
- What E2E tests will verify

## Output

Write architecture document to `docs/plans/$ARGUMENTS-arch.md`:

```markdown
# $ARGUMENTS Architecture

## Component Overview

[ASCII diagram showing component relationships]

## Foundation (Build First)

### Shared Types
- **File**: [path/to/types]
- **Exports**: [interfaces, types]

### Common Utilities
- **File**: [path/to/utils]
- **Exports**: [shared functions]

## Independent Components (Build in Parallel)

### Component 1: [Name]
- **Purpose**: [What it does]
- **File**: [path/to/file]
- **Dependencies**: [External deps only]
- **Interface**:
  - Input: [What it receives]
  - Output: [What it produces]
- **Can parallel with**: [Other components]

### Component 2: [Name]
- **Purpose**: [What it does]
- **File**: [path/to/file]
- **Dependencies**: [External deps only]
- **Interface**:
  - Input: [What it receives]
  - Output: [What it produces]
- **Can parallel with**: [Other components]

### Component 3: [Name]
...

## Integration Layer (Build After Components)

### Wiring
- How components connect
- Coordination logic
- Entry points

### Integration Tests
- What scenarios to test
- What connections to verify

## Interfaces

### [Interface Name]
```typescript
interface Example {
  method(param: Type): ReturnType;
}
```

## Data Flow

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Files to Create/Modify

| File | Action | Purpose | Phase |
|------|--------|---------|-------|
| path/to/types.py | Create | Shared types | Foundation |
| path/to/comp1.py | Create | Component 1 | Parallel |
| path/to/comp2.py | Create | Component 2 | Parallel |
| path/to/main.py | Create | Integration | Integration |

## Build Sequence

1. **Foundation Phase** (sequential):
   - Shared types and interfaces
   - Common utilities
   - Configuration

2. **Component Phase** (parallel):
   - Component 1 (subagent A)
   - Component 2 (subagent B)
   - Component 3 (subagent C)

3. **Integration Phase** (sequential):
   - Wire components together
   - Integration tests
   - E2E tests

## External Integrations

| Service | Purpose | API Key Required |
|---------|---------|------------------|
| [Service] | [Why] | Yes/No |

## API Key Requirements

List any external services that need API keys:
- [Service]: Check if `$ENV_VAR` is set
- [Service]: Check if `$ENV_VAR` is set
```

## Completion

End with:

```
Architecture design complete for: $ARGUMENTS

Artifact created:
- docs/plans/$ARGUMENTS-arch.md

Architecture supports:
- [N] independent components for parallel implementation
- [N] external integrations identified
- Build sequence: Foundation → Parallel Components → Integration

Next step:
/tdd-workflow:review-plan $ARGUMENTS
```
