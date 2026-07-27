---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

Worktrees give you isolated workspaces that share one repository, so you can work on several branches without switching.

Note that Claude Code also has an `EnterWorktree` tool that creates a worktree under `.claude/worktrees/` and moves the session into it. Use that when the user explicitly asks to work in a worktree. Use this skill when setting up a worktree as a workspace in the project's own convention.

## Choosing the directory

In priority order:

1. **An existing directory.** Check for `.worktrees` then `worktrees`. If both exist, `.worktrees` wins — hidden is preferred.
2. **A stated project preference.** `grep -i "worktree.*director" AGENTS.md CLAUDE.md 2>/dev/null`. If one is specified, use it without asking.
3. **Ask.** Offer project-local `.worktrees/` or the global location (`~/Documents/worktrees/<project>/<branch>`), and let the user pick.

Do not assume a location when it is ambiguous — inconsistent worktree placement is annoying to unwind later.

## Verify the directory is ignored

For a project-local directory, confirm git ignores it *before* creating the worktree:

```bash
git check-ignore -q .worktrees || git check-ignore -q worktrees
```

`check-ignore` is the right check because it respects local, global, and system gitignore rather than just the repo's `.gitignore`. If the directory is not ignored, add it to `.gitignore` and commit that before continuing. Skipping this means the worktree's contents get tracked and pollute `git status` for everyone.

A global directory outside the project needs no such check.

## Create and set up

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
git worktree add "<path>/<branch-name>" -b "<branch-name>"
```

Then install dependencies using whatever the project actually uses — detect it from the manifest present (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`) rather than assuming a toolchain. For Python, this means `uv sync`.

## Verify a clean baseline

Run the project's test command before writing any code. This is the step people skip, and it is the one that matters: without a known-good baseline you cannot tell your new failures from pre-existing ones.

If the baseline fails, report the failures and ask whether to proceed or investigate. Do not quietly continue.

Then report the worktree path, the baseline test result, and what you are about to implement.
