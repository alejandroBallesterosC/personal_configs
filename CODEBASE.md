# personal_configs - Codebase Analysis

> Last updated: 2026-01-19
> Iteration: 3 of 3 (Final)

## 1. System Purpose & Domain

**Core Purpose**: A personal development configurations repository that centralizes and synchronizes IDE configurations, AI assistant (Claude Code) custom commands, MCP server configurations, plugins, and development workflow tools across multiple projects and environments.

**Problem Solved**: Manages the complexity of maintaining consistent development tooling configurations across:
- Claude Code AI assistant customizations
- Cursor IDE configurations
- VS Code configurations
- MCP (Model Context Protocol) server setups

**Domain Entities**:
- **Commands**: Markdown-based prompts for Claude Code (e.g., `/commit`, `/understand-repo`)
- **Plugins**: Structured Claude Code extensions with agents, commands, hooks, and skills
- **Skills**: Reusable Claude Code skills (e.g., CLAUDE.md writing guide, TDD guidance)
- **MCP Servers**: External service integrations (Context7, Exa, Playwright, Puppeteer, Notion)
- **Sync Scripts**: Shell scripts to bidirectionally sync configs between this repo and `~/.claude/`

## 2. Technology Stack

**Languages**:
- Shell/Bash (scripts) - primary automation
- Markdown (commands, docs, skills)
- JSON (configurations)
- Python (embedded in sync_mcp_servers scripts for JSON manipulation)

**Tooling**:
- Claude Code CLI (AI assistant being configured)
- VS Code / Cursor IDEs
- uv (Python package manager, referenced in docs)
- git for version control

**External Services (via MCP)**:
- Context7 (documentation lookup) - `global_mcp_settings.json:3-8`
- Exa (web search, code context) - `global_mcp_settings.json:23-31`
- Playwright (browser automation) - `global_mcp_settings.json:39-42`
- Puppeteer (browser automation) - `global_mcp_settings.json:14-18`
- Notion (workspace integration) - `.cursor/mcp.json:3-6`
- Fetch (HTTP requests) - `global_mcp_settings.json:10-13`

## 3. Architecture

**Pattern**: Configuration Distribution Hub (spoke model)

```
                    ┌─────────────────────┐
                    │   personal_configs  │
                    │      (this repo)    │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  ~/.claude/   │   │   .cursor/    │   │   .vscode/    │
│   (global)    │   │   (IDE cfg)   │   │   (IDE cfg)   │
└───────────────┘   └───────────────┘   └───────────────┘
        │
        ├── commands/    (synced from claude-code/commands/)
        ├── docs/        (synced from claude-code/docs/)
        ├── plugins/     (synced from claude-code/plugins/)
        ├── skills/      (synced from claude-code/skills/)
        └── CLAUDE.md    (synced from claude-code/CLAUDE.md)
```

**Data Flow**:
1. User edits configs in this repo (version controlled)
2. Sync scripts copy to/from `~/.claude/` global config
3. MCP sync script resolves `${VAR}` references using `.env` file
4. Claude Code reads from `~/.claude/` at runtime
5. IDEs read from `.cursor/` and `.vscode/` directories

**Key Directories**:
| Directory | Purpose |
|-----------|---------|
| `claude-code/commands/` | Slash commands for Claude Code |
| `claude-code/docs/` | Reference documentation (Python, uv, Docker) |
| `claude-code/plugins/` | Full plugins with agents/hooks/skills |
| `claude-code/skills/` | Standalone skills |
| `scripts/` | Bidirectional sync scripts |
| `.cursor/` | Cursor IDE MCP configs |
| `.vscode/` | VS Code tasks and keybindings |

## 4. Boundaries & Interfaces

### Sync Script Interface
All sync scripts follow the same pattern:
- Source path: `$(dirname "$0")/../claude-code/<type>/`
- Destination path: `$HOME/.claude/<type>/`
- Support `--overwrite` flag for clean sync
- File: `scripts/sync_commands_to_global.sh:1-35`

### MCP Sync Interface (Special)
- Merges MCP configs into `~/.claude.json` (not just copy)
- Resolves `${VAR}` references from `.env` file
- Uses embedded Python for JSON manipulation
- File: `scripts/sync_mcp_servers_to_global.sh:1-160`

### Command Interface
Commands are plain markdown files invoked via `/command-name`:
- Location: `claude-code/commands/*.md`
- Format: Markdown with optional YAML frontmatter (`description`, `model`)
- Example: `claude-code/commands/commit.md` - concise commit message generation

