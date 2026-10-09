# Playwright Plugin

Browser automation for testing websites, web apps, and UIs. Uses `@playwright/cli` for token-efficient interactive browser automation and `@playwright/test` for formal CI test files.

```
/plugin install playwright --marketplace alejandroBallesterosC/personal_configs
```

## Components

- **1 skill** (`playwright`): Auto-activates when browser testing, screenshots, form filling, responsive design, or E2E frontend testing is needed

## Prerequisites

- **Node.js >= 18**
- **@playwright/cli**: `npm install -g @playwright/cli@latest`

## How It Works

This plugin provides skill guidance for two complementary Playwright tools:

### `playwright-cli` (interactive, token-efficient)

Shell commands for interactive browser automation. Saves screenshots and accessibility snapshots to disk (`.playwright-cli/` directory) — the agent reads them selectively via the Read tool, avoiding context bloat.

Microsoft recommends the CLI over the Playwright MCP server for coding agents: the [playwright-mcp README](https://github.com/microsoft/playwright-mcp/blob/main/README.md) says "If you are using a coding agent, you might benefit from using the CLI+SKILLS instead," and [playwright.dev](https://playwright.dev/docs/getting-started-cli) describes `playwright-cli` as "best for coding agents ... that favor token-efficient, skill-based workflows." No official source publishes a token-count comparison.

`playwright-cli install --skills` installs Microsoft's own `playwright-cli` command-reference skill. This plugin's skill adds the parts that one does not cover: the visual verification workflow, the screenshot-before-claiming-a-fix rule, quality criteria, and test-integrity rules. If you install both, the command tables overlap; `playwright-cli --help` is authoritative.

### `@playwright/test` (formal CI tests)

Standard Playwright test framework for writing test files committed to the repo. See `API_REFERENCE.md` for the full API reference.

## Key Commands

| Command | Description |
|---------|-------------|
| `playwright-cli open [url]` | Launch browser and navigate |
| `playwright-cli screenshot` | Save screenshot as PNG |
| `playwright-cli snapshot --filename <path>` | Save accessibility snapshot as YAML |
| `playwright-cli click <ref>` | Click element by snapshot reference |
| `playwright-cli fill <ref> <text>` | Fill form field |
| `playwright-cli resize <w> <h>` | Set the viewport size |
| `playwright-cli console` | Show browser console messages |
| `playwright-cli requests` | List network requests |
| `playwright-cli close-all` | Close all browser sessions |

## Documentation

- `skills/playwright/SKILL.md`: Full usage guide with visual verification workflow, visual quality criteria, screenshot evaluation, test integrity rules, and multi-viewport testing
- `skills/playwright/API_REFERENCE.md`: `@playwright/test` API reference (selectors, network interception, auth, visual regression, mobile emulation, CI/CD)
