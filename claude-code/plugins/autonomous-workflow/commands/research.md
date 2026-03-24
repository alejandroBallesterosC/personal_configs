---
description: "Mode 1: Autonomous deep research producing a LaTeX report"
model: opus
argument-hint: <topic-name> "Your detailed research prompt..." --research-iterations N
---

# ABOUTME: Mode 1 command that runs one iteration of deep research per invocation.
# ABOUTME: Spawns strategy-dependent parallel researcher agents, synthesizes findings, updates LaTeX report and state.

# Autonomous Deep Research

**Topic**: $1
**Prompt**: $2
**All Arguments**: $ARGUMENTS

Parse optional flags from **All Arguments**:
- `--research-iterations N`: total research iteration budget (default: 50)

## Objective

Run ONE ITERATION of deep research on the given topic. Each iteration: read state, spawn parallel researcher agents (dispatched by current strategy), synthesize findings, update the LaTeX report, update state. The Stop hook re-feeds this command for multi-iteration execution.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `.claude/autonomous-$1-research-state.md` exists.

### If state file does NOT exist (first iteration):

1. Create directory structure:
   ```
   docs/autonomous/$1/research/
   docs/autonomous/$1/research/transcripts/
   ```

2. Read the report template from the plugin:
   - Use Glob to find `**/autonomous-workflow/templates/report-template.tex`
   - Read the template
   - Replace `PLACEHOLDER_TITLE` with a descriptive title based on the research prompt
   - Write to `docs/autonomous/$1/research/$1-report.tex`

3. Create empty bibliography file `docs/autonomous/$1/research/sources.bib`:
   ```bibtex
   % Bibliography for research topic: $1
   % Entries are added as sources are discovered during research.
   ```

4. Create `docs/autonomous/$1/research/research-progress.md`:
   ```markdown
   # Research Progress: $1

   ## Original Prompt
   $2

   ## Major Themes/Findings
   - (none yet)

   ## Well-Supported vs. Thin
   - (to be updated as research progresses)

   ## Open Contradictions
   - (none yet)

   ## Methodological Quality
   - Claims with TIGHT evidence gap: 0
   - Claims with MODERATE evidence gap: 0
   - Claims with WIDE evidence gap: 0
   - Claims narrowed after critique: 0
   - Sources flagged for removal: 0

   ## Research Direction
   - Begin with wide-exploration to establish baseline understanding
   ```

5. Parse research budget from `--research-iterations` flag in All Arguments. If not provided, default to 50.

6. Create state file `.claude/autonomous-$1-research-state.md` with YAML frontmatter:
   ```yaml
   ---
   workflow_type: autonomous-research
   name: $1
   status: in_progress
   current_phase: "Phase R: Research"
   iteration: 1
   total_iterations_research: 0
   synthesis_iteration: 0
   sources_cited: 0
   findings_count: 0
   research_budget: <parsed from --research-iterations flag, or 50 if not provided>
   current_research_strategy: wide-exploration
   research_strategies_completed: []
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   command: |
     <the full invocation command, e.g. /autonomous-workflow:research '$1' '$2' --research-iterations N>
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase R: Research

   ## Original Prompt
   $2

   ## Completed Phases
   - [ ] Phase R: Research
   - [ ] Phase S: Synthesis

   ## Research Progress
   - Sources consulted: 0
   - Key findings: 0
   - Open questions: 5
   - Sections in report: 0

   ## Strategy History
   | Strategy | Iterations | Contributions | Rotated At |
   |----------|-----------|---------------|------------|

   ## Open Questions
   1. [Derive 5 initial research questions from the prompt]
   2. ...

   ## Context Restoration Files
   1. .claude/autonomous-$1-research-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/research/research-progress.md
   4. CLAUDE.md
   ```

### If state file EXISTS (resuming):

1. Read `.claude/autonomous-$1-research-state.md` to get current state
2. Read `docs/autonomous/$1/research/$1-report.tex` to understand what research has been done
3. Read `docs/autonomous/$1/research/research-progress.md` for high-level research progress
4. Extract open questions and gaps from the state file
5. Read `current_research_strategy` and `current_phase` from state YAML

