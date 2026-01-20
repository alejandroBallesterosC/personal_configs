---
description: Iteratively explore and document codebase understanding across multiple passes
argument-hint: [iterations=3] [output=CODEBASE.md]
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit, Skill
---

# Iterative Codebase Understanding

You will perform **${1:-3} iterations** of codebase exploration using parallel subagents, persisting all findings to **${2:-CODEBASE.md}**. You will also update CLAUDE.md files using the writing-claude-md skill.

## Phase 0: Launch Parallel Code Explorers

**Immediately launch 3 agents in parallel** (in a single message with multiple Task tool calls) to explore different aspects of the codebase simultaneously:

### Agent 1: Structure & Stack Explorer
Launch with `subagent_type: "Explore"` and prompt:
> Explore the codebase structure and technology stack. Map directory structure (exclude node_modules/vendor/target/.git). Identify all dependency files (package.json, requirements.txt, go.mod, Cargo.toml). List all entry points (main.*, index.*, app.*, Dockerfile). Identify build/CI config files. Catalog environment/config files. Output a structured report.

### Agent 2: Architecture & Patterns Explorer
Launch with `subagent_type: "Explore"` and prompt:
> Explore the codebase architecture and patterns. Identify the architectural pattern (monolith, microservices, modular). Map module/package boundaries and imports. Find key interfaces, contracts, abstractions. Identify data models, schemas, type definitions. Analyze error handling and logging patterns. Output a structured report.

### Agent 3: Testing & Quality Explorer
Launch with `subagent_type: "Explore"` and prompt:
> Explore the testing strategy and code quality. Find all test files and frameworks. Analyze test patterns (unit, integration, e2e). Check linting/formatting config. Identify CI/CD workflows. Find documentation (README, docs/). Check recent git activity. Output a structured report.

**Wait for all agents to complete**, then synthesize their findings into ${2:-CODEBASE.md}.

---

## Critical: Context Survival

Write findings to the markdown file immediately as you discover them. The file is your persistent memory—if context is compacted, re-read it to restore state.

**Rules:**
- Write findings to ${2:-CODEBASE.md} IMMEDIATELY after discovering them
- If you notice context was compacted, FIRST read ${2:-CODEBASE.md} to restore state
- Never keep important findings only in your working memory
- Update the markdown incrementally with new findings - don't wait until "done"

---

## Iteration Protocol

### Iteration 1: Discovery Synthesis

1. **Create ${2:-CODEBASE.md}** with initial structure
2. **Synthesize agent findings** into the required sections
3. **Identify gaps** - what didn't the agents cover?
4. **End with "Open Questions"** - list 5-10 high priority questions

### Iteration 2: Deep Dive (The Logic)

1. **Read ${2:-CODEBASE.md}** to restore context
2. **Trace key workflows** end-to-end (auth, main business logic, data flow)
3. **Verify boundaries** - are contracts strict or loose?
4. **Analyze data strategy** - where is state? How does it flow?
5. **Update Open Questions** - add new, mark answered

### Iterations 3 through ${1:-3}: Explore Open Questions

1. **Read ${2:-CODEBASE.md}** to restore context
2. **Select 3-5 highest priority open questions**
3. **Trace execution paths** - follow actual code, not documentation claims
4. **Launch additional subagents** if needed for deep dives
5. **Refresh Open Questions** - remove answered, add newly discovered

---

## Final Phase: CLAUDE.md Update

After completing exploration, **invoke the writing-claude-md skill** and update CLAUDE.md:

1. **Check if CLAUDE.md exists** at project root
2. **If missing**: Create one following claude-md-guide best practices
3. **If exists**: Update it to reflect current codebase state

### CLAUDE.md Must Include (per writing-claude-md skill):
- Project overview (2-3 sentences)
- Architecture (key layers, boundaries)
- Key patterns (when/how to use)
- Code style conventions
- Testing (framework, location, commands)
- Common commands (build, lint, dev, test)
- Key files and their purposes
- Gotchas (learned from exploration)

**Keep under 300 lines.** Use @imports for detailed docs.

---

## Exploration Methodology

### Principles

1. **Code over documentation**: READMEs and comments are hypotheses. Verify against actual code. Flag discrepancies.

2. **Trace actual execution**: For key functionality, follow real data/control flow. Don't trust function names.

3. **Explore by concept, not directory**: Search for "authentication" across the codebase, not "what's in src/auth/"

4. **Verify, don't guess**: Find the definition. Read the implementation. Check the tests.

---

## Required Sections in ${2:-CODEBASE.md}

```markdown
# [Project Name] - Codebase Analysis

> Last updated: [timestamp]
> Iteration: [N of ${1:-3}]

## 1. System Purpose & Domain
What problem does this solve? Identify the core domain entities and their relationships based on actual code (models, types, schemas).
[Include: actual model/type definitions with file paths]

## 2. Technology Stack
- Languages & frameworks (with versions from dependency files)
- Infrastructure (from Dockerfiles, IaC, CI configs)
- External services (from env files, config)

## 3. Architecture
- **Pattern**: Monolith / Microservices / Modular monolith / etc.
- **Component diagram**: (ASCII or mermaid)
- **Data flow/architecture**: Databases, caches, queues, event buses. How does data flow and persist?

## 4. Boundaries & Interfaces
For each major boundary:
- Interface contract (APIs, function signatures, types, schemas)
- What assumptions does each side make?
- Coupling assessment (tight/loose)
- Are there clear abstraction layers or is it spaghetti?

## 5. Key Design Decisions & Tradeoffs
Identify the significant architectural choices and analyze:
- What was chosen and what alternatives were likely considered
- What tradeoffs does this create, what was sacrificed (performance, complexity, flexibility, etc.)
- Identify areas of high complexity, metaprogramming, or obvious hacks.
- Identify any technical debt or constraints this creates

| Decision  | Chosen | Alternative | Tradeoff       |
| --------- | ------ | ----------- | -------------- |
| [Example] | [X]    | [Y]         | [Cost/Benefit] |

## 6. Code Quality & Patterns
- Recurring patterns/idioms
- Testing strategy (based on actual test files)
- Error handling approach
- Configuration management

## 7. Documentation Accuracy Audit
List specific discrepancies between docs/READMEs and actual implementation.
| Doc Claim       | Reality          | File Reference |
| --------------- | ---------------- | -------------- |
| [What docs say] | [What code does] | [path:line]    |

## 8. Open Questions
- [ ] Question 1
- [ ] Question 2
- [ ] ...

## 9. Ambiguities
What couldn't you determine from the code alone? What would you ask the original authors?
```

---

## Constraints

- **DO NOT** edit application code
- **DO NOT** commit anything
- **ONLY** write to ${2:-CODEBASE.md} and CLAUDE.md
- Use **concrete file:line references** for every claim
- Prioritize **insight density** in ${2:-CODEBASE.md}

---

## On Context Compaction

If you see "Compacting context..." or your context feels fresh:

1. STOP what you're doing
2. Read ${2:-CODEBASE.md} completely
3. Check which iteration you're on
4. Continue from where you left off

The markdown file is your source of truth. Trust it.

---

## Summary of Execution

1. **Launch 3 parallel subagents** (structure, architecture, testing)
2. **Synthesize findings** into ${2:-CODEBASE.md}
3. **Iterate** through deep dives and open questions
4. **Update CLAUDE.md** using writing-claude-md skill
5. **Present summary** to user
