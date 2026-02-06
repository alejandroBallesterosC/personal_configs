# Personal Configs - Codebase Analysis

> Last updated: 2026-02-06
> Iteration: 3 of 3 (Final)

## 1. System Purpose & Domain

Development infrastructure repository for AI-assisted workflows with Claude Code and Cursor. Contains plugins, configuration sync scripts, and IDE integrations that enable structured TDD implementation and hypothesis-driven debugging workflows.

**Core domain entities:**

| Entity | Definition Location | Purpose |
|--------|-------------------|---------|
| Plugin | `claude-code/plugins/*/` with `.claude-plugin/plugin.json` | Encapsulated workflow modules with commands, agents, skills, hooks |
| Command | `*/commands/*.md` with YAML frontmatter | User-invocable slash commands (e.g., `/dev-workflow:1-start-tdd-implementation`) |
| Agent | `*/agents/*.md` with YAML frontmatter | Specialized subagent definitions with model, tools, system prompts |
| Skill | `*/skills/*/SKILL.md` with YAML frontmatter | Auto-activating contextual guidance loaded on demand |
| Hook | `*/hooks/hooks.json` + shell/agent scripts | Event-driven automation (Stop, SessionStart, etc.) |
| State File | `docs/workflow-*/*-state.md` or `docs/debug/*/*-state.md` | YAML frontmatter + markdown workflow state |
| Sync Script | `sync-content-scripts/*/*.sh` | Bidirectional file sync between repo and `~/.claude/` or `~/.cursor/` |

**No application code.** This repo contains only: Markdown (commands/agents/skills), JSON configs, shell scripts, and one JavaScript skill (Playwright).

## 2. Technology Stack

| Category | Technologies |
|----------|-------------|
| **Primary IDE** | Claude Code (plugin system, hooks API, MCP servers) |
| **Secondary IDE** | Cursor (parallel config set, different hook format) |
| **IDE Integration** | VS Code (15 sync tasks in `.vscode/tasks.json`) |
| **AI Models** | Claude Opus (generative/reasoning), Claude Sonnet 1M (exploration/review), Claude Haiku (static content) |
| **Languages** | Markdown (~60 files), Bash (~18 scripts, 2499 LOC), JavaScript (2 files, ~450 LOC), JSON (12 configs) |
| **Browser Automation** | Playwright 1.57.0 (Node 18+) - `claude-code/plugins/playwright/skills/playwright/package.json` |
| **MCP Servers** | context7 (HTTP), fetch (stdio/uvx), exa (npx), playwright (npx) - `claude-code/global_mcp_settings.json` |
| **External Dependency** | ralph-loop plugin (iterative AI loops for TDD phases 7-9) |
| **Test Runners Supported** | pytest, vitest, jest, playwright, go test, cargo test, rspec, minitest, mix |
| **Repo Size** | 5.1 MB, ~130 tracked files |

**No build pipeline, no CI/CD, no Docker, no Python dependencies in this repo.** Docs reference uv/Python/Docker as best practices for target projects.

## 3. Architecture

### Pattern: Plugin-Based Modular Configuration

```
┌─────────────────────────────────────────────────────────────┐
│                    personal_configs (repo)                    │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  claude-code/ │  │   cursor/    │  │ sync-content-     │  │
│  │              │  │              │  │ scripts/           │  │
│  │  ┌─────────┐│  │  commands/   │  │                    │  │
│  │  │plugins/ ││  │  agents/     │  │  claude-code/ (12) │  │
│  │  │         ││  │  skills/     │  │  cursor/ (1)       │  │
│  │  │6 plugins││  │  hooks/      │  │                    │  │
│  │  └─────────┘│  └──────────────┘  └───────────────────┘  │
│  │  commands/   │           │                  │            │
│  │  docs/       │           │                  │            │
│  │  CLAUDE.md   │           │                  │            │
│  └──────────────┘           │                  │            │
│                              │                  │            │
│         ┌────────────────────┴──────────────────┘            │
│         │           Sync Scripts                             │
│         │    (bidirectional, last-sync-wins)                  │
│         ▼                                                    │
│  ~/.claude/          ~/.cursor/                              │
│  ├── plugins/        ├── commands/                           │
│  ├── commands/       ├── agents/                             │
│  ├── skills/         ├── skills/                             │
│  ├── docs/           └── hooks/                              │
│  ├── CLAUDE.md                                               │
│  └── mcp_servers.json                                        │
└─────────────────────────────────────────────────────────────┘
```

### Plugin Architecture

