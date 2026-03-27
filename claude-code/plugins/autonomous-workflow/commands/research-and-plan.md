---
description: "Mode 2: Autonomous deep research followed by scoping interview + rigorous 4-artifact planning (requirements, architecture, test plan, implementation plan) with cross-examination"
model: opus
argument-hint: <project-name> "Your detailed research and planning prompt..." --research-iterations N --plan-iterations N
---

# ABOUTME: Mode 2 command that runs research (Phase A) then scoping interview (B0) + rigorous 4-phase planning (Phase B).
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
   - Do NOT create any planning artifacts yet — they get created during Phase B sub-phases

3. Create empty bibliography file `docs/autonomous/$1/research/sources.bib`

4. Create `docs/autonomous/$1/research/research-progress.md` following the same format as Mode 1 (including the `## Methodological Quality` section for tracking evidence gap counts).

5. Parse budgets:
   - `research_budget` from `--research-iterations` (default: 30)
   - `planning_budget` from `--plan-iterations` (default: 20)

6. Create state file `.claude/autonomous-$1-research-state.md`:
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
     <the full invocation command>
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
   1. .claude/autonomous-$1-research-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/planning/$1-scoping-questions.md (after B0)
   4. docs/autonomous/$1/planning/$1-functional-requirements.md (after B1)
   5. docs/autonomous/$1/planning/$1-architecture-plan.md (after B2)
   6. docs/autonomous/$1/planning/$1-test-plan.md (after B3)
   7. docs/autonomous/$1/planning/$1-implementation-plan.md (after B3)
   8. CLAUDE.md
   ```

### If state file EXISTS:

1. Read state file and extract `current_phase` and `planning_sub_phase`
2. Read `docs/autonomous/$1/research/$1-report.tex`
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

### Execution

Follow the same Steps 2-6 from `/autonomous-workflow:research` (spawn strategy-dependent parallel researcher agents, optionally repo-analysts, synthesize with contribution counting, run consistency audit per Step 4.5, update LaTeX with in-line citations per Step 5, update state with strategy tracking) but with the research focus above.

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

**Note: Phase A does NOT have Phase R→S synthesis. It transitions directly to Phase B.**

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

3. **Create planning directory**:
   - Create `docs/autonomous/$1/planning/`
   - Create `docs/autonomous/$1/planning/transcripts/`

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
   1. .claude/autonomous-$1-implementation-state.md (this file)
   2. docs/autonomous/$1/research/$1-report.tex
   3. docs/autonomous/$1/planning/$1-scoping-questions.md (after B0)
   4. docs/autonomous/$1/planning/$1-functional-requirements.md (after B1)
   5. docs/autonomous/$1/planning/$1-architecture-plan.md (after B2)
   6. docs/autonomous/$1/planning/$1-test-plan.md (after B3)
   7. docs/autonomous/$1/planning/$1-implementation-plan.md (after B3)
   8. CLAUDE.md
   ```

6. **Continue to Phase B** in this same iteration (do not exit yet)

---

## PHASE B: Planning

If `current_phase` is `"Phase B: Planning"`:

Read `planning_sub_phase` from the state file to determine which sub-phase to execute. The sub-phases execute in strict order: B0 → B1 → B2 → B3 → B4.

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

