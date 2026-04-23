---
description: "Edit a previously completed research-report by gathering new evidence and rewriting affected chapters"
model: opus
argument-hint: "Your edit prompt..." --target <slug> [--research-iterations N]
---

# ABOUTME: Research-report edit command — runs ONE iteration per invocation across Phase E sub-phases (Plan, Research, Outline-Update, Write-Chapter, Rewrite-Conclusions, Rewrite-Front-Synthesis, Read, Compile).
# ABOUTME: Reconstructs state from artifacts on first iteration. Re-uses existing researcher, narrative-writer, methodological-critic, narrative-editor, latex-compiler agents.

# Edit a Research Report

**Edit prompt**: $1
**All Arguments**: $ARGUMENTS

Required flag:
- `--target <slug>`: which existing report to edit. Must match an existing directory at `docs/research-report/<slug>/`. Required (no auto-detect).

Optional flag:
- `--research-iterations N`: research iteration budget for this edit (default 10). Edits typically need much less than full reports.

## Objective

Run ONE ITERATION of the edit pipeline. Each iteration: read state, route to the appropriate Phase E sub-phase, execute it, update state. The Stop hook re-feeds this command for multi-iteration execution.

The edit always ends by re-running the back Conclusions, the front Synthesis, all reader passes, and recompiling — so a small substantive edit is guaranteed to produce a coherent finished report, not a Frankenstein.

**REQUIRED**: Use the Skill tool to invoke `research-report:research-report-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Parse `--target <slug>` from `$ARGUMENTS`. Set `<topic_slug>` to the parsed value. If `--target` is missing, ERROR with: "edit requires --target <slug>. Available reports:" followed by `ls docs/research-report/`.

Verify the report exists:
- `docs/research-report/<topic_slug>/<topic_slug>-report.tex` must exist
- `docs/research-report/<topic_slug>/chapter-arguments.json` must exist with `locked: true`
- `docs/research-report/<topic_slug>/evidence-pool.jsonl` must exist
- `docs/research-report/<topic_slug>/voice-guide.md` must exist
- `docs/research-report/<topic_slug>/sources.bib` must exist

If any required artifact is missing, ERROR with which artifact is missing and abort.

### If state file `.plugin-state/research-report-<topic_slug>-state.md` exists AND its `current_phase` starts with `Phase E:`:

We're resuming an in-progress edit. Read the state file and skip to the **Phase Router** below.

### Else (first edit iteration):

Reconstruct state from artifacts. Read the existing `chapter-arguments.json` to get `chapter_count`. Parse `--research-iterations` flag (default 10). Create state file `.plugin-state/research-report-<topic_slug>-state.md`:

```yaml
---
workflow_type: research-report
name: <topic_slug>
status: in_progress
current_phase: "Phase E: Plan"
iteration: 1

# Original creation flags — all true since report exists
voice_guide_written: true
chapter_arguments_locked: true
chapter_count: <from chapter-arguments.json>
writing_chapter: <chapter_count + 1>
conclusions_written: true
front_synthesis_written: true

# Phase R fields are NOT used during edit (kept for stop-hook compatibility)
total_iterations_research: 0
research_budget: 0
current_research_strategy: wide-exploration
evidence_pool_count: <line count of evidence-pool.jsonl minus 1 for header>
sources_cited: <count of @ entries in sources.bib>

# Edit-specific fields
edit_prompt: |
  $1
edit_research_budget: <parsed from --research-iterations, or 10>
edit_research_iterations_done: 0
edit_action_count: 0
edit_action_index: 0
edit_action_step: ""               # "research" | "outline" | "write" — within current action
edit_action_chapter_idx: 0         # for write step, which affected chapter
edit_research_iter_within_action: 0

# Phase E: Read fields (reuses existing reader-pass state structure, reset for the edit)
reading_iteration: 0
reading_phase: ""
reading_passes_completed: 0
reading_high_issues_initial: 0
reading_medium_issues_initial: 0
reading_high_issues_remaining: 0

command: |
  /research-report:edit '$1' --target <topic_slug> --research-iterations <budget>
---

# Edit Report State: <topic_slug>

## Current Phase
Phase E: Plan

## Edit Prompt
$1

