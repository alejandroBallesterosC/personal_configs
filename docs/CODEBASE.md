# Personal Configs - Codebase Analysis

> Last updated: 2026-02-28
> Iteration: 3 of 3 (refresh cycle)

## 1. System Purpose & Domain

Development infrastructure repository for AI-assisted workflows with Claude Code and Cursor IDE. Contains no application code — only Markdown (commands, agents, skills, docs), JSON (configs, manifests), and Shell scripts (hooks, sync). The core domain is **orchestrated TDD implementation, hypothesis-driven debugging, and autonomous multi-phase research/planning/implementation** via a plugin-based architecture.

**Core domain entities:**
- **Plugins** (7): Self-contained packages of commands, agents, skills, hooks
- **Workflows**: TDD Implementation (8 phases), Debug (9 phases), Autonomous (3 phases: Research/Planning/Implementation with 4 modes)
- **State files**: YAML frontmatter + markdown body tracking workflow progress
- **Hooks**: Event-driven automation (Stop, SessionStart, PreCompact) for context preservation
- **Sync scripts**: Bidirectional config sync between repo and `~/.claude/`

## 2. Technology Stack

| Layer | Technology | Version/Source |
|-------|-----------|----------------|
| Runtime | Claude Code CLI | Anthropic (external) |
| Plugins | Claude Code Plugin System | plugin.json manifests |
| Content | Markdown (113 files) | YAML frontmatter conventions |
| Scripts | Bash (26 files) | POSIX-compatible |
| Config | JSON (22 files) | Plugin manifests, hooks, MCP |
| Browser automation | Playwright (JS) | package.json in skill (v1.57.0) |
| IDE mirror | Cursor IDE | Unidirectional sync |
| MCP servers | context7 (HTTP), fetch (stdio), exa (npx), playwright (npx) | global_mcp_settings.json |
| Dependencies | yq, jq (hooks), ralph-loop plugin (TDD/autonomous), MacTeX (optional, LaTeX PDF) | brew install |

## 3. Architecture

### Pattern: Plugin-Based Configuration Infrastructure

```
personal_configs/
├── claude-code/                    # Primary source of truth
│   ├── plugins/ (7 plugins)       # Encapsulated workflow packages
│   │   ├── dev-workflow/          # 12 agents, 18 commands, 6 skills, 4 hooks
│   │   ├── autonomous-workflow/   # 6 agents, 6 commands, 1 skill, 3 hooks
│   │   ├── ralph-loop/           # 3 commands, 1 hook (iterative loops)
│   │   ├── playwright/           # 1 skill (browser automation, JS)
│   │   ├── claude-session-feedback/ # 4 commands
│   │   ├── infrastructure-as-code/  # 1 command, 1 skill
│   │   └── claude-md-best-practices/ # 1 skill
│   ├── commands/ (6)             # Global commands (synced to ~/.claude/commands/)
│   ├── docs/ (3)                 # Best practice guides (synced to ~/.claude/docs/)
│   ├── CLAUDE.md                 # Template (synced to ~/.claude/CLAUDE.md)
│   └── global_mcp_settings.json  # MCP config (synced to ~/.claude.json)
├── cursor/                        # Cursor IDE mirror (TDD-only, unidirectional)
├── sync-content-scripts/          # 9 sync scripts (8 bidirectional + 1 unidirectional)
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
    │   └── 7 installed plugins
    │
    └──[sync_to_cursor.sh]──► ~/.cursor/ (IDE config)
        ├── commands/*.md (no YAML frontmatter)
        ├── hooks/ (camelCase events, version:1)
        └── skills/
```

### Hook Architecture

Plugin execution order follows marketplace.json registration order:
1. dev-workflow, 2. playwright, 3. claude-session-feedback, 4. infrastructure-as-code, 5. ralph-loop, 6. claude-md-best-practices, 7. autonomous-workflow