---

## Phase Router

After initializing or resuming, check `current_phase` from the state file:

- If `current_phase` is **"Phase R: Research"** (or "Phase A: Research" for backward compatibility): proceed to **STEP 2** below (normal research iteration).
- If `current_phase` is **"Phase S: Synthesis"**: skip directly to the **Phase S: Synthesis** section at the end of this document.

---

## STEP 2: Empty Repo Detection

Before spawning repo-analyst agents, check if the repo has meaningful non-research content:

Use Glob to search for files matching `**/*.py`, `**/*.ts`, `**/*.js`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.c`, `**/*.cpp`, `**/*.swift` (code files). Exclude anything under `docs/autonomous/*`.

- If code files found: spawn repo-analyst agents in Step 3
- If NO code files found: skip repo-analyst agents entirely

---

## STEP 3: Spawn Parallel Research Agents (Strategy-Dependent)

Read `current_research_strategy` from the state file YAML. Dispatch agents based on the active strategy.

### Strategy Dispatch Table

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

### Agent Prompt Format

Each agent's prompt MUST include:
1. A `Strategy: <name>` line so the researcher agent knows how to behave
2. Strategy-specific instructions (see strategy descriptions below)
3. Context about the current research state (iteration number, existing coverage, etc.)

```
Task tool with subagent_type='autonomous-workflow:researcher'
prompt: "Strategy: <current_research_strategy>

Research question: <specific question derived from strategy>

Context: This is iteration N of a deep research project on '<topic>'. Current strategy: <strategy>. Previous findings have covered: <brief summary of sections already written>. Focus on: <strategy-specific focus>.

<Strategy-specific instructions — see below>

Return findings in the structured format appropriate for this strategy."
```

### Strategy-Specific Agent Instructions

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
Task tool with subagent_type='autonomous-workflow:methodological-critic'
prompt: "Evaluate these source-claim pairs from the research report.

Report: docs/autonomous/$1/research/$1-report.tex
Sources: docs/autonomous/$1/research/sources.bib

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

### Repo-Analyst Agents (0-2 in parallel, if applicable)

If Step 2 found code files, spawn 1-2 repo-analyst agents in the SAME message as researchers:

```
Task tool with subagent_type='autonomous-workflow:repo-analyst'
prompt: "Analyze how the codebase relates to: <specific aspect of the research topic>"
```

### CRITICAL: Never search the web yourself.

ALL web interaction happens in researcher subagents. The main instance receives ONLY compressed summaries. This prevents context bloat from raw web content.

Launch ALL agents in a SINGLE message with multiple Task tool calls to maximize parallelism.

---

## STEP 4: Synthesize Findings

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

### Step 4.5: Internal Consistency Audit

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

---

## STEP 5: Update LaTeX Report

1. Read the current `docs/autonomous/$1/research/$1-report.tex`
2. Read the formatting rules in the template comments (between the `FORMATTING RULES` markers near the top of the document). Follow them strictly.
3. Integrate new findings into the appropriate sections:
   - Add new findings to `\section{Key Findings}` as subsections
   - Update `\section{Analysis \& Synthesis}` with cross-cutting patterns
   - Add unresolved items to `\section{Open Questions}`
   - Update `\section{Methodology}` with iteration count and source count
4. Write the updated `.tex` file

### CRITICAL: Document Formatting Rules

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

### In-Line Citation Rules

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

5. Update `docs/autonomous/$1/research/sources.bib` with new BibTeX entries (after dedup check)

### Synthesis Section — Placeholder During Phase R

During Phase R (research iterations), do NOT write content into the `\section{Synthesis}`. Leave it as a placeholder:

```latex
\section{Synthesis}
% Synthesis will be written in Phase S after research completes.
\textit{This section will be written after all research iterations are complete.}
```

The full Synthesis is written during Phase S (see the Phase S section below). This prevents drift from per-iteration rewrites and avoids wasting tokens on work that's immediately overwritten.

### Update research-progress.md

After updating the report, update `docs/autonomous/$1/research/research-progress.md` with:

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

---

## STEP 6: Update State File

Update `.claude/autonomous-$1-research-state.md`:

1. Increment `iteration` by 1
2. Update `total_iterations_research`
3. Update `sources_cited` (total unique sources across all iterations)
4. Update `findings_count` (total substantive findings in report)
5. Set `contributions_last_iteration` to the total from Step 4
6. Update `consecutive_low_contributions`:
   - If `contributions_last_iteration < 2`: increment `consecutive_low_contributions`
   - Otherwise: reset `consecutive_low_contributions` to 0
7. Update the `## Strategy History` table with this iteration's strategy and contribution count
8. Update the `## Open Questions` section with new questions and remove answered ones
9. Update `## Research Progress` counts

---

## STEP 7: Strategy Rotation Check

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
     Run via Bash: osascript -e 'display notification "Strategy cycle complete for $1 — restarting from wide-exploration" with title "Autonomous Workflow" subtitle "Research"'
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
     Run via Bash: osascript -e 'display notification "Rotating research strategy to <new_strategy> for $1" with title "Autonomous Workflow" subtitle "Research"'
     ```

### Phase R Completion → Phase S Transition

After updating the state file and checking strategy rotation, check:

If `total_iterations_research >= research_budget`:
1. Transition to Phase S — update the state file:
   - Set `current_phase: "Phase S: Synthesis"`
   - Set `synthesis_iteration: 1`
   - Do NOT set `status: complete` — keep it as `in_progress`
   - Mark `Phase R: Research` as completed in the `## Completed Phases` section
2. Send macOS notification:
   ```
   Run via Bash: osascript -e 'display notification "Research budget reached for $1 — transitioning to Phase S: Synthesis" with title "Autonomous Workflow" subtitle "Research"'
   ```

The Stop hook re-feeds the command. The next invocation will enter Phase S via the Phase Router.

---

## STEP 8: Identify Next Research Directions

Based on the current strategy, write 3-5 prioritized research directions for the next iteration. These become the open questions in the state file and guide the next iteration's researcher agent prompts.

### Direction Priorities by Strategy

**wide-exploration**: Contradictions that need resolution, claims with low confidence needing verification, gaps in coverage, follow-up questions from agents, deeper dives into important findings.

**source-verification**: Claims with lowest confidence scores, single-source claims, high-impact claims whose truth significantly affects conclusions.

**contradiction-resolution**: Explicit contradictions in Open Questions, agent-reported conflicts, claims where sources disagree on key details.

**deep-dive**: Thinnest sections of the report, surface-level-only findings, prompt-specific depth requests.

**adversarial-challenge**: Strongest/most confident conclusions first, implementation-critical conclusions, claims the report treats as settled.

**gaps-and-blind-spots**: Missing perspectives (stakeholder groups not considered), unexplored adjacent domains, methodological gaps (types of evidence not yet gathered).

**temporal-analysis**: Key turning points in the domain, most recent shifts in understanding, emerging trends, historical precedents that inform current state.

**cross-domain-synthesis**: Most structurally similar problems in other fields, frameworks from other domains that map cleanly to this research domain.

---

## PHASE R OUTPUT

After completing one research iteration, output a brief summary:

```
## Iteration N Complete (Phase R: Research)

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
---

# Phase S: Synthesis (3 dedicated iterations)

This phase runs AFTER the research budget is exhausted. The Phase Router (after Step 1) sends control here when `current_phase` is "Phase S: Synthesis".

Read `synthesis_iteration` from the state file to determine which synthesis step to perform.

---

## Phase S — Iteration 1: "Read and Outline"

**Goal**: Absorb the full report and produce a structured outline for the Synthesis section.

1. Read the ENTIRE `docs/autonomous/$1/research/$1-report.tex` end-to-end — all Key Findings, Analysis & Synthesis, Open Questions sections
2. Read `docs/autonomous/$1/research/research-progress.md` for the high-level view of what's well-supported vs. thin
3. Produce a structured outline with:
   - The 5-7 most important takeaways (ranked by importance, not discovery order)
   - Key conclusions that flow from the evidence
   - Actionable recommendations tied to each conclusion
   - Confidence levels and known limitations
4. Write the outline to `docs/autonomous/$1/research/synthesis-outline.md`
5. Do NOT write anything to the `.tex` report in this iteration

**After completing this iteration:**
- Update `synthesis_iteration` to 2 in the state file
- Update `iteration` (overall counter) by 1

---

## Phase S — Iteration 2: "Write"

**Goal**: Write the full Synthesis section into the LaTeX report.

1. Read `docs/autonomous/$1/research/synthesis-outline.md` from iteration 1
2. Read the report's Key Findings section for `\cite{}` reference keys
3. Write the full `\section{Synthesis}` into the `.tex` report, replacing the placeholder

### Synthesis Structure (MANDATORY formatting):

- `\subsection{Summary}`: 2-3 SHORT paragraphs (3-4 sentences each). What was researched, why it matters, scope.
- `\subsection{Key Takeaways}`: **MUST use `\begin{enumerate}`** with 5-7 items. Each item uses `\item \textbf{Takeaway title.}` followed by 2-4 sentences of explanation. Each must reference its supporting section (e.g., "see Section 3.2"). Include `\cite{}` references.
- `\subsection{Conclusions \& Recommendations}`: **MUST use `\begin{itemize}`** with paired items. Format: `\item \textbf{Conclusion:} [text] \\\\ \textbf{Recommendation:} [text]`. Keep each pair to 3-5 sentences total.
- `\subsection{Confidence \& Limitations}`: One short paragraph for overall confidence, then **`\begin{itemize}`** listing specific limitations (1-2 sentences each).

### Hard Rules:

1. **Length**: 1500-2000 words. Absolute maximum 2500 words.
2. **NEVER** reference iteration numbers, research phases, strategy names, or chronological discovery order.
3. **Write as if all findings were discovered simultaneously.** No temporal narrative.
4. **Self-contained**: A busy reader with 5 minutes should understand the core findings, conclusions, and action items from this section alone.
5. **Demonstrate JUDGMENT** (curate the 5-7 most important things), not THOROUGHNESS (list everything found).
6. **Anti-contradiction rules**:
   - No recommendation that contradicts its paired conclusion
   - No Key Takeaway that contradicts another Key Takeaway
   - If the report contains mixed evidence on a topic, the Synthesis MUST reconcile this into a single coherent position with appropriate nuance, not present both as separate unqualified claims

**After completing this iteration:**
- Update `synthesis_iteration` to 3 in the state file
- Update `iteration` (overall counter) by 1

---

## Phase S — Iteration 3: "Edit and Polish"

**Goal**: Quality-check and tighten the Synthesis.

1. Re-read the `\section{Synthesis}` alongside the full `\section{Key Findings}`
2. Check for:
   - Internal contradictions within the Synthesis
   - Critical findings from Key Findings that are missing from the Synthesis
   - Unsupported claims (claims in Synthesis without backing in Key Findings)
   - Recommendations that don't flow logically from their paired conclusions
3. Tighten prose — remove filler, improve clarity, fix formatting
4. Verify all `\cite{}` references in the Synthesis resolve against `sources.bib`
5. Verify word count is within 1500-2500 words
6. After this iteration, set `status: complete` in the state file

**After completing this iteration:**
- Set `status: complete` in the state file
- Mark `Phase S: Synthesis` as completed in the `## Completed Phases` section
- Send macOS notification:
  ```
  Run via Bash: osascript -e 'display notification "Research complete for $1 — Synthesis written" with title "Autonomous Workflow" subtitle "Research"'
  ```

The Stop hook verifies `status: complete`, `synthesis_iteration >= 3`, and `total_iterations_research >= research_budget` before allowing the workflow to end.

---

## PHASE S OUTPUT

After completing a synthesis iteration, output:

```
## Phase S — Iteration [1|2|3] Complete

### Step: [Read and Outline | Write | Edit and Polish]
### Synthesis Status: [outline produced | section written | polished and final]
### Word Count: [N/A for iteration 1 | count for iterations 2-3]
### Issues Found: [list any contradictions, missing findings, etc.]
```
