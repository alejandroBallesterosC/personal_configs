# Personal Configs - Codebase Analysis

> Last updated: 2026-04-15
> Iteration: 3 of 3 (refresh cycle)

## 1. System Purpose & Domain

Development infrastructure repository for AI-assisted workflows with Claude Code and Cursor IDE. Contains no application code — only Markdown (commands, agents, skills, docs), JSON (configs, manifests), and Shell scripts (hooks, sync). The core domain is **orchestrated TDD implementation, hypothesis-driven debugging, and autonomous multi-phase research/planning/implementation** via a plugin-based architecture.

**Core domain entities:**
- **Plugins** (9 active, 1 deprecated): Self-contained packages of commands, agents, skills, hooks
- **Workflows**: TDD Implementation (8 phases), Debug (9 phases), Autonomous (3 phases: Research/Planning/Implementation with 4 modes)
- **State files**: YAML frontmatter + markdown body tracking workflow progress
- **Hooks**: Event-driven automation (Stop, SessionStart) for context preservation and iteration control
- **Sync**: Symlinks for Claude Code (`~/.claude/`), copy-based for Cursor (`~/.cursor/`)

## 2. Technology Stack

| Layer | Technology | Version/Source |
|-------|-----------|----------------|
| Runtime | Claude Code CLI | Anthropic (external) |
| Plugins | Claude Code Plugin System | plugin.json manifests |
| Content | Markdown (117 files) | YAML frontmatter conventions |
| Scripts | Bash (27 files) | POSIX-compatible |
| Config | JSON (22 files) | Plugin manifests, hooks, MCP |
| Browser automation | Playwright (`playwright-cli` + `@playwright/test`) | npm global install |
| IDE mirror | Cursor IDE | Unidirectional sync |
| MCP servers | context7 (HTTP), fetch (stdio), exa (npx), playwright (npx) | global_mcp_settings.json |
| Dependencies | yq, jq (hooks), ralph-loop plugin (long-horizon-impl 2-implement), MacTeX (optional, LaTeX PDF) | brew install |

## 3. Architecture

### Pattern: Plugin-Based Configuration Infrastructure

```
personal_configs/
├── claude-code/                    # Primary source of truth
│   ├── plugins/ (10 plugins, 9 active + 1 deprecated)
│   │   ├── dev-workflow/          # 12 agents, 20 commands, 6 skills, 5 hooks
│   │   ├── research-report/      # 4 agents, 3 commands, 1 skill, 2 hooks
│   │   ├── long-horizon-impl/    # 9 agents, 4 commands, 1 skill, 2 hooks
│   │   ├── ralph-loop/           # 3 commands, 1 hook (iterative loops)
│   │   ├── playwright/           # 1 skill (browser automation, CLI-based)
│   │   ├── claude-session-feedback/ # 4 commands
│   │   ├── infrastructure-as-code/  # 1 command, 1 skill
│   │   ├── claude-md-best-practices/ # 1 skill
│   │   ├── notify/               # 2 hooks (Notification, Stop)
│   │   └── autonomous-workflow/  # DEPRECATED (replaced by research-report + long-horizon-impl)
│   ├── agents/ (1)               # Global subagents (symlinked to ~/.claude/agents/)
│   ├── commands/ (8)             # Global commands (symlinked to ~/.claude/commands/)
│   ├── docs/ (3)                 # Best practice guides (symlinked to ~/.claude/docs/)
│   ├── CLAUDE.md                 # Template (symlinked to ~/.claude/CLAUDE.md)
│   └── global_mcp_settings.json  # MCP config
├── cursor/                        # Cursor IDE mirror (TDD-only, unidirectional)
├── sync-content-scripts/          # Symlink setup (Claude Code) + copy sync (Cursor)
├── CLAUDE.md                      # This repo's coding standards
└── docs/CODEBASE.md              # This file
```

### Data Flow

```
Repository (source of truth)
    │
    ├──[symlinks]──► ~/.claude/ (global config)
    │   ├── agents/ → claude-code/agents/
    │   ├── commands/ → claude-code/commands/
    │   ├── docs/ → claude-code/docs/
    │   └── CLAUDE.md → claude-code/CLAUDE.md
    │
    ├──[plugin marketplace]──► Claude Code runtime
    │   └── 10 registered plugins (9 active + 1 deprecated)
    │
    └──[sync_to_cursor.sh]──► ~/.cursor/ (IDE config, copy-based)
        ├── commands/*.md (no YAML frontmatter)
        ├── hooks/ (camelCase events, version:1)
        └── skills/
```

