<!-- ABOUTME: Command to review and synthesize accumulated learnings from long-horizon-impl workflows. -->
<!-- ABOUTME: Reads all learning files from the learnings directory and produces a structured synthesis. -->

---
description: Review and synthesize all accumulated learnings from long-horizon-impl workflows
model: opus
---

Review and synthesize all accumulated learnings from long-horizon-impl workflows by following these steps:

## Step 1: Locate Learnings Directory

Check for a `learnings_dir` override in `.claude/long-horizon-impl.local.md` (YAML frontmatter field). If found, use that path. If not found or the file does not exist, use the default: `~/.claude/plugin-learnings/long-horizon-impl/`.

## Step 2: Find Learning Files

Glob for all `*.md` files in the learnings directory.

If no files are found, report: "No learnings found in [directory]. Run a 1-research-and-plan or 2-implement workflow to accumulate learnings." Then exit.

## Step 3: Read All Learning Files

Read every `.md` file found. Note the filename (which typically encodes date and workflow run context) and full contents of each.

## Step 4: Synthesize

Produce a structured synthesis organized into the following sections. Use concrete examples from the learning files where possible. Avoid vague generalities.

### Recurring Patterns
What themes, observations, or outcomes appear across multiple workflow runs? What is consistently true regardless of topic or project?

### Strategy Effectiveness
Which of the 9 research strategies (web search, academic search, code search, expert opinion, adversarial search, trend analysis, comparative analysis, depth drill, gap identification) produced the most useful findings? Which tended to be redundant or low-yield? Are there patterns by topic type?

### Planning Phase Effectiveness
Which B-phases (B1 Requirements, B2 Architecture, B3 Test + Impl Plan, B4 Cross-Examination) produced the most actionable output? Where did planning tend to stall or produce weak results? Were the budget allocations (20%/30%/25%/25%) appropriate?

### Escalation Patterns
Which escalation types (plan mismatch, test evasion, scope creep, circular failure, ambiguous requirement, architecture conflict, human decision needed) occurred most frequently during 2-implement? What conditions tend to trigger each? How were they resolved?

### TDD Observations
What patterns emerged during 2-implement? Where did the TDD loop work well? Where did it break down or require human intervention?

### Cross-Phase Insights
Are there connections between Phase A research quality and B-phase planning quality? Are there connections between planning quality and 2-implement success?

### Plugin Improvement Suggestions

Group by priority:

**High priority** — improvements that would meaningfully change workflow outcomes
**Medium priority** — useful refinements that would reduce friction
**Low priority** — minor polish or nice-to-haves

### Workflow Design Insights
What does the accumulated evidence suggest about the overall workflow design? Are there structural changes to the phase sequence, budget allocation, or agent responsibilities that would improve outcomes?

## Step 5: Present to User

Present the full synthesis clearly. Include a header noting how many learning files were reviewed and the date range they cover (inferred from filenames or file metadata if available).
