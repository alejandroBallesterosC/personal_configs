---
description: "Mode 1: Autonomous deep research producing a LaTeX report"
model: opus
argument-hint: <topic-name> "Your detailed research prompt..."
---

# ABOUTME: Mode 1 command that runs one iteration of deep research per invocation.
# ABOUTME: Spawns strategy-dependent parallel researcher agents, synthesizes findings, updates LaTeX report and state.

# Autonomous Deep Research

**Topic**: $1
**Prompt**: $2

## Objective

Run ONE ITERATION of deep research on the given topic. Each iteration: read state, spawn parallel researcher agents (dispatched by current strategy), synthesize findings, update the LaTeX report, update state. Ralph-loop calls this command repeatedly for multi-iteration execution.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `docs/autonomous/$1/research/$1-state.md` exists.

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

4. Create state file `docs/autonomous/$1/research/$1-state.md` with YAML frontmatter:
   ```yaml
   ---
   workflow_type: autonomous-research
   name: $1
   status: in_progress
   current_phase: "Phase A: Research"
   iteration: 1
   total_iterations_research: 0
   sources_cited: 0
   findings_count: 0
   current_research_strategy: wide-exploration
   research_strategies_completed: []
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase A: Research

   ## Original Prompt
   $2

   ## Completed Phases
   - [ ] Phase A: Research

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
   1. docs/autonomous/$1/research/$1-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. CLAUDE.md
   ```

### If state file EXISTS (resuming):

1. Read `docs/autonomous/$1/research/$1-state.md` to get current state
2. Read `docs/autonomous/$1/research/$1-report.tex` to understand what research has been done
3. Extract open questions and gaps from the state file
4. Read `current_research_strategy` from state YAML to determine dispatch behavior

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

---

## STEP 5: Update LaTeX Report

1. Read the current `docs/autonomous/$1/research/$1-report.tex`
2. Integrate new findings into the appropriate sections:
   - Add new findings to `\section{Key Findings}` as subsections
   - Update `\section{Analysis \& Synthesis}` with cross-cutting patterns
   - Add unresolved items to `\section{Open Questions}`
   - Update `\section{Methodology}` with iteration count and source count
   - Update `\section{Executive Summary}` (keep it current, not just at the end)
3. Write the updated `.tex` file

**LaTeX formatting rules**:
- Escape special characters in content: `\%`, `\&`, `\$`, `\#`, `\_`, `\^{}`, `\{`, `\}`, `\textasciitilde{}`
- Use `\url{...}` for URLs (requires hyperref package, already included)
- Organize findings thematically, NOT chronologically
- Each finding subsection should have: claim, evidence, sources, confidence level

4. Update `docs/autonomous/$1/research/sources.bib` with any new BibTeX entries for sources cited

---

## STEP 6: Update State File

Update `docs/autonomous/$1/research/$1-state.md`:

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

3. If ALL 8 strategies are in `research_strategies_completed`:
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
     3. `contradiction-resolution`
     4. `deep-dive`
     5. `adversarial-challenge`
     6. `gaps-and-blind-spots`
     7. `temporal-analysis`
     8. `cross-domain-synthesis`
   - Set `current_research_strategy` to the next strategy
   - Reset `consecutive_low_contributions` to 0
   - Send notification:
     ```
     Run via Bash: osascript -e 'display notification "Rotating research strategy to <new_strategy> for $1" with title "Autonomous Workflow" subtitle "Research"'
     ```

**`ralph-loop --max-iterations` is the only stopping mechanism for Mode 1.** Do not attempt to signal or force workflow completion.

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

## OUTPUT

After completing one iteration, output a brief summary:

```
## Iteration N Complete

### Strategy: [current_research_strategy]
### Contributions This Iteration: [count]
- New findings: [count]
- Verifications: [count]
- Contradictions resolved: [count]
- Depth additions: [count]
- Source upgrades: [count]

### Sources Added: [count]
### Open Questions Remaining: [count]
### Strategy Progress: [completed_count]/8 strategies in current cycle
### Consecutive Low-Contribution Iterations: [N]/[threshold]

### Next Iteration Focus:
- Strategy: [current or next strategy]
- [Top 3 research directions]
```
