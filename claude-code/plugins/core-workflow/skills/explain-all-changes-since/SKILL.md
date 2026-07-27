---
name: explain-all-changes-since
description: Summarize all changes pushed by collaborators across every remote branch since a given date/time. User-invoked only.
disable-model-invocation: true
argument-hint: <date-time> [timezone]
allowed-tools: Read, Grep, Glob, Bash, Agent
effort: xhigh
---

# Explain All Changes Since

Fetch every remote branch and synthesize what collaborators other than you have changed across all of them since a given date/time.

This is strictly read-only: no checkout, no merge, no push, no file edits, no commits.

## STEP 0: VALIDATE ARGUMENTS

The user's arguments are: **$ARGUMENTS**

- If no date/time was provided, respond with "Usage: /core-workflow:explain-all-changes-since <date-time> [timezone]  You must specify a cutoff date/time." and stop.
- If a timezone was provided, use it. If none was provided, **assume Eastern Time (America/New_York)** — use the IANA timezone name (not a fixed UTC offset) so daylight saving is handled automatically.
- Confirm a remote is configured: `git remote -v`. If empty, respond with "No git remote is configured for this repository." and stop.

## STEP 1: FETCH AND IDENTIFY THE USER

Run in parallel:

1. `git fetch --all --prune`
2. `git config user.email` and `git config user.name` (to exclude the user's own commits later)
3. `git for-each-ref --format='%(refname:short)' refs/remotes | grep -v '/HEAD$'` (list every remote branch)

## STEP 2: COLLECT QUALIFYING COMMITS PER REMOTE BRANCH

For each remote branch found in Step 1, list commits since the cutoff, using the resolved IANA timezone so the date is interpreted correctly regardless of daylight saving:

```bash
TZ="<IANA timezone, e.g. America/New_York>" git log <remote-branch> --since="<date-time>" \
  --pretty=format:'%H%x09%an%x09%ae%x09%aI%x09%s'
```

From the results, **exclude any commit whose author name or email matches the current user** (from Step 1). What remains are candidate commits from other collaborators.

Group the remaining commits by branch. If a branch has zero qualifying commits, drop it from further analysis. If NO branch has any qualifying commits, report "No changes found on any remote branch since <date-time> by collaborators other than you." and stop.

## STEP 3: GET THE ACTUAL DIFFS

For each branch with qualifying commits, get the diff covering just those commits (not the whole branch history) — e.g. diff from the parent of the oldest qualifying commit to the branch tip, or `git show` per commit if the branch has only a few commits:

```bash
git diff <oldest-qualifying-commit>^..<remote-branch>
```

## STEP 4: LAUNCH PARALLEL SUMMARIZATION AGENTS

The user invoked this skill to get a parallel sweep, so delegate rather than reading every branch serially. Launch one `subagent_type: "Explore"` agent per branch with qualifying commits, all in a single message — the branch count sets the agent count. If a great many branches qualify, batch several small ones per agent rather than spawning an agent per trivial branch.

Give each agent:

```
You are summarizing commits pushed to a remote git branch by collaborators (not the repository's current user).

Branch: <branch name>
Commits (hash, author, date, subject):
[insert the filtered commit list for this branch from Step 2]

Diff:
[insert the diff for this branch from Step 3]

Report:
1. What changed at a high level — features, fixes, refactors, config and infra changes.
2. For each distinct piece of work (grouped by author or by logical change, whichever is clearer), what changed and why it matters.
3. Anything risky, breaking, or worth the repo owner's attention: schema changes, new dependencies, security-relevant changes, config changes.
4. Which author made each change.

Cite `file:line`. Do not speculate beyond what the diff and commit messages show; where intent is unclear, say the intent is unclear rather than guessing at it. This is read-only — do not edit any files.
```

## STEP 5: SYNTHESIZE

Combine all agents' reports into one response to the user:

```markdown
# Remote Changes Since <date-time> <timezone>

## Overview
- Branches with new commits from collaborators: [list]
- Total qualifying commits: [count]
- Collaborators involved: [list of authors]

## By Branch

### <branch name>
**Author(s)**: [list]
**Summary**: [synthesized from that branch's agent]
**Noteworthy/risky changes**: [if any]

(repeat per branch)

## Cross-Branch Observations
[Patterns across branches — multiple branches touching the same area, coordinated work, conflicting approaches]
```

Keep each branch's entry to a short paragraph plus its noteworthy changes. The reader wants to know what moved while they were away and what affects their own work, so lead with that rather than an exhaustive per-commit account.

## Notes

- If a branch's diff is very large, say it was summarized rather than analyzed line by line.
- If a commit's author name or email does not clearly match or exclude the current user (for example the user has multiple emails), include it and note the ambiguity rather than dropping it silently.
