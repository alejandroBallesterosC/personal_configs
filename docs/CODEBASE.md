# Personal Configs - Codebase Analysis

> Last updated: 2026-02-06
> Iteration: 3 of 3

## 1. System Purpose & Domain

This repository is a **development infrastructure system** for AI-assisted workflows with Claude Code and Cursor IDE. It contains no application code — exclusively configurations, plugins, documentation, and sync scripts that orchestrate how AI assistants work on downstream projects.

**Core domain entities:**

- **Plugins** (6): Self-contained capability packages with agents, commands, skills, and hooks
- **Agents**: Specialized AI workers with tool restrictions and model assignments (YAML frontmatter in `.md` files)
- **Commands**: User-invocable slash commands with argument hints and model selection
- **Skills**: Auto-activating reference documentation loaded when context matches their description
- **Hooks**: Event-driven automation (Stop, SessionStart) that enforce workflow invariants
- **State files**: YAML-frontmatter markdown files that persist workflow progress across context resets
- **Sync scripts**: Bidirectional shell scripts that distribute configs between repo and `~/.claude/`

**Domain relationships:**
```
Plugin ──contains──> Commands, Agents, Skills, Hooks
Command ──invokes──> Skill (via Skill tool), Agent (via Task tool)
Hook ──triggers on──> Stop, SessionStart events
State file ──persists──> Workflow phase, decisions, artifacts
Sync script ──distributes──> Plugin → ~/.claude/ (bidirectional)
```

## 2. Technology Stack

| Layer | Technology | Source |
|-------|-----------|--------|
| **Shell scripts** | Bash (19 scripts, 755+ lines) | `sync-content-scripts/`, `hooks/` |
| **JavaScript** | Node.js 18+ (4 files) | `plugins/playwright/skills/playwright/` |
| **Playwright** | ^1.57.0 | `package.json` in playwright skill |
| **MCP servers** | context7 (HTTP), fetch (stdio/uvx), exa (npx), playwright (npx) | `global_mcp_settings.json` |
| **Python tooling** | uv (referenced in docs, fetch MCP server) | `docs/using-uv.md`, `docs/python.md` |
| **IDE integration** | VS Code tasks (15), keybindings | `.vscode/tasks.json` |

**No build system, no CI/CD, no deployment pipeline.** This is purely infrastructure.

## 3. Architecture

### Pattern: Plugin-Based Modular Architecture

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # 6 isolated plugins (no cross-imports)
│   │   ├── dev-workflow/           # 11 agents, 17 commands, 6 skills, 3 hooks
│   │   ├── playwright/             # Browser automation (JS skill)
│   │   ├── ralph-loop/             # Self-referential AI loops (3 commands, 1 hook)
│   │   ├── claude-session-feedback/ # Session management (4 commands)
│   │   ├── infrastructure-as-code/ # Terraform workflows (1 command, 1 skill)
│   │   └── claude-md-best-practices/ # Documentation patterns (1 skill)
│   ├── commands/                   # 6 shared command templates
│   ├── docs/                       # Best practices guides (3 files)
│   ├── CLAUDE.md                   # Global coding standards template
│   └── global_mcp_settings.json    # MCP server configuration
├── cursor/                         # Cursor IDE mirror (37 files, unidirectional sync)
├── sync-content-scripts/           # Bidirectional sync infrastructure
│   ├── claude-code/                # 8 sync scripts (to/from global)
│   └── cursor/                     # 1 unidirectional sync script
├── .vscode/                        # IDE integration (tasks, keybindings, scripts)
├── .claude/                        # Claude Code settings
├── .claude-plugin/                 # Plugin marketplace config
└── docs/                           # This analysis
```

### Data Flow

```
                    ┌─────────────────────────────┐
                    │   Plugin Marketplace          │
                    │   (.claude-plugin/)           │
                    └──────────┬──────────────────┘
                               │ /plugin install
                    ┌──────────▼──────────────────┐
                    │   Plugin Runtime              │
                    │   (claude-code/plugins/)      │
                    └──────────┬──────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼────┐  ┌───────▼──────┐ ┌───────▼──────┐
    │  Commands     │  │  Hooks        │ │  Skills       │
    │  (user invokes│  │  (auto-fires) │ │  (auto-loads) │
    │  /command)    │  │  Stop,Session │ │  by context)  │
    └───────┬──────┘  └───────┬──────┘ └──────────────┘
            │                 │
    ┌───────▼──────┐  ┌───────▼──────┐
    │  Agents       │  │  State Files  │
    │  (subagents)  │  │  (docs/       │
    │  via Task tool│  │   workflow-*/) │
    └──────────────┘  └──────────────┘
