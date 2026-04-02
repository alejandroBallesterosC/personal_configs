<!-- ABOUTME: Command to review and synthesize all accumulated learnings from research-report workflows. -->
<!-- ABOUTME: Reads learnings directory, identifies patterns, and presents prioritized improvement suggestions. -->

---
description: Review and synthesize all accumulated learnings from research-report workflows
model: opus
---

Follow these steps to review and synthesize all accumulated learnings from past research-report sessions.

## Step 1 — Determine learnings directory

Check for a per-project override by looking for `.plugin-state/research-report.local.md` in the current working directory. If the file exists, read its YAML frontmatter and extract the `learnings_dir` field.

If no override is found, use the default directory: `~/.claude/plugin-learnings/research-report/`

## Step 2 — Find all learning files

Use the Glob tool to find all `*.md` files in the learnings directory.

If no files are found, report to the user that no learnings have been accumulated yet for the research-report plugin and exit.

## Step 3 — Read all learning files

Read each learning file found in Step 2.

## Step 4 — Synthesize and present

Synthesize the content of all learning files and present a structured report with the following sections:

### Recurring Patterns
Themes, topics, or behaviors that appear across multiple sessions. Include frequency counts where patterns are clearly repeated.

### Strategy Effectiveness
Which of the 9 research strategies (broad survey, deep dive, contrarian, source triangulation, temporal, practitioner, academic, gap analysis, quantitative) produced the highest-quality findings across sessions. Note any strategies that consistently underperformed.

### Source Quality Trends
Domains, publication types, or source categories that consistently provided high-credibility findings. Note any source types that were unreliable.

### Plugin Improvement Suggestions
Concrete suggestions for improving future research sessions, grouped by priority:
- **High priority** — changes that would significantly improve research quality or efficiency
- **Medium priority** — useful improvements worth implementing when convenient
- **Low priority** — minor refinements

Include frequency counts for suggestions that appear across multiple sessions.

### Workflow Design Insights
Observations about how the Phase R / Phase S structure, iteration budgets, or agent behaviors could be tuned for different research domains or question types.
