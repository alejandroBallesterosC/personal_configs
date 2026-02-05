# TDD Workflow Plugin

A fully orchestrated, planning-heavy TDD workflow for Claude Code with **parallel subagents** at every stage. Based on best practices from Boris Cherny, Thariq Shihab, Mo Bitar, and Geoffrey Huntley.

## Quick Start

```bash
/tdd-workflow:1-start user-authentication "Add user authentication with OAuth2 and JWT tokens"
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
│ PHASE 2: PARALLEL EXPLORATION - /2-explore                                  │
│   Architecture │ Patterns │ Boundaries │ Testing │ Dependencies            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: SPECIFICATION INTERVIEW - /3-user-specification-interview          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: ARCHITECTURE DESIGN - /4-plan-architecture                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: IMPLEMENTATION PLAN - /5-plan-implementation                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: PLAN REVIEW & APPROVAL - /6-review-plan                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: ORCHESTRATED TDD - /7-implement                                    │
│   ralph-loop → test-designer → RUN TESTS → implementer → RUN TESTS → ...   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: ORCHESTRATED E2E - /8-e2e-test                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 9: REVIEW, FIXES & COMPLETION - /9-review                             │
│   Security │ Performance │ Code Quality │ Test Coverage │ Spec Compliance  │
│   (parallel review → orchestrated fixes → completion summary)               │
└─────────────────────────────────────────────────────────────────────────────┘

Context is managed automatically via hooks - no manual checkpoints needed.
```

## Commands

| Command | Purpose |
|---------|---------|
| `/tdd-workflow:1-start <name> "<description>"` | **Start full orchestrated workflow** |
| `/tdd-workflow:2-explore <name> "<description>"` | Parallel codebase exploration (5 agents) |
| `/tdd-workflow:3-user-specification-interview <name> "<description>"` | Specification interview (40+ questions) |
| `/tdd-workflow:4-plan-architecture <name>` | Technical architecture design |
| `/tdd-workflow:5-plan-implementation <name>` | Create implementation plan from architecture |
| `/tdd-workflow:6-review-plan <name>` | Challenge plan, find gaps |
| `/tdd-workflow:7-implement <name> "<description>"` | Parallel TDD implementation |
| `/tdd-workflow:8-e2e-test <name> "<description>"` | End-to-end testing |
| `/tdd-workflow:9-review <name>` | Parallel multi-aspect review (5 agents) |
| `/tdd-workflow:continue-workflow <name>` | **Continue an in-progress workflow** |
| `/tdd-workflow:help` | Show this help |

## Context Management

Long workflows degrade in quality as context fills. This workflow uses **automatic context preservation via hooks** following community best practices.

### Why Automatic Context Management?

> "Clear at 60k tokens or 30% context... The automatic compaction is opaque, error-prone, and not well-optimized." - Community Best Practices

### How It Works

Context is managed via two hooks:

1. **Stop hook** (agent): Before Claude stops responding, verifies the state file is up to date. If outdated, blocks Claude from stopping until the state file is updated.
2. **SessionStart hook** (command): After context reset (`/compact` or `/clear`), reads the state file and injects full context for seamless resume.

The main Claude instance is responsible for keeping `docs/workflow-<feature>/<feature>-state.md` current. The Stop hook enforces this by blocking Claude from stopping if the state file is stale.

This works for:
- **Auto-compaction / `/compact`**: Stop hook ensures state is current, SessionStart restores full context after
- **Manual `/clear`**: Stop hook ensures state is current, SessionStart restores full context after

### Manual Continuation

For scenarios where hooks don't fire (e.g., starting a fresh session):

```bash
/tdd-workflow:continue-workflow user-authentication
```

This command validates the workflow exists and is in progress, loads all context restoration files, and continues from the current phase.

### Auto-Context Preservation (Hooks)

| Hook | Event | Purpose |
|------|-------|---------|
| Stop (command) | After Claude responds | Runs tests after code changes |
| Stop (agent) | Before Claude stops | Verifies state file is up to date; blocks stopping if outdated |
| SessionStart (command) | After context reset | Reads state file, injects full context for seamless resume |

