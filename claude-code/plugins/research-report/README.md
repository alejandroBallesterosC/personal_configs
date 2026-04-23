<!-- ABOUTME: README for the research-report plugin. -->
<!-- ABOUTME: Argument-driven deep research producing a single-voice LaTeX report via evidence-pool, chapter-argument outline, sequential writing, and reader-pass iterations. -->

# research-report plugin

Argument-driven deep research producing a structured, single-voice LaTeX report. The plugin separates **evidence collection** (Phase R) from **report writing** (Phase S). Phase R harvests structured evidence-pool entries — no prose is written into the report. Phase S writes the report from the pool with a single authorial voice, sequential per-chapter writing, methodological audits at three levels, and reader-pass iterations that improve flow without sacrificing rigor.

## Why This Shape

Most research-agent reports read as bags of disjoint findings. The fix is structural: separate the evidence pool from the report, design chapter-level *arguments* (not topic buckets), write the body sequentially with a single voice, then run reader passes that improve engagement while a rigor-preservation diff prevents the editor from softening qualifications.

The output reads as a continuous argument that uses many cited sources to defend chapter-level positions, with the so-what spelled out at every level — front Synthesis (TL;DR), back Conclusions (earned argument), and an interpretive closing on every chapter.

## Workflow at a glance

```
Phase R: Research                     → evidence-pool.jsonl
  └─ interleaved Phase O outline       chapter-arguments.json (revisable hypotheses, every 5 iters)
Phase S: Voice                        → voice-guide.md
Phase S: Outline-Final                → chapter-arguments.json locked
Phase S: Write-Chapter (× N)          → body chapters, sequentially, single voice
                                         each: narrative-writer drafts → methodological-critic Mode 3 audits → writer revises
Phase S: Write-Conclusions            → back-loaded \section{Conclusions \& Recommendations}
Phase S: Write-Front-Synthesis        → front-loaded \section{Synthesis} (executive summary, written LAST)
Phase S: Read (2-5 passes)            → narrative-editor IDENTIFY → FIX × 0-3 → VERIFY (rigor-preservation diff; early termination when no HIGH issues remain)
Phase S: Compile                      → latex-compiler → PDF
```

## Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Strategy-aware research; produces structured evidence-pool entries (not prose) |
| `methodological-critic` | opus | Three modes: source vs. entry (1), entry-set vs. chapter-arg (2), prose vs. entry-set (3) |
| `repo-analyst` | sonnet | Analyzes code repositories when research involves software projects |
| `narrative-writer` | opus | Sequential per-section prose: body chapters, back Conclusions, front Synthesis |
| `narrative-editor` | opus | Reader-pass agent: IDENTIFY/FIX/VERIFY for flow without sacrificing rigor |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF, fixes formatting issues |

## Research Strategies (Phase R)

| # | Strategy | Description |
|---|---|---|
| 1 | `wide-exploration` | Broad landscape coverage |
| 2 | `source-verification` | Cross-validate existing pool entries against independent sources |
| 3 | `methodological-critique` | Evaluate whether sources actually support the pool's claims (critic Mode 1) |
| 4 | `contradiction-resolution` | Resolve conflicting pool entries with authoritative evidence |
| 5 | `deep-dive` | Focused investigation, primary sources (5-10 entries per agent) |
| 6 | `adversarial-challenge` | Find strongest counter-arguments to chapter args or pool entries |
| 7 | `gaps-and-blind-spots` | Identify uncovered areas |
| 8 | `temporal-analysis` | Historical evolution and trajectory |
| 9 | `cross-domain-synthesis` | Analogous problems from other fields |

Strategies rotate when consecutive iterations produce fewer than 2 contributions. Once Phase O has proposed chapter arguments, later iterations target them (researcher prompts include `Target chapter argument:` lines).

## Rigor model

Three layers of methodological-critic safeguards keep claims tight:

1. **Mode 1 — Source vs. Pool-Entry** (Phase R `methodological-critique` strategy): does the source actually support the entry's claim? Verdicts mutate the pool (NARROW, DOWNGRADE, WIDEN_GAP, FLAG_FOR_REMOVAL).
2. **Mode 2 — Pool-Entry Set vs. Chapter Argument** (every Phase O pass): do the cited entries jointly carry the chapter argument's weight? Catches argument-fitting before any prose is written.
3. **Mode 3 — Drafted Prose vs. Pool Entries** (every chapter audit in Phase S): does the prose stay within what entries support? Catches overstatement, lost qualifications, smuggled inferences.

Layered with the **narrative-editor's rigor-preservation rule**: no `\cite{}` may be dropped, no qualification weakened, no qualified claim turned unqualified. Verified by diff after every reader pass.