Write to `docs/autonomous/$1/planning/$1-scoping-questions.md`:

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
   Run via Bash: osascript -e 'display notification "Scoping questions ready for $1 — answer before planning continues" with title "Autonomous Workflow" subtitle "Waiting for Input"'
   ```

6. **Output**:
   ```
   ## Scoping Questions Generated

   Questions written to: docs/autonomous/$1/planning/$1-scoping-questions.md
   Total questions: N

   ⏸️ WORKFLOW PAUSED — Waiting for human to answer scoping questions.

   To resume:
   1. Answer the questions in the scoping questions file
   2. Update .claude/autonomous-$1-implementation-state.md:
      - Set status: in_progress
      - Set planning_sub_phase: "B1"
      - Set planning_sub_phase_iteration: 0
   3. Nudge this session to continue
   ```

The stop hook sees `status: waiting_for_input` and allows Claude Code to exit cleanly.

#### B0 → B1 Transition (After Human Answers)

When the workflow resumes (nudged by orchestrator after human answers):
1. Read `docs/autonomous/$1/planning/$1-scoping-questions.md` for answers
2. The state file should already have `planning_sub_phase: "B1"` and `status: in_progress` (set by orchestrator)
3. Mark `Phase B0: Scoping Interview` as complete `[x]`
4. Proceed to B1

**All subsequent sub-phases (B1-B4) MUST read the scoping answers** and incorporate them into their work. The answers are as authoritative as the research findings.

---

### SUB-PHASE B1: Functional Requirements

**Goal**: Produce `docs/autonomous/$1/planning/$1-functional-requirements.md`

#### B1 — First Iteration

1. **Read the scoping answers** at `docs/autonomous/$1/planning/$1-scoping-questions.md` (with human's answers). These answers are authoritative — they override any conflicting research findings on matters of scope, priorities, and preferences.

2. **Spawn 3 parallel requirements-analyst agents**, each focused on a different category:

```
Task tool with subagent_type='autonomous-workflow:requirements-analyst' (3 parallel instances)

Instance 1 — Core Functionality:
prompt: "Derive core functional requirements for project '$1'.
Research report: docs/autonomous/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/autonomous/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: primary user-facing behaviors, core data transformations, main API endpoints, essential workflows."

Instance 2 — Edge Cases & Constraints:
prompt: "Derive edge case requirements and system constraints for project '$1'.
Research report: docs/autonomous/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/autonomous/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: boundary conditions, error handling, performance requirements, scalability constraints, security requirements, input validation, concurrent access."