```
Stop Event (on Claude exit attempt) — sequential, order matters
├── 1. dev-workflow:
│   ├── archive-completed-workflows.sh   # Move status:complete to docs/archive/
│   ├── run-scoped-tests.sh              # Run tests per .tdd-test-scope file
│   └── State verification agent          # Block exit if state file outdated (120s)
├── 5. ralph-loop:
│   └── stop-hook.sh                     # Block exit + feed prompt back (loop)
└── 7. autonomous-workflow:
    └── verify-state.sh                  # Block exit if state inconsistent with artifacts

SessionStart Event (after compact|clear) — sequential
├── 1. dev-workflow:
│   └── auto-resume-after-compact-or-clear.sh  # Inject TDD/debug context
└── 7. autonomous-workflow:
    └── auto-resume.sh                         # Inject research/planning/impl context

PreCompact Event (before context compaction)
└── 7. autonomous-workflow:
    └── auto-checkpoint.sh                     # Save transcript + state snapshot
```

**Ordering implication**: ralph-loop (5th) runs BEFORE autonomous-workflow (7th) in Stop chain. If ralph-loop blocks (feeds prompt back for next iteration), autonomous-workflow's verify-state.sh may not execute, meaning state file consistency is not verified between iterations.

## 4. Boundaries & Interfaces

### Plugin Interface Contract
Each plugin is self-contained in `.claude-plugin/plugin.json`:
- **Commands**: YAML frontmatter (`description`, `model`, `argument-hint`) + markdown body
- **Agents**: YAML frontmatter (`name`, `description`, `tools[]`, `model`) + system prompt
- **Skills**: YAML frontmatter (`name`, `description` for activation) + SKILL.md content
- **Hooks**: `hooks.json` registering event handlers (command scripts or agent prompts)

**Coupling**: Plugins are loosely coupled. dev-workflow depends on ralph-loop (hard, Phases 7-9) and optionally playwright (E2E). autonomous-workflow depends on ralph-loop (hard, iteration loop) and optionally exa MCP (deep research) and MacTeX (PDF output). claude-md-best-practices is a soft dependency (skill invocation).

### Hook Interface Contract
- **Command hooks**: Shell scripts returning exit code 0 (success) or 1 (failure/block)
- **Agent hooks**: Return JSON `{"ok": true}` or `{"ok": false, "reason": "..."}`
- **Stop hooks can block**: Returning failure prevents Claude from exiting
- **SessionStart hooks inject context**: Return JSON with `additionalContext` field
- **PreCompact hooks**: Save state before context compaction (autonomous-workflow only)

### Sync Interface Contract
- **Direction**: Bidirectional (to/from global) for Claude Code; unidirectional (to) for Cursor
- **Behavior**: `cp -f` (last sync wins), optional `--overwrite` clears destination first
- **Plugins do NOT sync**: Installed via marketplace (`/plugin marketplace add` + `/plugin install`)

### State File Contract
- **TDD state**: `docs/workflow-<name>/<name>-state.md` — YAML frontmatter (`workflow_type`, `name`, `status`, `current_phase`)
- **Debug state**: `docs/debug/<name>/<name>-state.md` — Same format + `fix_attempts`, `max_fix_attempts`
- **Autonomous research state**: `docs/autonomous/<topic>/research/<topic>-state.md` — YAML with `current_research_strategy`, `research_budget`, iteration tracking
- **Autonomous implementation state**: `docs/autonomous/<topic>/implementation/<topic>-state.md` — YAML with `planning_budget`, `features_total/complete/failed`
- **Lifecycle**: Created at workflow start → updated per phase → verified on Stop → archived on completion
- **Guard**: Only one active workflow per type (enforced by start commands)

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Plugin encapsulation | Self-contained dirs with manifests | Flat global commands | Isolation + marketplace distribution vs. more complex installation |
| YAML frontmatter state | Markdown files with YAML headers | JSON/SQLite state | Human-readable + git-friendly vs. no structured querying; requires yq |
| Hook-based verification | Stop hook agent verifies state | Trust Claude to update state | Deterministic correctness vs. 120s timeout on every exit |
| Bidirectional sync | cp -f with overwrite flag | Git submodules or symlinks | Simplicity vs. last-sync-wins can lose changes |
| Cursor mirror | Separate adapted copy | Shared source with adapters | Simpler sync script vs. files to maintain in parallel |
| ralph-loop as external dep | Plugin marketplace install | Built-in to dev-workflow | Separation of concerns vs. extra install step |
| yq for YAML parsing | Shell + yq | Python yaml module | Simpler scripts vs. hard dependency on yq binary |
| Subagent data isolation | Sonnet absorbs raw web data, Opus gets summaries | Main instance does all research | Prevents context bloat in long-running workflows |
| Budget-based phase transitions | Iteration count triggers transition | Contribution-based / quality heuristics | Predictable timing vs. may transition when still productive |
| Artifact-first memory | .tex/.md files are canonical state | Conversation history | Survives context compaction vs. requires disciplined file updates |
| No auto-termination from research | ralph-loop --max-iterations stops | Contribution-based auto-stop | Always explores fully vs. may waste iterations |

