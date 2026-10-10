---
name: playwright
description: Browser automation with Playwright for testing websites, web apps, and UIs. Use when the user wants to test web pages, take screenshots, check responsive design, validate UX, test login flows, fill forms, check broken links, automate browser interactions, perform visual regression testing, or do end-to-end frontend testing. Uses playwright-cli for token-efficient browser automation and @playwright/test for formal CI test files.
---

# Playwright Browser Automation

## When to Use Which Tool

### `playwright-cli` (default for interactive work)
Use for: visual verification during development, screenshots, accessibility snapshots, form interaction, console/network checks, viewport testing. Token-efficient — it writes screenshots and snapshots to disk so you read only what you need.

### `@playwright/test` (formal test files)
Use for: test files committed to the repo, CI pipeline tests, complex multi-step test scenarios with assertions, test reports. See [API_REFERENCE.md](./API_REFERENCE.md) for the full API.

**Prerequisite**: `npm install -g @playwright/cli@latest`

---

## CLI Command Reference

The CLI is young and its command set still changes between releases; `playwright-cli --help` is authoritative when this table and the installed version disagree.

| Command | Description |
|---------|-------------|
| `playwright-cli open [url]` | Launch browser and navigate to URL (`--device="iPhone 15"` or `--mobile` for device emulation) |
| `playwright-cli goto <url>` | Navigate to URL in current session |
| `playwright-cli snapshot [--filename <path>]` | Accessibility snapshot as YAML; prints to stdout unless `--filename` is given |
| `playwright-cli screenshot` | Save screenshot as PNG to `.playwright-cli/` |
| `playwright-cli click <ref>` | Click element by reference (e.g., `e21` from snapshot) |
| `playwright-cli fill <ref> <text>` | Fill form field by reference |
| `playwright-cli type <text>` | Type text into focused element |
| `playwright-cli hover <ref>` | Hover over element by reference |
| `playwright-cli press <key>` | Keyboard input (Enter, Tab, Escape, etc.) |
| `playwright-cli resize <width> <height>` | Set the viewport size |
| `playwright-cli run-code "<function>"` | Run a Playwright function expression, e.g. `"async page => { ... }"` |
| `playwright-cli console` | Show browser console messages |
| `playwright-cli requests` | List network requests (`request <index>` for one) |
| `playwright-cli tab-new` / `tab-list` | Tab management |
| `playwright-cli list` | List active browser sessions |
| `playwright-cli close-all` | Close all browser sessions |
| `playwright-cli show` | Visual dashboard of all sessions |

---

## Working with Snapshots and Screenshots

- **Snapshots** are YAML with element references like `e21`, `e35`. Commands also save an automatic snapshot to `.playwright-cli/page-<timestamp>.yml`. For a large page, write the snapshot to a file with `--filename` and search it rather than printing it into context
- **Screenshots** are saved as PNG files in `.playwright-cli/`
- Read screenshots with the **Read tool** to visually evaluate the page (Read supports images)
- Element refs from snapshots are used in `click`, `fill`, `hover` commands

### Workflow

```
1. playwright-cli snapshot --filename .playwright-cli/snap.yml  → YAML with element refs
2. Read or grep the YAML           → find the ref for your target element (e.g., e21)
3. playwright-cli click e21        → interact using the ref
4. playwright-cli screenshot       → saves PNG of current state
5. Read the PNG file               → visually verify the result
```

---

## The core rule

**Do not claim a visual or layout fix is correct without taking a fresh screenshot and reading the PNG.** You cannot tell from the CSS whether a layout renders correctly — only the rendered output shows that. After every CSS or layout change the cycle is: apply fix, screenshot, Read the PNG, evaluate. Reasoning about the change instead of looking at it is how confidently-wrong layout claims happen.

---

## Visual Verification Workflow

Use this workflow when verifying that a frontend/UI looks and functions correctly. Desktop is always verified, since it is the most important viewport. Run the tablet and mobile steps only when the user asks for responsive or mobile checks.

```
1. Ensure dev server is running (see "Dev Server Detection" below)

2. Open the page:
   playwright-cli open http://localhost:<port>/path

3. Desktop verification (1280x800):
   playwright-cli resize 1280 800
   playwright-cli screenshot
   → Read the saved PNG via Read tool → evaluate visually

4. Take accessibility snapshot:
   playwright-cli snapshot --filename .playwright-cli/snap.yml
   → Read the YAML to understand page structure

5. Only if responsive checks were requested — tablet (768x1024), then mobile (375x812):
   playwright-cli resize 768 1024
   playwright-cli screenshot     → Read PNG → evaluate
   playwright-cli resize 375 812
   playwright-cli screenshot     → Read PNG → evaluate

6. Check for errors:
   playwright-cli console       → look for uncaught exceptions
   playwright-cli requests      → look for failed requests

7. Test interactive elements:
   playwright-cli snapshot --filename .playwright-cli/snap.yml  → get element refs
   playwright-cli click e21     → test buttons/links
   playwright-cli fill e35 "test input"  → test form fields
   playwright-cli screenshot    → verify result

8. Fix issues → re-screenshot → confirm fix

9. Close when done:
   playwright-cli close-all
```

