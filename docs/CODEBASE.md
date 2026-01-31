# Personal Configs - Codebase Analysis

> Last updated: 2026-01-30
> Iteration: 3 of 3 (Final)

## 1. System Purpose & Domain

**Purpose:** AI-assisted development infrastructure repository for Claude Code workflows. Provides encapsulated plugins, configuration sync scripts, and IDE integrations for test-driven development and debugging.

**Core Domain Entities:**
- **Plugins** (6): Self-contained workflow packages with agents, commands, skills, hooks
- **Agents** (18): Specialized AI assistants with defined tools and models
- **Commands** (25+): Stateless executable markdown templates
- **Skills** (11): Auto-activating contextual guides
- **Hooks** (1): Event-driven automation (PostToolUse triggers)

**Key Insight:** This repository contains **NO application code**—only configuration (markdown, JSON, shell scripts) designed to sync with and extend Claude Code IDE.

## 2. Technology Stack

| Category | Technology | Version/Source |
|----------|------------|----------------|
| Primary Language | Markdown | 56 files |
| Scripting | Bash | 15 files |
| Automation | JavaScript/Node.js | 2 files (Playwright) |
| Configuration | JSON | 13 files |
| Browser Automation | Playwright | ^1.57.0 |
| Python Tooling | UV | Referenced in docs |
| External Services | MCP Servers | context7, fetch, exa, playwright |

**No build process, no runtime dependencies, no deployment pipeline.**

## 3. Architecture

### Pattern: Modular Plugin Architecture

```
personal_configs/
├── .claude/                    # Local Claude settings
├── .vscode/                    # VS Code integration (15 tasks)
├── scripts/                    # 13 bidirectional sync scripts
└── claude-code/
    ├── CLAUDE.md               # Global coding standards (TEMPLATE)
    ├── global_mcp_settings.json
    ├── commands/               # 6 shared global commands
    ├── docs/                   # Best practices (python, uv, docker)
    └── plugins/                # 6 encapsulated plugins
        ├── tdd-workflow/       # 7 agents, 11 commands, 4 skills
        ├── debug-workflow/     # 4 agents, 7 commands, 1 skill
        ├── playwright/         # Browser automation (JS)
        ├── claude-session-feedback/
        ├── infrastructure-as-code/
        └── claude-md-best-practices/
```

### Data Flow

```
Repository (local-plugins/)
         ↓↓ sync scripts
Global (~/.claude/)
         ↓↓ Claude Code loads
Runtime (agents, commands, skills active)
         ↑↑ reverse sync
Repository (version controlled)
```

### Plugin Architecture

Each plugin follows the structure:
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Manifest
├── agents/                   # *.md with YAML frontmatter
├── commands/                 # *.md with YAML frontmatter
├── skills/                   # SKILL.md in subdirectories
└── hooks/                    # hooks.json + scripts (optional)
```

## 4. Boundaries & Interfaces

### Agent Definition Contract
```yaml
---
name: <agent-name>
description: <auto-activation trigger>
tools: [Read, Write, Edit, Bash, Grep, Glob]
model: sonnet|opus
---
```
- **Sonnet**: Parallel read-only tasks (1M context window)
- **Opus**: Complex reasoning and code generation

### Command Definition Contract
```markdown
---
description: Human-readable purpose
model: opus|sonnet
argument-hint: <arg1> "<arg2>"
---
```
- Arguments are POSITIONAL ($1, $2), not named
- Output is markdown to context

### Hook Definition Contract
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "..."}]
    }]
  }
}
```
- Currently only tdd-workflow uses hooks
- Triggers test runner after code changes

### MCP Server Contract
```json
{
  "mcpServers": {
    "context7": {"type": "http", "url": "...", "headers": {...}},
    "fetch": {"type": "stdio", "command": "uvx", "args": [...]},
    "exa": {"command": "npx", "args": [...], "env": {...}},
    "playwright": {"command": "npx", "args": [...]}
  }
}
```

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Configuration-first | Pure markdown/JSON | Application code | No build, but limited validation |
| Plugin isolation | Self-contained dirs | Monolithic config | Easy updates, more files |
| Model selection | Sonnet for parallel, Opus for complex | Single model | Cost optimization vs simplicity |
| State preservation | Markdown state files | In-memory | Survives /clear, manual checkpoints |
| Bidirectional sync | 13 script pairs | GitOps/CI | Manual but flexible |
| Test infrastructure | Detection + execution hooks | Embedded tests | Works for any language, no self-tests |

