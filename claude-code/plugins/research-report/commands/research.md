---
description: "Deep research producing an argument-driven LaTeX report via the research-report plugin"
model: opus
argument-hint: "Your detailed research prompt..." [--research-iterations N]
---

# ABOUTME: Research-report plugin orchestrator that runs ONE iteration per invocation across an evidence-pool / outline / write / read pipeline.
# ABOUTME: Phase R harvests evidence-pool entries; Phase S writes the report from the pool with single-voice sequential chapters and reader-pass iterations (max 5 with early termination).

# Autonomous Deep Research

**Prompt**: $1
**All Arguments**: $ARGUMENTS
**Topic slug**: derived in STEP 1 (kebab-case, generated from prompt on first iteration; read from state on resume)

Parse optional flags from **All Arguments**:
- `--research-iterations N`: total research iteration budget (default: 30)

Reader passes in Phase S are **hardcoded at a maximum of 5** with early termination — no flag.

## Objective

Run ONE ITERATION of the research-report pipeline. Each iteration: read state, route to the appropriate phase action, execute it, update state. The Stop hook re-feeds this command for multi-iteration execution.

The pipeline separates **evidence collection** (Phase R) from **report writing** (Phase S). Phase R harvests structured evidence-pool entries — no prose is written into the report during Phase R. Phase S writes the report from the pool with a single authorial voice, sequential per-chapter writing, methodological audits, and reader-pass iterations.

