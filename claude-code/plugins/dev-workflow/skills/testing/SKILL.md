---
name: testing
description: TDD guidance, .tdd-test-scope file usage, and test optimization. Use when writing tests, implementing TDD RED/GREEN/REFACTOR cycles, configuring .tdd-test-scope for the dev-workflow stop hook, using test markers or tiering, caching API responses in tests, or doing visual/frontend testing with Playwright. Also activates during orchestrated TDD implementation (Phase 7) or E2E testing (Phase 8) when loaded by workflow commands.
---

# Testing Skill

This skill provides guidance for Test-Driven Development practices.

## When to Activate

Activate when:
- Engaging in a TDD workflow
- Writing tests before implementation
- Implementing code to pass tests
- Refactoring code with tests
- Asking about TDD practices
  
**Announce at start:** "I'm using the testing skill."

## TDD Core Principles

### Test With Real Services and Real APIs

Always strongly prefer using real data and real APIs for testing. Only resort to implementing a mock mode for tests when you absolutely positively have to.
If you are ntegrating with other internal components or services that are being developed in parallel (in the same code base) and are thus not currently available you can implement a mock for testing (only if this component is truly not available yet).
In the rare case an external API is not working after many many attempts you can implement a mock in tests to unblock yourself (this should be a last resort and exceedingly rare).
ALWAYS proactively inform the user when you have tested with a mock rather than with a real API.

### DO NOT Hard Code or Hack Your Way Around Tests

Do not just hard code an implementation or hack your way into passing tests. Actually stick to the goal of the project and implementation faithfully. Your implementations and tests should be honest, faithful, and genuine, not a hack to get around tests.

### The TDD Cycle

```
RED → GREEN → REFACTOR → (repeat)
```

1. **RED**: Write a failing test
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve without changing behavior

### RED Phase Rules

- Write ONE test at a time
- Test should fail for the right reason
- Test name describes expected behavior
- Test should be simple and focused

```python
# Good: Focused, descriptive
def test_user_creation_assigns_unique_id():
    user = create_user(name="Alice")
    assert user.id is not None
    assert isinstance(user.id, str)

# Bad: Testing multiple things
def test_user():
    user = create_user(name="Alice")
    assert user.id is not None
    assert user.name == "Alice"
    assert user.email is None
    assert user.is_active == True
```

### GREEN Phase Rules

- Write MINIMAL code to pass
- Don't optimize
- Don't add features
- Don't worry about code quality yet

```python
# Test expects:
def test_add_returns_sum():
    assert add(2, 3) == 5

# Minimal implementation (good):
def add(a, b):
    return a + b

# Over-engineered (bad):
def add(*args, **kwargs):
    """Add any number of values with optional precision."""
    precision = kwargs.get('precision', None)
    result = sum(args)
    return round(result, precision) if precision else result
```

### REFACTOR Phase Rules

- Tests must stay green
- Make ONE change at a time
- Run tests after each change
- Undo if tests fail

Common refactorings:
- Extract function
- Rename for clarity
- Remove duplication
- Simplify conditionals

## Test Writing Guidelines

### Arrange-Act-Assert Pattern

```python
def test_order_total_includes_shipping():
    # Arrange
    order = Order(items=[Item(price=100)])
    shipping = ShippingRate(cost=10)

    # Act
    total = order.calculate_total(shipping)

    # Assert
    assert total == 110
```

### Test Boundaries

Always test:
- Zero items
- One item
- Many items
- Maximum/minimum values
- Invalid inputs
- Empty strings/null values

```python
def test_list_handling():
    # Zero
    assert process([]) == []

    # One
    assert process([1]) == [1]

    # Many
    assert process([1, 2, 3]) == [1, 2, 3]
```

### Test Independence

Each test should:
- Run in isolation
- Not depend on other tests
- Not depend on execution order
- Clean up after itself

## Common TDD Mistakes

### 1. Writing Too Many Tests at Once
❌ Write 10 tests, then implement
✅ Write 1 test, implement, repeat

### 2. Writing Too Much Code
❌ Implement full feature to pass one test
✅ Write minimum code for this test only

### 3. Skipping the Red Phase
❌ Write implementation, then tests
✅ Always see the test fail first

### 4. Refactoring While Red
❌ Clean up code when tests are failing
✅ Only refactor when GREEN

### 5. Testing Implementation Details
❌ Test private methods
✅ Test public behavior

