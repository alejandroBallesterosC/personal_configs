# Personal Development Configurations

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains configuration, documentation, plugins, and automation scripts.

## Repository Structure

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # Encapsulated workflow plugins
│   │   ├── tdd-workflow/           # 7 agents, 11 commands, 6 skills, hooks
│   │   └── debug-workflow/         # 4 agents, 7 commands, 1 skill
│   ├── commands/                   # 16 shared global commands
│   ├── docs/                       # Python, UV, Docker best practices
│   ├── CLAUDE.md                   # Global coding standards template
│   └── global_mcp_settings.json    # MCP server configuration
├── scripts/                        # 13 sync scripts (bidirectional)
├── .vscode/                        # VS Code tasks (15 sync tasks)
├── .cursor/                        # Cursor IDE configurations
├── CODEBASE.md                     # Comprehensive codebase analysis
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

**Phase Validation:** The resume command validates prerequisites before allowing continuation. For example, resuming Phase 7 requires Phases 2-6 (including Review and Approval) to be complete. This prevents accidental phase skipping.

**Commands:**
- `/tdd-workflow:1-start <feature> "<description>"` - Start workflow
- `/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow <feature> --phase N` - Resume after /clear
- `/tdd-workflow:2-explore`, `/tdd-workflow:4-plan-architecture`, `/tdd-workflow:5-plan-implementation`, `/tdd-workflow:7-implement`, `/tdd-workflow:9-review`

### Debug Workflow (`claude-code/plugins/debug-workflow/`)

A 9-phase hypothesis-driven debugging workflow with instrumentation and evidence-based analysis.

**Flow:** EXPLORE -> DESCRIBE -> HYPOTHESIZE -> INSTRUMENT -> REPRODUCE -> ANALYZE -> FIX -> VERIFY -> CLEAN

**Commands:**
- `/debug-workflow:debug` - Start debugging workflow
- `/debug-workflow:explore`, `/debug-workflow:hypothesize`, `/debug-workflow:instrument`, `/debug-workflow:analyze`, `/debug-workflow:verify`

## MCP Servers

Configured in `claude-code/global_mcp_settings.json`:
- **context7**: Documentation retrieval
- **fetch**: URL content fetching
- **exa**: Web search
- **playwright**: Browser automation

## Sync Scripts

Bidirectional sync between this repo and `~/.claude/`:

| Script | Direction |
|--------|-----------|
| `sync_plugins_to_global.sh` | Plugins -> ~/.claude/plugins/ |
| `sync_commands_to_global.sh` | Commands -> ~/.claude/commands/ |
| `sync_skills_to_global.sh` | Skills -> ~/.claude/skills/ |
| `sync_docs_to_global.sh` | Docs -> ~/.claude/docs/ |
| `sync_claude_md_to_global.sh` | CLAUDE.md -> ~/.claude/ |
| `sync_mcp_settings_to_global.sh` | MCP config -> ~/.claude/ |

All scripts support `--overwrite` flag. Reverse sync scripts (`*_from_global.sh`) also available.

## Usage

### First-time Setup

```bash
# Sync plugins to global
./scripts/sync_plugins_to_global.sh

# Load plugin
claude --plugin-dir ~/.claude/plugins/tdd-workflow
```

### Start TDD Workflow

```bash
/tdd-workflow:1-start my-feature "Add user authentication"
```

### Resume After Context Clear

```bash
/clear
/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow my-feature --phase 6
```

## External Dependencies

- **ralph-loop plugin** (required for TDD implement phase)
- **Claude Code** (runtime environment)
- **uv** (Python package management)

## Documentation

- `CODEBASE.md` - Comprehensive codebase analysis with workflow traces
- `claude-code/plugins/tdd-workflow/README.md` - TDD workflow reference
- `claude-code/plugins/debug-workflow/README.md` - Debug workflow reference
- `claude-code/docs/` - Python, UV, Docker best practices

---

*Configuration repository for AI-assisted development workflows.*
