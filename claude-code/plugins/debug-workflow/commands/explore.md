---
description: Explore codebase to understand systems relevant to a bug
model: opus
argument-hint: <area or bug description>
---

# Debug Exploration

Exploring codebase for: **$ARGUMENTS**

## Purpose

Before debugging, understand the relevant systems. This exploration phase prevents wasted effort from incorrect assumptions about code behavior.

## Exploration Tasks

Use the debug-explorer agent to investigate:

### 1. File Discovery

Find all files potentially related to the bug:

```
- Entry points (routes, handlers, CLI commands)
- Core logic (services, models, utilities)
- Configuration (env, config files, constants)
- Tests (existing test coverage for this area)
```

### 2. Execution Flow Mapping

Trace the code path from trigger to failure:

```
- Where does user input enter the system?
- What functions process the data?
- Where are external calls made?
- Where could failures occur?
```

### 3. Dependency Analysis

Understand what this code depends on:

```
- Internal modules imported
- External libraries used
- Database/API interactions
- Shared state or globals
```

### 4. Recent Changes

Check git history for potential regression:

```bash
# Recent commits to relevant files
git log --oneline -20 -- <relevant-paths>

# What changed in the last week
git diff HEAD~7 -- <relevant-paths>

# Who touched these files recently
git log --format='%an' -- <relevant-paths> | sort | uniq -c | sort -rn
```

### 5. Test Coverage

Understand existing test coverage:

```
- What tests exist for this area?
- What scenarios are covered?
- What's NOT tested?
```

## Output

Write exploration findings to: `docs/debug/$ARGUMENTS-exploration.md`

```markdown
# Exploration: [area]

## Relevant Files

| File | Purpose | Risk Level |
|------|---------|------------|
| `path/to/file.py` | [what it does] | High/Medium/Low |

## Execution Flow

```
[entry point] → [function] → [function] → [potential failure]
```

## Dependencies

- **Internal**: [list]
- **External**: [list]
- **State**: [shared state accessed]

## Recent Changes

[summary of git history]

## Test Coverage

- **Covered**: [scenarios]
- **Gaps**: [missing tests]

## Initial Observations

[anything suspicious or noteworthy]
```

## Next Steps

After exploration, proceed to:
```
/debug-workflow:debug <bug description>
```

Or if you already have hypotheses:
```
/debug-workflow:hypothesize
```
