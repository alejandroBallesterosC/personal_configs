# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains two major plugins (TDD workflow, Debug workflow), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # Encapsulated workflows (TDD, Debug)
│   ├── tdd-workflow/  # 7 agents, 10 commands, 6 skills, hooks
│   └── debug-workflow/ # 4 agents, 7 commands, 1 skill
├── commands/          # Shared command templates
├── docs/              # Python, UV, Docker best practices
└── CLAUDE.md          # Global template (syncs to ~/.claude/)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: `PostToolUse` triggers (e.g., auto-run tests after Write|Edit)

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (MCP servers, VS Code tasks, plugin manifests)
- Shell scripts (sync, test runner)

No dependencies, no build, no deployment.

## Commands

| Action | Command |
|--------|---------|
| Sync plugins to global | `./scripts/sync_plugins_to_global.sh` |
| Sync all to global | Run VS Code tasks (15 sync tasks) |
| Test runner detection | `./scripts/run-tests.sh` (auto via hooks) |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config
- `claude-code/plugins/tdd-workflow/README.md`: TDD workflow reference
- `claude-code/plugins/debug-workflow/README.md`: Debug workflow reference
- `CODEBASE.md`: Comprehensive codebase analysis

## Dependencies

- **ralph-loop plugin** (required for TDD implement phase)
- **Claude Code** (runtime environment)

## Gotchas

- `README.md` is severely outdated - see `CODEBASE.md` for accurate docs
- Plugins must be synced to `~/.claude/plugins/` before use
- `ralph-loop` is external dependency, not included
- `claude-code/CLAUDE.md` is a TEMPLATE (syncs to ~/.claude/), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- Context checkpoints are manual (/clear + /resume), not automatic

## Sync Usage

After modifying configs:
```bash
./scripts/sync_plugins_to_global.sh
./scripts/sync_commands_to_global.sh
./scripts/sync_skills_to_global.sh
```

Then load plugins:
```bash
claude --plugin-dir ~/.claude/plugins/tdd-workflow
```

Or:
```
/plugin marketplace add ~/.claude/plugins
```
