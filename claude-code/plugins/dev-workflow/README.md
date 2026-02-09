# Dev Workflow Plugin

A unified development workflow plugin combining **TDD implementation workflow** and **hypothesis-driven debugging** for Claude Code. Based on best practices from Boris Cherny, Thariq Shihab, Mo Bitar, Geoffrey Huntley, Cursor's Debug Mode, and Anthropic's engineering team.

## Quick Start

### TDD Implementation Workflow

```bash
/dev-workflow:1-start-tdd-implementation user-authentication "Add user authentication with OAuth2 and JWT tokens"
```

This **single command** orchestrates the entire TDD implementation workflow automatically. You only respond when questions need answers, plans need approval, or decisions require input.

### Debug Workflow

```bash
# Start full debug workflow
/dev-workflow:1-start-debug "API returns 500 error when user has emoji in name"

# Or step through manually
/dev-workflow:1-explore-debug user-api
/dev-workflow:3-hypothesize emoji-bug
/dev-workflow:4-instrument emoji-bug
# [user reproduces bug, logs captured to logs/debug-output.log]
/dev-workflow:6-analyze emoji-bug
/dev-workflow:8-verify emoji-bug
```

## TDD Workflow (Phases 2-9)

```
EXPLORE -> INTERVIEW -> ARCHITECTURE -> PLAN -> REVIEW -> IMPLEMENT -> E2E TEST -> REVIEW
```

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-tdd-implementation <name> "<desc>"` | **Start full orchestrated workflow** |
| `/dev-workflow:2-explore <name> "<desc>"` | Parallel codebase exploration (5 agents) |
| `/dev-workflow:3-user-specification-interview <name> "<desc>"` | Specification interview (40+ questions) |
| `/dev-workflow:4-plan-architecture <name>` | Technical architecture design |
| `/dev-workflow:5-plan-implementation <name>` | Create implementation plan from architecture |
| `/dev-workflow:6-review-plan <name>` | Challenge plan, find gaps |
| `/dev-workflow:7-implement <name> "<desc>"` | Parallel TDD implementation |
| `/dev-workflow:8-e2e-test <name> "<desc>"` | End-to-end testing |
| `/dev-workflow:9-review <name>` | Parallel multi-aspect review (5 agents) |

### Key Features

- **Parallel Exploration** (Phase 2): 5 code-explorer agents run simultaneously with Sonnet (1M context)
- **Exhaustive Planning** (Phases 3-6): 40+ interview questions, plan designed for parallel implementation, user approval before coding
- **Orchestrated TDD** (Phase 7): Main instance runs ralph-loop, subagents do discrete tasks, main runs tests between
- **Orchestrated E2E** (Phase 8): Main instance runs ralph-loop for E2E test iteration
- **Parallel Review** (Phase 9): 5 code-reviewer agents simultaneously, only >=80% confidence findings reported

## Debug Workflow (9 Phases)

```
EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> VERIFY -> CLEAN
```

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-debug <bug>` | **Start full debug workflow** |
| `/dev-workflow:1-explore-debug <area>` | Phase 1: Explore codebase for context |
| `/dev-workflow:3-hypothesize <name>` | Phase 3: Generate ranked hypotheses |
| `/dev-workflow:4-instrument <name>` | Phase 4: Add debug logging |
| `/dev-workflow:6-analyze <name>` | Phase 6: Analyze log output |
| `/dev-workflow:8-verify <name>` | Phases 8-9: Verify fix and cleanup |

### Key Features

- **File-based log capture**: Instrumentation writes to `logs/debug-output.log` (overwritten on each app run). Claude reads the file directly after reproduction — no copy/paste needed.
- **Hypothesis-driven**: 3-5 ranked theories with tagged instrumentation (`[DEBUG-H1]`)
- **Human verification gates**: Phases 2 (describe), 5 (reproduce), 8 (verify fix)
- **3-Fix Rule**: After 3 failed fixes, question the architecture
- **Loopback flows**: Rejected hypotheses loop to Phase 3; failed fixes loop to Phase 6

## Shared

| Command | Purpose |
|---------|---------|
| `/dev-workflow:continue-workflow <name>` | **Continue any in-progress workflow** (detects TDD vs debug) |
| `/dev-workflow:help` | Show help |

## Context Management

Long workflows degrade in quality as context fills. This plugin uses **automatic context preservation via hooks**.

