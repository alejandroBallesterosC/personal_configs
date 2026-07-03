# Personal Development Configurations

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 5 plugins, configuration sync scripts, and IDE integrations.

## Repository Structure

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # 5 encapsulated workflow plugins
│   │   ├── core-workflow/          # 6 commands, 6 skills, 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
│   │   ├── playwright/             # Browser automation (1 skill, token-efficient CLI)
│   │   ├── infrastructure-as-code/ # 1 command, 1 skill
│   │   ├── notify/                 # Terminal bell + macOS banner notifications (2 hooks)
│   │   └── precise-technical-communication/ # 1 skill
│   ├── agents/                     # Global subagents (symlinked to ~/.claude/agents/)
│   ├── commands/                   # Shared global commands (symlinked to ~/.claude/commands/)
│   ├── docs/                       # Python, UV, Docker best practices (symlinked to ~/.claude/docs/)
│   └── global_mcp_settings.json    # MCP server configuration
├── cursor/                         # Cursor IDE parallel configs
├── sync-content-scripts/           # Symlink setup (Claude Code) + copy sync (Cursor)
├── .vscode/                        # VS Code tasks
├── docs/
│   └── CODEBASE.md                 # Comprehensive codebase analysis
└── CLAUDE.md                       # Project-specific instructions
```

## Core Plugin: Core Workflow

### `claude-code/plugins/core-workflow/`

A lean set of commands, skills, and an agent for TDD, debugging, plan review, research rigor, LaTeX reports, understanding a codebase, and reviewing what collaborators have pushed. No hooks, no workflow state machines — skills are checklists applied directly, commands are one-shot orchestrations of parallel subagents.

**Commands:**
```bash
/core-workflow:readonly <prompt>                                       # Run a prompt in read-only mode
/core-workflow:research <topic>                                        # Thorough internet research via parallel web-researcher subagents
/core-workflow:understand-repo                                         # Single-pass codebase understanding with architecture diagram + reading list
/core-workflow:compare-branch-to-another <other-branch>                # Compare current branch against another
/core-workflow:explain-all-changes-since <date-time> [timezone]        # Summarize collaborators' pushes across all remote branches since a cutoff
/core-workflow:explain-branch-changes-since <date-time-or-commit> [timezone]  # Summarize collaborators' pushes to your branch's upstream since a cutoff
```

**Skills:** `tdd-discipline`, `structured-debug`, `using-git-worktrees`, `adversarial-plan-review`, `research-methodology`, `latex-report`

**Agent:** `web-researcher` — internet research specialist used by `/research`

See `claude-code/plugins/core-workflow/README.md` for full details.

### Other Plugins

| Plugin | Purpose | Components |
|--------|---------|------------|
| **playwright** | Browser automation with Playwright | 1 skill (token-efficient CLI) |
| **infrastructure-as-code** | Terraform and AWS management | 1 command, 1 skill |
| **precise-technical-communication** | Plain, exact, auditable technical writing | 1 skill |
| **notify** | Terminal bell + macOS banner notifications | 2 hooks (Notification, Stop) |

## MCP Servers

Configured in `claude-code/global_mcp_settings.json`:

| Server | Type | Purpose |
|--------|------|---------|
| **context7** | HTTP | Documentation retrieval |
| **fetch** | stdio | URL content fetching |
| **exa** | npx | Web search + code context |
| **playwright** | npx | Browser automation |

**Environment Variables Required:**
```bash
CONTEXT7_API_KEY  # For context7 HTTP server
EXA_API_KEY       # For exa web search
```

Store in `.env` file (gitignored).

## Sync Setup

### Claude Code (symlinks)

Claude Code agents, commands, docs, and CLAUDE.md are symlinked from this repo to `~/.claude/`:

```bash
# One-time setup (idempotent, backs up existing files)
./sync-content-scripts/claude-code/setup_symlinks.sh
```

This creates four symlinks:
- `~/.claude/CLAUDE.md` → `claude-code/CLAUDE.md`
- `~/.claude/agents/` → `claude-code/agents/`
- `~/.claude/commands/` → `claude-code/commands/`
- `~/.claude/docs/` → `claude-code/docs/`

Edits in this repo are immediately reflected in Claude Code. No re-sync needed.

### Cursor (copy-based)

Cursor configs use copy-based sync because Cursor has known bugs with symlinked directories:

```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

### Plugins

Plugins install via the marketplace system (not file sync):
```bash
/plugin marketplace add alejandroBallesterosC/personal_configs
/plugin install core-workflow
```

## Usage

### Plugin Installation

Register this repo as a Claude Code plugin marketplace, then install plugins:

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone
/plugin marketplace add /path/to/personal_configs/claude-code/plugins
```

Then install plugins:
```bash
/plugin install core-workflow
/plugin install playwright
/plugin install infrastructure-as-code
/plugin install precise-technical-communication
/plugin install notify
```

### Context Preservation

- **Stop hook**: terminal bell + macOS banner (notify)
- **Notification hook**: terminal bell + macOS banner when Claude needs input (notify)

`core-workflow` has no hooks or cross-session state to preserve — its commands are single-pass and its skills apply directly within a session.

## External Dependencies

- **Claude Code** (runtime environment)
- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only)
- **terminal-notifier** (optional, for notify plugin — `brew install terminal-notifier` on macOS; falls back to osascript)
- **uv** (Python package management, referenced in docs)

## Documentation

- `docs/CODEBASE.md` - Comprehensive codebase analysis (architecture, workflows, open questions)
- `claude-code/plugins/core-workflow/README.md` - Core workflow plugin reference
- `claude-code/docs/` - Python, UV, Docker best practices

---

*Configuration repository for AI-assisted development workflows.*
