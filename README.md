# Personal Development Configurations

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 9 plugins, configuration sync scripts, and IDE integrations.

## Repository Structure

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # 9 encapsulated workflow plugins
│   │   ├── dev-workflow/           # 12 agents, 20 commands, 6 skills, 5 hooks (TDD + Debug)
│   │   ├── research-report/        # 4 agents, 3 commands, 1 skill, 2 hooks (Iterative research + LaTeX)
│   │   ├── long-horizon-impl/      # 9 agents, 4 commands, 1 skill, 2 hooks (Research/Plan/Implement)
│   │   ├── playwright/             # Browser automation (1 skill, token-efficient CLI)
│   │   ├── claude-session-feedback/ # 4 commands
│   │   ├── infrastructure-as-code/ # 1 command, 1 skill
│   │   ├── claude-md-best-practices/ # 1 skill
│   │   ├── ralph-loop/            # Iterative AI loops (3 commands, 1 hook)
│   │   └── notify/                # Terminal bell + macOS banner notifications (2 hooks)
│   ├── agents/                     # Global subagents (symlinked to ~/.claude/agents/)
│   ├── commands/                   # Shared global commands (symlinked to ~/.claude/commands/)
│   ├── docs/                       # Python, UV, Docker best practices (symlinked to ~/.claude/docs/)
│   ├── CLAUDE.md                   # Global coding standards template (symlinked to ~/.claude/)
│   └── global_mcp_settings.json    # MCP server configuration
├── cursor/                         # Cursor IDE parallel configs
├── sync-content-scripts/           # Symlink setup (Claude Code) + copy sync (Cursor)
├── .vscode/                        # VS Code tasks (16 total: 9 working sync + 4 dead sync + 3 other)
├── docs/
│   └── CODEBASE.md                 # Comprehensive codebase analysis
└── CLAUDE.md                       # Project-specific instructions
```

## Core Plugin: Dev Workflow

### `claude-code/plugins/dev-workflow/`

A unified plugin combining an **8-phase TDD implementation workflow** and a **9-phase hypothesis-driven debugging workflow**. 12 specialized agents, 20 commands, 6 skills, and automatic context preservation via hooks.

### TDD Implementation Workflow (Phases 2-9)

```
Phase 2: EXPLORE (5 parallel agents) → Phase 3: INTERVIEW (40+ questions)
→ Phase 4: ARCHITECTURE → Phase 5: IMPLEMENTATION PLAN
→ Phase 6: PLAN REVIEW (approval gate) → Phase 7: TDD IMPLEMENT (ralph-loop)
→ Phase 8: E2E TESTING → Phase 9: PARALLEL REVIEW (5 agents) → COMPLETE
```

**Key Features:**
- Parallel exploration with 5 code-explorer agents (Phase 2)
- Specification interview with 40+ questions (Phase 3)
- Architecture design before implementation planning (Phase 4 → Phase 5)
- Plan review and approval gate before implementation (Phase 6)
- Orchestrated TDD with ralph-loop integration (Phase 7)
- E2E testing (Phase 8)
- Parallel code review with 5 specialized reviewers + fixes (Phase 9)
- Automatic context preservation via Stop + SessionStart hooks

**Commands:**
```bash
# Start the full orchestrated workflow
/dev-workflow:1-start-tdd-implementation my-feature "Add user authentication"

# Resume after context clear or fresh session
/dev-workflow:continue-workflow my-feature

# Run individual phases
/dev-workflow:2-explore my-feature "description"
/dev-workflow:3-user-specification-interview my-feature "description"
/dev-workflow:4-plan-architecture my-feature
/dev-workflow:5-plan-implementation my-feature
/dev-workflow:6-review-plan my-feature
/dev-workflow:7-implement my-feature "description"
/dev-workflow:8-e2e-test my-feature "description"
/dev-workflow:9-review my-feature

# Help
/dev-workflow:help
```

### Debug Workflow (9 Phases)

```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

**Iron Law:** No fixes until root cause is proven. **3-Fix Rule:** After 3 failed fixes, question the architecture. Debug instrumentation writes to `logs/debug-output.log` (overwritten per run) — Claude reads it directly, no copy/paste needed.

**Commands:**
```bash
# Start full debug workflow
/dev-workflow:1-start-debug "API returns 500 error when user has emoji in name"

# Run individual phases
/dev-workflow:2-explore-debug user-api
/dev-workflow:4-hypothesize emoji-bug
/dev-workflow:5-instrument emoji-bug
# [user reproduces bug, logs captured to logs/debug-output.log]
/dev-workflow:7-analyze emoji-bug
/dev-workflow:9-verify emoji-bug
```

### Research Report Plugin

### `claude-code/plugins/research-report/`

Autonomous iterative deep research producing LaTeX reports with synthesis, 9 research strategies, parallel subagents, and strategy rotation.

**Commands:**
```bash
/research-report:research "topic" "prompt"
/research-report:continue-research topic-name
/research-report:help
```

### Long Horizon Implementation Plugin