### Hook Architecture

Plugin execution order follows marketplace.json registration order:
1. dev-workflow, 2. playwright, 3. claude-session-feedback, 4. infrastructure-as-code, 5. ralph-loop, 6. claude-md-best-practices, 7. autonomous-workflow (deprecated), 8. research-report, 9. long-horizon-impl, 10. notify

```
Stop Event (on Claude exit attempt) — all matching hooks run in parallel
├── dev-workflow:
│   ├── archive-completed-workflows.sh   # Move status:complete to .plugin-state/archive/
│   ├── run-scoped-tests.sh              # Run tests per .tdd-test-scope file
│   └── tdd-implementation-gate.sh         # Block exit during phases 7-9 + re-feed command
├── ralph-loop:
│   └── stop-hook.sh                     # Block exit + feed prompt back (loop)
├── research-report:
│   └── stop-hook.sh                     # Iteration engine + completion verifier
├── long-horizon-impl:
│   └── stop-hook.sh                     # Iteration engine + completion verifier
├── notify:
│   └── cc-notify.sh done               # Terminal bell + macOS banner
└── .claude/hooks/ (project-level):
    └── document-learnings.sh            # Prompt Claude to document insights

Notification Event (permission_prompt|idle_prompt|elicitation_dialog)
└── notify:
    └── cc-notify.sh input              # Terminal bell + macOS banner

SessionStart Event (after compact|clear) — sequential
├── dev-workflow:
│   └── auto-resume-after-compact-or-clear.sh  # Inject TDD/debug context
├── research-report:
│   └── auto-resume-after-compact-or-clear.sh  # Inject research context
└── long-horizon-impl:
    └── auto-resume-after-compact-or-clear.sh  # Inject research/planning/impl context
```

**Note**: All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). The most restrictive decision wins after all hooks complete.

## 4. Boundaries & Interfaces

### Plugin Interface Contract
Each plugin is self-contained in `.claude-plugin/plugin.json`:
- **Commands**: YAML frontmatter (`description`, `model`, `argument-hint`) + markdown body
- **Agents**: YAML frontmatter (`name`, `description`, `tools[]`, `model`) + system prompt
- **Skills**: YAML frontmatter (`name`, `description` for activation) + SKILL.md content
- **Hooks**: `hooks.json` registering event handlers (command scripts or agent prompts)

**Coupling**: Plugins are loosely coupled. dev-workflow has no hard plugin dependencies (uses built-in TDD implementation gate Stop hook for Phases 7-9) and optionally playwright (E2E, visual verification). long-horizon-impl depends on ralph-loop (hard, 2-implement iteration) and optionally exa MCP (deep research), MacTeX (PDF output), and playwright-cli (visual verification of UI features). claude-md-best-practices is a soft dependency (skill invocation). notify has no plugin dependencies (only requires terminal-notifier for full functionality, falls back to osascript).

### Hook Interface Contract
- **Command hooks**: Shell scripts returning exit code 0 (allow) or JSON `{"decision": "block", ...}` (block)
- **Agent hooks**: Return JSON `{"ok": true}` or `{"ok": false, "reason": "..."}`
- **Exit code 2**: Missing dependency (yq/jq) — fatal, with install instructions
- **Stop hooks can block**: Returning JSON decision blocks Claude from exiting
- **SessionStart hooks inject context**: Return JSON with `additionalContext` field

### Sync Interface Contract
- **Claude Code**: Symlinks from `~/.claude/` to repo (`setup_symlinks.sh`) for CLAUDE.md, agents/, commands/, docs/. Changes in repo are immediately live.
- **Cursor**: Copy-based sync (`sync_to_cursor.sh`), unidirectional. Symlinks are unreliable in Cursor due to known bugs with skill/agent discovery after restart.
- **Plugins do NOT sync**: Installed via marketplace (`/plugin marketplace add` + `/plugin install`)

