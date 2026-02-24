---
description: "Mode 2: Autonomous deep research followed by iterative implementation plan design"
model: opus
argument-hint: <project-name> "Your detailed research and planning prompt..."
---

# ABOUTME: Mode 2 command that runs research (Phase A) then iterative plan design (Phase B).
# ABOUTME: Auto-transitions between phases based on diminishing returns and planning stability.

# Autonomous Research + Plan

**Project**: $1
**Prompt**: $2

## Objective

Run ONE ITERATION of research (Phase A) or planning (Phase B) for the given project. The workflow automatically transitions from research to planning when research reaches diminishing returns. Ralph-loop calls this command repeatedly.

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

2. Read both templates from the plugin:
   - Use Glob to find `**/autonomous-workflow/templates/report-template.tex` and `**/autonomous-workflow/templates/plan-template.tex`
   - Read the report template, replace `PLACEHOLDER_TITLE` with a research-focused title
   - Write to `docs/research-$1/$1-report.tex`
   - Do NOT create the plan `.tex` yet — it gets created at Phase A→B transition

3. Create empty bibliography file `docs/research-$1/sources.bib`

4. Create state file `docs/research-$1/$1-state.md`:
   ```yaml
   ---
   workflow_type: autonomous-research-plan
   name: $1
   status: in_progress
   current_phase: "Phase A: Research"
   iteration: 1
   total_iterations_research: 0
   total_iterations_planning: 0
   sources_cited: 0
   findings_count: 0
   new_findings_last_iteration: 0
   consecutive_low_findings: 0
   consecutive_no_blockers: 0
   phase_transition_threshold: 3
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase A: Research

   ## Original Prompt
   $2

   ## Completed Phases
   - [ ] Phase A: Research
   - [ ] Phase B: Planning

   ## Research Progress
   - Sources consulted: 0
   - Key findings: 0
   - Open questions: 5
   - Sections in report: 0

   ## Planning Progress
   - Components designed: 0
   - Critic issues resolved: 0
   - Open design decisions: 0

   ## Open Questions
   1. [Derive 5 initial questions focused on technical feasibility, competitive landscape, architecture patterns, defensibility, and technology stack]

   ## Context Restoration Files
   1. docs/research-$1/$1-state.md (this file)
   2. docs/research-$1/$1-report.tex
   3. docs/research-$1/$1-plan.tex (after Phase B starts)
   4. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file and extract `current_phase`
2. Read `docs/research-$1/$1-report.tex`
3. If Phase B: also read `docs/research-$1/$1-plan.tex`
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

### Execution

Follow the same Steps 2-6 from `/autonomous-workflow:research` (spawn 3-5 parallel researcher agents, optionally repo-analysts, synthesize, update LaTeX, update state) but with the research focus above.

### Phase Transition Check

After updating the state file, check:

If `consecutive_low_findings >= phase_transition_threshold`:

1. **Compile research report to PDF**:
   Spawn `autonomous-workflow:latex-compiler` agent:
   ```
   Task tool with subagent_type='autonomous-workflow:latex-compiler'
   prompt: "Compile docs/research-$1/$1-report.tex to PDF. The working directory is docs/research-$1/."
   ```

2. **Send macOS notification**:
   ```
   Run via Bash: osascript -e 'display notification "Phase A complete — transitioning to planning" with title "Autonomous Workflow" subtitle "$1"'
   ```

3. **Create plan document**:
   - Read the plan template from `**/autonomous-workflow/templates/plan-template.tex`
   - Replace `PLACEHOLDER_TITLE` with the project name
   - Write to `docs/research-$1/$1-plan.tex`
   - Populate initial sections based on research findings

4. **Update state**:
   - Mark Phase A as complete in the checklist
   - Set `current_phase: "Phase B: Planning"`
   - Reset `consecutive_low_findings: 0`

5. **Continue to Phase B** in this same iteration (do not exit yet)

---

## PHASE B: Planning Iteration

If `current_phase` is `"Phase B: Planning"`:

### Step B1: Spawn Parallel Planning Agents

In a SINGLE message with multiple Task tool calls, spawn:

**2 plan-architect agents** (parallel), each assigned a different section of the plan:
```
Task tool with subagent_type='autonomous-workflow:plan-architect'
prompt: "Review and improve the '<section-name>' section of the plan.

Current plan: docs/research-$1/$1-plan.tex
Research report: docs/research-$1/$1-report.tex

Read both documents. Propose specific improvements to this section grounded in the research findings."
```

**2 plan-critic agents** (parallel), each scrutinizing a different aspect:
```
Task tool with subagent_type='autonomous-workflow:plan-critic'
prompt: "Scrutinize the '<aspect>' of the plan against research findings.

Current plan: docs/research-$1/$1-plan.tex
Research report: docs/research-$1/$1-report.tex

Read both documents. Identify logical conflicts, unsupported claims, feasibility concerns, and defensibility gaps."
```

### Step B2: Synthesize

1. Read all 4 agent outputs
2. Integrate architect proposals into the plan (prioritize changes with strong research backing)
3. Address critic issues:
   - BLOCKER issues: must be resolved in this iteration
   - CONCERN issues: address if straightforward, track otherwise
   - SUGGESTION issues: incorporate if they improve the plan without adding complexity
4. Count BLOCKER issues that remain unresolved

### Step B3: Validate New Claims

If architects introduced claims not in the original research, spawn 1 researcher agent to validate:
```
Task tool with subagent_type='autonomous-workflow:researcher'
prompt: "Validate the following claims made in an implementation plan: <claims>. Check if they are supported by credible sources."
```

### Step B4: Update Plan LaTeX

Write the updated `docs/research-$1/$1-plan.tex`.

### Step B5: Update State

1. Increment `iteration` and `total_iterations_planning`
2. Update `## Planning Progress` counts
3. Track `consecutive_no_blockers`:
   - If zero BLOCKER issues this iteration: increment
   - Otherwise: reset to 0

### Step B6: Check Planning Stability

If `consecutive_no_blockers >= 2` (plan stable for 2 iterations):

1. **Compile both documents**:
   Spawn `autonomous-workflow:latex-compiler` for both report and plan

2. **Send macOS notification**:
   ```
   Run via Bash: osascript -e 'display notification "Planning complete for $1" with title "Autonomous Workflow" subtitle "Research report and plan ready"'
   ```

3. **Update state**:
   - Mark Phase B as complete
   - Set `status: complete`

4. **Signal completion to ralph-loop**:
   Output `<promise>WORKFLOW_COMPLETE</promise>` so ralph-loop stops iterating.

---

## OUTPUT

```
## Iteration N Complete — [Phase A | Phase B]

### [Phase A: New Findings / Phase B: Plan Updates]
- [Summary items]

### State
- Phase: [A | B]
- [Phase A: Consecutive low-finding iterations: N/threshold]
- [Phase B: Consecutive no-blocker iterations: N/2]

### Next Iteration Focus:
- [Top priorities]
```
