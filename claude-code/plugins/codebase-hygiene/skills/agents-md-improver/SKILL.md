---
name: agents-md-improver
description: Audit and improve AGENTS.md and CLAUDE.md files in repositories. Use when user asks to check, audit, update, improve, or fix agent instruction files. Scans for AGENTS.md/CLAUDE.md files, evaluates quality against templates, outputs a quality report, then makes targeted updates. Also use when the user mentions "CLAUDE.md maintenance", "AGENTS.md maintenance", or "project memory optimization".
tools: Read, Glob, Grep, Bash, Edit
---

# AGENTS.md Improver

Audit, evaluate, and improve AGENTS.md/CLAUDE.md files across a codebase to ensure coding agents have optimal project context.

**This skill can write to AGENTS.md and CLAUDE.md files.** After presenting a quality report and getting user approval, it updates instruction files with targeted improvements.

When a repository has a root `AGENTS.md`, treat it as the canonical shared instruction file for Codex, Cursor, and Claude. Every first-party `CLAUDE.md` file must be import-only and reference a same-directory `AGENTS.md`.

## What This Skill Enforces

Every documentation-maintenance pass keeps two things current:

**1. Agent interoperability structure (always enforced, every repo):**

- `AGENTS.md`: canonical shared agent instructions for Codex, Cursor Agent CLI,
  and Claude Code. The root `AGENTS.md` is the single source of truth.
- `CLAUDE.md`: import-only pointer whose entire content is `@AGENTS.md`.
- First-party subdirectory agent files: every `AGENTS.md` has a same-directory
  `CLAUDE.md`, every `CLAUDE.md` has a same-directory `AGENTS.md`, and any
  substantive Claude-specific content is moved into `AGENTS.md`. Ignore
  dependency/generated/cache directories such as `.git`, `node_modules`,
  `.venv`, `__pycache__`, and `.pytest_cache`.
- README files and all other documentation in the repo stay accurate and
  free of stale, redundant, or misleading content.

For agent interoperability across tools (Codex, Cursor, Claude Code, and other
agent CLIs), the same shared instructions can be surfaced under `.agents/`,
`.codex/`, `.cursor/`, and `.claude/` by symlinking or importing back to the
root `AGENTS.md` so every tool reads one source of truth. Prefer symlinks or
minimal import wrappers over copies, which drift.

**2. Repo-specific required docs (only when declared):**

