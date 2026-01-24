# Personal Configs - Codebase Analysis

> Last updated: 2026-01-23
> Iteration: 3 of 3 (FINAL)

## 1. System Purpose & Domain

**Purpose:** AI-assisted development workflow orchestration platform for Claude Code. This is a configuration-only repository containing zero application code—only markdown commands, YAML agent definitions, JSON configuration, and bash automation scripts.

**Core Domain Entities:**

| Entity | Definition | Location |
|--------|------------|----------|
| **Plugin** | Encapsulated workflow with agents, commands, skills, hooks | `claude-code/plugins/*/` |
| **Agent** | Specialized task executor with defined tools and model | `*/agents/*.md` (YAML frontmatter) |
| **Command** | CLI entry point for workflow phases | `*/commands/*.md` |
| **Skill** | Auto-activated methodology guidance | `*/skills/*/SKILL.md` |
| **Hook** | PostToolUse automation trigger | `*/hooks/hooks.json` |

**Two Primary Plugins:**
1. **TDD Workflow** (v1.0.0): 9-phase test-driven development with parallel exploration/review
2. **Debug Workflow** (v1.0.0): Hypothesis-driven debugging with instrumentation

## 2. Technology Stack

### Languages & Formats
- **Markdown** (62 files): Commands, agents, skills, documentation
- **JSON** (8 files): Plugin manifests, MCP config, IDE tasks, hooks
- **Bash** (15 files): Bidirectional sync scripts, test automation

### Runtime Dependencies
- **Claude Code**: Platform runtime (required)
- **ralph-loop plugin**: TDD Phase 7 orchestration (external dependency)

### MCP Servers (from `global_mcp_settings.json`)
| Server | Type | Purpose | Auth |
|--------|------|---------|------|
| context7 | HTTP | Documentation retrieval | API key |
| fetch | stdio/uvx | URL content fetching | None |
| exa | stdio/npx | Web search, code context | API key |
| playwright | stdio/npx | Browser automation | None |

### Test Framework Support (auto-detected)
- Python: pytest (with uv)
- JavaScript: vitest, jest
- Go: go test
- Rust: cargo test
- Ruby: rspec, minitest
- Elixir: mix test

## 3. Architecture

### Pattern: Modular Plugin Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Claude Code Platform (Runtime)                 │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ loads plugins from ~/.claude/
                              │
┌─────────────────────────────────────────────────────────────────┐
│              personal_configs Repository (This codebase)         │
├──────────────────┬───────────────────┬─────────────────────────┤
│  Plugin Layer    │   Shared Layer    │   Infrastructure        │
├──────────────────┼───────────────────┼─────────────────────────┤
│  tdd-workflow/   │   commands/       │   scripts/ (13 sync)    │
│   - 7 agents     │    16 shared      │   .vscode/tasks.json    │
│   - 11 commands  │   docs/ (3)       │   MCP config            │
│   - 6 skills     │   CLAUDE.md       │   .claude/settings      │
│   - hooks.json   │    (template)     │                         │
│                  │                   │                         │
│  debug-workflow/ │                   │                         │
│   - 4 agents     │                   │                         │
│   - 7 commands   │                   │                         │
│   - 1 skill      │                   │                         │
└──────────────────┴───────────────────┴─────────────────────────┘
          │
          ▼ syncs to
┌─────────────────────────────────────────────────────────────────┐
│                    ~/.claude/ (Global Config)                    │
│   plugins/ │ commands/ │ skills/ │ docs/ │ CLAUDE.md            │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

**TDD Workflow (9 phases):**
```
Phase 2 (Explore) ─────────────────┐
  5 parallel code-explorer agents  │
  Output: exploration.md           │
           ↓                       │ Checkpoint 1
Phase 3 (Interview) ←──────────────┘
  40+ interview questions
  Output: specs.md
           ↓
Phase 4 (Architecture)
  code-architect agent
  Output: arch.md
           ↓
Phase 5 (Planning)
  Main instance
  Output: plan.md
           ↓
Phase 6 (Review) ──────────────────┐
  plan-reviewer agent              │
  Gate: User approval              │ Checkpoint 2
           ↓                       │
Phase 7 (Implement) ←──────────────┘
  ralph-loop orchestration
  RED → GREEN → REFACTOR cycle
           ↓
Phase 8 (E2E Testing) ─────────────┐
  ralph-loop orchestration         │
  Output: passing E2E tests        │ Checkpoint 3
           ↓                       │
Phase 9 (Review) ←─────────────────┘
  5 parallel code-reviewer agents
  Fix critical issues
  Output: FIX_COMPLETE
```

