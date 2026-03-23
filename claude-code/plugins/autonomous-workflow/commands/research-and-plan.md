---
description: "Mode 2: Autonomous deep research followed by iterative implementation plan design"
model: opus
argument-hint: <project-name> "Your detailed research and planning prompt..." --research-iterations N --plan-iterations N
---

# ABOUTME: Mode 2 command that runs research (Phase A) then iterative plan design (Phase B).
# ABOUTME: Phase A->B transition is budget-based; planning runs until its budget is exhausted.

# Autonomous Research + Plan

**Project**: $1
**Prompt**: $2
**All Arguments**: $ARGUMENTS

Parse optional flags from **All Arguments**:
- `--research-iterations N`: number of research iterations before transitioning to planning (default: 30)
- `--plan-iterations N`: number of planning iterations (default: 15)

## Objective

Run ONE ITERATION of research (Phase A) or planning (Phase B) for the given project. The workflow transitions from research to planning when the research iteration budget is exhausted. The Stop hook re-feeds this command for multi-iteration execution.

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
   - Read the report template, replace `PLACEHOLDER_TITLE` with a research-focused title
   - Write to `docs/autonomous/$1/research/$1-report.tex`
   - Do NOT create the implementation plan yet — it gets created at Phase A->B transition

3. Create empty bibliography file `docs/autonomous/$1/research/sources.bib`

4. Parse research budget from `--research-iterations` flag in All Arguments. If not provided, default to 30.
   Parse planning budget from `--plan-iterations` flag in All Arguments. If not provided, default to 15.

5. Create state file `.claude/autonomous-$1-research-state.md`:
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
   research_budget: <parsed from --research-iterations flag, or 30 if not provided>
   planning_budget: <parsed from --plan-iterations flag, or 15 if not provided>
   current_research_strategy: wide-exploration
   research_strategies_completed: []
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   command: |
     <the full invocation command, e.g. /autonomous-workflow:research-and-plan '$1' '$2' --research-iterations N --plan-iterations N>
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
   1. .claude/autonomous-$1-research-state.md (this file)
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

Follow the same Steps 2-6 from `/autonomous-workflow:research` (spawn strategy-dependent parallel researcher agents, optionally repo-analysts, synthesize with contribution counting, run consistency audit per Step 4.5, update LaTeX with in-line citations and Synthesis section per Step 5, update state with strategy tracking) but with the research focus above.

Follow Step 7 from `/autonomous-workflow:research` for strategy rotation (rotate through all 9 strategies on low contributions, never auto-terminate). The strategies are:
1. `wide-exploration`
2. `source-verification`
3. `methodological-critique` (uses `methodological-critic` agent instead of `researcher`)
4. `contradiction-resolution`
5. `deep-dive`
6. `adversarial-challenge`
7. `gaps-and-blind-spots`
8. `temporal-analysis`
9. `cross-domain-synthesis`

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
   - Set `status: complete` in `.claude/autonomous-$1-research-state.md`

5. **Create implementation state file** at `.claude/autonomous-$1-implementation-state.md`:
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
   planning_budget: <from research state>
   current_research_strategy: <from research state>
   research_strategies_completed: <from research state>
   strategy_rotation_threshold: 3
   contributions_last_iteration: 0
   consecutive_low_contributions: 0
   command: |
     <same command from research state>
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
   1. .claude/autonomous-$1-implementation-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/implementation/$1-implementation-plan.md
   4. CLAUDE.md
   ```

6. **Continue to Phase B** in this same iteration (do not exit yet)

---

## PHASE B: Planning Iteration

If `current_phase` is `"Phase B: Planning"`:

### Step B1: Identify Technical Research Needs

Read the current plan at `docs/autonomous/$1/implementation/$1-implementation-plan.md` and the research report. Identify what technical decisions the plan needs to make or refine this iteration. Categorize research needs into two types:

**Technical implementation research** (spawn for EVERY planning iteration):
Identify 2-4 specific technical questions the plan needs answered. These typically fall into:
- Architecture patterns and best practices for the specific system being built
- Technology stack evaluation (frameworks, libraries, databases — trade-offs and recommendations)
- Dependencies and third-party services (APIs, SDKs, pricing, rate limits, integration complexity)
- Relevant open-source repositories and reference implementations
- Deployment and infrastructure patterns
- Testing strategies for the specific tech stack

**Academic/literature research** (spawn ONLY when the project involves technically complex domains):
Determine whether the project requires academic grounding. Spawn academic researchers when the implementation involves domains like:
- AI/ML algorithms, model architectures, training pipelines, or inference optimization
- Statistical methods, prediction models, or probabilistic systems
- Cryptography, consensus algorithms, or formal verification
- Signal processing, computer vision, NLP, or other specialized computational domains
- Novel algorithmic approaches where peer-reviewed research would inform implementation choices

Do NOT spawn academic researchers for straightforward implementations like CRUD applications, standard ETL pipelines, typical web/mobile apps, REST API services, or infrastructure automation — for these, the technical implementation research above is sufficient.

### Step B2: Spawn Technical Research Agents

In a SINGLE message, spawn ALL research agents for this iteration:

**2-3 technical researcher agents** (parallel, every iteration):
```
Task tool with subagent_type='autonomous-workflow:researcher'
prompt: "Strategy: deep-dive