**REQUIRED**: Use the Skill tool to invoke `research-report:research-report-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

**Find existing in-progress workflow first.** Use Glob to look for `.plugin-state/research-report-*-state.md`. For each match, check the YAML frontmatter `status` field — pick the one with `status: in_progress`.

### If an in-progress state file exists (resuming):

1. Read its YAML frontmatter and extract `name` (the topic slug)
2. Set `<topic_slug>` to that value for all paths below
3. Read `.plugin-state/research-report-<topic_slug>-state.md` for full state
4. Read `docs/research-report/<topic_slug>/evidence-pool.jsonl` (count entries; do NOT load all into context if large — use grep/wc)
5. Read `docs/research-report/<topic_slug>/chapter-arguments.json`
6. Read `docs/research-report/<topic_slug>/research-progress.md`
7. If `current_phase` is past `Phase S: Voice`, also read `docs/research-report/<topic_slug>/voice-guide.md`
8. Read `current_phase` and the relevant sub-phase counters from state YAML
9. Skip to the **Phase Router**

### If no in-progress state file exists (first iteration):

1. **Derive topic slug from the prompt.** Generate a short kebab-case slug (3-5 words, lowercase, hyphen-separated) that captures the prompt's subject. Examples:
   - Prompt: *"Research the dental practice RCM market and major players"* → `dental-rcm-market`
   - Prompt: *"How are LLM agents being used in customer support today?"* → `llm-agents-customer-support`
   - Prompt: *"Compare the leading vector databases for RAG"* → `vector-db-rag-comparison`

   Pick a slug that's specific enough to be unique but short enough to use in file names. Set `<topic_slug>` to the chosen slug.

2. Create directory structure:
   ```
   docs/research-report/<topic_slug>/
   docs/research-report/<topic_slug>/transcripts/
   ```

3. Read the report template from the plugin:
   - Use Glob to find `**/research-report/templates/report-template.tex`
   - Read the template
   - Replace `PLACEHOLDER_TITLE` with a descriptive title based on the prompt
   - Write to `docs/research-report/<topic_slug>/<topic_slug>-report.tex`

4. Create empty bibliography file `docs/research-report/<topic_slug>/sources.bib`:
   ```bibtex
   % Bibliography for research topic: <topic_slug>
   % Entries are added as sources are discovered during research.
   ```

5. Create empty evidence pool `docs/research-report/<topic_slug>/evidence-pool.jsonl`:
   - Read `**/research-report/templates/evidence-pool-template.jsonl` for the format spec (do not copy the example entry into the live pool)
   - Write a fresh empty file with a single header line: `{"_comment": "Evidence pool for <topic_slug>. One JSON object per line."}`

6. Create empty chapter-arguments file `docs/research-report/<topic_slug>/chapter-arguments.json`:
   ```json
   {"locked": false, "chapters": []}
   ```

7. Create `docs/research-report/<topic_slug>/research-progress.md`:
   ```markdown
   # Research Progress: <topic_slug>

   ## Original Prompt
   $1

   ## Major Themes/Findings
   - (none yet)

   ## Well-Supported vs. Thin
   - (to be updated as research progresses)

   ## Open Contradictions
   - (none yet)

   ## Methodological Quality
   - Pool entries with TIGHT gap: 0
   - Pool entries with MODERATE gap: 0
   - Pool entries with WIDE gap: 0
   - Entries narrowed after critique: 0
   - Entries flagged for removal: 0

   ## Research Direction
   - Begin with wide-exploration to establish baseline understanding
   ```

8. Parse research budget from `--research-iterations` flag in All Arguments. If not provided, default to 30.

9. Create state file `.plugin-state/research-report-<topic_slug>-state.md` with YAML frontmatter:
   ```yaml
   ---
   workflow_type: research-report
   name: <topic_slug>
   status: in_progress
   current_phase: "Phase R: Research"
   iteration: 1
   total_iterations_research: 0
   research_budget: <parsed from --research-iterations flag, or 30 if not provided>
   current_research_strategy: wide-exploration
   research_strategies_completed: []
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   evidence_pool_count: 0
   sources_cited: 0

   # Phase O fields (interleaved within Phase R)
   last_outline_pass_iteration: 0
   outline_pass_interval: 5
   chapter_arguments_count: 0
   chapter_arguments_locked: false

   # Phase S sub-phase tracking
   voice_guide_written: false
   chapter_count: 0
   writing_chapter: 0
   conclusions_written: false
   front_synthesis_written: false

   # Phase S Read (max 5 passes with early termination — no user-facing budget)
   reading_iteration: 0
   reading_phase: ""              # "IDENTIFY" | "FIX" | "VERIFY"
   reading_passes_completed: 0
   reading_high_issues_initial: 0     # set after IDENTIFY pass
   reading_medium_issues_initial: 0   # set after IDENTIFY pass
   reading_high_issues_remaining: 0   # updated after each FIX pass

   command: |
     <the full invocation command, e.g. /research-report:research '$1' --research-iterations N>
   ---

   # Research Report State: <topic_slug>

   ## Current Phase
   Phase R: Research

   ## Original Prompt
   $1

   ## Completed Phases
   - [ ] Phase R: Research (with interleaved Phase O outline passes)
   - [ ] Phase S: Voice
   - [ ] Phase S: Outline-Final
   - [ ] Phase S: Write-Chapter (one per chapter)
   - [ ] Phase S: Write-Conclusions
   - [ ] Phase S: Write-Front-Synthesis
   - [ ] Phase S: Read (early termination at any of 2-5 passes)
   - [ ] Phase S: Compile

   ## Strategy History
   | Strategy | Iterations | Pool Entries Added | Rotated At |
   |----------|-----------|-------------------|------------|

   ## Open Questions
   1. [Derive 5 initial research questions from the prompt]
   2. ...

   ## Context Restoration Files
   1. .plugin-state/research-report-<topic_slug>-state.md (this file)
   2. docs/research-report/<topic_slug>/<topic_slug>-report.tex
   3. docs/research-report/<topic_slug>/evidence-pool.jsonl
   4. docs/research-report/<topic_slug>/chapter-arguments.json
   5. docs/research-report/<topic_slug>/research-progress.md
   6. CLAUDE.md
   ```

---

## Phase Router

Route based on `current_phase`:

| current_phase | Action |
|--------------|--------|
| `Phase R: Research` | STEP 2 (Phase R iteration) |
| `Phase S: Voice` | STEP 10 (write voice-guide.md) |
| `Phase S: Outline-Final` | STEP 11 (lock chapter arguments) |
| `Phase S: Write-Chapter` | STEP 12 (write the chapter at `writing_chapter`) |
| `Phase S: Write-Conclusions` | STEP 13 (write back-loaded Conclusions) |
| `Phase S: Write-Front-Synthesis` | STEP 14 (write front Synthesis) |
| `Phase S: Read` | STEP 15 (run reader pass — mode determined by `reading_phase`) |
| `Phase S: Compile` | STEP 16 (latex-compiler) |

---

# PHASE R: Research (evidence collection)

Phase R does NOT write prose into the report. It harvests structured pool entries. Interleaved Phase O passes propose chapter-level arguments based on accumulated evidence.

## STEP 2: Empty Repo Detection

Before spawning repo-analyst agents, check if the repo has meaningful non-research content:

Use Glob to search for files matching `**/*.py`, `**/*.ts`, `**/*.js`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.c`, `**/*.cpp`, `**/*.swift`. Exclude anything under `docs/research-report/*`.

- If code files found: spawn 1-2 repo-analyst agents alongside researchers in STEP 3
- If NO code files found: skip repo-analyst agents

## STEP 3: Spawn Parallel Research Agents (Strategy-Dependent)

Read `current_research_strategy` from state. Dispatch agents based on the active strategy.

### Strategy Dispatch Table

| Strategy | Agents | Prompt Focus |
|----------|--------|--------------|
| `wide-exploration` | 3-5 | Different broad questions derived from prompt + open questions |
| `source-verification` | 3-4 | Each verifies 2-3 existing pool entries against independent sources |
| `methodological-critique` | 2-3 | Each evaluates 2-3 pool entries via `methodological-critic` Mode 1 |
| `contradiction-resolution` | 2-3 | Each resolves 1-2 contradictions in pool |
| `deep-dive` | 2-3 | Single high-value topic per agent, primary sources, 5-10 entries |
| `adversarial-challenge` | 3-4 | Each challenges a key pool entry or chapter argument |
| `gaps-and-blind-spots` | 3-4 | Each investigates an uncovered area |
| `temporal-analysis` | 3-4 | Historical evolution, recent developments, future trajectory |
| `cross-domain-synthesis` | 3-4 | Analogous problems in other fields |

### Agent Prompt Format

Every agent prompt MUST include:

1. `Strategy: <name>` line
2. The specific research question for this agent
3. Brief context: iteration number, evidence-pool count, current themes
4. **If `chapter_arguments_locked == false` and there are no proposed chapter args yet**: no chapter-arg targeting line
5. **If proposed chapter args exist** (count > 0): one line `Target chapter argument: "<chapter heading>" — produce entries with supports_chapter_arg set to STRENGTHENS, WEAKENS, QUALIFIES, or UNRELATED for this argument.` Pick the chapter argument that needs more evidence (lowest entry count) or that the strategy is well-suited to (e.g., adversarial-challenge → most-cited argument).
6. For `source-verification`: a list of 2-3 existing pool entry IDs to verify (researchers must NOT reuse those entries' sources)
7. For `contradiction-resolution`: descriptions of 1-2 contradictions from open questions

```
Task tool with subagent_type='research-report:researcher'
prompt: "Strategy: <current_research_strategy>

Research question: <specific question>

Context: This is iteration N of a deep research project on '<topic_slug>'. Current strategy: <strategy>. Evidence pool currently has <count> entries across themes: <top themes>. <Optional: target chapter arg line.>

<Strategy-specific instructions and inputs.>

Return Pool Entries and Source Catalogue per the researcher agent's output spec."
```

### Strategy-Specific Dispatch Notes

- **wide-exploration**: derive 3-5 specific questions from the prompt, open questions, and theme gaps. Standard researcher behavior.
- **source-verification / contradiction-resolution / adversarial-challenge / gaps-and-blind-spots / temporal-analysis / cross-domain-synthesis**: see researcher agent spec for the strategy-specific output fields each entry must include.
- **deep-dive**: 2-3 agents, each on one high-value topic from current themes. Each produces 5-10 pool entries.
- **methodological-critique**: dispatch via `methodological-critic` agent in Mode 1 (Source vs. Pool-Entry):
  ```
  Task tool with subagent_type='research-report:methodological-critic'
  prompt: "Mode: 1 (Source vs. Pool-Entry)

  Pool file: docs/research-report/<topic_slug>/evidence-pool.jsonl
  Sources file: docs/research-report/<topic_slug>/sources.bib

  Pool entry IDs to evaluate:
  - <entry_id_1>
  - <entry_id_2>
  - <entry_id_3>

  Read the source URLs directly. Evaluate whether each entry's claim and narrowest_defensible_reading match what the source actually proves. Return Mode 1 output per the methodological-critic spec."
  ```

### Repo-Analyst Agents

If STEP 2 found code files, spawn 1-2 in the SAME message as researchers:
```
Task tool with subagent_type='research-report:repo-analyst'
prompt: "Analyze how the codebase relates to: <specific aspect of the research topic>"
```

### CRITICAL: Never search the web yourself.

ALL web interaction happens in subagents. The main instance receives only structured pool entries.

Launch ALL agents in a SINGLE message with multiple Task tool calls.

## STEP 4: Validate and Append Pool Entries

After all agents return:

1. Collect all `## Pool Entries` JSON arrays from researcher outputs.
2. For each entry, validate required fields are present: `id`, `claim`, `evidence_summary`, `narrowest_defensible_reading`, `source_assertion`, `source_keys`, `gap_rating`, `load_bearing_assumptions`, `regime_conditions`, `themes`, `supports_chapter_arg`, `confidence`, `iteration_added`, `strategy`. If any required field is missing, ask the responsible researcher to fix (or reject the entry and log).
3. **Deduplicate against existing pool**: for each new entry, grep `evidence-pool.jsonl` for entries with overlapping `claim` text or identical `source_keys`. If a near-duplicate exists, either merge (extend `source_keys`, keep tighter `gap_rating`) or skip.
4. **Append validated entries** to `docs/research-report/<topic_slug>/evidence-pool.jsonl` (one JSON object per line, append-only).
5. **Apply methodological-critic Mode 1 verdicts** (if this iteration's strategy was `methodological-critique`):
   - `KEEP_AS_IS`: no change
   - `NARROW_THE_CLAIM`: rewrite the entry's `claim` and `narrowest_defensible_reading` fields in-place (use `jq` or Edit on the JSONL line)
   - `DOWNGRADE_CONFIDENCE`: lower `confidence` field
   - `WIDEN_GAP_RATING`: change `gap_rating` to MODERATE or WIDE
   - `FLAG_FOR_REMOVAL`: delete the entry from the pool. Write a source-quality learning (see Learnings System below).
6. **Count contributions** across types:
   - **New entries**: count of new pool entries added this iteration
   - **Verifications applied**: entries with `verification.verdict` field (CONFIRMED/REFUTED/INCONCLUSIVE)
   - **Contradictions resolved**: entries with `resolution` field
   - **Pool refinements**: entries updated by methodological-critic verdicts (NARROW/DOWNGRADE/WIDEN/REMOVE)
   - **Source-set expansions**: count of new BibTeX sources added to `sources.bib`
7. Sum to get `contributions_this_iteration`.

## STEP 5: Update sources.bib

For each unique new source key from the agents' `## Source Catalogue` outputs:

1. Check if a BibTeX entry with that key already exists in `sources.bib` — skip if so. Also check if same URL appears under a different key — if so, log and use existing key.
2. Convert the catalogue record to a BibTeX entry. Use `@article` for journal papers, `@techreport` for reports, `@misc` for web content. Include: title, author, year, url, note (with type and credibility).
3. Append to `sources.bib`.

Sources.bib accumulates across all iterations. The narrative-writer's `\cite{key}` references will resolve against this file.

**Bibliography hygiene rule (final, enforced in Phase S Compile)**: every `\cite{}` in the report must resolve against `sources.bib`. Conversely, any orphan source (in `sources.bib` but never cited) is acceptable during Phase R but will be pruned in Phase S Compile.

## STEP 6: Update State File

Update `.plugin-state/research-report-<topic_slug>-state.md`:

1. Increment `iteration` by 1
2. Update `total_iterations_research` (+1)
3. Update `evidence_pool_count` (count lines in `evidence-pool.jsonl` minus header line)
4. Update `sources_cited` (count entries in `sources.bib`)
5. Set `contributions_last_iteration` to the total from STEP 4
6. Update `consecutive_low_contributions`:
   - If `contributions_last_iteration < 2`: increment
   - Otherwise: reset to 0
7. Update Strategy History table with this iteration's strategy and pool entries added
8. Update Open Questions section
9. Update `research-progress.md` (Major Themes, Well-Supported vs. Thin, Open Contradictions, Methodological Quality counts; ≤500 words total)

## STEP 7: Strategy Rotation Check

If `consecutive_low_contributions >= strategy_rotation_threshold`:

1. Add `current_research_strategy` to `research_strategies_completed`
2. Log to Strategy History
3. If ALL 9 strategies in `research_strategies_completed`: clear list, set strategy back to `wide-exploration`, log cycle restart, send macOS notification.
4. Else: pick next strategy in fixed order:
   1. `wide-exploration`
   2. `source-verification`
   3. `methodological-critique`
   4. `contradiction-resolution`
   5. `deep-dive`
   6. `adversarial-challenge`
   7. `gaps-and-blind-spots`
   8. `temporal-analysis`
   9. `cross-domain-synthesis`
5. Reset `consecutive_low_contributions` to 0
6. Send macOS notification: rotation message
7. Write a strategy-rotation learning (see Learnings System below)

## STEP 8: Interleaved Phase O Outline Pass (conditional)

Run this step IF `total_iterations_research >= outline_pass_interval` AND `(total_iterations_research - last_outline_pass_iteration) >= outline_pass_interval`. Otherwise skip to STEP 9.

This is the heart of the argument-driven approach: chapter arguments evolve as evidence comes in.

### 8.1: Cluster pool entries by theme

Read `evidence-pool.jsonl`. Group entries by their `themes` tags. Identify 3-7 thematic clusters that the report could organize around. Look for:

- Themes with high entry counts (well-supported)
- Themes with conflicting entries (the report should engage the conflict)
- Themes that span multiple iterations and strategies (durable patterns)
- Themes with both STRENGTHENS and WEAKENS support (interesting argument terrain)

### 8.2: Propose / revise chapter arguments

Read existing `chapter-arguments.json`. For each thematic cluster, draft (or revise) a chapter-level argument:

- Heading must be a sentence that takes a position, not a topic bucket
- Include `argument` field: 2-3 sentence thesis the chapter will defend
- Include `supporting_entry_ids[]`: pool entry IDs that bear on the argument
- Include `confidence`: high | medium | low based on the supporting entries' gap_ratings
- Set `status`: PROPOSED (new), REVISED (changed from prior pass), STABLE (unchanged), DROPPED (no longer supported)

Cap at 8 chapters. Long topics use deeper chapters (more sub-arguments per chapter), not more chapters.

### 8.3: Methodological-critic Mode 2 check on each chapter argument

Spawn methodological-critic in Mode 2 for each PROPOSED or REVISED chapter argument:

```
Task tool with subagent_type='research-report:methodological-critic'
prompt: "Mode: 2 (Pool-Entry Set vs. Chapter-Level Argument)

Pool file: docs/research-report/<topic_slug>/evidence-pool.jsonl

Proposed chapter argument: '<heading>'
Argument thesis: '<2-3 sentence thesis>'
Supporting pool entry IDs: <list>

Evaluate whether the pool entries jointly carry the argument's weight. Check for aggregation overreach, cherry-picking (look at entries with WEAKENS or QUALIFIES that the argument may ignore), and regime drift. Return Mode 2 verdict per the methodological-critic spec."
```

### 8.4: Apply verdicts

For each chapter argument, apply the critic's verdict:
- `HOLDS`: keep as-is, mark STABLE
- `NARROW_THE_ARGUMENT`: replace heading and thesis with the critic's proposed revision
- `STRONG_BUT_OVERSTATED`: keep but add `required_qualifications` field for the writer to honor
- `DOES_NOT_HOLD`: drop the chapter (set status: DROPPED, keep in file for audit)

### 8.5: Write chapter-arguments.json

Write the updated structure:
```json
{
  "locked": false,
  "last_pass_iteration": <total_iterations_research>,
  "chapters": [
    {
      "id": "chapter-1",
      "heading": "<argument-style sentence>",
      "argument": "<thesis>",
      "supporting_entry_ids": ["...", "..."],
      "required_qualifications": ["..."],
      "confidence": "high | medium | low",
      "status": "PROPOSED | REVISED | STABLE | DROPPED",
      "critic_verdict_history": ["HOLDS", "STRONG_BUT_OVERSTATED", ...]
    }
  ]
}
```

Update state: `last_outline_pass_iteration = total_iterations_research`, `chapter_arguments_count = count of non-DROPPED chapters`.

Send macOS notification:
```
osascript -e 'display notification "Phase O outline pass complete for <topic_slug> — N chapter arguments" with title "Research Report" subtitle "Outline"'
```

## STEP 9: Phase R Completion Check / Identify Next Directions

If `total_iterations_research >= research_budget`:

1. Run a FINAL Phase O outline pass (per STEP 8) regardless of cadence — ensures the most-evolved chapter arguments enter Phase S
2. Transition to Phase S:
   - Set `current_phase: "Phase S: Voice"`
   - Mark `Phase R: Research` complete in Completed Phases
3. Send macOS notification: "Research budget reached for <topic_slug> — transitioning to Phase S"
4. Stop hook re-feeds command; next invocation enters Phase S via Phase Router.

Otherwise, write 3-5 prioritized research directions for the next iteration in the state file's Open Questions section. Direction-priority by strategy:
- **wide-exploration**: contradictions, low-confidence claims, gaps, deeper dives
- **source-verification**: lowest-confidence pool entries, single-source entries
- **contradiction-resolution**: explicit pool contradictions, agent-reported conflicts
- **deep-dive**: thinnest themes, surface-only entries
- **adversarial-challenge**: strongest chapter arguments, most-confident pool entries
- **gaps-and-blind-spots**: missing perspectives, unexplored adjacent domains
- **temporal-analysis**: turning points, recent shifts, emerging trends
- **cross-domain-synthesis**: structurally analogous problems in other fields
- **methodological-critique**: highest-impact pool entries, single-source entries

### Phase R Output

```
## Iteration N Complete (Phase R: Research)

### Strategy: [current_research_strategy]
### Contributions This Iteration: [count]
- New pool entries: [count]
- Verifications applied: [count]
- Contradictions resolved: [count]
- Pool refinements: [count]
- New sources added: [count]

### Pool Size: [evidence_pool_count]
### Sources: [sources_cited]
### Chapter Arguments: [chapter_arguments_count] (after [N] outline passes)
### Strategy Progress: [completed]/9
### Consecutive Low-Contribution Iterations: [N]/[threshold]

### Next Iteration:
- Strategy: [current or rotated]
- Top 3 directions: ...
```

---

# PHASE S: Writing the report from the pool

Phase S is broken into sub-phases routed by `current_phase`. One sub-phase action per iteration. Each writes its outputs and transitions `current_phase` to the next sub-phase.

## STEP 10: Phase S — Voice (write voice-guide.md)

Goal: write `docs/research-report/<topic_slug>/voice-guide.md` based on the topic and the audience inferable from the research prompt.

1. Read `**/research-report/templates/voice-guide-template.md`
2. Read the original research prompt from state and skim 10-20 representative pool entries to infer the audience and appropriate register
3. Fill out every section of the voice-guide based on what fits the topic. Be decisive — pick one option per choice. Document terminology decisions for any concept where pool entries used different vocabulary.
4. Write the headline argument as a single sentence based on the chapter arguments in `chapter-arguments.json`
5. Write to `docs/research-report/<topic_slug>/voice-guide.md`
6. Update state: `voice_guide_written: true`, `current_phase: "Phase S: Outline-Final"`
7. Mark `Phase S: Voice` complete in Completed Phases
8. Output:
   ```
   ## Phase S — Voice Complete
   ### Audience: [inferred audience]
   ### Register: [chosen]
   ### Headline Argument: [one sentence]
   ### Next: Outline-Final
   ```

## STEP 11: Phase S — Outline-Final (lock chapter arguments)

Goal: produce the final, locked chapter outline that the body will be written from.

1. Read `chapter-arguments.json` (current state from interleaved Phase O passes)
2. Read full `evidence-pool.jsonl`
3. Read `voice-guide.md`
4. Run a final Phase O pass (per STEP 8.1-8.4) using the FULL pool. This may revise, drop, or merge chapters. Cap at 8.
5. For each surviving chapter, finalize:
   - `id`: stable chapter ID (chapter-1 through chapter-N in final order)
   - `heading`: argument-style sentence (final)
   - `argument`: 2-3 sentence thesis (final)
   - `supporting_entry_ids[]`: full list of pool entries the chapter will draw from
   - `required_qualifications[]`: caveats from critic that the writer must honor
   - `target_word_count`: 1500-3500 based on `len(supporting_entry_ids)` and argument complexity
   - `surrounding_context`: brief 1-line summary of preceding chapter and following chapter (for the writer's through-line awareness)
6. Determine final chapter ORDER. Order should build the argument: foundational claims first, applications/implications later, counter-arguments and edge cases near the end before the back Conclusions.
7. Update `chapter-arguments.json`:
   ```json
   {
     "locked": true,
     "locked_at_iteration": <iteration>,
     "chapter_count": N,
     "chapters": [...]
   }
   ```
8. Update state: `chapter_arguments_locked: true`, `chapter_count: N`, `writing_chapter: 1`, `current_phase: "Phase S: Write-Chapter"`
9. Mark `Phase S: Outline-Final` complete in Completed Phases
10. Output:
    ```
    ## Phase S — Outline-Final Complete
    ### Locked Chapters: N
    1. [heading 1]
    2. [heading 2]
    ...
    ### Next: Write-Chapter 1
    ```

## STEP 12: Phase S — Write-Chapter (one chapter per iteration)

Goal: write the body chapter at index `writing_chapter` as continuous argumentative prose, audit it, revise if needed.

Read the chapter to write from `chapter-arguments.json` at index `writing_chapter - 1` (1-indexed).

### 12.1: Spawn narrative-writer

```
Task tool with subagent_type='research-report:narrative-writer'
prompt: "Section to write: body chapter <writing_chapter> of <chapter_count>

