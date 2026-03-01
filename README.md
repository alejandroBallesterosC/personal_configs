# Personal Development Configurations

Development infrastructure repository for AI-assisted workflows with Claude Code. Contains 7 plugins, configuration sync scripts, and IDE integrations.

## Repository Structure

```
personal_configs/
├── claude-code/
│   ├── plugins/                    # 7 encapsulated workflow plugins
│   │   ├── dev-workflow/           # 12 agents, 18 commands, 6 skills, 4 hooks (TDD + Debug)
│   │   ├── autonomous-workflow/    # 6 agents, 6 commands, 1 skill, 3 hooks (Research/Plan/Implement)
│   │   ├── playwright/             # Browser automation (JS + skill)
│   │   ├── claude-session-feedback/ # 4 commands
│   │   ├── infrastructure-as-code/ # 1 command, 1 skill
│   │   ├── claude-md-best-practices/ # 1 skill
│   │   └── ralph-loop/            # Iterative AI loops (3 commands, 1 hook)
│   ├── commands/                   # Shared global commands
│   ├── docs/                       # Python, UV, Docker best practices
│   ├── CLAUDE.md                   # Global coding standards template
│   └── global_mcp_settings.json    # MCP server configuration
├── cursor/                         # Cursor IDE parallel configs
├── sync-content-scripts/           # 9 sync scripts (bidirectional + cursor)
├── .vscode/                        # VS Code tasks (16 total: 9 working sync + 4 dead sync + 3 other)
├── docs/
│   └── CODEBASE.md                 # Comprehensive codebase analysis
└── CLAUDE.md                       # Project-specific instructions
```

## Core Plugin: Dev Workflow

### `claude-code/plugins/dev-workflow/`

A unified plugin combining an **8-phase TDD implementation workflow** and a **9-phase hypothesis-driven debugging workflow**. 12 specialized agents, 18 commands, 6 skills, and automatic context preservation via hooks.

### TDD Implementation Workflow (Phases 2-9)

```
Phase 2: EXPLORE (5 parallel agents) → Phase 3: INTERVIEW (40+ questions)
→ Phase 4: ARCHITECTURE → Phase 5: IMPLEMENTATION PLAN
→ Phase 6: PLAN REVIEW (approval gate) → Phase 7: TDD IMPLEMENT (ralph-loop)
→ Phase 8: E2E TESTING → Phase 9: PARALLEL REVIEW (5 agents) → COMPLETE
```

**Key Features:**
- Parallel exploration with 5 code-explorer agents (Phase 2)
- Specification interview with 40+ questions (Phase 3)
- Architecture design before implementation planning (Phase 4 → Phase 5)
- Plan review and approval gate before implementation (Phase 6)
- Orchestrated TDD with ralph-loop integration (Phase 7)
- E2E testing (Phase 8)
- Parallel code review with 5 specialized reviewers + fixes (Phase 9)
- Automatic context preservation via Stop + SessionStart hooks

**Commands:**
```bash
# Start the full orchestrated workflow
/dev-workflow:1-start-tdd-implementation my-feature "Add user authentication"

# Resume after context clear or fresh session
/dev-workflow:continue-workflow my-feature

# Run individual phases
/dev-workflow:2-explore my-feature "description"
/dev-workflow:3-user-specification-interview my-feature "description"
/dev-workflow:4-plan-architecture my-feature
/dev-workflow:5-plan-implementation my-feature
/dev-workflow:6-review-plan my-feature
/dev-workflow:7-implement my-feature "description"
/dev-workflow:8-e2e-test my-feature "description"
/dev-workflow:9-review my-feature

# Help
/dev-workflow:help
```

### Debug Workflow (9 Phases)

```
EXPLORE → DESCRIBE → HYPOTHESIZE → INSTRUMENT → REPRODUCE → ANALYZE → FIX → VERIFY → CLEAN
```

**Iron Law:** No fixes until root cause is proven. **3-Fix Rule:** After 3 failed fixes, question the architecture. Debug instrumentation writes to `logs/debug-output.log` (overwritten per run) — Claude reads it directly, no copy/paste needed.

**Commands:**
```bash
# Start full debug workflow
/dev-workflow:1-start-debug "API returns 500 error when user has emoji in name"

# Run individual phases
/dev-workflow:1-explore-debug user-api
/dev-workflow:3-hypothesize emoji-bug
/dev-workflow:4-instrument emoji-bug
# [user reproduces bug, logs captured to logs/debug-output.log]
/dev-workflow:6-analyze emoji-bug
/dev-workflow:8-verify emoji-bug
```

### Autonomous Workflow Plugin

### `claude-code/plugins/autonomous-workflow/`

Long-running autonomous research, planning, and TDD implementation with 4 modes, 8 research strategies, budget-based phase transitions, and LaTeX report output.

**Modes:**
| Mode | Command | Phases | Outputs |
|------|---------|--------|---------|
| 1 | `/autonomous-workflow:research` | Research only | LaTeX report |
| 2 | `/autonomous-workflow:research-and-plan` | Research + Plan | Report + plan |
| 3 | `/autonomous-workflow:full-auto` | Research + Plan + Implement | Report + plan + code |
| 4 | `/autonomous-workflow:implement` | Implement from plan | Working code |

