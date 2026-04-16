---
description: Show dev workflow plugin help (TDD implementation + debug workflows)
model: haiku
---

# Dev Workflow Plugin Help

A unified development workflow plugin combining **TDD implementation workflow** and **hypothesis-driven debugging**.

---

## TDD Implementation Workflow

### Quick Start

```bash
/dev-workflow:1-start-tdd-implementation user-authentication "Add user authentication with OAuth2 and JWT tokens"
```

This **single command** orchestrates the entire 8-phase TDD implementation workflow (Phases 2-9) automatically. You only respond when:
- Questions need your answers
- Plans need your approval
- Decisions require your input

### TDD Phases

```
EXPLORE -> INTERVIEW -> ARCHITECTURE -> PLAN -> REVIEW -> IMPLEMENT -> E2E TEST -> REVIEW
```

### TDD Implementation Commands

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-tdd-implementation <name> "<description>"` | **Start full orchestrated workflow** |
| `/dev-workflow:2-explore <name> "<description>"` | Parallel codebase exploration (5 agents) |
| `/dev-workflow:3-user-specification-interview <name> "<description>"` | Specification interview (40+ questions) |
| `/dev-workflow:4-plan-architecture <name>` | Technical architecture design |
| `/dev-workflow:5-plan-implementation <name>` | Create implementation plan from architecture |
| `/dev-workflow:6-review-plan <name>` | Challenge plan, find gaps |
| `/dev-workflow:7-implement <name> "<description>"` | Parallel TDD implementation |
| `/dev-workflow:8-e2e-test <name> "<description>"` | End-to-end testing |
| `/dev-workflow:9-review <name>` | Parallel multi-aspect review (5 agents) |

### TDD Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| code-explorer | Sonnet (1M) | Deep codebase exploration with focus areas |
| code-architect | Opus | Technical design from spec + exploration |
| plan-reviewer | Opus | Challenge assumptions, find gaps |
| test-designer | Opus | Write failing tests (RED phase) |
| implementer | Sonnet | Minimal code to pass tests (GREEN phase) |
| refactorer | Sonnet | Improve while keeping tests green |
| code-reviewer | Sonnet (1M) | Multi-aspect review with focus areas |

### TDD Skills

| Skill | Purpose |
|-------|---------|
| tdd-implementation-workflow-guide | Navigate workflow phases |
| testing | RED -> GREEN -> REFACTOR cycle |
| writing-plans | Parallelizable component design |
| using-git-worktrees | Feature branch isolation |

---

## Debug Workflow

### Quick Start

```bash
# Start full debug workflow
/dev-workflow:1-start-debug "Login fails with 500 error for users with special characters in email"

# Or step through manually
/dev-workflow:2-explore-debug authentication
/dev-workflow:4-hypothesize login-bug
/dev-workflow:5-instrument login-bug
# [user reproduces bug, logs captured to logs/debug-output.log]
/dev-workflow:7-analyze login-bug
/dev-workflow:9-verify login-bug
```

### Debug Phases

```
EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> VERIFY -> CLEAN
```

### Debug Commands

| Command | Purpose |
|---------|---------|
| `/dev-workflow:1-start-debug <bug description>` | **Start full debug workflow** |
| `/dev-workflow:2-explore-debug <area>` | Phase 2: Explore codebase for context |
| `/dev-workflow:4-hypothesize <bug-name>` | Phase 4: Generate ranked hypotheses |
| `/dev-workflow:5-instrument <bug-name>` | Phase 5: Add debug logging |
| `/dev-workflow:7-analyze <bug-name>` | Phase 7: Analyze log output |
| `/dev-workflow:9-verify <bug-name>` | Phases 9-10: Verify fix and cleanup |

### Debug Agents

| Agent | Purpose |
|-------|---------|
| debug-explorer | Explore codebase for bug context |
| hypothesis-generator | Generate ranked hypotheses |
| instrumenter | Add targeted debug logging |
| log-analyzer | Analyze logs against hypotheses |

### Debug Skills

| Skill | Purpose |
|-------|---------|
| debug-workflow-guide | Source of truth for workflow navigation, phases, state file format |
| structured-debug | Debugging methodology: instrumentation patterns, anti-patterns |

---

## Shared Commands

| Command | Purpose |
|---------|---------|
| `/dev-workflow:continue-workflow <name>` | **Continue any in-progress workflow** (detects TDD vs debug) |
| `/dev-workflow:compare-branches <target-branch>` | Parallel branch comparison using 5 subagents |
| `/dev-workflow:review-learnings` | Synthesize accumulated learnings from TDD and debug sessions |
| `/dev-workflow:record-feedback <name>` | Record user feedback about a completed workflow |
| `/dev-workflow:help` | Show this help |

## Context Management

Context is managed **automatically via hooks** - no manual intervention needed.

| Hook | Event | Type | Purpose |
|------|-------|------|---------|
| tdd-implementation-gate.sh | Stop | command | Blocks stop during Phases 7-9, re-feeds command after compaction |
| archive-completed-workflows.sh | Stop | command | Auto-archives completed workflows to `.plugin-state/archive/` |
| run-scoped-tests.sh | Stop | command | Run tests after code changes |
| auto-resume | SessionStart | command | Reads state file, injects context to resume (checks both TDD and debug) |

### Manual Continuation

For fresh sessions (not triggered by compaction/clear):

```bash
/dev-workflow:continue-workflow <feature-or-bug-name>
```

## Dependencies

- **Required**: `yq` and `jq` (YAML/JSON parsing for hooks)
  ```bash
  brew install yq jq  # macOS
  ```
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test, etc.)

## Artifacts

### TDD Artifacts
```
.plugin-state/workflow-<feature>/
├── <feature>-state.md
├── <feature>-original-prompt.md
├── <feature>-review.md
├── codebase-context/<feature>-exploration.md
├── specs/<feature>-specs.md
└── plans/
    ├── <feature>-architecture-plan.md
    ├── <feature>-implementation-plan.md
    └── <feature>-tests.md
```

### Debug Artifacts
```
.plugin-state/debug/<bug-name>/
├── <bug-name>-state.md
├── <bug-name>-bug.md
├── <bug-name>-exploration.md
├── <bug-name>-hypotheses.md
├── <bug-name>-analysis.md
└── <bug-name>-resolution.md
```