### `claude-code/plugins/long-horizon-impl/`

Long-running autonomous research, planning, and TDD implementation with parallel subagents, anti-slop escalation, and multi-day execution.

**Commands:**
```bash
/long-horizon-impl:1-research-and-plan "project" "prompt"
/long-horizon-impl:2-implement project-name
/long-horizon-impl:continue-workflow project-name
/long-horizon-impl:help
```

### Other Plugins

| Plugin | Purpose | Components |
|--------|---------|------------|
| **playwright** | Browser automation with Playwright | 1 skill (token-efficient CLI) |
| **ralph-loop** | Iterative AI loops for autonomous development | 3 commands, 1 hook |
| **claude-session-feedback** | Export conversations, read history, provide feedback | 4 commands |
| **infrastructure-as-code** | Terraform and AWS management | 1 command, 1 skill |
| **claude-md-best-practices** | CLAUDE.md writing guidance | 1 skill |
| **notify** | Terminal bell + macOS banner notifications | 2 hooks (Notification, Stop) |

## MCP Servers

Configured in `claude-code/global_mcp_settings.json`:

| Server | Type | Purpose |
|--------|------|---------|
| **context7** | HTTP | Documentation retrieval |
| **fetch** | stdio | URL content fetching |
| **exa** | npx | Web search + code context |
| **playwright** | npx | Browser automation |

**Environment Variables Required:**
```bash
CONTEXT7_API_KEY  # For context7 HTTP server
EXA_API_KEY       # For exa web search
```

Store in `.env` file (gitignored).

## Sync Setup

### Claude Code (symlinks)

Claude Code agents, commands, docs, and CLAUDE.md are symlinked from this repo to `~/.claude/`:

```bash
# One-time setup (idempotent, backs up existing files)
./sync-content-scripts/claude-code/setup_symlinks.sh
```

This creates four symlinks:
- `~/.claude/CLAUDE.md` → `claude-code/CLAUDE.md`
- `~/.claude/agents/` → `claude-code/agents/`
- `~/.claude/commands/` → `claude-code/commands/`
- `~/.claude/docs/` → `claude-code/docs/`

Edits in this repo are immediately reflected in Claude Code. No re-sync needed.

### Cursor (copy-based)

Cursor configs use copy-based sync because Cursor has known bugs with symlinked directories:

```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

### Plugins

Plugins install via the marketplace system (not file sync):
```bash
/plugin marketplace add alejandroBallesterosC/personal_configs
/plugin install dev-workflow
```

## Usage

### Plugin Installation

Register this repo as a Claude Code plugin marketplace, then install plugins:

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone
/plugin marketplace add /path/to/personal_configs/claude-code/plugins
```

Then install plugins:
```bash
/plugin install dev-workflow
/plugin install research-report
/plugin install long-horizon-impl
/plugin install playwright
/plugin install claude-session-feedback
/plugin install infrastructure-as-code
/plugin install ralph-loop
/plugin install claude-md-best-practices
/plugin install notify
```

### Install External Dependencies

```bash
# ralph-loop is required for TDD implementation phases 7-9
/plugin marketplace add alejandroBallesterosC/personal_configs && /plugin install ralph-loop
```

**Warning:** Always set `--max-iterations` with ralph-loop (50 iterations = $50-100+ in API costs).

### Context Preservation

Context is preserved automatically via hooks:
- **Stop hook**: Runs scoped tests + verifies state file accuracy before allowing Claude to stop (dev-workflow), iteration engine + completion verifier (research-report, long-horizon-impl), terminal bell + macOS banner (notify)
- **SessionStart hook**: Auto-restores workflow context after `/compact` or `/clear` (dev-workflow, research-report, long-horizon-impl)
- **Notification hook**: Terminal bell + macOS banner when Claude needs input (notify)
- **Manual resume**: `/dev-workflow:continue-workflow <name>`, `/research-report:continue-research <name>`, or `/long-horizon-impl:continue-workflow <name>` for fresh sessions

## External Dependencies

- **ralph-loop plugin** (required for long-horizon-impl 2-implement only; dev-workflow uses its own built-in Stop hook)
- **Claude Code** (runtime environment)
- **yq + jq** (required for dev-workflow, research-report, and long-horizon-impl hooks — `brew install yq jq` on macOS)
- **terminal-notifier** (optional, for notify plugin — `brew install terminal-notifier` on macOS; falls back to osascript)
- **uv** (Python package management, referenced in docs)
- **MacTeX** (optional, for research-report and long-horizon-impl LaTeX PDF compilation)

## Documentation

- `docs/CODEBASE.md` - Comprehensive codebase analysis (architecture, workflows, open questions)
- `claude-code/plugins/dev-workflow/README.md` - Dev workflow plugin reference
- `claude-code/plugins/research-report/README.md` - Research report plugin reference
- `claude-code/plugins/long-horizon-impl/README.md` - Long-horizon implementation reference
- `claude-code/docs/` - Python, UV, Docker best practices

---

*Configuration repository for AI-assisted development workflows.*