## 6. Code Quality & Patterns

### Conventions Enforced
1. **ABOUTME comments**: All code files start with 2-line `# ABOUTME:` comments (36+ occurrences)
2. **YAML frontmatter**: Commands, agents, skills all use structured YAML headers
3. **Loud dependency failures**: Hook scripts check for yq/jq and exit 1 with install instructions
4. **State file format**: Consistent YAML frontmatter across TDD, debug, and autonomous workflows
5. **Guard clauses**: Single active workflow enforcement in start commands
6. **Strategy rotation**: 8 research strategies with contribution-based rotation (autonomous-workflow)

### Shell Script Quality
- 26 scripts, majority with `set -e` (error exit on failure)
- Proper quoting, `git rev-parse --show-toplevel` for repo root detection
- Defensive file existence checks before operations
- Non-fatal exits (exit 0) for optional features (no test runner = not an error)

### Test Runner Support
9 frameworks auto-detected by `detect-test-runner.sh`:
pytest, vitest, jest, playwright, go test, cargo test, rspec, minitest, mix

### No Linting/Formatting Config
By design — repo contains only Markdown, JSON, and Bash (no application code to lint).

## 7. Plugin Details

### dev-workflow (v1.0.0) — TDD Implementation + Debug

**Components**: 12 agents, 18 commands, 6 skills, 4 hooks (Stop×3, SessionStart×1)

**TDD Phases** (8):
| Phase | Command | Agents | Gate |
|-------|---------|--------|------|
| Init | `1-start-tdd-implementation` | None | ralph-loop check |
| 2: Explore | `2-explore` | 5× code-explorer (Sonnet, parallel) | User confirmation |
| 3: Interview | `3-user-specification-interview` | None (Opus) | 40+ questions |
| 4: Architecture | `4-plan-architecture` | code-architect (Opus) | None |
| 5: Plan | `5-plan-implementation` | None (Opus) | None |
| 6: Review | `6-review-plan` | plan-reviewer (Opus) | User approval |
| 7: Implement | `7-implement` | ralph-loop → test-designer, implementer, refactorer | Per-component |
| 8: E2E | `8-e2e-test` | ralph-loop → test-designer, implementer | All tests green |
| 9: Review | `9-review` | 5× code-reviewer (Sonnet, parallel) | Fix criticals |

**Debug Phases** (9): Hypothesis-driven with loopback flows. 3-fix rule (after 3 failed fixes, question architecture).

**Key patterns**:
- Foundation-first: shared types/interfaces before parallel component implementation
- `.tdd-test-scope` file: one-shot test scope consumed by Stop hook
- Phase 6 is only phase requiring explicit user approval

### autonomous-workflow (v1.2.0) — Research/Planning/Implementation

**Components**: 6 agents, 6 commands, 1 skill, 3 hooks (PreCompact, SessionStart, Stop)

