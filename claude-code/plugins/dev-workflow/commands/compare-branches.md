---
description: Compare current git branch to another branch using parallel subagents for detailed analysis
model: opus
argument-hint: <target-branch>
---

# Branch Comparison

**Current branch**: (detected automatically)
**Target branch**: $1

## Objective

Compare the current git branch against `$1` using **parallel subagents** to produce a thorough, multi-angle analysis of all differences between the two branches.

---

## STEP 1: GATHER GIT CONTEXT

Before spawning agents, collect the raw data they'll need.

Run these **3 Bash commands in parallel**:

1. **Detect current branch and merge base**:
   ```bash
   echo "CURRENT_BRANCH: $(git rev-parse --abbrev-ref HEAD)" && echo "MERGE_BASE: $(git merge-base HEAD $1)" && echo "COMMITS_AHEAD: $(git rev-list --count $1..HEAD)" && echo "COMMITS_BEHIND: $(git rev-list --count HEAD..$1)"
   ```

2. **Get diff stats (file-level summary)**:
   ```bash
   git diff --stat $1...HEAD
   ```

3. **Get list of changed files with status**:
   ```bash
   git diff --name-status $1...HEAD
   ```

Capture all outputs. You will pass this context to every agent below.

---

## STEP 2: GET THE FULL DIFF

Run this Bash command to get the full diff content:

```bash
git diff $1...HEAD
```

Store the full diff output — you will include it in each agent prompt so they can analyze the actual code changes.

---

## STEP 3: LAUNCH 5 PARALLEL ANALYSIS AGENTS

Launch all 5 agents **IN PARALLEL** using a single message with 5 Task tool calls.

Pass each agent the **git context from Step 1**, the **full diff from Step 2**, and its specific focus instructions.

### Agent 1: Structural & Architectural Impact (code-explorer)

`subagent_type: "dev-workflow:code-explorer"`

```
EXPLORATION FOCUS: Structural & Architectural Impact of Branch Differences

You are comparing two git branches. Analyze the structural and architectural differences.

Current branch: [insert current branch]
Target branch: $1
Commits ahead: [insert]
Commits behind: [insert]

CHANGED FILES:
[insert name-status output from Step 1]

DIFF STATS:
[insert stat output from Step 1]

FULL DIFF:
[insert full diff from Step 2]

Your analysis tasks:
1. Categorize all changed files by type (source, test, config, docs, build, etc.)
2. Identify which modules/components are affected and how
3. Assess architectural impact — are layers, boundaries, or data flows changed?
4. Flag any new dependencies introduced or removed
5. Identify file renames, moves, or reorganizations
6. Map which parts of the codebase are touched vs untouched
7. Assess whether changes are localized or spread across the codebase

Produce a structured report on the structural and architectural differences.
```

### Agent 2: Logic & Behavior Changes (code-explorer)

`subagent_type: "dev-workflow:code-explorer"`

```
EXPLORATION FOCUS: Logic & Behavior Changes Between Branches

You are comparing two git branches. Analyze what the code changes actually DO.

Current branch: [insert current branch]
Target branch: $1

CHANGED FILES:
[insert name-status output from Step 1]

FULL DIFF:
[insert full diff from Step 2]

Your analysis tasks:
1. For each changed file, explain WHAT changed and WHY it matters
2. Trace behavior changes end-to-end (e.g., "this endpoint now validates X before Y")
3. Identify new features, capabilities, or behaviors introduced
4. Identify removed features or deprecated behaviors
5. Document changes to public APIs, interfaces, or contracts
6. Flag any changes to error handling, logging, or observability
7. Note changes to configuration, environment variables, or defaults
8. Identify any changes that could affect backwards compatibility

Produce a structured report explaining the functional and behavioral differences in plain language.
```

### Agent 3: Testing & Quality Changes (code-explorer)

`subagent_type: "dev-workflow:code-explorer"`

