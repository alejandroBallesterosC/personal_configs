# Personal Configs - Codebase Analysis

> Last updated: 2025-02-03
> Iteration: 3 of 3 (FINAL)

## 1. System Purpose & Domain

**Purpose**: Development infrastructure repository for AI-assisted workflows with Claude Code. Provides encapsulated plugins, workflow orchestration, and configuration sync mechanisms.

**Core Domain Entities**:

| Entity | Definition | Location |
|--------|------------|----------|
| **Plugin** | Self-contained capability module with commands, agents, skills, hooks | `claude-code/plugins/*/` |
| **Command** | User-invocable action (YAML frontmatter + markdown prompt) | `*/commands/*.md` |
| **Agent** | Specialized subagent (YAML frontmatter defines tools/model) | `*/agents/*.md` |
| **Skill** | Auto-activating guidance (description-based context matching) | `*/skills/*/SKILL.md` |
| **Hook** | Event-triggered automation (PostToolUse, PreCompact, SessionStart) | `*/hooks/hooks.json` |

**Domain Model** (from plugin.json manifests):
```
Plugin
├── manifest (plugin.json): name, description, version, author, keywords
├── commands/: User-invocable slash commands
├── agents/: Spawnable subagents for Task tool
├── skills/: Context-activated guidance documents
└── hooks/: Event handlers (JSON config + shell/agent handlers)
```

## 2. Technology Stack

| Technology | Version | Usage | Source |
|------------|---------|-------|--------|
| **Markdown** | N/A | Commands, agents, skills, documentation | All `.md` files |
| **JavaScript** | Node 18.0.0+ | Playwright browser automation | `playwright/package.json` |
| **Bash/Shell** | POSIX | Sync scripts, test runners, hooks | `scripts/`, `hooks/` |
| **JSON** | N/A | Plugin manifests, MCP config, VS Code tasks | `*.json` files |
| **YAML** | N/A | Agent/command frontmatter | Embedded in `.md` |

**Infrastructure**:
- **Runtime**: Claude Code CLI
- **MCP Servers**: context7 (HTTP), fetch (stdio), exa (npx), playwright (npx)
- **Sync Target**: `~/.claude/` global configuration

**External Services** (from `global_mcp_settings.json`):
| Service | Purpose | Auth |
|---------|---------|------|
| Context7 | Documentation retrieval | `CONTEXT7_API_KEY` |
| Exa | Web search, code context | `EXA_API_KEY` |
| Playwright MCP | Browser automation | None |

## 3. Architecture

**Pattern**: Modular Plugin Architecture with Orchestrator Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Code Runtime                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ tdd-workflow │  │debug-workflow│  │  Other Plugins (4)   │   │
│  │  7 agents    │  │  4 agents    │  │  playwright, iac,    │   │
│  │  10 commands │  │  7 commands  │  │  session-feedback,   │   │
│  │  4 skills    │  │  1 skill     │  │  claude-md-practices │   │
│  │  3 hooks     │  │  0 hooks     │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                MCP Servers (4 connections)                 │ │
│  │  context7 │ fetch │ exa │ playwright                       │ │
│  └────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Sync Scripts (bidirectional)                  │ │
│  │  plugins ↔ commands ↔ skills ↔ docs ↔ mcp ↔ claude.md     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Data Flow**:
1. User invokes `/plugin:command` → Command markdown loaded
2. Command spawns agents via Task tool → Agents execute with defined tools
3. Hooks fire on events → Shell scripts or agent prompts execute
4. Artifacts written to `docs/` → State persisted across context clears

## 4. Boundaries & Interfaces

### Plugin Boundary Contract

Each plugin is **completely self-contained**:

```
plugin/
├── .claude-plugin/plugin.json  # REQUIRED: name, description, version
├── commands/                   # OPTIONAL: *.md with YAML frontmatter
├── agents/                     # OPTIONAL: *.md with YAML frontmatter
├── skills/                     # OPTIONAL: */SKILL.md
└── hooks/                      # OPTIONAL: hooks.json + handlers
```

**Interface Contract** (plugin.json schema):
```json
{
  "name": "string (required)",
  "description": "string (required)",
  "version": "semver (required)",
  "author": {"name": "string"},
  "repository": "url",
  "keywords": ["array", "of", "tags"]
}
```

### Agent YAML Contract

```yaml
---
name: agent-name          # Required: unique within plugin
description: "..."        # Required: skill auto-activation trigger
tools: [Read, Write, ...]  # Required: subset of available tools
model: sonnet|opus        # Required: model selection
---
```

**Tool Constraints by Role**:
| Agent Role | Allowed Tools | Rationale |
|------------|---------------|-----------|
| test-designer | Read, Grep, Glob, Task | Specification only (no Write) |
| implementer | Read, Write, Edit, Bash, Grep, Glob | GREEN phase (minimal code) |
| refactorer | Read, Write, Edit, Bash, Grep, Glob | Quality improvement |
| code-reviewer | Read, Grep, Glob, Bash | Analysis only |

