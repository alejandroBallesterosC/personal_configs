# TDD Workflow Plugin

A fully orchestrated, planning-heavy TDD workflow for Claude Code with **parallel subagents** at every stage. Based on best practices from Boris Cherny, Thariq Shihab, Mo Bitar, and Geoffrey Huntley.

## Quick Start

```bash
/tdd-workflow:start user-authentication "Add user authentication with OAuth2 and JWT tokens"
```

This **single command** orchestrates the entire workflow automatically. You only respond when:
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
                    ══════ CONTEXT CHECKPOINT 1 ══════
                    (Save state → /clear → /resume)
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
                    ══════ CONTEXT CHECKPOINT 2 ══════
                    (Save state → /clear → /resume)
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
                    ══════ CONTEXT CHECKPOINT 3 ══════
                    (Save state → /clear → /resume)
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

Long workflows degrade in quality as context fills. This workflow includes **3 strategic context checkpoints** following community best practices.

### Why Clear Context?

> "Clear at 60k tokens or 30% context... The automatic compaction is opaque, error-prone, and not well-optimized." - Community Best Practices

### Checkpoints

| Checkpoint | After Phase | Reason |
|------------|-------------|--------|
| 1 | Exploration | Heavy read operations filled context |
| 2 | Plan Approval | Fresh start for implementation |
| 3 | E2E Testing | Fresh perspective for review |

### How It Works

1. Workflow **saves state** to `docs/workflow/<feature>-state.md`
2. User is prompted to run **`/clear`**
3. User runs **`/tdd-workflow:resume <feature>`** to continue
4. Context is **restored from files** and workflow continues

### State File

All progress tracked in `docs/workflow/<feature>-state.md`:
- Current phase
- Completed phases
- Key decisions
- Files to read for context restoration

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
- **Main instance runs tests** and validates results between subagent calls
- Context managed at orchestrator level for better quality
- **Real API implementations** preferred (mocks as fallback only)

### Orchestrated E2E Testing (Phase 7)
- **Main instance runs ralph-loop** for E2E test iteration
- Subagents fix specific failures when found
- **Main instance validates** after each fix
- Tests real integrations

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
- This follows Claude Code best practices for verification loops

### Real Implementations First
- Use actual APIs with real credentials
- Connect to real services
- Only mock when integration is truly impossible

### Strategic Parallelization
- Exploration: 5 agents simultaneously (read-only, safe to parallelize)
- Review: 5 agents simultaneously (read-only, safe to parallelize)
- Implementation: Sequential TDD cycles with orchestrator control
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
├── plans/
│   ├── <feature>-plan.md           # Implementation plan
│   └── <feature>-arch.md           # Architecture design
└── workflow/
    ├── <feature>-state.md          # Workflow state for resume
    └── <feature>-review.md         # Consolidated review findings
```

## Credits

Based on insights from:
- **Boris Cherny** (Anthropic): Parallel exploration, Opus for everything, shared CLAUDE.md
- **Thariq Shihab** (Anthropic): Interview-first spec development, fresh sessions
- **Mo Bitar**: Interrogation method, pushback on idealistic ideas
- **Geoffrey Huntley**: Ralph Wiggum autonomous loops
