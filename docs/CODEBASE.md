# Personal Configs - Codebase Analysis

> Last updated: 2026-02-04
> Iteration: 3 of 3 (Final)

## 1. System Purpose & Domain

**Purpose**: Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 6 plugins, configuration sync scripts, and IDE integrations.

**Core Domain Entities**:

| Entity | Definition Location | Purpose |
|--------|---------------------|---------|
| Plugin | `plugins/*/plugin.json` | Self-contained capability module |
| Agent | `plugins/*/agents/*.md` | Subagent with specific tools and model |
| Command | `plugins/*/commands/*.md` | User-invocable slash commands |
| Skill | `plugins/*/skills/*/SKILL.md` | Context-activated knowledge module |
| Hook | `plugins/*/hooks/hooks.json` | Event-driven automation |
| Workflow State | `docs/workflow-<feature>/*-state.md` | Persistent session progress |

**Not an Application**: This repository contains ONLY:
- Markdown files (commands, agents, skills, documentation)
- JSON configs (MCP servers, VS Code tasks, plugin manifests)
- Shell scripts (sync utilities, test runner)
- One JavaScript module (Playwright executor)

No dependencies, no build system, no deployment pipeline.

---

## 2. Technology Stack

### Languages & Runtimes
| Technology | Version | Source | Purpose |
|------------|---------|--------|---------|
| Node.js | >=18.0.0 | `plugins/playwright/package.json:8` | Playwright executor |
| Bash | System | `scripts/*.sh` | Sync utilities, hooks |
| Markdown | N/A | `*.md` files | Commands, agents, skills |
| JSON | N/A | `*.json` files | Configuration |

### Dependencies
| Package | Version | Location | Purpose |
|---------|---------|----------|---------|
| Playwright | ^1.57.0 | `plugins/playwright/package.json:6` | Browser automation |

### External Services (MCP Servers)
| Server | Type | Purpose | Config |
|--------|------|---------|--------|
| context7 | HTTP | Documentation API | `global_mcp_settings.json:3-5` |
| fetch | stdio | Web content fetching | `global_mcp_settings.json:6-9` |
| exa | npx | Web search + code context | `global_mcp_settings.json:10-25` |
| playwright | npx | Browser automation | `global_mcp_settings.json:26-29` |

### Required Environment Variables
```bash
CONTEXT7_API_KEY=<key>  # In .env, gitignored
EXA_API_KEY=<key>       # In .env, gitignored
```

---

## 3. Architecture

### Pattern: Plugin-Based Modular Architecture with Hook-Driven Automation

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Claude Code Platform (Runtime)                   │
│  [Task Tool] [AskUserQuestion] [SlashCommand] [Agent Spawning]      │
└──────────────────────────────────────────────────────────────────────┘
                                    ↑
                    ┌───────────────┼───────────────┐
                    │               │               │
        ┌───────────▼──────┐  ┌────▼──────────┐  ┌─▼──────────────┐
        │  Plugin Layer    │  │  Hook System  │  │  MCP Servers   │
        │  (6 plugins)     │  │  (4 events)   │  │  (4 servers)   │
        └──────────────────┘  └───────────────┘  └────────────────┘
                    ↓                 ↓
        ┌─────────────────────────────────────────┐
        │   File System (Workflow State)           │
        │   docs/workflow-<feature>/              │
        └─────────────────────────────────────────┘
```

### Plugin Structure (6 plugins)
| Plugin | Agents | Commands | Skills | Hooks | Purpose |
|--------|--------|----------|--------|-------|---------|
| tdd-workflow | 7 | 11 | 4 | 3 | TDD orchestration |
| debug-workflow | 4 | 7 | 1 | 0 | Hypothesis-driven debugging |
| playwright | 0 | 0 | 1 | 0 | Browser automation |
| claude-session-feedback | 0 | 4 | 0 | 0 | Conversation export |
| infrastructure-as-code | 0 | 1 | 1 | 0 | Terraform management |
| claude-md-best-practices | 0 | 0 | 1 | 0 | CLAUDE.md guidance |

### Data Flow: Context Preservation
```
TDD Workflow Running
    ↓
Context Approaching Limit (~60k tokens)
    ↓