**Commands:**
```bash
# Research only (infinite until ralph-loop stops)
/ralph-loop:ralph-loop "/autonomous-workflow:research 'topic' 'prompt'" --max-iterations 50

# Full autonomous (research + planning + TDD implementation)
/ralph-loop:ralph-loop "/autonomous-workflow:full-auto 'project' 'prompt' --research-iterations 30 --plan-iterations 15" --max-iterations 150 --completion-promise "WORKFLOW_COMPLETE"

# Resume interrupted workflow
/autonomous-workflow:continue-auto project-name

# Help
/autonomous-workflow:help
```

### Other Plugins

| Plugin | Purpose | Components |
|--------|---------|------------|
| **playwright** | Browser automation with Playwright | JS executor + skill |
| **ralph-loop** | Iterative AI loops for autonomous development | 3 commands, 1 hook |
| **claude-session-feedback** | Export conversations, read history, provide feedback | 4 commands |
| **infrastructure-as-code** | Terraform and AWS management | 1 command, 1 skill |
| **claude-md-best-practices** | CLAUDE.md writing guidance | 1 skill |

## MCP Servers

Configured in `claude-code/global_mcp_settings.json`:

| Server | Type | Purpose |
|--------|------|---------|
| **context7** | HTTP | Documentation retrieval |
| **fetch** | stdio | URL content fetching |
| **exa** | npx | Web search + code context |
| **playwright** | npx | Browser automation |

**Environment Variables Required:**
```bash
CONTEXT7_API_KEY  # For context7 HTTP server
EXA_API_KEY       # For exa web search
```

Store in `.env` file (gitignored).

## Sync Scripts

Bidirectional sync between this repo and `~/.claude/` via `sync-content-scripts/claude-code/`:

| Script | Direction |
|--------|-----------|
| `sync_commands_to_global.sh` | Commands → ~/.claude/commands/ |
| `sync_docs_to_global.sh` | Docs → ~/.claude/docs/ |
| `sync_claude_to_global.sh` | CLAUDE.md → ~/.claude/ |
| `sync_mcp_servers_to_global.sh` | MCP config → ~/.claude/ |

Reverse sync scripts (`*_from_global.sh`) also available for each. Cursor sync: `sync-content-scripts/cursor/sync_to_cursor.sh` (unidirectional).

Plugins install via the marketplace system (not file sync):
```bash
/plugin marketplace add alejandroBallesterosC/personal_configs
/plugin install dev-workflow
```

Sync behavior: Last sync wins (`cp -f`, optional `--overwrite` clears destination first).

## Usage

### Plugin Installation

Register this repo as a Claude Code plugin marketplace, then install plugins:

```bash
# From GitHub
/plugin marketplace add alejandroBallesterosC/personal_configs

# From a local clone
/plugin marketplace add /path/to/personal_configs/claude-code/plugins
```

Then install plugins:
```bash
/plugin install dev-workflow
/plugin install autonomous-workflow
/plugin install playwright
/plugin install claude-session-feedback
/plugin install infrastructure-as-code
/plugin install ralph-loop
/plugin install claude-md-best-practices
```

### Install External Dependencies

```bash
# ralph-loop is required for TDD implementation phases 7-9
/plugin marketplace add alejandroBallesterosC/personal_configs && /plugin install ralph-loop
```

**Warning:** Always set `--max-iterations` with ralph-loop (50 iterations = $50-100+ in API costs).

### Context Preservation

Context is preserved automatically via hooks:
- **Stop hook**: Runs scoped tests + verifies state file accuracy before allowing Claude to stop (dev-workflow + autonomous-workflow)
- **SessionStart hook**: Auto-restores workflow context after `/compact` or `/clear` (dev-workflow + autonomous-workflow)
- **PreCompact hook**: Saves transcript + state snapshot before context compaction (autonomous-workflow only)
- **Manual resume**: `/dev-workflow:continue-workflow <name>` or `/autonomous-workflow:continue-auto <name>` for fresh sessions

## External Dependencies

- **ralph-loop plugin** (required for TDD implementation phases 7-9 and autonomous workflows)
- **Claude Code** (runtime environment)
- **yq + jq** (required for hooks — `brew install yq jq` on macOS)
- **uv** (Python package management, referenced in docs)
- **Node.js 18+** (for Playwright plugin)
- **MacTeX** (optional, for autonomous-workflow LaTeX PDF compilation)

## Documentation

- `docs/CODEBASE.md` - Comprehensive codebase analysis (architecture, workflows, open questions)
- `claude-code/plugins/dev-workflow/README.md` - Dev workflow plugin reference
- `claude-code/plugins/autonomous-workflow/README.md` - Autonomous workflow plugin reference
- `claude-code/docs/` - Python, UV, Docker best practices

---

*Configuration repository for AI-assisted development workflows.*