**State file verification criteria (enforced by Stop hook):**
- Phase accuracy matches actual work done
- Component accuracy (if in Phase 7/8)
- Next action reflects what should actually be done
- No stale progress from previous sessions
- Files modified list matches reality

**What happens after context reset:**
- Detects active workflow from `docs/workflow-*/*-state.md`
- Reads the **entire state file** and injects it into context
- Lists all relevant artifact files to read
- Claude continues the workflow automatically

### State File

All progress tracked in `docs/workflow-<feature>/<feature>-state.md`:
- Current phase
- Completed phases
- Key decisions
- Files to read for context restoration

## Key Features

### Parallel Exploration (Phase 2)
- **5 code-explorer agents** run simultaneously
- Each uses **Sonnet with 1M context window**
- Explores: Architecture, Patterns, Boundaries, Testing, Dependencies
- Identifies API keys availability

### Exhaustive Planning (Phases 3-6)
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

### Agents by Phase

| Phase | Agent(s) Used | How to Invoke |
|-------|---------------|---------------|
| Phase 2: Exploration | `code-explorer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-explorer"` |
| Phase 3: Interview | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 4: Architecture | `code-architect` (optional) | `Task tool with subagent_type: "tdd-workflow:code-architect"` |
| Phase 5: Plan | None (main instance) | Main instance creates plan from architecture |
| Phase 6: Review | `plan-reviewer` | `Task tool with subagent_type: "tdd-workflow:plan-reviewer"` |
| Phase 7: Implement | `test-designer`, `implementer`, `refactorer` | Via ralph-loop orchestration |
| Phase 8: E2E Test | `test-designer`, `implementer` | Via ralph-loop orchestration |
| Phase 9: Review | `code-reviewer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-reviewer"` |

## Skills

| Skill | Purpose |
|-------|---------|
| tdd-workflow-guide | Navigate workflow phases |
| testing | RED → GREEN → REFACTOR cycle |
| writing-plans | Parallelizable component design |
| using-git-worktrees | Feature branch isolation |

## Hooks

| Hook | Event | Type | Purpose |
|------|-------|------|---------|
| run-scoped-tests.sh | Stop | command | Run tests after Claude responds |
| State verification | Stop | agent | Verify state file is up to date; block stopping if outdated |
| auto-resume-after-compact-or-clear.sh | SessionStart | command | Inject context to resume workflow after context reset |

### Hook Files

```
hooks/
├── hooks.json                    # Hook configuration
├── run-scoped-tests.sh           # Scoped test runner (used by Stop hook)
├── detect-test-runner.sh         # Test framework detection
└── auto-resume-after-compact-or-clear.sh  # Context restoration hook
```

## Dependencies

- **Required**: `ralph-loop` plugin for TDD implementation loops
  ```bash
  /plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum
  ```
  **Warning:** Always set `--max-iterations` (50 iterations = $50-100+ in API costs)
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

All artifacts for a feature are stored in `docs/workflow-<feature>/`:

```
docs/workflow-<feature>/
├── <feature>-state.md                    # Workflow state (auto-managed by hooks)
├── <feature>-original-prompt.md          # Original user request
├── <feature>-review.md                   # Consolidated review findings
├── codebase-context/
│   └── <feature>-exploration.md          # Codebase analysis
├── specs/
│   └── <feature>-specs.md                # Full specification
└── plans/
    ├── <feature>-architecture-plan.md    # Architecture design
    ├── <feature>-implementation-plan.md  # Implementation plan
    └── <feature>-tests.md                # Test strategy
```

## Credits

Based on insights from:
- **Boris Cherny** (Anthropic): Parallel exploration, Opus for everything, shared CLAUDE.md
- **Thariq Shihab** (Anthropic): Interview-first spec development, fresh sessions
- **Mo Bitar**: Interrogation method, pushback on idealistic ideas
- **Geoffrey Huntley**: Ralph Wiggum autonomous loops
