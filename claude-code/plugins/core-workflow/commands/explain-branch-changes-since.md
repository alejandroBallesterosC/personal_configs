---
description: Summarize changes pushed by collaborators to the remote version of your current branch since a date/time or commit
argument-hint: <date-time-or-commit-hash> [timezone]
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Explain Branch Changes Since

Fetch the remote tracking branch of the branch you currently have checked out, and synthesize what other collaborators (not you) have pushed to it since a given date/time or commit hash.

## IMPORTANT: DO NOT EDIT ANY CODE, CHANGE ANY FILES, CHECK OUT ANY BRANCH, MERGE, OR MAKE ANY GIT ADDITIONS, COMMITS, OR PUSHES WHILE CARRYING OUT THESE INSTRUCTIONS.

## STEP 0: VALIDATE ARGUMENTS AND STATE

The user's arguments are: **$ARGUMENTS**

- If no cutoff was provided (neither a date/time nor a commit hash), respond with "Usage: /explain-branch-changes-since <date-time-or-commit-hash> [timezone]  You must specify a cutoff." and stop.
- Determine whether the cutoff is a commit hash or a date/time:
  - If it resolves via `git cat-file -e <cutoff>^{commit}`, treat it as a commit hash.
  - Otherwise treat it as a date/time. If a timezone was also provided, use it; if not, **assume Eastern Time (America/New_York)** — use the IANA timezone name so daylight saving is handled automatically.
- Check the current branch has an upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`. If this fails, respond with "Current branch '<branch>' has no upstream tracking branch configured — nothing to compare against." and stop.

## STEP 1: FETCH AND IDENTIFY THE USER

Run in parallel:

1. `git fetch`
2. `git config user.email` and `git config user.name` (to exclude the user's own commits later)
3. `git rev-parse --abbrev-ref HEAD` and `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}` (current branch and its upstream)

## STEP 2: COLLECT QUALIFYING COMMITS

If the cutoff is a **commit hash**:
```bash
git log <cutoff>..@{upstream} --pretty=format:'%H%x09%an%x09%ae%x09%aI%x09%s'
```

If the cutoff is a **date/time**:
```bash
TZ="<IANA timezone, e.g. America/New_York>" git log @{upstream} --since="<date-time>" \
  --pretty=format:'%H%x09%an%x09%ae%x09%aI%x09%s'
```

From the results, **exclude any commit whose author name or email matches the current user** (from Step 1). What remains are candidate commits from other collaborators.

If nothing remains, report "No changes found on <upstream branch> since <cutoff> by collaborators other than you." and stop.

## STEP 3: GET THE ACTUAL DIFF

```bash
git diff <oldest-qualifying-commit>^..@{upstream}
```

Also capture:
```bash
git diff --stat <oldest-qualifying-commit>^..@{upstream}
git diff --name-status <oldest-qualifying-commit>^..@{upstream}
```

## STEP 4: LAUNCH PARALLEL ANALYSIS AGENTS

Launch agents in parallel (single message, multiple Agent tool calls) mirroring the `/compare-branch-to-another` structure, scoped to just the qualifying commits:

- **Agent 1** (`subagent_type: "Explore"`) — Structural & Architectural Impact: what files/modules are touched, categorize by type, dependency changes.
- **Agent 2** (`subagent_type: "Explore"`) — Logic & Behavior Changes: what the changes actually do, new/removed behavior, API/contract changes.
- **Agent 3** (`subagent_type: "Explore"`) — Testing Changes: test coverage added/removed, gaps.
- **Agent 4** (`subagent_type: "general-purpose"`, prompted as a code reviewer) — Code Quality: style, complexity, duplication, confidence-scored findings (>=80% confidence only).
- **Agent 5** (`subagent_type: "general-purpose"`, prompted as a risk reviewer) — Risk & Impact: security, performance, breaking changes, confidence-scored findings (>=80% confidence only).

Give every agent the qualifying commit list (author, date, subject) and the full diff from Step 3.

## STEP 5: SYNTHESIZE

```markdown
# Changes on <upstream branch> Since <cutoff>

## Overview
- Current branch: <branch> (tracking <upstream>)
- Qualifying commits: [count]
- Collaborators: [list of authors]

## Structural Changes
[Agent 1]

## Behavior Changes
[Agent 2]

## Testing Changes
[Agent 3]

## Code Quality Assessment
[Agent 4, >=80% confidence findings]

## Risk Assessment
[Agent 5, >=80% confidence findings]

## Summary
[Bullet-point summary of what collaborators pushed and why it matters, e.g. whether to pull before continuing local work]
```

## IMPORTANT NOTES

- This command is strictly read-only: no checkout, no merge, no push, no file edits.
- If the diff is extremely large, summarize the most impactful changes and note truncation.
- If a commit's author name/email doesn't clearly match or exclude the current user, err on the side of including it and flag the ambiguity rather than silently dropping it.