A repo can declare documentation files that must always exist, be non-empty,
and stay current by listing them in a `.documentation-check` file at the repo
root (see [The `.documentation-check` Manifest](#the-documentation-check-manifest)).
When that file is present, every maintenance pass must keep the listed files
current and create any that are missing. When it is absent or empty, no
specific files are required beyond the interoperability structure above.

## The `.documentation-check` Manifest

Repo-specific required docs are **not** hardcoded in this skill. They are read
from a `.documentation-check` file at the repo root, which the companion
`pre-git-documentation-check` hook reads from the same location.

Format: one entry per line, `path|description`, where `path` is relative to the
repo root. Blank lines and lines beginning with `#` are ignored.

```
# .documentation-check — files that must exist, be non-empty, and stay current
docs/architecture.md|current system architecture and component boundaries
docs/datamodel.md|complete data model for every persisted entity and field
docs/api.md|request/response schemas for every public endpoint
```

Behavior:

- **File present with entries**: each listed file must exist and be non-empty;
  keep every listed file current on each pass, creating any that are missing.
- **File absent or empty**: enforce only the interoperability structure and
  general documentation currency — no specific files are required.

When a repo has no `.documentation-check`, offer to create one if the codebase
has documentation whose currency clearly matters (architecture, data model,
API contracts), but do not require it.

## Workflow

### Phase 1: Discovery

Find all agent instruction files in the repository. Prune dependency, cache,
and build directories rather than a fixed set of project paths:

```bash
find . \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ -o -name .mypy_cache -o -name .pytest_cache -o -name dist -o -name build -o -name coverage \) -prune -o \( -name "AGENTS.md" -o -name "CLAUDE.md" -o -name ".claude.md" -o -name ".claude.local.md" \) -print 2>/dev/null | head -50
```

Also read the repo-root `.documentation-check` file, if present, to learn which
repo-specific docs must stay current:

```bash
[ -f .documentation-check ] && cat .documentation-check
```

**File Types & Locations:**

| Type | Location | Purpose |
|------|----------|---------|
| Project root shared | `./AGENTS.md` | Canonical shared project context for Codex, Cursor, and Claude when present |
| Claude import | `./CLAUDE.md` | Claude-readable import of same-directory AGENTS.md only |
| Local overrides | `./.claude.local.md` | Personal/local settings (gitignored, not shared) |
| Global defaults | `~/.claude/CLAUDE.md` | User-wide defaults across all projects |
| Package-specific | `./packages/*/AGENTS.md` or `./packages/*/CLAUDE.md` | Module-level context in monorepos |
| Subdirectory | Any nested location | Feature/domain-specific context |

**Note:** Claude auto-discovers CLAUDE.md files in parent directories, making monorepo setups work automatically.

**Pairing rule:** For first-party directories only, a directory with
`AGENTS.md` must also have `CLAUDE.md`, and a directory with `CLAUDE.md` must
also have `AGENTS.md`. `CLAUDE.md` should contain only an import such as
`@AGENTS.md`. Subdirectory `AGENTS.md` files can import parent instructions
when no local additions are needed.

### Phase 2: Quality Assessment

For each instruction file, evaluate against quality criteria. See [references/quality-criteria.md](references/quality-criteria.md) for detailed rubrics.

**Quick Assessment Checklist:**

| Criterion | Weight | Check |
|-----------|--------|-------|
| Commands/workflows documented | High | Are build/test/deploy commands present? |
| Architecture clarity | High | Can Claude understand the codebase structure? |
| Non-obvious patterns | Medium | Are gotchas and quirks documented? |
| Conciseness | Medium | No verbose explanations or obvious info? |
| Currency | High | Does it reflect current codebase state? |
| Actionability | High | Are instructions executable, not vague? |

**Quality Scores:**
- **A (90-100)**: Comprehensive, current, actionable
- **B (70-89)**: Good coverage, minor gaps
- **C (50-69)**: Basic info, missing key sections
- **D (30-49)**: Sparse or outdated
- **F (0-29)**: Missing or severely outdated

### Phase 3: Quality Report Output

**ALWAYS output the quality report BEFORE making any updates.**

Format:

```
## Agent Instruction Quality Report

### Summary
- Files found: X
- Average score: X/100
- Files needing update: X

### File-by-File Assessment

#### 1. ./AGENTS.md (Project Root)
**Score: XX/100 (Grade: X)**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Commands/workflows | X/20 | ... |
| Architecture clarity | X/20 | ... |
| Non-obvious patterns | X/15 | ... |
| Conciseness | X/15 | ... |
| Currency | X/15 | ... |
| Actionability | X/15 | ... |

**Issues:**
- [List specific problems]

**Recommended additions:**
- [List what should be added]

#### 2. ./packages/api/AGENTS.md (Package-specific)
...
```

### Phase 4: Targeted Updates

After outputting the quality report, ask user for confirmation before updating.

**Update Guidelines (Critical):**

1. **Propose targeted additions only** - Focus on genuinely useful info:
   - Commands or workflows discovered during analysis
   - Gotchas or non-obvious patterns found in code
   - Package relationships that weren't clear
   - Testing approaches that work
   - Configuration quirks

2. **Keep it minimal** - Avoid:
   - Restating what's obvious from the code
   - Generic best practices already covered
   - One-off fixes unlikely to recur
   - Verbose explanations when a one-liner suffices

3. **Show diffs** - For each change, show:
   - Which AGENTS.md or CLAUDE.md file to update
   - The specific addition (as a diff or quoted block)
   - Brief explanation of why this helps future sessions

**Diff Format:**

```markdown
### Update: ./CLAUDE.md

**Why:** Build command was missing, causing confusion about how to run the project.

```diff
+ ## Quick Start
+
+ ```bash
+ npm install
+ npm run dev  # Start development server on port 3000
+ ```
```
```

### Phase 5: Apply Updates

After user approval, apply changes using the Edit tool. Preserve existing content structure.

If `AGENTS.md` exists, put shared project facts there. Update `CLAUDE.md` only to keep it as an import-only pointer to same-directory `AGENTS.md`.

## Templates

See [references/templates.md](references/templates.md) for CLAUDE.md templates by project type.

## Common Issues to Flag

1. **Stale commands**: Build commands that no longer work
2. **Missing dependencies**: Required tools not mentioned
3. **Outdated architecture**: File structure that's changed
4. **Missing environment setup**: Required env vars or config
5. **Broken test commands**: Test scripts that have changed
6. **Undocumented gotchas**: Non-obvious patterns not captured

## User Tips to Share

When presenting recommendations, remind users:

- **`#` key shortcut**: During a Claude session, press `#` to have Claude auto-incorporate learnings into CLAUDE.md
- **Keep it concise**: AGENTS.md/CLAUDE.md should be human-readable; dense is better than verbose
- **Actionable commands**: All documented commands should be copy-paste ready
- **Use `.claude.local.md`**: For personal preferences not shared with team (add to `.gitignore`)
- **Global defaults**: Put user-wide preferences in `~/.claude/CLAUDE.md`

## What Makes a Great AGENTS.md or CLAUDE.md

**Key principles:**
- Concise and human-readable
- Actionable commands that can be copy-pasted
- Project-specific patterns, not generic advice
- Non-obvious gotchas and warnings

**Recommended sections** (use only what's relevant):
- Commands (build, test, dev, lint)
- Architecture (directory structure)
- Key Files (entry points, config)
- Code Style (project conventions)
- Environment (required vars, setup)
- Testing (commands, patterns)
- Gotchas (quirks, common mistakes)
- Workflow (when to do what)
