# Personal Configs - Codebase Analysis

> Last updated: 2026-07-07

## 1. System Purpose & Domain

A Claude Code plugin marketplace repository. Contains no application code — only Markdown (commands, agents, skills, docs), JSON (plugin manifests), and Shell scripts (hooks). The repo hosts 8 self-contained plugins, distributed exclusively via the Claude Code plugin marketplace system. It does **not** host global Claude Code configuration (a CLAUDE.md template, global commands/agents/docs symlinked to `~/.claude/`) or an IDE mirror (Cursor) — both were removed; this repo is plugins-only by design.

**Core domain entities:**
- **Plugins** (8 active): Self-contained packages of commands, agents, skills, hooks, each with its own `.claude-plugin/plugin.json` manifest
- **Skills**: Standalone guidance documents applied directly within a session (no state machines)
- **Commands**: Single-pass orchestrations of parallel subagents
- **Marketplace manifest**: A single `marketplace.json` at the repo root (`.claude-plugin/marketplace.json`) lists all plugins with `source` paths relative to the repo root

## 2. Technology Stack

| Layer | Technology | Version/Source |
|-------|-----------|----------------|
| Runtime | Claude Code CLI | Anthropic (external) |
| Plugins | Claude Code Plugin System | plugin.json manifests |
| Content | Markdown | YAML frontmatter conventions |
| Scripts | Bash | POSIX-compatible, inside plugin `hooks/` (and `.claude/hooks/` for this repo's own session); `codebase-hygiene` ships hook smoke tests |
| Config | JSON | Plugin manifests, hooks |
| Browser automation | Playwright (`playwright-cli` + `@playwright/test`) | npm global install |
| Dependencies | pdflatex/MacTeX (optional, `core-workflow`'s `latex-report` skill only), terminal-notifier (optional, `notify`) | brew install |

## 3. Architecture

### Pattern: Plugin-Only Marketplace Repository

```
personal_configs/
├── claude-code/
│   └── plugins/ (8 active)
│       ├── core-workflow/          # 6 commands, 6 skills, 1 agent
│       ├── clear-writing/          # 1 skill (clear, plain-style prose)
│       ├── playwright/             # 1 skill (browser automation, CLI-based)
│       ├── infrastructure-as-code/ # 1 command, 1 skill
│       ├── notify/                 # 2 hooks (Notification, Stop)
│       ├── precise-technical-communication/ # 1 skill + output style
│       ├── codebase-hygiene/       # 2 skills + 1 PreToolUse hook (with smoke tests)
│       └── python-code-quality/    # 1 skill (Python code-quality principles)
├── .claude-plugin/                 # Marketplace manifest (marketplace.json)
├── .claude/                        # Project-level Claude Code config (this repo's own session)
│   ├── commands/review-playwright-plugin.md
│   ├── hooks/document-learnings.sh
│   └── settings.json
├── .vscode/                        # VS Code tasks (some leftover from a prior project)
├── .github/workflows/              # claude.yml, claude-code-review.yml
├── CLAUDE.md                       # This repo's coding standards
└── docs/CODEBASE.md                # This file
```

### Marketplace Registration

```
Repository (source of truth)
    │
    └──[plugin marketplace]──► Claude Code runtime
        └── .claude-plugin/marketplace.json   (root; source: "./claude-code/plugins/<name>")
```

A single marketplace manifest at the repo root lists all 8 plugins. Install from GitHub or from a local clone by pointing `/plugin marketplace add` at the repo root.

### Hook Architecture

Two plugins register hooks: `notify` (Stop, Notification) and `codebase-hygiene` (PreToolUse). `core-workflow` deliberately has none — a TDD Stop-hook test-gate and Ralph-loop-style iteration engine were considered and dropped in favor of plain-guidance skills (`tdd-discipline`) and native Claude Code capabilities (Plan Mode, TaskCreate/TaskList, the Workflow tool for multi-agent orchestration).

```
PreToolUse Event (before Bash / GitHub MCP tool calls)
└── codebase-hygiene:
    └── pre-git-documentation-check.sh   # Block git/GitHub commit & PR mutations
                                         # until the documentation contract holds

Stop Event (on Claude exit attempt) — all matching hooks run in parallel
├── notify:
│   └── cc-notify.sh done               # Terminal bell + macOS banner
└── .claude/hooks/ (project-level, this repo's own session only):
    └── document-learnings.sh            # Prompt Claude to document insights

Notification Event (permission_prompt|idle_prompt|elicitation_dialog)
└── notify:
    └── cc-notify.sh input              # Terminal bell + macOS banner
```

`codebase-hygiene`'s guard resolves the repo being committed to (the working directory's git toplevel), enforces root `AGENTS.md`/`CLAUDE.md` pairing and any files listed in a repo-root `.documentation-check` manifest, then reminds once per change that all docs must be current before allowing the unchanged diff on the next attempt. It requires `jq` and only acts inside a git work tree.

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
- `notify`'s hooks, `codebase-hygiene`'s PreToolUse guard, and the project-level `document-learnings.sh` hook are the active hooks. `notify`'s always exit 0 (never block); `codebase-hygiene`'s guard and `document-learnings.sh` can block to enforce/prompt documentation.

### Distribution Interface Contract
- **Plugins install via marketplace only**: `/plugin marketplace add` + `/plugin install`. There is no symlink or copy-based sync mechanism in this repo — that was removed along with the global-config and Cursor-mirror content it used to sync.

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin encapsulation | Self-contained dirs with manifests | Flat global commands | Isolation + marketplace distribution vs. more complex installation |
| Plugins-only repo | Removed global Claude Code config (CLAUDE.md template, global commands/agents/docs) and the Cursor IDE mirror from this repo | Keep global config + IDE mirror alongside plugins | Single clear purpose (a plugin marketplace) and no symlink/sync-script maintenance vs. those configs now need to live and be maintained elsewhere |
| Condense to one lean plugin | `core-workflow` bundles 6 skills, 6 commands, 1 agent from what were 6 separate plugins | Keep many small plugins | Smaller system-prompt footprint and less to maintain vs. losing some workflow-specific naming/namespacing |
| Skills over hooks/state machines | Checklists applied directly by the model each time | Stop-hook gates + YAML state files + phase commands | Simpler, no external deps, no infinite-loop risk between competing hooks vs. no hard enforcement — relies on the model actually applying the skill |
| Drop TDD Stop-hook gate | Plain `tdd-discipline` skill guidance | Hook that blocks session exit until tests pass | No forced verification gate vs. no hook-ordering conflicts, works even if the model forgets once |
| Drop Ralph-loop / hand-rolled iteration engines | Rely on native Claude Code capabilities (Plan Mode, TaskCreate/TaskList, the Workflow tool) for multi-step or long-running work | Bespoke bash while-loop Stop hooks per plugin | Less custom scaffolding to maintain vs. losing the single-session transcript-persistence guarantee those hooks provided |

## 6. Code Quality & Patterns

### Conventions Enforced
1. **ABOUTME comments**: Code files start with 2-line `# ABOUTME:` comments where applicable
2. **YAML frontmatter**: Commands, agents, skills all use structured YAML headers
3. **Read-only commands**: All `core-workflow` commands explicitly forbid file edits, commits, and pushes
4. **Announce-at-start convention**: Skills like `tdd-discipline`, `structured-debug`, and `using-git-worktrees` announce activation at the start of use

### Shell Script Quality
- 5 scripts total: `notify`'s hook script and the project-level `document-learnings.sh`, plus supporting `.vscode/scripts/` shell scripts unrelated to plugins
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

### codebase-hygiene — Documentation & Repo Hygiene

**Components**: 2 skills, 1 PreToolUse hook (with smoke tests)

Keeps a codebase organized, evergreen, and documented. The `codebase-hygiene` skill is an umbrella hygiene pass (docs current, `AGENTS.md`/`CLAUDE.md` paired, repo organized, names evergreen); the `agents-md-improver` skill audits and improves agent instruction files and repo documentation. The `pre-git-documentation-check` hook is a PreToolUse guard that blocks git/GitHub commit and PR mutations until the documentation contract holds.

Repo-specific required docs are declared per-repo in a root `.documentation-check` manifest (`path|description` per line; `#` comments and blank lines ignored), read by both the skill and the hook. With no manifest, only the always-on `AGENTS.md`/`CLAUDE.md` pairing and general documentation-currency checks apply.

**Dependencies**: `jq` (required by the hook; blocks with an explanatory message if missing), `git` (the hook only acts inside a work tree).

### python-code-quality — Python Code Quality

**Components**: 1 skill

Python-specific code-quality principles: verification-first, runtime-validated (Pydantic at boundaries), legible artifacts, with anti-overengineering guardrails. Covers contract-driven design, golden/expect tests, deleting dead code from evidence, and the rejected anti-patterns (e.g. static type-checker CI gates that buy no runtime guarantee).

### Other Plugins

- **clear-writing**: 1 skill for clear, plain-style prose with no slop, plus `references/` (examples, banned phrases, banned structures)
- **playwright**: Browser automation via `playwright-cli` (interactive) and `@playwright/test` (CI). Skill-only plugin — no commands, agents, or hooks
- **infrastructure-as-code**: 1 command + 1 skill for Terraform/AWS
- **precise-technical-communication**: 1 skill for plain, exact, auditable technical writing, plus an optional output style distributed outside the plugin's skill directory

## 8. Removed Content (Historical Note)

This repo previously also hosted:
- **Global Claude Code configuration**: a CLAUDE.md template, global `commands/`, `agents/`, and `docs/` directories, symlinked to `~/.claude/` via `sync-content-scripts/claude-code/setup_symlinks.sh`
- **A Cursor IDE mirror** (`cursor/`): commands and skills copy-synced to `~/.cursor/` via `sync-content-scripts/cursor/sync_to_cursor.sh`
- **Six additional plugins** (`dev-workflow`, `research-report`, `long-horizon-impl`, `ralph-loop`, `claude-session-feedback`, `claude-md-best-practices`) and an already-deprecated `autonomous-workflow`, condensed into `core-workflow` and dropped for reasons documented in git history around 2026-07-03

All of the above were removed. This repo is now scoped exclusively to the plugin marketplace.

## 9. VS Code Tasks and GitHub Workflows

`.vscode/tasks.json` retains two tasks (`Compile & Run Current File`, `Run App Start Script`) left over from a prior, unrelated project — out of scope for this repo's plugin marketplace purpose. `.github/workflows/` has `claude.yml` and `claude-code-review.yml`; their current activation status was not verified as part of this pass.

## 10. Open Questions

- [ ] Should `.vscode/tasks.json`'s leftover unrelated tasks be removed?
- [ ] Should GitHub Actions workflows (`claude.yml`, `claude-code-review.yml`) be reviewed for currency?
- [ ] Where do the removed global Claude Code configuration and Cursor mirror now live, and should this doc cross-reference that location?

## 11. Ambiguities

- **No sync mechanism remains**: any future global-config or IDE-mirror needs must be solved outside this repo; there is no symlink or copy-based sync script to repurpose.
