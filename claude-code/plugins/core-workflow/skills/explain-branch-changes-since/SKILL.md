---
name: explain-branch-changes-since
description: Summarize changes pushed by collaborators to the remote version of your current branch since a date/time or commit. User-invoked only.
disable-model-invocation: true
argument-hint: <date-time-or-commit-hash> [timezone]
allowed-tools: Read, Grep, Glob, Bash, Agent
effort: xhigh
---

# Explain Branch Changes Since

Fetch the remote tracking branch of the currently checked-out branch and synthesize what collaborators other than you have pushed to it since a given date/time or commit.

This is strictly read-only: no checkout, no merge, no push, no file edits, no commits.

## Step 0: Validate arguments and state

The user's arguments are: **$ARGUMENTS**

- If no cutoff was provided, respond with "Usage: /core-workflow:explain-branch-changes-since <date-time-or-commit-hash> [timezone]  You must specify a cutoff." and stop.
- Determine whether the cutoff is a commit or a date/time: if `git cat-file -e <cutoff>^{commit}` succeeds, it is a commit. Otherwise treat it as a date/time, using the provided timezone or defaulting to Eastern Time. Use the IANA name (`America/New_York`) rather than a fixed offset so daylight saving is handled.
- Check for an upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`. If it fails, respond with "Current branch '<branch>' has no upstream tracking branch configured — nothing to compare against." and stop.

## Step 1: Fetch and identify the user

Run in parallel: `git fetch`; `git config user.email` and `git config user.name`; `git rev-parse --abbrev-ref HEAD` and `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`.

## Step 2: Collect qualifying commits

For a commit cutoff:
```bash
git log <cutoff>..@{upstream} --pretty=format:'%H%x09%an%x09%ae%x09%aI%x09%s'
```

For a date/time cutoff:
```bash
TZ="<IANA timezone>" git log @{upstream} --since="<date-time>" --pretty=format:'%H%x09%an%x09%ae%x09%aI%x09%s'
```

Exclude commits whose author name or email matches the current user. If a commit's authorship is ambiguous (for example the user has several emails), include it and flag the ambiguity rather than dropping it silently.

If nothing remains, report "No changes found on <upstream branch> since <cutoff> by collaborators other than you." and stop.

## Step 3: Get the diff

```bash
git diff <oldest-qualifying-commit>^..@{upstream}
git diff --stat <oldest-qualifying-commit>^..@{upstream}
git diff --name-status <oldest-qualifying-commit>^..@{upstream}
```

## Step 4: Launch parallel analysis agents

The user invoked this skill to get a parallel multi-angle review, so delegate rather than reading the diff serially. Launch one agent per focus area, all in a single message, scoped to the qualifying commits. Five focus areas means up to five agents; combine them when the diff is small.

Give every agent the qualifying commit list (author, date, subject), the full diff, and this shared brief:

> This is read-only: do not edit any files. Report everything you find in your focus area, most significant first, with `file:line` citations. Note your confidence in each finding rather than omitting the uncertain ones — the synthesis step decides what surfaces.

Focus areas, mirroring `/core-workflow:compare-branch-to-another`:

1. **Structural and architectural impact** (`Explore`) — files and modules touched, categorized by type; dependency changes.
2. **Logic and behavior changes** (`Explore`) — what the changes do; new and removed behavior; API and contract changes.
3. **Testing changes** (`Explore`) — coverage added or removed, and gaps where implementation changed without tests.
4. **Code quality** (`general-purpose`, prompted as a code reviewer) — style, complexity, duplication.
5. **Risk and impact** (`general-purpose`, prompted as a risk reviewer) — security, performance, breaking changes, with a severity per risk.

If the diff is too large to pass whole, give each agent the portion for its area and note the truncation in the report.

## Step 5: Synthesize

```markdown
# Changes on <upstream branch> Since <cutoff>

## Overview
- Current branch: <branch> (tracking <upstream>)
- Qualifying commits: [count]
- Collaborators: [authors]

## Structural Changes

## Behavior Changes

## Testing Changes

## Code Quality Assessment

## Risk Assessment
[With severity per risk]

## Summary
[What collaborators pushed and what it means for your local work — in particular whether to pull before continuing]
```

Keep each section to a few paragraphs. The reader's real question is usually whether they need to pull and what will surprise them if they do, so lead with that. Keep uncertain findings and label them as uncertain.
