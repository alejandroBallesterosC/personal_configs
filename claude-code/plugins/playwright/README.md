# Playwright Plugin

Browser automation with Playwright for testing websites, web apps, and UIs. Write custom Playwright scripts for any browser automation task and execute them via a universal executor.

## Components

- **1 skill** (`playwright`): Auto-activates when browser testing, screenshots, form filling, responsive design, or E2E frontend testing is needed

## Quick Start

```bash
# First-time setup (installs Playwright + Chromium)
cd ${CLAUDE_PLUGIN_ROOT}/skills/playwright && npm run setup
```

Then ask Claude to test a page, take screenshots, fill forms, or automate any browser interaction. The skill handles everything automatically.

## How It Works

1. Auto-detects running dev servers on localhost
2. Writes custom Playwright scripts to `/tmp/playwright-test-*.js`
3. Executes via `cd ${CLAUDE_PLUGIN_ROOT}/skills/playwright && node run.js /tmp/playwright-test-*.js`
4. Browser window visible by default (`headless: false`) for debugging
5. Scripts auto-cleaned from `/tmp` by OS

## Features

- **Auto server detection**: Finds running dev servers before writing test code
- **Visible browser**: `headless: false` by default for easy debugging
- **Parameterized URLs**: All scripts use a `TARGET_URL` constant
- **Custom HTTP headers**: Configure via `PW_HEADER_NAME`/`PW_HEADER_VALUE` env vars
- **Helper utilities**: `lib/helpers.js` provides safe clicks, typed input, screenshot helpers, cookie banner handling, table extraction
- **Inline execution**: Quick one-off tasks without creating files
- **Multi-viewport testing**: Desktop, tablet, and mobile viewport presets

## Dependencies

- **Node.js >= 18.0.0**
- **Playwright** (v1.57.0, installed via `npm run setup`)
- **Chromium** (installed via `npx playwright install chromium`)

## Documentation

- `skills/playwright/SKILL.md`: Full usage guide with code patterns
- `skills/playwright/API_REFERENCE.md`: Playwright API reference (selectors, network interception, auth, visual regression, mobile emulation)

## Version

4.1.0
