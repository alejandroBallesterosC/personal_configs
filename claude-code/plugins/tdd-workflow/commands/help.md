---
description: Show TDD workflow plugin help
model: haiku
---

# TDD Workflow Plugin Help

## Overview

This plugin implements a planning-heavy, TDD-driven development workflow with 6 phases:

1. **Explore** - Understand codebase, synthesize CLAUDE.md
2. **Plan** - Interview-based spec development (40+ questions)
3. **Architect** - Technical design from spec + exploration
4. **Review Plan** - Challenge assumptions, find gaps
5. **Implement** - TDD via ralph-loop (RED → GREEN → REFACTOR)
6. **Review** - Confidence-scored code review

## Commands

### `/tdd-workflow:explore <feature>`
Deep codebase analysis before planning.
- Analyzes architecture, patterns, related code
- Outputs to `docs/context/<feature>-exploration.md`
- Synthesizes or updates CLAUDE.md if missing/outdated

### `/tdd-workflow:plan <feature>`
Interview-based specification development.
- Asks ONE question at a time via AskUserQuestionTool
- Covers 9 domains: functionality, constraints, UI/UX, edge cases, security, testing, integration, performance, deployment
- Outputs to `docs/specs/<feature>.md` and `docs/plans/`

### `/tdd-workflow:architect <feature>`
Technical architecture design.
- Reads exploration context and specification
- Designs components, interfaces, data flow
- Outputs to `docs/plans/<feature>-arch.md`

### `/tdd-workflow:review-plan <feature>`
Critical review before implementation.
- Challenges assumptions and architectural decisions
- Asks follow-up questions for gaps
- Must resolve all blockers before implementation

### `/tdd-workflow:implement <feature> --max-iterations N`
TDD implementation using ralph-loop.
- Reads spec, plan, and architecture files
- Invokes ralph-loop with TDD prompt
- Enforces RED → GREEN → REFACTOR cycle
- Git commits at each phase transition

**Required**: `--max-iterations N` flag

### `/tdd-workflow:review`
Code review of implementation.
- Confidence-scored findings (reports only ≥80%)
- Checks: CLAUDE.md compliance, test coverage, security, spec compliance

## Dependencies

- **Required**: `ralph-loop` plugin must be installed
- **Optional**: Project test framework (pytest, jest, vitest, go, cargo)

## Example Full Workflow

```bash
/tdd-workflow:explore user-auth
/tdd-workflow:plan user-auth
/tdd-workflow:architect user-auth
/tdd-workflow:review-plan user-auth
/clear  # Start fresh session
/tdd-workflow:implement user-auth --max-iterations 20
/tdd-workflow:review
```