Each plugin follows a consistent structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Manifest: name, version, description, author, keywords
├── commands/*.md            # YAML frontmatter: description, model, argument-hint
├── agents/*.md              # YAML frontmatter: name, description, tools, model
├── skills/*/SKILL.md        # YAML frontmatter: name, description (activation trigger)
├── hooks/
│   ├── hooks.json           # Event declarations: Stop, SessionStart, etc.
│   └── *.sh                 # Hook implementation scripts
└── README.md
```

### Data Flow

State flows through the filesystem, not databases:

```
User Prompt
    │
    ▼
Command (phase entry)
    │ Creates/reads state file
    ▼
State File (docs/workflow-*/  or  docs/debug/*/)
    │ YAML frontmatter + markdown body
    ▼
Subagents (spawned via Task tool)
    │ Read-only or write access per agent tier
    ▼
Stop Hook ──► Verifies state file accuracy
    │         Runs scoped tests (.tdd-test-scope)
    ▼
SessionStart Hook ──► Restores context after compact/clear
```

## 4. Boundaries & Interfaces

### Plugin Boundaries

| Boundary | Interface | Coupling | Assessment |
|----------|----------|----------|------------|
| dev-workflow → ralph-loop | `/ralph-loop:ralph-loop` slash command | Hard dependency | Phases 7-9 require it. Prerequisite check in Phase 1. |
| dev-workflow → playwright | Skill reference in E2E testing | Soft reference | Referenced in docs/instructions, not invoked directly |
| All plugins → MCP servers | MCP tool calls (context7, fetch, exa, playwright) | Loose | Available but not required by any plugin |
| Repo → Global config | Sync scripts (`rm -rf` + `cp -r`) | One-way overwrite | Last sync wins, no merge strategy |
| Claude Code → Cursor | Separate config trees | No coupling | Different formats, separate sync scripts |

### Agent Capability Tiers

| Tier | Tools | Agents | Parallelization |
|------|-------|--------|----------------|
| Tier 1: Exploration | Glob, Grep, Read, Bash | code-explorer, code-reviewer, debug-explorer | Safe (read-only) |
| Tier 2: Planning | Glob, Grep, Read | code-architect, plan-reviewer, test-designer, hypothesis-generator | Safe (read-only) |
| Tier 3: Implementation | Read, Write, Edit, Bash, Grep, Glob | implementer, refactorer, instrumenter | Sequential only |
| Tier 4: Orchestration | All tools + Task + ralph-loop | Main instance (not a subagent) | Owns feedback loop |

### Hook Event Contracts

| Event | Input | Expected Output | Script |
|-------|-------|----------------|--------|
| Stop (test runner) | stdin: hook JSON | exit 0 (pass) or non-zero (fail) | `run-scoped-tests.sh` |
| Stop (state verify) | Agent prompt context | `{"ok": true}` or `{"ok": false, "reason": "..."}` | Inline agent (120s timeout) |
| SessionStart | stdin: `{"source": "compact\|clear"}` | `{"hookSpecificOutput": {"additionalContext": "..."}}` | `auto-resume-after-compact-or-clear.sh` |

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Unified dev-workflow plugin | Single plugin for TDD + Debug | Separate plugins | Shared hooks/agents reduce duplication; but larger plugin = more complexity per load |
| Filesystem state files | YAML frontmatter + markdown | Database, JSON, in-memory | Human-readable, git-trackable, survives crashes; but fragile sed parsing, no atomic updates |
| Stop hook for state enforcement | Agent verifies before allowing stop | Trust Claude to update state | Guarantees state accuracy; but 120s timeout adds latency, may fail on large repos |
| ralph-loop as external dependency | Separate plugin | Inline implementation | Reusable across workflows; but requires separate install, version management |
| Bidirectional sync scripts | Manual `rm -rf` + `cp -r` | Symlinks, git submodules | Simple, predictable; but last-sync-wins can lose changes, no merge |
| Sonnet for exploration/review | 1M context, cheaper | Opus for everything | Can read entire codebases; but may miss nuance that Opus would catch |
| Opus for implementation/planning | Best reasoning | Sonnet for cost savings | Higher accuracy on generative tasks; but more expensive |
| Cursor parallel configs | Separate directory tree | Shared configs with adapters | Clean separation; but duplicated content, manual sync required |

## 6. Code Quality & Patterns

### Recurring Patterns

**ABOUTME comment convention:** Every file starts with 2-line comment: `# ABOUTME: <description>`. Enforced by project CLAUDE.md.

**YAML frontmatter schema consistency:** All commands, agents, and skills use YAML frontmatter with consistent field names across plugins.

**`${CLAUDE_PLUGIN_ROOT}` path resolution:** Hook scripts resolve paths relative to plugin root using this variable.

**State file pattern:** YAML frontmatter for machine-readable fields + markdown body for human-readable progress. Used by both TDD and debug workflows.

### Shell Script Quality

| Aspect | Status | Details |
|--------|--------|---------|
| Shebang | All have `#!/bin/bash` | Consistent across all 18 scripts |
| Error handling | `set -e` in all sync scripts | Hook scripts handle errors differently (exit 0 for non-fatal) |
| ABOUTME headers | Present in all scripts | 2-line format as per CLAUDE.md convention |
| Quoting | Generally good | Some unquoted `$variables` in test runner scripts (potential word-splitting) |
| `set -o pipefail` | Missing from all scripts | Could hide pipe failures |
| `set -u` (nounset) | Missing from all scripts | Unset variables won't cause errors |
| shellcheck | Not configured | No CI to enforce it |

### YAML Parsing Concern

State files parsed via `sed` one-liners:
```bash
sed -n '/^---$/,/^---$/{ /^status:/{ s/^status: *//; s/ *$//; p; } }'
```
This is fragile for: multiline values, quoted strings, comments, `---` within values.

### Testing Strategy

**No automated tests for this repo itself.** The repo supports test-driven development in target projects via:
- `.tdd-test-scope` file mechanism (Stop hook reads scope, runs targeted tests)
- `detect-test-runner.sh` (9 frameworks supported)
- `run-scoped-tests.sh` (280 lines, multi-runner executor)

### Git History Patterns

- Single author (Alejandro Ballesteros)
- Co-authored commits with Claude Opus 4.5/4.6
- Descriptive commit messages (multi-paragraph for complex changes)
- Single branch (`main`), no PR workflow
- Active development: 15+ commits in last 35 hours
- Recent evolution: debug-workflow → unified dev-workflow (consolidated in last 20 hours)

### Security

| Item | Status |
|------|--------|
| `.env` file | Gitignored (contains CONTEXT7_API_KEY, EXA_API_KEY) |
| `.gitignore` | Covers `*.env`, `*.claude.json`, `.DS_Store` |
| API keys in code | Not hardcoded; `${VAR}` placeholders in MCP config |
| Permission model | `.claude/settings.local.json` with allowlisted commands |
| Credential rotation | No mechanism documented |

## 7. Documentation Accuracy Audit

### CRITICAL: README.md is severely stale

The root `README.md` still references the **old** plugin names and commands from before the consolidation into `dev-workflow`. This is the most significant documentation issue.

| Doc Claim | Reality | File Reference |
|-----------|---------|---------------|
| **README references `tdd-workflow/` plugin** | Renamed to `dev-workflow/` (unified TDD + Debug) | `README.md:11,31,49` |
| **README references `debug-workflow/` plugin** | Merged into `dev-workflow/` | `README.md:12,53,62` |
| **README: `/tdd-workflow:1-start`** | Correct command: `/dev-workflow:1-start-tdd-implementation` | `README.md:49,133` |
| **README: `reinitialize-context-after-clear-and-continue-workflow`** | No longer exists. Use `/dev-workflow:continue-workflow` | `README.md:50,140` |
| **README: `/debug-workflow:debug`** | Correct command: `/dev-workflow:1-start-debug` | `README.md:62` |
| **README: `scripts/sync_plugins_to_global.sh`** | Actual path: `sync-content-scripts/claude-code/sync_plugins_to_global.sh` | `README.md:112` |
| **README: `claude-session-feedback` has "3 commands"** | Actually has 4 commands | `README.md:70` |
| README says "6 plugins" | Correct (6 in repo) | `README.md:3` - Accurate |
| CLAUDE.md (project) says "5 plugins" | Actually 6 (missing ralph-loop from count) | `CLAUDE.md:5` |
| CLAUDE.md says "4 hooks" | 3 hook events (2 Stop + 1 SessionStart) across 4 shell scripts | `CLAUDE.md:10` |
| dev-workflow README says "11 agents, 17 commands, 6 skills" | Verified accurate | `claude-code/plugins/dev-workflow/README.md` |

### Template CLAUDE.md vs Project CLAUDE.md divergence

The file `claude-code/CLAUDE.md` is a **template** that syncs to `~/.claude/CLAUDE.md`. It differs from the project's `CLAUDE.md` in several ways:
- Template says "NEVER implement a mock mode" (absolute); Project CLAUDE.md has a more nuanced mock policy
- Template references `github issues`; Project CLAUDE.md doesn't
- Template omits `ast-grep` rule; Project CLAUDE.md includes it
- Template says "Write the implementation"; Project CLAUDE.md says "Write minimal code to make the test pass"

## 8. Open Questions

### Answered in Iteration 2
- [x] ~~How do dev-workflow and ralph-loop Stop hooks interact?~~ Both register Stop hooks independently. dev-workflow runs test + state verification; ralph-loop blocks exit and re-feeds prompt. When both active during Phases 7-9, ralph-loop takes precedence (blocks exit regardless of dev-workflow verdict).
- [x] ~~What format does the hook decision use?~~ dev-workflow state agent: `{"ok": true/false}`. ralph-loop: `{"decision": "block", "reason": "..."}`.

### Still Open
- [ ] **CRITICAL: README.md is severely stale** - still references old `tdd-workflow`/`debug-workflow` plugin names and commands. Needs complete rewrite.
- [ ] Why does the Cursor config duplicate so much from Claude Code instead of using a shared source with format adapters?
- [ ] Should sync scripts use symlinks instead of copy to avoid drift?
- [ ] Is the 120s Stop hook timeout sufficient for large repos with many changed files?
- [ ] Should shell scripts use `set -o pipefail` and `set -u` for robustness?
- [ ] Should the `sed`-based YAML parsing be replaced with `yq` for reliability?
- [ ] How does the system handle concurrent workflows across different worktrees?
- [ ] Should there be a PostToolUse formatting hook (per Boris Cherny's recommendation)?
- [ ] Should marketplace.json auto-update when plugins are added/removed?
- [ ] Template CLAUDE.md vs Project CLAUDE.md have diverged - should they be reconciled?
- [ ] The `continue-workflow` command and `auto-resume` hook share duplicated logic - should this be extracted?

## 9. Iteration 3 Findings: Code Path Verification

### Confirmed: Logic duplication between hook and command

The `auto-resume-after-compact-or-clear.sh` hook and `continue-workflow.md` command perform the same core operations:
1. Scan for state files in `docs/workflow-*/*-state.md` and `docs/debug/*/*-state.md`
2. Parse YAML frontmatter for `status: in_progress`
3. Build list of context restoration files
4. Inject workflow context into the session

**Difference:** The hook fires automatically on compact/clear and uses shell/JSON output. The command is manually invoked and uses markdown prompt instructions. Both enumerate the same artifact files. Changes to one must be manually mirrored in the other.

### Confirmed: sed YAML parsing is used in 2 locations

1. `auto-resume-after-compact-or-clear.sh:27,48` - parses `status` field
2. Same pattern would apply to any future hooks reading frontmatter

Both use: `sed -n '/^---$/,/^---$/{ /^status:/{ s/^status: *//; s/ *$//; p; } }'`

### Verified: Stop hook ordering

When both dev-workflow and ralph-loop are active (Phases 7-9):
- dev-workflow Stop hooks run first (test runner + state verification)
- ralph-loop Stop hook runs second (blocks exit, re-feeds prompt)
- Since ralph-loop blocks with `{"decision": "block"}`, the dev-workflow test results appear in output but don't prevent the loop from continuing

### Verified: Sync script safety

`sync_plugins_to_global.sh:40` always does `rm -rf` before `cp -r`, even without `--overwrite`. The `--overwrite` flag only controls whether plugins NOT in the repo are also removed from the destination. With or without the flag, repo plugins always overwrite their destination counterparts.

## 10. Ambiguities

**Cursor format differences:** The cursor/ directory contains parallel implementations of commands, agents, skills, and hooks in Cursor's format (camelCase events, version: 1, no plugin prefixes). It's unclear how actively this is maintained vs. Claude Code being primary.

**Plugin discovery:** Marketplace.json lists 6 plugins but it's a static registry. There's no auto-discovery mechanism for new plugins added to the directory.

**Hook ordering:** When both dev-workflow Stop hooks and ralph-loop Stop hooks are active, the execution order and interaction between them is not documented.

**State file atomicity:** The state file is updated by the main Claude instance but verified by the Stop hook agent. There's no locking mechanism if both try to access simultaneously (unlikely but possible in edge cases).

**Sync conflict resolution:** "Last sync wins" means if you edit a plugin globally and also in the repo, the last sync direction overwrites the other. No warning or diff is shown.