## Commands

| Command | Description |
|---|---|
| `/research-report:research` | Start or continue an autonomous iterative research session |
| `/research-report:edit` | Edit a previously-completed report with new evidence and/or chapter revisions |
| `/research-report:help` | Show plugin reference (invocation, phases, agents, costs) |
| `/research-report:record-feedback` | Record user feedback about a completed report as a learning |
| `/research-report:review-learnings` | Review and synthesize accumulated learnings from past sessions |

### Editing an existing report

```
/research-report:edit "<edit prompt>" --target <slug> [--research-iterations N]
```

`--target <slug>` is required (slug is the report's directory name under `docs/research-report/`). Default research budget is 10 iterations — edits typically need much less than full reports.

The edit command classifies the prompt into actions and runs the affected slice of the pipeline:

| Action type | Triggered by | What runs |
|------------|--------------|-----------|
| `ADD_CHAPTER` | "Add a chapter on X" | Targeted Phase R → Phase O insert → Write the new chapter |
| `REVISE_CHAPTER` | "Make Chapter 3 more skeptical" | Optional targeted Phase R → Rewrite the chapter with revision instructions |
| `EXPAND_RESEARCH` | "Update with developments since the original research" | Phase R targeted at themes → affected chapters re-written |
| `POLISH` | "Tighten Chapter 5" | Skip research; chapter rewrite |

After all actions finish, the edit ALWAYS re-runs Conclusions, Front Synthesis, and Reader passes, then recompiles the PDF — so a small substantive edit produces a coherent finished report, not a Frankenstein.

State is reconstructed from artifacts each edit (no persistent state file between edits). Phases are routed via a new `Phase E:` namespace (Plan → Research → Outline-Update → Write-Chapter → Rewrite-Conclusions → Rewrite-Front-Synthesis → Read → Compile).

## Invocation

```
/research-report:research "<prompt>" [--research-iterations N]
```

The topic name is derived automatically from the prompt as a kebab-case slug — no need to pass it explicitly. Re-running the command while another workflow is in progress resumes that workflow regardless of what prompt is passed.

- `--research-iterations N`: total Phase R iteration budget (default 30). Each iteration runs one strategy plus optional Phase O outline pass.

Reader passes in Phase S are **hardcoded at a maximum of 5 with early termination** — no flag. The orchestrator decides each pass's mode (IDENTIFY → FIX × 0-3 → VERIFY) based on what the prior pass found. Minimum 2 passes (IDENTIFY + VERIFY) when the draft is clean; maximum 5 (IDENTIFY + 3 FIX + VERIFY) when issues persist.

**Cost estimate:** ~$1.00–$5.00 per Phase R iteration; Phase S costs scale with chapter count and reader-pass count (typically $5-30 total Phase S). A 30-iteration run costs approximately $40-150. Long deep-research runs (100+ Phase R iterations) suit 6-24 hour sessions and may run $150-500. Set `--research-iterations` explicitly to control spend.

## Learnings System

After each session the plugin writes structured learnings capturing:

- Which strategies produced the highest-quality findings
- Source quality patterns (domains flagged for removal)
- Chapter arguments that didn't survive the pool (DOES_NOT_HOLD)
- Writing-revision patterns (overstatement, lost_qualification, etc.)
- Reader-pass rigor-preservation failures
- Per-session retrospectives

**Storage location:** `~/.claude/plugin-learnings/research-report/`

**Per-project override:** Create `.plugin-state/research-report.local.md` in the project root with YAML frontmatter:

```yaml
---
learnings_dir: /path/to/custom/learnings/dir
---
```

Use `/research-report:review-learnings` to synthesize accumulated learnings into actionable patterns.

## Artifacts

```
.plugin-state/research-report-<topic>-state.md
docs/research-report/<topic>/
├── <topic>-report.tex
├── <topic>-report.pdf
├── sources.bib
├── evidence-pool.jsonl              # structured findings, one JSON per line
├── chapter-arguments.json           # chapter-level argument hypotheses
├── voice-guide.md                   # single-authorial-voice spec
├── research-progress.md
├── reader-pass-N-{issues,fixes,verification}.md
└── transcripts/
```

## Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `yq` | Required | YAML parsing in stop hook and auto-resume hook |
| `jq` | Required | JSON parsing in stop hook |
| `MacTeX` / `texlive` | Optional | PDF compilation via `latex-compiler` agent |
| `exa` MCP server | Optional | Web search and deep research for `researcher` agent |

Install required tools on macOS:

```bash
brew install yq jq
```

If MacTeX is not installed, the plugin produces a `.tex` source file and skips PDF compilation.
