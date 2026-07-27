---
name: understand-repo
description: Understand a codebase in a single pass using parallel subagents. User-invoked only.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
effort: xhigh
---

# Understand Repo

Produce a single-pass understanding of this codebase using parallel subagents, then present it directly in your response.

## Methodology

1. **Code over documentation**: READMEs and comments are hypotheses. Check them against the code and flag discrepancies.
2. **Trace actual execution**: For key functionality, follow real data and control flow. Function names lie.
3. **Explore by concept, not directory**: Search for "authentication" across the codebase, not "what's in src/auth/".
4. **Ground every claim**: Find the definition, read the implementation, check the tests.

## Step 1: Launch Parallel Explorers

The user invoked this skill to get a parallel sweep, so delegate rather than reading serially yourself. Launch one `subagent_type: "Explore"` agent per section below, all in a single message. Five sections means up to five agents; collapse two into one if the repo is small enough that their findings would overlap. Give each agent its full section text as its focus.

### Agent 1: System Purpose & Domain
> Identify what problem this codebase solves and its core domain entities and their relationships, based on actual code (models, types, schemas) — not just the README. Include file paths for the model/type definitions you find.

### Agent 2: Technology Stack
> Identify languages, frameworks, and their versions (from dependency files), infrastructure (Dockerfiles, IaC, CI configs), and external services (from env files, config). Cite the specific file each fact comes from.

### Agent 3: Architecture
> Identify the architectural pattern (monolith, microservices, modular monolith), map the major components and how they connect, and describe how data flows and persists (databases, caches, queues, event buses). Note enough detail to sketch a component diagram.

### Agent 4: Boundaries & Interfaces
> For each major boundary, identify the interface contract (APIs, function signatures, types, schemas), what assumptions each side makes, whether coupling is tight or loose, and whether abstraction layers are clear or tangled.

### Agent 5: Key Design Decisions & Tradeoffs
> Identify the significant architectural choices and analyze each: what was chosen versus the likely alternatives, what tradeoffs that creates (performance, complexity, flexibility), and where complexity, metaprogramming, or technical debt is concentrated.

## Step 2: Synthesize

Synthesize the agents' findings directly into your response with this structure:

```markdown
# [Project Name] — Codebase Understanding

## Architecture Diagram
[ASCII or mermaid diagram of the major components and how they connect]

## 1. System Purpose & Domain

## 2. Technology Stack

## 3. Architecture

## 4. Boundaries & Interfaces

## 5. Key Design Decisions & Tradeoffs
[Table: Decision | Chosen | Alternative | Tradeoff]

## Top Files to Read
8 to 15 items, ordered by priority. For each: file path, one line on why it matters.
```

Keep each section to a few paragraphs or a short table — this is an orientation document, not a transcript of what the subagents returned. Where subagents disagree, say so rather than picking one silently.

## Constraints

- Read-only: do not edit code, commit anything, or write any file unless the user explicitly asks for one.
- Use concrete `file:line` references for every claim.
- Keep "Top Files to Read" genuinely prioritized. Resist listing everything.