## Completed Phases
- [ ] Phase E: Plan
- [ ] Phase E: Execute (per-action: Research → Outline-Update → Write-Chapter)
- [ ] Phase E: Rewrite-Conclusions
- [ ] Phase E: Rewrite-Front-Synthesis
- [ ] Phase E: Read
- [ ] Phase E: Compile

## Context Restoration Files
1. .plugin-state/research-report-<topic_slug>-state.md (this file)
2. docs/research-report/<topic_slug>/<topic_slug>-report.tex
3. docs/research-report/<topic_slug>/chapter-arguments.json
4. docs/research-report/<topic_slug>/evidence-pool.jsonl
5. docs/research-report/<topic_slug>/voice-guide.md
6. docs/research-report/<topic_slug>/edit-plan.json (after Phase E: Plan)
```

---

## Phase Router

Route based on `current_phase`:

| current_phase | Action |
|--------------|--------|
| `Phase E: Plan` | STEP 2 — classify edit prompt, write edit-plan.json |
| `Phase E: Research` | STEP 3 — run one Phase R iteration targeted at current action |
| `Phase E: Outline-Update` | STEP 4 — run Phase O pass to incorporate new evidence |
| `Phase E: Write-Chapter` | STEP 5 — write/rewrite the current affected chapter |
| `Phase E: Rewrite-Conclusions` | STEP 6 — re-run back Conclusions |
| `Phase E: Rewrite-Front-Synthesis` | STEP 7 — re-run front Synthesis |
| `Phase E: Read` | STEP 8 — reader pass (delegates to STEP 15 of research.md) |
| `Phase E: Compile` | STEP 9 — latex-compiler |

---

## STEP 2: Phase E — Plan

Goal: classify the edit prompt into actions and produce `docs/research-report/<topic_slug>/edit-plan.json`.

### 2.1: Read context

- `chapter-arguments.json` — current chapter outline (locked)
- `<topic_slug>-report.tex` — the existing report (skim for chapter list and current argument shape)
- `voice-guide.md` — for terminology continuity
- The edit prompt from state's `edit_prompt` field

### 2.2: Classify the edit prompt into actions

Decompose the prompt into one or more actions. Action types:

| Type | When to use | Example prompt |
|------|-------------|----------------|
| `ADD_CHAPTER` | Edit asks for a new topic not currently covered | "Add a chapter on regulatory implications" |
| `REVISE_CHAPTER` | Edit asks to change stance, depth, or framing of an existing chapter | "Make Chapter 3 more skeptical of the consolidation thesis" |
| `EXPAND_RESEARCH` | Edit asks for more evidence on existing themes (often time-sensitive) | "Update with developments since the original research" |
| `POLISH` | Edit asks for prose tightening only, no substance change | "Tighten Chapter 5's prose; nothing else" |

A single edit prompt may decompose into multiple actions. Order them: research-needing actions first, polish last.

### 2.3: For each action, decide

- `research_budget`: how many of the total `edit_research_budget` to spend on this action's research. ADD_CHAPTER and EXPAND_RESEARCH typically need 3-7. REVISE_CHAPTER typically 0-3. POLISH always 0. Sum across actions must not exceed `edit_research_budget`.
- For ADD_CHAPTER: propose a tentative argument-style chapter heading and 2-3 sentence thesis. The Phase O pass after research will refine.
- For REVISE_CHAPTER: which `chapter_id` (from chapter-arguments.json), and specific revision instructions for the writer.
- For EXPAND_RESEARCH: which themes (matching pool entries' `themes` tags) to target.
- For POLISH: which `chapter_ids` to tighten (or "all").

### 2.4: Identify affected chapters

For each action, compute which chapter IDs will be written/rewritten:
- ADD_CHAPTER: a new chapter ID (assign as `chapter-<chapter_count+1>` and append)
- REVISE_CHAPTER: the named chapter
- EXPAND_RESEARCH: chapters whose `supporting_entry_ids` overlap with the new pool entries (will be determined after research; for now, set provisional list of chapters likely to be affected)
- POLISH: the named chapters

Combine across all actions into a deduplicated `affected_chapter_ids` list. Note this in state.

### 2.5: Write edit-plan.json

```json
{
  "edit_prompt": "<from state>",
  "actions": [
    {
      "id": "action-1",
      "type": "ADD_CHAPTER",
      "description": "Add chapter on regulatory implications",
      "research_budget": 5,
      "tentative_chapter": {
        "id": "chapter-N",
        "heading": "Regulatory Pressure Is Reshaping the Adoption Curve",
        "argument": "..."
      },
      "status": "PENDING"
    },
    {
      "id": "action-2",
      "type": "REVISE_CHAPTER",
      "chapter_id": "chapter-3",
      "instructions": "Make more skeptical — give counter-evidence more weight, soften the consolidation conclusion",
      "research_budget": 0,
      "status": "PENDING"
    }
  ],
  "affected_chapter_ids": ["chapter-3", "chapter-N"],
  "total_research_budget": 5,
  "current_action_index": 0
}
```

### 2.6: Update state and route

- `edit_action_count`: number of actions
- `edit_action_index: 0`
- For action 0: set `edit_action_step: "research"` if `research_budget > 0`, else `"write"` (skip research+outline)
- Set `current_phase` to next phase based on the first action's first step:
  - If first action's step is `"research"`: `current_phase: "Phase E: Research"`
  - Else: `current_phase: "Phase E: Write-Chapter"`, `edit_action_chapter_idx: 0`
- Mark `Phase E: Plan` complete

Output:
```
## Phase E — Plan Complete
### Edit prompt: <truncated>
### Actions: <count>
1. <type>: <description>
2. ...
### Affected chapters: <list>
### Total research budget: <N>
### Next: <Phase E: Research | Phase E: Write-Chapter>
```

---

## STEP 3: Phase E — Research (one iteration)

Goal: run one targeted Phase R iteration for the current action. Reuses `commands/research.md` STEPs 2-7 logic conceptually but with edit-specific targeting.

Read `edit-plan.json`, get the current action (`actions[edit_action_index]`).

### 3.1: Spawn researchers targeted at the action

For ADD_CHAPTER and EXPAND_RESEARCH:

```
Task tool with subagent_type='research-report:researcher'
prompt: "Strategy: wide-exploration