PreCompact Hook (agent) → Saves to docs/workflow-<feature>/*-state.md
    ↓
Context Compacted
    ↓
SessionStart Hook (script) → Reads state, injects context
    ↓
Workflow Resumes Automatically
```

---

## 4. Boundaries & Interfaces

### Plugin Manifest Contract
Every plugin requires `.claude-plugin/plugin.json`:
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": { "name": "author" },
  "keywords": ["category"]
}
```

### Command YAML Frontmatter (required)
```yaml
---
name: command-name
description: "What this command does"
model: sonnet|opus                    # optional
argument-hint: "<args>"               # optional
allowed-tools: [Tool1, Tool2]         # optional
---
```

### Agent YAML Frontmatter (required)
```yaml
---
name: agent-name
description: "What this agent does"
tools: [Glob, Grep, Read, Write, Edit, Bash]
model: sonnet|opus
---
```

### Hook Event Types
| Event | Trigger | Use Case |
|-------|---------|----------|
| PostToolUse | After Write\|Edit | Auto-run tests |
| PreCompact | Before context compaction | Save workflow state |
| SessionEnd | Before logout/clear/exit | Save progress |
| SessionStart | After /compact or /clear | Restore context |

### Coupling Assessment
- **Plugins → Platform**: Tight (depends on Claude Code runtime)
- **Plugin → Plugin**: None (zero cross-dependencies)
- **Plugin → MCP**: Loose (optional service layer)
- **Hooks → State Files**: Tight (file format contract)

---

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Configuration repo only | No application code | Full application | Simplicity vs. extensibility |
| Markdown-based definitions | YAML frontmatter in .md | Pure JSON/YAML | Human-readable vs. schema validation |
| Agent-based state saving | PreCompact hook spawns agent | Shell script | Context-aware vs. simpler |
| PostToolUse auto-testing | Hook after Write/Edit | Manual test runs | Immediate feedback vs. flexibility |
| ralph-loop dependency | External plugin | Built-in loop | Reuse vs. self-containment |
| File-based state | docs/workflow-*/ | Database/API | Simplicity vs. queryability |

### Technical Debt Identified
1. **API keys in git history**: Keys in .env are gitignored but may exist in history
2. **No schema validation**: Plugin manifests have no JSON schema enforcement
3. **No CI/CD**: No automated validation on push
4. **Empty docs/ folder**: Root docs/ directory is empty despite being declared

---

## 6. Code Quality & Patterns

### Recurring Patterns

**ABOUTME Comments**: All code files start with 2-line description
```bash
# ABOUTME: Runs tests using auto-detected runner
# ABOUTME: Exits 0 if tests pass or no framework found
```

**Hook JSON Structure** (`hooks.json`):
```json
{
  "description": "Hook description",
  "hooks": {
    "EventName": [{
      "matcher": "regex",
      "hooks": [{ "type": "command|agent", ... }]
    }]
  }
}
```

**Workflow State File** (`*-state.md`):
```markdown
# Workflow State: <feature>
## Current Phase
## Completed Phases
## Key Decisions
## Session Progress (Auto-saved)
## Files Modified This Session
## Context Restoration Files
```

### Testing Strategy
- **No unit tests**: Configuration repo, not application
- **Auto-detection**: `run-tests.sh` detects pytest, jest, vitest, go, cargo, rspec, minitest, mix
- **PostToolUse hook**: Runs tests after every Write/Edit
- **TDD workflow**: 8-phase methodology enforced by plugin

### Error Handling
- Hook scripts exit 0 when no framework found (non-fatal)
- Agent-based hooks provide context-aware error messages
- Debug workflow uses hypothesis-driven approach with proof requirement

---

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| "6 plugins" (README) | 6 plugins confirmed | `plugins/*/plugin.json` |
| "7 agents in TDD" (README) | 7 agents confirmed | `plugins/tdd-workflow/agents/*.md` |
| "ralph-loop required" | Only for Phases 7, 8, 9 | `plugins/tdd-workflow/README.md:44-47` |
| "docs/ folder empty" | Confirmed empty | `/docs/` directory |
| "3 hooks in TDD" | 4 event types, 3 implementations | `plugins/tdd-workflow/hooks/hooks.json` |

---

## 8. Open Questions

### Answered in Iteration 2

- [x] **Sync conflict resolution**: No merge logic. Both directions do `rm -rf` then `cp -r`. Last sync wins.
  - Source: `scripts/sync_plugins_to_global.sh:40`, `scripts/sync_plugins_from_global.sh:44`
- [x] **ralph-loop integration**: Invoked via `/ralph-loop:ralph-loop "prompt" --max-iterations N --completion-promise "STRING"`
  - Pattern: Main instance runs ralph-loop, spawns test-designer/implementer/refactorer subagents
  - Completion: Stops when output contains the completion promise string
  - Source: `plugins/tdd-workflow/commands/7-implement.md:68-157`
