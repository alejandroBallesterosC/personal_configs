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
    └── conceptual-thought-partner/ # 1 Fable subagent + 1 user-invoked skill (conceptual sparring, architecture review, interactive multi-turn discussion with handoff doc; never implements)
AGENTS.md          # This file (canonical shared instructions; CLAUDE.md imports it)
CLAUDE.md          # Import-only wrapper: @AGENTS.md
.claude-plugin/    # Marketplace manifest (marketplace.json)
.claude/           # This repo's own session config (settings.json, settings.local.json)
.agents/hooks/     # Standalone copy of the codebase-hygiene guard, wired up by .claude/settings.json
.vscode/           # VS Code tasks — leftover from a prior unrelated project
.github/workflows/ # claude.yml, claude-code-review.yml
```

Two plugins have no README of their own, so their mechanics are recorded here:

- **clear-writing**: 1 skill plus `references/` (examples, banned phrases, banned structures). The banned-phrase and banned-structure lists encode specific taste (no em dashes anywhere including number ranges, no "leverage"/"delve"/"robust"/"seamless", no "not X, it's Y" pivots) — a capable model will not infer these, so do not compress them away.
- **conceptual-thought-partner**: 1 subagent pinned to `model: fable` plus 1 user-invoked `think` skill. Both are the same persona and must stay aligned when either changes. The subagent is one-shot with fresh context and is restricted to `Read`/`Grep`/`Glob`. The `think` skill is interactive and multi-turn, meant to run in a branched session (`/branch` then `/model fable`) so it inherits the working session's context. Its no-edit guarantee comes from **plan mode**, entered manually with `Shift+Tab` — a skill cannot set its own permission mode, so the skill can only require and warn, not enforce. When the user says they are done and asks for the handoff, it calls `ExitPlanMode` (the approval prompt is the deliberate gate) and writes exactly one file to `docs/thinking/`.

## Key Patterns

- **Plugin structure**: Each plugin has `commands/`, `agents/`, `skills/`, optional `hooks/`
- **Agent YAML frontmatter**: `name`, `description`, `model` (`inherit`|`sonnet`|`opus`|`haiku`|`fable`|full model ID), `effort` (`low`..`max`), optional `color` and `tools`. Plugin-shipped agents cannot use `hooks`, `mcpServers`, or `permissionMode`
- **Skill YAML frontmatter**: `name`, `description`, plus optional `disable-model-invocation`, `argument-hint`, `allowed-tools`, `disallowed-tools`, `effort`, `model`, `context`
- **Skill activation**: Skills auto-activate when context matches their description, unless they set `disable-model-invocation: true` (user-invoked only, and excluded from the always-loaded skill listing)
- **Version bumping**: Any time a change is made to a Claude Code plugin you MUST bump (increase) the version number in the plugin's `plugin.json` so that it registers as having been updated. Keep the version in exactly one place — do not add a `## Version` section to a plugin README, which drifts
- **Hooks**: Event-driven automation — `notify` uses Stop/Notification hooks; `codebase-hygiene` uses a PreToolUse hook to guard commits
- **Project-level hooks**: `.claude/settings.json` registers a PreToolUse guard for this repo's own sessions, pointing at `.agents/hooks/pre-git-documentation-check.sh` — a copy of the `codebase-hygiene` hook kept outside the plugin so it runs without the plugin installed. Keep that copy in sync with `claude-code/plugins/codebase-hygiene/hooks/`; it is a duplicate, so fixes to one must be applied to the other

## Design Decisions

Why the repo is shaped this way. These are settled — reopen them deliberately, not by accident.

