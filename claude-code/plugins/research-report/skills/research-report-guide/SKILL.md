---
name: research-report-guide
description: "Autonomous research-report workflow guide. ALWAYS invoke this skill when starting, navigating, or continuing a research-report workflow, after compaction/clear, or when asking about phases, strategies, agents, or state formats. Do not proceed with research-report commands without loading this skill first."
---

# ABOUTME: Source of truth skill for the research-report plugin workflow.
# ABOUTME: Covers Phase R (evidence pool) with interleaved Phase O (chapter-argument outline), and Phase S sub-phases (Voice, Outline-Final, Write-Chapter, Write-Conclusions, Write-Front-Synthesis, Read, Compile).

# Research Report Workflow Guide

Announce at start: "I'm using the research-report-guide skill for reference on autonomous research report workflows."

## When to Activate

- Starting a research-report workflow command
- Resuming a research-report workflow after interruption
- After context compaction or clear (SessionStart hook injects this)
- When asked about research-report phases, agents, or artifacts
- When checking state file format or phase transition logic

## Workflow Overview

The pipeline separates **evidence collection** from **report writing**. Phase R harvests structured evidence-pool entries — no prose is written into the report during Phase R. Phase S writes the report from the pool with a single authorial voice, sequential per-chapter writing, methodological audits, and reader-pass iterations.

```
Phase R: Research                     → evidence-pool.jsonl (no report prose yet)
  └─ interleaved Phase O passes       → chapter-arguments.json (revisable hypotheses)
                                         every outline_pass_interval (default 5) iterations
Phase S: Voice                        → voice-guide.md
Phase S: Outline-Final                → chapter-arguments.json locked
Phase S: Write-Chapter (× N)          → body chapters, sequentially, single voice
                                         each chapter: writer drafts → critic Mode 3 audits → writer revises
Phase S: Write-Conclusions            → back-loaded \section{Conclusions \& Recommendations}
Phase S: Write-Front-Synthesis        → front-loaded \section{Synthesis} (executive summary)
Phase S: Read (2-5 passes)            → narrative-editor: IDENTIFY → FIX × 0-3 → VERIFY (early termination when no HIGH issues remain)
Phase S: Compile                      → latex-compiler → PDF
```

## Key Principles

1. **Evidence pool is the source of truth.** Researchers append structured entries; writers consume them. The pool's gap_rating, regime_conditions, narrowest_defensible_reading, and load_bearing_assumptions are rigor anchors that survive every downstream pass.
2. **Subagents absorb ALL raw data.** Main Opus instance gets only structured pool entries.
3. **Body is built from chapter-level ARGUMENTS, not topic buckets.** Every `\section{}` heading must be a sentence that takes a position.
4. **Single authorial voice across the body.** The narrative-writer drafts chapters sequentially, never in parallel, reading voice-guide.md before each.
5. **Three layers of methodological-critic safeguards** (Modes 1, 2, 3): pool-entry vs. source, chapter-arg vs. pool-entries, drafted prose vs. pool-entries.
6. **Reader passes must preserve rigor.** narrative-editor may improve flow but never drops `\cite{}`, weakens qualifications, or turns qualified claims unqualified. Verified by diff before each pass finalizes.
7. **Front Synthesis is written LAST**, after the body and back Conclusions are finalized — so it accurately reflects what was actually argued.
8. **One iteration per invocation.** Stop hook re-feeds the command.
9. **Never mock, never slop.** Quality over speed.

## Research Strategies (Phase R, 9 total)

| # | Strategy | Focus | Agent |
|---|----------|-------|-------|
| 1 | `wide-exploration` | Broad coverage | researcher |
| 2 | `source-verification` | Verify/refute existing pool entries | researcher |
| 3 | `methodological-critique` | Evaluate source vs. pool-entry (Mode 1) | methodological-critic |
| 4 | `contradiction-resolution` | Resolve pool conflicts | researcher |
| 5 | `deep-dive` | Primary sources, 5-10 entries | researcher |
| 6 | `adversarial-challenge` | Counter-arguments to entries or chapter args | researcher |
| 7 | `gaps-and-blind-spots` | Uncovered areas | researcher |
| 8 | `temporal-analysis` | Historical evolution | researcher |
| 9 | `cross-domain-synthesis` | Analogous problems | researcher |