## TDD Benefits Reminder

- **Design feedback**: Hard to test = bad design
- **Documentation**: Tests show how code works
- **Confidence**: Refactor without fear
- **Focus**: One thing at a time
- **Quality**: Fewer bugs, cleaner code

## Quick Reference

| Phase | Do | Don't |
|-------|-----|-------|
| RED | Write one failing test | Write implementation |
| GREEN | Minimal code to pass | Optimize or add features |
| REFACTOR | Improve code quality | Change behavior |

---

## Test Optimization for TDD Loops

When doing TDD with real APIs and services, optimize for fast feedback to the extent possible by doing the following:

### Test Tiering with Markers

Tier tests. If using python and pytest, you can use markers to enable selective execution:

```python
import pytest

# Unit tests - fast, no external dependencies
@pytest.mark.unit
def test_parse_response():
    ...

# Integration tests - may use local services
@pytest.mark.integration
def test_database_connection():
    ...

# API tests - call external services (slow, may cost money)
@pytest.mark.api
def test_gemini_text_generation():
    ...

# Slow tests - any test taking >1s
@pytest.mark.slow
def test_large_file_processing():
    ...
```

**Marker Guidelines:**
- `@pytest.mark.unit`: Pure logic, no I/O, runs in milliseconds
- `@pytest.mark.integration`: Local services (DB, cache), runs in seconds
- `@pytest.mark.api`: External API calls, may be slow/flaky/costly
- `@pytest.mark.slow`: Any test >1 second regardless of type

Tests can have multiple markers:
```python
@pytest.mark.api
@pytest.mark.slow
def test_gemini_image_generation():
    # External API + inherently slow
    ...
```

### API Response Caching

For tests that call external APIs, use caching to avoid re-pinging on every run. If using python and pytest you can do this like so:

**Using pytest-recording (VCR-style):**
```python
import pytest

@pytest.mark.api
@pytest.mark.vcr  # Records HTTP responses on first run, replays thereafter
def test_gemini_api_response():
    response = call_gemini_api("test prompt")
    assert response.status == "success"
```

**Using Session-Scoped Fixtures:**
```python
# conftest.py
import pytest
import json
from pathlib import Path

CACHE_DIR = Path(__file__).parent / ".test_cache"

@pytest.fixture(scope="session")
def cached_gemini_response():
    """Cache expensive API response for entire test session."""
    cache_file = CACHE_DIR / "gemini_response.json"

    if cache_file.exists():
        return json.loads(cache_file.read_text())

    # Only call API once per session
    response = call_real_gemini_api()
    CACHE_DIR.mkdir(exist_ok=True)
    cache_file.write_text(json.dumps(response))
    return response

# In test file
@pytest.mark.api
def test_gemini_response_parsing(cached_gemini_response):
    # Uses cached response, no API call
    result = parse_response(cached_gemini_response)
    assert result.is_valid
```

**Cache Invalidation:**
```bash
# .gitignore
.test_cache/
cassettes/  # VCR recordings
```

### Test Scope File (Relevant when using dev-workflow)

