---
name: codebase-hygiene
description: Use after finishing implementation work, when writing or updating documentation, and when creating or editing a skill, hook, command, or agent in a repo. Keeps the codebase organized, evergreen, and well documented, and keeps AGENTS.md/CLAUDE.md and cross-tool agent config correctly paired.
---

# Codebase Hygiene

Keep the codebase organized, clean, and documented as you work, so a commit
never leaves stale docs or a broken agent-config structure behind.

## When to Use

- After finishing a unit of implementation work, before committing.
- When writing or updating any documentation (README, `AGENTS.md`, `docs/`).
- When creating or editing a skill, hook, command, or agent.

## Companion pieces in this plugin

- **`agents-md-improver` skill**: audits and improves `AGENTS.md`/`CLAUDE.md`
  files and repo documentation. Load it for a focused documentation pass. It
  reads repo-specific required docs from a root `.documentation-check` file.
- **`pre-git-documentation-check` hook**: a `PreToolUse` guard that fires before
  git/GitHub commit and PR mutations. It blocks until the documentation
  contract holds, then reminds once per change that all docs must be current.

The skill and the hook read the same `.documentation-check` manifest, so what a
repo declares as required is enforced consistently by both.

## The Hygiene Pass

Run this before committing.

### 1. Documentation is current

- Every README, `AGENTS.md`, and `docs/` file reflects the code as it is now.
  No stale commands, dead file paths, or descriptions of removed behavior.
- No obviously redundant or contradictory documentation.
- Documentation is evergreen: it describes current state, not what changed or
  "was recently refactored".
- If the repo has a `.documentation-check` file, every listed doc exists, is
  non-empty, and is current. For a deeper pass, load `agents-md-improver`.

### 2. Agent instruction files are paired and canonical

- Root `AGENTS.md` exists and is the single source of truth for shared agent
  instructions (Codex, Cursor, Claude Code, and other agent CLIs).
- Root `CLAUDE.md` contains exactly `@AGENTS.md` and nothing else.
- In first-party directories, `AGENTS.md` and `CLAUDE.md` come in pairs: every
  `AGENTS.md` has a same-directory `CLAUDE.md` (an `@AGENTS.md` import) and vice
  versa. Substantive instructions live in `AGENTS.md`, never only in
  `CLAUDE.md`.
- For cross-tool interoperability, surface the same instructions under
  `.agents/`, `.codex/`, `.cursor/`, and `.claude/` by symlinking or importing
  back to the root `AGENTS.md`. Prefer symlinks or minimal import wrappers over
  copies, which drift out of sync.

### 3. The repo is organized

- New files live where their kind already lives; follow the existing layout
  rather than inventing a parallel one.
- No duplicate or near-duplicate files created to work around a problem; fix the
  original instead.
- No dead code, scratch files, or commented-out blocks left behind. Delete from
  evidence (an unused, unreferenced artifact), not on a hunch.
- New skills, hooks, commands, and agents follow the conventions already used by
  their siblings (frontmatter shape, `ABOUTME:` comments, naming).

### 4. Names are evergreen

- No `new`, `improved`, `enhanced`, `v2`, or `final` in file, symbol, or
  directory names. What is new today is old later; name for what a thing *is*.

## The `.documentation-check` Manifest

A repo declares its required documentation files in a `.documentation-check`
file at the repo root. One entry per line, `path|description`, path relative to
the repo root. Blank lines and lines starting with `#` are ignored.

```
# .documentation-check — docs that must exist, be non-empty, and stay current
docs/architecture.md|current system architecture and component boundaries
docs/datamodel.md|complete data model for every persisted entity and field
```

When the file is absent or empty, no specific docs are required — only the
general currency and agent-config-pairing checks above apply.
