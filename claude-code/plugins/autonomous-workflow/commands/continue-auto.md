---
description: "Resume an interrupted autonomous workflow from saved state"
model: opus
argument-hint: "[topic-name]"
---

# ABOUTME: Resume command that detects active autonomous workflows and continues from saved state.
# ABOUTME: Reads strategy and budget fields from state, compiles LaTeX for progress check, then dispatches.

# Continue Autonomous Workflow

**Topic** (optional): $1

## Objective

Detect and resume an active autonomous workflow. Compiles any existing LaTeX documents to PDF first (so you can check progress), then continues from the current phase.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Find Active Workflow

### If topic name provided ($1 is not empty):

Look for `docs/autonomous/$1/implementation/$1-state.md` first, then `docs/autonomous/$1/research/$1-state.md`. If neither found, output error:
```
ERROR: No workflow found for '$1'.
Searched:
- docs/autonomous/$1/implementation/$1-state.md
- docs/autonomous/$1/research/$1-state.md

Available workflow directories:
[list contents of docs/autonomous/*/]
```

### If no topic name provided:

Scan `docs/autonomous/*/implementation/*-state.md` and `docs/autonomous/*/research/*-state.md` for files with `status: in_progress` in YAML frontmatter.

Read each candidate state file's YAML frontmatter (between `---` delimiters) and check the `status` field.

- If exactly ONE active workflow found: use it
- If MULTIPLE active workflows found: list them and ask which to resume using AskUserQuestion
- If NONE found: output error:
  ```
  ERROR: No active autonomous workflows found.

  Start a new workflow with:
  - /autonomous-workflow:research 'topic' 'prompt'
  - /autonomous-workflow:research-and-plan 'project' 'prompt'
  - /autonomous-workflow:full-auto 'project' 'prompt'
  - /autonomous-workflow:implement 'project'
  ```

---

## STEP 2: Read State

Read the state file and extract:
- `workflow_type` — determines which mode logic to use
- `current_phase` — determines which phase to resume
- `name` — the topic/project name
- `current_research_strategy` — active research strategy (for research phases)
- `research_budget` — research iteration budget (Modes 2/3)
- `planning_budget` — planning iteration budget (Mode 3)
- All other YAML fields for context

Read the corresponding documents:
- Always read: `docs/autonomous/<name>/research/<name>-report.tex` (if exists)
- If modes 2+3+4: read `docs/autonomous/<name>/implementation/<name>-implementation-plan.md` (if exists)
- If modes 3+4: read `docs/autonomous/<name>/implementation/feature-list.json` and `docs/autonomous/<name>/implementation/progress.txt` (if they exist)

---

## STEP 3: Compile LaTeX (Progress Check)

Spawn `autonomous-workflow:latex-compiler` agent for the research report:

```
Task tool with subagent_type='autonomous-workflow:latex-compiler'
prompt: "Compile docs/autonomous/<name>/research/<name>-report.tex to PDF. The working directory is docs/autonomous/<name>/research/."
```

This produces a PDF the user can check while the workflow continues. (The implementation plan is Markdown and does not need compilation.)

---

## STEP 4: Resume Workflow

Based on `workflow_type` and `current_phase`, dispatch to the appropriate iteration logic:

| workflow_type | current_phase | Action |
|---|---|---|
| `autonomous-research` | Phase A: Research | Execute one research iteration (same as `/autonomous-workflow:research`) |
| `autonomous-research-plan` | Phase A: Research | Execute one research iteration with planning focus (same as `/autonomous-workflow:research-and-plan` Phase A) |
| `autonomous-research-plan` | Phase B: Planning | Execute one planning iteration (same as `/autonomous-workflow:research-and-plan` Phase B) |
| `autonomous-full-auto` | Phase A: Research | Execute one research iteration (same as `/autonomous-workflow:full-auto` Phase A) |
| `autonomous-full-auto` | Phase B: Planning | Execute one planning iteration (same as `/autonomous-workflow:full-auto` Phase B) |
| `autonomous-full-auto` | Phase C: Implementation | Execute one implementation iteration (same as `/autonomous-workflow:full-auto` Phase C) |
| `autonomous-implement` | Phase C: Implementation | Execute one implementation iteration (same as `/autonomous-workflow:implement` Step 3) |

For research iterations: read `current_research_strategy` from state, spawn strategy-dependent parallel researcher agents based on open questions. Follow strategy rotation logic from `/autonomous-workflow:research` Step 7.
For planning iterations: spawn plan-architect + plan-critic agents.
For implementation iterations: find next unblocked feature, spawn autonomous-coder.

Follow the full iteration logic from the corresponding command (research.md, research-and-plan.md, full-auto.md, or implement.md). The iteration steps are identical — this command just handles the detection and dispatch.

---

## Wrapping in ralph-loop

To continue for multiple iterations autonomously:

```
/ralph-loop:ralph-loop "/autonomous-workflow:continue-auto '<topic-name>'" --max-iterations 30
```

---

## OUTPUT

```
## Resumed: <name> (<workflow_type>)

### Current Phase: <phase>
### Iteration: <N>

### This Iteration:
[Phase-specific summary from the dispatched iteration]

### Next:
[What the next iteration will focus on]
```