```
EXPLORATION FOCUS: Testing & Quality Impact of Branch Differences

You are comparing two git branches. Analyze the testing and quality aspects of the differences.

Current branch: [insert current branch]
Target branch: $1

CHANGED FILES:
[insert name-status output from Step 1]

FULL DIFF:
[insert full diff from Step 2]

Your analysis tasks:
1. Identify all test file changes (added, modified, deleted)
2. Analyze what new test coverage was added and what it validates
3. Check if implementation changes have corresponding test changes
4. Identify any test gaps — code changes without matching test updates
5. Note changes to test infrastructure (fixtures, helpers, config)
6. Assess whether test naming and organization follows existing conventions
7. Flag any disabled, skipped, or weakened tests

Produce a structured report on how testing and quality assurance differ between branches.
```

### Agent 4: Code Quality Review (code-reviewer)

`subagent_type: "dev-workflow:code-reviewer"`

```
REVIEW FOCUS: Code Quality of Branch Differences

You are reviewing the differences between two git branches. Assess the quality of the changes.

Current branch: [insert current branch]
Target branch: $1

CHANGED FILES:
[insert name-status output from Step 1]

FULL DIFF:
[insert full diff from Step 2]

Review the diff for:
1. Code style consistency with the rest of the codebase
2. Naming conventions adherence
3. Error handling patterns (proper vs missing vs inconsistent)
4. Code duplication introduced or eliminated
5. Function/method complexity (long functions, deep nesting)
6. Readability and maintainability of the changes
7. CLAUDE.md compliance (if present)
8. Comment quality — are complex changes explained?

Produce a confidence-scored review (only findings ≥80% confidence) of the code quality in the branch differences.
```

### Agent 5: Risk & Impact Assessment (code-reviewer)

`subagent_type: "dev-workflow:code-reviewer"`

```
REVIEW FOCUS: Risk & Impact Assessment of Branch Differences

You are reviewing the differences between two git branches. Assess risks and potential impact.

Current branch: [insert current branch]
Target branch: $1

CHANGED FILES:
[insert name-status output from Step 1]

FULL DIFF:
[insert full diff from Step 2]

Assess the changes for:
1. Security implications (new attack surfaces, auth changes, input handling)
2. Performance implications (algorithmic changes, new queries, resource usage)
3. Breaking changes that could affect other parts of the system
4. Data migration or schema changes that need coordination
5. Configuration changes that could affect deployment
6. External service integration changes (API contracts, endpoints)
7. Concurrency or race condition risks
8. Error scenarios that may not be handled

Produce a confidence-scored risk assessment (only findings ≥80% confidence) with severity ratings and mitigation recommendations.
```

---

## STEP 4: SYNTHESIZE

After all 5 agents complete, synthesize their findings into a comprehensive comparison report.

Present the report directly to the user (do NOT write to a file unless asked):

```markdown
# Branch Comparison: [current branch] vs $1

## Overview
- **Current branch**: [name] ([N] commits ahead, [M] commits behind $1)
- **Target branch**: $1
- **Files changed**: [count]
- **Insertions**: [count] | **Deletions**: [count]

---

## Structural Changes
[Synthesized from Agent 1 — what files/modules changed and how]

## Behavior Changes
[Synthesized from Agent 2 — what the changes DO, explained clearly]

## Testing Changes
[Synthesized from Agent 3 — test coverage, gaps, quality]

## Code Quality Assessment
[Synthesized from Agent 4 — quality findings ≥80% confidence]

## Risk Assessment
[Synthesized from Agent 5 — risks ≥80% confidence with severity]

---

## Summary of Key Differences
[Bullet-point summary of the most important differences]

## Recommendations
[Actionable recommendations based on findings]
```

---

## IMPORTANT NOTES

- All agents receive the **full diff** so they can analyze actual code, not just file names
- Agents use **read-only tools** (no file modifications)
- The three-dot diff (`$1...HEAD`) shows changes since the branches diverged, not the total difference
- If the diff is extremely large, summarize the most impactful changes and note that the full diff was truncated
- If $1 does not exist as a branch, report the error clearly and suggest checking branch names with `git branch -a`
