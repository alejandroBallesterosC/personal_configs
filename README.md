# Personal Development Configurations

A Claude Code plugin marketplace. Contains 10 plugins, installed via the plugin system — no global Claude Code configuration or IDE sync lives in this repo.

## Repository Structure

```
personal_configs/
├── claude-code/
│   └── plugins/                     # 10 encapsulated workflow plugins
│       ├── core-workflow/           # 12 skills (6 user-invoked, 6 auto-activating), 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
│       ├── clear-writing/           # 1 skill (clear, plain-style prose)
│       ├── playwright/              # Browser automation (1 skill, token-efficient CLI)
│       ├── infrastructure-as-code/  # 2 skills (1 user-invoked)
│       ├── notify/                  # Terminal bell + macOS banner notifications (2 hooks)
│       ├── precise-technical-communication/ # 1 skill
│       ├── codebase-hygiene/        # 2 skills + 1 PreToolUse hook (documentation currency & AGENTS.md/CLAUDE.md pairing)
│       ├── python-code-quality/     # 1 skill (Python code-quality principles)
│       ├── export-to-clipboard/     # 1 user-only skill + Python/bash scripts (session transcript -> Obsidian vault, or clipboard when remote)
│       └── conceptual-thought-partner/ # 1 Fable subagent + 1 user-invoked think skill (conceptual sparring/architecture review; never implements)
├── .claude-plugin/                  # Marketplace manifest (marketplace.json)
├── .vscode/                         # VS Code tasks
├── AGENTS.md                        # Canonical shared agent instructions (source of truth)
└── CLAUDE.md                        # Import-only wrapper: @AGENTS.md
```

## Core Plugin: Core Workflow

### `claude-code/plugins/core-workflow/`

A lean set of skills and an agent for TDD, debugging, plan review, research rigor, LaTeX reports, understanding a codebase, and reviewing what collaborators have pushed. No hooks, no workflow state machines — auto-activating skills are checklists applied directly, user-invoked skills are one-shot orchestrations of parallel subagents that run only when you type their slash command.

**User-invoked skills** (typed as slash commands; never auto-trigger):
```bash
/core-workflow:readonly <prompt>                                       # Run a prompt in read-only mode
/core-workflow:research <topic>                                        # Thorough internet research via parallel web-researcher subagents
/core-workflow:understand-repo                                         # Single-pass codebase understanding with architecture diagram + reading list
/core-workflow:compare-branch-to-another <other-branch>                # Compare current branch against another
/core-workflow:explain-all-changes-since <date-time> [timezone]        # Summarize collaborators' pushes across all remote branches since a cutoff
/core-workflow:explain-branch-changes-since <date-time-or-commit> [timezone]  # Summarize collaborators' pushes to your branch's upstream since a cutoff
```

**Auto-activating skills:** `tdd-discipline`, `structured-debug`, `using-git-worktrees`, `adversarial-plan-review`, `research-methodology`, `latex-report`

**Agent:** `web-researcher` — internet research specialist used by `/core-workflow:research`

See `claude-code/plugins/core-workflow/README.md` for full details.

### Other Plugins

| Plugin | Purpose | Components |
|--------|---------|------------|
| **clear-writing** | Clear, plain-style prose with no slop | 1 skill, eval suite |
| **playwright** | Browser automation with Playwright | 1 skill (token-efficient CLI) |
| **infrastructure-as-code** | Terraform and AWS management | 2 skills (1 user-invoked) |
| **precise-technical-communication** | Plain, exact, auditable technical writing | 1 skill, 1 output style (applied automatically), eval suite |
| **notify** | Terminal bell + macOS banner notifications | 2 hooks (Notification, Stop) |
| **codebase-hygiene** | Keep docs current & agent instruction files paired; pre-commit documentation guard | 2 skills, 1 PreToolUse hook |
| **python-code-quality** | Python code-quality principles (Pydantic at boundaries, anti-overengineering) | 1 skill |
| **export-to-clipboard** | User-invoked export of the current session transcript (full or last N turns) to an Obsidian vault, or to the clipboard via OSC 52 when running remotely | 1 user-only skill + scripts |
| **conceptual-thought-partner** | Senior engineering/research thought partner on Claude Fable — stress-tests approaches and architecture conversationally; read-only, never implements | 1 Fable subagent, 1 user-invoked skill |

## Installation

Install a plugin in one step (Claude Code 2.1.275 or later), which adds this marketplace if needed:

```bash
/plugin install core-workflow --marketplace alejandroBallesterosC/personal_configs
```

Or register the marketplace once and install by name:

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone (point at the repo root, where .claude-plugin/marketplace.json lives)
/plugin marketplace add /path/to/personal_configs
```

Then install plugins:
```bash
/plugin install core-workflow
/plugin install clear-writing
/plugin install playwright
/plugin install infrastructure-as-code
/plugin install precise-technical-communication
/plugin install notify
/plugin install codebase-hygiene
/plugin install python-code-quality
/plugin install export-to-clipboard
/plugin install conceptual-thought-partner
```

## External Dependencies

- **Claude Code** (runtime environment; 2.1.141+ for the `notify` bell, 2.1.257+ for Fable 5.1, 2.1.269+ to run the plugin eval suites)
- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only)
- **terminal-notifier** (optional, for notify plugin — `brew install terminal-notifier` on macOS; falls back to osascript)
- **jq** (required by `codebase-hygiene`'s pre-commit documentation hook; blocks with an explanatory message if missing)

## Documentation

- `AGENTS.md` - Architecture, design decisions, interface contracts, and conventions (canonical; `CLAUDE.md` imports it)
- Each plugin's own `README.md` - that plugin's components, mechanics, and dependencies

---

*Claude Code plugin marketplace.*