## 6. Code Quality & Patterns

### Patterns

1. **YAML Frontmatter**: All agents, commands, skills use structured metadata
2. **Plugin Manifests**: Each plugin has `.claude-plugin/plugin.json`
3. **Bidirectional Sync**: 13 pairs of to/from scripts
4. **PostToolUse Hooks**: Auto-run tests after Write/Edit
5. **Confidence-Scored Reviews**: Only report findings ≥80% confidence
6. **Hypothesis-Driven Debug**: EXPLORE → HYPOTHESIZE → INSTRUMENT → ANALYZE → FIX

### Testing Strategy

**No traditional test files** (intentional design):
- Test infrastructure for *downstream projects*, not this repo
- `detect-test-runner.sh`: Auto-detects pytest, jest, vitest, go, cargo, rspec, mix
- `run-tests.sh`: Executes detected framework with appropriate flags
- Hook-based continuous feedback during development

### Error Handling

- Scripts use `set -e` for fail-fast
- Graceful fallbacks (exit 0 if no test framework found)
- Phase validation in TDD workflow prevents skipping steps
- Context restoration from markdown state files after /clear

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| "6 plugins" (CLAUDE.md) | 6 plugins found | `claude-code/plugins/` |
| "7 agents in tdd-workflow" | 7 agent files | `plugins/tdd-workflow/agents/*.md` |
| "ralph-loop required" | External dependency | Not in repo, install via marketplace |
| "13 sync scripts" | Actually 13 | `scripts/sync_*.sh` |
| "No application code" | Correct | Only config + 2 JS files for Playwright |

## 8. Key Workflow: TDD (Traced End-to-End)

### Workflow Entry
```
/tdd-workflow:1-start <feature-name> "<description>"
```

### Phase Sequence with Context Checkpoints
```
Phase 2: Exploration (5 parallel code-explorer agents)
    ↓
    ══════ CHECKPOINT 1: /clear + /reinitialize-context-after-clear-and-continue-workflow ══════
    ↓
Phase 3: Specification Interview (40+ questions via AskUserQuestionTool)
Phase 4: Architecture Design (code-architect agent optional)
Phase 5: Implementation Plan (creates component list)
Phase 6: Plan Review & Approval (plan-reviewer agent + user approval)
    ↓
    ══════ CHECKPOINT 2: /clear + /reinitialize-context-after-clear-and-continue-workflow ══════
    ↓
Phase 7: TDD Implementation (ralph-loop orchestrates test-designer → implementer → refactorer)
Phase 8: E2E Testing (ralph-loop orchestrates integration tests)
    ↓
    ══════ CHECKPOINT 3: /clear + /reinitialize-context-after-clear-and-continue-workflow ══════
    ↓
Phase 9: Review & Completion (5 parallel code-reviewer agents + fixes)
```

### Artifacts Flow
| Phase | Input | Output |
|-------|-------|--------|
| 2 | Codebase | `docs/context/<feature>-exploration.md` |
| 3 | Exploration | `docs/specs/<feature>.md` |
| 4 | Spec | `docs/plans/<feature>-arch.md` |
| 5 | Architecture | `docs/plans/<feature>-plan.md` |
| 7-8 | Plan | Implementation files + tests |
| 9 | Implementation | `docs/workflow/<feature>-review.md` |

### ralph-loop Cost Controls (Answered)
- **`--max-iterations` flag**: REQUIRED, explicitly set (e.g., `--max-iterations 50`)
- **`--completion-promise` flag**: Stops loop when output contains promise string
- **Safety note from CLAUDE.md**: "50 iterations = $50-100+ in API costs"
- **Orchestrator pattern**: Main instance runs ralph-loop; subagents do discrete tasks and return