Argument to defend: <chapter heading>
Thesis: <chapter argument>
Required qualifications: <required_qualifications list>
Target word count: <target_word_count>

Voice guide: docs/research-report/<topic_slug>/voice-guide.md
Evidence pool: docs/research-report/<topic_slug>/evidence-pool.jsonl
Pool entry IDs assigned to this chapter: <supporting_entry_ids>

Surrounding context:
- Preceding chapter: <one-line summary or 'first chapter — opens the body'>
- Following chapter: <one-line summary or 'last chapter — leads into back Conclusions'>

Output: append the chapter's LaTeX content to docs/research-report/<topic_slug>/<topic_slug>-report.tex inside the body chapters region. The first time you write a body chapter, REPLACE the line containing '% CHAPTERS_PLACEHOLDER' with your chapter content. For subsequent chapters, INSERT after the previous chapter's last line.

Follow the narrative-writer spec: argument-style heading, continuous argumentative prose, every paragraph makes a claim with cites as evidence, closing paragraph interprets, all qualifications from pool preserved."
```

### 12.2: Spawn methodological-critic Mode 3 audit

Once the writer finishes:

```
Task tool with subagent_type='research-report:methodological-critic'
prompt: "Mode: 3 (Drafted Chapter Prose vs. Pool Entries)

