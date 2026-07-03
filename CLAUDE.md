# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 5 plugins (Core Workflow, Playwright, Infrastructure-as-Code, Notify, Precise Technical Communication), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 5 encapsulated plugins (installed via marketplace)
│   ├── core-workflow/ # 6 commands, 6 skills, 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
│   ├── playwright/    # Browser automation (1 skill, token-efficient CLI)
│   ├── infrastructure-as-code/ # 1 command, 1 skill
│   ├── notify/       # Terminal bell + macOS banner notifications (2 hooks: Notification, Stop)
│   └── precise-technical-communication/ # 1 skill (precise, auditable technical reporting)
├── agents/            # Global subagents (symlinked to ~/.claude/agents/)
├── commands/          # Shared global commands (symlinked to ~/.claude/commands/)
├── docs/              # Python, UV, Docker best practices (symlinked to ~/.claude/docs/)
└── CLAUDE.md          # Global coding standards template (symlinked to ~/.claude/)
sync-content-scripts/  # Symlink setup script (Claude Code) + 1 copy-based sync script (Cursor)
cursor/                # Cursor IDE mirror (TDD-only removed; commands/skills unidirectional sync)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop, Notification) — only `notify` uses hooks in this repo
  - `Stop`: terminal bell + macOS banner (notify)
  - `Notification`: terminal bell + macOS banner when Claude needs input (notify)
- **Project-level hooks** (`.claude/hooks/`): `document-learnings.sh` Stop hook prompts Claude to document architectural decisions and insights after implementation work

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (MCP servers, VS Code tasks, plugin manifests)
- Shell scripts (sync, test runner)

No build, no deployment. Runtime dependencies: none required (see Dependencies).

## Commands

| Action | Command |
|--------|---------|
| Set up Claude Code symlinks | `./sync-content-scripts/claude-code/setup_symlinks.sh` |
| Sync Cursor configs | `./sync-content-scripts/cursor/sync_to_cursor.sh` |
| Install plugins | `/plugin marketplace add alejandroBallesterosC/personal_configs` then `/plugin install <name>` |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config (context7, fetch, exa, playwright)
- `claude-code/plugins/core-workflow/README.md`: Core workflow plugin reference (commands, skills, agent)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only — skips gracefully if absent)
- **Claude Code** (runtime environment)

## Gotchas

- `claude-code/CLAUDE.md` is a TEMPLATE (symlinked to ~/.claude/CLAUDE.md), not this repo's CLAUDE.md
- **Context is preserved automatically** via the notify plugin's hooks for user-input signaling — `core-workflow` has no hooks or workflow state to preserve across sessions
- Two `marketplace.json` files exist: root (for GitHub install) and `claude-code/plugins/` (for local install) — both point to the same 5 plugins
- All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). If any hook returns `decision: "block"`, Claude continues — the most restrictive decision wins after all hooks complete. There is no sequential ordering or short-circuit between plugins
- Plugin state files (debug logs, config overrides) are stored in `.plugin-state/` at the project repo root, NOT in `.claude/` — this avoids Claude Code's hardcoded `.claude/` directory write protection (v2.1.78+). Currently unused by any active plugin (only historical, now-deleted plugins wrote here)

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

Claude Code commands, docs, and CLAUDE.md are symlinked from this repo to `~/.claude/`:
```bash
# One-time setup (idempotent, backs up existing files)
./sync-content-scripts/claude-code/setup_symlinks.sh
```

This creates four symlinks:
- `~/.claude/CLAUDE.md` → `claude-code/CLAUDE.md`
- `~/.claude/commands/` → `claude-code/commands/`
- `~/.claude/agents/` → `claude-code/agents/`
- `~/.claude/docs/` → `claude-code/docs/`

Cursor configs use copy-based sync (symlinks are unreliable in Cursor):
```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

Plugins install via marketplace (not file sync).

## Documentation

- `docs/CODEBASE.md`: Full codebase analysis (architecture, workflows, Q&A)
- `claude-code/docs/`: Best practices guides (python.md, using-uv.md, docker-uv.md)
