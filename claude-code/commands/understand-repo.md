# Instructions

You are performing a deep technical analysis of this codebase. Your goal is to understand it as thoroughly as a senior engineer joining the team would need to. DO NOT EDIT ANY CODE, MAKE ANY CHANGES, OR COMMIT ANYTHING.

## Methodology

### Principles

1. **Code over documentation**: Treat README files, comments, and docs as *hypotheses* to verify against actual code. Flag any discrepancies you find—stale docs are common and important to surface.

2. **Trace actual execution paths**: For key functionality, trace how data/control actually flows through the system rather than relying on stated intentions.

3. **Verify, Don't Guess:** If you see a function call `processPayment()`, do not guess what it does based on the name. Find the definition and verify the logic.

### PHASE 1: DISCOVERY (The Map)
*Action: Run terminal commands or file searches to build your mental map.*
1.  **Map the Territory:** Run `ls -R` or `tree` (excluding node_modules/vendor/target) to understand the physical structure of the project.
2.  **Verify the Stack:** specific dependency files (e.g., `package.json`, `go.mod`, `pom.xml`, `requirements.txt`) to confirm the *actual* libraries and versions used.
3.  **Locate Entry Points:** Find the *actual* production entry points (e.g., `index.ts`, `main.go`, `wsgi.py`, Dockerfiles).

### PHASE 2: DEEP DIVE (The Logic)
*Action: Select the most important core workflows to understand (e.g., "Data Ingestion" or the main business logic) and trace them end-to-end.*
1.  **Architecture Pattern:** Determine if this is Monolithic, Microservices, Hexagonal, or Event-Driven based on how modules import each other.
2.  **Boundaries & Contracts:** Identify the key interfaces. Are they strict (e.g., TypeScript interfaces, gRPC protos) or loose? How do modules communicate (HTTP, Message Bus, Direct calls)?
3.  **Data Strategy:** Where is the state? (DB, Cache, In-memory). Verify the ORM or database access patterns.

## Analysis Structure

### 1. System Purpose & Domain
What problem does this system solve? What domain concepts are encoded in the code? Identify the core domain entities and their relationships based on actual code (models, types, schemas).

### 2. Technology Stack
- Languages, frameworks, major dependencies
- Infrastructure/deployment (inferred from configs, IaC, CI/CD)
- External service integrations

### 3. Architecture
- **High-level pattern**: Monolith, microservices, modular monolith, etc.
- **Component map**: What are the major modules/packages/services? Draw the dependency graph.
- **Data architecture**: Databases, caches, queues, event buses. How does data flow and persist?

### 4. Boundaries & Interfaces
For each major component boundary:
- What is the interface contract? (APIs, function signatures, message schemas)
- What assumptions does each side make?
- Where is coupling tight vs. loose?
- Are there clear abstraction layers or is it spaghetti?

### 5. Key Design Decisions & Tradeoffs
Identify the significant architectural choices and analyze:
- What was chosen and what alternatives were likely considered
- What tradeoffs does this create, what was sacrificed (performance, complexity, flexibility, etc.) 
- Identify areas of high complexity, metaprogramming, or obvious hacks.
- Identify any technical debt or constraints this creates

### 6. Code Quality & Patterns
- Recurring patterns and idioms used
- Testing strategy (unit, integration, e2e—based on actual test files)
- Error handling approach
- Configuration management

### 7. Documentation Accuracy Audit
List specific discrepancies between docs/READMEs and actual implementation.

### 8. Open Questions & Ambiguities
What couldn't you determine from the code alone? What would you ask the original authors?

## Output Format
- Use concrete code references (file paths, function names) to support claims
- Include simplified diagrams where helpful (ASCII or mermaid)
- Prioritize insight density over comprehensiveness—focus on what matters most for understanding this specific system