**4 Modes**:
| Mode | Command | Phases | Termination |
|------|---------|--------|-------------|
| 1: Research | `/research` | A only | ralph-loop stops |
| 2: Research+Plan | `/research-and-plan` | A→B | ralph-loop stops |
| 3: Full Auto | `/full-auto` | A→B→C | WORKFLOW_COMPLETE |
| 4: Implement | `/implement` | C only | WORKFLOW_COMPLETE |
| - | `/continue-auto` | Auto-detect | Resumes any |

**8 Research Strategies** (rotate on low contribution):
wide-exploration → source-verification → contradiction-resolution → deep-dive → adversarial-challenge → gaps-and-blind-spots → temporal-analysis → cross-domain-synthesis

**Agents**:
| Agent | Model | Phase | Role |
|-------|-------|-------|------|
| researcher | Sonnet | A | 3-5 parallel internet research agents |
| repo-analyst | Sonnet | A | 0-2 parallel codebase analysis |
| latex-compiler | Sonnet | Boundaries | LaTeX → PDF compilation |
| plan-architect | Opus | B | 2× parallel plan improvement |
| plan-critic | Opus | B, Mode 4 | 2× parallel plan scrutiny |
| autonomous-coder | Opus | C | Full TDD cycle per feature |

**Artifacts**: `docs/autonomous/<topic>/research/` (.tex, .bib, state) + `docs/autonomous/<topic>/implementation/` (plan.md, feature-list.json, progress.txt, state)

**Budget system**: research_budget (default 30) and planning_budget (default 15) control phase transitions. Only Phase C has natural completion (all features resolved).

**Cost estimates**: ~$0.50-$3.00 per iteration; 50 iterations ≈ $25-$150.

### ralph-loop (v1.0.0) — Iterative Loop Engine

**Components**: 3 commands, 1 hook (Stop)

**Role**: Provides the iteration loop for both dev-workflow (Phases 7-9) and autonomous-workflow (all modes). Calls command once per iteration, checks for `<promise>WORKFLOW_COMPLETE</promise>` signal.

**Safety**: Always set `--max-iterations` (50 iterations = $50-100+ in API costs).

### Other Plugins

- **playwright** (skill v4.1.0): Browser automation via Playwright JS skill
- **claude-session-feedback** (v1.0.0): 4 commands for conversation export/feedback
- **infrastructure-as-code** (v1.0.0): 1 command + 1 skill for Terraform/AWS
- **claude-md-best-practices** (v1.0.0): 1 skill for CLAUDE.md writing guidance

## 8. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| CLAUDE.md says "6 plugins" | Now 7 plugins (autonomous-workflow added) | `CLAUDE.md:1,3` |
| CLAUDE.md architecture shows 6 plugins | Missing autonomous-workflow | `CLAUDE.md:7-21` |
| README.md references 6 plugins | Should be 7 | `README.md` |
| VS Code tasks.json lists "Sync Skills" and "Sync Plugins" tasks | No corresponding sync scripts exist | `.vscode/tasks.json` |
| CLAUDE.md says "8 bidirectional + 1 unidirectional sync scripts" | Correct count | `sync-content-scripts/` |

## 9. Cursor Mirror Drift Analysis

The Cursor mirror at `cursor/` has **significant drift** from the Claude Code source:

### Missing from Cursor (entire debug + autonomous workflows)
- **6 debug commands**: `1-start-debug`, `1-explore-debug`, `3-hypothesize`, `4-instrument`, `6-analyze`, `8-verify`
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
- "Sync Claude Code Skills to/from Global" → scripts removed (plugin system replaced)
- "Sync Claude Code Plugins to/from Global" → scripts removed (plugin system replaced)

Also has leftover tasks: "Compile Frontend Typescript" and "HoPF config file" input from a previous project.

## 11. Hook Execution Analysis (Iteration 2 Deep Dive)

### Stop Hook Chain (corrected order per marketplace.json)

