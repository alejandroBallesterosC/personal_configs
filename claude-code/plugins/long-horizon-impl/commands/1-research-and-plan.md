---
description: "Long-horizon-impl deep research followed by scoping interview + rigorous 4-artifact planning (requirements, architecture, test plan, implementation plan) with cross-examination"
model: opus
argument-hint: <project-name> "Your detailed research and planning prompt..." --research-iterations N --plan-iterations N
---

# ABOUTME: Research-and-plan command for the long-horizon-impl plugin that runs research (Phase A) then scoping interview (B0) + rigorous 4-phase planning (Phase B).
# ABOUTME: Phase B0 generates scoping questions from research, pauses for human input, then resumes.
# ABOUTME: Phase B produces: functional requirements, architecture plan, test plan, implementation plan.
# ABOUTME: Final sub-phase cross-examines all artifacts against each other before marking complete.

# Autonomous Research + Plan

**Project**: $1
**Prompt**: $2
**All Arguments**: $ARGUMENTS

Parse optional flags from **All Arguments**:
- `--research-iterations N`: number of research iterations before transitioning to planning (default: 30)
- `--plan-iterations N`: number of planning iterations across ALL sub-phases (default: 20)

## Objective

Run ONE ITERATION of research (Phase A) or planning (Phase B) for the given project. The workflow transitions from research to planning when the research iteration budget is exhausted. Phase B has 5 sub-phases (B0-B4) that produce distinct artifacts. The Stop hook re-feeds this command for multi-iteration execution.

**REQUIRED**: Use the Skill tool to invoke `long-horizon-impl:long-horizon-impl-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `.plugin-state/lhi-$1-research-state.md` exists.

### If state file does NOT exist (first iteration):

1. Create directory structure:
   ```
   docs/long-horizon-impl/$1/research/
   docs/long-horizon-impl/$1/research/transcripts/
   ```

2. Read the report template from the plugin:
   - Use Glob to find `**/long-horizon-impl/templates/report-template.tex`
   - Read the report template, replace `PLACEHOLDER_TITLE` with a research-focused title
   - Write to `docs/long-horizon-impl/$1/research/$1-report.tex`
   - Do NOT create any planning artifacts yet — they get created during Phase B sub-phases

3. Create empty bibliography file `docs/long-horizon-impl/$1/research/sources.bib`

4. Create `docs/long-horizon-impl/$1/research/research-progress.md` following the research-progress format (including the `## Methodological Quality` section for tracking evidence gap counts).

5. Parse budgets:
   - `research_budget` from `--research-iterations` (default: 30)
   - `planning_budget` from `--plan-iterations` (default: 20)

