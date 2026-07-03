# Personal Configs

Claude Code plugin marketplace repository. Contains 5 plugins (Core Workflow, Playwright, Infrastructure-as-Code, Notify, Precise Technical Communication). No global Claude Code configuration (CLAUDE.md template, global commands/agents/docs) lives here — those are maintained elsewhere and this repo installs only via the plugin system.

## Architecture

```
claude-code/
└── plugins/           # 5 encapsulated plugins (installed via marketplace)
    ├── core-workflow/  # 6 commands, 6 skills, 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
    ├── playwright/     # Browser automation (1 skill, token-efficient CLI)
    ├── infrastructure-as-code/ # 1 command, 1 skill
    ├── notify/         # Terminal bell + macOS banner notifications (2 hooks: Notification, Stop)
    └── precise-technical-communication/ # 1 skill (precise, auditable technical reporting)
CLAUDE.md          # This file
docs/CODEBASE.md   # Repo analysis
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop, Notification) — only `notify` uses hooks in this repo
- **Project-level hooks** (`.claude/hooks/`): `document-learnings.sh` Stop hook prompts Claude to document architectural decisions and insights after implementation work

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (plugin manifests)
- Shell scripts (hooks)

No build, no deployment, no sync scripts. Distribution is exclusively via the Claude Code plugin marketplace.

## Plugin Installation

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone
/plugin marketplace add /path/to/personal_configs/claude-code/plugins
```

Then install plugins via `/plugin install <name>`.

## Key Files

- `claude-code/plugins/core-workflow/README.md`: Core workflow plugin reference (commands, skills, agent)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only — skips gracefully if absent)
- **terminal-notifier** (optional, for `notify` — falls back to `osascript`)
- **Claude Code** (runtime environment)

## Gotchas

- Two `marketplace.json` files exist: root (`.claude-plugin/marketplace.json`, for GitHub install) and `claude-code/plugins/.claude-plugin/marketplace.json` (for local install) — both must list the same 5 plugins, kept in sync manually
- All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). If any hook returns `decision: "block"`, Claude continues — the most restrictive decision wins after all hooks complete
- This repo previously also hosted global Claude Code configuration (a CLAUDE.md template, global commands/agents/docs symlinked to `~/.claude/`) and a Cursor IDE mirror — both were removed; this repo is now plugins-only