Report file: docs/research-report/<topic_slug>/<topic_slug>-report.tex
Pool file: docs/research-report/<topic_slug>/evidence-pool.jsonl

Chapter heading just drafted: '<chapter heading>'
Pool entry IDs the writer was assigned: <supporting_entry_ids>

Read the chapter prose. For each cite, verify the claim being supported matches the pool entry's narrowest_defensible_reading. Check for OVERSTATEMENT, LOST_QUALIFICATION, SMUGGLED_INFERENCE, SOURCE_CLAIM_MISMATCH, AGGREGATION_OVERREACH. Return Mode 3 audit per the methodological-critic spec."
```

### 12.3: Apply audit verdict

If overall verdict is `NEEDS_REVISION`:

Re-spawn the narrative-writer with the audit's issues list and instructions to fix:
```
Task tool with subagent_type='research-report:narrative-writer'
prompt: "Section to revise: body chapter <writing_chapter>
[Original prompt as above]

REVISION REQUIRED. Methodological-critic audit found these issues:
<issues list from audit>

Fix each issue in the chapter at the locations identified. Do not introduce new claims; do not change cites. Re-write only the prose flagged."
```

After revision, optionally re-audit (max one re-audit per chapter — if it still fails, accept and document outstanding issues in state).

### 12.4: Increment chapter pointer and route

Update state:
- `writing_chapter += 1`
- If `writing_chapter > chapter_count`: set `current_phase: "Phase S: Write-Conclusions"`, mark `Phase S: Write-Chapter` complete in Completed Phases (one entry covers all chapters)
- Else: stay on `current_phase: "Phase S: Write-Chapter"` (next iteration writes the next chapter)

Send macOS notification per chapter completion:
```
osascript -e 'display notification "Chapter <writing_chapter-1> drafted for <topic_slug>" with title "Research Report" subtitle "Phase S: Write"'
```

### 12.5: Output

```
## Phase S — Write-Chapter <N> Complete
### Heading: <heading>
### Word count: <approx>
### Audit verdict: PASSES | NEEDS_REVISION (revised: yes/no)
### Outstanding issues: <list or 'none'>
### Next: Write-Chapter <N+1> | Write-Conclusions
```

## STEP 13: Phase S — Write-Conclusions (back-loaded section)

Goal: write the back-loaded `\section{Conclusions \& Recommendations}` — the integrated argument earned by the body chapters.

```
Task tool with subagent_type='research-report:narrative-writer'
prompt: "Section to write: Conclusions & Recommendations (back-loaded)