### Context Checkpoint Strategy (Answered)
- **Rationale**: "Clear at 60k tokens or 30% context... automatic compaction is opaque, error-prone"
- **Timing**: After heavy read operations (Phase 2), before implementation (Phase 6→7), after E2E (Phase 8→9)
- **Mechanism**: State saved to `docs/workflow/<feature>-state.md` → user runs `/clear` → user runs `/reinitialize-context-after-clear-and-continue-workflow`
- **Validation**: reinitialize command checks prerequisites (e.g., Phase 7 requires Phases 2-6 complete)

## 9. Key Workflow: Debug (Traced End-to-End)

### Workflow Entry
```
/debug-workflow:debug "<bug description>"
```

### Phase Sequence (9 Steps)
```
1. EXPLORE → Understand relevant systems (debug-explorer agent)
2. DESCRIBE → Document bug with complete context
3. HYPOTHESIZE → Generate 3-5 ranked theories (hypothesis-generator agent)
4. INSTRUMENT → Add targeted logging (instrumenter agent)
5. REPRODUCE → Trigger bug and capture logs
6. ANALYZE → Match logs to hypotheses (log-analyzer agent)
7. FIX → Minimal changes to address root cause
8. VERIFY → Confirm fix by reproducing original scenario
9. CLEAN → Remove debug instrumentation
```

### Iron Law
> "No fixes until root cause is proven."

### Log Annotation Standard
```python
# HYPOTHESIS: H1 - <description>
# DEBUG: Remove after fix
logging.debug(f"[DEBUG-H1] variable={value}")
```

### Artifact Location
```
docs/debug/
├── bug-name-exploration.md
├── bug-name-bug.md
├── bug-name-hypotheses.md
└── archive/
```

## 10. Sync Mechanism (Traced End-to-End)

### Script Behavior: `sync_plugins_to_global.sh`
1. Validates source directory exists (`claude-code/plugins/`)
2. Creates destination if needed (`~/.claude/plugins/`)
3. **Selective delete**: Only removes plugins that exist in repo (protects unrelated plugins)
4. Copies each plugin directory
5. Copies marketplace manifest (`.claude-plugin/marketplace.json`)

### Sync Script Pairs
| Component | To Global | From Global |
|-----------|-----------|-------------|
| Plugins | `sync_plugins_to_global.sh` | `sync_plugins_from_global.sh` |
| Commands | `sync_commands_to_global.sh` | `sync_commands_from_global.sh` |
| Skills | `sync_skills_to_global.sh` | `sync_skills_from_global.sh` |
| Docs | `sync_docs_to_global.sh` | `sync_docs_from_global.sh` |
| CLAUDE.md | `sync_claude_to_global.sh` | `sync_claude_from_global.sh` |
| MCP | `sync_mcp_servers_to_global.sh` | `sync_mcp_servers_from_global.sh` |

### Loading Plugins After Sync
```bash
# Option 1: Load specific plugin
claude --plugin-dir ~/.claude/plugins/tdd-workflow

# Option 2: Add local marketplace
/plugin marketplace add ~/.claude/plugins
```

## 11. MCP Server Configuration (Detailed)

### Configured Servers
| Server | Type | Command | Purpose |
|--------|------|---------|---------|
| context7 | HTTP | N/A (HTTP endpoint) | Documentation retrieval |
| fetch | stdio | `uvx mcp-server-fetch` | URL content fetching |
| exa | npx | `exa-mcp-server` | Web search + code context |
| playwright | npx | `@playwright/mcp@latest` | Browser automation |

### Environment Variables Required
```bash
CONTEXT7_API_KEY  # For context7 HTTP server
EXA_API_KEY       # For exa web search
```

### Token Cost Warning
> "Single MCP server with 20 tools = ~14,000 tokens; disable unused servers before heavy work"
— CLAUDE.md

## 12. Skill Discovery

### How Users Find Skills
1. **`/tdd-workflow:help`** - Lists all tdd-workflow commands
2. **`/debug-workflow:help`** - Lists all debug-workflow commands
3. **System-reminder** - Skills automatically listed in context when available
4. **Auto-activation** - Skills activate when description keywords match context

