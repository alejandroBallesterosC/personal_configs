# Personal Configs - Codebase Analysis

> Last updated: 2026-02-23
> Iteration: 3 of 3 (refresh cycle)

## 1. System Purpose & Domain

Development infrastructure repository for AI-assisted workflows with Claude Code and Cursor IDE. Contains no application code — only Markdown (commands, agents, skills, docs), JSON (configs, manifests), and Shell scripts (hooks, sync). The core domain is **orchestrated TDD implementation and hypothesis-driven debugging** via a plugin-based architecture.

**Core domain entities:**
- **Plugins** (6): Self-contained packages of commands, agents, skills, hooks
- **Workflows**: TDD Implementation (8 phases) and Debug (9 phases)
- **State files**: YAML frontmatter + markdown body tracking workflow progress
- **Hooks**: Event-driven automation (Stop, SessionStart) for context preservation
- **Sync scripts**: Bidirectional config sync between repo and `~/.claude/`

## 2. Technology Stack

| Layer | Technology | Version/Source |
|-------|-----------|----------------|
| Runtime | Claude Code CLI | Anthropic (external) |
| Plugins | Claude Code Plugin System | plugin.json manifests, v1.0.0 |
| Content | Markdown (96 files) | YAML frontmatter conventions |
| Scripts | Bash (23 files) | POSIX-compatible |
| Config | JSON (20 files) | Plugin manifests, hooks, MCP |
| Browser automation | Playwright (JS) | package.json in skill |
| IDE mirror | Cursor IDE | Unidirectional sync (42 files) |
| MCP servers | context7 (HTTP), fetch (stdio), exa (npx), playwright (npx) | global_mcp_settings.json |
| Dependencies | yq, jq (required for hooks), ralph-loop plugin (required for TDD Phase 7-9) | brew install |

## 3. Architecture

### Pattern: Plugin-Based Configuration Infrastructure

```
personal_configs/
├── claude-code/                    # Primary source of truth
│   ├── plugins/ (6 plugins)       # Encapsulated workflow packages
│   │   ├── dev-workflow/          # 11 agents, 18 commands, 6 skills, 4 hooks
│   │   ├── ralph-loop/           # 3 commands, 1 hook (iterative loops)
│   │   ├── playwright/           # 1 skill (browser automation, JS)
│   │   ├── claude-session-feedback/ # 4 commands
│   │   ├── infrastructure-as-code/  # 1 command, 1 skill
│   │   └── claude-md-best-practices/ # 1 skill
│   ├── commands/ (6)             # Global commands (synced to ~/.claude/commands/)
│   ├── docs/ (3)                 # Best practice guides (synced to ~/.claude/docs/)
│   ├── CLAUDE.md                 # Template (synced to ~/.claude/CLAUDE.md)
│   └── global_mcp_settings.json  # MCP config (synced to ~/.claude.json)
├── cursor/                        # Cursor IDE mirror (42 files, unidirectional)
├── sync-content-scripts/          # 9 bidirectional sync scripts
├── CLAUDE.md                      # This repo's coding standards
└── docs/CODEBASE.md              # This file
```

### Data Flow

```
Repository (source of truth)
    │
    ├──[sync scripts]──► ~/.claude/ (global config)
    │   ├── commands/*.md
    │   ├── docs/*.md
    │   ├── CLAUDE.md
    │   └── .claude.json (MCP servers)
    │
    ├──[plugin marketplace]──► Claude Code runtime
    │   └── 6 installed plugins
    │
    └──[sync_to_cursor.sh]──► ~/.cursor/ (IDE config)
        ├── commands/*.md (no YAML frontmatter)
        ├── hooks/ (camelCase events, version:1)
        └── skills/
```

### Hook Architecture

```
Stop Event (on Claude exit attempt)
├── archive-completed-workflows.sh   # Move status:complete to docs/archive/
├── run-scoped-tests.sh              # Run tests per .tdd-test-scope file
├── State verification agent          # Block exit if state file outdated
└── ralph-loop stop-hook.sh          # Block exit + feed prompt back (loop)

SessionStart Event (after compact|clear)
└── auto-resume-after-compact-or-clear.sh  # Inject workflow context
```

