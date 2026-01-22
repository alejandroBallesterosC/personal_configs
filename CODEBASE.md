# Personal Configs - Codebase Analysis

> Last updated: 2026-01-21
> Iteration: 3 of 3 (FINAL)

## 1. System Purpose & Domain

This repository is a **development infrastructure and configuration ecosystem** for AI-assisted software development. It is NOT a traditional application—it contains no deployable artifacts or runtime dependencies.

**Core Domain Entities**:

| Entity | Purpose | Location |
|--------|---------|----------|
| **Plugin** | Encapsulated development workflow (TDD, Debug) | `claude-code/plugins/` |
| **Command** | Entry point for workflow phase | `claude-code/commands/` |
| **Agent** | Specialized Claude instance with constrained tools | `plugins/*/agents/` |
| **Skill** | Domain knowledge that activates contextually | `plugins/*/skills/` |
| **Hook** | Automatic trigger after tool operations | `plugins/*/hooks/` |
| **MCP Server** | External capability integration | `global_mcp_settings.json` |

**Problem Solved**: Provides systematic, repeatable workflows for:
1. Planning-heavy TDD implementation (EXPLORE → PLAN → ARCHITECT → IMPLEMENT → REVIEW)
2. Hypothesis-driven debugging (EXPLORE → HYPOTHESIZE → INSTRUMENT → ANALYZE → FIX)
3. Configuration synchronization between local and global Claude Code settings

---

## 2. Technology Stack

### Languages & Frameworks
- **Shell** (bash): Automation scripts, test runners
- **Markdown**: Commands, agents, skills, documentation
- **JSON**: Configuration (MCP servers, VS Code tasks, plugin manifests)
- **YAML**: Frontmatter in markdown files (metadata)

### External Tools (from scripts)
- **Python**: Via `uv run` (UV package manager)
- **C++**: Via `clang++` (C++23 standard)
- **TypeScript**: Via `npx tsc`

### MCP Servers Configured
| Server | Type | Purpose |
|--------|------|---------|
| context7 | HTTP | Documentation & API context lookup |
| fetch | stdio | URL content fetching |
| exa | stdio | Web search, code context |
| playwright | stdio | Browser automation |

### Version Control
- Git repository on GitHub (`jandro/personal_configs`)
- Main branch, clean working directory

---

## 3. Architecture

### Pattern: **Modular Plugin Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│          Personal Development Configuration Monolith            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │          Plugin Orchestration Layer                      │   │
│  │  (Manages lifecycle, commands, skills, agents)           │   │
│  └────────────────┬──────────────────┬─────────────────────┘   │
│                   │                  │                          │
│     ┌─────────────▼──────┐  ┌───────▼──────────────┐           │
│     │  TDD Workflow      │  │  Debug Workflow      │           │
│     │  Plugin            │  │  Plugin              │           │
│     │                    │  │                      │           │
│     │ - Commands (8)     │  │ - Commands (7)       │           │
│     │ - Agents (7)       │  │ - Agents (4)         │           │
│     │ - Skills (6)       │  │ - Skills (1)         │           │
│     │ - Hooks (auto-test)│  │ - No hooks           │           │
│     └────────────────────┘  └──────────────────────┘           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    Shared Infrastructure                                 │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐      │  │
│  │  │  Commands  │  │  Docs       │  │  Scripts     │      │  │
│  │  │  (17 MD)   │  │  (3 MD)     │  │  (13 bash)   │      │  │
│  │  └────────────┘  └─────────────┘  └──────────────┘      │  │
│  │                                                          │  │
│  │  ┌───────────────────────────────────────────────────┐  │  │
│  │  │  MCP Integration (Context7, Fetch, Exa, Playwright)│  │  │
│  │  └───────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  IDE Integrations                                        │  │
│  │  - VS Code: tasks.json (22 tasks), key_bindings.json    │  │
│  │  - Cursor: rules/maintain-docs.mdc                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

