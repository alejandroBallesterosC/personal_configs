---
description: Technical architecture design for planned feature
model: opus
argument-hint: <feature>
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

## Output

Write architecture document to `docs/plans/$ARGUMENTS-arch.md`:

```markdown
# $ARGUMENTS Architecture

## Component Overview

[ASCII diagram showing component relationships]

## Components

### Component 1: [Name]
- **Purpose**: [What it does]
- **File**: [path/to/file]
- **Dependencies**: [What it imports]
- **Exports**: [What it exposes]

### Component 2: [Name]
...

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

| File | Action | Purpose |
|------|--------|---------|
| path/to/new.py | Create | [purpose] |
| path/to/existing.py | Modify | [what changes] |

## Build Sequence

Implement in this order:
1. [First thing] - no dependencies
2. [Second thing] - depends on #1
3. [Third thing] - depends on #1, #2
```

## Completion

End with:

```
Architecture design complete for: $ARGUMENTS

Artifact created:
- docs/plans/$ARGUMENTS-arch.md

Next step:
/tdd-workflow:review-plan $ARGUMENTS
```