**Debug Workflow (9 phases):**
```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

## 4. Boundaries & Interfaces

### Agent Contract (YAML Frontmatter)
```yaml
---
name: <agent-name>           # Task tool invocation identifier
description: <role>          # Auto-activation trigger
tools: [Read, Write, ...]    # Available capabilities
model: opus|sonnet           # Model preference
---
```

**Read-only agents:** code-explorer, test-designer, debug-explorer, hypothesis-generator, plan-reviewer, log-analyzer
**Write agents:** implementer, refactorer, instrumenter

### Command Contract
```yaml
---
description: <purpose>
model: opus|sonnet
argument-hint: <usage>
---
```

### Plugin Manifest (`plugin.json`)
```json
{
  "name": "<plugin-name>",
  "description": "<purpose>",
  "version": "1.0.0",
  "author": { "name": "jandro" }
}
```

### Hook Contract (`hooks.json`)
```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "run-tests.sh", "timeout": 120 }]
    }
  ]
}
```

### Coupling Assessment
- **Loose:** Plugins are independent; commands are shared utilities
- **Strict contracts:** YAML frontmatter enforces interface definition
- **External dependency:** ralph-loop plugin required for TDD Phase 7

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| **Config-only repo** | Markdown + JSON | Python/JS implementation | Human-readable, version-controllable, but limited to simple config |
| **Main instance owns feedback** | ralph-loop orchestration | Subagent-driven loops | Context managed centrally; requires external plugin dependency |
| **Parallel read-only phases** | 5 agents for explore/review | Sequential processing | Faster exploration; more complex orchestration |
| **Context checkpoints** | Manual /clear + /resume | Automatic summarization | Quality maintained; requires user action |
| **Real APIs first** | Production credentials | Mock implementations | Catches integration issues; requires API key availability |
| **Bidirectional sync** | Both directions supported | One-way only | Flexibility; potential conflict resolution complexity |
| **Phase-based state** | Sequential progression | Free-form | Clear checkpoints; cannot skip phases |

## 6. Code Quality & Patterns

### Recurring Patterns

**1. Graceful degradation** (`run-tests.sh:20-30`)
```bash
if command -v pytest &> /dev/null; then
    uv run pytest -q
else
    echo "pytest not found"
    exit 0  # Non-fatal
fi
```

**2. Fail-fast automation** (all sync scripts)
```bash
set -e  # Exit on first error
```

**3. Pre-flight validation** (`sync_plugins_to_global.sh:11-14`)
```bash
if [ ! -d "$REPO_PLUGINS_DIR" ]; then
    echo "Error: Directory not found"
    exit 1
