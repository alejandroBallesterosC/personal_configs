<!-- ABOUTME: Command to review and synthesize accumulated learnings from dev-workflow TDD and debug sessions. -->
<!-- ABOUTME: Reads all learning files from the learnings directory and produces a structured synthesis. -->

---
description: Review and synthesize all accumulated learnings from dev-workflow TDD and debug sessions
model: opus
---

Review and synthesize all accumulated learnings from dev-workflow workflows by following these steps:

## Step 1: Locate Learnings Directory

Check for a `learnings_dir` override in `.plugin-state/dev-workflow.local.md` (YAML frontmatter field). If found, use that path. If not found or the file does not exist, use the default: `~/.claude/plugin-learnings/dev-workflow/`.

## Step 2: Find Learning Files

Glob for all `*.md` files in the learnings directory.

If no files are found, report: "No learnings found in [directory]. Complete a TDD or debug workflow to accumulate learnings, or use `/dev-workflow:record-feedback` to record manual feedback." Then exit.

## Step 3: Read All Learning Files

Read every `.md` file found. Note the filename (which encodes date, topic, and type) and full contents of each.

## Step 4: Synthesize

Produce a structured synthesis organized into the following sections. Use concrete examples from the learning files where possible. Avoid vague generalities.

### Recurring Patterns
What themes, observations, or outcomes appear across multiple workflow runs? What is consistently true regardless of feature or bug?

### TDD Workflow Observations
Which phases produce friction? Common requirement gaps, architecture decision patterns, implementation surprises, plan-vs-reality mismatches. Where does the TDD cycle work well and where does it break down?

### Debug Workflow Observations
Common bug categories, hypothesis accuracy rates, fix attempt patterns, instrumentation effectiveness. Where does the debug workflow accelerate resolution and where does it add overhead?

### Code Review Trends
Recurring issue categories across reviews — security, performance, quality, test coverage. Which review focus areas consistently surface findings vs. which are usually clean?

### Visual Verification Insights
Common UI/frontend issues caught by playwright-cli screenshots during implementation or E2E testing, if applicable. Skip this section if no visual verification learnings exist.

### Plugin Improvement Suggestions

Group by priority:

**High priority** — improvements that would meaningfully change workflow outcomes
**Medium priority** — useful refinements that would reduce friction
**Low priority** — minor polish or nice-to-haves

### Workflow Design Insights
What does the accumulated evidence suggest about the overall workflow design? Are there structural changes to the phase sequence, agent effectiveness, parallelization strategy, or budget allocation that would improve outcomes?

## Step 5: Present to User

Present the full synthesis clearly. Include a header noting how many learning files were reviewed and the date range they cover (inferred from filenames or file metadata if available).