### State File Contract
- **TDD state**: `.plugin-state/workflow-<name>/<name>-state.md` — YAML frontmatter (`workflow_type`, `name`, `status`, `current_phase`)
- **Debug state**: `.plugin-state/debug/<name>/<name>-state.md` — Same format + `fix_attempts`, `max_fix_attempts`
- **Autonomous research state**: `.claude/autonomous-<topic>-research-state.md` — YAML with `current_research_strategy`, `research_budget`, iteration tracking
- **Autonomous implementation state**: `.claude/autonomous-<topic>-implementation-state.md` — YAML with `planning_budget`, `features_total/complete/failed`
- **Autonomous feature list**: `.claude/autonomous-<topic>-feature-list.json` — JSON array of features for TDD implementation
- **Lifecycle**: Created at workflow start -> updated per phase -> verified on Stop -> archived on completion (dev-workflow) or deleted on completion (autonomous-workflow)
- **Guard**: Only one active workflow per type (enforced by start commands)

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin encapsulation | Self-contained dirs with manifests | Flat global commands | Isolation + marketplace distribution vs. more complex installation |
| YAML frontmatter state | Markdown files with YAML headers | JSON/SQLite state | Human-readable + git-friendly vs. no structured querying; requires yq |
| Hook-based verification | Stop hook agent verifies state | Trust Claude to update state | Deterministic correctness vs. 120s timeout on every exit |
| Symlinks for Claude Code | Symlinks to repo dirs | Copy-based sync scripts | Instant sync, single source of truth vs. breaks if repo moves |
| Cursor mirror | Separate adapted copy | Shared source with adapters | Simpler sync script vs. files to maintain in parallel |
| Built-in TDD gate hook | Stop hook blocks during Phases 7-9, re-feeds command | External ralph-loop plugin | No external dependency vs. shared iteration engine |
| yq for YAML parsing | Shell + yq | Python yaml module | Simpler scripts vs. hard dependency on yq binary |
| Subagent data isolation | Sonnet absorbs raw web data, Opus gets summaries | Main instance does all research | Prevents context bloat in long-running workflows |
| Budget-based phase transitions | Iteration count triggers transition | Contribution-based / quality heuristics | Predictable timing vs. may transition when still productive |
| Artifact-first memory | .tex/.md files are canonical state | Conversation history | Survives context compaction vs. requires disciplined file updates |
| Autonomous state in .claude/ | `.claude/` directory for state files | `docs/autonomous/` | Keeps ephemeral state separate from persistent docs vs. not git-tracked |
| Stop hook iteration engine | Hook re-feeds command on in_progress | ralph-loop for autonomous iteration | Direct iteration control per workflow type vs. simpler but less workflow-aware |

## 6. Code Quality & Patterns

### Conventions Enforced
1. **ABOUTME comments**: All code files start with 2-line `# ABOUTME:` comments (36+ occurrences)
2. **YAML frontmatter**: Commands, agents, skills all use structured YAML headers
3. **Loud dependency failures**: Hook scripts check for yq/jq and exit 2 with install instructions
4. **State file format**: Consistent YAML frontmatter across TDD, debug, and autonomous workflows
5. **Guard clauses**: Single active workflow enforcement in start commands
6. **Strategy rotation**: 8 research strategies with contribution-based rotation (autonomous-workflow)
7. **Atomic file updates**: Hooks use temp file + mv for safe iteration counter increments

### Shell Script Quality
- 27 scripts, majority with `set -euo pipefail` (strict error handling)
- Proper quoting, `git rev-parse --show-toplevel` for repo root detection
- Defensive file existence checks before operations
- Non-fatal exits (exit 0) for optional features (no test runner = not an error)
- Debug logging to `.claude/<hook-name>-debug.log` files
- Trap handlers for cleanup in test scripts

### Test Runner Support
9 frameworks auto-detected by `detect-test-runner.sh`:
pytest, vitest, jest, playwright, go test, cargo test, rspec, minitest, mix

### Testing
- `test-stop-hook.sh` (20 test cases): Comprehensive hook validation with custom assertion helpers
- `test-hooks.sh`: Integration tests for autonomous-workflow hooks
- Custom shell testing: assert_exit_code(), assert_output_contains(), assert_valid_json(), assert_json_field()
- Test isolation: Each test runs in mktemp -d, cleaned up via trap
- No external linting configured (no application code to lint)

### No Linting/Formatting Config
By design — repo contains only Markdown, JSON, and Bash (no application code to lint).

## 7. Plugin Details