**TDD Workflow Execution**:
```
/tdd-workflow:start <feature>
  ↓
EXPLORE → code-explorer agent → docs/context/<feature>-exploration.md
  ↓
PLAN → AskUserQuestionTool (40+ questions) → docs/specs/<feature>.md
  ↓
ARCHITECT → code-architect agent → docs/plans/<feature>-arch.md
  ↓
REVIEW-PLAN → plan-reviewer agent → resolved questions
  ↓
[FRESH SESSION RECOMMENDED]
  ↓
IMPLEMENT → ralph-loop with RED/GREEN/REFACTOR agents
  ├─ RED: test-designer (read-only, proposes tests)
  ├─ GREEN: implementer (minimal code to pass)
  └─ REFACTOR: refactorer (improve while green)
  ↓
Hook: PostToolUse Write|Edit → auto-run tests
  ↓
REVIEW → code-reviewer agent → confidence-scored findings
```

**Debug Workflow Execution**:
```
/debug-workflow:debug <bug>
  ↓
EXPLORE → debug-explorer agent → docs/debug/<bug>-exploration.md
  ↓
DESCRIBE → user interview → docs/debug/<bug>-bug.md
  ↓
HYPOTHESIZE → hypothesis-generator → docs/debug/<bug>-hypotheses.md
  ↓
INSTRUMENT → instrumenter → adds [DEBUG-H1..H5] logging
  ↓
REPRODUCE → user executes, captures logs
  ↓
ANALYZE → log-analyzer → CONFIRMED/REJECTED/INCONCLUSIVE
  ↓
FIX → minimal fix + regression test
  ↓
VERIFY → user confirms
  ↓
CLEAN → remove debug markers, commit
```

---

## 4. Boundaries & Interfaces

### Interface: Command Protocol
**Contract**: YAML frontmatter + Markdown body
```yaml
---
description: Human-readable workflow description
model: haiku|sonnet|opus
argument-hint: <required> [optional]
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob, Task, Skill]
---
```
**Implementations**: `claude-code/commands/*.md` (17 commands)

### Interface: Agent Protocol
**Contract**: YAML frontmatter defining tools, model, constraints
```yaml
---
name: agent-name
description: short description
tools: [Read, Grep, Glob, Write, Edit, Bash]
model: sonnet|opus
---
```
**Key Constraint Patterns**:
- `test-designer`: NO Write/Edit (read-only, proposes tests in output)
- `implementer`: NO refactoring (just make tests pass)
- `refactorer`: ONLY during GREEN phase

### Interface: Skill Protocol
**Contract**: Domain knowledge activated contextually
```yaml
---
name: skill-name
description: activation trigger
---
```
**Implementations**: TDD has 6 skills, Debug has 1 skill

