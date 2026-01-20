---
description: Start the full TDD workflow with guided phases
model: opus
argument-hint: <feature description>
---

# TDD Workflow

Feature: **$ARGUMENTS**

This command initiates a planning-heavy, TDD-driven development workflow based on best practices from Boris Cherny, Thariq Shihab, Mo Bitar, and Geoffrey Huntley.

## Workflow Overview

```
EXPLORE → PLAN → ARCHITECT → REVIEW-PLAN → [FRESH SESSION] → IMPLEMENT → REVIEW
```

---

## Phase 1: EXPLORE (Codebase Understanding)

Before planning, I need to understand the codebase context. Use the code-explorer agent to:

1. **Analyze architecture** - Understand layers, boundaries, data flow
2. **Identify patterns** - Find existing conventions and idioms
3. **Find related code** - Locate similar features for reference
4. **Check test coverage** - Understand testing approach
5. **Review CLAUDE.md** - Synthesize or update if needed

### Output

Write exploration findings to: `docs/context/$ARGUMENTS-exploration.md`

### Relevant Commands
- `/tdd-workflow:explore $ARGUMENTS` - Run exploration separately

---

## Phase 2: PLAN (Interview-Based Specification)

Conduct a comprehensive planning interview using AskUserQuestionTool.

### Interview Domains (40+ questions)

Ask ONE question at a time, covering:

1. **Core Functionality** - What exactly should this feature do?
2. **Technical Constraints** - Performance, compatibility, dependencies?
3. **UI/UX Requirements** - User interactions, flows, states?
4. **Edge Cases** - What could go wrong? Unusual inputs?
5. **Security** - Authentication, authorization, data protection?
6. **Testing Requirements** - What must be tested? Acceptance criteria?
7. **Integration Points** - What systems does this interact with?
8. **Performance Requirements** - Latency, throughput, scale?
9. **Deployment Considerations** - Rollout strategy, feature flags?

### Key Principles

- Ask **NON-OBVIOUS** questions - challenge assumptions
- **Pushback on idealistic ideas** (Mo Bitar's approach)
- Continue until **complete clarity** on ALL aspects
- Record answers in the spec file

### Output

Write specification to: `docs/specs/$ARGUMENTS.md`
Write test cases to: `docs/plans/$ARGUMENTS-tests.md`

### Relevant Commands
- `/tdd-workflow:plan $ARGUMENTS` - Run planning separately

---

## Phase 3: ARCHITECT (Technical Design)

Design the technical architecture based on exploration + specification.

### Design Components

1. **Component breakdown** - What modules/classes/functions?
2. **Interface design** - APIs, function signatures, data contracts
3. **Data flow** - How does data move through the system?
4. **State management** - Where is state stored? How is it updated?
5. **Error handling** - What can fail? How to handle it?
6. **Testing strategy** - Unit, integration, e2e approach

### Output

Write architecture to: `docs/plans/$ARGUMENTS-arch.md`
Write implementation plan to: `docs/plans/$ARGUMENTS-plan.md`

### Relevant Commands
- `/tdd-workflow:architect $ARGUMENTS` - Run architecture separately

---

## Phase 4: REVIEW-PLAN (Challenge & Validate)

Critically review the plan before implementation.

### Review Areas

1. **Assumption challenges** - What are we assuming that might be wrong?
2. **Gap analysis** - What's missing from the spec or plan?
3. **Risk identification** - What could go wrong during implementation?
4. **Dependency validation** - Are all dependencies available?
5. **Test coverage** - Do test cases cover all requirements?

### Process

- Ask follow-up questions for any gaps
- Challenge architectural decisions
- Verify all blockers are resolved
- Get explicit user approval before proceeding

### Relevant Commands
- `/tdd-workflow:review-plan $ARGUMENTS` - Run review separately

---

## ⚠️ FRESH SESSION RECOMMENDED

> "Start a fresh session to execute the completed spec" - Thariq Shihab

Before implementation, recommend starting a fresh Claude Code session:

```
/clear
```

This prevents context pollution and lets implementation start clean with just the spec files.

---

## Phase 5: IMPLEMENT (TDD via Ralph Loop)

Execute strict Test-Driven Development using the ralph-loop plugin.

### TDD Cycle

For EACH requirement in the plan:

#### RED Phase
1. Write ONE failing test that defines expected behavior
2. Run tests, confirm failure
3. Commit: `git commit -m "red: test for [requirement]"`

#### GREEN Phase
1. Write MINIMAL code to pass the test
2. No extra features, no optimization
3. Run tests, confirm pass
4. Commit: `git commit -m "green: [requirement]"`

#### REFACTOR Phase
1. Improve code quality
2. Run tests after EACH change
3. If tests fail, undo immediately
4. Commit: `git commit -m "refactor: [description]"`

### Execution

```
/tdd-workflow:implement $ARGUMENTS --max-iterations 25
```

This invokes ralph-loop with the TDD prompt and iterates until complete.

### Relevant Commands
- `/tdd-workflow:implement $ARGUMENTS --max-iterations N` - Run implementation

---

## Phase 6: REVIEW (Code Quality Verification)

Comprehensive code review with confidence scoring.

### Review Checks

1. **CLAUDE.md Compliance** - Does code follow project conventions?
2. **Test Coverage** - Are all code paths tested?
3. **Security Review** - Any vulnerabilities introduced?
4. **Code Quality** - Clean, readable, maintainable?
5. **Spec Compliance** - Does implementation match specification?

### Output Format

Report findings with confidence scores (only ≥80% reported):

- **Critical** (must fix)
- **Warnings** (should fix)
- **Suggestions** (nice to have)

### Relevant Commands
- `/tdd-workflow:review` - Run code review

---

## Key Principles

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

1. **Front-load planning** - 40+ questions eliminate ambiguity
2. **Interview-first** - Claude asks YOU, not the other way around
3. **Fresh sessions** - Start clean for implementation
4. **Strict TDD** - RED → GREEN → REFACTOR, always
5. **Verify everything** - Tests run after every change

---

## Quick Reference

| Phase | Command | Output |
|-------|---------|--------|
| Explore | `/tdd-workflow:explore <feature>` | `docs/context/<feature>-exploration.md` |
| Plan | `/tdd-workflow:plan <feature>` | `docs/specs/<feature>.md` |
| Architect | `/tdd-workflow:architect <feature>` | `docs/plans/<feature>-arch.md` |
| Review Plan | `/tdd-workflow:review-plan <feature>` | Approval to proceed |
| Implement | `/tdd-workflow:implement <feature> --max-iterations N` | Working code + tests |
| Review | `/tdd-workflow:review` | Review report |

---

## Help Command
- `/tdd-workflow:help` - Show all TDD workflow commands

---

## Let's Begin!

Starting Phase 1: EXPLORE for **$ARGUMENTS**

I'll use the code-explorer agent to understand the codebase context before we begin planning.
