---
name: tdd-workflow-guide
description: Guide for using the TDD workflow plugin. Activates when starting or navigating the TDD workflow phases.
---

# TDD Workflow Guide Skill

This skill provides **navigation guidance** for the TDD workflow plugin's 8 phases (Phases 2-9). Based on practices from Boris Cherny (Claude Code creator), Thariq Shihab (Anthropic), Mo Bitar, and Geoffrey Huntley.

**Important:** This skill is for understanding and navigating the workflow. For **detailed execution instructions** (agent prompts, ralph-loop invocations, interview questions), see:
`claude-code/plugins/tdd-workflow/commands/1-start.md`

## When to Activate

Activate when:
- User asks about the TDD workflow process
- User seems lost in the workflow
- Navigating between workflow phases
- User needs help understanding workflow phases

**Note:** When executing the workflow via `/tdd-workflow:1-start`, follow the instructions in that command directly - this skill is supplementary guidance.

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

Long workflows degrade in quality as context fills. This plugin uses **hooks for automatic context preservation**.

### How It Works

Context is managed **automatically** via hooks - no manual commands needed:

1. **PreCompact hook** (agent): Before any compaction, extracts and saves session progress to `docs/workflow/<feature>-state.md`
2. **SessionStart hook** (command): After compaction, reads the state file and injects full context for seamless resume

**What gets auto-saved:**
- Current phase, component, and requirement
- Session progress and key decisions
- Blockers and issues
- Files modified
- Next action to take

**What happens after compaction:**
- Detects active workflow from `docs/workflow/*-state.md`
- Reads the entire state file and injects it into context
- Lists all relevant artifact files to read
- Claude continues the workflow automatically

This works for:
- **Auto-compaction**: When context fills up during long sessions
- **Manual `/clear`**: When you optionally want to reset context

### How Context Preservation Works

Regardless of when or how context is cleared:
1. **PreCompact hook** saves state to `docs/workflow/<feature>-state.md` before compaction
2. **SessionStart hook** restores context after compaction
3. **Workflow continues** automatically from where it left off

No specific phase or "checkpoint" required - works at any point in the workflow.

---

## Phase Details

**Note:** These are summaries for understanding the workflow. For detailed execution instructions, see the corresponding `## PHASE N` sections in `1-start.md`.

### Phase 2: PARALLEL EXPLORATION
**Purpose**: Understand the codebase from multiple angles simultaneously

**What happens**:
- 5 code-explorer agents run in parallel (Sonnet with 1M context)
- Each explores: Architecture, Patterns, Boundaries, Testing, Dependencies
- Identifies test command and API key availability

**Output**: `docs/context/<feature>-exploration.md`

**Command**: `/tdd-workflow:2-explore <feature> "<description>"`

---

### Phase 3: SPECIFICATION INTERVIEW
**Purpose**: Create unambiguous specification through exhaustive questioning

**What happens**:
- Ask 40+ questions ONE AT A TIME via AskUserQuestionTool
- Cover 9 domains: functionality, constraints, integration, edge cases, security, testing, etc.
- Challenge assumptions, pushback on idealistic ideas

**Output**: `docs/specs/<feature>.md`

**Command**: `/tdd-workflow:3-user-specification-interview <feature> "<description>"`

---

### Phase 4: ARCHITECTURE DESIGN
**Purpose**: Create technical architecture from specification and exploration. For simple features/changes do it yourself, for complex features/changes use the code-architect agent to do this.

**What happens**:
- Technical design based on spec + exploration findings
- Define independent components for parallel implementation
- Architecture decisions documented
- Integration points identified

**Output**: `docs/plans/<feature>-arch.md`

**Command**: `/tdd-workflow:4-plan-architecture <feature>`

---

### Phase 5: IMPLEMENTATION PLAN
**Purpose**: Create detailed implementation plan from the architecture

**What happens**:
- Read architecture from Phase 4
- Map architecture components to implementation tasks
- Define task dependencies for parallel implementation
- Create test strategy per component

**Output**:
- `docs/plans/<feature>-plan.md`
- `docs/plans/<feature>-tests.md`

**Command**: `/tdd-workflow:5-plan-implementation <feature>`

---

### Phase 6: PLAN REVIEW & APPROVAL
**Purpose**: Challenge, validate, and approve the plan before implementation

**What happens**:
- Plan-reviewer agent critically analyzes the plan
- Challenges assumptions, identifies gaps
- Asks clarifying questions via AskUserQuestionTool
- Gets explicit user approval to proceed

**Output**: Updated plans based on feedback + User approval

**Command**: `/tdd-workflow:6-review-plan <feature>`

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

**Output**: Working code with test coverage

**Command**: `/tdd-workflow:7-implement <feature> "<description>"`

---

### Phase 8: ORCHESTRATED E2E TESTING
**Purpose**: Verify all components work together

**What happens**:
- Main instance runs ralph-loop for E2E iteration
- test-designer writes E2E tests
- Subagents fix failures until all pass

**Output**: Passing E2E test suite

**Command**: `/tdd-workflow:8-e2e-test <feature> "<description>"`

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

**Output**: `docs/workflow/<feature>-review.md`, completion report

**Command**: `/tdd-workflow:9-review <feature>`

---

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/tdd-workflow:1-start <name> "<desc>"` | Start full orchestrated workflow |
| `/tdd-workflow:2-explore <name> "<desc>"` | Parallel exploration (5 agents) |
| `/tdd-workflow:3-user-specification-interview <name> "<desc>"` | Specification interview (40+ questions) |
| `/tdd-workflow:4-plan-architecture <name>` | Technical architecture design |
| `/tdd-workflow:5-plan-implementation <name>` | Create implementation plan from architecture |
| `/tdd-workflow:6-review-plan <name>` | Challenge plan |
| `/tdd-workflow:7-implement <name> "<desc>"` | TDD implementation |
| `/tdd-workflow:8-e2e-test <name> "<desc>"` | E2E testing |
| `/tdd-workflow:9-review <name>` | Parallel review (5 agents) |
| `/tdd-workflow:help` | Show help |

---

## Guiding Users Through Phases

### Starting the Workflow

When user invokes `/tdd-workflow:1-start <feature> "<description>"`:
1. The `1-start.md` command contains all execution instructions
2. Follow the phases sequentially as defined in `1-start.md`
3. State is saved automatically by hooks whenever context is compacted
4. If context is cleared (manually or by auto-compact), hooks restore context

### After Context Clear or Compaction

When context is cleared or compacted:
1. The SessionStart hook automatically detects the active workflow
2. It reads the state file and injects full context
3. You should read the listed artifact files and continue the workflow
4. No manual command needed - just continue where you left off

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
| Phase 2: Exploration | `code-explorer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-explorer"` |
| Phase 3: Interview | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 4: Architecture | `code-architect` (optional) | `Task tool with subagent_type: "tdd-workflow:code-architect"` |
| Phase 5: Plan | None (main instance) | Main instance creates plan from architecture |
| Phase 6: Review | `plan-reviewer` | `Task tool with subagent_type: "tdd-workflow:plan-reviewer"` |
| Phase 7: Implement | `test-designer`, `implementer`, `refactorer` | Via ralph-loop orchestration |
| Phase 8: E2E Test | `test-designer`, `implementer` | Via ralph-loop orchestration |
| Phase 9: Review | `code-reviewer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-reviewer"` |

---

## Dependencies

- **Required**: `ralph-loop` plugin for Phases 7, 8, 9
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test)

## Integration with Debug Workflow

If bugs are discovered during implementation or review:

```
/debug-workflow:debug <bug description>
```

This switches to the hypothesis-driven debugging workflow.