6. Create state file `.plugin-state/lhi-$1-research-state.md`:
   ```yaml
   ---
   workflow_type: lhi-research-plan
   name: $1
   status: in_progress
   current_phase: "Phase A: Research"
   iteration: 1
   total_iterations_research: 0
   total_iterations_planning: 0
   sources_cited: 0
   findings_count: 0
   research_budget: <parsed>
   planning_budget: <parsed>
   current_research_strategy: wide-exploration
   research_strategies_completed: []
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   planning_sub_phase: null
   planning_sub_phase_iteration: 0
   command: |
     /long-horizon-impl:1-research-and-plan <the full invocation command>
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase A: Research

   ## Original Prompt
   $2

   ## Completed Phases
   - [ ] Phase A: Research
   - [ ] Phase B0: Scoping Interview
   - [ ] Phase B1: Functional Requirements
   - [ ] Phase B2: Architecture
   - [ ] Phase B3: Test Plan + Implementation Plan
   - [ ] Phase B4: Cross-Examination

   ## Research Progress
   - Sources consulted: 0
   - Key findings: 0
   - Open questions: 5
   - Sections in report: 0

   ## Strategy History
   | Strategy | Iterations | Contributions | Rotated At |
   |----------|-----------|---------------|------------|

   ## Planning Progress
   - Sub-phase: Not started
   - Artifacts complete: 0/4
   - Blocker issues: 0

   ## Open Questions
   1. [Derive 5 initial questions focused on technical feasibility, competitive landscape, architecture patterns, defensibility, and technology stack]

   ## Context Restoration Files
   1. .plugin-state/lhi-$1-research-state.md (this file)
   2. docs/long-horizon-impl/$1/research/$1-report.tex
   3. docs/long-horizon-impl/$1/planning/$1-scoping-questions.md (after B0)
   4. docs/long-horizon-impl/$1/planning/$1-functional-requirements.md (after B1)
   5. docs/long-horizon-impl/$1/planning/$1-architecture-plan.md (after B2)
   6. docs/long-horizon-impl/$1/planning/$1-test-plan.md (after B3)
   7. docs/long-horizon-impl/$1/planning/$1-implementation-plan.md (after B3)
   8. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file and extract `current_phase` and `planning_sub_phase`
2. Read `docs/long-horizon-impl/$1/research/$1-report.tex`
3. If Phase B: also read whatever planning artifacts exist
4. Proceed to the appropriate phase below

---

## PHASE A: Research Iteration

If `current_phase` is `"Phase A: Research"`:

### Research Focus

Researcher agents should focus on topics directly relevant to building a software product:
- Technical feasibility of the proposed approach
- Existing solutions and competitive landscape
- Architecture patterns used by similar systems
- Defensibility and moat analysis
- Technology stack evaluation and trade-offs

### Step A1: Empty Repo Detection

Before spawning repo-analyst agents, check if the repo has meaningful non-research content:

Use Glob to search for files matching `**/*.py`, `**/*.ts`, `**/*.js`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.c`, `**/*.cpp`, `**/*.swift` (code files). Exclude anything under `docs/long-horizon-impl/*`.

- If code files found: spawn repo-analyst agents in Step A2
- If NO code files found: skip repo-analyst agents entirely

### Step A2: Spawn Parallel Research Agents (Strategy-Dependent)

Read `current_research_strategy` from the state file YAML. Dispatch agents based on the active strategy.

#### Strategy Dispatch Table

| Strategy | Agents | Prompt Focus | Output |
|----------|--------|-------------|--------|
| `wide-exploration` | 3-5 | Different broad questions (default behavior) | Standard 200-500 words |
| `source-verification` | 3-4 | Each verifies 2-3 existing claims from report against independent sources | Standard + Verification Results (CONFIRMED/REFUTED/INCONCLUSIVE) |
| `methodological-critique` | 2-3 | Each evaluates 2-3 source-claim pairs from the report | Standard + Methodological Evaluation |
| `contradiction-resolution` | 2-3 | Each resolves 1-2 contradictions from open questions | Standard + Resolution Analysis |
| `deep-dive` | 2-3 | Single high-value topic per agent, primary sources | Expanded 800 words |
| `adversarial-challenge` | 3-4 | Each challenges a key conclusion from the report | Standard + Counter-Argument Strength (STRONG/MODERATE/WEAK) |
| `gaps-and-blind-spots` | 3-4 | Each investigates an uncovered area | Standard + Relevance Assessment (HIGH/MEDIUM/LOW) |
| `temporal-analysis` | 3-4 | Historical evolution, recent developments, future trajectory | Standard + Timeline section |
| `cross-domain-synthesis` | 3-4 | Analogous problems in other fields, applicable frameworks | Standard + Cross-Domain Mapping section |

#### Agent Prompt Format

Each agent's prompt MUST include:
1. A `Strategy: <name>` line so the researcher agent knows how to behave
2. Strategy-specific instructions (see strategy descriptions below)
3. Context about the current research state (iteration number, existing coverage, etc.)

```
Task tool with subagent_type='long-horizon-impl:researcher'
prompt: "Strategy: <current_research_strategy>

Research question: <specific question derived from strategy>

Context: This is iteration N of a deep research project on '<topic>'. Current strategy: <strategy>. Previous findings have covered: <brief summary of sections already written>. Focus on: <strategy-specific focus>.

<Strategy-specific instructions — see below>

Return findings in the structured format appropriate for this strategy."
```

#### Strategy-Specific Agent Instructions

**wide-exploration**: Derive 3-5 specific research questions from the original prompt, open questions in the state file, gaps identified in the report, claims that need verification, and contradictions that need resolution. Standard researcher behavior.

**source-verification**: Read the current report and identify 6-10 claims. Assign 2-3 claims to each agent. Agent must find independent sources (NOT already cited in the report) that confirm or refute each claim. Agent adds `### Verification Results` section with CONFIRMED/REFUTED/INCONCLUSIVE per claim.

**contradiction-resolution**: Read the Open Questions section and identify contradictions. Assign 1-2 contradictions per agent. Agent must find authoritative sources that settle the disagreement. Agent adds `### Resolution Analysis` section.

**deep-dive**: Identify 2-3 high-value topics that have only surface-level coverage. Assign one topic per agent. Agent produces expanded 800-word output. Agent should prefer primary sources and use `deep_researcher_start` preferentially.

**adversarial-challenge**: Read the report's key conclusions. Assign 1-2 conclusions per agent. Agent must find the strongest counter-arguments (not strawmen). Agent adds `### Counter-Argument Strength` section (STRONG/MODERATE/WEAK).

**gaps-and-blind-spots**: Identify uncovered areas: missing perspectives, unexplored adjacent domains, methodological gaps. Assign one area per agent. Agent adds `### Relevance Assessment` section (HIGH/MEDIUM/LOW).

**temporal-analysis**: Identify key topics. Assign agents to investigate: historical evolution, recent developments, emerging trends, future trajectory. Agent adds `### Timeline` section.

**cross-domain-synthesis**: Identify the core problem structure. Assign agents to investigate analogous problems in other fields (e.g., if researching blockchain scalability, look at how distributed databases solved similar problems). Agent adds `### Cross-Domain Mapping` section with explicit mapping from analogous domain to research domain.

**methodological-critique**: Read the current report and `sources.bib`. Identify the 6-8 most consequential source-claim pairs (claims that drive major conclusions or recommendations). Assign 2-3 pairs per agent. Use the `methodological-critic` agent type instead of the standard `researcher` agent type:

```
Task tool with subagent_type='long-horizon-impl:methodological-critic'
prompt: "Evaluate these source-claim pairs from the research report.

Report: docs/long-horizon-impl/$1/research/$1-report.tex
Sources: docs/long-horizon-impl/$1/research/sources.bib

Source-claim pairs to evaluate:
1. Source [key1]: Claim '[claim text from report]'
2. Source [key2]: Claim '[claim text from report]'
3. Source [key3]: Claim '[claim text from report]'

For each, assess: what the source actually proves vs. what the report claims from it, load-bearing assumptions, regime-dependency, and the evidence-to-claim gap. Identify the surviving insight from each source."
```

After receiving evaluations, apply verdicts to the report:
- **KEEP_AS_IS**: No change needed
- **NARROW_THE_CLAIM**: Rewrite the claim in the report to match the narrower valid interpretation. Update the prose to state the boundary conditions.
- **DOWNGRADE_CONFIDENCE**: Add qualification language ("under conditions X, evidence suggests..." rather than "research shows...")
- **FLAG_FOR_REMOVAL**: Remove the claim if no surviving insight exists, or replace with the surviving insight if one was identified.

Count changes as contributions: each NARROW/DOWNGRADE/REMOVAL counts as one contribution.

When a **FLAG_FOR_REMOVAL** verdict is issued, write a learning about the source quality pattern:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-source-quality.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: methodological-critique
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: What source was flagged, what claim it supported, and the verdict rationale.
   - **Learning**: The pattern — what made this source unreliable or the claim unsupported (e.g., source type, methodology weakness, scope mismatch).
   - **Suggestion**: How to avoid similar issues in future research (e.g., prefer primary sources for X-type claims, verify sample sizes for quantitative claims).

#### Repo-Analyst Agents (0-2 in parallel, if applicable)

If Step A1 found code files, spawn 1-2 repo-analyst agents in the SAME message as researchers:

```
Task tool with subagent_type='long-horizon-impl:repo-analyst'
prompt: "Analyze how the codebase relates to: <specific aspect of the research topic>"
```

#### CRITICAL: Never search the web yourself.

ALL web interaction happens in researcher subagents. The main instance receives ONLY compressed summaries. This prevents context bloat from raw web content.

Launch ALL agents in a SINGLE message with multiple Task tool calls to maximize parallelism.

### Step A3: Synthesize Findings

After all agents return:

1. Read each agent's output (they return structured summaries)
2. Identify:
   - Findings that are consistent across multiple agents (high confidence)
   - Contradictions between agents (need resolution)
   - Gaps not covered by any agent
   - Claims that need further verification
3. Count contributions across 5 types:
   - **New findings** — information not already in the report
   - **Claims verified or refuted** — existing findings confirmed/refuted by new sources
   - **Contradictions resolved** — conflicting information settled with evidence
   - **Depth additions** — existing findings expanded with non-redundant detail/nuance
   - **Source quality upgrades** — weak sources replaced with stronger ones
4. Sum all types to get `contributions_this_iteration`

#### Step A3.5: Internal Consistency Audit

Before updating the report, audit the current report against the new findings for consistency:

1. **New-vs-existing check**: For each new finding, check whether it contradicts any existing section of the report. If it does:
   - Determine which has stronger evidence (more sources, higher credibility, more recent)
   - The weaker claim must be updated or removed — do NOT leave both standing as separate conclusions
   - Note the resolution in the `\section{Open Questions}` if confidence is not high

2. **Cross-section consistency check**: Verify that:
   - No Key Finding subsection contradicts another Key Finding subsection
   - The Analysis & Synthesis section's patterns are consistent with Key Findings
   - If genuinely mixed evidence exists, it must be presented as nuance in a single location, not as contradictory claims in separate sections. Use the pattern: "Evidence suggests X; however Y — on balance, Z."

3. **Evidence gap audit** (during `methodological-critique` strategy iterations):
   - For each claim modified by the methodological-critic (NARROW/DOWNGRADE/REMOVE), verify the change is reflected consistently across all sections that reference the same source.
   - Update the `## Methodological Quality` section of research-progress.md with current gap counts.

4. **Deep consistency audit** (every 5th iteration, i.e., when `total_iterations_research` is a multiple of 5):
   - Re-read the ENTIRE report from start to finish
   - List all major claims and conclusions made across all sections
   - Check each pair of claims for logical consistency
   - Resolve any contradictions found by updating the weaker claim
   - Update confidence levels across the report if new evidence has shifted the balance

### Step A4: Update LaTeX Report

1. Read the current `docs/long-horizon-impl/$1/research/$1-report.tex`
2. Read the formatting rules in the template comments (between the `FORMATTING RULES` markers near the top of the document). Follow them strictly.
3. Integrate new findings into the appropriate sections:
   - Add new findings to `\section{Key Findings}` as subsections
   - Update `\section{Analysis \& Synthesis}` with cross-cutting patterns
   - Add unresolved items to `\section{Open Questions}`
   - Update `\section{Methodology}` with iteration count and source count
4. Write the updated `.tex` file

#### CRITICAL: Document Formatting Rules

**Readability is non-negotiable.** The report must be easy to scan and read as a PDF. Follow these rules for ALL content:

1. **No wall-of-text paragraphs.** Maximum 4-5 sentences per paragraph. If a paragraph has more, split it.
2. **Use `\begin{itemize}` or `\begin{enumerate}`** for ANY list of 3+ related items. Do NOT embed lists as inline comma-separated items in a sentence.
3. **Use `\textbf{bold lead-ins}`** for list items that have a label + explanation pattern:
   ```latex
   \begin{itemize}
     \item \textbf{Market timing:} Evidence suggests the dental AI market is at an early-majority inflection \cite{McKinsey_2024_DentalAI}.
     \item \textbf{Competitive dynamics:} Three categories of competitors are converging \cite{ADA_2025_TechReport}.
   \end{itemize}
   ```
4. **Use `\subsubsection{}`** to break up any section that exceeds ~1 page of content.
5. **One point per paragraph.** State the claim, provide evidence, note confidence — then start a new paragraph for the next point.
6. **Whitespace is your friend.** Leave blank lines between paragraphs in the `.tex` source. LaTeX paragraph spacing handles the rest.
7. **Never write a single paragraph longer than ~150 words.** If you catch yourself doing this, stop and restructure with bullets or sub-sections.

#### In-Line Citation Rules

Every factual claim in the report MUST have an in-line `\cite{key}` reference. Follow these rules:

1. **Converting researcher output to BibTeX**: Each researcher agent returns structured source entries with a `key` field (format: `AuthorOrOrg_Year_ShortTopic`). Convert each to a BibTeX entry:
   ```bibtex
   @article{AuthorOrOrg_Year_ShortTopic,
     title = {Article Title},
     author = {Author Name or Organization},
     year = {2024},
     url = {https://...},
     note = {Type: article/report/blog. Credibility note here.}
   }
   ```
   Use `@misc` for web content, `@article` for journal papers, `@techreport` for reports/whitepapers.

2. **Deduplication**: Before adding a new BibTeX entry to `sources.bib`, check if an entry with the same URL already exists. If it does, reuse the existing key — do NOT create a duplicate entry. If the same source appears with a slightly different URL (e.g., with/without trailing slash, with tracking parameters), treat it as the same source.

3. **In-line citation placement**: Place `\cite{key}` immediately after the claim it supports. For claims supported by multiple sources, use `\cite{key1, key2}`. Examples:
   - "DSOs process 40\% of dental claims nationally \cite{ADA_2024_ClaimsData}."
   - "Automated RCM reduces denial rates by 15-30\% \cite{McKinsey_2024_DentalAI, Becker_2024_RCMBenchmarks}."

4. **Coverage requirement**: Every entry in `sources.bib` MUST appear as a `\cite{}` somewhere in the report (no orphan references). Every factual claim in Key Findings and Analysis \& Synthesis MUST have at least one `\cite{}`.

5. Update `docs/long-horizon-impl/$1/research/sources.bib` with new BibTeX entries (after dedup check)

#### Synthesis Section — Placeholder During Phase A

During Phase A (research iterations), do NOT write content into the `\section{Synthesis}`. Leave it as a placeholder:

```latex
\section{Synthesis}
% Synthesis will be written after research completes and planning begins.
\textit{This section will be written after all research iterations are complete.}
```

#### Update research-progress.md

After updating the report, update `docs/long-horizon-impl/$1/research/research-progress.md` with:

1. **Major Themes/Findings**: Bullet points of the main themes discovered so far
2. **Well-Supported vs. Thin**: Which findings have strong multi-source evidence vs. which are still single-source or shallow
3. **Open Contradictions**: Any unresolved contradictions between sources or findings
4. **Research Direction**: What the next iterations should focus on

**Hard limit**: research-progress.md must never exceed 500 words / ~3000 characters. If it grows beyond that, trim older or less important items to stay within the limit. This file is a living summary, not a log.

**LaTeX formatting rules**:
- Escape special characters in content: `\%`, `\&`, `\$`, `\#`, `\_`, `\^{}`, `\{`, `\}`, `\textasciitilde{}`
- Use `\url{...}` for URLs (requires hyperref package, already included)
- Organize findings thematically, NOT chronologically
- Each finding subsection should have: claim, evidence with `\cite{}` references, confidence level
- **NEVER write a paragraph longer than 5 sentences or ~150 words**
- **ALWAYS use `\begin{itemize}` or `\begin{enumerate}` for lists** — never inline lists as comma-separated items in prose

### Step A5: Update State File

Update `.plugin-state/lhi-$1-research-state.md`:

1. Increment `iteration` by 1
2. Update `total_iterations_research`
3. Update `sources_cited` (total unique sources across all iterations)
4. Update `findings_count` (total substantive findings in report)
5. Set `contributions_last_iteration` to the total from Step A3
6. Update `consecutive_low_contributions`:
   - If `contributions_last_iteration < 2`: increment `consecutive_low_contributions`
   - Otherwise: reset `consecutive_low_contributions` to 0
7. Update the `## Strategy History` table with this iteration's strategy and contribution count
8. Update the `## Open Questions` section with new questions and remove answered ones
9. Update `## Research Progress` counts

### Step A6: Strategy Rotation Check

Check if the current strategy has reached diminishing returns and should rotate.

If `consecutive_low_contributions >= strategy_rotation_threshold`:

1. Add `current_research_strategy` to `research_strategies_completed`
2. Log to `## Strategy History`: strategy name, iterations spent, total contributions, rotation iteration number

3. If ALL 9 strategies are in `research_strategies_completed`:
   - Clear `research_strategies_completed` to `[]`
   - Set `current_research_strategy` to `wide-exploration`
   - Reset `consecutive_low_contributions` to 0
   - Send notification:
     ```
     Run via Bash: osascript -e 'display notification "Strategy cycle complete for $1 — restarting from wide-exploration" with title "Long Horizon Impl" subtitle "Research"'
     ```
   - Log "--- Cycle N restart ---" to Strategy History table

4. Else:
   - Pick next strategy from the fixed order NOT in `research_strategies_completed`:
     1. `wide-exploration`
     2. `source-verification`
     3. `methodological-critique`
     4. `contradiction-resolution`
     5. `deep-dive`
     6. `adversarial-challenge`
     7. `gaps-and-blind-spots`
     8. `temporal-analysis`
     9. `cross-domain-synthesis`
   - Set `current_research_strategy` to the next strategy
   - Reset `consecutive_low_contributions` to 0
   - Send notification:
     ```
     Run via Bash: osascript -e 'display notification "Rotating research strategy to <new_strategy> for $1" with title "Long Horizon Impl" subtitle "Research"'
     ```

#### Strategy Rotation Learnings

When rotation is triggered due to low contributions, write a learning about which strategy underperformed:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-strategy-rotation.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: strategy-rotation
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: Which strategy was rotated away from, how many iterations it ran, and how many contributions it produced (include the specific counts from the Strategy History table).
   - **Learning**: Why the strategy likely underperformed in this context (e.g., topic already well-covered by previous strategies, limited available sources for this approach, strategy not well-suited to this topic type).
   - **Suggestion**: When this strategy might be more productive (e.g., earlier in the research cycle, for topics with more primary sources, after more contradictions have accumulated).

### Step A7: Identify Next Research Directions

Based on the current strategy, write 3-5 prioritized research directions for the next iteration. These become the open questions in the state file and guide the next iteration's researcher agent prompts.

#### Direction Priorities by Strategy

**wide-exploration**: Contradictions that need resolution, claims with low confidence needing verification, gaps in coverage, follow-up questions from agents, deeper dives into important findings.

**source-verification**: Claims with lowest confidence scores, single-source claims, high-impact claims whose truth significantly affects conclusions.

**contradiction-resolution**: Explicit contradictions in Open Questions, agent-reported conflicts, claims where sources disagree on key details.

**deep-dive**: Thinnest sections of the report, surface-level-only findings, prompt-specific depth requests.

**adversarial-challenge**: Strongest/most confident conclusions first, implementation-critical conclusions, claims the report treats as settled.

**gaps-and-blind-spots**: Missing perspectives (stakeholder groups not considered), unexplored adjacent domains, methodological gaps (types of evidence not yet gathered).

**temporal-analysis**: Key turning points in the domain, most recent shifts in understanding, emerging trends, historical precedents that inform current state.

**cross-domain-synthesis**: Most structurally similar problems in other fields, frameworks from other domains that map cleanly to this research domain.

**Note: Phase A does NOT have a separate synthesis sub-phase. It transitions directly to Phase B.**

### Phase Transition Check

After updating the state file and checking strategy rotation, check:

If `total_iterations_research >= research_budget`:

1. **Compile research report to PDF**:
   Spawn `long-horizon-impl:latex-compiler` agent:
   ```
   Task tool with subagent_type='long-horizon-impl:latex-compiler'
   prompt: "Compile docs/long-horizon-impl/$1/research/$1-report.tex to PDF. The working directory is docs/long-horizon-impl/$1/research/."
   ```

2. **Send macOS notification**:
   ```
   Run via Bash: osascript -e 'display notification "Research budget reached — transitioning to planning" with title "Long Horizon Impl" subtitle "$1"'
   ```

3. **Create planning directory**:
   - Create `docs/long-horizon-impl/$1/planning/`
   - Create `docs/long-horizon-impl/$1/planning/transcripts/`

4. **Update research state**:
   - Mark Phase A as complete in the checklist
   - Set `status: complete` in `.plugin-state/lhi-$1-research-state.md`

5. **Create implementation state file** at `.plugin-state/lhi-$1-implementation-state.md`:
   ```yaml
   ---
   workflow_type: lhi-research-plan
   name: $1
   status: in_progress
   current_phase: "Phase B: Planning"
   iteration: <current iteration + 1>
   total_iterations_research: <from research state>
   total_iterations_planning: 0
   sources_cited: <from research state>
   findings_count: <from research state>
   research_budget: <from research state>
   planning_budget: <from research state>
   current_research_strategy: <from research state>
   research_strategies_completed: <from research state>
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   planning_sub_phase: "B0"
   planning_sub_phase_iteration: 0
   command: |
     <same command from research state>
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase B: Planning (Sub-phase B0: Scoping Interview)

   ## Original Prompt
   <copied from research state>

   ## Completed Phases
   - [x] Phase A: Research
   - [ ] Phase B0: Scoping Interview
   - [ ] Phase B1: Functional Requirements
   - [ ] Phase B2: Architecture
   - [ ] Phase B3: Test Plan + Implementation Plan
   - [ ] Phase B4: Cross-Examination

   ## Planning Progress
   - Sub-phase: B0 (Scoping Interview)
   - Sub-phase iteration: 0
   - Artifacts complete: 0/4
   - Blocker issues: 0

   ## Context Restoration Files
   1. .plugin-state/lhi-$1-implementation-state.md (this file)
   2. docs/long-horizon-impl/$1/research/$1-report.tex
   3. docs/long-horizon-impl/$1/planning/$1-scoping-questions.md (after B0)
   4. docs/long-horizon-impl/$1/planning/$1-functional-requirements.md (after B1)
   5. docs/long-horizon-impl/$1/planning/$1-architecture-plan.md (after B2)
   6. docs/long-horizon-impl/$1/planning/$1-test-plan.md (after B3)
   7. docs/long-horizon-impl/$1/planning/$1-implementation-plan.md (after B3)
   8. CLAUDE.md
   ```

6. **Continue to Phase B** in this same iteration (do not exit yet)

### PHASE A OUTPUT

After completing one research iteration (when NOT transitioning to Phase B), output a brief summary:

```
## Iteration N Complete (Phase A: Research)

### Strategy: [current_research_strategy]
### Contributions This Iteration: [count]
- New findings: [count]
- Verifications: [count]
- Contradictions resolved: [count]
- Depth additions: [count]
- Source upgrades: [count]

### Sources Added: [count]
### Open Questions Remaining: [count]
### Strategy Progress: [completed_count]/9 strategies in current cycle
### Consecutive Low-Contribution Iterations: [N]/[threshold]

### Next Iteration Focus:
- Strategy: [current or next strategy]
- [Top 3 research directions]
```

---

## PHASE B: Planning

If `current_phase` is `"Phase B: Planning"`:

Read `planning_sub_phase` from the state file to determine which sub-phase to execute. The sub-phases execute in strict order: B0 -> B1 -> B2 -> B3 -> B4.

### Sub-Phase Budget Allocation

The total `planning_budget` is distributed across sub-phases B1-B4 (B0 uses 1 iteration and does not consume the planning budget). Use this allocation:

| Sub-Phase | % of Budget | Default (budget=20) | Purpose |
|-----------|-------------|---------------------|---------|
| B0: Scoping Interview | N/A (1 iteration) | 1 iteration | Generate questions, pause for human input |
| B1: Requirements | 20% | 4 iterations | Derive and refine functional requirements |
| B2: Architecture | 30% | 6 iterations | Design component architecture |
| B3: Test Plan + Implementation Plan | 25% | 5 iterations | Create test plan and implementation plan |
| B4: Cross-Examination | 25% | 5 iterations | Cross-examine all artifacts, resolve issues |

Calculate sub-phase budgets at the start of Phase B (when `planning_sub_phase` is "B0"):
```
b1_budget = ceil(planning_budget * 0.20)
b2_budget = ceil(planning_budget * 0.30)
b3_budget = ceil(planning_budget * 0.25)
b4_budget = planning_budget - b1_budget - b2_budget - b3_budget
```

Store these in the state file under `## Sub-Phase Budgets`.

---

### SUB-PHASE B0: Scoping Interview

**Goal**: Generate research-informed scoping questions, then pause for human answers.

This sub-phase runs exactly ONCE (1 iteration), produces a questions document, and sets the workflow to `waiting_for_input` so the stop hook allows Claude Code to exit. The human (via the orchestrator) answers the questions, then nudges the session to resume.

#### B0 — Execution

1. **Read the full research report** and the original prompt
2. **Read research-progress.md** for the high-level summary of what's well-supported vs. thin

3. **Generate scoping questions** organized by domain. These should be:
   - Grounded in research findings (not generic)
   - Focused on decisions that affect architecture, scope, and implementation
   - Specific enough that the answers directly inform requirements
   - Challenging where appropriate — push back on unstated assumptions

Write to `docs/long-horizon-impl/$1/planning/$1-scoping-questions.md`:

```markdown
# Scoping Questions: $1

> These questions were generated after reviewing the research report.
> Please answer each question. Write "skip" for questions that don't apply.
> When done, save this file and nudge the workflow to resume.

## Core Functionality
1. [Question grounded in research finding — e.g., "The research found 3 competing approaches to X (A, B, C). Which approach should we use, and why?"]
2. [Question about primary user workflow]
3. [Question about expected inputs/outputs]

## Technical Constraints
4. [Question about tech stack preferences given research findings]
5. [Question about deployment environment]
6. [Question about performance requirements]

## Scope & Priorities
7. [Question about MVP scope — what's in, what's deferred?]
8. [Question about which features from the research are must-haves vs nice-to-haves]
9. [Question about timeline/budget constraints]

## External Integrations
10. [Question about which external services to integrate with, based on research]
11. [Question about available API keys/credentials]
12. [Question about data sources and access]

## Edge Cases & Risk
13. [Question about failure modes the research identified]
14. [Question about security requirements]
15. [Question about scale expectations]

## Open Research Questions
16. [Question where the research was inconclusive — which direction to go?]
17. [Question about tradeoffs the research identified but couldn't resolve without human judgment]

---
*Answer below each question. The autonomous workflow will resume and use your answers to inform all planning artifacts.*
```

Aim for **15-30 questions** total. Quality over quantity — each question should be one that, if answered differently, would change the plan.

4. **Update state**:
   - Set `status: waiting_for_input`
   - Set `planning_sub_phase_iteration: 1`
   - Mark `Phase B0: Scoping Interview` in checklist as `[~]` (in progress, waiting)

5. **Send macOS notification**:
   ```
   Run via Bash: osascript -e 'display notification "Scoping questions ready for $1 — answer before planning continues" with title "Long Horizon Impl" subtitle "Waiting for Input"'
   ```

6. **Output**:
   ```
   ## Scoping Questions Generated

   Questions written to: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md
   Total questions: N

   WORKFLOW PAUSED — Waiting for human to answer scoping questions.

   To resume:
   1. Answer the questions in the scoping questions file
   2. Update .plugin-state/lhi-$1-implementation-state.md:
      - Set status: in_progress
      - Set planning_sub_phase: "B1"
      - Set planning_sub_phase_iteration: 0
   3. Nudge this session to continue
   ```

The stop hook sees `status: waiting_for_input` and allows Claude Code to exit cleanly.

#### B0 -> B1 Transition (After Human Answers)

When the workflow resumes (nudged by orchestrator after human answers):
1. Read `docs/long-horizon-impl/$1/planning/$1-scoping-questions.md` for answers
2. The state file should already have `planning_sub_phase: "B1"` and `status: in_progress` (set by orchestrator)
3. Mark `Phase B0: Scoping Interview` as complete `[x]`
4. Proceed to B1

**All subsequent sub-phases (B1-B4) MUST read the scoping answers** and incorporate them into their work. The answers are as authoritative as the research findings.

---

### SUB-PHASE B1: Functional Requirements

**Goal**: Produce `docs/long-horizon-impl/$1/planning/$1-functional-requirements.md`

#### B1 — First Iteration

1. **Read the scoping answers** at `docs/long-horizon-impl/$1/planning/$1-scoping-questions.md` (with human's answers). These answers are authoritative — they override any conflicting research findings on matters of scope, priorities, and preferences.

2. **Spawn 3 parallel requirements-analyst agents**, each focused on a different category:

```
Task tool with subagent_type='long-horizon-impl:requirements-analyst' (3 parallel instances)

Instance 1 — Core Functionality:
prompt: "Derive core functional requirements for project '$1'.
Research report: docs/long-horizon-impl/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: primary user-facing behaviors, core data transformations, main API endpoints, essential workflows."

Instance 2 — Edge Cases & Constraints:
prompt: "Derive edge case requirements and system constraints for project '$1'.
Research report: docs/long-horizon-impl/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: boundary conditions, error handling, performance requirements, scalability constraints, security requirements, input validation, concurrent access."

Instance 3 — External Integrations & Data:
prompt: "Derive external integration and data requirements for project '$1'.
Research report: docs/long-horizon-impl/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: external API integrations, data storage requirements, data flow, authentication/authorization, third-party service dependencies, API key/credential requirements."
```

3. **Spawn 2 parallel researcher agents** for domain requirements validation:

```
Task tool with subagent_type='long-horizon-impl:researcher' (2 parallel instances)

Instance 1 — Competitive Feature Analysis:
prompt: "Strategy: deep-dive
Research question: What features do similar products/solutions to '$1' provide? What are the must-have vs nice-to-have features in this space? Research report: docs/long-horizon-impl/$1/research/$1-report.tex"

Instance 2 — Requirements Pitfalls:
prompt: "Strategy: deep-dive
Research question: What are common requirements mistakes and overlooked requirements when building systems similar to '$1'? What do teams typically forget to specify? Research report: docs/long-horizon-impl/$1/research/$1-report.tex"
```

4. **Synthesize** all agent outputs into the functional requirements document.

IMPORTANT: The three requirements-analyst instances produced requirements with independent numbering (each starting from REQ-001). When synthesizing, renumber ALL requirements sequentially (REQ-001 through REQ-NNN) to eliminate duplicates.

Write to `docs/long-horizon-impl/$1/planning/$1-functional-requirements.md`:

```markdown
# Functional Requirements: $1

## Project Overview
[2-3 sentences: what this system does and why]

## Stakeholders
[Who uses this system and what they need]

## Functional Requirements

### Core Requirements

**REQ-001: [Title]**
- *Description*: [Clear, testable statement]
- *Acceptance Criteria*:
  1. [Criterion 1]
  2. [Criterion 2]
- *Priority*: MUST | SHOULD | COULD
- *Research Basis*: [Section reference from research report]

[... more requirements ...]

### Edge Cases & Error Handling
[... same format ...]

### External Integrations
[... same format ...]

## Non-Functional Requirements
- Performance: [specific targets]
- Security: [requirements]
- Scalability: [requirements]

## External Dependencies
| Service/API | Purpose | Credential Required | Credential Name |
|-------------|---------|--------------------|-----------------|
| [Service] | [Why] | Yes/No | [ENV_VAR_NAME] |

## Out of Scope
- [Explicitly excluded functionality]

## Open Questions
- [Questions needing human clarification]
```

#### B1 — Subsequent Iterations

1. **Spawn 2 parallel plan-critic agents** to scrutinize the requirements (using the enhanced v2.1.0 evidence-to-decision audit):

```
Task tool with subagent_type='long-horizon-impl:plan-critic' (2 parallel instances)

Instance 1: "Scrutinize the functional requirements for completeness and testability.
Requirements: docs/long-horizon-impl/$1/planning/$1-functional-requirements.md
Research report: docs/long-horizon-impl/$1/research/$1-report.tex
Scoping answers: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md
Focus: Are all research findings reflected? Are acceptance criteria specific enough? Any MUST requirements missing?"

Instance 2: "Scrutinize the functional requirements for feasibility and consistency.
Requirements: docs/long-horizon-impl/$1/planning/$1-functional-requirements.md
Research report: docs/long-horizon-impl/$1/research/$1-report.tex
Scoping answers: docs/long-horizon-impl/$1/planning/$1-scoping-questions.md
Focus: Are requirements contradictory? Are external dependency requirements realistic? Any requirements that can't be implemented?"
```

2. **Spawn 1-2 researcher agents** for any gaps the critics identified

3. **Update** the requirements document, addressing BLOCKER and CONCERN issues

When a BLOCKER issue is raised by a plan-critic agent, write a learning about the blocker:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-blocker-B1.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: B1-requirements
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: What the BLOCKER issue was, which artifact it affected, and the critic's rationale.
   - **Learning**: The pattern — what type of blocker this was (e.g., missing requirement, infeasible constraint, contradictory requirements) and what conditions triggered it.
   - **Resolution**: How the blocker was resolved in this iteration.

#### B1 -> B2 Transition

When `planning_sub_phase_iteration >= b1_budget`:
1. Mark `Phase B1: Functional Requirements` as complete in checklist
2. Set `planning_sub_phase: "B2"`
3. Reset `planning_sub_phase_iteration: 0`

---

### SUB-PHASE B2: Architecture Plan

**Goal**: Produce `docs/long-horizon-impl/$1/planning/$1-architecture-plan.md`

#### B2 — First Iteration

1. **Spawn 5 parallel researcher agents** (inspired by dev-workflow Phase 4):

```
Task tool with subagent_type='long-horizon-impl:researcher' (5 parallel instances)

Instance 1 — Architecture Patterns:
prompt: "Strategy: deep-dive
Research focus: Architecture patterns for systems similar to '$1'. Read docs/long-horizon-impl/$1/planning/$1-functional-requirements.md for what the system must do. Read docs/long-horizon-impl/$1/planning/$1-scoping-questions.md for human's preferences. Look for design patterns, component decomposition strategies, and proven approaches."

Instance 2 — Technology Evaluation:
prompt: "Strategy: deep-dive
Research focus: Technology and library evaluation for '$1'. Read docs/long-horizon-impl/$1/planning/$1-functional-requirements.md. Compare candidate frameworks, check maintenance status, community health, known issues."

Instance 3 — Data Modeling:
prompt: "Strategy: deep-dive
Research focus: Data modeling and storage patterns for '$1'. Read docs/long-horizon-impl/$1/planning/$1-functional-requirements.md. Schema design, data flow patterns, state management, storage trade-offs."

Instance 4 — API Design:
prompt: "Strategy: deep-dive
Research focus: API design patterns and interface contracts for '$1'. Read docs/long-horizon-impl/$1/planning/$1-functional-requirements.md. REST/GraphQL conventions, versioning, error handling, contract-first approaches."

Instance 5 — Infrastructure:
prompt: "Strategy: deep-dive
Research focus: Infrastructure and deployment for '$1'. Read docs/long-horizon-impl/$1/planning/$1-functional-requirements.md. Containerization, scaling, monitoring, deployment pipelines."
```

2. **Synthesize** research into the architecture plan. If the repo has existing code, also spawn 1-2 repo-analyst agents.

Write to `docs/long-horizon-impl/$1/planning/$1-architecture-plan.md`:

```markdown
# Architecture Plan: $1

## Architecture Research Summary
[Key takeaways from the 5 research agents]

## Component Overview
[ASCII diagram showing component relationships]

## Technology Stack
| Layer | Choice | Rationale | Research Basis |
|-------|--------|-----------|----------------|

## Foundation (Build First)
### Shared Types
### Common Utilities

## Independent Components (Build in Parallel)
### Component N: [Name]
- **Purpose**: [What it does]
- **File(s)**: [paths]
- **Requirements Covered**: [REQ-001, REQ-003, ...]
- **Interface**: Input/Output
- **Dependencies**: [external deps only]
- **Can parallel with**: [other components]

## Integration Layer (Build After Components)

## Data Flow

## External Integrations
| Service | Purpose | API Key Required | Integration Approach |

## Files to Create/Modify
| File | Action | Purpose | Phase |

## Build Sequence
1. Foundation (sequential)
2. Components (parallel)
3. Integration (sequential)

## Requirements Coverage Matrix
| Requirement | Component(s) | Status |
```

#### B2 — Subsequent Iterations

1. **Spawn 2 plan-architect agents** (each improving a different section, with research backing)
2. **Spawn 2 plan-critic agents** (scrutinizing architecture against requirements and research, using evidence-to-decision audit)
3. **Update** the architecture plan

When a BLOCKER issue is raised by a plan-critic agent, write a learning about the blocker:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-blocker-B2.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: B2-architecture
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: What the BLOCKER issue was, which artifact it affected, and the critic's rationale.
   - **Learning**: The pattern — what type of blocker this was (e.g., technology incompatibility, missing component, infeasible integration) and what conditions triggered it.
   - **Resolution**: How the blocker was resolved in this iteration.

#### B2 -> B3 Transition

When `planning_sub_phase_iteration >= b2_budget`:
1. Mark `Phase B2: Architecture` as complete in checklist
2. Set `planning_sub_phase: "B3"`
3. Reset `planning_sub_phase_iteration: 0`

---

### SUB-PHASE B3: Test Plan + Implementation Plan

**Goal**: Produce `docs/long-horizon-impl/$1/planning/$1-test-plan.md` AND `docs/long-horizon-impl/$1/planning/$1-implementation-plan.md`

#### B3 — First Iteration

1. **Spawn 4 parallel researcher agents**:

```
Instance 1 — Testing Strategies:
prompt: "Strategy: deep-dive
Research focus: Testing strategies for the tech stack chosen in docs/long-horizon-impl/$1/planning/$1-architecture-plan.md. Framework comparisons, mocking approaches, CI/CD integration."

Instance 2 — Implementation Patterns:
prompt: "Strategy: deep-dive
Research focus: Implementation patterns for '$1' with the chosen tech stack. Read docs/long-horizon-impl/$1/planning/$1-architecture-plan.md. Real-world examples, code samples."

Instance 3 — Implementation Pitfalls:
prompt: "Strategy: deep-dive
Research focus: Common implementation pitfalls when building '$1'. Migration issues, breaking changes, deprecated APIs, gotchas. Read docs/long-horizon-impl/$1/planning/$1-architecture-plan.md."

Instance 4 — TDD Patterns:
prompt: "Strategy: deep-dive
Research focus: TDD patterns and test-first development approaches for the tech stack in docs/long-horizon-impl/$1/planning/$1-architecture-plan.md."
```

2. **Create both artifacts**.

Write to `docs/long-horizon-impl/$1/planning/$1-test-plan.md`:

```markdown
# Test Plan: $1

## Test Infrastructure
- Framework: [chosen framework with rationale]
- Runner: [test runner]

## Unit Tests
### [Component] Tests
| Test ID | Test Case | Requirement | Expected Behavior |

## Integration Tests
| Test ID | Test Case | Components | Requirement | Expected Behavior |

## E2E Tests
| Test ID | Scenario | Requirements Covered | Steps | Expected Outcome |

## Edge Case Tests

## Requirements Traceability
| Requirement | Test IDs | Coverage |
```

Write to `docs/long-horizon-impl/$1/planning/$1-implementation-plan.md`:

```markdown
# Implementation Plan: $1

## Architecture Reference
See docs/long-horizon-impl/$1/planning/$1-architecture-plan.md

## Feature List

### Foundation Features (Sequential)
**F001: [Feature name]**
- *Component*: Foundation
- *Requirements*: REQ-NNN
- *Files to create*: [exact paths]
- *Dependencies*: none
- *Implementation details*: [specific what to build]
- *Tests*: T-001, T-002
- *Estimated complexity*: S | M | L

### Component Features (Parallel)
**F002: [Feature name]**
- *Component*: [from architecture]
- *Requirements*: REQ-NNN
- *Dependencies*: [F001]
- *External services*: [if any]

### Integration Features (Sequential)
**F0NN: [Integration feature]**
- *Dependencies*: [F002, F003, ...]

## Build Order
[Dependency graph]

## External Dependencies Checklist
| Service | Feature(s) | API Key/Credential | Status |

## Risk Register
| Risk | Impact | Mitigation | Feature(s) Affected |
```

#### B3 — Subsequent Iterations

1. **Spawn 2 plan-architect agents** (one for test plan, one for implementation plan)
2. **Spawn 2 plan-critic agents** (one scrutinizing test coverage, one scrutinizing implementation feasibility)
3. **Update** both artifacts

When a BLOCKER issue is raised by a plan-critic agent, write a learning about the blocker:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-blocker-B3.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: B3-test-impl-plan
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: What the BLOCKER issue was, which artifact it affected, and the critic's rationale.
   - **Learning**: The pattern — what type of blocker this was (e.g., untestable requirement, missing test infrastructure, circular dependency in build order) and what conditions triggered it.
   - **Resolution**: How the blocker was resolved in this iteration.

#### B3 -> B4 Transition

When `planning_sub_phase_iteration >= b3_budget`:
1. Mark `Phase B3: Test Plan + Implementation Plan` as complete in checklist
2. Set `planning_sub_phase: "B4"`
3. Reset `planning_sub_phase_iteration: 0`

---

### SUB-PHASE B4: Cross-Examination

**Goal**: Validate ALL artifacts against each other. Resolve contradictions, fill gaps, ensure consistency.

#### B4 — Every Iteration

1. **Spawn 5 parallel researcher agents for validation** (inspired by dev-workflow Phase 6):

```
Instance 1 — Architecture Validation:
prompt: "Strategy: adversarial-challenge
Validate architecture decisions in docs/long-horizon-impl/$1/planning/$1-architecture-plan.md against current best practices."

Instance 2 — Technology Risk:
prompt: "Strategy: adversarial-challenge
Technology risk assessment for libraries/frameworks in docs/long-horizon-impl/$1/planning/$1-architecture-plan.md. Check for deprecation, CVEs, breaking changes."

Instance 3 — Known Issues:
prompt: "Strategy: deep-dive
Known bugs and issues in the libraries chosen in docs/long-horizon-impl/$1/planning/$1-architecture-plan.md."

Instance 4 — Alternative Approaches:
prompt: "Strategy: adversarial-challenge
Alternative approaches to implementing '$1' that might be simpler."

Instance 5 — Security Validation:
prompt: "Strategy: deep-dive
Security validation for '$1' against current threat models. OWASP top 10."
```

2. **Spawn 2 plan-reviewer agents** for cross-examination:

```
Task tool with subagent_type='long-horizon-impl:plan-reviewer' (2 parallel instances)

Instance 1: "Cross-examine Requirements <-> Architecture <-> Implementation Plan.
- Requirements: docs/long-horizon-impl/$1/planning/$1-functional-requirements.md
- Architecture: docs/long-horizon-impl/$1/planning/$1-architecture-plan.md
- Test Plan: docs/long-horizon-impl/$1/planning/$1-test-plan.md
- Implementation Plan: docs/long-horizon-impl/$1/planning/$1-implementation-plan.md
- Research: docs/long-horizon-impl/$1/research/$1-report.tex
Focus: requirements coverage, component-to-requirement mapping, build order correctness, external dependency audit."

Instance 2: "Cross-examine Test Plan <-> Requirements <-> Architecture.
- Requirements: docs/long-horizon-impl/$1/planning/$1-functional-requirements.md
- Architecture: docs/long-horizon-impl/$1/planning/$1-architecture-plan.md
- Test Plan: docs/long-horizon-impl/$1/planning/$1-test-plan.md
- Implementation Plan: docs/long-horizon-impl/$1/planning/$1-implementation-plan.md
- Research: docs/long-horizon-impl/$1/research/$1-report.tex
Focus: test coverage gaps, feasibility concerns, research-plan contradictions, practical implementation risks."
```

3. **Synthesize** all findings:
   - BLOCKER issues: must be resolved in this iteration (update the relevant artifact)
   - CONCERN issues: address if straightforward, track otherwise
   - SUGGESTION issues: incorporate the good ones
   - Write a cross-examination log to `docs/long-horizon-impl/$1/planning/cross-examination-log.md` (append each iteration's findings)

When a BLOCKER issue is raised during cross-examination, write a learning about the blocker:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Write a learning file named `YYYY-MM-DD-$1-blocker-B4.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: B4-cross-examination
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: What the BLOCKER issue was, which artifacts were involved, and the reviewer's rationale.
   - **Learning**: The pattern — what type of cross-artifact inconsistency this was (e.g., requirement without test coverage, architecture component without implementation plan, contradictory constraints across artifacts) and what conditions triggered it.
   - **Resolution**: How the blocker was resolved in this iteration.

4. **Update ALL four artifacts** as needed to resolve issues

5. **Update sources.bib** with any new sources from validation research

#### B4 Completion

When `planning_sub_phase_iteration >= b4_budget`:

1. Mark `Phase B4: Cross-Examination` as complete in checklist
2. Set `status: complete` in `.plugin-state/lhi-$1-implementation-state.md`
3. **Compile research report** (final version):
   Spawn `long-horizon-impl:latex-compiler`
4. Send macOS notification:
   ```
   Run via Bash: osascript -e 'display notification "Planning complete for $1 — 4 artifacts ready for review" with title "Long Horizon Impl" subtitle "Planning"'
   ```

#### B4 Completion Retrospective Learning

After setting `status: complete`, write a completion retrospective:

1. Resolve the learnings directory: read `.plugin-state/long-horizon-impl.local.md` for a `learnings_dir` YAML field. If not found or file does not exist, fall back to `~/.claude/plugin-learnings/long-horizon-impl/`.
2. Run `mkdir -p` on the learnings directory.
3. Read all 4 planning artifacts and the original prompt from the state file.
4. Write a learning file named `YYYY-MM-DD-$1-completion-review.md` (using today's date) with:
   ```yaml
   ---
   type: learning
   plugin: long-horizon-impl
   workflow_topic: $1
   phase: completion-review
   date: YYYY-MM-DD
   ---
   ```
   Followed by sections:
   - **Observation**: Summary of the planning workflow — how many research iterations ran, how many planning iterations ran, how many sources were cited, how many strategies were used, how many requirements were produced.
   - **Intent Alignment**: Did the 4 planning artifacts address the user's original prompt? What aspects were well-covered vs. underserved? Review each artifact against the original intent.
   - **What Worked Well**: Which research strategies produced the highest quality findings for planning? Which planning phases ran smoothly? Which artifacts were strongest?
   - **What Produced Lower Quality**: Which strategies underperformed? Where did the planning end up thin or repetitive? Which artifacts needed the most rework during cross-examination?
   - **Improvement Suggestions**: Specific, actionable suggestions for improving the long-horizon-impl plugin workflow (e.g., "increase B2 architecture budget for microservice projects", "add pre-B1 requirements brainstorm step").

The Stop hook verifies `status: complete` AND both `total_iterations_research >= research_budget` AND `total_iterations_planning >= planning_budget` before allowing the workflow to end.

---

## State Update (Every Iteration in Phase B)

After each Phase B iteration (B1-B4, not B0):

1. Increment `iteration` and `total_iterations_planning`
2. Increment `planning_sub_phase_iteration`
3. Check if sub-phase budget is exhausted -> transition to next sub-phase
4. Update `## Planning Progress` in state file with artifact status

---

## OUTPUT

```
## Iteration N Complete — [Phase A | Phase B: Sub-Phase BX]

### [Phase A: Contributions / Phase B: Sub-Phase Work]
- [Summary items]

### State
- Phase: [A | B]
- [Phase A: Strategy: <name>, Contributions: N]
- [Phase B: Sub-phase: B0/B1/B2/B3/B4, Sub-phase iteration: N/budget]
- [Phase B: Artifacts complete: N/4]

### Artifacts Status
- [ ] Functional Requirements: [not started | in progress | complete]
- [ ] Architecture Plan: [not started | in progress | complete]
- [ ] Test Plan: [not started | in progress | complete]
- [ ] Implementation Plan: [not started | in progress | complete]

### Next Iteration Focus:
- [Top priorities]
```