---

## Visual Quality Criteria

When evaluating screenshots, check for:

### Layout
- Consistent spacing between elements
- Proper alignment (no misaligned text, buttons, or containers)
- No overlapping elements
- Logical visual hierarchy

### Typography
- Readable font sizes (min 14px body, 12px labels)
- Proper heading hierarchy (h1 > h2 > h3)
- Adequate line height (1.4-1.6 for body text)

### Responsiveness
- No horizontal scroll at any viewport
- No truncated or hidden content
- Touch-friendly targets (>= 44px) on mobile
- Content reflows appropriately between viewports

### Functionality
- All buttons and links respond to clicks
- Forms accept input and submit correctly
- Navigation works (page transitions, routing)
- Dropdowns, modals, and overlays open and close
- No dead interactive elements

### Console Health
- No uncaught exceptions
- No failed network requests to expected endpoints
- No deprecation warnings that indicate broken features

### Visual Polish
- Consistent color usage
- Adequate contrast between text and background
- No orphaned elements (floating without context)
- No unexpected whitespace gaps
- Proper loading states (no flash of unstyled content)

---

## Evaluating a Screenshot

After reading each screenshot, check it against the Visual Quality Criteria above. For each criterion that fails, name the specific element at fault and where, for example "the nav overlaps the logo at 375px wide". A named failure can be fixed and re-checked; a score cannot. Fix failures before moving on, then take a fresh screenshot and check again.

---

## Multi-Viewport Testing

Desktop is the default; tablet and mobile are verified only on request (see the workflow above).

| Viewport | Width x Height | Use for |
|----------|---------------|---------|
| Desktop | 1280 x 800 | Default layout verification |
| Tablet | 768 x 1024 | Responsive breakpoint verification |
| Mobile | 375 x 812 | Mobile layout, touch targets, content reflow |

To resize the viewport within a session:
```bash
playwright-cli resize WIDTH HEIGHT
```

`run-code` takes a function expression, not a bare statement, so the equivalent there is `playwright-cli run-code "async page => { await page.setViewportSize({ width: WIDTH, height: HEIGHT }); }"`. For real device emulation (user agent, touch, device scale factor), open with `--device="iPhone 15"` instead.

---

## `@playwright/test` (Formal Test Files)

### Test Integrity Rules

When writing `@playwright/test` files, these rules are non-negotiable:

- **A test must fail when the feature it tests is broken.** A test that passes either way measures nothing.
- **Do not inject JavaScript that modifies application behavior.** Tests observe and assert; they do not patch the app.
- **Do not modify the DOM, inject styles, or override API responses inside test code to make assertions pass.** If something must change for the test to pass, change the application code.
- **Do not delete, skip, or weaken existing tests to get a green suite.** Fix the code instead. A suite made green this way is worse than a failing one, because it also destroys the signal.

For writing formal test files committed to the repo and run in CI, use `@playwright/test`. See [API_REFERENCE.md](./API_REFERENCE.md) for:

- Selectors and Locators best practices
- Network interception and API mocking
- Authentication and session management
- Visual regression testing
- Mobile device emulation
- Performance testing
- Debugging techniques
- CI/CD integration

Run tests with:
```bash
npx playwright test
```

---

## Dev Server Detection

Before testing localhost, check for running dev servers:

```bash
lsof -i :3000 -i :5173 -i :5174 -i :8080 -i :4200 -i :3001 | grep LISTEN
```

- If **1 server found**: Use it automatically
- If **multiple servers found**: Ask user which one to test
- If **no servers found**: Ask for URL or offer to help start dev server

---

## Troubleshooting

**playwright-cli not installed:**
```bash
npm install -g @playwright/cli@latest
```

**A command from this skill is rejected as unknown:** the CLI renamed it. Check `playwright-cli --help` (for example, `network` became `requests`).

**Browser doesn't open:**
Run `playwright-cli open` to verify the CLI can launch a browser.

**Element not found in snapshot:**
Take a fresh snapshot after the page has fully loaded: `playwright-cli snapshot`

**Session issues:**
```bash
playwright-cli list       # check active sessions
playwright-cli close-all  # clean up all sessions
```