Strategies rotate when consecutive iterations produce fewer than 2 contributions. Later iterations target chapter arguments (set by interleaved Phase O passes) — researcher prompts include `Target chapter argument:` lines.

## Phase Sub-Phase Reference

| Sub-phase | Per-iteration action |
|----------|----------------------|
| `Phase R: Research` | researcher agents → pool entries appended; interleaved Phase O outline pass every 5 iterations |
| `Phase S: Voice` | orchestrator writes voice-guide.md (one iteration) |
| `Phase S: Outline-Final` | final Phase O pass with full pool, lock chapter arguments (one iteration) |
| `Phase S: Write-Chapter` | narrative-writer drafts chapter `writing_chapter`, methodological-critic Mode 3 audits, writer revises (one iteration per chapter) |
| `Phase S: Write-Conclusions` | narrative-writer drafts back-loaded Conclusions (one iteration) |
| `Phase S: Write-Front-Synthesis` | narrative-writer drafts front Synthesis from finalized body (one iteration) |
| `Phase S: Read` | narrative-editor — pass 1 = IDENTIFY (always); passes 2-4 = FIX or VERIFY based on remaining HIGH issues; pass 5 = VERIFY (forced if reached). Min 2 passes, max 5. |
| `Phase S: Compile` | latex-compiler → PDF, formatting verification (one iteration) |

## Commands Reference

| Command | Description |
|---------|-------------|
| `/research-report:research` | Start or continue an autonomous research session |
| `/research-report:edit` | Edit a previously-completed report (`--target <slug>` required) |
| `/research-report:help` | Show plugin reference |
| `/research-report:record-feedback` | Record feedback about a completed report |
| `/research-report:review-learnings` | Synthesize accumulated learnings |

### Edit Phase Reference (Phase E namespace)

| Sub-phase | Per-iteration action |
|----------|----------------------|
| `Phase E: Plan` | Classify edit prompt into actions, write `edit-plan.json` (one iteration) |
| `Phase E: Research` | Targeted Phase R iteration for the current action (skipped if `research_budget == 0`) |
| `Phase E: Outline-Update` | Phase O pass to add/revise chapter args based on new pool entries |
| `Phase E: Write-Chapter` | narrative-writer drafts/rewrites the current affected chapter; methodological-critic Mode 3 audits |
| `Phase E: Rewrite-Conclusions` | Re-run back-loaded Conclusions (always, after any substantive change) |
| `Phase E: Rewrite-Front-Synthesis` | Re-run front Synthesis (always) |
| `Phase E: Read` | Reader passes (max 5 with early termination, same machinery as `Phase S: Read`) |
| `Phase E: Compile` | latex-compiler → PDF |

State for an edit is reconstructed from existing artifacts (chapter-arguments.json, evidence-pool.jsonl, voice-guide.md, report.tex, sources.bib). The edit runs an additional state file `edit-plan.json` documenting the planned actions and their progress.

## Agents Reference

| Agent | Model | Purpose |
|-------|-------|---------|
| researcher | sonnet | Strategy-aware research; produces evidence-pool entries (not prose) |
| methodological-critic | opus | Three modes: source vs. entry (1), entry vs. chapter-arg (2), prose vs. entries (3) |
| repo-analyst | sonnet | Codebase analysis when repo has code |
| narrative-writer | opus | Sequential per-section prose: body chapters, back Conclusions, front Synthesis |
| narrative-editor | opus | Reader-pass agent: IDENTIFY/FIX/VERIFY for flow without sacrificing rigor |
| latex-compiler | sonnet | LaTeX → PDF compilation, formatting verification |

## Artifact Directory Tree

```
.plugin-state/
├── research-report-<topic>-state.md     (active workflow state)
└── research-report.local.md             (optional plugin settings)

docs/research-report/<topic>/
├── <topic>-report.tex                   (final report)
├── <topic>-report.pdf                   (compiled PDF)
├── sources.bib                          (bibliography)
├── evidence-pool.jsonl                  (structured findings, one JSON per line)
├── chapter-arguments.json               (chapter-level argument hypotheses)
├── voice-guide.md                       (single-authorial-voice spec)
├── research-progress.md                 (high-level living summary, ≤500 words)
├── reader-pass-N-issues.md              (narrative-editor IDENTIFY output)
├── reader-pass-N-fixes.md               (narrative-editor FIX output)
├── reader-pass-N-verification.md        (narrative-editor VERIFY output)
└── transcripts/                         (subagent transcripts, optional)
```

