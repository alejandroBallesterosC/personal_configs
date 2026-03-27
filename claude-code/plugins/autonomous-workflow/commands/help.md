# ABOUTME: Deprecation notice for the autonomous-workflow plugin.
# ABOUTME: Directs users to install research-report and/or long-horizon-impl instead.

---
description: "DEPRECATED — shows migration instructions to the replacement plugins"
model: haiku
---

# autonomous-workflow is deprecated (v4.0.0)

This plugin has been split into two focused plugins:

## Replacements

| Old | New | What it does |
|-----|-----|--------------|
| `/autonomous-workflow:research` | `/research-report:research` | Iterative deep research producing a LaTeX report with 9 strategies and synthesis |
| `/autonomous-workflow:research-and-plan` | `/long-horizon-impl:research-and-plan` | Research + scoping interview + 4-artifact planning (requirements, architecture, test plan, implementation plan) |
| `/autonomous-workflow:implement` | `/long-horizon-impl:implement` | TDD feature-by-feature implementation with anti-slop escalation, driven by ralph-loop |

## Migration steps

1. Uninstall this plugin:
   ```
   /plugin uninstall autonomous-workflow
   ```

2. Install the replacement(s) you need:
   ```
   /plugin install research-report
   /plugin install long-horizon-impl
   ```

3. Update any saved prompts or scripts that reference `/autonomous-workflow:` commands to use the new prefixes.

## What changed

- All workflow logic is preserved — strategies, phases, agents, hooks, anti-slop rules
- State file prefixes changed: `autonomous-*` is now `research-report-*` or `lhi-*`
- Artifact directories changed: `docs/autonomous/` is now `docs/research-report/` or `docs/long-horizon-impl/`
- Each plugin has its own learnings system (`/review-learnings` and `/record-feedback` commands)

## In-progress workflows

Any in-progress `autonomous-workflow` state files (`.claude/autonomous-*`) will NOT be recognized by the new plugins. Complete or discard existing workflows before migrating.