This is the integrated argument earned by all the body chapters. Be more direct than the front Synthesis — the reader has done the work.

Voice guide: docs/research-report/<topic_slug>/voice-guide.md
Evidence pool: docs/research-report/<topic_slug>/evidence-pool.jsonl
Chapter arguments: docs/research-report/<topic_slug>/chapter-arguments.json
Report so far: docs/research-report/<topic_slug>/<topic_slug>-report.tex (read the full body)

Required subsections (per template): 'The Argument, Stated Plainly', 'Conclusions', 'Recommendations', 'Conditions Under Which the Argument Could Change'.

Output: replace the placeholder content inside \section{Conclusions \& Recommendations} of docs/research-report/<topic_slug>/<topic_slug>-report.tex with the drafted content. Each conclusion must reference the chapter(s) that earned it; each recommendation must pair with a conclusion."
```

After writer completes, update state:
- `conclusions_written: true`
- `current_phase: "Phase S: Write-Front-Synthesis"`
- Mark `Phase S: Write-Conclusions` complete in Completed Phases

Output:
```
## Phase S — Write-Conclusions Complete
### Word count: <approx>
### Next: Write-Front-Synthesis
```

## STEP 14: Phase S — Write-Front-Synthesis (executive summary, written last)

Goal: write the front-loaded `\section{Synthesis}` AFTER body and back are finalized, so it accurately reflects what was actually argued.

```
Task tool with subagent_type='research-report:narrative-writer'
prompt: "Section to write: front Synthesis (executive summary)