### Plugin Interface
Plugins follow Claude Code plugin structure:
- `.claude-plugin/plugin.json` - metadata (name, description, version, author)
- `agents/` - specialized agent prompts with frontmatter (name, description, tools, model)
- `commands/` - plugin-specific commands with frontmatter
- `hooks/hooks.json` - event-triggered actions (PostToolUse, etc.)
- `skills/` - reusable skills with SKILL.md
- `scripts/` - helper scripts for the plugin
- Example: `claude-code/plugins/tdd-workflow/`

### Skill Interface
Skills are SKILL.md files in named directories:
- Path: `skills/<skill-name>/SKILL.md`
- Frontmatter: `name`, `description`
- Content: Detailed guidance/rules
- Example: `claude-code/skills/claude-md-guide/SKILL.md`

### VS Code Tasks Interface
- File: `.vscode/tasks.json`
- Provides 15 tasks including sync operations
- Exposes sync scripts via VS Code task runner
- Keybinding: Cmd+Shift+B for compile/run

## 5. Key Design Decisions & Tradeoffs

| Decision | Chosen | Alternative | Tradeoff |
|----------|--------|-------------|----------|
| Bidirectional sync | Shell scripts | Symlinks | More control, but requires manual sync vs automatic updates |
| Version control configs | Git repo | Dotfiles manager (stow, chezmoi) | Simpler approach, but no automatic linking |
| Command format | Plain markdown | Structured YAML/JSON | Human-readable, but less machine-parseable |
| Plugin storage | Copied to ~/.claude | Plugin marketplace only | Works offline, but manual updates |
| TDD workflow via plugin | Custom plugin | Built-in commands | Full control over agents/hooks, but requires ralph-loop dependency |
| API keys in .env | Resolved at sync time | Stored directly in config | Security (not committed), but requires .env setup |

**Notable Design Choices**:
1. **No symlinks**: Files are copied, not linked - enables clean overwrites
2. **Markdown-first**: Commands and docs are plain markdown for readability
3. **Separate IDE configs**: .cursor and .vscode configs are not synced (IDE-specific)
4. **Hooks for TDD feedback**: PostToolUse hooks run tests after Write/Edit operations
5. **Local plugin marketplace**: Uses `.claude-plugin/marketplace.json` to register local plugins

## 6. Code Quality & Patterns

**Recurring Patterns**:
- All shell scripts start with `#!/bin/bash` and `set -e`
- Scripts use `ABOUTME:` comment convention (per `CLAUDE.md:8`)
- Consistent directory structure across sync scripts
- Agent prompts use Arrange-Act-Assert test structure
- Graceful degradation (test runners exit 0 on missing tools)

**Configuration Management**:
- `CLAUDE.md` defines coding standards (TDD, no mocks, evergreen naming)
- Docs reference files in `~/.claude/docs/` (Python, uv, Docker guidelines)

**Error Handling**:
- Scripts check for directory existence before operations
- `set -e` stops on first error
- Test runner scripts exit 0 on missing runners (graceful degradation)
- MCP sync warns but continues if .env is missing

**TDD Workflow Pattern** (from `workflow_plan.md`):
1. Interview-first planning (40+ questions via AskUserQuestionTool)
2. Spec persistence to `docs/specs/` and `docs/plans/`
3. Strict RED-GREEN-REFACTOR phases with separate agents
4. Ralph-loop for autonomous iteration
5. Confidence-scored code review

## 7. Documentation Accuracy Audit

| Doc Claim | Reality | File Reference |
|-----------|---------|----------------|
| README shows simple structure | Actually includes plugins/, skills/ not shown | `README.md:7-20` vs actual structure |
| README mentions 4 sync scripts | Actually 12+ sync scripts exist | `README.md:64-67` vs `scripts/` directory |
| Commands list in README | Missing many commands (readonly, export-conversation, etc.) | `README.md:47-53` |
| README says copy commands to ~/.claude/commands | Also has plugins and skills | `README.md:55` |

## 8. Open Questions

- [x] ~~What is the `workflow_plan.md` file for?~~ → Design document synthesizing TDD workflow best practices
- [x] ~~How do hooks in the tdd-workflow plugin get triggered?~~ → Via `hooks.json` PostToolUse matcher on Write|Edit
- [x] ~~How does the maintain-docs.mdc rule work in Cursor?~~ → Cursor-specific rule format with globs
- [x] ~~How are the plugins activated/loaded in Claude Code?~~ → Via `~/.claude/settings.json` `enabledPlugins` field + marketplace registration
- [x] ~~What is the relationship between ralph-loop and this repo?~~ → ralph-loop is from official marketplace (`claude-plugins-official`), tdd-workflow depends on it
- [x] ~~Are the MCP server configs in global_mcp_settings.json used?~~ → Yes, synced to `~/.claude.json` with env var resolution
- [x] ~~What is in .env?~~ → API keys: CONTEXT7_API_KEY, EXA_API_KEY
- [x] ~~How do skills differ from plugin skills?~~ → Same structure, both end up in `~/.claude/skills/`
- [x] ~~What triggers sync scripts?~~ → Manual via VS Code tasks or command line