## 4. Boundaries & Interfaces

### Plugin Interface Contract
Each plugin is self-contained in `.claude-plugin/plugin.json`:
- **Commands**: YAML frontmatter (`description`, `model`, `argument-hint`) + markdown body
- **Agents**: YAML frontmatter (`name`, `description`, `tools[]`, `model`) + system prompt
- **Skills**: YAML frontmatter (`name`, `description` for activation) + SKILL.md content
- **Hooks**: `hooks.json` registering event handlers (command scripts or agent prompts)

**Coupling**: Plugins are loosely coupled. Only dev-workflow depends on ralph-loop (hard dependency for Phases 7-9) and optionally on playwright (E2E testing). claude-md-best-practices is a soft dependency (skill invocation).

### Hook Interface Contract
- **Command hooks**: Shell scripts returning exit code 0 (success) or 1 (failure)
- **Agent hooks**: Return JSON `{"ok": true}` or `{"ok": false, "reason": "..."}`
- **Stop hooks can block**: Returning failure prevents Claude from exiting
- **SessionStart hooks inject context**: Return JSON with `additionalContext` field

### Sync Interface Contract
- **Direction**: Bidirectional (to/from global) for Claude Code; unidirectional (to) for Cursor
- **Behavior**: `cp -f` (last sync wins), optional `--overwrite` clears destination first
- **Plugins do NOT sync**: Installed via marketplace (`/plugin marketplace add` + `/plugin install`)

### State File Contract
- **Location**: `docs/workflow-<name>/<name>-state.md` (TDD) or `docs/debug/<name>/<name>-state.md` (debug)
- **Format**: YAML frontmatter (`workflow_type`, `name`, `status`, `current_phase`) + markdown body
- **Lifecycle**: Created at workflow start → updated per phase → verified on Stop → archived on completion
- **Guard**: Only one active workflow per type (enforced by start commands)

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin encapsulation | Self-contained dirs with manifests | Flat global commands | Isolation + marketplace distribution vs. more complex installation |
| YAML frontmatter state | Markdown files with YAML headers | JSON/SQLite state | Human-readable + git-friendly vs. no structured querying; requires yq |
| Hook-based verification | Stop hook agent verifies state | Trust Claude to update state | Deterministic correctness vs. 120s timeout on every exit |
| Bidirectional sync | cp -f with overwrite flag | Git submodules or symlinks | Simplicity vs. last-sync-wins can lose changes |
| Cursor mirror | Separate adapted copy | Shared source with adapters | Simpler sync script vs. 42 files to maintain in parallel |
| ralph-loop as external dep | Plugin marketplace install | Built-in to dev-workflow | Separation of concerns vs. extra install step |
| yq for YAML parsing | Shell + yq | Python yaml module | Simpler scripts vs. hard dependency on yq binary |

## 6. Code Quality & Patterns

### Conventions Enforced
1. **ABOUTME comments**: All code files start with 2-line `# ABOUTME:` comments (36 occurrences across repo)
2. **YAML frontmatter**: Commands, agents, skills all use structured YAML headers
3. **Loud dependency failures**: Hook scripts check for yq/jq and exit 1 with install instructions
4. **State file format**: Consistent YAML frontmatter across TDD and debug workflows
5. **Guard clauses**: Single active workflow enforcement in start commands

### Shell Script Quality
- 22 scripts, 13 with `set -e` (error exit on failure)
- Proper quoting, `git rev-parse --show-toplevel` for repo root detection
- Defensive file existence checks before operations
- Non-fatal exits (exit 0) for optional features (no test runner = not an error)

### Test Runner Support
9 frameworks auto-detected by `detect-test-runner.sh`:
pytest, vitest, jest, playwright, go test, cargo test, rspec, minitest, mix

