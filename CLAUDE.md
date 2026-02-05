# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 4 plugins (Dev Workflow, Playwright, Session Feedback, Infrastructure-as-Code, CLAUDE.md Best Practices), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 5 encapsulated plugins
│   ├── dev-workflow/  # 11 agents, 17 commands, 6 skills, 4 hooks (TDD implementation + Debug)
│   ├── playwright/    # Browser automation (JS + skill)
│   ├── claude-session-feedback/ # 4 commands
│   ├── infrastructure-as-code/ # 1 command, 1 skill
│   └── claude-md-best-practices/ # 1 skill
├── commands/          # Shared command templates
├── docs/              # Python, UV, Docker best practices
└── CLAUDE.md          # Global template (syncs to ~/.claude/)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop + SessionStart in dev-workflow plugin)
  - `Stop`: Run scoped tests + verify state file is up to date (agent)
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
| Sync plugins to global | `./scripts/sync_plugins_to_global.sh` |
| Sync all to global | Run VS Code tasks (15 sync tasks) |
| Test runner detection | `claude-code/plugins/dev-workflow/hooks/run-scoped-tests.sh` (auto via Stop hook) |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config (context7, fetch, exa, playwright)
- `claude-code/plugins/dev-workflow/README.md`: Unified dev workflow reference (TDD implementation + Debug)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **ralph-loop plugin** (required for TDD implementation phase)
  - Install: `/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum`
  - Safety: ALWAYS set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **Claude Code** (runtime environment)

## Gotchas

- Plugins must be synced to `~/.claude/plugins/` before use
- `ralph-loop` is external dependency - install via plugin marketplace (see Dependencies)
- `claude-code/CLAUDE.md` is a TEMPLATE (syncs to ~/.claude/), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- **Context is preserved automatically** via Stop/SessionStart hooks - no manual action needed
- Phase transitions still validate prerequisites (can't skip phases)
- Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work
- MCP servers require env vars: `CONTEXT7_API_KEY`, `EXA_API_KEY` (in `.env`, gitignored)
- `dev-workflow` plugin contains both TDD implementation and debug workflows

## Sync Usage

After modifying configs:
```bash
./scripts/sync_plugins_to_global.sh   # Copies all 5 plugins
./scripts/sync_commands_to_global.sh
./scripts/sync_skills_to_global.sh
```

Sync behavior: Last sync wins (no merge - `rm -rf` then `cp -r`).

Then load plugins:
```bash
claude --plugin-dir ~/.claude/plugins/dev-workflow
```

Or add local marketplace:
```
/plugin marketplace add ~/.claude/plugins
```

## Documentation

- `docs/CODEBASE.md`: Full codebase analysis (architecture, workflows, Q&A)
- `claude-code/docs/`: Best practices guides (python.md, using-uv.md, docker-uv.md)
