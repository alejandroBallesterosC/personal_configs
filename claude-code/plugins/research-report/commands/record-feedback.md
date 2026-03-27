# ABOUTME: Command for the user to manually record feedback about a research report's final output.
# ABOUTME: Writes user feedback as an independent learning entry with artifact metrics for factual context.

---
description: "Record user feedback about a completed research report — writes to the learnings directory with artifact metrics for context"
model: opus
argument-hint: <topic-name> ["Your feedback here..."]
---

## Record Feedback for a Research Report

You are recording the user's feedback about the final output of a research-report workflow. The feedback is written as an independent data point in the learnings directory. Do NOT read or cross-reference other learnings — each entry should stand alone. The `/review-learnings` command is where all learnings get synthesized together.

### Arguments

- `$1` — topic name (required). Used to locate artifacts at `docs/research-report/$1/`.
- `$2` — user feedback (optional). If not provided, ask the user using AskUserQuestion.

### Step 1: Locate Artifacts

Check if the research report artifacts exist:
- `docs/research-report/$1/$1-report.tex` (the main report)
- `docs/research-report/$1/research-progress.md` (progress log)
- `docs/research-report/$1/sources.bib` (bibliography)

If the report directory does not exist, tell the user no artifacts were found for topic `$1` and ask them to verify the topic name.

### Step 2: Collect Feedback

If `$2` was provided, use it as the user's feedback.

If `$2` was NOT provided, ask the user:

> What feedback do you have about the research report for "$1"? You can comment on:
> - Overall quality and usefulness of the report
> - Whether it addressed your original research intent
> - Sections that were strong or weak
> - Source quality and citation issues
> - Anything that surprised you (positively or negatively)
> - Suggestions for how the workflow could produce better results

### Step 3: Read Artifacts for Factual Context

Read the following files to extract factual metrics (counts, distributions — not causal explanations):
1. `docs/research-report/$1/$1-report.tex` — section structure, source count
2. `docs/research-report/$1/research-progress.md` — strategy history, methodological quality counters

Extract:
- Which research strategies were used and how many iterations each
- How many sources were cited
- The methodological quality breakdown (TIGHT/MODERATE/WIDE evidence gaps)
- Whether any strategies were rotated due to low contributions
- The key themes/findings covered

### Step 4: Write Learning Entry

Resolve the learnings directory:
1. Check if `.claude/research-report.local.md` exists and has a `learnings_dir` field in YAML frontmatter
2. If not, use `~/.claude/plugin-learnings/research-report/`
3. Create the directory with `mkdir -p` if it doesn't exist

Write the learning file as `YYYY-MM-DD-$1-user-feedback.md` (use today's date). If a file with that name already exists, append a counter: `YYYY-MM-DD-$1-user-feedback-2.md`.

```markdown
---
type: feedback
plugin: research-report
workflow_topic: <$1>
date: <today's date>
sources_cited: <count from artifacts>
iterations_run: <from progress log>
strategies_used: <list from progress log>
---

## User Feedback

<The user's original feedback, quoted verbatim>

## Artifact Metrics

<Factual metrics only — what the artifacts show, without causal interpretation:>

- **Report sections**: <list of major sections in the report>
- **Sources cited**: <count>
- **Evidence quality**: <TIGHT: N, MODERATE: N, WIDE: N from methodological quality>
- **Strategies used**: <list with iteration counts>
- **Low-contribution rotations**: <count and which strategies>

## Possible Connections (Hypotheses)

IMPORTANT: You are offering tentative hypotheses, not conclusions. Artifact metrics show WHAT was produced but not WHY. The user's direct experience of the final product is more authoritative than any inference you make from metrics.

<For each piece of user feedback, note any artifact metrics that MIGHT be relevant. Use language like:
- "This might be related to..." / "One possible factor is..."
- "The artifacts show X, which could partially explain..."
- "Worth investigating whether..."

Do NOT write confident causal claims like "This happened because..." or "The root cause is..."

If you cannot see a plausible connection between the feedback and the metrics, say so: "I don't see an obvious connection in the artifact metrics — the user's direct experience is more informative here."

Keep this section brief. The purpose is to annotate the user's feedback with potentially relevant data points, not to diagnose root causes.>

## Suggested Improvements (Hypotheses)

<List 2-5 potential improvements. Frame as hypotheses for the user to evaluate, not prescriptions:
- What the user reported
- What the artifacts show (if relevant)
- A tentative suggestion for what might help
- What you're uncertain about

The user will evaluate these with context you lack. Surface possibilities, not diagnoses.>
```

### Step 5: Confirm

Tell the user the feedback has been recorded and where the file was saved.
