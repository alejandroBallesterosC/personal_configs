# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 6 plugins (TDD, Debug, Playwright, Session Feedback, Infrastructure-as-Code, CLAUDE.md Best Practices), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 6 encapsulated plugins
│   ├── tdd-workflow/  # 7 agents, 11 commands, 4 skills, 4 hooks
│   ├── debug-workflow/ # 4 agents, 7 commands, 1 skill
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
- **Hooks**: Event-driven automation (4 event types in TDD plugin)
  - `PostToolUse`: Auto-run tests after Write|Edit
  - `PreCompact`: Save workflow state before context compaction (agent)
  - `SessionEnd`: Save state before logout/clear/exit (agent)
  - `SessionStart`: Auto-restore context after reset (shell script)

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
| Test runner detection | `claude-code/plugins/tdd-workflow/hooks/run-tests.sh` (auto via PostToolUse hook) |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config (context7, fetch, exa, playwright)
- `claude-code/plugins/tdd-workflow/README.md`: TDD workflow reference
- `claude-code/plugins/debug-workflow/README.md`: Debug workflow reference
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **ralph-loop plugin** (required for TDD implement phase)
  - Install: `/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum`
  - Safety: ALWAYS set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **Claude Code** (runtime environment)

## Gotchas

- Plugins must be synced to `~/.claude/plugins/` before use
- `ralph-loop` is external dependency - install via plugin marketplace (see Dependencies)
- `claude-code/CLAUDE.md` is a TEMPLATE (syncs to ~/.claude/), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- **Context is preserved automatically** via PreCompact/SessionEnd/SessionStart hooks - no manual action needed
- Phase transitions still validate prerequisites (can't skip phases)
- Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work
- MCP servers require env vars: `CONTEXT7_API_KEY`, `EXA_API_KEY` (in `.env`, gitignored)
- TDD workflow uses hooks for state persistence; debug workflow does not (single-session design)

## Sync Usage

After modifying configs:
```bash
./scripts/sync_plugins_to_global.sh   # Copies all 6 plugins
./scripts/sync_commands_to_global.sh
./scripts/sync_skills_to_global.sh
```

Sync behavior: Last sync wins (no merge - `rm -rf` then `cp -r`).

Then load plugins:
```bash
claude --plugin-dir ~/.claude/plugins/tdd-workflow
```

Or add local marketplace:
```
/plugin marketplace add ~/.claude/plugins
```

## Documentation

- `docs/CODEBASE.md`: Full codebase analysis (architecture, workflows, Q&A)
- `claude-code/docs/`: Best practices guides (python.md, using-uv.md, docker-uv.md)