```
1. dev-workflow: archive-completed-workflows.sh   → always exits 0
2. dev-workflow: run-scoped-tests.sh              → exits 0 or 1+
   IF exit 1+: CHAIN MAY HALT (subsequent hooks may not run)
3. dev-workflow: State verification agent          → {ok:true/false}, 120s timeout
4. ralph-loop: stop-hook.sh                       → exits 0 or blocks with JSON
   IF active loop: blocks stop, feeds prompt back → steps 5+ never run
5. autonomous-workflow: verify-state.sh           → exits 0 or blocks with JSON
```

**Risk 1**: If tests fail (step 2 exits nonzero), steps 3-5 may never execute.
**Risk 2**: If ralph-loop blocks (step 4 feeds prompt back), autonomous-workflow verify-state never runs. State file consistency is not verified between ralph-loop iterations.
**Risk 3**: On final ralph-loop iteration (WORKFLOW_COMPLETE detected or max reached), ralph-loop allows stop (exit 0) and autonomous-workflow verify-state finally runs.

### Ralph-Loop Integration Mechanism

Ralph-loop provides iteration control via Stop hook blocking + prompt injection:

1. `setup-ralph-loop.sh` creates `.claude/ralph-loop.local.md` state file with YAML frontmatter (`iteration`, `max_iterations`, `completion_promise`) and prompt body
2. On Stop event, `stop-hook.sh` reads state file, extracts last assistant message from transcript
3. Checks for `<promise>TEXT</promise>` XML tags via Perl regex; literal string match against `completion_promise`
4. If match found → deletes state file → exits 0 (allows stop, loop ends)
5. If no match → increments iteration counter atomically (temp file + mv) → outputs JSON `{decision: "block", reason: "<prompt>"}` → Claude receives prompt as next iteration input
6. If `iteration >= max_iterations` → deletes state file → exits 0 (allows stop, budget exhausted)

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
- **ralph-loop**: `reason` = the prompt to re-execute; `systemMessage` = iteration count + promise reminder
- **autonomous-workflow**: `reason` = what's wrong (stale state/missing artifact); `systemMessage` = what to fix
- **dev-workflow agent**: Returns `{ok: true/false, reason: "..."}` (different format)

### Shell Script Dependencies

| Script | Hard Deps | Failure Mode |
|--------|-----------|--------------|
| archive-completed-workflows.sh | yq | Exit 1 if yq missing |
| run-scoped-tests.sh | (none) | Exit 0 if no runner found |
| auto-resume-after-compact-or-clear.sh | yq, jq | Exit 1 if missing |
| auto-checkpoint.sh | jq | Exit 0 if no active workflow |
| auto-resume.sh | jq | Exit 0 if no active workflow |
| verify-state.sh | jq | Exit 0 if no active workflow |
| ralph-loop stop-hook.sh | (none) | Exit 0 on parse failure |
| detect-test-runner.sh | (none) | Always exits 0 |

## 12. Open Questions

- [ ] Should CLAUDE.md and README.md be updated to reflect 7 plugins (autonomous-workflow)?
- [ ] Should the Cursor mirror be updated to include the debug workflow?
- [ ] Should dead VS Code tasks be removed?
- [ ] Is the 120s timeout for the Stop hook state verification agent sufficient for large workflows?
- [ ] Should `detect-test-runner.sh` support additional frameworks (e.g., PHPUnit, dotnet test)?
- [x] ~~How do multiple Stop hooks interact across plugins when one fails?~~ **Answered**: Sequential execution per marketplace.json order. If hook exits nonzero or blocks, downstream hooks may not run.
- [x] ~~Should autonomous-workflow verify-state.sh run before or after ralph-loop?~~ **Answered**: Currently runs AFTER ralph-loop (marketplace order: dev-workflow→ralph-loop→autonomous-workflow). This means verify-state doesn't run between ralph-loop iterations — only on final iteration when ralph-loop allows stop. Moving autonomous-workflow before ralph-loop in marketplace.json would fix this.
- [x] ~~Is there risk of state file naming collisions?~~ **Answered**: No. dev-workflow uses `docs/workflow-*/` and `docs/debug/*/`, autonomous-workflow uses `docs/autonomous/*/`. Completely separate directory hierarchies.
- [ ] Should there be a cost cap mechanism in autonomous-workflow beyond ralph-loop --max-iterations?
- [ ] Should research results be cached to avoid re-searching on workflow restart?
- [ ] Should autonomous-workflow be registered before ralph-loop in marketplace.json so verify-state.sh runs before ralph-loop feeds the next prompt?
- [x] ~~Do both SessionStart hooks (dev-workflow + autonomous-workflow) conflict when both have active workflows?~~ **Answered**: YES, potential conflict. Both output identical JSON structure `{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: "..."}}` independently. When both have active workflows, two separate JSON objects hit stdout sequentially. Behavior depends on Claude Code's hook handler (likely last-write-wins or only first parsed). No merging logic exists.

