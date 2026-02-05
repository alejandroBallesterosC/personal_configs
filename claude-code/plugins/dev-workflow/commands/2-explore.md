---
description: Parallel codebase exploration with 5 code-explorer agents
model: opus
argument-hint: <feature-name> "<feature description>"
---

# Parallel Codebase Exploration

**Feature**: $1
**Description**: $2

## Objective

Explore the codebase from **5 different angles simultaneously** by spawning 5 instances of the `code-explorer` agent in parallel. Each instance uses **Sonnet with 1M context window** for comprehensive analysis.

---

## LAUNCHING 5 PARALLEL CODE-EXPLORER AGENTS

Launch all 5 agents **IN PARALLEL** using a single message with 5 Task tool calls.

Each uses `subagent_type: "dev-workflow:code-explorer"`:

### Agent 1: Architecture Focus

```
Feature: $1
Description: $2

EXPLORATION FOCUS: Architecture

Explore the codebase architecture relevant to implementing this feature:

1. Identify architectural layers (presentation, business logic, data access, infrastructure)
2. Map the component/module structure and organization
3. Document data flow patterns - how data enters, transforms, and exits
4. Identify entry points (main files, routers, handlers, CLI)
5. Note key architectural decisions and their rationale

Produce a comprehensive architecture exploration report.
```

### Agent 2: Patterns & Conventions Focus

```
Feature: $1
Description: $2

EXPLORATION FOCUS: Patterns & Conventions

Explore coding patterns and conventions relevant to implementing this feature:

1. Document naming conventions (files, classes, functions, variables)
2. Identify code organization patterns within files and modules
3. Find common abstractions (base classes, interfaces, utilities)
4. Note error handling patterns used throughout
5. Find similar existing features that can serve as templates

Produce a comprehensive patterns exploration report.
```

### Agent 3: Boundaries & Interfaces Focus

```
Feature: $1
Description: $2

EXPLORATION FOCUS: Boundaries & Interfaces

Explore module boundaries and interfaces relevant to implementing this feature:

1. Map module boundaries and their contracts
2. Identify public APIs and internal interfaces
3. Document integration points with external systems
4. Analyze coupling between components
5. Note dependency directions and any circular dependencies

Produce a comprehensive boundaries exploration report.
```

### Agent 4: Testing Strategy Focus

```
Feature: $1
Description: $2

EXPLORATION FOCUS: Testing Strategy

Explore the testing approach relevant to implementing this feature:

1. Identify test frameworks and tools in use
2. Analyze existing test coverage and gaps
3. Document testing conventions (naming, structure, organization)
4. Find example tests for similar features to follow
5. Note mocking patterns and test data approaches

Produce a comprehensive testing exploration report.
```

### Agent 5: Dependencies & Environment Focus

```
Feature: $1
Description: $2

EXPLORATION FOCUS: Dependencies & Environment

Explore dependencies and environment requirements for implementing this feature:

1. Identify required packages/libraries and their versions
2. Document external service integrations (APIs, databases, queues)
3. List required environment variables and configuration
4. CHECK IF API KEYS ARE AVAILABLE for any required external services
5. Note any infrastructure or deployment requirements

Produce a comprehensive dependencies exploration report. IMPORTANTLY: Report which API keys are available and which are missing.
```

---

## SYNTHESIS

After all 5 agents complete, synthesize their findings:

### 1. Create Exploration Document

Write comprehensive exploration to: `docs/workflow-$1/codebase-context/$1-exploration.md`

Structure:
```markdown
# Exploration: $1

## Feature Description
$2

## Architecture
[Synthesized from Architecture Focus agent]
- Layer structure
- Component map
- Data flow

## Patterns & Conventions
[Synthesized from Patterns Focus agent]
- Naming conventions
- Code organization
- Similar features to follow

## Boundaries & Interfaces
[Synthesized from Boundaries Focus agent]
- Module boundaries
- Integration points
- External systems

## Testing Strategy
[Synthesized from Testing Focus agent]
- Frameworks and tools
- Conventions to follow
- Example tests

## Dependencies & Environment
[Synthesized from Dependencies Focus agent]
- Required packages
- External services
- Environment variables

## API Keys Status
| Service | Status | Notes |
|---------|--------|-------|
| [Service] | Available/Missing | [Details] |

## Key Files for This Feature
| File | Purpose | Relevance |
|------|---------|-----------|
| `path` | [Purpose] | [Why relevant] |

## Patterns to Follow
1. [Pattern]: [How to apply]
2. [Pattern]: [How to apply]

## Concerns & Risks
- [Concern]: [Mitigation]

## Recommendations
- [Recommendation]
```

### 2. Update CLAUDE.md (if needed)

If `CLAUDE.md` is missing or lacks key project information discovered during exploration:
- Create or update with project overview
- Document discovered patterns
- Add relevant commands
- Note key files

---

## Next Step

Phase 2 (Exploration) is complete.

Using AskUserQuestionTool, ask the user if they want to continue to Phase 3 of the workflow (the specification interview):

```
Phase 2 (Exploration) is complete.

Continue with Specification Interview?
```
