# Playwright Plugin

Browser automation for testing websites, web apps, and UIs. Uses `@playwright/cli` for token-efficient interactive browser automation and `@playwright/test` for formal CI test files.

## Components

- **1 skill** (`playwright`): Auto-activates when browser testing, screenshots, form filling, responsive design, or E2E frontend testing is needed

## Prerequisites

- **Node.js >= 18**
- **@playwright/cli**: `npm install -g @playwright/cli@latest`

## How It Works

This plugin provides skill guidance for two complementary Playwright tools:

### `playwright-cli` (interactive, token-efficient)

Shell commands for interactive browser automation. Saves screenshots and accessibility snapshots to disk (`.playwright-cli/` directory) — the agent reads them selectively via the Read tool, avoiding context bloat.

~4x fewer tokens than MCP-based approaches (27K vs 114K per task), officially recommended by Microsoft for coding agents.

### `@playwright/test` (formal CI tests)

Standard Playwright test framework for writing test files committed to the repo. See `API_REFERENCE.md` for the full API reference.

## Key Commands

| Command | Description |
|---------|-------------|
| `playwright-cli open [url]` | Launch browser and navigate |
| `playwright-cli screenshot` | Save screenshot as PNG |
| `playwright-cli snapshot` | Save accessibility snapshot as YAML |
| `playwright-cli click <ref>` | Click element by snapshot reference |
| `playwright-cli fill <ref> <text>` | Fill form field |
| `playwright-cli console` | Show browser console messages |
| `playwright-cli network` | List network requests |
| `playwright-cli close-all` | Close all browser sessions |

## Documentation

- `skills/playwright/SKILL.md`: Full usage guide with visual verification workflow, visual quality criteria, evaluation scoring rubric, test integrity rules, and multi-viewport testing
- `skills/playwright/API_REFERENCE.md`: `@playwright/test` API reference (selectors, network interception, auth, visual regression, mobile emulation, CI/CD)

## Version

5.0.0
