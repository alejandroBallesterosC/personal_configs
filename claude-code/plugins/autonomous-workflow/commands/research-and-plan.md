---
description: "Mode 2: Autonomous deep research followed by iterative implementation plan design"
model: opus
argument-hint: <project-name> "Your detailed research and planning prompt..." [research-budget]
---

# ABOUTME: Mode 2 command that runs research (Phase A) then iterative plan design (Phase B).
# ABOUTME: Phase A->B transition is budget-based; planning runs until ralph-loop stops it.

# Autonomous Research + Plan

**Project**: $1
**Prompt**: $2
**Research Budget**: $3 (optional — number of research iterations before transitioning to planning. Default: 30)

## Objective

Run ONE ITERATION of research (Phase A) or planning (Phase B) for the given project. The workflow transitions from research to planning when the research iteration budget is exhausted. Ralph-loop calls this command repeatedly.

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
   - Read the report template, replace `PLACEHOLDER_TITLE` with a research-focused title
   - Write to `docs/autonomous/$1/research/$1-report.tex`
   - Do NOT create the implementation plan yet — it gets created at Phase A->B transition

3. Create empty bibliography file `docs/autonomous/$1/research/sources.bib`

4. Parse research budget: if $3 is provided and is a number, use it; otherwise default to 30.

5. Create state file `docs/autonomous/$1/research/$1-state.md`:
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
   research_budget: 30
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
   - [ ] Phase B: Planning

   ## Research Progress
   - Sources consulted: 0
   - Key findings: 0
   - Open questions: 5
   - Sections in report: 0

   ## Strategy History
   | Strategy | Iterations | Contributions | Rotated At |
   |----------|-----------|---------------|------------|

   ## Planning Progress
   - Components designed: 0
   - Critic issues resolved: 0
   - Open design decisions: 0

   ## Open Questions
   1. [Derive 5 initial questions focused on technical feasibility, competitive landscape, architecture patterns, defensibility, and technology stack]

   ## Context Restoration Files
   1. docs/autonomous/$1/research/$1-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/implementation/$1-implementation-plan.md (after Phase B starts)
   4. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file and extract `current_phase`
2. Read `docs/autonomous/$1/research/$1-report.tex`
3. If Phase B: also read `docs/autonomous/$1/implementation/$1-implementation-plan.md`
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

Follow the same Steps 2-6 from `/autonomous-workflow:research` (spawn strategy-dependent parallel researcher agents, optionally repo-analysts, synthesize with contribution counting, update LaTeX, update state with strategy tracking) but with the research focus above.

Follow Step 7 from `/autonomous-workflow:research` for strategy rotation (rotate strategies on low contributions, never auto-terminate).

### Phase Transition Check

After updating the state file and checking strategy rotation, check:

If `total_iterations_research >= research_budget`:

1. **Compile research report to PDF**:
   Spawn `autonomous-workflow:latex-compiler` agent:
   ```
   Task tool with subagent_type='autonomous-workflow:latex-compiler'
   prompt: "Compile docs/autonomous/$1/research/$1-report.tex to PDF. The working directory is docs/autonomous/$1/research/."
   ```

2. **Send macOS notification**:
   ```
   Run via Bash: osascript -e 'display notification "Research budget reached — transitioning to planning" with title "Autonomous Workflow" subtitle "$1"'
   ```

3. **Create implementation directory and plan document**:
   - Create `docs/autonomous/$1/implementation/` and `docs/autonomous/$1/implementation/transcripts/`
   - Create the implementation plan as Markdown at `docs/autonomous/$1/implementation/$1-implementation-plan.md`:
     ```markdown
     # Implementation Plan: $1

     ## Executive Summary
     [Brief overview of what will be built and why]

     ## Architecture
     [System architecture, component diagram, data flow]

     ## Components
     ### Component 1: <name>
     - **Purpose**:
     - **Interface**:
     - **Dependencies**:

     ## Implementation Sequence
     1. [Ordered list of implementation steps]

     ## Defensibility
     [Why this approach is sound, trade-offs considered]

     ## Open Design Decisions
     [Unresolved choices to be refined during planning iterations]
     ```
   - Populate initial sections based on research findings

4. **Update research state**:
   - Mark Phase A as complete in the checklist
   - Set `status: complete` in `docs/autonomous/$1/research/$1-state.md`

5. **Create implementation state file** at `docs/autonomous/$1/implementation/$1-state.md`:
   ```yaml
   ---
   workflow_type: autonomous-research-plan
   name: $1
   status: in_progress
   current_phase: "Phase B: Planning"
   iteration: <current iteration + 1>
   total_iterations_research: <from research state>
   total_iterations_planning: 0
   sources_cited: <from research state>
   findings_count: <from research state>
   research_budget: <from research state>
   current_research_strategy: <from research state>
   research_strategies_completed: <from research state>
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   ---

   # Autonomous Workflow State: $1

   ## Current Phase
   Phase B: Planning

   ## Original Prompt
   <copied from research state>

   ## Completed Phases
   - [x] Phase A: Research
   - [ ] Phase B: Planning

   ## Planning Progress
   - Components designed: 0
   - Critic issues resolved: 0
   - Open design decisions: 0

   ## Context Restoration Files
   1. docs/autonomous/$1/implementation/$1-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/implementation/$1-implementation-plan.md
   4. CLAUDE.md
   ```

6. **Continue to Phase B** in this same iteration (do not exit yet)

---

## PHASE B: Planning Iteration

If `current_phase` is `"Phase B: Planning"`:

### Step B1: Spawn Parallel Planning Agents

In a SINGLE message with multiple Task tool calls, spawn:

**2 plan-architect agents** (parallel), each assigned a different section of the plan:
```
Task tool with subagent_type='autonomous-workflow:plan-architect'
prompt: "Review and improve the '<section-name>' section of the plan.

Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md
Research report: docs/autonomous/$1/research/$1-report.tex

Read both documents. Propose specific improvements to this section grounded in the research findings."
```

**2 plan-critic agents** (parallel), each scrutinizing a different aspect:
```
Task tool with subagent_type='autonomous-workflow:plan-critic'
prompt: "Scrutinize the '<aspect>' of the plan against research findings.

Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md
Research report: docs/autonomous/$1/research/$1-report.tex

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
prompt: "Strategy: source-verification

Validate the following claims made in an implementation plan: <claims>. Check if they are supported by credible sources."
```

### Step B4: Update Plan

Write the updated `docs/autonomous/$1/implementation/$1-implementation-plan.md`.

### Step B5: Update State

1. Increment `iteration` and `total_iterations_planning`
2. Update `## Planning Progress` counts

Planning runs until `ralph-loop --max-iterations` stops the workflow.

**NEVER emit `<promise>WORKFLOW_COMPLETE</promise>` from Mode 2.**
Only `ralph-loop --max-iterations` stops this workflow.

---

## OUTPUT

```
## Iteration N Complete — [Phase A | Phase B]

### [Phase A: Contributions / Phase B: Plan Updates]
- [Summary items]

### State
- Phase: [A | B]
- [Phase A: Strategy: <name>, Contributions: N, Low-contribution streak: N/threshold]
- [Phase A: Research budget: N/budget iterations used]
- [Phase B: Planning iteration: N]

### Next Iteration Focus:
- [Top priorities]
```