Written last so it reflects what was actually argued. Standalone — a busy reader who reads only this section gets the report.

Voice guide: docs/research-report/<topic_slug>/voice-guide.md
Report so far: docs/research-report/<topic_slug>/<topic_slug>-report.tex (READ the entire finalized body and back Conclusions)

Required subsections (per template): 'Summary', 'Key Takeaways', 'Conclusions & Recommendations Preview', 'Confidence & Limitations'. Length 1500-2000 words. Key Takeaways MUST be \\begin{enumerate} with 5-7 items, each \\item \\textbf{Takeaway title.} followed by 2-4 sentences with \\cite{}. Each must reference its supporting chapter (e.g., 'see Chapter 3').

No temporal narrative, no references to iterations or strategies. Write as if all findings were known simultaneously.

Output: replace the placeholder content inside \\section{Synthesis} of docs/research-report/<topic_slug>/<topic_slug>-report.tex with the drafted content."
```

After writer completes, update state:
- `front_synthesis_written: true`
- `reading_iteration: 1`
- `reading_phase: "IDENTIFY"`
- `current_phase: "Phase S: Read"`
- Mark `Phase S: Write-Front-Synthesis` complete in Completed Phases

Output:
```
## Phase S — Write-Front-Synthesis Complete
### Word count: <approx>
### Body, Conclusions, Front Synthesis all drafted.
### Next: Read pass 1 (IDENTIFY)
```

## STEP 15: Phase S — Read (max 5 passes with early termination)

Goal: improve flow, engagement, and argumentative cohesion without sacrificing rigor.

The reader-pass loop runs **at most 5 iterations** with early termination. The orchestrator decides each iteration's mode based on `reading_phase` from state.

### Pass structure

| Pass # | Mode (typical) | Notes |
|--------|----------------|-------|
| 1 | IDENTIFY | Always. Catalogues issues with HIGH/MEDIUM/LOW severity. |
| 2-4 | FIX or VERIFY | FIX runs as long as HIGH issues remain. Otherwise VERIFY (early termination). |
| 5 | VERIFY | Forced final pass if not already VERIFY'd. |

Minimum: 2 passes (IDENTIFY + VERIFY). Maximum: 5 passes (IDENTIFY + 3 FIX + VERIFY).

### Run the current pass

Read `reading_phase` from state. Spawn the narrative-editor with the corresponding mode:

```
Task tool with subagent_type='research-report:narrative-editor'
prompt: "Pass <reading_iteration>. Mode: <reading_phase>

