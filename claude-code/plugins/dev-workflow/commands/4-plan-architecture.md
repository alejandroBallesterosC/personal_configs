---
description: Technical architecture design from specification (Phase 4)
model: opus
argument-hint: <feature-name>
---

# Technical Architecture Design

You are designing the technical architecture for: **$ARGUMENTS**

This is **Phase 4** of the TDD implementation workflow. It creates the technical architecture from the specification, which will guide the implementation plan.

## Prerequisites

Read these files before designing:
- `docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md` (codebase context)
- `docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md` (feature specification)
- `CLAUDE.md` (project conventions)

If any are missing, recommend running the previous workflow steps first:
- `/dev-workflow:2-explore $ARGUMENTS "<description>"` for exploration
- `/dev-workflow:3-user-specification-interview $ARGUMENTS "<description>"` for specification

## Architecture Research

Before designing the architecture, spawn **5 parallel `researcher` subagents** to gather technical insights that inform architectural decisions.

```
Use Task tool with subagent_type: "dev-workflow:researcher" (5 parallel instances)

Each instance receives:
Feature: $ARGUMENTS
Specification: docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md

Instance 1 - Architecture Patterns:
Research focus: Architecture patterns for systems similar to "$ARGUMENTS". Look for design patterns, component decomposition strategies, and proven architectural approaches.

Instance 2 - Technology Evaluation:
Research focus: Technology and library evaluation for "$ARGUMENTS". Compare candidate libraries and frameworks, check maintenance status, community health, and known issues.

Instance 3 - Data Modeling:
Research focus: Data modeling and storage patterns for "$ARGUMENTS". Look for schema design approaches, data flow patterns, state management strategies, and storage trade-offs.

Instance 4 - API Design:
Research focus: API design patterns and interface contracts for "$ARGUMENTS". Look for REST/GraphQL/RPC conventions, versioning strategies, error handling patterns, and contract-first approaches.

Instance 5 - Infrastructure and Deployment:
Research focus: Infrastructure and deployment patterns for "$ARGUMENTS". Look for containerization approaches, scaling strategies, monitoring patterns, and deployment pipelines.
```

### Synthesize Research

After all 5 researcher agents return, synthesize their findings into:

Write to `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-research.md`:

```markdown
# Architecture Research: $ARGUMENTS

## Sources Summary
[Total sources consulted, date of research]

## Architecture Patterns
[Synthesized findings from Instance 1]

## Technology Evaluation
[Synthesized findings from Instance 2]

## Data Modeling
[Synthesized findings from Instance 3]

## API Design
[Synthesized findings from Instance 4]

## Infrastructure and Deployment
[Synthesized findings from Instance 5]

## Key Takeaways for Architecture Design
[3-5 bullet points highlighting what to incorporate into the architecture]
```

Reference the architecture research when making design decisions below.

---

## Process

You have two options for creating the architecture:

### Option A: Main Instance Creates Architecture (Recommended)

The main instance designs the architecture directly, since it has full context from the exploration and specification phases.

Design the technical architecture:
1. Component breakdown and responsibilities
2. File structure and naming
3. API contracts and interfaces
4. Data flow and state management
5. Integration approach with existing code
6. **Parallel implementation strategy**

### Option B: Spawn Code-Architect Subagent

For complex architectures, spawn a `code-architect` subagent using the Task tool:

```
Use Task tool with subagent_type: "dev-workflow:code-architect"

Prompt:
Feature: $ARGUMENTS

Create technical architecture for this feature.

Context files to read:
- docs/workflow-$ARGUMENTS/codebase-context/$ARGUMENTS-exploration.md (codebase context)
- docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md (feature specification)
- CLAUDE.md (project conventions)

Design requirements:
1. Component breakdown with clear responsibilities
2. File structure and naming following existing patterns
3. API contracts and interfaces
4. Data flow and state management
5. Integration approach with existing code
6. Parallel implementation strategy - components must be independently implementable

Output: Write architecture to docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md
```

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

Write architecture document to `docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md`:

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

Artifacts created:
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-research.md (architecture research)
- docs/workflow-$ARGUMENTS/plans/$ARGUMENTS-architecture-plan.md (architecture design)

Architecture supports:
- [N] independent components for parallel implementation
- [N] external integrations identified
- Build sequence: Foundation → Parallel Components → Integration

Next step:
/dev-workflow:5-plan-implementation $ARGUMENTS (create implementation plan from architecture)
```
