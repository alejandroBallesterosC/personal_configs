# Personal Development Configurations

This repository contains a curated collection of shared configurations, scripts, and development tools to streamline and standardize development workflows across different projects and environments.

## 📁 Repository Structure

```
personal_configs/
├── .cursor/                    # Cursor IDE configurations
│   ├── mcp.json               # Model Context Protocol server configurations
│   └── rules/
│       └── maintain-docs.mdc  # Documentation maintenance rules
├── .vscode/                   # Visual Studio Code configurations
│   ├── key_bindings.json      # Custom keyboard shortcuts
│   └── tasks.json             # Build and run tasks
├── claude-code/               # Claude AI assistant command templates
│   └── commands/              # Reusable command prompts
├── scripts/                   # Utility scripts
│   └── run_file.sh           # Universal file runner script
└── README.md                  # This file
```

## 🛠️ Components

### Cursor Configs (`.cursor/`)

**MCP Server Setup** (`mcp.json`)
- Configures Model Context Protocol servers for enhanced AI capabilities
- **Notion Integration**: Connects to Notion workspace via `@notionhq/notion-mcp-server`
- **Browser Tools**: Enables web interaction capabilities with `@agentdeskai/browser-tools-mcp`

**Documentation Rules** (`rules/maintain-docs.mdc`)
- Automated documentation maintenance guidelines
- Ensures README files stay current with code changes
- Triggers updates for API changes, configuration changes, and new features

### VS Code Configs (`.vscode/`)

**Custom Key Bindings** (`key_bindings.json`)
- `Cmd+Shift+B`: Quick compile and run current file

**Build Tasks** (`tasks.json`)
- **Compile & Run Current File**: Universal task that delegates to `run_file.sh` (in `/scripts`)
- **Compile Frontend TypeScript**: TypeScript compilation for frontend projects
- **Run App**: General application runner script

### Claude Code Custom Commands (`claude-code/commands/`)

Pre-written command templates for common development tasks:
- `execute-plan-subagents.md`: Template for parallel task execution using multiple AI agents
- `explain-repo.md`: Repository explanation and architecture analysis prompt
- `understand-repo.md`: Comprehensive codebase review template
- `update-docs-and-todos.md`: Documentation and TODO maintenance prompt

you can copy this to ~/.claude/commands for global use across all your claude-code projects and then call them with/{command}

### Utility Scripts (`scripts/`)

**File Runner** (`run_file.sh`)
- Universal file runner supporting C++ and Python
- Triggered by VS Code's Cmd+Shift+B shortcut

**Claude Code Sync Scripts**
- `sync_commands_from_global.sh`: Copy commands from `~/.claude/commands/` → `claude-code/commands/`
- `sync_commands_to_global.sh`: Copy commands from `claude-code/commands/` → `~/.claude/commands/`
- `sync_docs_from_global.sh`: Copy docs from `~/.claude/docs/` → `claude-code/docs/`
- `sync_docs_to_global.sh`: Copy docs from `claude-code/docs/` → `~/.claude/docs/`

All sync scripts support `--overwrite` flag to clear destination before copying (default: overwrites only matching filenames)

---

*This configuration repository is designed to be a living collection that evolves with your development needs. Feel free to adapt and extend these configurations for your specific workflow requirements.*