### Hook Event Contract

```json
{
  "hooks": {
    "EventType": [
      {
        "matcher": "pattern",
        "hooks": [{"type": "command|agent", "command|prompt": "..."}]
      }
    ]
  }
}
```

**Supported Events**: PreToolUse, PostToolUse, Stop, SubagentStop, SessionStart, SessionEnd, UserPromptSubmit, PreCompact, Notification

### Coupling Assessment

| Boundary | Coupling | Notes |
|----------|----------|-------|
| Plugin ↔ Plugin | **Loose** | No direct imports; communicate via filesystem |
| Plugin ↔ Runtime | **Tight** | Depends on Claude Code tool/event system |
| TDD ↔ ralph-loop | **Tight** | External dependency required for Phases 7-9 |
| Repository ↔ ~/.claude/ | **Bidirectional** | Sync scripts manage |

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin isolation | Self-contained directories | Shared component library | Duplication vs. independence |
| Agent spawning | Task tool with subagent_type | In-process execution | Overhead vs. tool constraints |
| State persistence | Markdown files in docs/ | Database/JSON state | Human-readable vs. structured |
| Test auto-run | PostToolUse hook | Manual test invocation | Latency vs. immediate feedback |
| Context restoration | Hook-based auto-resume | Manual checkpoint commands | Complexity vs. UX |
| MCP servers | 4 always-loaded | On-demand loading | Token overhead (~14k) vs. availability |