### Interface: Hook Contract
**Location**: `tdd-workflow/hooks/hooks.json`
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "run-tests.sh", "timeout": 120}]
    }]
  }
}
```
**Purpose**: Automatic test feedback after code changes

### Coupling Assessment
- **Command → Agent**: Loose (composition via Task tool)
- **Agent → Skill**: Loose (reference, skill provides guidance)
- **Plugin → Plugin**: None (TDD and Debug completely independent)
- **Plugin → MCP**: Loose (declarative configuration)

---

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| **Document-centric state** | Markdown files (docs/context/, docs/specs/) | Database/API | Human-readable, version-controlled; no querying |
| **Agent constraints via YAML** | Frontmatter metadata | Code-enforced permissions | Relies on agent compliance; easy to modify |
| **Planning-first workflow** | 4 phases before implementation | Jump to coding | Front-loads ambiguity; slower initial progress |
| **Auto-test hooks** | PostToolUse Write|Edit | Manual test invocation | Tight feedback loop; 120s timeout may be slow |
| **Bidirectional sync scripts** | Shell scripts | Symlinks or dotfile managers | Explicit control; requires manual invocation |
| **No CI/CD** | Manual sync, local execution | GitHub Actions | Infrastructure repo; not deployed |

---

## 6. Code Quality & Patterns

### Recurring Patterns

**RED-GREEN-REFACTOR TDD Cycle** (from `tdd-guide` skill):
1. Write FAILING test that specifies behavior
2. Write MINIMAL code to pass test
3. REFACTOR while keeping tests green

**Hypothesis-Driven Debugging** (from `structured-debug` skill):
1. Generate 3-5 ranked theories
2. Add surgical logging tagged `[DEBUG-H1..H5]`
3. Match logs to hypotheses
4. Fix only after evidence confirms root cause

**Document Persistence** (from CLAUDE.md):
- All code files start with `ABOUTME:` comment (2 lines)
- CLAUDE.md is single source of truth per project
- Exploration outputs to `docs/context/`, specs to `docs/specs/`

### Testing Strategy
- **Framework**: Auto-detected (pytest, jest, vitest, go test, cargo, rspec, minitest, mix)
- **Location**: `plugins/tdd-workflow/scripts/detect-test-runner.sh`
- **Command**: Auto-run via hooks after Write|Edit
- **Coverage**: Tests MUST cover implemented functionality

### Error Handling
- Test failure is EXPECTED in RED phase
- If tests fail during refactoring: UNDO, re-verify green, make smaller change
- Debug workflow: No fixes until root cause proven with evidence

---

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| "7 specialized agents" (TDD) | Verified: 7 agent files | `plugins/tdd-workflow/agents/` |
| "4 specialized agents" (Debug) | Verified: 4 agent files | `plugins/debug-workflow/agents/` |
| "6 skills" (TDD) | Verified: 6 skill directories | `plugins/tdd-workflow/skills/` |
| "PostToolUse hook runs tests" | Verified: hooks.json exists | `plugins/tdd-workflow/hooks/hooks.json` |
| "MCP servers: context7, fetch, exa, playwright" | Verified: 4 servers configured | `claude-code/global_mcp_settings.json` |

---

## 8. Open Questions

**Answered in Iteration 2:**

- [x] **How does marketplace.json get populated?** → Manual. The `marketplace.json` at `plugins/.claude-plugin/marketplace.json` is hand-written and lists plugins with relative source paths (`./tdd-workflow`, `./debug-workflow`). Sync script copies the manifest to `~/.claude/plugins/.claude-plugin/`.

- [x] **What happens when detect-test-runner.sh fails?** → Returns "unknown" and exits 0 (graceful). The `run-tests.sh` then echoes "No test runner detected" and exits 0 (no error).

- [x] **How do ralph-loop iterations integrate?** → The implement command constructs a prompt with embedded instructions and invokes `/ralph-loop:ralph-loop` with `--max-iterations N` and `--completion-promise "TDD_COMPLETE"`. Ralph-loop is an external plugin that iterates autonomously.

- [x] **Are TDD and Debug plugins independent?** → Yes, completely. No shared code, no cross-references. Both are self-contained in their directories.

**Answered in Iteration 3:**

- [x] **Where does ralph-loop come from?** → `ralph-loop` is a **separate plugin** (not in this repo) inspired by Geoffrey Huntley. The TDD README explicitly lists it as a **Required dependency** (line 70-71). It enables autonomous iteration with a completion promise pattern. Must be installed separately.

- [x] **Sync cadence?** → On-demand via VS Code tasks. 15 tasks defined in `.vscode/tasks.json` for bidirectional sync (Commands, Docs, Skills, Plugins, MCP Servers, Claude). User runs them manually when needed.

**Still Open:**

- [ ] How is plugin versioning handled beyond git commits?
- [ ] Is there a mechanism to disable auto-test hooks for specific file types?
- [ ] What's the recovery path if context is compacted mid-workflow?

---

## 9. Ambiguities

**Resolved in Iteration 2:**

1. ~~**Ralph-loop integration**~~: Invoked via `/ralph-loop:ralph-loop "<prompt>" --max-iterations N --completion-promise "TDD_COMPLETE"`. The implement command constructs the full TDD prompt.

**Still Ambiguous:**

1. **Plugin loading mechanism**: How does Claude Code discover and load plugins from `plugins/.claude-plugin/marketplace.json`? The sync script says to use `claude --plugin-dir ~/.claude/plugins/<plugin-name>` or `/plugin marketplace add ~/.claude/plugins`. Loading is external to this repo.

2. **Skill activation triggers**: Skills describe "when to activate" but activation is determined by Claude Code's internal matching, not code in this repo.

3. **Context compaction handling**: Documents mention "if context is compacted" but recovery is manual: re-read docs/specs/ and docs/plans/ files. No automatic verification.

4. **Environment variable precedence**: `.env` file is gitignored (secrets). `global_mcp_settings.json` references `${CONTEXT7_API_KEY}` and `${EXA_API_KEY}` which are sourced from shell environment, not .env directly. The .env file is likely sourced by user's shell profile.

5. **Ralph-loop origin**: The TDD workflow depends on `ralph-loop` plugin but it's not defined in this repo. It's presumably installed separately.

---

## 10. Workflow Deep Dive (Iteration 2)

### TDD Workflow End-to-End Trace

**Entry**: `/tdd-workflow:start <feature>`

**Phase 1 - EXPLORE** (`start.md:21-38`)
- Uses `code-explorer` agent (not directly invoked, but described)
- Output: `docs/context/<feature>-exploration.md`
- Also reviews/updates CLAUDE.md

**Phase 2 - PLAN** (`start.md:40-72`)
- Interactive interview using `AskUserQuestionTool`
- 40+ questions across 9 domains (Core Functionality, Constraints, UI/UX, Edge Cases, Security, Testing, Integration, Performance, Deployment)
- Key principle: "Pushback on idealistic ideas" (Mo Bitar's approach)
- Output: `docs/specs/<feature>.md` + `docs/plans/<feature>-tests.md`

**Phase 3 - ARCHITECT** (`start.md:74-95`)
- Uses `code-architect` agent
- Designs components, interfaces, data flow, state, error handling, testing strategy
- Output: `docs/plans/<feature>-arch.md` + `docs/plans/<feature>-plan.md`

**Phase 4 - REVIEW-PLAN** (`start.md:97-119`)
- Uses `plan-reviewer` agent
- Challenges assumptions, identifies gaps/risks, validates dependencies
- Requires explicit user approval before proceeding

**[FRESH SESSION]** (`start.md:122-133`)
- Recommends `/clear` to prevent context pollution
- Implementation starts clean with just spec files

**Phase 5 - IMPLEMENT** (`implement.md`)
- Prerequisite check: All 4 docs must exist (spec, arch, plan, tests)
- Invokes: `/ralph-loop:ralph-loop "<embedded TDD prompt>" --max-iterations N --completion-promise "TDD_COMPLETE"`
- The prompt instructs ralph-loop to:
  - Read all planning artifacts
  - For EACH requirement: RED → GREEN → REFACTOR
  - Commit at each phase transition
  - Output "TDD_COMPLETE" when done
- Auto-test hook fires after every Write|Edit

**Phase 6 - REVIEW** (`start.md:174-196`)
- Uses `code-reviewer` agent
- Checks: CLAUDE.md compliance, test coverage, security, code quality, spec compliance
- Only reports findings with confidence ≥80%

### Test Runner Auto-Detection Trace

**Entry**: Hook fires after Write|Edit → `run-tests.sh`

**Detection Flow** (`detect-test-runner.sh`):
1. Check Python: `pyproject.toml`, `pytest.ini`, `setup.py`, `setup.cfg` + grep for "pytest"
2. Check Vitest: `vitest.config.ts/js/mts`
3. Check Jest: `jest.config.js/ts/mjs` or `package.json` contains `"jest"`
4. Check package.json for `"vitest"`
5. Check Go: `go.mod`
6. Check Rust: `Cargo.toml`
7. Check Ruby: `Gemfile` + grep for `rspec` or `minitest`
8. Check Elixir: `mix.exs`
9. Default: `unknown`

**Execution** (`run-tests.sh`):
- Case statement routes to appropriate command
- Python: Tries `uv run pytest` first, falls back to `pytest`
- JS: Uses `npx vitest run` or `npx jest`
- Graceful failure: Missing command → "X not found" + exit 0

### Sync Scripts Trace

**Entry**: `sync_plugins_to_global.sh [--overwrite]`

**Flow**:
1. Source: `$REPO/claude-code/plugins/`
2. Destination: `~/.claude/plugins/`
3. If `--overwrite`: Delete matching plugin dirs in destination
4. Copy each plugin dir from source to destination
5. Copy `.claude-plugin/marketplace.json` manifest

**Usage after sync** (from script comments):
- `claude --plugin-dir ~/.claude/plugins/<plugin-name>`
- Or `/plugin marketplace add ~/.claude/plugins`

---

## 11. Intellectual Heritage (Iteration 3)

The workflows in this repo are based on insights from several practitioners:

| Person | Affiliation | Contribution |
|--------|-------------|--------------|
| **Boris Cherny** | Anthropic (Claude Code creator) | Parallel exploration, Opus for everything, shared CLAUDE.md, feedback loops |
| **Thariq Shihab** | Anthropic engineer | Interview-first spec development, fresh sessions between phases |
| **Mo Bitar** | - | "Interrogation method" - ask 40+ questions, pushback on idealistic ideas |
| **Geoffrey Huntley** | - | "Ralph Wiggum" autonomous loops (ralph-loop) |

### Key Quotes (embedded in workflow)

> "A good plan is really important to avoid issues down the line." - Boris Cherny

> "Start a fresh session to execute the completed spec." - Thariq Shihab

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

---

## 12. External Dependencies

### Required (for full functionality)

| Dependency | Purpose | Installation |
|------------|---------|--------------|
| **ralph-loop plugin** | Autonomous TDD iteration | Install separately; not included |
| **Claude Code** | Runtime environment | Official Anthropic CLI |

### Optional (for test runner)

| Framework | Detection File | Command |
|-----------|----------------|---------|
| pytest | `pyproject.toml`, `pytest.ini` | `uv run pytest` or `pytest` |
| vitest | `vitest.config.ts/js/mts` | `npx vitest run` |
| jest | `jest.config.js/ts/mjs` | `npx jest` |
| go test | `go.mod` | `go test ./...` |
| cargo test | `Cargo.toml` | `cargo test` |
| rspec | `Gemfile` + "rspec" | `bundle exec rspec` |
| minitest | `Gemfile` + "minitest" | `ruby -Ilib:test test/**/*_test.rb` |
| mix | `mix.exs` | `mix test` |

### MCP Servers (configured)

| Server | API Key Env Var |
|--------|-----------------|
| context7 | `CONTEXT7_API_KEY` |
| exa | `EXA_API_KEY` |
| fetch | (none) |
| playwright | (none) |

---

## 13. Documentation Discrepancy Audit

| Location | Doc Claim | Actual Reality | Assessment |
|----------|-----------|----------------|------------|
| `README.md` | Lists `mcp.json` in `.cursor/` | File exists (deprecated per other docs) | Outdated README |
| `README.md` | Lists only 4 commands | Actually 17+ commands in `claude-code/commands/` | README outdated |
| `README.md` | No mention of plugins | Two major plugins exist | README incomplete |
| `README.md` | No mention of TDD/Debug workflows | Core functionality | README incomplete |
| Task count | README doesn't mention tasks | 15 VS Code sync tasks | README incomplete |

**Recommendation**: The `README.md` is significantly outdated and should be updated to reflect the current plugin-based architecture.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `claude-code/CLAUDE.md` | Coding standards, TDD principles, tool requirements |
| `claude-code/workflow_plan.md` | TDD workflow blueprint (927 lines) |
| `claude-code/global_mcp_settings.json` | MCP server configuration |
| `claude-code/plugins/tdd-workflow/README.md` | TDD workflow overview |
| `claude-code/plugins/debug-workflow/README.md` | Debug workflow overview |
| `claude-code/plugins/tdd-workflow/hooks/hooks.json` | Auto-test hook configuration |
| `claude-code/plugins/tdd-workflow/scripts/detect-test-runner.sh` | Framework auto-detection |
| `scripts/sync_*_to_global.sh` | Config sync scripts (bidirectional) |
| `.vscode/tasks.json` | 22 VS Code tasks for build/sync |