### dev-workflow (v2.2.0) — TDD Implementation + Debug

**Components**: 12 agents, 20 commands, 6 skills, 5 hooks (Stop x4, SessionStart x1)

**TDD Phases** (8):
| Phase | Command | Agents | Gate |
|-------|---------|--------|------|
| Init | `1-start-tdd-implementation` | None | None |
| 2: Explore | `2-explore` | 5x code-explorer (Sonnet, parallel) | User confirmation |
| 3: Interview | `3-user-specification-interview` | None (Opus) | 40+ questions |
| 4: Architecture | `4-plan-architecture` | code-architect (Opus) | None |
| 5: Plan | `5-plan-implementation` | None (Opus) | None |
| 6: Review | `6-review-plan` | plan-reviewer (Opus) | User approval |
| 7: Implement | `7-implement` | orchestrator -> test-designer, implementer, refactorer | Per-component |
| 8: E2E | `8-e2e-test` | orchestrator -> test-designer, implementer | All tests green |
| 9: Review | `9-review` | 5x code-reviewer (Sonnet, parallel) | Fix criticals |

**Debug Phases** (9): Hypothesis-driven with loopback flows. 3-fix rule (after 3 failed fixes, question architecture).

**Key patterns**:
- Foundation-first: shared types/interfaces before parallel component implementation
- `.tdd-test-scope` file: one-shot test scope consumed by Stop hook
- Phase 6 is only phase requiring explicit user approval
- Model strategy: Sonnet (1M context) for exploration/review agents, Opus for architecture/implementation/testing

### autonomous-workflow (DEPRECATED)

Replaced by **research-report** and **long-horizon-impl** plugins. Still registered in marketplace for backwards compatibility.

### research-report — Iterative Deep Research

**Components**: 4 agents, 3 commands, 1 skill, 2 hooks (Stop, SessionStart)

Autonomous iterative deep research producing LaTeX reports with synthesis, 9 research strategies, parallel subagents, and strategy rotation. Uses its own Stop hook iteration engine (no ralph-loop dependency).

### long-horizon-impl — Research/Planning/TDD Implementation

**Components**: 9 agents, 4 commands, 1 skill, 2 hooks (Stop, SessionStart)

Long-running autonomous research, planning, and TDD implementation with parallel subagents, anti-slop escalation, and multi-day execution. 1-research-and-plan uses its own Stop hook for iteration; 2-implement uses ralph-loop.

### notify — Terminal Notifications

**Components**: 2 hooks (Notification, Stop)

Terminal bell (BEL) and macOS banner notifications via terminal-notifier (with osascript fallback). Designed for tmux + Ghostty workflows. Sends notifications on Stop events (Claude finished responding) and Notification events (Claude needs input — permission prompts, idle prompts, elicitation dialogs).

**Dependencies**: `terminal-notifier` (optional, `brew install terminal-notifier`; falls back to osascript).

### ralph-loop (v1.2.0) — Iterative Loop Engine

**Components**: 3 commands, 1 hook (Stop)

**Role**: Provides iteration loop for long-horizon-impl 2-implement. Uses `.claude/ralph-loop.local.md` state file with YAML frontmatter tracking iteration count and completion promise.

**Mechanism**: Stop hook checks for `<promise>TEXT</promise>` XML tags in Claude's output via Perl regex. If found -> allows stop. If not -> increments iteration counter atomically (PID-based temp file + mv) -> blocks stop with JSON `{decision: "block"}` containing prompt for next iteration.

**Safety**: Always set `--max-iterations` (50 iterations = $50-100+ in API costs).

### Other Plugins

- **playwright** (v5.0.0): Browser automation via `playwright-cli` (interactive) and `@playwright/test` (CI). Skill-only plugin — no commands, agents, or hooks
- **claude-session-feedback** (v1.0.0): 4 commands for conversation export/feedback
- **infrastructure-as-code** (v1.0.0): 1 command + 1 skill for Terraform/AWS
- **claude-md-best-practices** (v1.0.0): 1 skill for CLAUDE.md writing guidance

## 8. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| autonomous-workflow marked deprecated in marketplace.json | Replaced by research-report + long-horizon-impl | `.claude-plugin/marketplace.json` |
| VS Code tasks.json lists "Sync Skills" and "Sync Plugins" tasks | No corresponding sync scripts exist | `.vscode/tasks.json` |
| CLAUDE.md architecture shows correct counts (9 active plugins) | Matches actual plugin structure | `CLAUDE.md:7-21` |