Research question: <derived from action — e.g., 'What are the regulatory implications of dental RCM automation in the US, 2024-2026?'>

Context: This is an EDIT iteration on an existing report '<topic_slug>'. Edit action: <action description>. Evidence pool currently has <count> entries.

<For ADD_CHAPTER:> Target chapter argument: '<tentative chapter heading>' — produce entries with supports_chapter_arg set to STRENGTHENS, WEAKENS, QUALIFIES, or UNRELATED for this argument.
<For EXPAND_RESEARCH:> Target themes: <theme tags>. Find new pool entries on these themes, focusing on the most recent and authoritative sources.

Return Pool Entries and Source Catalogue per the researcher agent's output spec."
```

Spawn 2-3 researchers in parallel.

For REVISE_CHAPTER with `research_budget > 0`: spawn 1-2 researchers focused on the revision direction (e.g., for "make more skeptical": find counter-evidence to the chapter's current argument).

### 3.2: Validate, append, update sources.bib

Same as STEP 4 and STEP 5 of `commands/research.md` — validate pool entries, dedupe, append to `evidence-pool.jsonl`. Update `sources.bib` with new BibTeX entries.

### 3.3: Update state and route

- Increment `edit_research_iter_within_action` by 1
- Increment `edit_research_iterations_done` by 1
- Update `evidence_pool_count`, `sources_cited`

Decide next phase:
- If `edit_research_iter_within_action >= action.research_budget`: research done for this action.
  - Set `current_phase: "Phase E: Outline-Update"`
  - Reset `edit_research_iter_within_action: 0`
- Else: stay on `current_phase: "Phase E: Research"` (next iteration runs another research pass for this action)

Output:
```
## Phase E — Research Iteration <N> for Action <edit_action_index+1>
### Action: <type>: <description>
### Pool entries added: <count>
### Sources added: <count>
### Research iterations spent on this action: <iter>/<budget>
### Next: <Phase E: Research | Phase E: Outline-Update>
```

---

## STEP 4: Phase E — Outline-Update (one iteration)

Goal: incorporate the new pool entries into chapter-arguments.json.

Read the current action from `edit-plan.json`.

### 4.1: For ADD_CHAPTER

Run a Phase O pass focused on the new chapter:

1. Read the tentative chapter from the action
2. Look at all pool entries added in this action's research
3. Refine the chapter heading and argument based on what the evidence actually supports
4. Spawn methodological-critic Mode 2 on the refined chapter:

```
Task tool with subagent_type='research-report:methodological-critic'
prompt: "Mode: 2 (Pool-Entry Set vs. Chapter-Level Argument)