If using dev-workflow plugin a stop hook will run all tests declared in .tdd-test-scope file (this file should be written in the root of the project's repo).

The `.tdd-test-scope` file controls which tests the stop hook in the dev-workflow runs. It supports file paths (universal), keywords, and runner-specific options.

**Location**: The `.tdd-test-scope` file MUST be placed in the **repository root** (the directory containing `.git/`). The hook script automatically finds the git repo root and looks for the file there. This ensures consistent behavior regardless of what subdirectory you're working in.

#### Format

```bash
# .tdd-test-scope

# === KEYWORDS (universal) ===
all                    # Run entire test suite
none                   # Skip tests entirely

# === FILE PATHS (universal) ===
# Any test file path - works with all runners
tests/test_parser.py
src/__tests__/Button.test.tsx
spec/models/user_spec.rb

# === RUNNER-SPECIFIC OPTIONS ===
# Prefix with runner name and colon

# pytest options
pytest:-m "unit"                    # Run tests with @pytest.mark.unit
pytest:-m "not slow"                # Exclude slow tests
pytest:-k "test_parse"              # Run tests matching keyword

# vitest options
vitest:--grep "parser"              # Filter by test name pattern
vitest:--grep "^Parser"             # Regex patterns supported

# jest options
jest:--testNamePattern "parser"     # Filter by test name
jest:-t "should parse"              # Short form

# playwright options
playwright:--grep "login"           # Filter by test title
playwright:--grep-invert "slow"     # Exclude tests matching pattern
playwright:--project chromium       # Run specific project

# cargo (Rust) options
cargo:parser                        # Run tests matching "parser"
cargo:--test integration            # Run specific test target

# go test options
go_test:-run TestParser             # Run tests matching regex
go_test:-run "Test.*Parse"          # Regex patterns supported

# rspec options
rspec:--tag unit                    # Run tests with tag
rspec:--tag ~slow                   # Exclude tests with tag

# minitest options
minitest:-n "/test_parse/"          # Run tests matching pattern
minitest:-n "test_specific_method"  # Run specific test method

# mix (Elixir) options
mix:--only unit                     # Run tests with @tag :unit
mix:--exclude slow                  # Exclude tests with @tag :slow
```

#### Supported Frameworks

| Framework | Detection | File Pattern | Runner-Specific Prefix |
|-----------|-----------|--------------|------------------------|
| **pytest** | `pyproject.toml`, `pytest.ini` | `*.py` | `pytest:` |
| **vitest** | `vitest.config.{ts,js,mts}` | `*.{test,spec}.{ts,js,tsx,jsx}` | `vitest:` |
| **jest** | `jest.config.{js,ts}`, `package.json` | `*.{test,spec}.{ts,js,tsx,jsx}` | `jest:` |
| **playwright** | `playwright.config.{ts,js}` | `*.{test,spec}.{ts,js}` | `playwright:` |
| **cargo** | `Cargo.toml` | N/A (uses test names) | `cargo:` |
| **go test** | `go.mod` | `*_test.go` | `go_test:` |
| **rspec** | `Gemfile` with rspec | `*_spec.rb` | `rspec:` |
| **minitest** | `Gemfile` with minitest | `*_test.rb` | `minitest:` |
| **mix** | `mix.exs` | `*_test.exs` | `mix:` |

#### Examples by Workflow

**RED phase** (just wrote a failing test):
```bash
# Write to repo root: .tdd-test-scope
# Scope to the specific test file
tests/test_gemini_client.py
```

**GREEN phase** (implementing):
```bash
# Same file, or add unit marker for speed
tests/test_gemini_client.py
pytest:-m "unit"
```

**REFACTOR phase** (ensuring no regressions):
```bash
# Run all tests for the component
tests/test_gemini_client.py
tests/test_parser.py
```

**Before finishing** (full verification):
```bash
all
```

**Skip verification** (exploratory work):
```bash
none
```

#### How It Works

1. Claude writes `.tdd-test-scope` to the **repository root** specifying which tests to verify
2. Stop hook finds the repo root (via `git rev-parse --show-toplevel`) and reads the file
3. Hook detects the test runner and runs only specified tests from the repo root
4. Scope file is deleted after running (one-shot verification)

If no `.tdd-test-scope` file exists in the repo root, no tests run (Claude must explicitly request verification).

---

## Visual and Frontend Testing

When working on applications with frontends or UIs, you must load the playwright:playwright skill and use **Playwright** to verify:
- **Functional correctness**: UI interactions work as expected
- **Visual appearance**: The UI looks correct and matches design expectations
- **Integration**: Frontend and backend work together properly
  
Specifically, you must load the playwright:playwright skill and use Playwright tests when:
- Building or modifying frontend/UI components
- Implementing user-facing features
- Verifying visual design matches expectations
- Testing end-to-end user flows
- Ensuring responsive design works across viewports

**the `playwright:playwright` skill** contains detailed guidance on:
- Writing Playwright tests
- Taking screenshots for visual verification
- Visual regression testing
- Responsive design testing across viewports
- TDD with frontend components


### Playwright Test Scope

Use the `.tdd-test-scope` file to run specific Playwright tests:

```bash
# Run specific test file
tests/e2e/checkout.spec.ts

# Filter by test name
playwright:--grep "checkout"

# Run specific project (browser)
playwright:--project chromium

# Exclude slow visual tests during rapid iteration
playwright:--grep-invert "visual regression"
```

### TDD with Playwright

Apply TDD principles to frontend development:

1. **RED phase**: Write failing Playwright test for expected UI behavior
2. **GREEN phase**: Implement the UI to make test pass
3. **REFACTOR phase**: Clean up implementation while keeping tests green

Take screenshots after each change to verify the UI looks correct visually.
