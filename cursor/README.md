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
├── subagents/      # Subagent definitions → ~/.cursor/subagents/
├── hooks/
│   ├── hooks.json  # Hook configuration → ~/.cursor/hooks.json
│   └── scripts/    # Hook shell scripts → ~/.cursor/hooks/scripts/
└── README.md
```

## Installation

```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

This syncs all components to `~/.cursor/` and sets script permissions.

## Components

### Commands (14)

**TDD Workflow:**
- `1-start` through `9-review` - Full TDD workflow phases
- `continue-tdd-workflow` - Resume in-progress workflow
- `tdd-workflow-help` - Show workflow help

**Ralph Loop:**
- `ralph-loop` - Start iterative development loop
- `cancel-ralph` - Cancel active Ralph loop
- `ralph-help` - Explain Ralph Wiggum technique

### Skills (5)

| Skill | Purpose |
|-------|---------|
| `tdd-workflow-guide` | Navigation for TDD workflow phases |
| `testing` | TDD guidance (RED-GREEN-REFACTOR) |
| `writing-plans` | Plan creation guidance |
| `using-git-worktrees` | Git worktree setup |
| `playwright` | Browser automation (self-contained with runtime) |

### Subagents (7)

| Agent | Model | Purpose |
|-------|-------|---------|
| `code-explorer` | Sonnet | Deep codebase exploration |
| `code-architect` | Opus | Technical design |
| `plan-reviewer` | Opus | Critical plan review |
| `test-designer` | Opus | RED phase - write failing tests |
| `implementer` | Opus | GREEN phase - minimal code |
| `refactorer` | Opus | REFACTOR phase - improve code |
| `code-reviewer` | Sonnet | Comprehensive review |

### Hooks

- **stop**: Runs scoped tests + verifies workflow state + ralph-loop continuation
- **sessionStart** (`compact|clear`): Auto-resumes workflow after context reset

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
| Hook events | PascalCase (`Stop`) | camelCase (`stop`) |
| hooks.json | No version field | `"version": 1` required |
| Hook paths | `${CLAUDE_PLUGIN_ROOT}/...` | `$HOME/.cursor/...` |
| State files | `.claude/` | `.cursor/` |
| Hook decision JSON | `{"decision": "block", "reason": "..."}` | `{"continue": false, "agentMessage": "..."}` |

## Ralph Loop Usage

Start an iterative development loop:

```bash
/ralph-loop "Build a REST API" --max-iterations 20 --completion-promise "API COMPLETE"
```

The stop hook feeds the same prompt back until:
- Max iterations reached, OR
- Completion promise detected: `<promise>API COMPLETE</promise>`

Cancel with `/cancel-ralph`.

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

- **No plugin prefixes**: Cursor doesn't use plugins, so commands are invoked directly (e.g., `/1-start` not `/tdd-workflow:1-start`)
- **hooks.json merge**: If `~/.cursor/hooks.json` exists, sync creates a backup and warns you to merge manually
- **Ralph loop state**: Uses `.cursor/ralph-loop.local.md` (not `.claude/`)
- **Playwright setup**: Run `npm run setup` in `~/.cursor/skills/playwright/` before first use
- Hook scripts use `$HOME/.cursor/hooks/scripts/` paths (not `${CLAUDE_PLUGIN_ROOT}`)
