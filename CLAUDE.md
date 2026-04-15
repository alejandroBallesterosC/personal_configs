# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 9 plugins (Dev Workflow, Research Report, Long Horizon Impl, Playwright, Session Feedback, Infrastructure-as-Code, CLAUDE.md Best Practices, Ralph Loop, Notify), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 9 encapsulated plugins (installed via marketplace)
│   ├── dev-workflow/  # 12 agents, 20 commands, 6 skills, 5 hooks (TDD + Debug)
│   ├── research-report/   # 4 agents, 3 commands, 1 skill, 2 hooks (Iterative research + LaTeX)
│   ├── long-horizon-impl/ # 9 agents, 4 commands, 1 skill, 2 hooks (Research/Plan/Implement)
│   ├── playwright/    # Browser automation (1 skill, token-efficient CLI)
│   ├── claude-session-feedback/ # 4 commands
│   ├── infrastructure-as-code/ # 1 command, 1 skill
│   ├── claude-md-best-practices/ # 1 skill
│   ├── ralph-loop/   # Iterative AI loops (3 commands, 1 hook)
│   └── notify/       # Terminal bell + macOS banner notifications (2 hooks: Notification, Stop)
├── agents/            # Global subagents (symlinked to ~/.claude/agents/)
├── commands/          # 8 shared global commands (symlinked to ~/.claude/commands/)
├── docs/              # Python, UV, Docker best practices (symlinked to ~/.claude/docs/)
└── CLAUDE.md          # Global coding standards template (symlinked to ~/.claude/)
sync-content-scripts/  # Symlink setup script (Claude Code) + 1 copy-based sync script (Cursor)
cursor/                # Cursor IDE mirror (42 files, TDD-only, unidirectional sync)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop, SessionStart, Notification across plugins)
  - `Stop`: TDD implementation gate + archive completed workflows + run scoped tests + state verification agent (dev-workflow), iteration control (ralph-loop), iteration engine + completion verifier (research-report, long-horizon-impl), terminal bell + macOS banner (notify)
  - `SessionStart`: Auto-restore context after compact/clear (dev-workflow: TDD + debug state, research-report: research state, long-horizon-impl: research/planning/impl state)
  - `Notification`: Terminal bell + macOS banner when Claude needs input (notify)
- **Project-level hooks** (`.claude/hooks/`): `document-learnings.sh` Stop hook prompts Claude to document architectural decisions and insights after implementation work

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (MCP servers, VS Code tasks, plugin manifests)
- Shell scripts (sync, test runner)

No build, no deployment. Runtime dependencies: yq, jq (see Dependencies).

## Commands

| Action | Command |
|--------|---------|
| Set up Claude Code symlinks | `./sync-content-scripts/claude-code/setup_symlinks.sh` |
| Sync Cursor configs | `./sync-content-scripts/cursor/sync_to_cursor.sh` |
| Install plugins | `/plugin marketplace add alejandroBallesterosC/personal_configs` then `/plugin install <name>` |
| Test runner detection | `claude-code/plugins/dev-workflow/hooks/run-scoped-tests.sh` (auto via Stop hook) |

## Key Files

- `claude-code/CLAUDE.md`: Global coding standards template
- `claude-code/global_mcp_settings.json`: MCP server config (context7, fetch, exa, playwright)
- `claude-code/plugins/dev-workflow/README.md`: Unified dev workflow reference (TDD implementation + Debug)
- `claude-code/plugins/research-report/README.md`: Research report plugin reference (iterative research + LaTeX, 9 strategies)
- `claude-code/plugins/long-horizon-impl/README.md`: Long-horizon implementation reference (research + planning + TDD implementation)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **yq + jq** (required for dev-workflow, research-report, and long-horizon-impl hooks — YAML/JSON parsing)
  - Install: `brew install yq jq` (macOS)
  - Hooks fail loudly with install instructions if missing
- **ralph-loop plugin** (required for long-horizon-impl 2-implement only; dev-workflow uses its own built-in Stop hook)
  - Install: `/plugin marketplace add alejandroBallesterosC/personal_configs && /plugin install ralph-loop`
  - Safety: ALWAYS set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **MacTeX** (optional, for research-report and long-horizon-impl LaTeX PDF compilation)
- **Claude Code** (runtime environment)

## Gotchas

- `dev-workflow` uses a built-in TDD implementation gate Stop hook for Phases 7-9 (no external ralph-loop dependency)
- `claude-code/CLAUDE.md` is a TEMPLATE (symlinked to ~/.claude/CLAUDE.md), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- **Context is preserved automatically** via Stop/SessionStart hooks - no manual action needed
- Phase transitions still validate prerequisites (can't skip phases)
- Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work
- MCP servers require env vars: `CONTEXT7_API_KEY`, `EXA_API_KEY` (in `.env`, gitignored)
- `dev-workflow` plugin contains both TDD implementation and debug workflows
- Cursor mirror (`cursor/`) is TDD-only — missing entire debug workflow (6 commands, 4 agents, 2 skills)
- VS Code `tasks.json` has dead tasks referencing removed sync scripts and leftover tasks from previous projects
- Two `marketplace.json` files exist: root (for GitHub install) and `claude-code/plugins/` (for local install) — both point to same 10 plugins (9 active + 1 deprecated autonomous-workflow)
- All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). If any hook returns `decision: "block"`, Claude continues — the most restrictive decision wins after all hooks complete. There is no sequential ordering or short-circuit between plugins
- `research-report` has its own Stop hook iteration engine — it does NOT depend on ralph-loop for iteration
- `long-horizon-impl` 1-research-and-plan uses its own Stop hook for iteration; 2-implement uses ralph-loop
- Running TDD and research/impl workflows simultaneously may cause SessionStart hook context loss (both output independently, no merging)
- `autonomous-workflow/` directory still exists but is superseded by `research-report/` and `long-horizon-impl/`
- Plugin state files (debug logs, workflow state, config overrides) are stored in `.plugin-state/` at the project repo root, NOT in `.claude/` — this avoids Claude Code's hardcoded `.claude/` directory write protection (v2.1.78+)

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