- [x] **Test detection silent exit**: By design. Exit 0 when no framework found allows repos without tests to use TDD workflow for planning phases.
  - Source: `plugins/tdd-workflow/hooks/run-tests.sh:83-85`
- [x] **Marketplace.json coverage**: All 6 plugins ARE in marketplace.json. Previous concern was unfounded.
  - Source: `plugins/.claude-plugin/marketplace.json:8-63`
- [x] **Debug-workflow no hooks**: Design choice. Debug workflow is single-session (investigate → fix → done). TDD is multi-session (planning across days/weeks).
  - Source: Plugin comparison - debug has no state files, TDD has docs/workflow-*/ directory pattern

### Answered in Iteration 3

- [x] **API keys in git history**: No. `git log --all -p -- '.env'` returns empty. .env was never committed.
- [x] **Formal schema for workflow state**: No JSON schema. Format defined in PreCompact hook agent prompt (`hooks.json:21`). Agent could deviate but structure is consistent.
- [x] **Root docs/ vs claude-code/docs/**: Different purposes:
  - `/docs/` = project-specific documentation (CODEBASE.md)
  - `/claude-code/docs/` = synced best practices (python.md, using-uv.md, docker-uv.md)

### Still Open

- [ ] Token cost of 4 MCP servers? (Requires runtime measurement - README claims ~14k tokens for 20 tools)
- [ ] Hook execution order when multiple match same event?

---

## 9. Ambiguities

### Workflow State Format
The `*-state.md` files have structure defined in PreCompact hook prompt (`hooks.json:21`):
```markdown
## Session Progress (Auto-saved)
- **Phase**: [current phase]
- **Component**: [if applicable]
- **Requirement**: [if applicable]
- **Next Action**: [specific next step]

## Recent Decisions
## Blockers
## Files Modified This Session
```

However, this is enforced by agent prompt, not schema validation. Agent could deviate.

### Sync Direction Design
**Confirmed**: No conflict resolution. Both scripts do destructive copy:
```bash
rm -rf "$GLOBAL_PLUGINS_DIR/$plugin_name"
cp -r "$plugin_dir" "$GLOBAL_PLUGINS_DIR/$plugin_name"
```
This is intentional: repo is source of truth (to_global), global can be backup (from_global).

### ralph-loop Cost Model
From `7-implement.md:156`:
```
--max-iterations 50  # 50 iterations = $50-100+ in API costs
```
Each iteration is one Opus API call. Integration layer uses `--max-iterations 20`.

---

## 10. Deep Dive: Key Workflows (Iteration 2)

### TDD Implementation Flow (Phase 7)

```
/tdd-workflow:7-implement <feature>
    │
    ├─ Check prerequisites (spec, plan, architecture, exploration files)
    │
    ├─ Create foundation + contracts (types, interfaces, utilities)
    │
    ├─ For each component:
    │   │
    │   └─ /ralph-loop:ralph-loop --max-iterations 50
    │       │
    │       ├─ RED: Task tool → test-designer agent → writes 1 failing test
    │       │   └─ Orchestrator runs tests (confirms red)
    │       │
    │       ├─ GREEN: Task tool → implementer agent → minimal passing code
    │       │   └─ Orchestrator runs tests (confirms green)
    │       │
    │       ├─ REFACTOR: Task tool → refactorer agent → improves code
    │       │   └─ Orchestrator runs tests (confirms still green)
    │       │
    │       └─ Loop until COMPONENT_<feature>_<name>_COMPLETE
    │
    └─ Integration layer via separate ralph-loop (--max-iterations 20)
```

### Context Preservation Flow

```
SessionStart (after /compact or /clear)
    │
    └─ auto-resume-after-compact-or-clear.sh
        │
        ├─ Read JSON from stdin: { "source": "compact|clear" }
        │
        ├─ Find docs/workflow-*/.*-state.md
        │
        ├─ Skip if no state file or workflow complete
        │
        ├─ Extract feature name from directory path
        │
        └─ Output JSON with additionalContext:
            {
              "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": "## TDD Workflow Resumed..."
              }
            }