### No Linting/Formatting Config
By design — repo contains only Markdown, JSON, and Bash (no application code to lint).

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| ~~CLAUDE.md says "17 commands" for dev-workflow~~ | ~~Commands now 18~~ | **FIXED** in CLAUDE.md and README.md |
| ~~CLAUDE.md says Cursor "37 files, TDD-only"~~ | ~~Cursor now has 42 files~~ | **FIXED** in CLAUDE.md |
| ~~CLAUDE.md Dependencies says ralph-loop installs via `anthropics/claude-code`~~ | ~~Actual install is via `alejandroBallesterosC/personal_configs`~~ | **FIXED** in CLAUDE.md and README.md |
| VS Code tasks.json lists "Sync Skills" and "Sync Plugins" tasks | No corresponding sync scripts exist (removed in favor of plugin system) | `.vscode/tasks.json` |
| CLAUDE.md says "8 bidirectional + 1 unidirectional sync scripts" | Correct count; description is accurate | `sync-content-scripts/` |
| README.md says "17 commands" in dev-workflow | Should be 18 | `README.md:11` vs `claude-code/plugins/dev-workflow/commands/` |
| README.md says ".vscode/ (15 sync tasks)" | Actual: 16 tasks (13 sync + 3 other) | `README.md:23` vs `.vscode/tasks.json` |

## 8. Cursor Mirror Drift Analysis (Iteration 2)

The Cursor mirror at `cursor/` has **significant drift** from the Claude Code source at `claude-code/plugins/dev-workflow/`:

### Missing from Cursor (entire debug workflow + compare-branches)
- **6 debug commands**: `1-start-debug`, `1-explore-debug`, `3-hypothesize`, `4-instrument`, `6-analyze`, `8-verify`
- **4 debug agents**: `debug-explorer`, `hypothesis-generator`, `instrumenter`, `log-analyzer`
- **2 debug skills**: `debug-workflow-guide`, `structured-debug`
- **1 hook script**: `archive-completed-workflows.sh`

### Naming divergence
| Cursor | Claude Code Source |
|--------|-------------------|
| `1-start.md` | `1-start-tdd-implementation.md` |
| `tdd-workflow-help.md` | `help.md` (comprehensive, both workflows) |
| `continue-tdd-workflow.md` | `continue-workflow.md` (handles both types) |
| `tdd-workflow-guide/` | `tdd-implementation-workflow-guide/` |

### Architecture differences
- Cursor manages ralph-loop locally (inline scripts); Claude Code uses it as external plugin
- Cursor hooks use camelCase events, `$HOME/.cursor/` paths, `"version": 1`
- Cursor `auto-resume` is 91 lines (TDD only); source is 184 lines (TDD + debug)
- Cursor state files use plain markdown; source uses YAML frontmatter

### Matching (no drift)
- `detect-test-runner.sh` and `run-scoped-tests.sh` are identical
- All 7 TDD agents match (with minor frontmatter differences)
- 3 TDD skills match: `testing`, `using-git-worktrees`, `writing-plans`

## 9. Marketplace Registration (Iteration 2, answered)

Two `marketplace.json` files serve different install methods:
- **Root** (`.claude-plugin/marketplace.json`): For GitHub-based install (`/plugin marketplace add alejandroBallesterosC/personal_configs`), uses `./claude-code/plugins/dev-workflow` paths
- **Nested** (`claude-code/plugins/.claude-plugin/marketplace.json`): For local clone install (`/plugin marketplace add /path/to/plugins`), uses `./dev-workflow` relative paths

Both register the same 6 plugins — they're two entry points to the same content.

## 10. VS Code Tasks Audit (Iteration 2, answered)

`.vscode/tasks.json` has **4 dead tasks** referencing non-existent sync scripts:
- "Sync Claude Code Skills to Global" → `sync_skills_to_global.sh` (does not exist)
- "Sync Claude Code Skills from Global" → `sync_skills_from_global.sh` (does not exist)
- "Sync Claude Code Plugins to Global" → `sync_plugins_to_global.sh` (does not exist)
- "Sync Claude Code Plugins from Global" → `sync_plugins_from_global.sh` (does not exist)

These were likely removed when skills/plugins moved from file sync to the plugin marketplace system.

Also has a "Compile Frontend Typescript" task referencing `${workspaceFolder}/frontend` and an `inputs` section referencing "HoPF config file" — both appear to be leftovers from a previous project.

## 11. Open Questions