Instance 3 — External Integrations & Data:
prompt: "Derive external integration and data requirements for project '$1'.
Research report: docs/autonomous/$1/research/$1-report.tex (read this thoroughly)
Scoping answers: docs/autonomous/$1/planning/$1-scoping-questions.md (read human's answers — these are authoritative)
Original prompt: <$2>
Focus on: external API integrations, data storage requirements, data flow, authentication/authorization, third-party service dependencies, API key/credential requirements."
```

3. **Spawn 2 parallel researcher agents** for domain requirements validation:

```
Task tool with subagent_type='autonomous-workflow:researcher' (2 parallel instances)

Instance 1 — Competitive Feature Analysis:
prompt: "Strategy: deep-dive
Research question: What features do similar products/solutions to '$1' provide? What are the must-have vs nice-to-have features in this space? Research report: docs/autonomous/$1/research/$1-report.tex"

Instance 2 — Requirements Pitfalls:
prompt: "Strategy: deep-dive
Research question: What are common requirements mistakes and overlooked requirements when building systems similar to '$1'? What do teams typically forget to specify? Research report: docs/autonomous/$1/research/$1-report.tex"
```

4. **Synthesize** all agent outputs into the functional requirements document:

Write to `docs/autonomous/$1/planning/$1-functional-requirements.md`:

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
Task tool with subagent_type='autonomous-workflow:plan-critic' (2 parallel instances)

Instance 1: "Scrutinize the functional requirements for completeness and testability.
Requirements: docs/autonomous/$1/planning/$1-functional-requirements.md
Research report: docs/autonomous/$1/research/$1-report.tex
Scoping answers: docs/autonomous/$1/planning/$1-scoping-questions.md
Focus: Are all research findings reflected? Are acceptance criteria specific enough? Any MUST requirements missing?"

Instance 2: "Scrutinize the functional requirements for feasibility and consistency.
Requirements: docs/autonomous/$1/planning/$1-functional-requirements.md
Research report: docs/autonomous/$1/research/$1-report.tex
Scoping answers: docs/autonomous/$1/planning/$1-scoping-questions.md
Focus: Are requirements contradictory? Are external dependency requirements realistic? Any requirements that can't be implemented?"
```

2. **Spawn 1-2 researcher agents** for any gaps the critics identified

3. **Update** the requirements document, addressing BLOCKER and CONCERN issues

#### B1 → B2 Transition

When `planning_sub_phase_iteration >= b1_budget`:
1. Mark `Phase B1: Functional Requirements` as complete in checklist
2. Set `planning_sub_phase: "B2"`
3. Reset `planning_sub_phase_iteration: 0`

---

### SUB-PHASE B2: Architecture Plan

**Goal**: Produce `docs/autonomous/$1/planning/$1-architecture-plan.md`

#### B2 — First Iteration

1. **Spawn 5 parallel researcher agents** (inspired by dev-workflow Phase 4):

```
Task tool with subagent_type='autonomous-workflow:researcher' (5 parallel instances)

Instance 1 — Architecture Patterns:
prompt: "Strategy: deep-dive
Research focus: Architecture patterns for systems similar to '$1'. Read docs/autonomous/$1/planning/$1-functional-requirements.md for what the system must do. Read docs/autonomous/$1/planning/$1-scoping-questions.md for human's preferences. Look for design patterns, component decomposition strategies, and proven approaches."

Instance 2 — Technology Evaluation:
prompt: "Strategy: deep-dive
Research focus: Technology and library evaluation for '$1'. Read docs/autonomous/$1/planning/$1-functional-requirements.md. Compare candidate frameworks, check maintenance status, community health, known issues."

Instance 3 — Data Modeling:
prompt: "Strategy: deep-dive
Research focus: Data modeling and storage patterns for '$1'. Read docs/autonomous/$1/planning/$1-functional-requirements.md. Schema design, data flow patterns, state management, storage trade-offs."

Instance 4 — API Design:
prompt: "Strategy: deep-dive
Research focus: API design patterns and interface contracts for '$1'. Read docs/autonomous/$1/planning/$1-functional-requirements.md. REST/GraphQL conventions, versioning, error handling, contract-first approaches."

Instance 5 — Infrastructure:
prompt: "Strategy: deep-dive
Research focus: Infrastructure and deployment for '$1'. Read docs/autonomous/$1/planning/$1-functional-requirements.md. Containerization, scaling, monitoring, deployment pipelines."
```

2. **Synthesize** research into the architecture plan. If the repo has existing code, also spawn 1-2 repo-analyst agents.

Write to `docs/autonomous/$1/planning/$1-architecture-plan.md`:

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

#### B2 → B3 Transition

When `planning_sub_phase_iteration >= b2_budget`:
1. Mark `Phase B2: Architecture` as complete in checklist
2. Set `planning_sub_phase: "B3"`
3. Reset `planning_sub_phase_iteration: 0`

---

### SUB-PHASE B3: Test Plan + Implementation Plan

**Goal**: Produce `docs/autonomous/$1/planning/$1-test-plan.md` AND `docs/autonomous/$1/planning/$1-implementation-plan.md`

#### B3 — First Iteration

1. **Spawn 4 parallel researcher agents**:

```
Instance 1 — Testing Strategies:
prompt: "Strategy: deep-dive
Research focus: Testing strategies for the tech stack chosen in docs/autonomous/$1/planning/$1-architecture-plan.md. Framework comparisons, mocking approaches, CI/CD integration."

Instance 2 — Implementation Patterns:
prompt: "Strategy: deep-dive  
Research focus: Implementation patterns for '$1' with the chosen tech stack. Read docs/autonomous/$1/planning/$1-architecture-plan.md. Real-world examples, code samples."

Instance 3 — Implementation Pitfalls:
prompt: "Strategy: deep-dive
Research focus: Common implementation pitfalls when building '$1'. Migration issues, breaking changes, deprecated APIs, gotchas. Read docs/autonomous/$1/planning/$1-architecture-plan.md."

Instance 4 — TDD Patterns:
prompt: "Strategy: deep-dive
Research focus: TDD patterns and test-first development approaches for the tech stack in docs/autonomous/$1/planning/$1-architecture-plan.md."
```

2. **Create both artifacts**.

Write to `docs/autonomous/$1/planning/$1-test-plan.md`:

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

Write to `docs/autonomous/$1/planning/$1-implementation-plan.md`:

```markdown
# Implementation Plan: $1

## Architecture Reference
See docs/autonomous/$1/planning/$1-architecture-plan.md

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

#### B3 → B4 Transition

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
Validate architecture decisions in docs/autonomous/$1/planning/$1-architecture-plan.md against current best practices."

Instance 2 — Technology Risk:
prompt: "Strategy: adversarial-challenge
Technology risk assessment for libraries/frameworks in docs/autonomous/$1/planning/$1-architecture-plan.md. Check for deprecation, CVEs, breaking changes."

Instance 3 — Known Issues:
prompt: "Strategy: deep-dive
Known bugs and issues in the libraries chosen in docs/autonomous/$1/planning/$1-architecture-plan.md."

Instance 4 — Alternative Approaches:
prompt: "Strategy: adversarial-challenge
Alternative approaches to implementing '$1' that might be simpler."

Instance 5 — Security Validation:
prompt: "Strategy: deep-dive
Security validation for '$1' against current threat models. OWASP top 10."
```

2. **Spawn 2 plan-reviewer agents** for cross-examination:

```
Task tool with subagent_type='autonomous-workflow:plan-reviewer' (2 parallel instances)

Instance 1: "Cross-examine Requirements ↔ Architecture ↔ Implementation Plan.
- Requirements: docs/autonomous/$1/planning/$1-functional-requirements.md
- Architecture: docs/autonomous/$1/planning/$1-architecture-plan.md  
- Test Plan: docs/autonomous/$1/planning/$1-test-plan.md
- Implementation Plan: docs/autonomous/$1/planning/$1-implementation-plan.md
- Research: docs/autonomous/$1/research/$1-report.tex
Focus: requirements coverage, component-to-requirement mapping, build order correctness, external dependency audit."

Instance 2: "Cross-examine Test Plan ↔ Requirements ↔ Architecture.
- Requirements: docs/autonomous/$1/planning/$1-functional-requirements.md
- Architecture: docs/autonomous/$1/planning/$1-architecture-plan.md
- Test Plan: docs/autonomous/$1/planning/$1-test-plan.md
- Implementation Plan: docs/autonomous/$1/planning/$1-implementation-plan.md
- Research: docs/autonomous/$1/research/$1-report.tex
Focus: test coverage gaps, feasibility concerns, research-plan contradictions, practical implementation risks."
```

3. **Synthesize** all findings:
   - BLOCKER issues: must be resolved in this iteration (update the relevant artifact)
   - CONCERN issues: address if straightforward, track otherwise
   - SUGGESTION issues: incorporate the good ones
   - Write a cross-examination log to `docs/autonomous/$1/planning/cross-examination-log.md` (append each iteration's findings)

4. **Update ALL four artifacts** as needed to resolve issues

5. **Update sources.bib** with any new sources from validation research

#### B4 Completion

When `planning_sub_phase_iteration >= b4_budget`:

1. Mark `Phase B4: Cross-Examination` as complete in checklist
2. Set `status: complete` in `.claude/autonomous-$1-implementation-state.md`
3. **Compile research report** (final version):
   Spawn `autonomous-workflow:latex-compiler`
4. Send macOS notification:
   ```
   Run via Bash: osascript -e 'display notification "Planning complete for $1 — 4 artifacts ready for review" with title "Autonomous Workflow" subtitle "Planning"'
   ```

The Stop hook verifies `status: complete` AND both `total_iterations_research >= research_budget` AND `total_iterations_planning >= planning_budget` before allowing the workflow to end.

---

## State Update (Every Iteration in Phase B)

After each Phase B iteration (B1-B4, not B0):

1. Increment `iteration` and `total_iterations_planning`
2. Increment `planning_sub_phase_iteration`
3. Check if sub-phase budget is exhausted → transition to next sub-phase
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
