---
name: understand-repo
description: Understand a codebase in a single pass using parallel subagents. User-invoked only.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Understand Repo

Produce a single-pass understanding of this codebase using parallel subagents, then present it directly in your response. Do not write to any file unless the user explicitly asks you to.

## Methodology

1. **Code over documentation**: READMEs and comments are hypotheses. Verify against actual code. Flag discrepancies.
2. **Trace actual execution**: For key functionality, follow real data/control flow. Don't trust function names alone.
3. **Explore by concept, not directory**: Search for "authentication" across the codebase, not "what's in src/auth/".
4. **Verify, don't guess**: Find the definition. Read the implementation. Check the tests.

## Step 1: Launch 5 Parallel Explorers

Launch 5 agents in a single message (multiple Agent tool calls), each with `subagent_type: "Explore"`, one per section below. Give each agent the full section description as its focus so it knows exactly what to report back.

### Agent 1: System Purpose & Domain
> Identify what problem this codebase solves and its core domain entities and their relationships, based on actual code (models, types, schemas) — not just the README. Include file paths for the actual model/type definitions you find.

### Agent 2: Technology Stack
> Identify languages, frameworks, and their versions (from dependency files), infrastructure (Dockerfiles, IaC, CI configs), and external services (from env files, config). Cite the specific files each fact comes from.

### Agent 3: Architecture
> Identify the architectural pattern (monolith, microservices, modular monolith, etc.), map the major components and how they connect, and describe how data flows and persists (databases, caches, queues, event buses). Note enough detail to sketch a component diagram.

### Agent 4: Boundaries & Interfaces
> For each major boundary in the codebase, identify the interface contract (APIs, function signatures, types, schemas), what assumptions each side makes, whether coupling is tight or loose, and whether there are clear abstraction layers or it's tangled.

### Agent 5: Key Design Decisions & Tradeoffs
> Identify the significant architectural choices made in this codebase and analyze: what was chosen vs. likely alternatives, what tradeoffs this creates (performance, complexity, flexibility), and any areas of high complexity, metaprogramming, or obvious technical debt.

## Step 2: Synthesize

Once all 5 agents return, synthesize their findings directly into your response (not a file) with this structure:

```markdown
# [Project Name] — Codebase Understanding

## Architecture Diagram
[ASCII or mermaid diagram of major components and how they connect, built from Agent 3's findings]

## 1. System Purpose & Domain
[Agent 1's findings]

## 2. Technology Stack
[Agent 2's findings]

## 3. Architecture
[Agent 3's findings]

## 4. Boundaries & Interfaces
[Agent 4's findings]

## 5. Key Design Decisions & Tradeoffs
[Agent 5's findings, as a table: Decision | Chosen | Alternative | Tradeoff]

## Top Files to Read
A prioritized, manageable list (aim for 8-15 items, not an exhaustive inventory) of the most important files or functions to read to understand this codebase, ordered by priority. For each: file path, one line on why it matters.
```

## Constraints

- Do NOT edit any code.
- Do NOT commit anything.
- Do NOT write any file unless the user explicitly asks for one.
- Use concrete file:line references for every claim.
- Keep the final "Top Files to Read" list genuinely prioritized and manageable — resist the urge to list everything.