## 9. Cursor Mirror Drift Analysis

The Cursor mirror at `cursor/` has **significant drift** from the Claude Code source:

### Missing from Cursor (entire debug + autonomous workflows)
- **6 debug commands**: `1-start-debug`, `2-explore-debug`, `4-hypothesize`, `5-instrument`, `7-analyze`, `9-verify`
- **4 debug agents**: `debug-explorer`, `hypothesis-generator`, `instrumenter`, `log-analyzer`
- **2 debug skills**: `debug-workflow-guide`, `structured-debug`
- **1 hook script**: `archive-completed-workflows.sh`
- **Entire autonomous-workflow**: Not mirrored to Cursor at all

### Architecture differences
- Cursor manages ralph-loop locally (inline scripts); Claude Code uses it as external plugin
- Cursor hooks use camelCase events, `$HOME/.cursor/` paths, `"version": 1`
- Cursor `auto-resume` is TDD only (91 lines); source handles TDD + debug (184 lines)

## 10. VS Code Tasks Audit

`.vscode/tasks.json` has **4 dead tasks** referencing non-existent sync scripts:
- "Sync Claude Code Skills to/from Global" -> scripts removed (plugin system replaced)
- "Sync Claude Code Plugins to/from Global" -> scripts removed (plugin system replaced)

Also has leftover tasks: "Compile Frontend Typescript" and "HoPF config file" input from a previous project.

## 11. Hook Execution Analysis

### Stop Hook Chain

All matching Stop hooks across all plugins run in **parallel** (official Claude Code behavior). The most restrictive decision wins after all hooks complete.

```
dev-workflow: tdd-implementation-gate.sh       -> blocks during Phases 7-9, re-feeds command
dev-workflow: archive-completed-workflows.sh   -> always exits 0
dev-workflow: run-scoped-tests.sh              -> exits 0 or blocks with JSON
dev-workflow: tdd-implementation-gate.sh        -> block+re-feed during phases 7-9, allow otherwise
ralph-loop: stop-hook.sh                       -> exits 0 or blocks with JSON
research-report: stop-hook.sh                  -> iteration engine + completion verifier
long-horizon-impl: stop-hook.sh                -> iteration engine + completion verifier
notify: cc-notify.sh done                      -> terminal bell + macOS banner (always exits 0)
.claude/hooks/document-learnings.sh            -> blocks to prompt documentation (project-level)
```

**Note**: Since hooks run in parallel, all hooks execute regardless of individual blocking decisions. The most restrictive decision (block) wins.

### Iteration Engine Stop Hook Mechanism (research-report, long-horizon-impl)

The stop-hook.sh in both research-report and long-horizon-impl acts as iteration engine and completion verifier:

1. Searches for active state files in `.plugin-state/`
2. Reads YAML frontmatter with yq: `status`, `iteration`, `command`, budget fields
3. If `status: in_progress` and iteration < budget:
   - Increments iteration atomically (sed + temp file + mv)
   - Returns JSON `{decision: "block", reason: "<command>"}` to re-feed command
4. If budget exhausted or `status: complete`:
   - Cleans up state files
   - Exits 0 (allows stop)

### Notify Hook Mechanism

The cc-notify.sh hook sends two types of notifications:

1. **Terminal bell**: `printf '\a'` sent to `/dev/tty` for Ghostty bell-features (dock bounce, title indicator, border flash, system sound)
2. **macOS banner**: via `terminal-notifier` (preferred, supports click-to-focus and per-event sounds) or `osascript` (fallback)

Triggers on two events:
- **Stop**: "Finished responding" notification with Glass sound
- **Notification** (permission_prompt|idle_prompt|elicitation_dialog): "Needs your input" notification with Funk sound

### Document-Learnings Hook (Project-Level)

The `.claude/hooks/document-learnings.sh` is a project-level Stop hook (not a plugin hook):

1. Compares current `git status` against a session baseline snapshot
2. If file changes detected since session start, blocks with a prompt asking Claude to document architectural decisions and insights
3. Skips if no new changes or if already triggered by a stop hook (prevents infinite loops via `stop_hook_active` check)

### Ralph-Loop Integration Mechanism

