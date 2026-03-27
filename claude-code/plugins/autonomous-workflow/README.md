# ABOUTME: Deprecation notice for the autonomous-workflow plugin (v4.0.0).
# ABOUTME: This plugin has been replaced by research-report and long-horizon-impl.

# autonomous-workflow (DEPRECATED)

**This plugin has been deprecated in v4.0.0 and replaced by two focused plugins:**

- **[research-report](../research-report/)** — Iterative deep research producing a LaTeX report with 9 strategies, methodological critique, and synthesis
- **[long-horizon-impl](../long-horizon-impl/)** — Research-driven planning (scoping interview + 4-artifact output) followed by TDD implementation with anti-slop escalation

## Migration

```bash
# Uninstall this plugin
/plugin uninstall autonomous-workflow

# Install replacements
/plugin install research-report      # if you used /autonomous-workflow:research
/plugin install long-horizon-impl    # if you used /autonomous-workflow:research-and-plan or /autonomous-workflow:implement
```

Run `/autonomous-workflow:help` for detailed migration instructions.