Report path: docs/research-report/<topic_slug>/<topic_slug>-report.tex
Voice guide: docs/research-report/<topic_slug>/voice-guide.md
Evidence pool (read-only, for verification): docs/research-report/<topic_slug>/evidence-pool.jsonl

<For FIX/VERIFY: include 'Issues from previous pass: docs/research-report/<topic_slug>/reader-pass-<N-1>-issues.md' (or -fixes.md if N>2)>

Follow the narrative-editor spec for the chosen mode. Run the rigor-preservation verification procedure before finalizing FIX or VERIFY passes."
```

### After the agent completes — read the output and decide what's next

Read the agent's output file (issues / fixes / verification).

#### If reading_phase was IDENTIFY (pass 1):

1. Parse the issues report. Count HIGH-severity issues (`reading_high_issues_initial`) and MEDIUM-severity issues (`reading_medium_issues_initial`).
2. Update state with these counts.
3. **Decide next pass:**
   - If `reading_high_issues_initial == 0` AND `reading_medium_issues_initial <= 3`:
     - **Early termination**: skip FIX passes. The report is clean enough.
     - Set `reading_phase: "VERIFY"`, `reading_iteration: 2`
     - Macos notification: "IDENTIFY found minor issues — skipping FIX, going to VERIFY"
   - Else:
     - Set `reading_phase: "FIX"`, `reading_iteration: 2`

4. Set `reading_passes_completed: 1`. Stay on `current_phase: "Phase S: Read"`.

#### If reading_phase was FIX (pass 2, 3, or 4):

1. Confirm the agent's rigor-preservation check PASSED. If FAILED, re-spawn the agent in FIX mode to address the failures BEFORE moving on (this happens within the same iteration; do not advance state until rigor passes).
2. Parse the fixes report to see which IDENTIFY issues were addressed and read the agent's "remaining HIGH issues" count. Update `reading_high_issues_remaining`.
3. **Decide next pass:**
   - If `reading_high_issues_remaining == 0`: all HIGH-severity issues resolved.
     - Set `reading_phase: "VERIFY"`, `reading_iteration += 1`
   - Else if `reading_iteration == 4` (just finished the 3rd FIX pass): force VERIFY at pass 5.
     - Set `reading_phase: "VERIFY"`, `reading_iteration: 5`
   - Else: keep fixing.
     - Set `reading_phase: "FIX"`, `reading_iteration += 1`

4. Increment `reading_passes_completed`. Stay on `current_phase: "Phase S: Read"`.

#### If reading_phase was VERIFY (pass 2, 3, 4, or 5):

1. Confirm the agent's rigor-preservation check PASSED. If FAILED, re-spawn in VERIFY mode (max one retry within the same iteration).
2. Read the verification report's sign-off (Argument cohesion, Flow, Voice, Rigor).
3. Update state:
   - `reading_passes_completed += 1`
   - `current_phase: "Phase S: Compile"`
   - Mark `Phase S: Read` complete in Completed Phases
4. Macos notification:
   ```
   osascript -e 'display notification "Reader passes complete (<reading_passes_completed> total) for <topic_slug> — verification PASS" with title "Research Report" subtitle "Phase S: Read"'
   ```

### Output

```
## Phase S — Read Pass <N> Complete (Mode: <IDENTIFY|FIX|VERIFY>)
### Issues identified: <count> (IDENTIFY) | Fixed: <count> (FIX) | Verified: pass/fail (VERIFY)
### HIGH issues remaining: <count>
### Rigor preservation: PASS | FAIL
### Next: Read pass <N+1> (mode <next_mode>) | Compile (if VERIFY just completed)
```

## STEP 16: Phase S — Compile

Goal: compile the LaTeX to PDF and verify formatting quality.

### 16.1: Spawn latex-compiler

```
Task tool with subagent_type='research-report:latex-compiler'
prompt: "Compile the LaTeX report at docs/research-report/<topic_slug>/<topic_slug>-report.tex to PDF.

