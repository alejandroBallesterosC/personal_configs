---
description: Deep codebase exploration before planning
model: opus
---

# Codebase Exploration

You are exploring the codebase to gather context for implementing: **$ARGUMENTS**

## Your Mission

Use the `code-explorer` agent to perform deep codebase analysis before any planning begins. This follows Boris Cherny's practice of using multiple exploration sessions before making changes.

## Process

1. **Invoke the code-explorer agent** with the feature name to analyze:
   - Architecture and layer structure
   - Existing patterns and conventions
   - Related code that might inform implementation
   - Test patterns and coverage approach
   - Dependencies that will be affected

2. **Create feature context file** at `docs/context/$ARGUMENTS-exploration.md` with:
   - Relevant files and their purposes
   - Patterns to follow
   - Integration points
   - Potential conflicts or considerations

3. **Synthesize CLAUDE.md** if missing or outdated:
   - Check if `CLAUDE.md` exists at project root
   - If missing or lacking key information, create/update it with:
     - Project overview
     - Architecture description
     - Key patterns and conventions
     - Code style guidelines
     - Testing setup
     - Common commands
     - Key files

## Output Locations

- Feature context: `docs/context/$ARGUMENTS-exploration.md`
- Project memory: `CLAUDE.md` (if created/updated)

## Next Step

After exploration, proceed with:
```
/tdd-workflow:plan $ARGUMENTS
```
