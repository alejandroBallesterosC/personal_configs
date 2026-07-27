---
name: compare-branch-to-another
description: Compare the current git branch against another branch using parallel subagents. User-invoked only.
disable-model-invocation: true
argument-hint: <other-branch>
allowed-tools: Read, Grep, Glob, Bash, Agent
effort: xhigh
---

# Compare Current Git Branch to Another

Compare the current git branch against `<OTHER_BRANCH>` using parallel subagents, producing a multi-angle analysis of the differences.

If `<OTHER_BRANCH>` was not specified, respond with "Usage: /core-workflow:compare-branch-to-another <OTHER_BRANCH>  You must specify another branch to compare this one to" and stop. If it was specified but does not exist, respond with "I could not find the branch you wish to compare this one to" and stop, suggesting `git branch -a`.

This is a read-only review. Do not edit files, stage, commit, or push at any point.

## Step 1: Gather git context

Run these three commands in parallel:

```bash
echo "CURRENT_BRANCH: $(git rev-parse --abbrev-ref HEAD)" && echo "MERGE_BASE: $(git merge-base HEAD <OTHER_BRANCH>)" && echo "COMMITS_AHEAD: $(git rev-list --count <OTHER_BRANCH>..HEAD)" && echo "COMMITS_BEHIND: $(git rev-list --count HEAD..<OTHER_BRANCH>)"
git diff --stat <OTHER_BRANCH>...HEAD
git diff --name-status <OTHER_BRANCH>...HEAD
```

Then get the full diff: `git diff <OTHER_BRANCH>...HEAD`

The three-dot form shows changes since the branches diverged, which is what you want here. If the diff is too large to pass along whole, give each agent the stat and name-status output plus the diff for the files in its area, and say in the final report that the diff was truncated.

## Step 2: Launch parallel analysis agents

The user invoked this skill to get a parallel multi-angle review, so delegate rather than reviewing the diff serially yourself. Launch one agent per focus area below, all in a single message. Five focus areas means up to five agents; combine two if the diff is small enough that separate agents would report the same things.

Give every agent the same shared brief:

> You are analyzing the difference between two git branches. Current branch: [insert]. Target branch: `<OTHER_BRANCH>`. Commits ahead: [insert]. Commits behind: [insert].
>
> CHANGED FILES: [insert name-status output]
> DIFF STATS: [insert stat output]
> FULL DIFF: [insert full diff]
>
> This is read-only: do not edit any files. Report everything you find in your focus area, ordered with the most significant first. Note how confident you are in each finding rather than dropping the ones you are unsure about — the synthesis step decides what surfaces. Cite `file:line` for each finding.

Then add one focus area per agent:

1. **Structural and architectural impact** (`subagent_type: "Explore"`) — Categorize changed files by type. Which modules are affected and how. Whether layers, boundaries, or data flows changed. Dependencies added or removed. Renames, moves, reorganizations. Whether the change is localized or spread out.

2. **Logic and behavior changes** (`subagent_type: "Explore"`) — What each change does and why it matters, traced end-to-end. New and removed behavior. Changes to public APIs, interfaces, and contracts. Changes to error handling, logging, and observability. Changes to configuration and defaults. Anything affecting backwards compatibility.

3. **Testing and quality changes** (`subagent_type: "Explore"`) — Test files added, modified, deleted, and what the new coverage validates. Implementation changes lacking corresponding test changes. Changes to fixtures, helpers, and test config. Any disabled, skipped, or weakened tests.

4. **Code quality review** (`subagent_type: "general-purpose"`, prompted as a code reviewer) — Style and naming consistency with the surrounding codebase. Error handling patterns. Duplication introduced or removed. Function complexity and nesting depth. Readability of the changes. AGENTS.md/CLAUDE.md compliance where those files exist. Whether complex changes are explained.

5. **Risk and impact** (`subagent_type: "general-purpose"`, prompted as a risk reviewer) — Security implications (attack surface, auth, input handling). Performance implications (algorithmic changes, new queries, resource usage). Breaking changes. Data migrations or schema changes needing coordination. Deployment-affecting config changes. External integration and API contract changes. Concurrency and race conditions. Unhandled error scenarios. Give each risk a severity.

## Step 3: Synthesize

Present the report directly in your response, not to a file:

```markdown
# Branch Comparison: [current branch] vs <OTHER_BRANCH>

## Overview
- **Current branch**: [name] ([N] ahead, [M] behind <OTHER_BRANCH>)
- **Files changed**: [count] | **Insertions**: [count] | **Deletions**: [count]

## Structural Changes

## Behavior Changes

## Testing Changes

## Code Quality Assessment

## Risk Assessment
[With severity per risk]

## Summary of Key Differences

## Recommendations
```

Rank findings by significance and lead each section with what matters most. Keep each section to a few paragraphs or a short table — the reader wants to know what changed and what to worry about, not to read the diff again in prose. Where an agent flagged a finding as uncertain, keep it and say it is uncertain. Where agents disagree, say so.
