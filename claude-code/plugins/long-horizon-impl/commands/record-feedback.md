# ABOUTME: Command for the user to manually record feedback about a long-horizon-impl workflow's final output.
# ABOUTME: Writes user feedback as an independent learning entry with artifact metrics for factual context.

---
description: "Record user feedback about a completed long-horizon-impl workflow — writes to the learnings directory with artifact metrics for context"
model: opus
argument-hint: <project-name> ["Your feedback here..."]
---

## Record Feedback for a Long-Horizon Implementation Workflow

You are recording the user's feedback about the final output of a long-horizon-impl workflow. The feedback is written as an independent data point in the learnings directory. Do NOT read or cross-reference other learnings — each entry should stand alone. The `/review-learnings` command is where all learnings get synthesized together.

### Arguments

- `$1` — project name (required). Used to locate artifacts at `docs/long-horizon-impl/$1/`.
- `$2` — user feedback (optional). If not provided, ask the user using AskUserQuestion.

### Step 1: Locate Artifacts

Check which artifacts exist for this project:

**Research artifacts** (from Phase A):
- `docs/long-horizon-impl/$1/research/$1-report.tex`
- `docs/long-horizon-impl/$1/research/research-progress.md`
- `docs/long-horizon-impl/$1/research/sources.bib`

**Planning artifacts** (from Phase B):
- `docs/long-horizon-impl/$1/planning/$1-functional-requirements.md`
- `docs/long-horizon-impl/$1/planning/$1-architecture-plan.md`
- `docs/long-horizon-impl/$1/planning/$1-test-plan.md`
- `docs/long-horizon-impl/$1/planning/$1-implementation-plan.md`
- `docs/long-horizon-impl/$1/planning/cross-examination-log.md`

**Implementation artifacts** (from 2-implement):
- `.claude/lhi-$1-feature-list.json`
- `.claude/lhi-$1-escalations.json`
- `docs/long-horizon-impl/$1/implementation/progress.txt`

If the project directory does not exist, tell the user no artifacts were found for project `$1` and ask them to verify the project name.

Determine which phases were completed based on which artifacts exist.

### Step 2: Collect Feedback

If `$2` was provided, use it as the user's feedback.

If `$2` was NOT provided, ask the user. Tailor the prompt based on which phases completed:

**If planning artifacts exist (1-research-and-plan was run):**
> What feedback do you have about the planning output for "$1"? You can comment on:
> - Quality of the research phase and how well it informed planning
> - Whether the scoping questions (B0) captured the right concerns
> - Quality of the 4 planning artifacts (requirements, architecture, test plan, implementation plan)
> - Whether the cross-examination (B4) caught real issues or was excessive
> - Any requirements that were missed or over-specified
> - How well the plan would translate to actual implementation

**If implementation artifacts exist (2-implement was run):**
> What feedback do you have about the implementation for "$1"? You can comment on:
> - Code quality and adherence to the plan
> - Whether escalations were appropriate or too aggressive/too lenient
> - Test quality — did the TDD cycle produce meaningful tests?
> - Features that worked well vs. features that needed rework
> - Whether blocked features had realistic unblock paths
> - Overall: did the final product match your intent?

**If both exist:**
> What feedback do you have about the full workflow for "$1" (research, planning, and implementation)? You can comment on any phase.

### Step 3: Read Artifacts for Factual Context

Read available artifacts to extract factual metrics (counts, distributions — not causal explanations):

**From research** (if exists):
- Skim `$1-report.tex` for section structure and source count
- Read `research-progress.md` for strategy history and quality metrics

**From planning** (if exists):
- Read `$1-functional-requirements.md` — count requirements, note MUST/SHOULD/COULD distribution
- Skim `$1-architecture-plan.md` — note component count and technology choices
- Skim `$1-test-plan.md` — count test cases
- Skim `$1-implementation-plan.md` — count features, note build order
- Read `cross-examination-log.md` if it exists — count BLOCKERs, CONCERNs, SUGGESTIONs

**From implementation** (if exists):
- Read `.claude/lhi-$1-feature-list.json` — count passed/failed/blocked features
- Read `.claude/lhi-$1-escalations.json` — count and categorize escalations by type
- Skim `progress.txt` for implementation timeline

### Step 4: Write Learning Entry

Resolve the learnings directory:
1. Check if `.claude/long-horizon-impl.local.md` exists and has a `learnings_dir` field in YAML frontmatter
2. If not, use `~/.claude/plugin-learnings/long-horizon-impl/`
3. Create the directory with `mkdir -p` if it doesn't exist

Write the learning file as `YYYY-MM-DD-$1-user-feedback.md` (use today's date). If a file with that name already exists, append a counter: `YYYY-MM-DD-$1-user-feedback-2.md`.

```markdown
---
type: feedback
plugin: long-horizon-impl
workflow_topic: <$1>
date: <today's date>
phases_completed: [<list of phases that had artifacts>]
features_passed: <count or N/A>
features_failed: <count or N/A>
features_blocked: <count or N/A>
escalation_count: <count or N/A>
requirements_count: <count or N/A>
---

## User Feedback

<The user's original feedback, quoted verbatim>

## Artifact Metrics

<Factual metrics only — what the artifacts show, without causal interpretation:>

### Research Phase (if applicable)
- **Sources cited**: <count>
- **Evidence quality**: <TIGHT: N, MODERATE: N, WIDE: N>
- **Strategies used**: <list with iteration counts>

### Planning Phase (if applicable)
- **Requirements**: <total count> (MUST: N, SHOULD: N, COULD: N)
- **Architecture components**: <count>
- **Test cases planned**: <count>
- **Features planned**: <count>
- **Cross-examination issues**: BLOCKER: N, CONCERN: N, SUGGESTION: N

### Implementation Phase (if applicable)
- **Features passed**: <N>/<total>
- **Features failed**: <N> — <brief reasons>
- **Features blocked**: <N> — <brief reasons>
- **Escalation types**: <breakdown by type>

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
