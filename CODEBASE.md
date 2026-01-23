# Personal Configs - Codebase Analysis

> Last updated: 2026-01-23
> Iteration: 5 (phase reordering - architecture before plan)

## 1. System Purpose & Domain

**Development infrastructure repository** for AI-assisted workflows with Claude Code. Contains configuration, documentation, and automation - **no application code**.

**Core Domain Entities:**
- **Plugins**: Encapsulated workflow systems (TDD, Debug)
- **Agents**: Specialized AI workers with constrained tools (`claude-code/plugins/*/agents/*.md`)
- **Commands**: Orchestration entry points (`claude-code/plugins/*/commands/*.md`, `claude-code/commands/*.md`)
- **Skills**: Domain knowledge modules that auto-activate on context match (`claude-code/plugins/*/skills/*/SKILL.md`)
- **Hooks**: Automation triggers (PostToolUse events)

**Problem Solved:** Provides structured, repeatable AI-assisted development workflows with:
- TDD implementation with parallel exploration and review
- Hypothesis-driven debugging with instrumentation
- Configuration sync between repo and global `~/.claude/`

## 2. Technology Stack

| Category | Technology | Source |
|----------|------------|--------|
| Configuration | Markdown (workflows), JSON (configs), YAML (frontmatter) | All files |
| Automation | Bash shell scripts | `scripts/*.sh` |
| IDE Support | VS Code (15 tasks), Cursor (rules) | `.vscode/`, `.cursor/` |
| AI Runtime | Claude Code (Anthropic) | External dependency |
| MCP Servers | context7, fetch, exa, playwright | `global_mcp_settings.json` |

**External Dependencies:**
- **ralph-loop plugin** (required for TDD implement phase)
- **uv** (Python package management)
- **npx** (JavaScript package execution)
- Test frameworks: pytest, jest, vitest, go test, cargo test, rspec, minitest, mix

## 3. Architecture

