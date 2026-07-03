# Cursor Configuration

Global Cursor IDE customizations synced to `~/.cursor/`.

## Directory Structure

```
cursor/
├── commands/       # Slash commands → ~/.cursor/commands/
├── skills/         # Agent skills → ~/.cursor/skills/
│   ├── playwright/ # Self-contained with runtime files
│   │   ├── SKILL.md
│   │   ├── run.js
│   │   ├── package.json
│   │   ├── API_REFERENCE.md
│   │   └── lib/helpers.js
│   └── .../        # Other skills
└── README.md
```

## Installation

```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

This syncs all components to `~/.cursor/` and sets script permissions.

## Components

### Commands (4)

| Command | Purpose |
|---------|---------|
| `answer-question-about-codebase` | Answer a question about this codebase |
| `answer-question-using-internet-research` | Answer a question using internet research |
| `understand-repo` | Explore and document codebase understanding |
| `compare-branch-to-another` | Compare the current branch against another using parallel subagents |

### Skills (3)

| Skill | Purpose |
|-------|---------|
| `testing` | TDD guidance (RED-GREEN-REFACTOR) |
| `using-git-worktrees` | Git worktree setup |
| `playwright` | Browser automation (self-contained with runtime) |

### Playwright Automation

The playwright skill is self-contained in `skills/playwright/` with all runtime files. After syncing:

```bash
cd ~/.cursor/skills/playwright && npm run setup
```

Features:
- Auto-detection of running dev servers
- Test scripts written to `/tmp` (no clutter)
- Visible browser by default for debugging
- Helper functions for common patterns

## Format Differences: Cursor vs Claude Code

| Aspect | Claude Code | Cursor |
|--------|-------------|--------|
| Commands | YAML frontmatter supported | Plain markdown only |
| No plugin prefixes | Commands namespaced by plugin (`/plugin:command`) | Commands invoked directly (`/command`) |

## Adding New Components

Just add files to the appropriate directory and re-run sync:

```bash
# Add a new command (plain markdown, no frontmatter)
echo '# My Command

Do something useful.' > commands/my-command.md

# Sync
./sync-content-scripts/cursor/sync_to_cursor.sh
```

## Notes

- **No plugin prefixes**: Cursor doesn't use plugins, so commands are invoked directly (e.g., `/understand-repo` not `/core-workflow:understand-repo`)
- **Playwright setup**: Run `npm run setup` in `~/.cursor/skills/playwright/` before first use