fi
```

### Testing Strategy
- **No tests in this repo:** Configuration-only repository
- **Test infrastructure:** Auto-detect and run 8+ frameworks via hooks
- **TDD enforcement:** Phase 7 uses RED→GREEN→REFACTOR cycle
- **Continuous verification:** PostToolUse hooks run tests on Write|Edit

### Error Handling
| Error Type | Handling | Exit Code |
|------------|----------|-----------|
| Missing tool | Log, continue | 0 (non-fatal) |
| Invalid path | Log, exit | 1 (fatal) |
| Test failure | Pass through | From test runner |
| Missing context | Ask user | N/A |

### Configuration Management
- **Environment:** `.env` (gitignored) for API keys
- **Local settings:** `.claude/settings.local.json` for permissions
- **Global template:** `claude-code/CLAUDE.md` syncs to ~/.claude/

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| "No application code" | Verified: 0 .py/.js/.go files | `CLAUDE.md:20` |
| "ralph-loop required" | Not bundled, external dependency | `tdd-workflow/README.md` |
| "8+ test frameworks" | Verified in detection script | `scripts/detect-test-runner.sh:1-50` |
| "Bidirectional sync" | All 13 scripts support both directions | `scripts/sync_*_to_global.sh`, `scripts/sync_*_from_global.sh` |

## 8. Open Questions

- [x] What happens if context checkpoints are skipped? **ANSWERED:** Resume command validates prerequisites per phase (see table in `reinitialize-context-after-clear-and-continue-workflow.md:27-31`). If Phase 6 not completed before Phase 7, user is warned and asked via AskUserQuestionTool whether to proceed.
- [x] How do skills auto-activate? **ANSWERED:** Skills have `name` and `description` in YAML frontmatter. Activation is based on description matching context (e.g., "Provides TDD guidance when writing tests").
- [x] Where is ralph-loop plugin sourced from? **ANSWERED:** "Ralph Wiggum" pattern by Geoffrey Huntley, packaged as official plugin by Boris Cherny. Install via `/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum` (per `workflow_plan.md:119-123`). Uses Stop hook to intercept exit code 2 and re-feed prompts.
- [ ] How are API key secrets managed beyond .env? No vault/secrets manager referenced.
- [ ] Are there version compatibility requirements between plugins and Claude Code?
- [ ] What's the conflict resolution strategy for bidirectional sync? Scripts use `rm -rf` + `cp -r` (last write wins).
- [ ] How are MCP server errors handled during workflow execution? No fallback documented.
- [ ] Is there a maximum context size that triggers checkpoint recommendations?
- [ ] What happens when hook timeout (120s) is exceeded? Claude Code platform behavior undocumented here.

## 9. Ambiguities

1. **ralph-loop integration:** Installation documented in `workflow_plan.md:119-123` but not in plugin READMEs. Users must know to check workflow_plan.md. Invoked as `/ralph-loop:ralph-loop "..." --max-iterations N --completion-promise "TEXT"`.
2. **Hook timeout behavior:** `hooks.json:12` sets 120s timeout but doesn't document timeout consequences.
3. **MCP server failure modes:** No documented fallback when servers are unavailable. Used for context7 (docs), exa (search), playwright (browser).
4. **Sync conflict resolution:** `sync_plugins_to_global.sh:40` does `rm -rf` then `cp -r` — last write wins, no merge.
5. **Phase skip consequences:** User can force skip with AskUserQuestionTool confirmation, but quality implications undocumented.

## 10. Deep Dive Findings (Iteration 2)

### Execution Flow Analysis

#### TDD Phase 7 (Implementation) - Key Workflow
**File:** `claude-code/plugins/tdd-workflow/commands/7-implement.md`

```
Main Instance (ralph-loop orchestrator)
    │
    ├── Step 1: Foundation (sequential)
    │   Create shared types, utilities, config
    │
    ├── Step 2: Identify Parallel Components
    │   Read docs/plans/$1-plan.md
    │
    ├── Step 3: For each component...
    │   │
    │   └── ralph-loop TDD cycle (max 50 iterations)
    │       │
    │       ├── RED: Spawn test-designer subagent
    │       │   → Write ONE failing test
    │       │   → Main instance RUNS tests (verify red)
    │       │   → Commit: "red: [$feature][$component] test for [req]"
    │       │
    │       ├── GREEN: Spawn implementer subagent
    │       │   → Write MINIMAL code to pass
    │       │   → Main instance RUNS tests (verify green)
    │       │   → Commit: "green: [$feature][$component] [req]"
    │       │
    │       └── REFACTOR: Spawn refactorer subagent (optional)
    │           → Improve code quality
    │           → Main instance RUNS tests (verify still green)
    │           → Commit: "refactor: [$feature][$component] [desc]"
    │
    └── Step 5: Integration Layer (ralph-loop, max 20 iterations)
        Wire components together
        Output: INTEGRATION_$1_COMPLETE
```

**Key Insight:** Main instance owns feedback loop and runs tests directly. Subagents are stateless workers.

#### Debug Workflow - Key Phases
**File:** `claude-code/plugins/debug-workflow/commands/debug.md`

9-phase systematic debugging:
1. **EXPLORE:** debug-explorer agent maps execution flow
2. **DESCRIBE:** Collect bug context via AskUserQuestionTool
3. **HYPOTHESIZE:** Generate 3-5 ranked theories
4. **INSTRUMENT:** Add tagged logging (`[DEBUG-H1]`, `[DEBUG-H2]`)
5. **REPRODUCE:** Guide user to trigger bug
6. **ANALYZE:** Match logs against hypotheses (CONFIRMED/REJECTED/INCONCLUSIVE)
7. **FIX:** Minimal fix + regression test
8. **VERIFY:** Confirm fix works
9. **CLEAN:** Remove all debug instrumentation (`// DEBUG: Remove after fix`)

**Key Principle:** "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny (cited in docs)

### Hook System Details

**File:** `claude-code/plugins/tdd-workflow/hooks/hooks.json`

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/run-tests.sh",
      "timeout": 120
    }]
  }]
}
```

**Behavior:**
- Triggers on ANY Write or Edit tool use
- Runs auto-detected test framework (8+ supported)
- 120 second timeout
- Non-fatal exit on missing runner (`exit 0`)

### MCP Server Configuration Details

**File:** `claude-code/global_mcp_settings.json`

| Server | Protocol | Command/URL | Auth Method |
|--------|----------|-------------|-------------|
| context7 | HTTP | `https://mcp.context7.com/mcp` | Header: `CONTEXT7_API_KEY` |
| fetch | stdio | `uvx mcp-server-fetch` | None |
| exa | stdio | `npx -y exa-mcp-server` | Env: `EXA_API_KEY` |
| playwright | stdio | `npx @playwright/mcp@latest` | None |