| Decision | Rationale |
|----------|-----------|
| Self-contained plugin dirs with manifests, not flat global commands | Isolation and marketplace distribution, at the cost of a real install step |
| Plugins-only repo | One clear purpose and no symlink/sync-script maintenance. The global Claude Code config and Cursor mirror this repo used to host now live elsewhere |
| `core-workflow` bundles 12 skills instead of 6 small plugins | Smaller system-prompt footprint and less to maintain, losing some per-workflow namespacing |
| Skills applied directly, not hooks plus state machines | No external deps and no infinite-loop risk between competing hooks. The tradeoff is real: there is no hard enforcement, so a skill works only when the model actually applies it |
| No TDD Stop-hook test gate | Avoids hook-ordering conflicts and still works when the model forgets once, at the cost of no forced verification |
| No hand-rolled iteration engines (Ralph-loop style) | Native Plan Mode, TaskCreate/TaskList, and the Workflow tool cover multi-step work; bespoke bash while-loop Stop hooks per plugin were not worth maintaining |

## Interface Contracts

**Hooks.** Command hooks always exit 0 and encode the decision in stdout JSON; empty stdout means allow. For `PreToolUse` the deny shape is `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}}` — the top-level `decision`/`reason` pair is deprecated for that event. Other events and providers differ: `{"decision": "block", ...}` for Stop/SubagentStop and the Codex provider, `{"permission": "deny", ...}` for Cursor. `pre-git-documentation-check.sh` branches per provider for this reason.

`notify`'s hooks never block. `codebase-hygiene`'s PreToolUse guard does. It resolves the target repo from the working directory's git toplevel, requires `jq`, only acts inside a git work tree, and reminds once per unique diff before allowing the same diff through on the next attempt.

**Coupling.** Plugins have no hard cross-plugin dependencies. `core-workflow`'s `tdd-discipline` optionally points at `playwright` for visual verification, and its `latex-report` optionally uses `pdflatex`. Both degrade gracefully.

**Distribution.** Marketplace only (`/plugin marketplace add` + `/plugin install`). There is deliberately no symlink or copy-based sync mechanism.

## Conventions

1. **ABOUTME comments**: code files open with two `# ABOUTME:` lines
2. **YAML frontmatter** on every command, agent, and skill
3. **Read-only orchestration skills**: `core-workflow`'s user-invoked skills forbid edits, commits, and pushes; `readonly` and `research` additionally enforce it with `disallowed-tools`
4. **Outcome-oriented skill prose**: state the rule and its reason rather than shouting or scripting each step. Keep examples only where they encode a preference the model could not infer — the Terraform directory layout, the `[DEBUG-H1]` instrumentation convention, the destructive-change warning format
5. **No linting config**, by design: Markdown, JSON, Bash, and one Python renderer with its own tests

## No Application Code

This repo contains ONLY:
- Markdown files (commands, agents, skills)
- JSON configs (plugin manifests)
- Shell scripts (hooks, and `export-to-clipboard`'s export script)
- Python (`export-to-clipboard`'s transcript renderer and its tests)

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
- Each plugin's own `README.md` documents its components. `clear-writing` and `conceptual-thought-partner` have none — see the Architecture section above.

## Tests

Three suites, all runnable from the repo root with no setup:

```bash
bash claude-code/plugins/codebase-hygiene/hooks/tests/test-hook-configs.sh
bash claude-code/plugins/codebase-hygiene/hooks/tests/test-pre-git-documentation-check.sh
python3 claude-code/plugins/export-to-clipboard/skills/export-to-clipboard/scripts/tests/test_render_transcript.py
```

The hook tests assert on the JSON the hook writes to stdout, not on its exit code — the script always exits 0 and encodes allow/block in that JSON. Change a hook's output shape and its test must change with it.

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
- `allowed-tools` on a skill only **pre-approves** the listed tools; every other tool stays callable. Real restriction comes from `disallowed-tools`. A skill using the subagent-only `tools:` field instead of `allowed-tools` silently restricts nothing
- Editing a plugin in this repo does not change the *installed* copy under `~/.claude/plugins/cache/`. A skill invoked during a session runs the installed version, so verify plugin edits by reading the repo files, not by invoking the skill
- Prose instructions in skills target Claude Opus 5, which self-verifies without being told to and follows conservative-reporting instructions literally. Do not add "double-check your work" scaffolding or `>=N% confidence only` filters — the first wastes tokens, the second suppresses findings. Keep feedback loops that surface real external output (screenshots, test runs, `terraform plan`); those are not the same thing
