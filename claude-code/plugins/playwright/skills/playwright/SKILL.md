---
name: playwright
description: Browser automation with Playwright for testing websites, web apps, and UIs. Use when the user wants to test web pages, take screenshots, check responsive design, validate UX, test login flows, fill forms, check broken links, automate browser interactions, perform visual regression testing, or do end-to-end frontend testing. Uses playwright-cli for token-efficient browser automation and @playwright/test for formal CI test files.
---

# Playwright Browser Automation

## When to Use Which Tool

### `playwright-cli` (default for interactive work)
Use for: visual verification during development, screenshots, accessibility snapshots, form interaction, console/network checks, viewport testing. Token-efficient — saves all output to disk, read selectively via Read tool.

### `@playwright/test` (formal test files)
Use for: test files committed to the repo, CI pipeline tests, complex multi-step test scenarios with assertions, test reports. See [API_REFERENCE.md](./API_REFERENCE.md) for the full API.

**Prerequisite**: `npm install -g @playwright/cli@latest`

---

## CLI Command Reference

| Command | Description |
|---------|-------------|
| `playwright-cli open [url]` | Launch browser and navigate to URL |
| `playwright-cli goto <url>` | Navigate to URL in current session |
| `playwright-cli snapshot` | Save accessibility snapshot as YAML to `.playwright-cli/` |
| `playwright-cli screenshot` | Save screenshot as PNG to `.playwright-cli/` |
| `playwright-cli click <ref>` | Click element by reference (e.g., `e21` from snapshot) |
| `playwright-cli fill <ref> <text>` | Fill form field by reference |
| `playwright-cli type <text>` | Type text into focused element |
| `playwright-cli hover <ref>` | Hover over element by reference |
| `playwright-cli press <key>` | Keyboard input (Enter, Tab, Escape, etc.) |
| `playwright-cli run-code <code>` | Run raw Playwright script in page context |
| `playwright-cli console` | Show browser console messages |
| `playwright-cli network` | List network requests |
| `playwright-cli tab-new` / `tab-list` | Tab management |
| `playwright-cli list` | List active browser sessions |
| `playwright-cli close-all` | Close all browser sessions |
| `playwright-cli show` | Visual dashboard of all sessions |

---

## Working with Snapshots and Screenshots

- **Snapshots** are saved as YAML files in `.playwright-cli/` with element references like `e21`, `e35`
- **Screenshots** are saved as PNG files in `.playwright-cli/`
- Read snapshots with the **Read tool** to understand page structure and get element refs for interaction
- Read screenshots with the **Read tool** to visually evaluate the page (Read supports images)
- Element refs from snapshots are used in `click`, `fill`, `hover` commands

### Workflow

```
1. playwright-cli snapshot          → saves YAML with element refs
2. Read the YAML file              → find the ref for your target element (e.g., e21)
3. playwright-cli click e21        → interact using the ref
4. playwright-cli screenshot       → saves PNG of current state
5. Read the PNG file               → visually verify the result
```

---

## Critical Rules

**NEVER claim a visual or layout fix is correct without taking a fresh screenshot and reading the PNG.** Claude cannot mentally render CSS — visual verification requires actual rendered output. After every CSS or layout change, the cycle is: apply fix → screenshot → Read PNG → evaluate. Skipping the screenshot step guarantees unreliable results.

---

## Visual Verification Workflow

Use this workflow when verifying that a frontend/UI looks and functions correctly.

```
1. Ensure dev server is running:
   lsof -i :3000 -i :5173 -i :8080 -i :4200 -i :3001 | grep LISTEN

2. Open the page:
   playwright-cli open http://localhost:<port>/path

3. Desktop verification (1280x800):
   playwright-cli screenshot
   → Read the saved PNG via Read tool → evaluate visually

4. Take accessibility snapshot:
   playwright-cli snapshot
   → Read the YAML to understand page structure

5. Mobile verification (375x812):
   playwright-cli run-code "await page.setViewportSize({width: 375, height: 812})"
   playwright-cli screenshot
   → Read PNG → evaluate

6. Tablet verification (768x1024):
   playwright-cli run-code "await page.setViewportSize({width: 768, height: 1024})"
   playwright-cli screenshot
   → Read PNG → evaluate

7. Check for errors:
   playwright-cli console       → look for uncaught exceptions
   playwright-cli network       → look for failed requests

8. Test interactive elements:
   playwright-cli snapshot      → get element refs
   playwright-cli click e21     → test buttons/links
   playwright-cli fill e35 "test input"  → test form fields
   playwright-cli screenshot    → verify result

9. Fix issues → re-screenshot → confirm fix

10. Close when done:
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

## Visual Evaluation Scoring

After reading each screenshot, evaluate against these criteria. Rate each 1-5 (1=broken, 3=acceptable, 5=polished):

| Criterion | What to check |
|-----------|--------------|
| **Layout** | Elements properly aligned? Spacing consistent? No overlap or overflow? |
| **Typography** | Text hierarchy clear? Sizes appropriate? Line heights readable? |
| **Responsiveness** | Layout adapts at this viewport? No horizontal scroll? Touch targets sized? |
| **Functionality** | Interactive elements visible and accessible? Forms work? Navigation works? |
| **Polish** | Visual artifacts? Clipping? Unexpected gaps? Loading states correct? |

**If any criterion scores below 3, fix the issue before proceeding.** Take a fresh screenshot after the fix and re-evaluate.

---

## Multi-Viewport Testing

| Viewport | Width x Height | Use for |
|----------|---------------|---------|
| Desktop | 1280 x 800 | Default layout verification |
| Tablet | 768 x 1024 | Responsive breakpoint verification |
| Mobile | 375 x 812 | Mobile layout, touch targets, content reflow |

To resize the viewport within a session:
```bash
playwright-cli run-code "await page.setViewportSize({width: WIDTH, height: HEIGHT})"
```

---

## `@playwright/test` (Formal Test Files)

### Test Integrity Rules

When writing `@playwright/test` files, these rules are non-negotiable:

- **Tests MUST fail when the feature they test is broken.** If a test passes regardless of whether the feature works, the test is useless.
- **NEVER inject JavaScript into tests that modifies app behavior.** Tests observe and assert — they do not patch the application.
- **NEVER modify the DOM, inject styles, or override API responses inside test code to make assertions pass.** If a test requires changes to pass, make those changes in application code.
- **NEVER delete or skip existing tests to make a test suite pass.** Fix the code, not the tests.

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
lsof -i :3000 -i :5173 -i :8080 -i :4200 -i :3001 | grep LISTEN
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

**Browser doesn't open:**
Run `playwright-cli open` to verify the CLI can launch a browser.

**Element not found in snapshot:**
Take a fresh snapshot after the page has fully loaded: `playwright-cli snapshot`

**Session issues:**
```bash
playwright-cli list       # check active sessions
playwright-cli close-all  # clean up all sessions
```
