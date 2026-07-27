---
name: agents-md-improver
description: Audit and improve AGENTS.md and CLAUDE.md files in repositories. Use when user asks to check, audit, update, improve, or fix agent instruction files. Scans for AGENTS.md/CLAUDE.md files, evaluates quality against templates, outputs a quality report, then makes targeted updates. Also use when the user mentions "CLAUDE.md maintenance", "AGENTS.md maintenance", or "project memory optimization".
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# AGENTS.md Improver

Audit and improve the AGENTS.md/CLAUDE.md files across a codebase so coding agents get accurate project context.

This skill writes to AGENTS.md and CLAUDE.md files. Report on quality first, get the user's agreement, then make targeted edits.

## What it enforces

**1. Agent interoperability structure, in every repo:**

- `AGENTS.md` is the canonical shared instruction file for Codex, Cursor Agent CLI, and Claude Code. The root `AGENTS.md` is the single source of truth.
- `CLAUDE.md` is import-only: its entire content is `@AGENTS.md`.
- In first-party directories, the two files come in pairs — every `AGENTS.md` has a same-directory `CLAUDE.md` and vice versa. Substantive Claude-specific content moves into `AGENTS.md`. Ignore dependency, generated, and cache directories (`.git`, `node_modules`, `.venv`, `__pycache__`, `.pytest_cache`).
- READMEs and other documentation stay accurate and free of stale or misleading content.

Other agent CLIs can read the same source through `.agents/`, `.codex/`, `.cursor/`, and `.claude/` by symlinking or importing back to the root `AGENTS.md`. Prefer symlinks or minimal import wrappers over copies, since copies drift.

**2. Repo-specific required docs, only when declared.** A repo declares docs that must exist, be non-empty, and stay current by listing them in `.documentation-check` at the repo root. When that file is absent or empty, only the interoperability structure applies.

## The `.documentation-check` manifest

Required docs are not hardcoded here. They are read from `.documentation-check` at the repo root, the same file the companion `pre-git-documentation-check` hook reads.

One entry per line, `path|description`, path relative to the repo root. Blank lines and `#` comments are ignored:

```
# .documentation-check — files that must exist, be non-empty, and stay current
docs/architecture.md|current system architecture and component boundaries
docs/datamodel.md|complete data model for every persisted entity and field
docs/api.md|request/response schemas for every public endpoint
```

With entries present, keep every listed file current on each pass and create any that are missing. When the file is absent, enforce only the interoperability structure and general documentation currency. If a repo has no manifest but does have documentation whose currency clearly matters (architecture, data model, API contracts), offer to create one — do not require it.

## Workflow

**Discover.** Find the instruction files, pruning dependency and build directories rather than guessing at project paths:

```bash
find . \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ -o -name .mypy_cache -o -name .pytest_cache -o -name dist -o -name build -o -name coverage \) -prune -o \( -name "AGENTS.md" -o -name "CLAUDE.md" -o -name ".claude.md" -o -name ".claude.local.md" \) -print 2>/dev/null | head -50
```

Read `.documentation-check` too, if it exists.

The files you may find, and what each is for:

| Type | Location | Purpose |
|------|----------|---------|
| Project root shared | `./AGENTS.md` | Canonical shared context for Codex, Cursor, and Claude |
| Claude import | `./CLAUDE.md` | Import-only pointer to same-directory AGENTS.md |
| Local overrides | `./.claude.local.md` | Personal settings, gitignored, not shared |
| Global defaults | `~/.claude/CLAUDE.md` | User-wide defaults across projects |
| Package-specific | `./packages/*/AGENTS.md` | Module-level context in monorepos |

Claude auto-discovers CLAUDE.md files in parent directories, which is what makes monorepo setups work without per-package duplication.

**Assess.** Judge each file against the criteria in [references/quality-criteria.md](references/quality-criteria.md): whether build/test/deploy commands are present and correct, whether the architecture description matches the actual structure, whether non-obvious gotchas are captured, whether it is concise rather than padded with the obvious, whether it reflects the current state of the code, and whether instructions are executable rather than vague.

Check claims against the codebase rather than judging the prose on its own. A confidently-worded stale command is worse than a missing one.

**Report before editing.** Present findings first, per file, with the specific problems you found and what you would add. Give the user something they can disagree with before anything changes.

**Then update, with approval.** Propose targeted additions only: commands and workflows you discovered, gotchas found in the code, package relationships that were not obvious, testing approaches that actually work, configuration quirks. Show each change as a diff with one line on why it helps a future session.

Do not add restatements of what the code makes obvious, generic best practices, or one-off fixes unlikely to recur. Shared project facts go in `AGENTS.md`; `CLAUDE.md` is touched only to keep it an import-only pointer.

See [references/templates.md](references/templates.md) for templates by project type and [references/update-guidelines.md](references/update-guidelines.md) for worked examples of what to add versus omit.

## Issues worth flagging

Stale build commands, required tools that go unmentioned, architecture descriptions that no longer match the tree, missing environment setup, test commands that have changed, and undocumented gotchas.

## Tips worth passing to the user

- Pressing `#` during a session has Claude fold a learning into the instruction file.
- `.claude.local.md` holds personal preferences not shared with the team — gitignore it.
- `~/.claude/CLAUDE.md` holds preferences that should apply across all projects.