### Skill Inventory
| Plugin | Skills | Activation Trigger |
|--------|--------|-------------------|
| tdd-workflow | tdd-guide | "writing tests", "TDD" |
| tdd-workflow | tdd-workflow-guide | "TDD workflow", "phases" |
| tdd-workflow | writing-plans | "implementation plan", "multi-step task" |
| tdd-workflow | using-git-worktrees | "feature work", "isolation" |
| debug-workflow | structured-debug | "debugging", "bug" |
| infrastructure-as-code | infrastructure-as-code | "Terraform", "AWS" |
| claude-md-best-practices | writing-claude-md | "CLAUDE.md", "project instructions" |
| playwright | playwright | "browser automation", "E2E" |

## 13. Open Questions (Remaining)

- [x] ~~How are ralph-loop iterations managed?~~ → `--max-iterations` flag required
- [x] ~~How do context checkpoints interact with compaction?~~ → Manual /clear before compaction
- [x] ~~When should checkpoints happen?~~ → After Phases 2, 6, 8
- [x] ~~How do users discover skills/commands?~~ → `/help` commands + auto-activation
- [ ] Why is there no CI/CD pipeline for validating plugin manifests?
- [ ] What happens when multiple plugins define conflicting hooks?
- [ ] Are there plans to publish plugins to a public marketplace?
- [ ] Why aren't the sync scripts themselves tested?
- [ ] What's the strategy for versioning plugins independently?

## 14. Ambiguities (Remaining)

1. **Plugin Loading Order**: Unclear if plugins have priority/ordering when conflicts occur
2. **MCP Server Limits**: "20 tools = ~14,000 tokens" but no hard limit guidance
3. **State File Schema**: No versioning or migration strategy documented
4. **ralph-loop Installation**: Requires external installation: `/plugin marketplace add anthropics/claude-code && /plugin install ralph-wiggum`

## 15. Architecture Decisions Summary

| Decision | Rationale | Source |
|----------|-----------|--------|
| Orchestrator owns feedback loop | Subagents don't accumulate token debt; main instance validates | TDD workflow README |
| Sonnet for parallel, Opus for complex | Cost optimization for read-only tasks vs quality for reasoning | Agent definitions |
| 3 context checkpoints | "Automatic compaction is opaque, error-prone" | Community best practices |
| State files in markdown | Survives /clear, human-readable, version controlled | Workflow design |
| Real APIs over mocks | "Only mock when integration is truly impossible" | CLAUDE.md |
| Confidence threshold ≥80% | Eliminates noise in code reviews | code-reviewer agent |
| Hypothesis-driven debugging | "No fixes until root cause is proven" | Debug workflow README |

## 16. Credits & Sources

Based on practices from:
- **Boris Cherny** (Anthropic): Parallel exploration, Opus for reasoning, shared CLAUDE.md
- **Thariq Shihab** (Anthropic): Interview-first spec development, fresh sessions
- **Mo Bitar**: Interrogation method, pushback on idealistic ideas
- **Geoffrey Huntley**: Ralph Wiggum autonomous loops
- **Cursor Debug Mode**: Hypothesis-driven debugging methodology

---

## Appendix: File Statistics

| Type | Count | Location |
|------|-------|----------|
| Markdown | 56 | Throughout |
| Shell scripts | 15 | `scripts/`, `hooks/` |
| JSON configs | 13 | `.claude-plugin/`, `.vscode/` |
| JavaScript | 2 | `plugins/playwright/` |
| Total | ~90 | - |

## Appendix: Plugin Summary

| Plugin | Agents | Commands | Skills | Hooks | Purpose |
|--------|--------|----------|--------|-------|---------|
| tdd-workflow | 7 | 11 | 4 | 1 | 8-phase TDD with parallel agents |
| debug-workflow | 4 | 7 | 1 | 0 | Hypothesis-driven debugging |
| playwright | 0 | 0 | 1 | 0 | Browser automation |
| claude-session-feedback | 0 | 3 | 0 | 0 | Export/feedback tools |
| infrastructure-as-code | 0 | 1 | 1 | 0 | Terraform/AWS management |
| claude-md-best-practices | 0 | 0 | 1 | 0 | Documentation standards |
