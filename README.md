# Personal Development Configurations

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 6 plugins, configuration sync scripts, and IDE integrations.

## Repository Structure

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # 6 encapsulated workflow plugins
│   │   ├── tdd-workflow/           # 7 agents, 11 commands, 4 skills, hooks
│   │   ├── debug-workflow/         # 4 agents, 7 commands, 1 skill
│   │   ├── playwright/             # Browser automation (JS + skill)
│   │   ├── claude-session-feedback/ # 3 commands
│   │   ├── infrastructure-as-code/ # 1 command, 1 skill
│   │   └── claude-md-best-practices/ # 1 skill
│   ├── commands/                   # Shared global commands
│   ├── docs/                       # Python, UV, Docker best practices
│   ├── CLAUDE.md                   # Global coding standards template
│   └── global_mcp_settings.json    # MCP server configuration
├── scripts/                        # 13 sync scripts (bidirectional)
├── .vscode/                        # VS Code tasks (15 sync tasks)
├── .cursor/                        # Cursor IDE configurations
├── docs/
│   └── CODEBASE.md                 # Comprehensive codebase analysis
└── CLAUDE.md                       # Project-specific instructions
```

## Core Plugins

### TDD Workflow (`claude-code/plugins/tdd-workflow/`)

An 8-phase (Phases 2-9) Test-Driven Development workflow with parallel exploration, specification interview, architecture design, implementation planning, and review phases.

**Key Features:**
- Parallel exploration with 5 code-explorer agents (Phase 2)
- Specification interview with 40+ questions (Phase 3)
- Architecture design before implementation planning (Phase 4 → Phase 5)
- Plan review and approval gates before implementation (Phase 6)
- Orchestrated TDD with ralph-loop integration (Phase 7)
- E2E testing (Phase 8)
- Parallel code review with 5 specialized reviewers + fixes (Phase 9)
- Context checkpoints with phase validation on resume
- Auto-test hook on Write/Edit operations

**Phase Validation:** The resume command validates prerequisites before allowing continuation. For example, resuming Phase 7 requires Phases 2-6 (including Review and Approval) to be complete.

**Commands:**
- `/tdd-workflow:1-start <feature> "<description>"` - Start workflow
- `/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow <feature> --phase N` - Resume after /clear
- `/tdd-workflow:help` - Show all commands

### Debug Workflow (`claude-code/plugins/debug-workflow/`)

A 9-phase hypothesis-driven debugging workflow with instrumentation and evidence-based analysis.

**Flow:** EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN

**Iron Law:** No fixes until root cause is proven.

**Commands:**
- `/debug-workflow:debug "<bug description>"` - Start debugging workflow
- `/debug-workflow:help` - Show all commands

### Other Plugins

| Plugin | Purpose | Components |
|--------|---------|------------|
| **playwright** | Browser automation with Playwright | JS executor + skill |
| **claude-session-feedback** | Export conversations, read history, provide feedback | 3 commands |
| **infrastructure-as-code** | Terraform and AWS management | 1 command, 1 skill |
| **claude-md-best-practices** | CLAUDE.md writing guidance | 1 skill |

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

## Sync Scripts

Bidirectional sync between this repo and `~/.claude/`:

| Script | Direction |
|--------|-----------|
| `sync_plugins_to_global.sh` | Plugins → ~/.claude/plugins/ |
| `sync_commands_to_global.sh` | Commands → ~/.claude/commands/ |
| `sync_skills_to_global.sh` | Skills → ~/.claude/skills/ |
| `sync_docs_to_global.sh` | Docs → ~/.claude/docs/ |
| `sync_claude_to_global.sh` | CLAUDE.md → ~/.claude/ |
| `sync_mcp_servers_to_global.sh` | MCP config → ~/.claude/ |

All scripts support `--overwrite` flag. Reverse sync scripts (`*_from_global.sh`) also available.

## Usage

### First-time Setup

```bash
# Sync plugins to global
./scripts/sync_plugins_to_global.sh

# Load plugin (option 1)
claude --plugin-dir ~/.claude/plugins/tdd-workflow

# Or add local marketplace (option 2)
/plugin marketplace add ~/.claude/plugins
```

### Install External Dependencies

```bash
# ralph-loop is required for TDD implementation phase
/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum
```

**Warning:** Always set `--max-iterations` with ralph-loop (50 iterations = $50-100+ in API costs).

### Start TDD Workflow

```bash
/tdd-workflow:1-start my-feature "Add user authentication"
```

### Resume After Context Clear

```bash
/clear
/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow my-feature --phase 7
```

## External Dependencies

- **ralph-loop plugin** (required for TDD implement phase)
- **Claude Code** (runtime environment)
- **uv** (Python package management, referenced in docs)
- **Node.js 18+** (for Playwright plugin)

## Documentation

- `docs/CODEBASE.md` - Comprehensive codebase analysis with workflow traces
- `claude-code/plugins/tdd-workflow/README.md` - TDD workflow reference
- `claude-code/plugins/debug-workflow/README.md` - Debug workflow reference
- `claude-code/docs/` - Python, UV, Docker best practices

---

*Configuration repository for AI-assisted development workflows.*