```

### Test Auto-Run Flow

```
PostToolUse (after Write|Edit)
    │
    └─ run-tests.sh
        │
        ├─ detect-test-runner.sh → returns framework name
        │
        ├─ Case statement for 8 frameworks:
        │   ├─ pytest: uv run pytest -q || pytest -q
        │   ├─ vitest: npx vitest run
        │   ├─ jest: npx jest --silent
        │   ├─ go: go test ./...
        │   ├─ cargo: cargo test
        │   ├─ rspec: bundle exec rspec || rspec
        │   ├─ minitest: ruby -Ilib:test test/**/*_test.rb
        │   └─ mix: mix test
        │
        └─ Default: exit 0 (no tests = success)
```

---

## 11. Skills Inventory (8 Total)

| Skill | Plugin | Purpose | Activation Trigger |
|-------|--------|---------|-------------------|
| `tdd-workflow-guide` | tdd-workflow | Navigation guidance for 8 phases | Starting/navigating TDD workflow |
| `testing` | tdd-workflow | RED/GREEN/REFACTOR methodology | Writing tests or implementing features |
| `writing-plans` | tdd-workflow | Parallelizable component design | Writing implementation plans |
| `using-git-worktrees` | tdd-workflow | Feature branch isolation | Starting feature work needing isolation |
| `structured-debug` | debug-workflow | Hypothesis-driven debugging | Debugging errors/unexpected behavior |
| `playwright` | playwright | Browser automation | Testing websites, automating browsers |
| `infrastructure-as-code` | infrastructure-as-code | Terraform/AWS best practices | Managing AWS infrastructure |
| `writing-claude-md` | claude-md-best-practices | CLAUDE.md authoring guidance | Creating/editing CLAUDE.md files |

---

## 12. MCP Server Configuration Details

**File**: `global_mcp_settings.json`

| Server | Type | Command/URL | Tools Enabled |
|--------|------|-------------|---------------|
| context7 | HTTP | `https://mcp.context7.com/mcp` | Documentation API |
| fetch | stdio | `uvx mcp-server-fetch` | URL content fetching |
| exa | npx | `exa-mcp-server` | `get_code_context_exa`, `web_search_exa`, `deep_researcher_start`, `deep_researcher_check` |
| playwright | npx | `@playwright/mcp@latest` | Browser automation |

**Environment Variables**:
- `CONTEXT7_API_KEY`: Header for context7 server
- `EXA_API_KEY`: Env var for exa server

**Token Cost**: README claims ~14,000 tokens for 20 tools when all servers enabled. Consider disabling unused servers before context-heavy work.

---

## 13. File Location Reference

### Plugin Components
```
claude-code/plugins/<plugin>/
├── .claude-plugin/plugin.json       # Required: manifest
├── commands/*.md                     # Optional: slash commands
├── agents/*.md                       # Optional: subagent definitions
├── skills/<skill>/SKILL.md          # Optional: context-activated knowledge
├── hooks/hooks.json                  # Optional: event automation
└── README.md                         # Optional: documentation
```

### Workflow Artifacts
```
docs/workflow-<feature>/
├── <feature>-state.md               # Auto-managed by hooks
├── <feature>-original-prompt.md     # Saved at workflow start
├── <feature>-review.md              # Phase 9 output
├── codebase-context/
│   └── <feature>-exploration.md     # Phase 2 output
├── specs/
│   └── <feature>-specs.md           # Phase 3 output
└── plans/
    ├── <feature>-architecture-plan.md    # Phase 4 output
    ├── <feature>-implementation-plan.md  # Phase 5 output
    └── <feature>-tests.md                # Phase 5 output
```

### Sync Scripts
```
scripts/
├── sync_plugins_to_global.sh        # Repo → ~/.claude/plugins/
├── sync_plugins_from_global.sh      # ~/.claude/plugins/ → Repo
├── sync_commands_to_global.sh       # Repo → ~/.claude/commands/
├── sync_commands_from_global.sh     # ~/.claude/commands/ → Repo
├── sync_skills_to_global.sh         # Repo → ~/.claude/skills/
├── sync_skills_from_global.sh       # ~/.claude/skills/ → Repo
├── sync_docs_to_global.sh           # Repo → ~/.claude/docs/
├── sync_docs_from_global.sh         # ~/.claude/docs/ → Repo
├── sync_claude_to_global.sh         # Repo → ~/.claude/CLAUDE.md
├── sync_claude_from_global.sh       # ~/.claude/CLAUDE.md → Repo
├── sync_mcp_servers_to_global.sh    # Repo → ~/.claude/mcp_settings
├── sync_mcp_servers_from_global.sh  # ~/.claude/mcp_settings → Repo
└── run_file.sh                      # VS Code file compilation
```
