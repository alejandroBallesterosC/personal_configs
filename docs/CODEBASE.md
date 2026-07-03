# Personal Configs - Codebase Analysis

> Last updated: 2026-07-03

## 1. System Purpose & Domain

Development infrastructure repository for AI-assisted workflows with Claude Code and Cursor IDE. Contains no application code — only Markdown (commands, agents, skills, docs), JSON (configs, manifests), and Shell scripts (hooks, sync). The core domain is a **lean set of Claude Code plugins**: commands are one-shot orchestrations of parallel subagents, and skills are checklists Claude applies directly — no hand-rolled workflow state machines or Stop-hook iteration engines.

**Core domain entities:**
- **Plugins** (5 active): Self-contained packages of commands, agents, skills, hooks
- **Skills**: Standalone guidance documents (TDD, debugging, plan review, research rigor, LaTeX writing, git worktrees) applied directly within a session
- **Commands**: Single-pass orchestrations of parallel subagents (codebase understanding, branch comparison, remote-change review, research)
- **Sync**: Symlinks for Claude Code (`~/.claude/`), copy-based for Cursor (`~/.cursor/`)

## 2. Technology Stack

| Layer | Technology | Version/Source |
|-------|-----------|----------------|
| Runtime | Claude Code CLI | Anthropic (external) |
| Plugins | Claude Code Plugin System | plugin.json manifests |
| Content | Markdown (47 files) | YAML frontmatter conventions |
| Scripts | Bash (7 files) | POSIX-compatible |
| Config | JSON (15 files) | Plugin manifests, hooks, MCP |
| Browser automation | Playwright (`playwright-cli` + `@playwright/test`) | npm global install |
| IDE mirror | Cursor IDE | Unidirectional sync |
| MCP servers | context7 (HTTP), fetch (stdio), exa (npx), playwright (npx) | global_mcp_settings.json |
| Dependencies | pdflatex/MacTeX (optional, `core-workflow`'s `latex-report` skill only) | brew install |

## 3. Architecture

### Pattern: Plugin-Based Configuration Infrastructure

```
personal_configs/
├── claude-code/                    # Primary source of truth
│   ├── plugins/ (5 active)
│   │   ├── core-workflow/          # 6 commands, 6 skills, 1 agent
│   │   ├── playwright/             # 1 skill (browser automation, CLI-based)
│   │   ├── infrastructure-as-code/ # 1 command, 1 skill
│   │   ├── notify/                 # 2 hooks (Notification, Stop)
│   │   └── precise-technical-communication/ # 1 skill
│   ├── agents/ (0)                 # Global subagents (symlinked to ~/.claude/agents/) — empty; web-researcher now lives in core-workflow
│   ├── commands/ (1)               # Global commands (symlinked to ~/.claude/commands/)
│   ├── docs/ (3)                   # Best practice guides (symlinked to ~/.claude/docs/)
│   ├── CLAUDE.md                   # Template (symlinked to ~/.claude/CLAUDE.md)
│   └── global_mcp_settings.json    # MCP config
├── cursor/                         # Cursor IDE mirror (commands + skills, unidirectional)
├── sync-content-scripts/           # Symlink setup (Claude Code) + copy sync (Cursor)
├── CLAUDE.md                       # This repo's coding standards
└── docs/CODEBASE.md                # This file
```

### Data Flow

```
Repository (source of truth)
    │
    ├──[symlinks]──► ~/.claude/ (global config)
    │   ├── agents/ → claude-code/agents/ (empty)
    │   ├── commands/ → claude-code/commands/
    │   ├── docs/ → claude-code/docs/
    │   └── CLAUDE.md → claude-code/CLAUDE.md
    │
    ├──[plugin marketplace]──► Claude Code runtime
    │   └── 5 registered plugins
    │
    └──[sync_to_cursor.sh]──► ~/.cursor/ (IDE config, copy-based)
        ├── commands/*.md (no YAML frontmatter)
        └── skills/
```

### Hook Architecture

Only `notify` registers hooks in this repo. `core-workflow` has none — its Stop-hook test-gate and iteration-engine equivalents were deliberately dropped in favor of plain-guidance skills (`tdd-discipline`) and native Claude Code capabilities (Plan Mode, TaskCreate/TaskList, the Workflow tool for multi-agent orchestration).

```
Stop Event (on Claude exit attempt) — all matching hooks run in parallel
├── notify:
│   └── cc-notify.sh done               # Terminal bell + macOS banner
└── .claude/hooks/ (project-level):
    └── document-learnings.sh            # Prompt Claude to document insights

Notification Event (permission_prompt|idle_prompt|elicitation_dialog)
└── notify:
    └── cc-notify.sh input              # Terminal bell + macOS banner
```

**Note**: All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). The most restrictive decision wins after all hooks complete.