Pool file: docs/research-report/<topic_slug>/evidence-pool.jsonl

Proposed chapter argument: '<refined heading>'
Argument thesis: '<refined argument>'
Supporting pool entry IDs: <list of new entries>

Evaluate per Mode 2 spec."
```

5. Apply verdict (HOLDS / NARROW / STRONG_BUT_OVERSTATED / DOES_NOT_HOLD)
6. If DOES_NOT_HOLD: drop this action, log a learning, advance edit_action_index, route to next action
7. Else: append the new chapter to `chapter-arguments.json`. Increment `chapter_count`. Determine its insertion order in the report (typically near related chapters or at the end before any explicitly-final chapter).

### 4.2: For EXPAND_RESEARCH

Run a Phase O pass on the EXISTING chapters that the new evidence affects:

1. For each chapter, check which new pool entries have `themes` overlapping its `supporting_entry_ids` themes
2. Append matching new entries to those chapters' `supporting_entry_ids`
3. Spawn methodological-critic Mode 2 on each affected chapter to verify the chapter argument still holds (it may need narrowing or strengthening)
4. Update `chapter-arguments.json`

Update the action's `affected_chapter_ids` based on which chapters actually got new evidence. Reflect in `affected_chapter_ids` at top of `edit-plan.json`.

### 4.3: For REVISE_CHAPTER (if entered with research)

If the action had research_budget > 0, the new evidence is added to the chapter's `supporting_entry_ids` and the chapter argument may be re-evaluated. Same Mode 2 check as above.

### 4.4: Update state and route

Set `current_phase: "Phase E: Write-Chapter"`. Set `edit_action_chapter_idx: 0` to start writing the first affected chapter for this action. (For ADD_CHAPTER, the only "affected" chapter is the new one.)

Output:
```
## Phase E — Outline-Update Complete for Action <edit_action_index+1>
### Action: <type>: <description>
### Chapter args added/revised: <list of chapter_ids>
### Methodological-critic verdicts: <summary>
### Affected chapters to write: <list>
### Next: Phase E: Write-Chapter (chapter <first affected>)
```

---

## STEP 5: Phase E — Write-Chapter (one iteration per affected chapter)

Goal: write or rewrite ONE chapter. Reuses STEP 12 of `commands/research.md`.

Read the current action and `affected_chapter_ids[edit_action_chapter_idx]`. Look up the chapter from `chapter-arguments.json`.

### 5.1: Spawn narrative-writer

```
Task tool with subagent_type='research-report:narrative-writer'
prompt: "Section to write: body chapter '<chapter heading>' (chapter <id>)

This is a <NEW chapter | REVISION of an existing chapter | EXPANDED chapter with new evidence>.

<For REVISE_CHAPTER:> Revision instructions: <action.instructions>. The current prose for this chapter is in docs/research-report/<topic_slug>/<topic_slug>-report.tex — read it. Keep what's still valid; revise per the instructions.

<For POLISH:> Tightening pass only. No substance change. Cuts redundancy, improves prose density, fixes any fact-dump paragraphs. Preserve all cites and qualifications.

Argument to defend: <chapter heading>
Thesis: <chapter argument>
Required qualifications: <required_qualifications list>
Target word count: <target_word_count or 'similar to current chapter length' for REVISE/POLISH>

Voice guide: docs/research-report/<topic_slug>/voice-guide.md
Evidence pool: docs/research-report/<topic_slug>/evidence-pool.jsonl
Pool entry IDs assigned to this chapter: <supporting_entry_ids>

Surrounding context:
- Preceding chapter: <one-line summary>
- Following chapter: <one-line summary>

