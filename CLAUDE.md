# Personal Configs

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 7 plugins (Dev Workflow, Autonomous Workflow, Playwright, Session Feedback, Infrastructure-as-Code, CLAUDE.md Best Practices, Ralph Loop), configuration sync scripts, and IDE integrations.

## Architecture

```
claude-code/
├── plugins/           # 7 encapsulated plugins (installed via marketplace)
│   ├── dev-workflow/  # 12 agents, 18 commands, 6 skills, 4 hooks (TDD + Debug)
│   ├── autonomous-workflow/ # 6 agents, 5 commands, 1 skill, 2 hooks (Research/Plan/Implement)
│   ├── playwright/    # Browser automation (JS + skill)
│   ├── claude-session-feedback/ # 4 commands
│   ├── infrastructure-as-code/ # 1 command, 1 skill
│   ├── claude-md-best-practices/ # 1 skill
│   └── ralph-loop/   # Iterative AI loops (3 commands, 1 hook)
├── commands/          # 7 shared global commands (symlinked to ~/.claude/commands/)
├── docs/              # Python, UV, Docker best practices (symlinked to ~/.claude/docs/)
└── CLAUDE.md          # Global coding standards template (symlinked to ~/.claude/)
sync-content-scripts/  # Symlink setup script (Claude Code) + 1 copy-based sync script (Cursor)
cursor/                # Cursor IDE mirror (42 files, TDD-only, unidirectional sync)
```

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: Defines `name`, `tools`, `model` (sonnet|opus)
- **Skill activation**: Skills auto-activate when context matches their description
- **Hooks**: Event-driven automation (Stop, SessionStart across dev-workflow + autonomous-workflow)
  - `Stop`: Archive completed workflows + run scoped tests + state verification agent (dev-workflow), iteration control (ralph-loop), iteration engine + completion verifier (autonomous-workflow)
  - `SessionStart`: Auto-restore context after compact/clear (dev-workflow: TDD + debug state, autonomous-workflow: research/planning/impl state)

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
- `claude-code/plugins/autonomous-workflow/README.md`: Autonomous workflow reference (4 modes, 8 strategies)
- `docs/CODEBASE.md`: Comprehensive codebase analysis (architecture, workflows, open questions)

## Dependencies

- **yq + jq** (required for dev-workflow and autonomous-workflow hooks — YAML/JSON parsing)
  - Install: `brew install yq jq` (macOS)
  - Hooks fail loudly with install instructions if missing
- **ralph-loop plugin** (required for TDD implementation phase in dev-workflow)
  - Install: `/plugin marketplace add alejandroBallesterosC/personal_configs && /plugin install ralph-loop`
  - Safety: ALWAYS set `--max-iterations` (50 iterations = $50-100+ in API costs)
- **MacTeX** (optional, for autonomous-workflow LaTeX PDF compilation)
- **Claude Code** (runtime environment)

## Gotchas

- `ralph-loop` is external dependency for dev-workflow - install via plugin marketplace (see Dependencies)
- `claude-code/CLAUDE.md` is a TEMPLATE (symlinked to ~/.claude/CLAUDE.md), not this repo's CLAUDE.md
- Test auto-detection exits 0 when no framework found (non-fatal for repos without tests)
- **Context is preserved automatically** via Stop/SessionStart hooks - no manual action needed
- Phase transitions still validate prerequisites (can't skip phases)
- Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work
- MCP servers require env vars: `CONTEXT7_API_KEY`, `EXA_API_KEY` (in `.env`, gitignored)
- `dev-workflow` plugin contains both TDD implementation and debug workflows
- Cursor mirror (`cursor/`) is TDD-only — missing entire debug workflow (6 commands, 4 agents, 2 skills)
- VS Code `tasks.json` has dead tasks referencing removed sync scripts and leftover tasks from previous projects
- Two `marketplace.json` files exist: root (for GitHub install) and `claude-code/plugins/` (for local install) — both point to same 7 plugins
- Stop hook chain order (per marketplace.json): dev-workflow → ralph-loop → autonomous-workflow. If an earlier hook blocks, later hooks do not run
- `autonomous-workflow` has its own Stop hook iteration engine (stop-hook.sh) — it does NOT depend on ralph-loop for iteration
- Running TDD and autonomous workflows simultaneously may cause SessionStart hook context loss (both output independently, no merging)

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

This creates three symlinks:
- `~/.claude/CLAUDE.md` → `claude-code/CLAUDE.md`
- `~/.claude/commands/` → `claude-code/commands/`
- `~/.claude/docs/` → `claude-code/docs/`

Cursor configs use copy-based sync (symlinks are unreliable in Cursor):
```bash
./sync-content-scripts/cursor/sync_to_cursor.sh
```

Plugins install via marketplace (not file sync).

## Documentation

- `docs/CODEBASE.md`: Full codebase analysis (architecture, workflows, Q&A)
- `claude-code/docs/`: Best practices guides (python.md, using-uv.md, docker-uv.md)