**exa tools enabled:** `get_code_context_exa`, `web_search_exa`, `deep_researcher_start`, `deep_researcher_check`

### Permission Configuration

**File:** `.claude/settings.local.json`

```json
{
  "permissions": {
    "allow": [
      "Read(//Users/jandro/.claude/**)",
      "WebSearch",
      "mcp__exa__web_search_exa",
      "mcp__fetch__fetch"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Analysis:** Only read access to ~/.claude/, web search, and fetch are pre-approved. All other operations require user confirmation.

### Sync Script Analysis

**File:** `scripts/sync_plugins_to_global.sh`

Flow:
1. Validate source dir exists (fatal error if not)
2. Create destination dir if needed
3. If `--overwrite`: Remove only repo plugins from destination (preserves unrelated plugins)
4. For each plugin: `rm -rf` destination, then `cp -r` source
5. Copy marketplace manifest if exists

**Conflict Resolution:** Last write wins. No merge, no diff, no backup.

## 11. Iteration 3 Findings: Ralph-Loop & Workflow Philosophy

### Ralph-Loop Plugin Origin & Installation

**Source:** `claude-code/workflow_plan.md:113-131`

The "Ralph Wiggum" pattern was created by Geoffrey Huntley and packaged as an official plugin by Boris Cherny. It implements **autonomous iteration loops** where Claude works continuously until completion criteria.

**How it works:**
- Uses a Stop hook that intercepts Claude's exit attempts (exit code 2)
- Feeds the same prompt back to Claude
- Claude observes its own modifications through git history and file changes
- Prompt stays constant, but codebase evolves

**Installation:**
```bash
/plugin marketplace add anthropics/claude-code
/plugin install ralph-wiggum
```

**Commands:**
```bash
/ralph-loop "<prompt>" --max-iterations N
/ralph-loop "<prompt>" --max-iterations N --completion-promise "DONE"
/cancel-ralph
```

**Critical Safety:** ALWAYS set `--max-iterations`. 50-iteration loops can cost **$50-100+** in API credits.

### Workflow Philosophy (from workflow_plan.md)

Key quotes that explain the design:

> "A good plan is really important to avoid issues down the line." - Boris Cherny

> "Start a fresh session to execute the completed spec." - Thariq Shihab

> "Ask questions in all caps, record answers, cover feature, UX, UI, architecture, API, security, edge cases, test requirements, and pushback on idealistic ideas." - Mo Bitar

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

### Context Compaction Behavior

**From workflow_plan.md:322-325:**
- Auto-compact triggers at ~95% capacity
- Preserves: architectural decisions, unresolved bugs, implementation details
- Discards: verbose tool outputs
- Retains: 5 most recently accessed files + compressed summary

**Best practice:** Manual compact at ~70-80% capacity:
```
/compact Focus on: current phase, test results, remaining tasks, key decisions
```

### CLAUDE.md Persistence

**Critical finding (workflow_plan.md:33-46):** CLAUDE.md is automatically re-injected after context compaction. This makes it the primary mechanism for persistent project memory.

| Location | Scope | Best Use |
|----------|-------|----------|
| `~/.claude/CLAUDE.md` | Global | Personal coding preferences |
| `./CLAUDE.md` | Project root | Team conventions (checked into git) |
| `./CLAUDE.local.md` | Project root (gitignored) | Personal overrides |
| `.claude/rules/*.md` | Path-specific | Context-aware rules |

### Cost Considerations

- 50-iteration ralph-loop: **$50-100+ in API credits**
- Single MCP server with 20 tools: **~14,000 tokens**
- Recommendation: Disable unused MCP servers before resource-intensive work

### Related Official Plugins

**From workflow_plan.md:347-364:**
```bash
/plugin install ralph-wiggum        # Autonomous iteration loops
/plugin install code-simplifier     # Clean up after long sessions
/plugin install pr-review-toolkit   # 6 parallel review agents
```

The pr-review-toolkit runs 6 specialized agents: comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-reviewer, code-simplifier.

---

## File Metrics

| Category | Count |
|----------|-------|
| Markdown files | 62 |
| JSON configs | 8 |
| Bash scripts | 15 |
| Agents (TDD) | 7 |
| Agents (Debug) | 4 |
| Commands (TDD) | 11 |
| Commands (Debug) | 7 |
| Commands (Shared) | 16 |
| Skills (TDD) | 6 |
| Skills (Debug) | 1 |
| Total repo size | 2.5 MB |
