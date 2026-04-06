# ABOUTME: Command for the user to manually record feedback about a dev-workflow TDD or debug session.
# ABOUTME: Writes user feedback as an independent learning entry with artifact metrics for factual context.

---
description: "Record user feedback about a completed dev-workflow session — writes to the learnings directory with artifact metrics for context"
model: opus
argument-hint: <workflow-name> ["Your feedback here..."]
---

## Record Feedback for a Dev Workflow Session

You are recording the user's feedback about the final output of a dev-workflow session. The feedback is written as an independent data point in the learnings directory. Do NOT read or cross-reference other learnings — each entry should stand alone. The `/dev-workflow:review-learnings` command is where all learnings get synthesized together.

### Arguments

- `$1` — workflow name (required). Used to locate artifacts at `docs/workflow-$1/` (TDD) or `docs/debug/$1/` (debug).
- `$2` — user feedback (optional). If not provided, ask the user using AskUserQuestion.

### Step 1: Detect Workflow Type and Locate Artifacts

Check which artifacts exist for this workflow:

**TDD artifacts** (at `docs/workflow-$1/`):
- `docs/workflow-$1/$1-state.md`
- `docs/workflow-$1/$1-original-prompt.md`
- `docs/workflow-$1/codebase-context/$1-exploration.md`
- `docs/workflow-$1/specs/$1-specs.md`
- `docs/workflow-$1/plans/$1-architecture-plan.md`
- `docs/workflow-$1/plans/$1-implementation-plan.md`
- `docs/workflow-$1/plans/$1-tests.md`
- `docs/workflow-$1/$1-review.md`

**Debug artifacts** (at `docs/debug/$1/`):
- `docs/debug/$1/$1-state.md`
- `docs/debug/$1/$1-bug.md`
- `docs/debug/$1/$1-exploration.md`
- `docs/debug/$1/$1-hypotheses.md`
- `docs/debug/$1/$1-analysis.md`
- `docs/debug/$1/$1-resolution.md`

Also check archived paths:
- `docs/archive/workflow-$1/` (TDD)
- `docs/archive/debug-$1/` (debug)

If no artifacts found at any path, tell the user no artifacts were found for workflow `$1` and ask them to verify the name.

Determine the workflow type (TDD or debug) based on which artifacts exist.

### Step 2: Collect Feedback

If `$2` was provided, use it as the user's feedback.

If `$2` was NOT provided, ask the user. Tailor the prompt based on workflow type:

**If TDD workflow:**
> What feedback do you have about the TDD workflow for "$1"? You can comment on:
> - Quality of the codebase exploration and specification interview
> - Whether the architecture and implementation plans were sound
> - Code quality and test coverage of the implementation
> - Whether the review phase caught real issues
> - Visual quality of any UI changes (if applicable)
> - Overall: did the final product match your intent?

**If debug workflow:**
> What feedback do you have about the debug session for "$1"? You can comment on:
> - Whether the initial hypotheses were on the right track
> - Whether instrumentation was effective at gathering evidence
> - How many fix attempts it took and whether they addressed root cause
> - Whether the regression test covers the actual bug
> - Overall: was the bug correctly identified and fixed?

### Step 3: Read Artifacts for Factual Context

Read available artifacts to extract factual metrics (counts, distributions — not causal explanations):

**TDD metrics** (if applicable):
- Read `$1-state.md` for phase progression and status
- Skim `$1-specs.md` for requirement count
- Skim `$1-architecture-plan.md` for component count
- Skim `$1-implementation-plan.md` for planned components
- Skim `$1-tests.md` for test case count
- Read `$1-review.md` for review finding counts by category and confidence

**Debug metrics** (if applicable):
- Read `$1-state.md` for phase progression and status
- Read `$1-hypotheses.md` for hypothesis count and which were confirmed/rejected
- Read `$1-analysis.md` for analysis outcome
- Read `$1-resolution.md` for fix description and verification result

### Step 4: Write Learning Entry

Resolve the learnings directory:
1. Check if `.plugin-state/dev-workflow.local.md` exists and has a `learnings_dir` field in YAML frontmatter
2. If not, use `~/.claude/plugin-learnings/dev-workflow/`
3. Create the directory with `mkdir -p` if it doesn't exist

Write the learning file as `YYYY-MM-DD-$1-user-feedback.md` (use today's date). If a file with that name already exists, append a counter: `YYYY-MM-DD-$1-user-feedback-2.md`.

```markdown
---
type: feedback
plugin: dev-workflow
workflow_type: <tdd | debug>
workflow_topic: <$1>
date: <today's date>
phases_completed: [<list of phases that had artifacts>]
---

## User Feedback

<The user's original feedback, quoted verbatim>

## Artifact Metrics

<Factual metrics only — what the artifacts show, without causal interpretation:>

### TDD Metrics (if applicable)
- **Requirements specified**: <count>
- **Components planned**: <count>
- **Test cases planned**: <count>
- **Review findings**: <count by category — security, performance, quality, test coverage>
- **Review confidence**: <distribution of confidence levels>

### Debug Metrics (if applicable)
- **Hypotheses generated**: <count>
- **Hypotheses confirmed**: <count>
- **Hypotheses rejected**: <count>
- **Fix attempts**: <count>
- **Root cause identified**: <yes/no>

## Possible Connections (Hypotheses)

IMPORTANT: You are offering tentative hypotheses, not conclusions. Artifact metrics show WHAT was produced but not WHY. The user's direct experience of the final product is more authoritative than any inference you make from metrics.

<For each piece of user feedback, note any artifact metrics that MIGHT be relevant. Use language like:
- "This might be related to..." / "One possible factor is..."
- "The artifacts show X, which could partially explain..."
- "Worth investigating whether..."

Do NOT write confident causal claims like "This happened because..." or "The root cause is..."

If you cannot see a plausible connection between the feedback and the metrics, say so: "I don't see an obvious connection in the artifact metrics — the user's direct experience is more informative here."

Keep this section brief.>

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