Output:
- For NEW chapter: insert at the chapter's determined position in the report's body region
- For REVISION/EXPANSION/POLISH: replace the existing chapter content (find the existing \\section{<old heading>} and replace through to the next \\section{} boundary)

Follow the narrative-writer spec."
```

### 5.2: Spawn methodological-critic Mode 3 audit

Same as STEP 12.2 of `research.md`. If verdict is `NEEDS_REVISION`, re-spawn narrative-writer once with the issues list.

### 5.3: Update state and route

- Increment `edit_action_chapter_idx` by 1
- If `edit_action_chapter_idx >= len(affected_chapter_ids for current action)`:
  - Mark action's `status: "DONE"` in `edit-plan.json`
  - Increment `edit_action_index` by 1
  - If `edit_action_index >= edit_action_count`: all actions done.
    - Set `current_phase: "Phase E: Rewrite-Conclusions"`
  - Else: start next action.
    - Read next action; set `edit_action_step: "research"` if its research_budget > 0, else `"write"`; set `edit_action_chapter_idx: 0`
    - Set `current_phase` accordingly: `"Phase E: Research"` or `"Phase E: Write-Chapter"`
- Else: stay on `current_phase: "Phase E: Write-Chapter"` (next iteration writes next affected chapter for this action)

Output:
```
## Phase E — Write-Chapter Complete (action <idx>, chapter <chapter_id>)
### Audit verdict: PASSES | NEEDS_REVISION (revised: yes/no)
### Action progress: <chapter idx>/<total affected> for this action
### Edit progress: action <edit_action_index+1>/<edit_action_count>
### Next: <next phase>
```

---

## STEP 6: Phase E — Rewrite-Conclusions (one iteration)

Goal: re-run the back-loaded `\section{Conclusions \& Recommendations}` because the body changed.

Identical to STEP 13 of `commands/research.md`. After completion:
- `current_phase: "Phase E: Rewrite-Front-Synthesis"`
- Mark `Phase E: Rewrite-Conclusions` complete

---

## STEP 7: Phase E — Rewrite-Front-Synthesis (one iteration)

Goal: re-run the front-loaded `\section{Synthesis}` because body and back changed.

Identical to STEP 14 of `commands/research.md`. After completion:
- `reading_iteration: 1`
- `reading_phase: "IDENTIFY"`
- `current_phase: "Phase E: Read"`
- Mark `Phase E: Rewrite-Front-Synthesis` complete

---

## STEP 8: Phase E — Read (max 5 passes with early termination)

Goal: same as STEP 15 of `commands/research.md`. Min 2 passes (IDENTIFY + VERIFY), max 5.

Run the current pass via the narrative-editor agent in the appropriate mode. Apply the same early-termination logic as STEP 15:
- Pass 1: IDENTIFY. If 0 HIGH and ≤3 MEDIUM issues, jump to VERIFY at pass 2.
- Passes 2-4: FIX or VERIFY based on remaining HIGH issues.
- Pass 5: forced VERIFY if reached.

After VERIFY pass completes:
- `current_phase: "Phase E: Compile"`
- Mark `Phase E: Read` complete

---

## STEP 9: Phase E — Compile (one iteration)

Identical to STEP 16 of `commands/research.md`:

1. Spawn `latex-compiler` to recompile.
2. Verify formatting.
3. Set `status: complete`.
4. Mark `Phase E: Compile` complete.
5. Send macOS notification: "Edit complete for <topic_slug> — PDF recompiled".
6. Write a completion-review learning capturing what changed in this edit (action types, chapters affected, research iterations spent).

The Stop hook verifies edit completion criteria (see `hooks/stop-hook.sh`) before allowing the workflow to end.

---

# Learnings System

Edit operations write learnings at:

| Trigger | File Pattern | Content |
|---------|--------------|---------|
| Action DOES_NOT_HOLD (Phase E: Outline-Update Mode 2) | `YYYY-MM-DD-<topic_slug>-edit-action-dropped.md` | Why a proposed action couldn't be earned by new evidence |
| Edit completion | `YYYY-MM-DD-<topic_slug>-edit-completion.md` | Retrospective: what was edited, what worked, what to improve |

Same directory resolution and file format as `commands/research.md`.
