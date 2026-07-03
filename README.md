# Personal Development Configurations

A Claude Code plugin marketplace. Contains 5 plugins, installed via the plugin system — no global Claude Code configuration or IDE sync lives in this repo.

## Repository Structure

```
personal_configs/
├── claude-code/
│   └── plugins/                     # 5 encapsulated workflow plugins
│       ├── core-workflow/           # 6 commands, 6 skills, 1 agent (TDD, debugging, plan review, research rigor, LaTeX reports, codebase understanding, remote-change review)
│       ├── playwright/              # Browser automation (1 skill, token-efficient CLI)
│       ├── infrastructure-as-code/  # 1 command, 1 skill
│       ├── notify/                  # Terminal bell + macOS banner notifications (2 hooks)
│       └── precise-technical-communication/ # 1 skill
├── .vscode/                         # VS Code tasks
├── docs/
│   └── CODEBASE.md                  # Comprehensive codebase analysis
└── CLAUDE.md                        # Project-specific instructions
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

## Installation

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

## External Dependencies

- **Claude Code** (runtime environment)
- **pdflatex/MacTeX** (optional, for `core-workflow`'s `latex-report` skill PDF compilation only)
- **terminal-notifier** (optional, for notify plugin — `brew install terminal-notifier` on macOS; falls back to osascript)

## Documentation

- `docs/CODEBASE.md` - Comprehensive codebase analysis (architecture, plugins, open questions)
- `claude-code/plugins/core-workflow/README.md` - Core workflow plugin reference

---

*Claude Code plugin marketplace.*