```

### Sync Flow

```
Repo (claude-code/)  ←── sync scripts ──→  ~/.claude/
                     ←── sync scripts ──→  ~/.cursor/ (one-way)
```

Conflict resolution: **Last sync wins** (`rm -rf` then `cp -r`).

## 4. Boundaries & Interfaces

### Plugin Manifest Contract (`plugin.json`)

Every plugin directory contains `.claude-plugin/plugin.json`:
```json
{
  "name": "dev-workflow",           // kebab-case identifier
  "description": "...",             // activation criteria + purpose
  "version": "1.0.0",              // semver
  "author": { "name": "jandro" }   // contact
}
```

**Coupling**: Plugins are **fully isolated** — no inter-plugin imports. Only documented soft dependency: dev-workflow → ralph-loop (external, installed separately via plugin marketplace).

### Hook Contract (`hooks.json`)

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/script.sh" },
        { "type": "agent", "prompt": "...", "timeout": 120 }
      ]
    }],
    "SessionStart": [{
      "matcher": "compact|clear",
      "hooks": [{ "type": "command", "command": "..." }]
    }]
  }
}
```

- Command hooks: Shell scripts, exit code determines pass/fail
- Agent hooks: Return `{"ok": true/false, "reason": "..."}`, can block events
- SessionStart matcher: Regex against event source

### Agent YAML Contract

```yaml
---
name: implementer
description: GREEN phase - Write minimal code to pass existing tests
tools: [Read, Write, Edit, Bash, Grep, Glob]
model: opus
---
```

### Command YAML Contract

```yaml
---
description: Start the fully orchestrated TDD implementation workflow
model: opus
argument-hint: <feature-name> "<feature description>"
---
```

### Skill YAML Contract

```yaml
---
name: tdd-implementation-workflow-guide
description: "Guide for using the TDD implementation workflow plugin..."
---
```

Skills auto-activate when Claude's context matches the description field semantically.

### State File Contract (YAML frontmatter)

```yaml
---
workflow_type: tdd-implementation    # or "debug"
name: feature-name
status: in_progress                  # or "complete"
current_phase: "Phase 7: Implementation"
---
```

State files are the **single source of truth** for workflow progress. Stop hooks enforce freshness; SessionStart hooks read them for auto-resume.

### Test Scope File (`.tdd-test-scope`)

Located at git repo root. Consumed by `run-scoped-tests.sh`:
```
all                              # Run all tests
none                             # No tests
pytest:tests/test_foo.py         # Framework-specific
vitest:--grep "pattern"          # Framework-specific options
tests/test_file.py               # Auto-detected by extension
```

One-shot file: deleted after execution (`run-scoped-tests.sh:279`).

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin isolation | No cross-imports, file-based IPC | Shared library / dependency injection | Simpler but requires external install for ralph-loop |
| State persistence | YAML frontmatter in markdown | Database / JSON files | Human-readable but fragile sed parsing |
| Sync strategy | Last-write-wins (rm + cp) | Git-based merge / symlinks | Simple but destructive; no conflict detection |
| Context management | Stop + SessionStart hooks | Manual `/compact` + re-read | Automatic but hooks add latency; sed YAML parsing fragile |
| Parallel exploration | 5 subagents (sonnet) | Single agent (opus) | Better coverage but higher token cost |
| TDD loops | ralph-loop (self-referential Stop hook) | Manual iteration | Autonomous but requires `--max-iterations` safety cap |
| Cursor support | Mirror structure + unidirectional sync | Shared config format | Duplication but handles format differences cleanly |
| Test scope | File-based IPC (`.tdd-test-scope`) | Environment variables / CLI args | Persistent across hook invocations but one-shot cleanup |

### Areas of Complexity

- **dev-workflow plugin**: 11 agents, 17 commands, 6 skills, 3 hooks — by far the most complex component
- **MCP server merge script**: `sync_mcp_servers_to_global.sh` embeds 100+ lines of inline Python for JSON merging
- **YAML parsing via sed**: `auto-resume-after-compact-or-clear.sh:27` uses fragile regex for frontmatter extraction

## 6. Code Quality & Patterns

### Recurring Patterns