## 13. SessionStart Hook Conflict Analysis (Iteration 3)

Both dev-workflow and autonomous-workflow register SessionStart hooks with matcher `"compact|clear"`. When both have active workflows:

**dev-workflow** (`auto-resume-after-compact-or-clear.sh`, 184 lines):
- Scans `docs/workflow-*/*-state.md` (TDD) and `docs/debug/*/*-state.md` (debug)
- Can detect both TDD and debug workflows simultaneously (concatenates with `---` separator)
- Outputs single JSON with `additionalContext` containing workflow state + Skill invocation instructions

**autonomous-workflow** (`auto-resume.sh`, 128 lines):
- Scans `docs/autonomous/*/research/*-state.md` and `docs/autonomous/*/implementation/*-state.md`
- Outputs single JSON with `additionalContext` containing state + context restoration file list

**Conflict**: Both hooks output independent JSON objects to stdout. No coordination mechanism. If both have active workflows, one hook's context may be lost (depends on Claude Code's SessionStart handler merging behavior).

**Severity**: MEDIUM — unlikely scenario (running TDD + autonomous workflows simultaneously is uncommon), but if it occurs, one workflow loses context restoration.

## 14. Changes Since 2026-02-23

### New Plugin
- **autonomous-workflow** (v1.2.0): 6 agents, 6 commands, 1 skill, 3 hooks
  - 4 execution modes (research, research+plan, full-auto, implement)
  - 8 research strategy rotation system
  - Budget-based phase transitions
  - LaTeX report output with BibTeX bibliography
  - Feature-list.json for TDD implementation tracking
  - PreCompact hook for transcript/state checkpointing

### Updated Counts
| Component | Previous (Feb 23) | Current (Feb 28) |
|-----------|-------------------|-------------------|
| Total files | 152 | 175 |
| Plugins | 6 | 7 (+autonomous-workflow) |
| Markdown files | 96 | 113 |
| Shell scripts | 23 | 26 |
| JSON files | 20 | 22 |
| Hook events used | Stop, SessionStart | Stop, SessionStart, PreCompact |

## 14. Ambiguities

- **Hook execution order across plugins**: When multiple plugins register Stop hooks, the order depends on plugin load order. If one hook fails, downstream hooks may not execute.
- **Sync conflict resolution**: Bidirectional sync with last-sync-wins behavior has no merge strategy. Independent edits on both sides silently overwrite.
- **Cursor mirror maintenance**: All adaptations baked into `cursor/` directory. Adding workflows requires creating adapted copies, not modifying sync script. Unclear if Cursor should have full parity.
- **VS Code tasks.json leftovers**: Contains tasks from previous projects (TypeScript compilation, HoPF config).
- **Debug phase 5 ownership**: No dedicated command for Phase 5 (Reproduce). User manually triggers bug.
- **State file verification scope**: 120s timeout may not suffice for complex multi-component workflows.
- **Autonomous workflow restart**: No merge/warning if `docs/autonomous/<topic>/` already exists; initialization overwrites.
- **Feature dependency graph**: feature-list.json dependencies are specified during decomposition. Cyclic or incomplete graphs may cause silent failures.
