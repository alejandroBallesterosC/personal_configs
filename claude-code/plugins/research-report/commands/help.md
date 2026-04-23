<!-- ABOUTME: Help command for the research-report plugin. -->
<!-- ABOUTME: Quick reference for invocation, phases (R + S sub-phases), strategies, agents, budgets, dependencies, learnings. -->

---
description: Show research-report plugin reference covering invocation, Phase R + Phase S sub-phases, strategies, agents, budget flags, dependencies, learnings, and cost estimates
model: haiku
---

Print the following reference for the research-report plugin:

---

## research-report plugin — Quick Reference

### Invocation

```
/research-report:research "<prompt>" [--research-iterations N]
```

Start or continue an autonomous research session producing an argument-driven LaTeX report. The topic name is derived from the prompt automatically (kebab-case slug). Re-running the command while another workflow is in progress resumes that one. The plugin manages iteration state automatically via its Stop hook. After a `/compact` or `/clear`, the SessionStart hook restores context so the session continues seamlessly.

### Workflow

The pipeline separates **evidence collection** (Phase R) from **report writing** (Phase S):

**Phase R — Research (evidence collection)**
- Each iteration runs one of 9 rotating research strategies
- Researchers append structured entries to `evidence-pool.jsonl` (no prose written into report)
- Every 5 iterations, an interleaved Phase O outline pass proposes/revises chapter-level argument hypotheses (with methodological-critic Mode 2 validation)
- Continues until `--research-iterations` budget is exhausted

**Phase S — Sub-phases (writing the report)**
| Sub-phase | Action |
|----------|--------|
| Voice | Write `voice-guide.md` — single-authorial-voice spec |
| Outline-Final | Lock chapter arguments based on full pool |
| Write-Chapter (× N) | Sequential per-chapter writing: narrative-writer drafts → methodological-critic Mode 3 audits → writer revises |
| Write-Conclusions | Back-loaded `\section{Conclusions \& Recommendations}` |
| Write-Front-Synthesis | Front-loaded `\section{Synthesis}` (written LAST, reflects what was actually argued) |
| Read (2-5 passes) | narrative-editor: IDENTIFY → FIX × 0-3 → VERIFY (early terminates when no HIGH issues remain), with rigor-preservation diff |
| Compile | latex-compiler → PDF |

### Research Strategies

| # | Strategy | Focus |
|---|---|---|
| 1 | `wide-exploration` | Broad coverage |
| 2 | `source-verification` | Cross-validate pool entries |
| 3 | `methodological-critique` | Evaluate sources vs. pool claims (critic Mode 1) |
| 4 | `contradiction-resolution` | Resolve pool conflicts |
| 5 | `deep-dive` | Primary sources, 5-10 entries |
| 6 | `adversarial-challenge` | Counter-arguments |
| 7 | `gaps-and-blind-spots` | Uncovered areas |
| 8 | `temporal-analysis` | Topic evolution |
| 9 | `cross-domain-synthesis` | Analogous problems |

### Agents

| Agent | Model | Role |
|---|---|---|
| `researcher` | sonnet | Strategy-aware research; produces evidence-pool entries (not prose) |
| `methodological-critic` | opus | Three modes: source-entry (1), entry-set vs. chapter-arg (2), prose vs. entries (3) |
| `repo-analyst` | sonnet | Analyzes code repositories |
| `narrative-writer` | opus | Sequential per-section prose: body, back Conclusions, front Synthesis |
| `narrative-editor` | opus | Reader-pass: IDENTIFY/FIX/VERIFY without sacrificing rigor |
| `latex-compiler` | sonnet | Compiles LaTeX to PDF |

### Budget Flag

```
/research-report:research "<prompt>" --research-iterations 30
```

- `--research-iterations N`: total Phase R iterations (default 30)

Reader passes in Phase S are hardcoded at max 5 with early termination — no flag.

Cost: ~$1-5/Phase R iter; ~$5-30 total Phase S; long 100+ research-iter runs ~$150-500.

### Commands

| Command | Description |
|---|---|
| `research-report:research` | Start or continue a research session |
| `research-report:edit` | Edit a completed report (`--target <slug>` required, `--research-iterations N` defaults to 10) |
| `research-report:help` | Show this reference |
| `research-report:record-feedback` | Record feedback about a completed report |
| `research-report:review-learnings` | Synthesize accumulated learnings |

### Editing

```
/research-report:edit "<edit prompt>" --target <slug> [--research-iterations N]
```

Edit prompt is classified into one or more actions: ADD_CHAPTER, REVISE_CHAPTER, EXPAND_RESEARCH, POLISH. Always re-runs Conclusions, Front Synthesis, Reader passes, and Compile. Phase E namespace: Plan → Research → Outline-Update → Write-Chapter → Rewrite-Conclusions → Rewrite-Front-Synthesis → Read → Compile.

### Learnings System

Learnings stored at `~/.claude/plugin-learnings/research-report/`. Override per-project via `.plugin-state/research-report.local.md` with YAML field `learnings_dir`. Use `research-report:review-learnings` to synthesize patterns.

### Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `yq` | Required | YAML parsing in hooks |
| `jq` | Required | JSON parsing in hooks |
| MacTeX / texlive | Optional | PDF compilation |
| exa MCP server | Optional | Web search |