## 9. Ambiguities

**Resolved**:
- Plugin installation: Local plugins registered via `marketplace.json`, installed via `/plugin marketplace add`
- Feature-dev agents: From official `feature-dev@claude-plugins-official` plugin (not this repo)

**Remaining**:
- Why two TDD workflow entries in installed_plugins.json (`tdd-workflow@local` and `tdd-workflow@local-plugins`)
- Whether sync scripts should be run in specific order

---

## Iteration 3 Findings: Plugin & Environment Architecture

### Plugin Registration System

**Two Marketplace Types**:
1. **Official Marketplace** (`claude-plugins-official`): GitHub-based, from `anthropics/claude-plugins-official`
2. **Local Marketplace** (`local-plugins`): Directory-based at `~/.claude/plugins/`

**Plugin Installation Flow**:
```
1. Run: /plugin marketplace add ~/.claude/plugins
2. This reads .claude-plugin/marketplace.json
3. Plugin appears in known_marketplaces.json
4. Enable via settings.json "enabledPlugins" or /plugin enable
```

**Current Enabled Plugins** (from `~/.claude/settings.json`):
- `ralph-wiggum@claude-plugins-official` ✓
- `ralph-loop@claude-plugins-official` ✓
- `feature-dev@claude-plugins-official` ✓
- `playwright@claude-plugins-official` ✓
- `tdd-workflow@local-plugins` ✓

### Environment Variable Resolution

The MCP sync script (`sync_mcp_servers_to_global.sh`) contains embedded Python that:
1. Reads `.env` file key-value pairs
2. Finds `${VAR}` patterns in JSON
3. Replaces with actual values
4. Writes resolved config to `~/.claude.json`

**API Keys in Use**:
- `CONTEXT7_API_KEY`: For Context7 documentation service
- `EXA_API_KEY`: For Exa web search and code context

### Global Claude Structure

```
~/.claude/
├── CLAUDE.md              # Global coding standards (synced from repo)
├── commands/              # Slash commands (synced)
├── docs/                  # Reference docs (synced)
├── plugins/               # Local plugins + cache
│   ├── tdd-workflow/      # Synced from repo
│   ├── .claude-plugin/    # Marketplace manifest
│   └── cache/             # Downloaded official plugins
├── skills/                # Synced skills
│   └── claude-md-guide/
├── settings.json          # User preferences + enabled plugins
├── history.jsonl          # Conversation history
├── projects/              # Project-specific data
└── todos/                 # Todo persistence

~/.claude.json             # Global config including mcpServers
```

### Command Taxonomy

| Type | Location | Invocation | Example |
|------|----------|------------|---------|
| Global commands | `~/.claude/commands/` | `/commit` | `commit.md` |
| Plugin commands | `~/.claude/plugins/<plugin>/commands/` | `/tdd-workflow:explore` | `explore.md` |
| Skills | `~/.claude/skills/<skill>/SKILL.md` | Auto-triggered | `claude-md-guide` |

### Test Runner Architecture

The tdd-workflow plugin includes intelligent test runner detection:

```bash
# Detection priority:
1. pytest (pyproject.toml, pytest.ini)
2. vitest (vitest.config.*)
3. jest (jest.config.*, package.json)
4. go test (go.mod)
5. cargo test (Cargo.toml)
6. rspec/minitest (Gemfile)
7. mix test (mix.exs)
```

### Key File Relationships

```
personal_configs/              ~/.claude/
├── .env                  →    (used at sync time, not copied)
├── claude-code/
│   ├── CLAUDE.md         →    CLAUDE.md
│   ├── commands/         →    commands/
│   ├── docs/             →    docs/
│   ├── plugins/          →    plugins/
│   ├── skills/           →    skills/
│   └── global_mcp_settings.json → ~/.claude.json (merged)
```

---

## Summary

This repository serves as a **version-controlled source of truth** for Claude Code configurations. It implements a hub-and-spoke model where:

1. **Central storage**: All configs live in this git repo
2. **Sync mechanism**: Shell scripts copy to `~/.claude/` with intelligent handling
3. **Environment isolation**: API keys stay in `.env`, never committed
4. **Plugin ecosystem**: Local `tdd-workflow` plugin extends official `ralph-loop`
5. **IDE integration**: VS Code tasks provide one-click sync operations

The primary workflow this enables is **TDD-driven development** with:
- Interview-first planning (40+ questions)
- Autonomous implementation via ralph-loop
- Automatic test feedback via PostToolUse hooks
- Confidence-scored code review

The codebase is well-organized with consistent patterns, though documentation (README.md) is outdated relative to actual capabilities.