**Technical Debt**:
- ralph-loop external dependency (not in this repo)
- Manual phase transitions (can't skip phases)
- Context limits still require periodic `/clear` despite hooks

## 6. Code Quality & Patterns

### Recurring Patterns

**Orchestrator Pattern** (TDD workflow):
- Main instance owns feedback loop
- Spawns stateless subagents for discrete tasks
- Main instance validates after each subagent completes

**Parallel-Safe Operations**:
- Exploration: 5 parallel read-only agents
- Review: 5 parallel analysis agents
- Implementation: Sequential (TDD cycle)

**Contract-First Development**:
- Architecture → Implementation Plan → Code
- Interfaces defined before implementation
- Components can be built in parallel after foundation

### Testing Strategy

**TDD Discipline** (from CLAUDE.md):
- RED: Write failing test (test-designer)
- GREEN: Minimal code to pass (implementer)
- REFACTOR: Improve while green (refactorer)

**Test Framework Detection** (`detect-test-runner.sh`):
```
pytest | vitest | jest | go test | cargo test | rspec | minitest | mix test
```

**Test Output Requirement**: "TEST OUTPUT MUST BE PRISTINE TO PASS"

### Error Handling

**Graceful Degradation**:
- Missing state file → exit 0 (no-op)
- No test runner detected → exit 0 (non-fatal)
- Hook preconditions not met → skip silently

**Debug Pattern** (hypothesis-driven):
```python
# HYPOTHESIS: H1 - User object is null
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] user={user}")
```

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| "6 plugins" (CLAUDE.md) | Verified: 6 plugin directories | `claude-code/plugins/` |
| "7 agents" in TDD | Verified: 7 agent files | `tdd-workflow/agents/*.md` |
| "11 commands" in TDD | Verified: Currently 10 commands (1 deleted) | `tdd-workflow/commands/` |
| "ralph-loop required" | Confirmed: Referenced in multiple commands | `7-implement.md:16-25` |
| "CODEBASE.md exists" | NOW TRUE: Recreated by this analysis | `docs/CODEBASE.md` |

## 8. Open Questions

**Answered (Iteration 2)**:
- [x] How does `auto-resume-after-compact.sh` interact with SessionStart hook?
  - **Answer**: The hook is triggered by SessionStart event with `"matcher": "compact"`. It reads the state file, checks if workflow is incomplete, and injects full context via `additionalContext` JSON field. See `hooks/auto-resume-after-compact.sh:10-80`
- [x] Why are some commands numbered (1-9) and others not (help)?
  - **Answer**: Numbers represent workflow phases that must execute in sequence. `help` is standalone reference. Commands 1-9 = workflow phases; non-numbered = utilities.
- [x] Is there a maximum iteration safety for ralph-loop?
  - **Answer**: YES. Commands explicitly set `--max-iterations` flag. Phase 7: 50 iterations per component, Phase 8: 30 iterations for E2E, Phase 9: 20 iterations for fixes. Cost warning: 50 iterations ≈ $50-100+

**Answered (Iteration 3)**:
- [x] Why was `reinitialize-context-after-clear-and-continue-workflow.md` deleted?
  - **Answer**: REPLACED BY AUTOMATIC HOOKS. The manual command was superseded by the new `PreCompact` and `SessionStart` hooks added in the same commit series. Git diff shows hooks.json was expanded from just PostToolUse to include PreCompact (agent) and SessionStart (command) handlers. The manual command required user to run `/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow <feature>` after `/clear`, but now context is auto-restored.
- [x] Why does debug-workflow not use hooks but tdd-workflow does?
  - **Answer**: TDD workflow is LONG-RUNNING (potentially 50+ iterations across 8 phases, hours of work) requiring state preservation across context clears. Debug workflow is SINGLE-SESSION (typically one bug, one fix) and completes within a context window. Debug state files (`docs/debug/*`) exist but don't need cross-session preservation.

**Still Open** (require external information):
- [ ] What is the exact token cost per MCP server? (Claimed ~14k total - needs measurement)
- [ ] What is the relationship between `ralph-loop` and `ralph-wiggum`? (Install: `ralph-wiggum`, invoke: `ralph-loop`)
- [ ] How are MCP server API keys rotated/managed? (`.env` is gitignored, no rotation scripts)
- [ ] What happens if PostToolUse hook fails mid-workflow? (No error recovery documented)
- [ ] Are there metrics on TDD workflow completion rates? (No analytics in codebase)

## 9. Key Workflow Traces (Iteration 2)

### TDD Workflow End-to-End Data Flow

```
User: /tdd-workflow:1-start myfeature "description"
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ 1-start.md LOADED                                          │
│ - Checks ralph-loop dependency                             │
│ - Spawns 5 parallel code-explorer agents (Phase 2)         │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (5 Task tool calls in single message)
┌────────────────────────────────────────────────────────────┐
│ code-explorer agents (parallel, read-only)                 │
│ - Architecture, Patterns, Boundaries, Testing, Dependencies│
│ - Output: individual exploration reports                   │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (main instance synthesizes)
┌────────────────────────────────────────────────────────────┐
│ ARTIFACT: docs/context/myfeature-exploration.md            │
│ ARTIFACT: docs/workflow/myfeature-state.md                 │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phase 3: Interview)
┌────────────────────────────────────────────────────────────┐
│ Main instance uses AskUserQuestionTool                     │
│ - 40+ questions ONE AT A TIME                              │
│ - Domains: functionality, constraints, integration, etc.   │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ ARTIFACT: docs/specs/myfeature.md                          │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phases 4-5: Architecture + Plan)
┌────────────────────────────────────────────────────────────┐
│ ARTIFACT: docs/plans/myfeature-arch.md                     │
│ ARTIFACT: docs/plans/myfeature-plan.md                     │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phase 6: Review)
┌────────────────────────────────────────────────────────────┐
│ plan-reviewer agent spawned                                │
│ - Challenges assumptions, identifies gaps                  │
│ - User approval required to proceed                        │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phase 7: Implementation)
┌────────────────────────────────────────────────────────────┐
│ ralph-loop:ralph-loop (external plugin)                    │
│ Per component:                                             │
│   ├─ test-designer: Write ONE failing test (RED)           │
│   ├─ Main runs tests → confirms failure                    │
│   ├─ implementer: Write minimal code (GREEN)               │
│   ├─ Main runs tests → confirms pass                       │
│   ├─ refactorer: Improve code (REFACTOR)                   │
│   └─ Main runs tests → confirms still green                │
│ --max-iterations 50 per component                          │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phase 8: E2E)
┌────────────────────────────────────────────────────────────┐
│ ralph-loop:ralph-loop for E2E tests                        │
│ --max-iterations 30                                        │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼ (Phase 9: Review + Completion)
┌────────────────────────────────────────────────────────────┐
│ 5 parallel code-reviewer agents                            │
│ - Security, Performance, Quality, Coverage, Compliance     │
│ - Only ≥80% confidence findings reported                   │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ ralph-loop:ralph-loop for critical fixes                   │
│ --max-iterations 20                                        │
│ FINAL: docs/workflow/myfeature-state.md = COMPLETE         │
│ FINAL: docs/workflow/myfeature-review.md                   │
└────────────────────────────────────────────────────────────┘
```

### Context Preservation Flow

```
DURING WORKFLOW (any point):
┌────────────────────────────────────────────────────────────┐
│ Context fills → PreCompact hook triggers                   │
│ - Agent prompt extracts: phase, component, requirement     │
│ - Updates docs/workflow/<feature>-state.md                 │
│ - Output: "TDD workflow state saved..."                    │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ Context compacted (automatic or /clear)                    │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ SessionStart hook triggers (matcher: "compact")            │
│ - Finds docs/workflow/*-state.md                           │
│ - Checks if workflow NOT complete                          │
│ - Reads entire state file                                  │
│ - Outputs JSON with additionalContext                      │
│   → Injects: state content, artifact file list             │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ Claude sees injected context                               │
│ - Reads listed artifact files                              │
│ - Continues workflow from saved position                   │
└────────────────────────────────────────────────────────────┘
```

### Sync Script Data Flow

```
Development Workflow:
┌──────────────────────────────────────────┐
│ Edit plugins in this repo                │
│ claude-code/plugins/<plugin>/            │
└──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ ./scripts/sync_plugins_to_global.sh      │
│ - Copies to ~/.claude/plugins/           │
│ - Preserves marketplace.json             │
│ - --overwrite: clean before copy         │
└──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ Claude Code loads from ~/.claude/        │
│ - /plugin marketplace add ~/.claude/plugins │
│ - OR: claude --plugin-dir ~/.claude/plugins/<name> │
└──────────────────────────────────────────┘
```

### Debug Workflow Flow

```
User: /debug-workflow:debug "API returns 500 when emoji in name"
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ debug.md LOADED                                            │
│ structured-debug skill auto-activates                      │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ debug-explorer agent                                       │
│ - Maps relevant code paths                                 │
│ - ARTIFACT: docs/debug/<bug>-exploration.md                │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ hypothesis-generator agent                                 │
│ - 3-5 ranked theories                                      │
│ - ARTIFACT: docs/debug/<bug>-hypotheses.md                 │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ instrumenter agent                                         │
│ - Adds targeted logging per hypothesis                     │
│ - Pattern: [DEBUG-H1], [DEBUG-H2], etc.                    │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ User reproduces bug → captures logs                        │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ log-analyzer agent                                         │
│ - Matches logs to hypotheses                               │
│ - Confirms/refutes theories                                │
└────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────┐
│ Fix + Verify + Cleanup                                     │
│ - Minimal fix for root cause                               │
│ - Remove all DEBUG instrumentation                         │
│ - Write regression test                                    │
└────────────────────────────────────────────────────────────┘
```

## 10. Ambiguities

**Cannot determine from code alone**:

1. **Ralph-loop plugin internals**: External dependency, no source in this repo. Install path suggests `anthropics/claude-code` marketplace but referenced as `ralph-wiggum`.
2. **MCP server implementation details**: Only configuration, not server code
3. **Historical context**: Why certain decisions were made (no ADR documents)
4. **Usage patterns**: No analytics on which plugins/commands are most used
5. **Performance characteristics**: No benchmarks or profiling data
6. **Recovery procedures**: What to do if hooks fail catastrophically
7. **Deleted command**: `reinitialize-context-after-clear-and-continue-workflow.md` was deleted but its purpose may have been subsumed by the new auto-resume hooks

**Questions for original authors**:
- What prompted the modular plugin architecture vs. a monolithic approach?
- Are there plans to internalize ralph-loop functionality?
- What's the expected token budget for a typical TDD workflow run?
- Why does debug-workflow not use hooks for state persistence like tdd-workflow?

## 11. Boundary Analysis (Iteration 2)

### Contract Strictness Assessment

| Interface | Strictness | Evidence |
|-----------|------------|----------|
| Plugin manifest | **Strict** | Required fields enforced by Claude Code runtime |
| Agent YAML frontmatter | **Strict** | Must have name, tools, model to spawn |
| Hook JSON schema | **Strict** | EventType, matcher, hooks array required |
| Command YAML frontmatter | **Loose** | description recommended, model optional |
| Skill activation | **Loose** | Based on description matching, heuristic |
| State file format | **Loose** | Markdown with expected sections, not validated |

### Coupling Analysis

**Tight Coupling**:
1. `7-implement.md` ↔ `ralph-loop` plugin: Commands directly invoke `/ralph-loop:ralph-loop`
2. `auto-resume-after-compact.sh` ↔ state file format: Script parses specific state file structure
3. TDD agents ↔ Task tool subagent_type: Must use exact `tdd-workflow:agent-name` syntax

**Loose Coupling**:
1. Plugins ↔ each other: No direct imports, filesystem-only communication
2. Commands ↔ skills: Skills auto-activate but commands don't require them
3. MCP servers ↔ plugins: MCP tools available to all, no plugin-specific binding

### Data Flow Boundaries

**Input Boundaries**:
- User commands: Arguments passed as `$1`, `$2` positional params
- Hook events: JSON via stdin, specific fields per event type
- Agent prompts: Markdown with embedded context

**Output Boundaries**:
- Artifacts: Markdown files in `docs/` hierarchy
- Hook responses: JSON to stdout with `additionalContext` field
- Agent returns: Text to orchestrating main instance

**State Persistence**:
- Location: `docs/workflow/<feature>-state.md`
- Format: Markdown with specific sections (Current Phase, Completed Phases, Session Progress)
- Access: Read by hooks, written by PreCompact agent prompt