- [x] ~~Are the VS Code tasks for "Sync Skills" and "Sync Plugins" dead references?~~ **Yes** — 4 dead tasks + 2 unrelated tasks (see Section 10)
- [x] ~~Are the Cursor mirror files diverging from Claude Code source?~~ **Yes, significantly** — entire debug workflow missing (see Section 8)
- [x] ~~Marketplace.json relationship?~~ **Answered** — two install entry points (see Section 9)
- [x] ~~Should CLAUDE.md line 39 ("No dependencies") be updated?~~ **Already done** — yq/jq added to Dependencies section
- [x] ~~Is the ralph-loop + dev-workflow Stop hook execution causing issues?~~ **Investigated** — execution order follows plugin registration order in marketplace.json (dev-workflow first, ralph-loop second). If test failure exits nonzero, ralph-loop hook may never run, stranding active loops. Behavior is undocumented by Anthropic. See Section 17.
- [x] ~~CLAUDE.md accuracy?~~ **Audited** — 17->18 commands, Cursor 37->42 files, ralph-loop install path wrong. See Section 7.
- [ ] Should the Cursor mirror be updated to include the debug workflow?
- [ ] Should dead VS Code tasks be removed?
- [ ] Is the 120s timeout for the Stop hook state verification agent sufficient for large workflows?
- [ ] Should `detect-test-runner.sh` support additional frameworks (e.g., PHPUnit, dotnet test)?
- [ ] Should there be a PreCompact hook to save state before auto-compaction?
- [x] ~~Should CLAUDE.md and README.md be updated?~~ **Done** — fixed 18 commands, 42 cursor files, correct ralph-loop install path in both files

## 12. Changes Since 2026-02-09

### New Commands
- `claude-code/plugins/dev-workflow/commands/compare-branches.md` — Parallel branch comparison using subagents (270 lines)
- `claude-code/commands/update-docs.md` — Replaced `update-docs-and-todos.md`, now uses 4 parallel Sonnet agents
- `cursor/commands/understand-repo.md` — Cursor mirror of the understand-repo command (169 lines)
- `cursor/commands/update-docs.md` — Cursor mirror of the update-docs command (31 lines)
- `cursor/commands/answer-question-using-internet-research.md` — Internet research command for Cursor

### New Infrastructure
- `.github/workflows/claude.yml` — Claude Code GitHub Action (disabled/commented out)
- `.github/workflows/claude-code-review.yml` — PR review with progress tracking (disabled/commented out)
- `.vscode/scripts/compile_latex.sh` — LaTeX compilation utility (56 lines)
- `.vscode/settings.json` — Python venv and analysis path configuration

### Updated Counts
| Component | Previous (Feb 9) | Current (Feb 23) |
|-----------|-------------------|-------------------|
| Total files | ~145 | 152 |
| Dev-workflow commands | 17 | 18 (+compare-branches) |
| Cursor commands | ~15 | 19 (+understand-repo, update-docs, internet-research, compare-branch) |
| Global commands | 6 | 6 (update-docs replaced update-docs-and-todos) |
| GitHub workflows | 0 | 2 (both disabled) |

## 13. Sync Script Analysis (from Iteration 3, 2026-02-09)

### `sync_to_cursor.sh` — Simple file copy, no content adaptation
The script (`sync-content-scripts/cursor/sync_to_cursor.sh`, 92 lines) is a straightforward `cp -r` that copies `cursor/` contents to `~/.cursor/`. It does NOT:
- Adapt YAML frontmatter (Cursor commands already lack it in the source `cursor/commands/`)
- Convert hook event names (Cursor hooks.json is already camelCase in the source)
- Transform paths (Cursor scripts already use `$HOME/.cursor/` in the source)

This means all Cursor-specific adaptations are baked into the `cursor/` directory itself — the sync script is just a deployer. Adding debug workflow to Cursor requires creating adapted copies of all debug files in `cursor/`, not modifying the sync script.