1. `setup-ralph-loop.sh` creates `.claude/ralph-loop.local.md` state file with YAML frontmatter (`iteration`, `max_iterations`, `completion_promise`) and prompt body
2. On Stop event, `stop-hook.sh` reads state file, extracts last assistant message from transcript
3. Checks for `<promise>TEXT</promise>` XML tags via Perl regex; literal string match against `completion_promise`
4. If match found -> deletes state file -> exits 0 (allows stop, loop ends)
5. If no match -> increments iteration counter atomically (temp file + mv) -> outputs JSON `{decision: "block", reason: "<prompt>"}` -> Claude receives prompt as next iteration input
6. If `iteration >= max_iterations` -> deletes state file -> exits 0 (allows stop, budget exhausted)

**State file atomicity**: Uses PID-based temp file `${FILE}.tmp.$$` + `mv` for POSIX-atomic iteration counter updates.

### JSON Output Format (Stop Hooks)

All blocking hooks use the same format:
```json
{
  "decision": "block",
  "reason": "<diagnostic or prompt text>",
  "systemMessage": "<user-facing message>"
}
```

**Plugin-specific behavior**:
- **dev-workflow gate**: `reason` = current phase command to re-feed; `systemMessage` = phase + state file path
- **ralph-loop**: `reason` = the prompt to re-execute; `systemMessage` = iteration count + promise reminder
- **research-report / long-horizon-impl**: `reason` = re-feed command; `systemMessage` = iteration progress
- **document-learnings**: `reason` = prompt to document insights; no `systemMessage`
- **dev-workflow agent**: Returns `{ok: true/false, reason: "..."}` (different format)
- **notify**: Does not block (always exits 0)

### Shell Script Dependencies

| Script | Hard Deps | Failure Mode |
|--------|-----------|--------------|
| tdd-implementation-gate.sh | yq, jq | Exit 2 if missing |
| archive-completed-workflows.sh | yq | Exit 2 if yq missing |
| run-scoped-tests.sh | jq | Exit 2 if jq missing |
| auto-resume-after-compact-or-clear.sh (dev) | yq, jq | Exit 2 if missing |
| auto-resume-after-compact-or-clear.sh (research-report) | yq, jq | Exit 2 if missing |
| auto-resume-after-compact-or-clear.sh (long-horizon-impl) | yq, jq | Exit 2 if missing |
| stop-hook.sh (research-report) | yq, jq | Exit 2 if missing |
| stop-hook.sh (long-horizon-impl) | yq, jq | Exit 2 if missing |
| ralph-loop stop-hook.sh | (none) | Exit 0 on parse failure |
| cc-notify.sh (notify) | (none) | Falls back to osascript if terminal-notifier missing |
| document-learnings.sh (project-level) | jq, git | Exit 0 if no changes |
| detect-test-runner.sh | (none) | Always exits 0 |

## 12. Open Questions

- [ ] Should the Cursor mirror be updated to include the debug workflow?
- [ ] Should dead VS Code tasks be removed?
- [x] ~~Is the 120s timeout for the Stop hook state verification agent sufficient for large workflows?~~ **Resolved**: State verification agent removed — it competed with the TDD implementation gate during phases 7-9, causing an infinite loop of conflicting blocks. The gate handles phase-based blocking; the command prompts handle state file updates.
- [ ] Should `detect-test-runner.sh` support additional frameworks (e.g., PHPUnit, dotnet test)?
- [x] ~~How do multiple Stop hooks interact across plugins when one fails?~~ **Answered**: Sequential execution per marketplace.json order. If hook exits nonzero or blocks, downstream hooks may not run.
- [x] ~~Should autonomous-workflow verify-state.sh run before or after ralph-loop?~~ **Answered**: autonomous-workflow stop-hook.sh runs AFTER ralph-loop (marketplace order). This means it doesn't run between ralph-loop iterations — only on final iteration.
- [x] ~~Is there risk of state file naming collisions?~~ **Answered**: No. dev-workflow uses `.plugin-state/workflow-*/` and `.plugin-state/debug/*/`, autonomous-workflow uses `.claude/autonomous-*`. Completely separate locations.
- [ ] Should there be a cost cap mechanism in autonomous-workflow beyond ralph-loop --max-iterations?
- [ ] Should research results be cached to avoid re-searching on workflow restart?
- [ ] Should autonomous-workflow be registered before ralph-loop in marketplace.json so stop-hook.sh runs before ralph-loop feeds the next prompt?
- [x] ~~Do both SessionStart hooks (dev-workflow + autonomous-workflow) conflict when both have active workflows?~~ **Answered**: YES, potential conflict. Both output independent JSON objects to stdout. No merging logic exists.
- [ ] Skill doc references `continue-auto` command but no command file exists — should it be created or the reference removed?
- [ ] Should GitHub Actions workflows (claude.yml, claude-code-review.yml) be re-enabled?