Bibliography: docs/research-report/<topic_slug>/sources.bib

Run the full pdflatex → bibtex → pdflatex → pdflatex pipeline. Fix any compilation errors. Prune orphan BibTeX entries (entries in sources.bib not referenced by any \\cite{} in the report)."
```

If pdflatex is not installed, the agent reports and exits — proceed to 16.3 (mark complete without PDF verification).

### 16.2: Verify PDF formatting quality

After compilation succeeds, read the `.tex` and verify (per existing template formatting rules):

- All `\section{}` and `\subsection{}` have descriptive titles (chapter sections must be argument-style sentences, not topic buckets)
- No paragraph exceeds 5 sentences or ~150 words
- Lists of 3+ items use `\begin{itemize}/\begin{enumerate}` (not inline comma-prose)
- Every `\cite{key}` resolves against `sources.bib`; no orphan sources
- `\bibliographystyle{plainnat}` and `\bibliography{sources}` present
- `parskip`, `setstretch{1.35}`, `\setlength{\parindent}{0pt}`, `\titlespacing*` all present
- Table of contents renders

Fix any violations directly in the `.tex` file, then re-spawn latex-compiler to recompile.

### 16.3: Mark complete

After PDF verification (or if pdflatex unavailable):

- Set `status: complete` in state file
- Mark `Phase S: Compile` complete in Completed Phases
- Send macOS notification:
  ```
  osascript -e 'display notification "Research complete for <topic_slug> — PDF compiled and verified" with title "Research Report" subtitle "Done"'
  ```

### 16.4: Completion retrospective learning

Write a completion retrospective per the Learnings System (see below).

Output:
```
## Phase S — Compile Complete
### PDF: docs/research-report/<topic_slug>/<topic_slug>-report.pdf (or 'pdflatex not installed — .tex valid')
### Formatting verification: PASS
### Workflow status: complete
```

The Stop hook verifies `status: complete`, `total_iterations_research >= research_budget`, and Phase S sub-phase progression before allowing the workflow to end.

---

# Learnings System

The plugin writes structured learnings at key workflow points so future runs benefit. Learnings live at `~/.claude/plugin-learnings/research-report/` (overridable via `.plugin-state/research-report.local.md` with YAML field `learnings_dir`).

### Learning Write Points

| Trigger | File Pattern | Content |
|---------|--------------|---------|
| Strategy rotation (low contributions) | `YYYY-MM-DD-<topic_slug>-strategy-rotation.md` | Which strategy underperformed and why |
| Pool entry FLAG_FOR_REMOVAL verdict | `YYYY-MM-DD-<topic_slug>-source-quality.md` | Source quality pattern that led to removal |
| Chapter argument DOES_NOT_HOLD verdict | `YYYY-MM-DD-<topic_slug>-chapter-argument-dropped.md` | Why a proposed argument couldn't be earned by the pool |
| Chapter audit NEEDS_REVISION (Mode 3) | `YYYY-MM-DD-<topic_slug>-writing-revision.md` | What kind of overstatement the writer made |
| Reader-pass rigor-preservation FAIL | `YYYY-MM-DD-<topic_slug>-reader-pass-rigor-fail.md` | What rigor element was lost (citation, qualifier) |
| Workflow completion | `YYYY-MM-DD-<topic_slug>-completion-review.md` | Retrospective: intent alignment, what worked, what to improve |

### Learning File Format

YAML frontmatter:
```yaml
---
type: learning
plugin: research-report
workflow_topic: <topic_slug>
phase: <current phase>
date: YYYY-MM-DD
---
```

Body sections (most learnings):
- **Observation**: what happened concretely
- **Learning**: the pattern (why it happened)
- **Suggestion**: how to avoid or address it next time

For completion-review, body sections are:
- **Observation**: iteration counts, pool size, sources, chapter count, reader passes (note: report how many reader passes ran given early termination)
- **Intent Alignment**: did the report address the original prompt?
- **What Worked Well**: which strategies and phases ran smoothly
- **What Produced Lower Quality**: which strategies underperformed; where the report ended up thin
- **Improvement Suggestions**: specific, actionable changes to the plugin workflow

Resolve learnings directory: read `.plugin-state/research-report.local.md` for `learnings_dir`; fall back to `~/.claude/plugin-learnings/research-report/`. Run `mkdir -p` before first write.
