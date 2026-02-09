# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 6 plugins (Dev Workflow, Playwright, Session Feedback, Infrastructure-as-Code, CLAUDE.md Best Practices, Ralph Loop), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 6 encapsulated plugins (installed via marketplace)
│   ├── dev-workflow/  # 11 agents, 17 commands, 6 skills, 4 hooks (TDD + Debug)
│   ├── playwright/    # Browser automation (JS + skill)
│   ├── claude-session-feedback/ # 4 commands
│   ├── infrastructure-as-code/ # 1 command, 1 skill
│   ├── claude-md-best-practices/ # 1 skill
│   └── ralph-loop/   # Iterative AI loops (3 commands, 1 hook)
├── commands/          # 6 shared global commands (syncs to ~/.claude/commands/)
├── docs/              # Python, UV, Docker best practices (syncs to ~/.claude/docs/)
└── CLAUDE.md          # Global coding standards template (syncs to ~/.claude/)
sync-content-scripts/  # 9 bidirectional sync scripts
cursor/                # Cursor IDE mirror (37 files, unidirectional sync)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop + SessionStart in dev-workflow plugin)
  - `Stop`: Archive completed workflows + run scoped tests + verify state file is up to date (agent)
  - `SessionStart`: Auto-restore context after reset (checks both TDD implementation and debug state)

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (MCP servers, VS Code tasks, plugin manifests)
- Shell scripts (sync, test runner)

No dependencies, no build, no deployment.

## Commands

| Action | Command |
|--------|---------|
| Sync commands to global | `./sync-content-scripts/claude-code/sync_commands_to_global.sh` |
| Sync docs to global | `./sync-content-scripts/claude-code/sync_docs_to_global.sh` |
| Sync MCP config to global | `./sync-content-scripts/claude-code/sync_mcp_servers_to_global.sh` |
| Sync CLAUDE.md to global | `./sync-content-scripts/claude-code/sync_claude_to_global.sh` |
| Sync all to global | Run VS Code tasks (15 sync tasks) |
| Install plugins | `/plugin marketplace add alejandroBallesterosC/personal_configs` then `/plugin install <name>` |
| Test runner detection | `claude-code/plugins/dev-workflow/hooks/run-scoped-tests.sh` (auto via Stop hook) |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config (context7, fetch, exa, playwright)
- `claude-code/plugins/dev-workflow/README.md`: Unified dev workflow reference (TDD implementation + Debug)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **yq + jq** (required for dev-workflow hooks — YAML/JSON parsing)
  - Install: `brew install yq jq` (macOS)
  - Hooks fail loudly with install instructions if missing
- **ralph-loop plugin** (required for TDD implementation phase)
  - Install: `/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum`
  - Safety: ALWAYS set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **Claude Code** (runtime environment)

## Gotchas

- `ralph-loop` is external dependency - install via plugin marketplace (see Dependencies)
- `claude-code/CLAUDE.md` is a TEMPLATE (syncs to ~/.claude/), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- **Context is preserved automatically** via Stop/SessionStart hooks - no manual action needed
- Phase transitions still validate prerequisites (can't skip phases)
- Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work
- MCP servers require env vars: `CONTEXT7_API_KEY`, `EXA_API_KEY` (in `.env`, gitignored)
- `dev-workflow` plugin contains both TDD implementation and debug workflows

## Plugin Installation

Register this repo as a Claude Code plugin marketplace, then install plugins:

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone
/plugin marketplace add /path/to/personal_configs/claude-code/plugins
```

Then install plugins via `/plugin install <name>`.

## Sync Usage

Commands, docs, MCP config, and CLAUDE.md sync to `~/.claude/` via scripts:
```bash
./sync-content-scripts/claude-code/sync_commands_to_global.sh [--overwrite]
./sync-content-scripts/claude-code/sync_docs_to_global.sh [--overwrite]
./sync-content-scripts/claude-code/sync_mcp_servers_to_global.sh
./sync-content-scripts/claude-code/sync_claude_to_global.sh
```

Plugins install via marketplace (not file sync). Skills and plugins scripts were removed in favor of the plugin system.

Sync behavior: Last sync wins (`cp -f`, optional `--overwrite` clears destination first).

## Documentation

- `docs/CODEBASE.md`: Full codebase analysis (architecture, workflows, Q&A)
- `claude-code/docs/`: Best practices guides (python.md, using-uv.md, docker-uv.md)