## 13. SessionStart Hook Conflict Analysis

Three plugins register SessionStart hooks with matcher `"compact|clear"`: dev-workflow, research-report, and long-horizon-impl. When multiple have active workflows:

**dev-workflow** (`auto-resume-after-compact-or-clear.sh`):
- Scans `.plugin-state/workflow-*/*-state.md` (TDD) and `.plugin-state/debug/*/*-state.md` (debug)
- Can detect both TDD and debug workflows simultaneously (concatenates with `---` separator)
- Outputs single JSON with `additionalContext` containing workflow state + Skill invocation instructions

**research-report** (`auto-resume-after-compact-or-clear.sh`):
- Scans `.plugin-state/` for active research state files
- Outputs single JSON with `additionalContext` containing state + context restoration

**long-horizon-impl** (`auto-resume-after-compact-or-clear.sh`):
- Scans `.plugin-state/` for active research/planning/implementation state files
- Outputs single JSON with `additionalContext` containing state + context restoration

**Conflict**: All hooks output independent JSON objects to stdout. No coordination mechanism. If multiple have active workflows, some hooks' context may be lost (depends on Claude Code's SessionStart handler merging behavior).

**Severity**: MEDIUM — unlikely scenario (running TDD + research/impl workflows simultaneously is uncommon), but if it occurs, some workflows lose context restoration.

## 14. File Inventory

| Category | Count | Details |
|----------|-------|---------|
| **Total Files** | 176 | Excluding .git |
| **Markdown** | 117 | Agents, commands, skills, docs |
| **Shell Scripts** | 27 | Sync (9), hooks (13), IDE (3), tests (2) |
| **JSON Configs** | 22 | Plugin (14), IDE (5), MCP (1), hooks (4) |
| **Plugins** | 10 (9 active) | dev-workflow, research-report, long-horizon-impl, ralph-loop, playwright, claude-session-feedback, infrastructure-as-code, claude-md-best-practices, notify, autonomous-workflow (deprecated) |
| **Agents** | 19 | 12 dev-workflow, 6 autonomous-workflow, 1 global |
| **Commands** | 40 | 20 dev-workflow, 5 autonomous-workflow, 3 ralph-loop, 4 claude-session-feedback, 1 infrastructure-as-code, 7 global (+ 1 research) |
| **Skills** | 9 | 6 dev-workflow, 1 autonomous-workflow, 1 playwright, 1 infrastructure-as-code |
| **VS Code Tasks** | 13 | 9 working, 4 dead/stale |
| **GitHub Workflows** | 2 | Both disabled/commented out |
| **Sync Scripts** | 2 | 1 symlink setup (claude-code: CLAUDE.md, agents/, commands/, docs/), 1 copy sync (cursor) |

## 15. Ambiguities

- **Hook execution order across plugins**: When multiple plugins register Stop hooks, the order depends on plugin load order. If one hook fails, downstream hooks may not execute.
- **Symlink dependency**: Claude Code symlinks break if the repo is moved. Re-run `setup_symlinks.sh` after moving.
- **Cursor mirror maintenance**: All adaptations baked into `cursor/` directory. Adding workflows requires creating adapted copies, not modifying sync script. Unclear if Cursor should have full parity.
- **VS Code tasks.json leftovers**: Contains tasks from previous projects (TypeScript compilation, HoPF config).
- **Debug phase 5 ownership**: No dedicated command for Phase 5 (Reproduce). User manually triggers bug.
- **State file verification scope**: 120s timeout may not suffice for complex multi-component workflows.
- **Autonomous workflow restart**: No merge/warning if `.claude/autonomous-<topic>-*` state files already exist; initialization overwrites.
- **Feature dependency graph**: feature-list.json dependencies are specified during decomposition. Cyclic or incomplete graphs may cause silent failures.
