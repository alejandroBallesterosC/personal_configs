---
description: Show TDD workflow plugin help
model: haiku
---

# TDD Workflow Plugin Help

## Quick Start

```bash
/tdd-workflow:start user-authentication "Add user authentication with OAuth2 and JWT tokens"
```

This **single command** orchestrates the entire 10-phase workflow automatically. You only respond when:
- Questions need your answers
- Plans need your approval
- Decisions require your input

## Arguments

The workflow takes **two arguments**:
1. **Feature name**: Short identifier (e.g., `user-auth`)
2. **Feature description**: Detailed description of what to implement

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: PARALLEL EXPLORATION (5 code-explorer agents with 1M context)     │
│   Architecture │ Patterns │ Boundaries │ Testing │ Dependencies            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: SPECIFICATION INTERVIEW (40+ questions via AskUserQuestionTool)   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: PLAN CREATION (plan mode - parallelizable components)             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: PLAN REVIEW (plan-reviewer asks clarifying questions)             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: PLAN APPROVAL (user approves or requests changes)                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: ORCHESTRATED TDD (main instance runs ralph-loop, owns feedback)   │
│   ralph-loop → test-designer → RUN TESTS → implementer → RUN TESTS → ...   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: ORCHESTRATED E2E (main instance runs tests, subagents fix issues) │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: PARALLEL REVIEW (5 code-reviewer agents with 1M context)          │
│   Security │ Performance │ Code Quality │ Test Coverage │ Spec Compliance  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 9: ORCHESTRATED FIXES (main runs ralph-loop, subagents fix issues)   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 10: COMPLETION SUMMARY                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Commands

| Command | Purpose |
|---------|---------|
| `/tdd-workflow:start <name> "<description>"` | **Start full orchestrated workflow** |
| `/tdd-workflow:resume <name> [--phase N]` | **Resume workflow after /clear** |
| `/tdd-workflow:explore <name> "<description>"` | Parallel codebase exploration (5 agents) |
| `/tdd-workflow:plan <name> "<description>"` | Interview-based spec development |
| `/tdd-workflow:architect <name>` | Technical design from spec |
| `/tdd-workflow:review-plan <name>` | Challenge plan, find gaps |
| `/tdd-workflow:implement <name> "<description>"` | Parallel TDD implementation |
| `/tdd-workflow:e2e-test <name> "<description>"` | End-to-end testing |
| `/tdd-workflow:review <name>` | Parallel multi-aspect review (5 agents) |
| `/tdd-workflow:help` | Show this help |

## Context Management

The workflow includes **3 strategic context checkpoints** where you'll be prompted to run `/clear`:

| Checkpoint | After | Why Clear |
|------------|-------|-----------|
| **1** | Phase 1 (Exploration) | Heavy read operations filled context |
| **2** | Phase 5 (Plan Approval) | Planning complete, fresh start for implementation |
| **3** | Phase 7 (E2E Testing) | Implementation complete, fresh perspective for review |

### How It Works

1. **State is saved** to `docs/workflow/<feature>-state.md`
2. **You run** `/clear` to clear context
3. **You run** `/tdd-workflow:resume <feature>` to restore and continue

### Why This Matters

> "Clear at 60k tokens or 30% context... The automatic compaction is opaque, error-prone, and not well-optimized." - Community Best Practices

Strategic clearing maintains output quality throughout long workflows.

## Key Features

### Parallel Exploration (Phase 1)
- **5 code-explorer agents** run simultaneously
- Each uses **Sonnet with 1M context window**
- Explores: Architecture, Patterns, Boundaries, Testing, Dependencies
- Identifies API keys availability

### Exhaustive Planning (Phases 2-5)
- **40+ interview questions** across 9 domains
- Plan designed for **parallel component implementation**
- Plan reviewer challenges assumptions
- User approval before implementation

### Orchestrated TDD Implementation (Phase 6)
- **Main instance runs ralph-loop** to own the feedback loop
- **Subagents do discrete tasks**: write ONE test, implement ONE fix, refactor
- **Main instance runs tests** and validates between subagent calls
- Context managed at orchestrator level for quality
- **Real API implementations** preferred (mocks as fallback only)

### Orchestrated E2E Testing (Phase 7)
- **Main instance runs ralph-loop** for E2E test iteration
- Subagents fix specific failures when found
- **Main instance validates** after each fix

### Parallel Review (Phase 8)
- **5 code-reviewer agents** run simultaneously
- Each uses **Sonnet with 1M context window**
- Reviews: Security, Performance, Quality, Coverage, Spec Compliance
- Only ≥80% confidence findings reported

### Orchestrated Final Fixes (Phase 9)
- **Main instance runs ralph-loop** to address critical findings
- Subagents implement specific fixes
- **Main instance verifies** all tests pass after each fix

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| code-explorer | Sonnet (1M) | Deep codebase exploration with focus areas |
| code-architect | Opus | Technical design from spec + exploration |
| plan-reviewer | Opus | Challenge assumptions, find gaps |
| test-designer | Opus | Write failing tests (RED phase) |
| implementer | Opus | Minimal code to pass tests (GREEN phase) |
| refactorer | Opus | Improve while keeping tests green |
| code-reviewer | Sonnet (1M) | Multi-aspect review with focus areas |

## Skills

| Skill | Purpose |
|-------|---------|
| tdd-workflow-guide | Navigate workflow phases |
| tdd-guide | RED → GREEN → REFACTOR cycle |
| writing-plans | Parallelizable component design |
| writing-claude-md | CLAUDE.md best practices |
| infrastructure-as-code | Terraform + AWS patterns |
| using-git-worktrees | Feature branch isolation |

## Dependencies

- **Required**: `ralph-loop` plugin for TDD implementation loops
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test, etc.)

## Philosophy

### Orchestrator Owns the Feedback Loop
- **Main instance runs ralph-loop** for TDD cycles
- Subagents are **stateless workers** that do one task and return
- Main instance **runs tests and validates** results
- Context managed at orchestrator level, not buried in subagents

### Real Implementations First
- Use actual APIs with real credentials
- Connect to real services
- Only mock when integration is truly impossible

### Strategic Parallelization
- Exploration: 5 agents simultaneously (read-only, safe)
- Review: 5 agents simultaneously (read-only, safe)
- Implementation: Sequential TDD with orchestrator control
- Fixes: Sequential with orchestrator validation

### Verify Continuously
- Tests run after every code change
- E2E tests verify full integration
- Reviews catch issues before completion

### Front-Load Planning
- 40+ questions eliminate ambiguity
- Plan designed for parallelization
- User approves before implementation

## Artifacts Created

```
docs/
├── context/
│   └── <feature>-exploration.md    # Codebase analysis
├── specs/
│   └── <feature>.md                # Full specification
└── plans/
    ├── <feature>-plan.md           # Implementation plan
    └── <feature>-arch.md           # Architecture design
```
