---
description: "Resume an interrupted autonomous workflow from saved state"
model: opus
argument-hint: "[topic-name]"
---

# ABOUTME: Resume command that detects active autonomous workflows and continues from saved state.
# ABOUTME: Compiles LaTeX for progress check, then dispatches to the appropriate phase iteration.

# Continue Autonomous Workflow

**Topic** (optional): $1

## Objective

Detect and resume an active autonomous workflow. Compiles any existing LaTeX documents to PDF first (so you can check progress), then continues from the current phase.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Find Active Workflow

### If topic name provided ($1 is not empty):

Look for `docs/research-$1/$1-state.md`. If not found, output error:
```
ERROR: No workflow found for '$1'.
Searched: docs/research-$1/$1-state.md

Available research directories:
[list contents of docs/research-*/]
```

### If no topic name provided:

Scan `docs/research-*/*-state.md` for files with `status: in_progress` in YAML frontmatter.

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
- All other YAML fields for context

Read the corresponding documents:
- Always read: `<name>-report.tex` (if exists)
- If modes 2+3+4: read `<name>-plan.tex` (if exists)
- If modes 3+4: read `feature-list.json` and `progress.txt` (if they exist)

---

## STEP 3: Compile LaTeX (Progress Check)

Spawn `autonomous-workflow:latex-compiler` agent for each existing `.tex` file:

```
Task tool with subagent_type='autonomous-workflow:latex-compiler'
prompt: "Compile all .tex files in docs/research-<name>/. The working directory is docs/research-<name>/."
```

This produces PDFs the user can check while the workflow continues.

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

For research iterations: spawn 3-5 parallel researcher agents based on open questions in state file.
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