Technical implementation research for a software project.

Project: $1
Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md (read this first)

Research question: <specific technical question from Step B1>

Focus on:
- Production-grade libraries and frameworks (not toy examples)
- Architecture patterns used by similar real-world systems
- GitHub repositories with reference implementations
- Official documentation for recommended dependencies
- Known pitfalls, performance characteristics, and scaling considerations
- Community consensus on best practices (Stack Overflow, engineering blogs, HN)

Return findings with full structured source entries for BibTeX integration."
```

**1-2 academic researcher agents** (parallel, ONLY when Step B1 determines the domain requires it):
```
Task tool with subagent_type='autonomous-workflow:researcher'
prompt: "Strategy: deep-dive

Academic literature review for a technically complex implementation.

Project: $1
Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md (read this first)

Research question: <specific academic/algorithmic question from Step B1>

Focus on:
- Peer-reviewed papers and preprints (arXiv, conference proceedings)
- Survey papers that compare approaches
- Reference implementations accompanying papers (GitHub links)
- Practical considerations for production deployment of academic methods
- State-of-the-art benchmarks and baseline comparisons

Prefer papers from the last 3 years unless foundational. Include paper titles, authors, and publication venues in your source entries."
```

### Step B3: Spawn Parallel Planning Agents

After all research agents return, read their outputs and make them available to planning agents.

In a SINGLE message with multiple Task tool calls, spawn:

**2 plan-architect agents** (parallel), each assigned a different section of the plan:
```
Task tool with subagent_type='autonomous-workflow:plan-architect'
prompt: "Review and improve the '<section-name>' section of the plan.

Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md
Research report: docs/autonomous/$1/research/$1-report.tex

Technical research findings from this iteration:
<paste summarized findings from Step B2 researchers relevant to this section>

Read the plan and research report. Propose specific improvements to this section grounded in both the original research findings AND the technical research above. Prefer specific library/framework/tool recommendations backed by the technical research over generic suggestions."
```

**2 plan-critic agents** (parallel), each scrutinizing a different aspect:
```
Task tool with subagent_type='autonomous-workflow:plan-critic'
prompt: "Scrutinize the '<aspect>' of the plan against research findings.

Current plan: docs/autonomous/$1/implementation/$1-implementation-plan.md
Research report: docs/autonomous/$1/research/$1-report.tex

Technical research findings from this iteration:
<paste summarized findings from Step B2 researchers relevant to this aspect>

Read both documents. Identify logical conflicts, unsupported claims, feasibility concerns, and defensibility gaps. Flag any technical decisions that contradict the technical research findings."
```

### Step B4: Synthesize

1. Read all planning agent outputs (architects + critics)
2. Integrate architect proposals into the plan (prioritize changes backed by technical research)
3. Address critic issues:
   - BLOCKER issues: must be resolved in this iteration
   - CONCERN issues: address if straightforward, track otherwise
   - SUGGESTION issues: incorporate if they improve the plan without adding complexity
4. Count BLOCKER issues that remain unresolved
5. Update `docs/autonomous/$1/research/sources.bib` with BibTeX entries from any new sources discovered by technical/academic researchers (follow the same dedup rules from Phase A Step 5)

### Step B5: Update Plan

Write the updated `docs/autonomous/$1/implementation/$1-implementation-plan.md`.

### Step B6: Update State

1. Increment `iteration` and `total_iterations_planning`
2. Update `## Planning Progress` counts

### Completion Check

After updating the state file, check:

If `total_iterations_planning >= planning_budget`:
1. Set `status: complete` in `.claude/autonomous-$1-implementation-state.md`
2. Send macOS notification:
   ```
   Run via Bash: osascript -e 'display notification "Planning budget reached for $1" with title "Autonomous Workflow" subtitle "Planning"'
   ```

The Stop hook verifies `status: complete` AND both `total_iterations_research >= research_budget` AND `total_iterations_planning >= planning_budget` before allowing the workflow to end.

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