### Hooks

| Hook | Event | Type | Purpose |
|------|-------|------|---------|
| archive-completed-workflows.sh | Stop | command | Auto-archives completed workflows to `docs/archive/` |
| run-scoped-tests.sh | Stop | command | Runs tests after code changes |
| State verification | Stop | agent | Verifies state files are up to date; blocks stopping if outdated |
| auto-resume | SessionStart | command | Restores context after `/compact` or `/clear` (checks both TDD and debug) |

The unified Stop hook checks both `docs/workflow-*/*-state.md` (TDD) and `docs/debug/*/*-state.md` (debug) for stale state.

The unified SessionStart hook detects which workflow type is active and injects the appropriate context.

### Manual Continuation

For fresh sessions (not triggered by compaction/clear):

```bash
/dev-workflow:continue-workflow user-authentication  # TDD
/dev-workflow:continue-workflow emoji-bug             # Debug
```

## Agents

### TDD Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| code-explorer | Sonnet (1M) | Deep codebase exploration with focus areas |
| code-architect | Opus | Technical design from spec + exploration |
| plan-reviewer | Opus | Challenge assumptions, find gaps |
| test-designer | Opus | Write failing tests (RED phase) |
| implementer | Opus | Minimal code to pass tests (GREEN phase) |
| refactorer | Opus | Improve while keeping tests green |
| code-reviewer | Sonnet (1M) | Multi-aspect review with focus areas |

### Debug Agents

| Agent | Purpose |
|-------|---------|
| debug-explorer | Codebase exploration and context gathering |
| hypothesis-generator | Generate testable theories about root cause |
| instrumenter | Add surgical debug logging |
| log-analyzer | Match logs to hypotheses |

## Skills

| Skill | Purpose |
|-------|---------|
| tdd-implementation-workflow-guide | Navigate TDD implementation workflow phases |
| testing | RED -> GREEN -> REFACTOR cycle |
| writing-plans | Parallelizable component design |
| using-git-worktrees | Feature branch isolation |
| debug-workflow-guide | Navigate debug workflow phases |
| structured-debug | Debugging methodology and techniques |

## Dependencies

- **Required for hooks**: `yq` and `jq` (YAML/JSON parsing for state management hooks)
  ```bash
  brew install yq jq  # macOS
  ```
  Hooks fail loudly with install instructions if these are missing.
- **Required for TDD**: `ralph-loop` plugin for implementation loops
  ```bash
  /plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum
  ```
  **Warning:** Always set `--max-iterations` (50 iterations = $50-100+)
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test, etc.)

## Artifacts

### TDD Artifacts

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

### Debug Artifacts

```
docs/debug/<bug-name>/
├── <bug-name>-state.md          # Session state (auto-managed by hooks)
├── <bug-name>-bug.md            # Bug description and repro steps
├── <bug-name>-exploration.md    # Codebase exploration findings
├── <bug-name>-hypotheses.md     # Ranked hypotheses
├── <bug-name>-analysis.md       # Log analysis results
└── <bug-name>-resolution.md     # Final resolution summary
```

## Philosophy

### Orchestrator Owns the Feedback Loop
- **Main instance runs ralph-loop** for TDD cycles
- Subagents are **stateless workers** that do one task and return
- Main instance **runs tests and validates** results
- Context managed at orchestrator level, not buried in subagents

### The Iron Law (Debug)
> **NO FIXES WITHOUT ROOT CAUSE PROVEN FIRST**

### Real Implementations First
- Use actual APIs with real credentials
- Connect to real services
- Only mock when integration is truly impossible

### Strategic Parallelization
- Exploration: 5 agents simultaneously (read-only, safe)
- Review: 5 agents simultaneously (read-only, safe)
- Implementation: Sequential TDD with orchestrator control
- Debugging: Sequential hypothesis testing

## Credits

Based on insights from:
- **Boris Cherny** (Anthropic): Parallel exploration, Opus for everything, shared CLAUDE.md
- **Thariq Shihab** (Anthropic): Interview-first spec development, fresh sessions
- **Mo Bitar**: Interrogation method, pushback on idealistic ideas
- **Geoffrey Huntley**: Ralph Wiggum autonomous loops
- **Cursor**: Debug Mode approach
- **@obra/superpowers**: Systematic debugging skill
- **Nathan Onn**: Stop arguing with your AI, visibility methods