1. **ABOUTME convention**: All code files start with 2-line `ABOUTME:` comments (`CLAUDE.md` standard)
2. **Namespace-qualified references**: Agents referenced as `dev-workflow:code-explorer` (plugin:component)
3. **Orchestrator → Worker pattern**: Main instance (opus) spawns read-only subagents (sonnet), synthesizes results
4. **Parallel for reads, sequential for writes**: Exploration = 5 parallel agents; Implementation = sequential TDD cycles
5. **State file as IPC**: Workflow state, test scope, and context restoration all use file-based communication
6. **`set -e` in all scripts**: 100% of shell scripts use `set -e` for fail-fast behavior

### Testing Strategy

No traditional tests in this repo (it's configuration, not application code). Testing infrastructure is **provided to downstream projects**:

- **9 test frameworks supported**: pytest, vitest, jest, playwright, go, cargo, rspec, minitest, mix
- **Auto-detection**: `detect-test-runner.sh` probes for config files in priority order
- **Scoped execution**: `.tdd-test-scope` file limits which tests run per hook invocation
- **Two-layer validation**: Shell script runs tests + Agent verifies state file accuracy

### Error Handling

- Shell scripts: `set -e` (100%), directory existence checks, stderr error messages
- Python (inline): try/except with traceback printing
- Hooks: Timeout (120s), fallback exit codes, glob-safe `[ -f "$file" ] || continue`

### Configuration Management

- MCP servers: `global_mcp_settings.json` → synced to `~/.claude/`
- Env vars: `.env` (gitignored) for `CONTEXT7_API_KEY`, `EXA_API_KEY`
- Permissions: `.claude/settings.local.json` for tool access restrictions
- Plugin enablement: `.claude/settings.json` lists active plugins

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| CLAUDE.md says "6 plugins" | Correct: 6 plugin directories with plugin.json | `claude-code/plugins/` |
| CLAUDE.md says "11 agents, 17 commands, 6 skills, 3 hooks" for dev-workflow | Correct: verified file counts | `claude-code/plugins/dev-workflow/` |
| CLAUDE.md says ralph-loop is "required for TDD implementation phase" | Accurate: Phase 7 invokes `/ralph-loop` | `commands/7-implement.md` |
| CLAUDE.md says "Last sync wins (no merge - rm -rf then cp -r)" | Partially accurate: sync scripts use `cp -f` with optional `--overwrite` flag for rm | `sync-content-scripts/claude-code/sync_commands_to_global.sh` |
| README.md lists 15 sync tasks | Verified: `.vscode/tasks.json` contains 15 task definitions | `.vscode/tasks.json` |
| CLAUDE.md says "Test auto-detection exits 0 when no framework found" | Correct: `detect-test-runner.sh` echoes "unknown" and exits 0 | `detect-test-runner.sh:79-82` |
| CLAUDE.md says "Single MCP server with 20 tools = ~14,000 tokens" | Plausible but not verifiable from code | N/A (runtime measurement) |
| README.md references `docs/CODEBASE.md` | File was deleted in recent cleanup (commit 2c36108) — now being recreated | `docs/` (empty) |

## 8. Key Workflow Traces (Iteration 2 Deep Dive)

### Workflow A: TDD Implementation (End-to-End)

```
USER: /dev-workflow:1-start-tdd-implementation auth "OAuth2 authentication"
  │
  ├─ 1-start-tdd-implementation.md (opus) loads skill, checks guards
  │   ├─ Loads: dev-workflow:tdd-implementation-workflow-guide (SKILL.md)
  │   ├─ Guard: checks docs/workflow-*/*-state.md for active workflows
  │   └─ Creates: docs/workflow-auth/{auth-state.md, auth-original-prompt.md}
  │
  ├─ PHASE 2: /2-explore → 5 parallel code-explorer agents (sonnet)
  │   └─ Output: docs/workflow-auth/codebase-context/auth-exploration.md
  │
  ├─ PHASE 3: /3-user-specification-interview → 40+ AskUserQuestionTool calls
  │   └─ Output: docs/workflow-auth/specs/auth-specs.md
  │
  ├─ PHASE 4: /4-plan-architecture → code-architect agent (optional)
  │   └─ Output: docs/workflow-auth/plans/auth-architecture-plan.md
  │
  ├─ PHASE 5: /5-plan-implementation → main instance
  │   └─ Output: auth-implementation-plan.md + auth-tests.md
  │
  ├─ PHASE 6: /6-review-plan → plan-reviewer agent
  │   └─ BLOCKS until user explicitly approves
  │
  ├─ PHASE 7: /7-implement → ralph-loop orchestration
  │   │
  │   │  For each component:
  │   │  ┌──────────────────────────────────────────────┐
  │   │  │ /ralph-loop "Implement [Component]..."       │
  │   │  │   --max-iterations 50                        │
  │   │  │   --completion-promise "COMPONENT_..._DONE"  │
  │   │  │                                              │
  │   │  │ LOOP:                                        │
  │   │  │   ├─ RED:    Task → test-designer subagent   │
  │   │  │   │          Main runs tests (confirm fail)  │
  │   │  │   │          git commit "red: ..."           │
  │   │  │   ├─ GREEN:  Task → implementer subagent     │
  │   │  │   │          Main runs tests (confirm pass)  │
  │   │  │   │          git commit "green: ..."         │
  │   │  │   ├─ REFACT: Task → refactorer subagent      │
  │   │  │   │          Main runs tests (confirm pass)  │
  │   │  │   │          git commit "refactor: ..."      │
  │   │  │   └─ Next requirement → repeat               │
  │   │  │                                              │
  │   │  │ OUTPUT: <promise>COMPONENT_..._DONE</promise>│
  │   │  └──────────────────────────────────────────────┘
  │   │
  │   └─ Integration: separate ralph-loop for wiring components
  │
  ├─ PHASE 8: /8-e2e-test → ralph-loop E2E testing
  │
  └─ PHASE 9: /9-review → 5 parallel code-reviewer agents + fixes
      └─ Completion: status → complete, archive to docs/archive/
```

### Workflow B: Ralph-Loop Self-Referential Mechanism

```
/ralph-loop "task" --max-iterations 50 --completion-promise "DONE"
  │
  ├─ 1. ralph-loop.md command executes setup-ralph-loop.sh
  │     Creates: .claude/ralph-loop.local.md (YAML frontmatter + prompt)
  │     Format:
  │       ---
  │       active: true
  │       iteration: 1
  │       max_iterations: 50
  │       completion_promise: "DONE"
  │       started_at: "2026-02-06T..."
  │       ---
  │       [prompt text]
  │
  ├─ 2. Claude works on the task...
  │
  ├─ 3. Claude tries to stop → Stop hook fires
  │     stop-hook.sh reads:
  │       ├─ .claude/ralph-loop.local.md (state)
  │       ├─ Hook input JSON (has transcript_path)
  │       └─ Transcript JSONL → last assistant message text
  │
  ├─ 4. Check completion:
  │     ├─ Extracts <promise>TEXT</promise> from last output (perl regex)
  │     ├─ Compares TEXT to completion_promise (literal = comparison)
  │     ├─ If match: rm state file, exit 0 (allow stop)
  │     ├─ If max_iterations reached: rm state file, exit 0
  │     └─ If no match: increment iteration, output JSON:
  │           {"decision": "block", "reason": "[same prompt]",
  │            "systemMessage": "iteration N | To stop: <promise>DONE</promise>"}
  │
  └─ 5. Loop continues until completion or max iterations
```

**Key detail**: `stop-hook.sh:119` uses `perl -0777` for multiline `<promise>` tag extraction, and `stop-hook.sh:123` uses literal `=` comparison (not glob `==`) to avoid pattern matching issues with special characters.

### Workflow C: Context Preservation (Stop + SessionStart)

```
DURING WORK:
  Main instance keeps docs/workflow-X/X-state.md updated

WHEN CLAUDE STOPS:
  ├─ Hook 1 (command): run-scoped-tests.sh
  │   ├─ Reads .tdd-test-scope from git repo root
  │   ├─ Detects test runner via detect-test-runner.sh
  │   ├─ Runs scoped tests (framework-specific)
  │   └─ Deletes .tdd-test-scope (one-shot)
  │
  └─ Hook 2 (agent): State verification
      ├─ Finds docs/workflow-*/*-state.md and docs/debug/*/*-state.md
      ├─ Checks git diff + git status for recent changes
      ├─ Verifies 5 criteria (phase, component, next action, staleness, files)
      └─ Returns {"ok": true/false, "reason": "..."}
          If false: blocks stop, Claude must update state first

AFTER /compact OR /clear:
  SessionStart hook fires (matcher: "compact|clear")
  ├─ auto-resume-after-compact-or-clear.sh
  │   ├─ Checks docs/workflow-*/*-state.md (TDD)
  │   ├─ Checks docs/debug/*/*-state.md (debug, skips archive/)
  │   ├─ Parses YAML frontmatter via sed (with markdown fallback)
  │   └─ Outputs JSON:
  │       {"hookSpecificOutput": {"hookEventName": "SessionStart",
  │        "additionalContext": "[full state + instructions]"}}
  │
  └─ Claude reads injected context and continues workflow
```

### Workflow D: Sync Scripts

```
Repo Structure:
  sync-content-scripts/claude-code/
  ├─ sync_commands_to/from_global.sh    # claude-code/commands/ ↔ ~/.claude/commands/
  ├─ sync_docs_to/from_global.sh        # claude-code/docs/ ↔ ~/.claude/docs/
  ├─ sync_claude_to/from_global.sh      # claude-code/CLAUDE.md ↔ ~/.claude/CLAUDE.md
  └─ sync_mcp_servers_to/from_global.sh # global_mcp_settings.json ↔ ~/.claude/ (Python merge)

NOTE: sync_plugins_to/from_global.sh and sync_skills_to/from_global.sh
were REMOVED in commit f6d5cff. Plugins are now installed via
/plugin marketplace add (not file sync).

Sync Pattern (sync_commands_to_global.sh):
  1. set -e (fail fast)
  2. Validate source dir exists
  3. mkdir -p destination
  4. If --overwrite: rm -f destination/*.md
  5. cp -f source/*.md destination/
  6. Report count

MCP Sync (special case):
  - Embeds inline Python (~100 lines) for JSON merging
  - Preserves existing MCP servers, adds/updates from repo
  - Handles ${ENV_VAR} substitution patterns
```

### Workflow E: Plugin Marketplace Discovery

```
.claude-plugin/marketplace.json defines:
  ├─ $schema: "https://anthropic.com/claude-code/marketplace.schema.json"
  ├─ name: "personal-configs"
  ├─ owner: { name: "jandro" }
  └─ plugins: [
       { name: "dev-workflow", source: "./claude-code/plugins/dev-workflow", ... }
       { name: "playwright", source: "./claude-code/plugins/playwright", ... }
       ... (6 total)
     ]

Each plugin source dir contains .claude-plugin/plugin.json with:
  { name, description, version, author }

Installation flow:
  /plugin marketplace add alejandroBallesterosC/personal_configs
    → Reads .claude-plugin/marketplace.json at repo root
    → Registers available plugins

  /plugin install dev-workflow
    → Reads plugin.json from source path
    → Registers commands/, agents/, skills/, hooks/
```

## 9. Open Questions

### Answered (Iteration 2)

- [x] **ralph-loop stop-hook.sh internals**: Reads `.claude/ralph-loop.local.md` state, parses transcript JSONL for last assistant message, extracts `<promise>` tags via perl regex, uses literal `=` comparison (not glob), outputs `{"decision": "block", "reason": "[prompt]"}` to re-inject. See `stop-hook.sh:90-174`.
- [x] **Plugin marketplace discovery**: Reads `.claude-plugin/marketplace.json` at repo root (has `$schema`, `plugins[]` with `source` paths). Each source dir has `.claude-plugin/plugin.json`. See `marketplace.json:1-64`.
- [x] **Test scope file lifecycle**: The `.tdd-test-scope` file is written by the main orchestrator instance (during Phase 7 implementation). The `testing` skill documents the format. `run-scoped-tests.sh` consumes and deletes it (one-shot). See `tdd-implementation-workflow-guide/SKILL.md:208`.
- [x] **Sync scripts reduced**: `sync_plugins_to/from_global.sh` and `sync_skills_to/from_global.sh` were removed in commit `f6d5cff`. Plugins now install via marketplace, not file sync. Only 9 sync scripts remain (8 claude-code + 1 cursor).

### Answered (Iteration 3)

- [x] **Debug workflow completion**: Verified by reading `1-start-debug.md` and `6-verify.md`. Debug workflow does NOT use ralph-loop. Verification is a **HUMAN GATE** (Phase 8/Step 10): user manually confirms fix via AskUserQuestionTool. If fix fails, loops back to analysis phase. 3-Fix Rule caps attempts. No completion promise mechanism.
- [x] **Shared commands vs plugin commands**: The 6 shared commands in `claude-code/commands/` (`commit`, `readonly`, `understand-repo`, `update-docs-and-todos`, `choose-worktree-implementation`, `clean-up-worktrees`) are **global commands** synced to `~/.claude/commands/` — available in all projects. Plugin commands are **namespaced** (e.g., `dev-workflow:7-implement`). No overlap or conflict — different namespaces.
- [x] **Cursor hooks.json format**: Documented in `cursor/README.md:88-97`. Format differences: Claude Code uses `{"decision": "block", "reason": "..."}` while Cursor uses `{"continue": false, "agentMessage": "..."}`. Also: hook events are camelCase in Cursor (`stop`), PascalCase in Claude Code (`Stop`). Cursor hooks.json requires `"version": 1`.
- [x] **CLAUDE.md template vs project CLAUDE.md**: `claude-code/CLAUDE.md` is a global template synced to `~/.claude/CLAUDE.md` (applies to all projects). The repo root `CLAUDE.md` is project-specific and loaded only in this repo's context. At runtime, Claude loads both: global first, project-specific overrides/extends. They compose additively — global provides coding standards, project provides repo-specific context.
- [x] **Settings structure**: `.claude/settings.json` enables 3 **external plugins** (plugin-dev, hookify, claude-code-setup from `@claude-plugins-official`). The 6 local plugins are registered via the marketplace mechanism separately. `.claude/settings.local.json` defines file-level permission rules for auto-approving certain tool uses.

### Still Open

- [ ] **Skill activation mechanics**: How exactly does the "description" field trigger skill loading? Is it semantic matching by the Claude runtime, or pattern-based? (Claude Code internal behavior — cannot determine from code alone)
- [ ] **State file locking**: No concurrency control — what happens if two Claude sessions modify state simultaneously? (Mitigated by single-active-workflow guard, but still possible via separate terminals)
- [ ] **MCP tool token cost**: CLAUDE.md claims "20 tools = ~14,000 tokens" — is this measured or estimated? (Cannot verify from code)
- [ ] **Hook execution order**: When dev-workflow and ralph-loop both register Stop hooks, which runs first? Both could block. This matters because dev-workflow's test runner should complete before ralph-loop re-injects the prompt. (Claude Code internal behavior)

## 10. Ambiguities

1. **Plugin load order**: If dev-workflow and ralph-loop both register Stop hooks, which runs first? Does order matter for state verification? (The test runner should complete before ralph-loop re-injects — if reversed, tests might not run.)
2. **Sync timing**: When should users run sync scripts? Before/after editing? The VS Code tasks suggest manual triggering but there's no automation. (Recommendation: sync FROM global after editing in production, sync TO global after editing in repo.)
3. **Cursor parity**: Cursor directory is actively maintained (37 files, sync script exists). Missing: debug workflow commands (only TDD). Cursor has 14 commands vs Claude Code's 17 — no debug commands in Cursor yet.
4. **State file format stability**: The YAML frontmatter schema isn't formally defined. Adding new fields is safe (sed only extracts `status:` field — see `auto-resume-after-compact-or-clear.sh:27`). However, changing the `status` field format would break parsing.
5. **Agent model selection**: Pattern confirmed across all 11 agents:
   - **Opus**: Orchestrators, architects, reviewers — complex reasoning (code-architect, plan-reviewer, test-designer, implementer, refactorer)
   - **Sonnet**: Workers doing broad exploration — high context, lower cost (code-explorer, code-reviewer)
   - Exception: `debug-explorer` and `hypothesis-generator` — model not specified in YAML (likely inherits from command's `model: opus`)
6. **Debug workflow is simpler than TDD**: Debug uses HUMAN GATES (user verifies fix, user provides logs) rather than ralph-loop automation. This means debug sessions require more user interaction but are safer — no runaway costs.

---

## File Statistics

| Metric | Count |
|--------|-------|
| Total non-git files | ~134 |
| Markdown files | ~97 |
| Shell scripts | 19 |
| JSON config files | 10 |
| JavaScript files | 4 |
| Plugin directories | 6 |
| Agent definitions | 11 (dev-workflow only) |
| Command files (dev-workflow) | 17 |
| Command files (shared) | 6 |
| Skill directories | 6+ |
| Sync scripts | 9 (8 claude-code + 1 cursor) |
| External plugins enabled | 3 (plugin-dev, hookify, claude-code-setup) |
