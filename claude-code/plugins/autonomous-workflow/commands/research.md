---
description: "Mode 1: Autonomous deep research producing a LaTeX report"
model: opus
argument-hint: <topic-name> "Your detailed research prompt..."
---

# ABOUTME: Mode 1 command that runs one iteration of deep research per invocation.
# ABOUTME: Spawns parallel researcher agents, synthesizes findings, updates LaTeX report and state.

# Autonomous Deep Research

**Topic**: $1
**Prompt**: $2

## Objective

Run ONE ITERATION of deep research on the given topic. Each iteration: read state, spawn parallel researcher agents, synthesize findings, update the LaTeX report, update state. Ralph-loop calls this command repeatedly for multi-iteration execution.

**REQUIRED**: Use the Skill tool to invoke `autonomous-workflow:autonomous-workflow-guide` to load the workflow source of truth.

---

## STEP 1: Initialize or Resume

Check if `docs/research-$1/$1-state.md` exists.

### If state file does NOT exist (first iteration):

1. Create directory structure:
   ```
   docs/research-$1/
   docs/research-$1/transcripts/
   ```

2. Read the report template from the plugin:
   - Use Glob to find `**/autonomous-workflow/templates/report-template.tex`
   - Read the template
   - Replace `PLACEHOLDER_TITLE` with a descriptive title based on the research prompt
   - Write to `docs/research-$1/$1-report.tex`

3. Create empty bibliography file `docs/research-$1/sources.bib`:
   ```bibtex
   % Bibliography for research topic: $1
   % Entries are added as sources are discovered during research.
   ```

4. Create state file `docs/research-$1/$1-state.md` with YAML frontmatter:
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
   new_findings_last_iteration: 0
   consecutive_low_findings: 0
   phase_transition_threshold: 3
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

   ## Open Questions
   1. [Derive 5 initial research questions from the prompt]
   2. ...

   ## Context Restoration Files
   1. docs/research-$1/$1-state.md (this file)
   2. docs/research-$1/$1-report.tex
   3. CLAUDE.md
   ```

### If state file EXISTS (resuming):

1. Read `docs/research-$1/$1-state.md` to get current state
2. Read `docs/research-$1/$1-report.tex` to understand what research has been done
3. Extract open questions and gaps from the state file

---

## STEP 2: Empty Repo Detection

Before spawning repo-analyst agents, check if the repo has meaningful non-research content:

Use Glob to search for files matching `**/*.py`, `**/*.ts`, `**/*.js`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.c`, `**/*.cpp`, `**/*.swift` (code files). Exclude anything under `docs/research-*`.

- If code files found: spawn repo-analyst agents in Step 3
- If NO code files found: skip repo-analyst agents entirely

---

## STEP 3: Spawn Parallel Research Agents

### Researcher Agents (3-5 in parallel)

Derive 3-5 specific research questions from:
- The original prompt (on first iteration)
- The open questions in the state file (on subsequent iterations)
- Gaps identified in the current report
- Claims that need verification
- Contradictions that need resolution

Spawn 3-5 parallel researcher agents using the Task tool:

```
Task tool with subagent_type='autonomous-workflow:researcher'
prompt: "Research question: <specific question>

Context: This is iteration N of a deep research project on '<topic>'. Previous findings have covered: <brief summary of sections already written>. Focus on: <specific facet>.

Return findings in the standard structured format (Key Findings, Sources, Confidence, Contradictions, Follow-up Questions)."
```

Launch ALL researcher agents in a SINGLE message with multiple Task tool calls to maximize parallelism.

### Repo-Analyst Agents (0-2 in parallel, if applicable)

If Step 2 found code files, spawn 1-2 repo-analyst agents in the SAME message as researchers:

```
Task tool with subagent_type='autonomous-workflow:repo-analyst'
prompt: "Analyze how the codebase relates to: <specific aspect of the research topic>"
```

### CRITICAL: Never search the web yourself.

ALL web interaction happens in researcher subagents. The main instance receives ONLY compressed summaries. This prevents context bloat from raw web content.

---

## STEP 4: Synthesize Findings

After all agents return:

1. Read each agent's output (they return 200-500 word structured summaries)
2. Identify:
   - Findings that are consistent across multiple agents (high confidence)
   - Contradictions between agents (need resolution)
   - Gaps not covered by any agent
   - Claims that need further verification
3. Count the number of NEW substantive findings this iteration (a finding is "new" if it adds information not already in the report)

---

## STEP 5: Update LaTeX Report

1. Read the current `docs/research-$1/$1-report.tex`
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

4. Update `docs/research-$1/sources.bib` with any new BibTeX entries for sources cited

---

## STEP 6: Update State File

Update `docs/research-$1/$1-state.md`:

1. Increment `iteration` by 1
2. Update `total_iterations_research`
3. Update `sources_cited` (total unique sources across all iterations)
4. Update `findings_count` (total substantive findings in report)
5. Set `new_findings_last_iteration` to the count from Step 4
6. Update `consecutive_low_findings`:
   - If `new_findings_last_iteration < 2`: increment `consecutive_low_findings`
   - Otherwise: reset `consecutive_low_findings` to 0
7. Update the `## Open Questions` section with new questions and remove answered ones
8. Update `## Research Progress` counts

---

## STEP 7: Check Diminishing Returns

If `consecutive_low_findings >= phase_transition_threshold`:
- Research is effectively complete for this topic
- Update state: `status: complete`, mark Phase A as complete
- Send macOS notification:
  ```
  Run via Bash: osascript -e 'display notification "Research complete for $1" with title "Autonomous Workflow" subtitle "Report ready"'
  ```
- Output `<promise>WORKFLOW_COMPLETE</promise>` so ralph-loop stops iterating

---

## STEP 8: Identify Next Research Directions

Based on the synthesis, write 3-5 prioritized research directions for the next iteration. These become the open questions in the state file and guide the next iteration's researcher agent prompts.

Priority order:
1. Contradictions that need resolution (highest priority)
2. Claims with low confidence that need verification
3. Gaps in coverage (sections with thin content)
4. Follow-up questions suggested by researcher agents
5. Deeper dives into the most important findings

---

## OUTPUT

After completing one iteration, output a brief summary:

```
## Iteration N Complete

### Findings This Iteration: [count]
- [1-line summary of each new finding]

### Sources Added: [count]
### Open Questions Remaining: [count]
### Consecutive Low-Finding Iterations: [N]/[threshold]

### Next Iteration Focus:
- [Top 3 research directions]
```