### Bidirectional sync risk
All `sync_*_to_global.sh` scripts use `cp -f` (force overwrite). The `--overwrite` flag adds `rm -rf` of the destination before copying. There is no diff, merge, or backup (except for Cursor's `hooks.json` which creates a `.bak`).

## 14. Test Runner Detection Coverage

`detect-test-runner.sh` (82 lines) checks 9 frameworks in priority order:
1. **pytest** — pyproject.toml, pytest.ini, setup.py, setup.cfg (verifies pytest is mentioned)
2. **playwright** — playwright.config.ts/js
3. **vitest** — vitest.config.ts/js/mts
4. **jest** — jest.config.js/ts/mjs
5. **Node.js fallback** — package.json grep for `@playwright/test`, `jest`, `vitest`
6. **go** — go.mod
7. **cargo** — Cargo.toml
8. **rspec** — Gemfile + grep "rspec"
9. **minitest** — Gemfile + grep "minitest"
10. **mix** — mix.exs

**Not supported**: PHPUnit, dotnet test, swift test, Deno test, Bun test. These could be added if needed but the current 9 cover the most common stacks.

**Edge case**: If a project has both vitest.config and jest.config, vitest wins (checked first). Playwright config files beat all JS runners.

## 15. TDD Workflow Trace (Iteration 2 Deep Dive)

### Phase Execution Summary

| Phase | Command | Agents Spawned | Output Files | Gate |
|-------|---------|----------------|-------------|------|
| Init | `1-start-tdd-implementation` | None | `*-original-prompt.md`, `*-state.md` | ralph-loop check |
| 2: Explore | `2-explore` | 5x code-explorer (parallel, Sonnet) | `codebase-context/*-exploration.md` | User confirmation |
| 3: Interview | `3-user-specification-interview` | None (main Opus) | `specs/*-specs.md` | 40+ AskUserQuestions |
| 4: Architecture | `4-plan-architecture` | Optional code-architect (Opus) | `plans/*-architecture-plan.md` | None |
| 5: Plan | `5-plan-implementation` | None (main Opus) | `plans/*-implementation-plan.md`, `plans/*-tests.md` | None |
| 6: Review | `6-review-plan` | plan-reviewer (Opus) | Updated plans | User approval required |
| 7: Implement | `7-implement` | ralph-loop -> test-designer, implementer, refactorer | Working code + tests | Per-component completion |
| 8: E2E | `8-e2e-test` | ralph-loop -> test-designer, implementer | E2E tests passing | All tests green |
| 9: Review | `9-review` | 5x code-reviewer (parallel, Sonnet) | Review findings | Fix criticals |

### Key Mechanisms
- **Phase 7 parallel components**: Independent components get ralph-loop instances launched in parallel; dependent components run sequentially
- **`.tdd-test-scope` file**: Written by orchestrator before each test run, consumed and deleted by `run-scoped-tests.sh`
- **Foundation-first pattern**: Shared types/interfaces created before parallel component implementation
- **Phase 6 explicit approval**: Only phase requiring user to say "proceed" before implementation starts
- **Phase 9 completion**: Updates state to `status: complete`, archives to `docs/archive/`

## 16. Debug Workflow Trace (Iteration 2 Deep Dive)

### Phase Numbering (Fragmented)

| Phase | Command | Agent | Human Gate? | Loopback? |
|-------|---------|-------|-------------|-----------|
| 1: Explore | `1-start-debug` (calls `1-explore-debug`) | debug-explorer (Sonnet) | No | No |
| 2: Describe | `1-start-debug` (Step 4) | None (Opus asks user) | Yes | No |
| 3: Hypothesize | `3-hypothesize` | hypothesis-generator (Sonnet) | No (but review) | Target of loopback |
| 4: Instrument | `4-instrument` | instrumenter (Sonnet) | No | Target of loopback |
| 5: Reproduce | Implicit (user action) | None | Yes | No |
| 6: Analyze | `6-analyze` | log-analyzer (Sonnet) | No | Triggers loopbacks |
| 7: Fix | `6-analyze` (Step 5.1) | None (Opus applies fix) | No | No |
| 8: Verify | `8-verify` | None (user verifies) | Yes | Triggers loopbacks |
| 9: Clean | `8-verify` (Step 6) | None (Opus cleanup) | No | No |

### Loopback Flows
1. **All hypotheses rejected** (Phase 6 -> Phase 3): Generate new hypotheses from unexpected log findings
2. **Inconclusive evidence** (Phase 6 -> Phase 4): Add more instrumentation for missing evidence
3. **Fix failed** (Phase 8 -> Phase 6): Re-analyze with new logs after failed fix
4. **3-Fix Rule**: After 3 failed fix attempts, stop and ask user about architectural assumptions

### Key Findings
- Command numbering is misleading: `1-start-debug` handles Phases 1-2, `6-analyze` handles Phases 6-7, `8-verify` handles Phases 8-9
- No dedicated Phase 5 command (user manually reproduces bug)
- Instrumentation uses `[DEBUG-H1]` tagged markers for cleanup tracking
- `logs/debug-output.log` overwritten on each reproduction run (not appended)
- State file tracks `fix_attempts` counter with `max_fix_attempts: 3`

## 17. Hook Execution Analysis (Iteration 2 Deep Dive)

### Stop Hook Chain (Claude Code)

```
1. archive-completed-workflows.sh   → always exits 0 (non-fatal)
2. run-scoped-tests.sh              → exits 0 (no tests/pass) or 1+ (fail)
   IF exit 1+: CHAIN HALTS (hooks 3-4 never run)
3. State verification agent          → JSON {ok:true/false}, 120s timeout
   IF ok:false: blocks exit
4. ralph-loop stop-hook.sh          → exits 0 (no loop) or blocks with JSON
   IF loop active: {decision:"block", reason:"prompt"}
```

### Exit Code Propagation Risk
If tests fail (step 2 exits nonzero), the verify-state-file agent and ralph-loop hook never execute. This means:
- State file may not be verified on test failure
- Active ralph-loop may get stranded (state file persists to next session)

### Cursor Hook Differences

| Aspect | Claude Code | Cursor |
|--------|------------|--------|
| Event names | `Stop`, `SessionStart` | `stop`, `sessionStart` |
| API version | (none) | `"version": 1` |
| Block JSON | `{decision:"block", reason:"..."}` | `{continue:false, userMessage:"..."}` |
| Plugin root | `${CLAUDE_PLUGIN_ROOT}` | `$HOME/.cursor/` |
| Archive hook | Present | Missing |
| Debug resume | TDD + Debug | TDD only |

### Shell Script Dependencies

| Script | Hard Deps | Soft Deps | Failure Mode |
|--------|-----------|-----------|--------------|
| archive-completed-workflows.sh | yq | git | Exit 1 if yq missing; exit 0 if no git |
| run-scoped-tests.sh | (none) | test runners, uv | Exit 0 if no runner found |
| auto-resume-after-compact-or-clear.sh | yq, jq | (none) | Exit 1 if either missing |
| ralph-loop stop-hook.sh | (none) | jq, perl | Exit 0 on parse failure (stops loop) |
| detect-test-runner.sh | (none) | (none) | Always exits 0 ("unknown" on no match) |

## 18. Ambiguities

- **Hook execution order**: When multiple plugins register Stop hooks, the order depends on plugin load order. If test failure (exit 1+) halts the chain, ralph-loop may get stranded.
- **Sync conflict resolution**: With bidirectional sync scripts and last-sync-wins behavior, there's no merge strategy. If both sides are edited independently, the last sync silently overwrites.
- **Cursor mirror maintenance strategy**: All adaptations are baked into `cursor/` directory files. Adding debug workflow to Cursor requires creating adapted copies of all debug files in `cursor/`, not modifying the sync script. It's unclear whether Cursor is intended to have full parity or remain TDD-only.
- **VS Code tasks.json leftovers**: Contains tasks for "Compile Frontend Typescript" and an input for "HoPF config file" that appear to be from a previous project.
- **Debug phase 5 ownership**: No dedicated command for Phase 5 (Reproduce). The user must manually trigger the bug and confirm — the workflow pauses with instructions and resumes when user says "done".
- **State file verification scope**: The Stop hook agent has a 120s timeout. For complex multi-component workflows, this may not be sufficient to verify all state file fields accurately.
