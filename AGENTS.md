# Personal Configs

Claude Code plugin marketplace repository. Contains 10 plugins (Core Workflow, Clear Writing, Playwright, Infrastructure-as-Code, Notify, Precise Technical Communication, Codebase Hygiene, Python Code Quality, Export to Clipboard, Conceptual Thought Partner). No global Claude Code configuration (CLAUDE.md template, global commands/agents/docs) lives here — those are maintained elsewhere and this repo installs only via the plugin system.

## Architecture

```
claude-code/
└── plugins/           # 10 encapsulated plugins (installed via marketplace)
    ├── core-workflow/  # 12 skills (6 user-invoked, 6 auto-activating), 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
    ├── clear-writing/  # 1 skill (clear, plain-style prose)
    ├── playwright/     # Browser automation (1 skill, token-efficient CLI)
    ├── infrastructure-as-code/ # 1 command, 1 skill
    ├── notify/         # Terminal bell + macOS banner notifications (2 hooks: Notification, Stop)
    ├── precise-technical-communication/ # 1 skill (precise, auditable technical reporting)
    ├── codebase-hygiene/ # 2 skills + 1 PreToolUse hook (documentation currency, AGENTS.md/CLAUDE.md pairing, .documentation-check manifest)
    ├── python-code-quality/ # 1 skill (Python code-quality principles)
    ├── export-to-clipboard/ # 1 user-only skill + Python renderer + bash export script (session transcript -> Obsidian vault, OSC 52 clipboard copy when remote)
    └── conceptual-thought-partner/ # 1 Fable subagent (conceptual sparring, architecture review; never implements)
AGENTS.md          # This file (canonical shared instructions; CLAUDE.md imports it)
docs/CODEBASE.md   # Repo analysis
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `description`, `model` (`inherit`|`sonnet`|`opus`|`haiku`|`fable`|full model ID), optional `color` and `tools`
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation — `notify` uses Stop/Notification hooks; `codebase-hygiene` uses a PreToolUse hook to guard commits
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

# From a local clone (point at the repo root, where .claude-plugin/marketplace.json lives)
/plugin marketplace add /path/to/personal_configs
```

Then install plugins via `/plugin install <name>`.

## Key Files

- `claude-code/plugins/core-workflow/README.md`: Core workflow plugin reference (commands, skills, agent)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only — skips gracefully if absent)
- **terminal-notifier** (optional, for `notify` — falls back to `osascript`)
- **jq** (required by `codebase-hygiene`'s `pre-git-documentation-check` hook to parse tool-call payloads; the hook blocks with an explanatory message if it is missing)
- **Claude Code** (runtime environment)

## Agent Instruction Files

- `AGENTS.md` (this file) is the canonical shared instruction file for Codex, Cursor, and Claude Code.
- `CLAUDE.md` is import-only: its entire content is `@AGENTS.md`.
- The `codebase-hygiene` PreToolUse guard enforces this pairing before any commit/PR mutation: root `AGENTS.md` must be non-empty, root `CLAUDE.md` must contain exactly `@AGENTS.md`, and any subdirectory holding one of the two files must hold both.

## Gotchas

- The marketplace manifest lives at `.claude-plugin/marketplace.json` (root, for GitHub install) and must list every plugin under `claude-code/plugins/`. There is no second manifest — the local `claude-code/plugins/.claude-plugin/marketplace.json` was removed; install from a local clone by pointing `/plugin marketplace add` at the repo root
- All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). If any hook returns `decision: "block"`, Claude continues — the most restrictive decision wins after all hooks complete
- This repo previously also hosted global Claude Code configuration (a CLAUDE.md template, global commands/agents/docs symlinked to `~/.claude/`) and a Cursor IDE mirror — both were removed; this repo is now plugins-only
