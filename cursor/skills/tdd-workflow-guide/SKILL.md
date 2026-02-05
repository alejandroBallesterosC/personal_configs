---
name: tdd-workflow-guide
description: Guide for using the TDD workflow. Activates when starting or navigating the TDD workflow phases.
---

# TDD Workflow Guide Skill

This skill provides **navigation guidance** for the TDD workflow's 8 phases (Phases 2-9). Based on practices from Boris Cherny (Claude Code creator), Thariq Shihab (Anthropic), Mo Bitar, and Geoffrey Huntley.

**Important:** This skill is the **source of truth** for understanding the workflow (overview, principles, context management, state file format). The command files (`1-start.md`, `7-implement.md`, etc.) contain the **execution instructions** only.

**IMPORTANT: Never use emojis in your codebase documentation, plans, specs, state file, code implementations, or test implementations**

## When to Activate

Activate when:
- User asks about the TDD workflow process
- User seems lost in the workflow
- Navigating between workflow phases
- User needs help understanding workflow phases

**Note:** When executing the workflow via `/1-start`, follow the instructions in that command directly - this skill is supplementary guidance.

**Announce at start:** "I'm using the tdd-workflow-guide skill to help navigate this workflow."


## Workflow Overview (8 Phases)

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
│   Security │ Performance │ Code Quality │ Test Coverage │ Spec Compliance   │
│   (parallel review → orchestrated fixes → completion summary)               │
└─────────────────────────────────────────────────────────────────────────────┘