**Pattern**: Modular Plugin System

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # Encapsulated workflow plugins
│   │   ├── tdd-workflow/           # 7 agents, 10 commands, 6 skills, hooks
│   │   │   ├── .claude-plugin/plugin.json
│   │   │   ├── agents/             # Specialized AI workers
│   │   │   ├── commands/           # Orchestration entry points
│   │   │   ├── skills/             # Auto-activating guidance
│   │   │   ├── hooks/              # PostToolUse triggers
│   │   │   └── scripts/            # Test detection & execution
│   │   └── debug-workflow/         # 4 agents, 7 commands, 1 skill
│   │       └── [same structure]
│   ├── commands/                   # 16 shared global commands
│   ├── docs/                       # Python, UV, Docker best practices
│   ├── CLAUDE.md                   # Global coding standards template
│   └── global_mcp_settings.json    # MCP server configuration
└── scripts/                        # 13 sync scripts (bidirectional)
```

**Data Flow:**

```
User Command → Plugin Command → Spawns Agents (via Task tool)
                    ↓
              Main Instance (owns feedback loop)
                    ↓
              Runs Tests/Verification
                    ↓
              State Files (docs/*.md)
```

**Key Architectural Decisions:**
1. Main instance owns verification loops (tests, reviews)
2. Subagents are stateless workers with constrained tools
3. Parallel for read operations (exploration, review)
4. Sequential for state-changing operations (TDD implementation)
5. Context checkpoints via file-based state persistence

## 4. Boundaries & Interfaces

### Plugin Boundary

**Contract**: Plugin manifest (`plugin.json`)
```json
{
  "name": "plugin-name",
  "description": "What it does",
  "version": "1.0.0"
}
```

**Coupling**: Loose - plugins are fully self-contained, no cross-plugin dependencies

### Agent Interface

**Contract**: YAML frontmatter in markdown
```yaml
---
name: agent-name
description: Activation trigger / role description
tools: [Tool1, Tool2, ...]    # Constrained capability
model: opus|sonnet            # Model assignment
---
```

**Coupling**: Tight with orchestrating command - agents designed for specific workflow phases

### Command Interface

**Contract**: YAML frontmatter + markdown body
```yaml
---
description: What this command does
model: opus|sonnet
argument-hint: <arg1> "<arg2>"
---
```

**Coupling**: Commands depend on agents they spawn, state files they read/write

### Skill Interface

**Contract**: YAML frontmatter in `SKILL.md`
```yaml
---
name: skill-name
description: When to auto-activate
---
```

**Coupling**: Loose - skills activate based on context matching, no explicit dependencies

### Hook Interface

**Contract**: `hooks.json` configuration
```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "..." }] }
    ]
  }
}
```

**Coupling**: Loose - hooks triggered by tool events, independent of workflow state

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Main instance owns tests | Orchestrator runs tests | Subagents run tests | Higher quality (orchestrator sees real output) vs. slower iteration |
| File-based state | Markdown in docs/ | Database, JSON | Human-readable + git-friendly vs. no schema validation |
| YAML frontmatter | Embedded metadata | Separate config files | Single source of truth vs. parsing complexity |
| Parallel exploration | 5 agents in parallel | Sequential exploration | Faster exploration vs. higher token cost |
| Context checkpoints | Manual /clear + /resume | Automatic context management | User control vs. workflow interruption |
| No mocking | Real APIs always | Mock for unit tests | Integration confidence vs. test speed |
| Phase validation on resume | Validate prerequisites + explicit sequences | Trust model to follow docs | Prevents phase skipping vs. more verbose instructions |

## 6. Code Quality & Patterns

### Recurring Patterns

**Orchestrator-Subagent Pattern:**
- Main instance spawns subagents via Task tool
- Subagents do ONE discrete task and return
- Main instance validates results (runs tests, reviews output)

**Parallel Agent Pattern:**
- Single command spawns N agents simultaneously
- Each agent explores from different angle
- Results synthesized into single document

**Context Checkpoint Pattern:**
- Save progress to docs/ at strategic points
- Prompt user to run /clear
- /reinitialize-context-after-clear-and-continue-workflow validates phase prerequisites before allowing continuation
- Provides explicit execution sequences (not just "where to start" but "what phases to complete")
- Phase validation prevents skipping (e.g., can't jump to Phase 7 without completing Phases 2-6)

### Testing Strategy

**Meta-testing framework** - provides test orchestration for external projects:
- Auto-detection: `scripts/detect-test-runner.sh` (pytest, jest, vitest, go, cargo, rspec, minitest, mix)
- Execution: `scripts/run-tests.sh`
- Auto-trigger: PostToolUse hook on Write|Edit

**TDD Methodology (from skills/tdd-guide):**
- RED: Write ONE failing test
- GREEN: Write MINIMAL code to pass
- REFACTOR: Improve while keeping tests green

### Error Handling

**Debugging Methodology (from debug-workflow):**
```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

- Hypothesis-first: Never fix without understanding root cause
- Evidence-driven: Let logs decide, not intuition
- Instrumentation pattern: `[DEBUG-H1]` tags in log statements

### Configuration Management

- MCP servers configured in `global_mcp_settings.json`
- API keys via environment variables (`${CONTEXT7_API_KEY}`, `${EXA_API_KEY}`)
- Bidirectional sync scripts maintain repo ↔ `~/.claude/` consistency

## 7. Documentation Accuracy Audit (Iteration 4)

### README.md - Updated and Accurate

README.md was rewritten (2026-01-23) to reflect current repository state:
- Accurate repository structure with plugins, scripts, docs
- Correct MCP servers (context7, fetch, exa, playwright)
- All major commands documented
- Plugin architecture explained
- Phase validation feature documented
- Sync scripts table included

### Confirmed Accurate

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| TDD workflow README accurate | 8-phase workflow (Phases 2-9), checkpoints, agents all match code | `tdd-workflow/README.md` |
| Debug workflow README accurate | 9-phase flow matches command implementation | `debug-workflow/README.md` |
| CLAUDE.md conventions | Applied throughout codebase | `claude-code/CLAUDE.md` |
| 16 shared commands | Confirmed - 16 .md files in commands/ | `claude-code/commands/` |
| TDD has 7 agents | Confirmed | `tdd-workflow/agents/` |
| Debug has 4 agents | Confirmed | `debug-workflow/agents/` |
| Hooks auto-run tests | PostToolUse on Write\|Edit triggers run-tests.sh | `tdd-workflow/hooks/hooks.json` |

## 8. Open Questions (Iteration 2 Answers)

- [x] **What is the exact integration pattern with ralph-loop plugin?**
  - **Answer**: TDD start.md invokes `/ralph-loop:ralph-loop` with a detailed prompt. The prompt includes context files, component details, and TDD cycle instructions. Ralph-loop manages iteration (`--max-iterations 50`, `--completion-promise "COMPONENT_COMPLETE"`). Main instance owns the outer loop, ralph-loop manages inner iteration.
  - **Source**: `tdd-workflow/commands/start.md:613-698`

- [x] **How do context checkpoints determine optimal timing?**
  - **Answer**: Manual heuristic - documentation quotes "60k tokens or 30% context" from community best practices. No automated detection. Checkpoints occur at fixed workflow points: after exploration (Phase 2), after planning/review (Phase 6), after E2E testing (Phase 8).
  - **Source**: `tdd-workflow/commands/1-start.md`

- [x] **Are there any undocumented hook configurations in debug-workflow?**
  - **Answer**: No - debug-workflow has no hooks directory. Only tdd-workflow has hooks (PostToolUse on Write|Edit).
  - **Source**: Directory listing shows no `debug-workflow/hooks/` exists

- [x] **What triggers skill auto-activation?**
  - **Answer**: Skills activate when their `description` field matches the current context. The skill explicitly states "Announce at start: 'I'm using the tdd-guide skill.'" suggesting the model self-identifies when activating.
  - **Source**: `tdd-workflow/skills/tdd-guide/SKILL.md:18-19`

- [x] **How does marketplace.json plugin discovery work?**
  - **Answer**: Sync script copies marketplace manifest to `~/.claude/plugins/.claude-plugin/`. Users then run `/plugin marketplace add ~/.claude/plugins` to register, or `claude --plugin-dir ~/.claude/plugins/<plugin-name>` to load directly.
  - **Source**: `scripts/sync_plugins_to_global.sh:54-58, 62-63`

- [x] **Recommended order for sync scripts?**
  - **Answer**: Scripts are independent. Typical order: plugins first (contains most functionality), then commands/skills/docs for global access, finally CLAUDE.md and MCP servers for environment setup.
  - **Source**: Scripts have no dependencies on each other

- [ ] **How do agents handle tool permission errors?** - Not documented, depends on Claude Code runtime

- [x] **What happens when test auto-detection fails?**
  - **Answer**: Script exits 0 (success) with message "No test runner detected". This is intentional - allows hook to trigger without failing the workflow when no tests exist.
  - **Source**: `tdd-workflow/scripts/run-tests.sh:82-86`

## 9. Workflow Traces (Iteration 2 Deep Dive)

### TDD Workflow: 8-Phase End-to-End Flow (Phases 2-9)

```
PHASE 2: Parallel Exploration (5 code-explorer agents via Task tool)
├── Architecture agent: Layers, components, data flow, entry points
├── Patterns agent: Naming conventions, abstractions, templates
├── Boundaries agent: Module contracts, coupling, dependencies
├── Testing agent: Framework detection, test command, coverage patterns
└── Dependencies agent: Packages, services, API keys
└─→ OUTPUT: docs/context/{feature}-exploration.md

══════ CONTEXT CHECKPOINT 1 ══════
User prompted via AskUserQuestionTool → /clear → /tdd-workflow:reinitialize-context-after-clear-and-continue-workflow {feature} --phase 3
Resume validates: Phase 2 complete → Executes Phases 3→4→5→6 in sequence

PHASE 3: Specification Interview (40+ questions via AskUserQuestionTool)
├── Core Functionality: What, why, inputs, outputs, happy path
├── Technical Constraints: Tech stack, performance, scale, compat
├── Integration Points: Systems, APIs, data stores, events
├── Edge Cases: Invalid input, failures, boundaries
├── Security: Auth, data protection, audit
├── Testing: Success criteria, automation needs
└── External Dependencies: APIs, keys, mock fallbacks
└─→ OUTPUT: docs/specs/{feature}.md

PHASE 4: Architecture Design (code-architect agent optional)
└─→ OUTPUT: docs/plans/{feature}-arch.md

PHASE 5: Implementation Plan (main instance)
└─→ OUTPUT: docs/plans/{feature}-plan.md, docs/plans/{feature}-tests.md

PHASE 6: Plan Review & Approval (plan-reviewer agent + user approval)
├── Challenge assumptions, identify gaps, clarifying questions
└── User confirms or requests changes
└─→ User approval required before implementation

══════ CONTEXT CHECKPOINT 2 ══════
User prompted → /clear → /tdd-workflow:reinitialize-context-after-clear-and-continue-workflow {feature} --phase 7
Resume validates: Phases 2-6 complete (incl. Review & Approval) → Executes Phases 7→8 in sequence

PHASE 7: Orchestrated TDD Implementation
├── MAIN INSTANCE runs: /ralph-loop:ralph-loop for each component
│   ├── RED: Spawn test-designer agent → returns test
│   │   └── MAIN INSTANCE RUNS TESTS → confirms failure
│   ├── GREEN: Spawn implementer agent → returns code
│   │   └── MAIN INSTANCE RUNS TESTS → confirms pass
│   └── REFACTOR: Spawn refactorer agent → returns improvements
│       └── MAIN INSTANCE RUNS TESTS → confirms still pass
└─→ OUTPUT: Implementation files + git commits

PHASE 8: E2E Testing (Orchestrated)
├── Spawn test-designer for E2E tests
└── MAIN INSTANCE runs ralph-loop to fix failures
└─→ OUTPUT: E2E test files passing

══════ CONTEXT CHECKPOINT 3 ══════
User prompted → /clear → /tdd-workflow:reinitialize-context-after-clear-and-continue-workflow {feature} --phase 9
Resume validates: Phases 2-8 complete → Executes Phase 9 to completion

PHASE 9: Review, Fixes & Completion
├── Parallel Multi-Aspect Review (5 code-reviewer agents)
│   ├── Security: Injection, auth, secrets
│   ├── Performance: Complexity, efficiency, caching
│   ├── Code Quality: CLAUDE.md compliance, organization
│   ├── Test Coverage: Paths, edges, errors
│   └── Spec Compliance: Requirements met, behavior correct
├── Final Fixes (ralph-loop on Critical findings)
└── Completion Summary
└─→ OUTPUT: docs/workflow/{feature}-review.md, docs/workflow/{feature}-state.md (COMPLETE)
```

### Agents by Phase

| Phase | Agent(s) Used | How to Invoke |
|-------|---------------|---------------|
| Phase 2: Exploration | `code-explorer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-explorer"` |
| Phase 3: Interview | None (main instance) | Main instance uses AskUserQuestionTool |
| Phase 4: Architecture | `code-architect` (optional) | `Task tool with subagent_type: "tdd-workflow:code-architect"` |
| Phase 5: Plan | None (main instance) | Main instance creates plan from architecture |
| Phase 6: Review | `plan-reviewer` | `Task tool with subagent_type: "tdd-workflow:plan-reviewer"` |
| Phase 7: Implement | `test-designer`, `implementer`, `refactorer` | Via ralph-loop orchestration |
| Phase 8: E2E Test | `test-designer`, `implementer` | Via ralph-loop orchestration |
| Phase 9: Review | `code-reviewer` (5x parallel) | `Task tool with subagent_type: "tdd-workflow:code-reviewer"` |

### Debug Workflow: 9-Phase Flow

```
EXPLORE: debug-explorer agent maps relevant systems
    └─→ File mapping, execution flow, dependencies, recent changes

DESCRIBE: AskUserQuestionTool gathers bug context
    └─→ OUTPUT: docs/debug/{bug}-bug.md

HYPOTHESIZE: hypothesis-generator agent creates theories
    └─→ OUTPUT: docs/debug/{bug}-hypotheses.md (3-5 ranked theories)

INSTRUMENT: instrumenter agent adds targeted logging
    └─→ Tags: [DEBUG-H1], [DEBUG-H2], etc.
    └─→ Comment: // DEBUG: Remove after fix

REPRODUCE: Guide user to trigger bug with instrumentation active

ANALYZE: log-analyzer agent matches logs to hypotheses
    └─→ For each: CONFIRMED / REJECTED / INCONCLUSIVE
    └─→ If all rejected: Return to HYPOTHESIZE

FIX: Propose minimal fix (keep instrumentation)

VERIFY: Apply fix, reproduce scenario, confirm behavior

CLEAN: Remove [DEBUG-Hx] statements, commit fix only
```

### State File Schema

**Location**: `docs/workflow/{feature}-state.md`

```markdown
# Workflow State: {feature}

## Current Phase
Phase N: {Name}

## Feature
- **Name**: {feature}
- **Description**: {description}

## Completed Phases
- [x] Phase 2: Parallel Exploration
- [x] Phase 3: Specification Interview
- [x] Phase 4: Architecture Design
- [x] Phase 5: Implementation Plan
- [x] Phase 6: Plan Review & Approval
- [ ] Phase 7: TDD Implementation
- [ ] Phase 8: E2E Testing
- [ ] Phase 9: Review, Fixes & Completion

## Key Decisions
- {decision from interview}
- {architecture choice}

## Context Restoration Files
1. docs/workflow/{feature}-state.md
2. docs/context/{feature}-exploration.md
3. docs/specs/{feature}.md
4. docs/plans/{feature}-arch.md
5. docs/plans/{feature}-plan.md
6. CLAUDE.md

## Resume Command
/tdd-workflow:reinitialize-context-after-clear-and-continue-workflow {feature} --phase N
```

## 11. Remaining Ambiguities

**From code alone, cannot determine:**
1. ~~Ralph-loop integration~~ **RESOLVED** - See workflow traces above
2. ~~Context checkpoint heuristics~~ **RESOLVED** - Fixed points in workflow, 60k/30% guideline
3. **MCP server failure handling** - No retry logic or fallback patterns documented
4. **Plugin versioning strategy** - All plugins at 1.0.0; no upgrade/migration patterns
5. **Multi-project workflows** - Test runner uses first-match; unclear priority with multiple frameworks

## 12. Iteration 3 Findings: Test Runner Behavior

**When test detection fails** (no recognized framework):
- `run-tests.sh:82-86` outputs "No test runner detected" and exits 0
- Non-fatal exit allows hooks to complete without breaking workflow
- Appropriate for repos without tests (like this config repo)

**Test framework priority** (from detect-test-runner.sh):
1. pytest (pyproject.toml, setup.py, pytest.ini)
2. vitest (vitest.config.*)
3. jest (jest.config.*, package.json with jest)
4. go (go.mod)
5. cargo (Cargo.toml)
6. rspec (.rspec, spec/)
7. minitest (test/*_test.rb)
8. mix (mix.exs)

**First match wins** - no multi-framework support currently

---

## Key Files Reference

| Purpose | Path |
|---------|------|
| TDD Plugin Manifest | `claude-code/plugins/tdd-workflow/.claude-plugin/plugin.json` |
| Debug Plugin Manifest | `claude-code/plugins/debug-workflow/.claude-plugin/plugin.json` |
| Marketplace Config | `claude-code/plugins/.claude-plugin/marketplace.json` |
| Auto-Test Hook | `claude-code/plugins/tdd-workflow/hooks/hooks.json` |
| MCP Servers | `claude-code/global_mcp_settings.json` |
| Test Runner | `claude-code/plugins/tdd-workflow/scripts/run-tests.sh` |
| TDD Workflow Orchestrator | `claude-code/plugins/tdd-workflow/commands/1-start.md` |
| Debug Workflow Orchestrator | `claude-code/plugins/debug-workflow/commands/debug.md` |
| Global Standards Template | `claude-code/CLAUDE.md` |
| VS Code Tasks | `.vscode/tasks.json` |

## Statistics

| Category | Count |
|----------|-------|
| TDD Agents | 7 |
| TDD Commands | 11 |
| TDD Skills | 6 |
| Debug Agents | 4 |
| Debug Commands | 7 |
| Debug Skills | 1 |
| Shared Commands | 16 |
| Sync Scripts | 13 |
| VS Code Tasks | 15 |
| MCP Servers | 4 |
