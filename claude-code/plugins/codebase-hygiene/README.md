# codebase-hygiene

A lean set of skills and a hook for keeping a codebase well-organized, clean, and well documented — with documentation kept evergreen and agent instruction files (`AGENTS.md`/`CLAUDE.md`) correctly paired for cross-tool interoperability.

```
/plugin install codebase-hygiene
```

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `codebase-hygiene` | Skill | Umbrella hygiene pass — run before committing: docs current, agent files paired, repo organized, names evergreen |
| `agents-md-improver` | Skill | Audits and improves `AGENTS.md`/`CLAUDE.md` files and repo documentation; outputs a quality report, then makes targeted updates |
| `pre-git-documentation-check` | Hook (`PreToolUse`) | Blocks git/GitHub commit and PR mutations until the documentation contract holds; reminds once per change that all docs must be current |

The skill and the hook read the same repo-root `.documentation-check` manifest, so what a repo declares as required documentation is enforced consistently by both.

## The `.documentation-check` manifest

To have specific documentation files enforced in a repo, add a `.documentation-check` file at the repo root. Each non-empty, non-comment line is a `path|description` entry — `path` is relative to the repo root, `description` explains what the file must contain.

```
# .documentation-check — files that must exist, be non-empty, and stay current
docs/architecture.md|current system architecture and component boundaries
docs/datamodel.md|complete data model for every persisted entity and field
docs/api.md|request/response schemas for every public endpoint
```

- **Present with entries**: each listed file must exist, be non-empty, and stay current before a commit is allowed.
- **Absent or empty**: no specific files are enforced. The hook and skill still enforce general documentation currency and the `AGENTS.md`/`CLAUDE.md` structure below.

The manifest is optional. A repo with no `.documentation-check` still gets the always-on checks.

## What the hook enforces

Before any git/GitHub commit or PR mutation, the `pre-git-documentation-check` guard checks the repository being committed to (its git toplevel) and blocks when:

- Root `AGENTS.md` is missing or empty.
- Root `CLAUDE.md` is not exactly `@AGENTS.md`.
- A first-party directory has an `AGENTS.md` without a paired `CLAUDE.md`, or a `CLAUDE.md` that is not a minimal `@AGENTS.md` wrapper, or vice versa. Dependency, cache, and build directories (`.git`, `node_modules`, `.venv`, `__pycache__`, `.mypy_cache`, `.pytest_cache`, `dist`, `build`, `coverage`) are ignored.
- Any file listed in `.documentation-check` is missing or empty.

When the contract holds, the guard denies the first commit attempt once per change with a reminder to bring all documentation up to date (naming any `.documentation-check` files), then allows the unchanged diff on the next attempt.

## Cross-tool agent configuration

The root `AGENTS.md` is the single source of truth for shared agent instructions. For interoperability across Codex, Cursor, Claude Code, and other agent CLIs, surface the same instructions under `.agents/`, `.codex/`, `.cursor/`, and `.claude/` by symlinking or importing back to the root `AGENTS.md`, rather than copying (copies drift). The `agents-md-improver` skill and the `codebase-hygiene` skill both describe this setup.

## Dependencies

- `jq` — required by the hook to parse tool-call payloads. If missing, the hook blocks with an explanatory message rather than failing open.
- `git` — the hook only acts inside a git work tree.