Context is managed automatically via hooks - no manual checkpoints needed.
```

## Automatic Context Management

### Why Clear Context?

> "Clear at 60k tokens or 30% context... The automatic compaction is opaque, error-prone, and not well-optimized." - Community Best Practices

Long workflows degrade in quality as context fills. The TDD workflow uses **hooks for automatic context preservation**.

### How It Works

Context is managed via two hooks:

1. **Stop hook** (agent): Before Claude stops responding, verifies the state file is up to date. If outdated, blocks Claude from stopping until the state file is updated.
2. **SessionStart hook** (command): After context reset (`/compact` or `/clear`), reads the state file and injects full context for seamless resume.

**The key insight**: The main Claude instance is responsible for keeping `docs/workflow-<feature>/<feature>-state.md` current. The Stop hook enforces this by blocking Claude from stopping if the state file is stale.

### State File Verification Criteria

The Stop hook verifies the state file against these criteria:
- **Phase accuracy**: Current phase matches actual work done
- **Component accuracy**: Current component (if in Phase 7/8) is correctly identified
- **Next action accuracy**: Next action reflects what should actually be done (not something completed)
- **No stale progress**: Session progress doesn't describe work from a previous session
- **Files reflect reality**: Modified files list matches actual recent changes

If any criterion fails, Claude is blocked from stopping and must update the state file first.

### What Happens After Context Reset

After `/compact` or `/clear`:
1. **SessionStart hook** detects active workflow from `docs/workflow-*/*-state.md`
2. Reads the entire state file and injects it into context
3. Lists all relevant artifact files to read
4. Claude continues the workflow automatically

### Manual Continuation

For fresh sessions (not triggered by compaction/clear):
```bash
/continue-tdd-workflow <feature-name>
```

No specific phase or "checkpoint" required - works at any point in the workflow.

---

## Phase Details

**Note:** These summaries explain what each phase does. For **execution instructions**, see the individual phase commands (`2-explore.md`, `3-user-specification-interview.md`, etc.). The `1-start.md` command orchestrates all phases in sequence.

### Phase 2: PARALLEL EXPLORATION
**Purpose**: Understand the codebase from multiple angles simultaneously

**What happens**:
- 5 code-explorer agents run in parallel (Sonnet with 1M context)
- Each explores: Architecture, Patterns, Boundaries, Testing, Dependencies
- Identifies test command and API key availability

**Output**: `docs/workflow-<feature>/codebase-context/<feature>-exploration.md`

**Command**: `/2-explore <feature> "<description>"`

---

### Phase 3: SPECIFICATION INTERVIEW
**Purpose**: Create unambiguous specification through exhaustive questioning

**What happens**:
- Ask 40+ questions ONE AT A TIME via AskUserQuestionTool
- Cover 9 domains: functionality, constraints, integration, edge cases, security, testing, etc.
- Challenge assumptions, pushback on idealistic ideas

**Output**: `docs/workflow-<feature>/specs/<feature>-specs.md`

**Command**: `/3-user-specification-interview <feature> "<description>"`

---

### Phase 4: ARCHITECTURE DESIGN
**Purpose**: Create technical architecture from specification and exploration. For simple features/changes do it yourself, for complex features/changes use the code-architect agent to do this.

**What happens**:
- Technical design based on spec + exploration findings
- Define independent components for parallel implementation
- Architecture decisions documented
- Integration points identified

**Output**: `docs/workflow-<feature>/plans/<feature>-architecture-plan.md`

**Command**: `/4-plan-architecture <feature>`

---

### Phase 5: IMPLEMENTATION PLAN
**Purpose**: Create detailed implementation plan from the architecture

**What happens**:
- Read architecture from Phase 4
- Map architecture components to implementation tasks
- Define task dependencies for parallel implementation
- Create test strategy per component

**Output**:
- `docs/workflow-<feature>/plans/<feature>-implementation-plan.md`
- `docs/workflow-<feature>/plans/<feature>-tests.md`

**Command**: `/5-plan-implementation <feature>`

---

### Phase 6: PLAN REVIEW & APPROVAL
**Purpose**: Challenge, validate, and approve the plan before implementation

**What happens**:
- Plan-reviewer agent critically analyzes the plan
- Challenges assumptions, identifies gaps
- Asks clarifying questions via AskUserQuestionTool
- Gets explicit user approval to proceed

**Output**: Updated plans based on feedback + User approval

**Command**: `/6-review-plan <feature>`

**Critical**: DO NOT proceed to Phase 7 without explicit approval

---

### Phase 7: ORCHESTRATED TDD IMPLEMENTATION
**Purpose**: Implement components using TDD with main instance owning feedback loop

**What happens**:
- Main instance runs ralph-loop
- Spawns subagents for discrete tasks:
  - `test-designer`: Write ONE failing test (RED)
  - `implementer`: Write minimal code to pass (GREEN)
  - `refactorer`: Improve while keeping tests green
- Main instance runs tests after each subagent task

**Test Scope File**: The `.tdd-test-scope` file controls which tests run. It MUST be written to the **repository root** (where `.git/` lives). See the `testing` skill for format details.

**Output**: Working code with test coverage

**Command**: `/7-implement <feature> "<description>"`

---

### Phase 8: ORCHESTRATED E2E TESTING
**Purpose**: Verify all components work together

**What happens**:
- Main instance runs ralph-loop for E2E iteration
- test-designer writes E2E tests
- Subagents fix failures until all pass

**Output**: Passing E2E test suite

**Command**: `/8-e2e-test <feature> "<description>"`

---

### Phase 9: REVIEW, FIXES & COMPLETION
**Purpose**: Comprehensive review, fix critical issues, and complete workflow

**What happens**:
- **Part A - Parallel Review**: 5 code-reviewer agents run in parallel
  - Reviews: Security, Performance, Quality, Coverage, Spec Compliance
  - Only ≥80% confidence findings reported
- **Part B - Orchestrated Fixes**: Main instance runs ralph-loop
  - Subagents fix Critical and High severity issues
  - Tests verified after each fix
- **Part C - Completion Summary**: Final state file updated, completion report generated

**Output**: `docs/workflow-<feature>/<feature>-review.md`, completion report

**Command**: `/9-review <feature>`

---

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/1-start <name> "<desc>"` | Start full orchestrated workflow |
| `/2-explore <name> "<desc>"` | Parallel exploration (5 agents) |
| `/3-user-specification-interview <name> "<desc>"` | Specification interview (40+ questions) |
| `/4-plan-architecture <name>` | Technical architecture design |
| `/5-plan-implementation <name>` | Create implementation plan from architecture |
| `/6-review-plan <name>` | Challenge plan |
| `/7-implement <name> "<desc>"` | TDD implementation |
| `/8-e2e-test <name> "<desc>"` | E2E testing |
| `/9-review <name>` | Parallel review (5 agents) |
| `/continue-tdd-workflow <name>` | **Continue an in-progress workflow** |
| `/tdd-workflow-help` | Show help |

---

## Guiding Users Through Phases

### Starting the Workflow

When user invokes `/1-start <feature> "<description>"`:
1. The `1-start.md` command orchestrates all phases in sequence
2. Each phase references its individual command file for detailed execution instructions
3. The Stop hook verifies state file is up to date before Claude stops responding
4. After context reset (`/compact` or `/clear`), SessionStart hook restores context

### After Context Reset

When context is reset (`/compact`, `/clear`, or session restart):
1. The SessionStart hook automatically detects the active workflow
2. It reads the state file and injects full context
3. You should read the listed artifact files and continue the workflow
4. No manual command needed - just continue where you left off

### Starting a Fresh Session

If you're starting a fresh session (not triggered by compaction) and want to continue an in-progress workflow:

```bash
/continue-tdd-workflow <feature-name>
```

This command:
1. Validates the workflow exists and is in progress (errors if not found or already complete)
2. Loads all context restoration files (state, spec, plan, architecture, exploration)
3. Summarizes current state and continues from the current phase

### Phase Transitions

After completing each phase:

```markdown
## Phase [N] Complete

[Summary of what was accomplished]

### Output Files
- [list of files created]

### Next Step
Continuing with Phase [N+1]...
```

### Phase Completion

When completing a phase, simply confirm completion and continue:

```markdown
## Phase [N] Complete

[Summary of what was accomplished]

Continuing with Phase [N+1]...
```

Context management is handled automatically by hooks - no special action required.

---

## Key Quotes

> "A good plan is really important to avoid issues down the line." - Boris Cherny

> "Start a fresh session to execute the completed spec." - Thariq Shihab

> "Ask questions in all caps, record answers, cover feature, UX, UI, architecture, API, security, edge cases, test requirements, and pushback on idealistic ideas." - Mo Bitar

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

---

## Agents by Phase

| Phase | Agent(s) Used | How to Invoke |
|-------|---------------|---------------|
| Phase 2: Exploration | `code-explorer` (5x parallel) | `Task tool with subagent_type: "code-explorer"` |
| Phase 3: Interview | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 4: Architecture | `code-architect` (optional) | `Task tool with subagent_type: "code-architect"` |
| Phase 5: Plan | None (main instance) | Main instance creates plan from architecture |
| Phase 6: Review | `plan-reviewer` | `Task tool with subagent_type: "plan-reviewer"` |
| Phase 7: Implement | `test-designer`, `implementer`, `refactorer` | Via ralph-loop orchestration |
| Phase 8: E2E Test | `test-designer`, `implementer` | Via ralph-loop orchestration |
| Phase 9: Review | `code-reviewer` (5x parallel) | `Task tool with subagent_type: "code-reviewer"` |

---

## Key Principles

These principles guide all phases of the workflow:

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

> "Clear at 60k tokens or 30% context... don't wait for limits." - Community Best Practices

1. **Orchestrator owns the feedback loop** - Main instance runs ralph-loop and tests, subagents do discrete tasks
2. **Strategic parallelization** - Parallel for read-only work (exploration, review), sequential for implementation
3. **Real integrations first** - Only mock when real integration is truly impossible
4. **Verify continuously** - Main instance runs tests after every subagent task
5. **Front-load planning** - Thorough questioning eliminates implementation rework
6. **Automatic context management** - Stop hook enforces state file accuracy, SessionStart hook restores context after reset
7. **Automatic orchestration** - User only provides input when needed

---

## State File Format

All progress is tracked in `docs/workflow-<feature>/<feature>-state.md`:

```markdown
# Workflow State: <feature>

## Current Phase
[Phase number and name]

## Feature
- **Name**: <feature>
- **Description**: <description>

## Completed Phases
- [x] Phase 2: Exploration
- [ ] Phase 3: Interview
...

## Key Decisions
- [Decision 1]
- [Decision 2]

## Session Progress (Auto-saved)
- **Phase**: [current phase]
- **Component**: [if applicable]
- **Requirement**: [if applicable]
- **Next Action**: [specific next step]

## Context Restoration Files
Read these files to restore context:
1. Use the tdd-workflow-guide skill if needed
2. docs/workflow-<feature>/<feature>-state.md (this file)
3. docs/workflow-<feature>/<feature>-original-prompt.md
4. docs/workflow-<feature>/codebase-context/<feature>-exploration.md
5. docs/workflow-<feature>/specs/<feature>-specs.md
6. docs/workflow-<feature>/plans/<feature>-architecture-plan.md
7. docs/workflow-<feature>/plans/<feature>-implementation-plan.md
8. CLAUDE.md
```

---

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

---

## Dependencies

- **Required**: `/ralph-loop` command for Phases 7, 8, 9 (built-in via cursor commands)
  **Warning:** Always set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test)

## Integration with Debug Workflow

If bugs are discovered during implementation or review:

```
/debug <bug description>
```

This switches to the hypothesis-driven debugging workflow.