## State File Format (Key Fields)

```yaml
workflow_type: research-report
name: <topic>
status: in_progress | complete
current_phase: "Phase R: Research" | "Phase S: Voice" | "Phase S: Outline-Final" | "Phase S: Write-Chapter" | "Phase S: Write-Conclusions" | "Phase S: Write-Front-Synthesis" | "Phase S: Read" | "Phase S: Compile"
iteration: <int>                          # overall counter
total_iterations_research: <int>
research_budget: <int>                    # from --research-iterations
current_research_strategy: <strategy>
research_strategies_completed: [...]
strategy_rotation_threshold: 3
contributions_last_iteration: <int>
consecutive_low_contributions: <int>
evidence_pool_count: <int>
sources_cited: <int>

# Phase O fields
last_outline_pass_iteration: <int>
outline_pass_interval: 5
chapter_arguments_count: <int>
chapter_arguments_locked: bool

# Phase S sub-phase tracking
voice_guide_written: bool
chapter_count: <int>
writing_chapter: <int>                    # 1..chapter_count, then chapter_count+1 when done
conclusions_written: bool
front_synthesis_written: bool

# Phase S Read (max 5 passes, hardcoded; no user-facing budget)
reading_iteration: <int>                  # 1..5
reading_phase: "IDENTIFY" | "FIX" | "VERIFY"
reading_passes_completed: <int>           # min 2 (IDENTIFY + VERIFY), max 5
reading_high_issues_initial: <int>        # set after IDENTIFY pass
reading_medium_issues_initial: <int>      # set after IDENTIFY pass
reading_high_issues_remaining: <int>      # updated after each FIX pass

command: |
  /research-report:research '<prompt>' --research-iterations N
```

## Completion Criteria (verified by Stop hook)

Before status: complete is accepted, the Stop hook verifies:
- `total_iterations_research >= research_budget`
- `voice_guide_written: true`
- `chapter_arguments_locked: true`
- `writing_chapter > chapter_count` (all body chapters written)
- `conclusions_written: true`
- `front_synthesis_written: true`
- `reading_passes_completed >= 2` (minimum: IDENTIFY + VERIFY)
- `current_phase: "Phase S: Compile"`

If any check fails, the hook blocks stop with an error message.

## Learnings System

The plugin writes learnings at key workflow points to help improve future runs.

### Learnings Directory Resolution
1. Read `.plugin-state/research-report.local.md` for `learnings_dir` YAML field
2. Fall back to `~/.claude/plugin-learnings/research-report/`
3. Run `mkdir -p` on first write

### Learning Write Points

| Trigger | File Pattern | Content |
|---------|--------------|---------|
| Strategy rotation (low contributions) | `YYYY-MM-DD-<topic>-strategy-rotation.md` | Which strategy underperformed and why |
| Pool entry FLAG_FOR_REMOVAL verdict | `YYYY-MM-DD-<topic>-source-quality.md` | Source quality pattern that led to removal |
| Chapter argument DOES_NOT_HOLD verdict | `YYYY-MM-DD-<topic>-chapter-argument-dropped.md` | Why a proposed argument couldn't be earned by the pool |
| Chapter audit NEEDS_REVISION (Mode 3) | `YYYY-MM-DD-<topic>-writing-revision.md` | Type of overstatement (overstatement, lost_qualification, etc.) |
| Reader-pass rigor-preservation FAIL | `YYYY-MM-DD-<topic>-reader-pass-rigor-fail.md` | What rigor element was lost |
| Workflow completion | `YYYY-MM-DD-<topic>-completion-review.md` | Retrospective: intent alignment, what worked, what to improve |

### Learning File Format
YAML frontmatter: `type: learning`, `plugin: research-report`, `workflow_topic`, `phase`, `date`. Body sections: Observation, Learning, Suggestion (most types) or Observation, Intent Alignment, What Worked Well, What Produced Lower Quality, Improvement Suggestions (completion-review).

## Dependencies

- **yq + jq**: hooks (hard dependency)
- **MacTeX / texlive**: PDF output (optional)
- **exa MCP server**: deep research (optional)