## 4. Boundaries & Interfaces

### Plugin Interface Contract
Each plugin is self-contained in `.claude-plugin/plugin.json`:
- **Commands**: YAML frontmatter (`description`, `model`, `argument-hint`) + markdown body
- **Agents**: YAML frontmatter (`name`, `description`, `tools[]`, `model`) + system prompt
- **Skills**: YAML frontmatter (`name`, `description` for activation) + SKILL.md content
- **Hooks**: `hooks.json` registering event handlers (command scripts or agent prompts)

**Coupling**: Plugins are loosely coupled with no hard cross-plugin dependencies. `core-workflow` optionally uses `playwright` (visual verification, referenced from its `tdd-discipline` skill) and optionally `pdflatex`/MacTeX (its `latex-report` skill's PDF compilation, gracefully skipped if absent). `notify` has no plugin dependencies (only requires `terminal-notifier` for full functionality, falls back to `osascript`).

### Hook Interface Contract
- **Command hooks**: Shell scripts returning exit code 0 (allow) or JSON `{"decision": "block", ...}` (block)
- **Stop hooks can block**: Returning JSON decision blocks Claude from exiting
- Only `notify`'s hooks and the project-level `document-learnings.sh` hook are active in this repo; both always exit 0 (never block), except `document-learnings.sh` which can block to prompt documentation.

### Sync Interface Contract
- **Claude Code**: Symlinks from `~/.claude/` to repo (`setup_symlinks.sh`) for CLAUDE.md, agents/, commands/, docs/. Changes in repo are immediately live.
- **Cursor**: Copy-based sync (`sync_to_cursor.sh`), unidirectional. Symlinks are unreliable in Cursor due to known bugs with skill/agent discovery after restart.
- **Plugins do NOT sync**: Installed via marketplace (`/plugin marketplace add` + `/plugin install`)

### State File Contract
`.plugin-state/` exists at the repo root (gitignored) as a landing spot for any future plugin state, but no currently active plugin writes to it — `core-workflow` is stateless by design (single-pass commands, no cross-session workflow state).

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin encapsulation | Self-contained dirs with manifests | Flat global commands | Isolation + marketplace distribution vs. more complex installation |
| Condense to one lean plugin | `core-workflow` bundles 6 skills, 6 commands, 1 agent from what were 6 separate plugins | Keep many small plugins | Smaller system-prompt footprint and less to maintain vs. losing some workflow-specific naming/namespacing |
| Skills over hooks/state machines | Checklists applied directly by the model each time | Stop-hook gates + YAML state files + phase commands | Simpler, no external deps (yq/jq), no infinite-loop risk between competing hooks vs. no hard enforcement — relies on the model actually applying the skill |
| Drop TDD Stop-hook gate | Plain `tdd-discipline` skill guidance | Hook that blocks session exit until tests pass | No forced verification gate vs. no hook-ordering conflicts, no yq/jq dependency, works even if the model forgets once |
| Drop Ralph-loop / hand-rolled iteration engines | Rely on native Claude Code capabilities (Plan Mode, TaskCreate/TaskList, the Workflow tool) for multi-step or long-running work | Bespoke bash while-loop Stop hooks per plugin | Less custom scaffolding to maintain vs. losing the single-session transcript-persistence guarantee those hooks provided |
| Symlinks for Claude Code | Symlinks to repo dirs | Copy-based sync scripts | Instant sync, single source of truth vs. breaks if repo moves |
| Cursor mirror | Separate adapted copy | Shared source with adapters | Simpler sync script vs. files to maintain in parallel |

## 6. Code Quality & Patterns

### Conventions Enforced
1. **ABOUTME comments**: Code files start with 2-line `# ABOUTME:` comments where applicable
2. **YAML frontmatter**: Commands, agents, skills all use structured YAML headers
3. **Read-only commands**: All `core-workflow` commands explicitly forbid file edits, commits, and pushes
4. **Announce-at-start convention**: Skills like `tdd-discipline`, `structured-debug`, and `using-git-worktrees` announce activation at the start of use

### Shell Script Quality
- 7 scripts (sync scripts + notify's hook script), using `set -euo pipefail` where applicable
- Proper quoting, `git rev-parse --show-toplevel` for repo root detection where relevant
- Non-fatal exits (exit 0) for optional features

### No Linting/Formatting Config
By design — repo contains only Markdown, JSON, and Bash (no application code to lint).

## 7. Plugin Details

### core-workflow (v1.0.0) — TDD, Debugging, Plan Review, Research, LaTeX, Codebase Understanding

**Components**: 6 commands, 6 skills, 1 agent, no hooks

**Commands**:
| Command | Purpose |
|---------|---------|
| `readonly` | Run a prompt in read-only mode |
| `research` | Wave-based parallel `web-researcher` internet research |
| `understand-repo` | Single-pass codebase understanding: 5 parallel `Explore` agents (System Purpose, Tech Stack, Architecture, Boundaries, Design Decisions), synthesized into an architecture diagram + prioritized reading list |
| `compare-branch-to-another` | 5 parallel agents (structural, behavioral, testing, code-quality, risk) compare the current branch against another |
| `explain-all-changes-since` | Fetches all remote branches, filters commits by collaborators (excluding the current user) since a date/time, summarizes via parallel agents |
| `explain-branch-changes-since` | Same, scoped to the current branch's upstream, accepts a date/time or commit hash |

**Skills**:
| Skill | Purpose |
|-------|---------|
| `tdd-discipline` | RED/GREEN/REFACTOR guidance, real-APIs-over-mocks rule, boundary testing |
| `structured-debug` | Hypothesis-driven debugging: Iron Law, 3-Fix Rule, tagged instrumentation |
| `using-git-worktrees` | Safe worktree creation with gitignore verification |
| `adversarial-plan-review` | Evidence-to-decision audit, assumption inversion, cross-artifact consistency checks |
| `research-methodology` | Evidence rigor discipline — what a source proves vs. asserts, gap ratings, overstatement audits |
| `latex-report` | Argument-driven LaTeX report structure, single-voice writing discipline, pdflatex/bibtex compile pipeline (bundles `report-template.tex` and `voice-guide-template.md` as reference files) |

**Agent**: `web-researcher` — internet research specialist, used by `/research`.

### notify — Terminal Notifications

**Components**: 2 hooks (Notification, Stop)

Terminal bell (BEL) and macOS banner notifications via terminal-notifier (with osascript fallback). Designed for tmux + Ghostty workflows. Sends notifications on Stop events (Claude finished responding) and Notification events (Claude needs input — permission prompts, idle prompts, elicitation dialogs).

**Dependencies**: `terminal-notifier` (optional, `brew install terminal-notifier`; falls back to osascript).

### Other Plugins

- **playwright**: Browser automation via `playwright-cli` (interactive) and `@playwright/test` (CI). Skill-only plugin — no commands, agents, or hooks
- **infrastructure-as-code**: 1 command + 1 skill for Terraform/AWS
- **precise-technical-communication**: 1 skill for plain, exact, auditable technical writing (plus an optional output style, distributed outside the plugin's skill directory)

## 8. Cursor Mirror

The Cursor mirror at `cursor/` was trimmed alongside the Claude Code plugin condensation: the TDD workflow (9 phase commands), Ralph loop (3 commands + Stop hook), 7 TDD-specific subagents, the `tdd-workflow-guide` skill, `writing-plans` skill, and all hooks (`hooks.json` + scripts) were removed, since their Claude Code counterparts (`dev-workflow`, `ralph-loop`) no longer exist.

**Remaining in Cursor**: 4 commands (`answer-question-about-codebase`, `answer-question-using-internet-research`, `understand-repo`, `compare-branch-to-another`) and 3 skills (`testing`, `using-git-worktrees`, `playwright`). Cursor has no plugin system, so these are plain files with no YAML frontmatter, synced by copy rather than symlink.

## 9. VS Code Tasks

`.vscode/tasks.json` predates this condensation and was not in scope for it — it may still contain tasks referencing sync scripts or prior-project leftovers. Worth a separate audit if VS Code task accuracy matters.

## 10. Open Questions

- [ ] Should the Cursor mirror gain a `core-workflow`-equivalent set of skills (e.g. `structured-debug`, `adversarial-plan-review`) now that Claude Code has them?
- [ ] Should `.vscode/tasks.json` be audited for dead tasks now that the plugin/sync landscape has changed?
- [ ] Should GitHub Actions workflows (`claude.yml`, `claude-code-review.yml`) be reviewed for currency?
- [ ] Is `.plugin-state/` (currently unused) still worth keeping as a documented convention, or should it be removed until a plugin actually needs it?

## 11. Ambiguities

- **Cursor mirror maintenance**: All adaptations baked into `cursor/` directory. Adding skills requires creating adapted copies, not modifying the sync script. Unclear if Cursor should track `core-workflow`'s newer skills (`adversarial-plan-review`, `research-methodology`, `latex-report`).
- **Symlink dependency**: Claude Code symlinks break if the repo is moved. Re-run `setup_symlinks.sh` after moving.
