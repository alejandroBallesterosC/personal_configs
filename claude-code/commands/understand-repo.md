---
description: Iteratively explore and document codebase understanding across multiple passes
argument-hint: [iterations=3] [output=CODEBASE.md]
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit
---

# Iterative Codebase Understanding

You will perform **${1:-3} iterations** of codebase exploration, persisting all findings to **${2:-CODEBASE.md}**.

## Critical: Context Survival

Write findings to the markdown file immediately as you discover them. The file is your persistent memory—if context is compacted, re-read it to restore state.

**Rules:**
- Write findings to ${2:-CODEBASE.md} IMMEDIATELY after discovering them
- If you notice context was compacted, FIRST read ${2:-CODEBASE.md} to restore state
- Never keep important findings only in your working memory
- Update the markdown incrementally with new findings - don't wait until "done"

---

## Iteration Protocol

### Iteration 1: Discovery (The Map)
*Action: Use the task tool for parallelized exploration by running terminal commands or file searches to build your mental map.*
1.  **Create ${2:-CODEBASE.md}** for writing your findings to it as you go.
2.  **Map the Territory:** Run `ls -R` or `tree` (excluding node_modules/vendor/target) to understand the physical structure of the project.
3.  **Verify the Stack:** Explore build system, dependencies (e.g., `package.json`, `go.mod`, `pom.xml`, `requirements.txt`), and tooling to confirm the libraries and versions used.
4.  **Locate Entry Points** Find the *actual* production entry points (e.g., `index.ts`, `main.go`, `wsgi.py`, Dockerfiles).
5.  **Explore External Integrations and APIs**
6.  **End With "Open Questions"** - list 5-10 high priority questions you have about the codebase that would most improve your understanding in ${2:-CODEBASE.md}

Example Discovery Commands:
```bash
# Structure (exclude noise)
tree -L 3 -I "node_modules|vendor|target|dist|.git|__pycache__|*.pyc"

# Dependencies
cat package.json 2>/dev/null || cat requirements.txt 2>/dev/null || cat go.mod 2>/dev/null || cat Cargo.toml 2>/dev/null

# Entry points
find . -name "main.*" -o -name "index.*" -o -name "app.*" | grep -v node_modules

# Recent activity (what's being worked on)
git log --oneline -20 2>/dev/null

# Test patterns
find . -type f \( -name "*test*" -o -name "*spec*" \) | head -20
```

### Iteration 2: Deep Dive (The Logic)
*Action: Select the most important core workflows to understand (e.g., "Data Ingestion" or the main business logic) and trace them end-to-end.*
1. **Read ${2:-CODEBASE.md}** to restore context if context was compacted.
2.  **Architecture Pattern:** Determine if this is Monolithic, Microservices, Hexagonal, or Event-Driven based on how modules import each other.
3.  **Boundaries & Contracts:** Identify the key interfaces. Are they strict (e.g., TypeScript interfaces, gRPC protos) or loose? How do modules communicate (HTTP, Message Bus, Direct calls)?
4.  **Data Strategy:** Where is the state? (DB, Cache, In-memory). Verify the ORM or database access patterns.
5.  **End With "Open Questions"** - Add 5-10 high priority questions you have about the codebase that would most improve your understanding in ${2:-CODEBASE.md}

### Iterations 3 through ${1:-3}: Explore Open Questions
*Action: Investigate open questions.*
1. **Read ${2:-CODEBASE.md}** to restore context if context was compacted.
2. **Select the 3-5 highest priority open questions** to investigate
3. **Trace execution paths** - follow actual code flow, not documentation claims
4. **Refresh Open Questions** - remove answered, add newly discovered

### Final: Synthesis
1. **Read ${2:-CODEBASE.md}** completely
2. **Present summary** to user in CLI with key insights

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

## 9. Ambiguities:
What couldn't you determine from the code alone? What would you ask the original authors?
```

---

## Constraints

- **DO NOT** edit application code
- **DO NOT** commit anything  
- **ONLY** write to ${2:-CODEBASE.md}
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
