#!/bin/bash
# ABOUTME: Detects the test runner for the current project
# ABOUTME: Returns: pytest, playwright, vitest, jest, go, cargo, rspec, minitest, mix, or "unknown"

# Check for Python (pytest)
if [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
    # Verify pytest is actually used
    if grep -q "pytest" pyproject.toml 2>/dev/null || \
       grep -q "pytest" setup.cfg 2>/dev/null || \
       [ -f "pytest.ini" ]; then
        echo "pytest"
        exit 0
    fi
fi

# Check for Playwright (check before other JS runners)
if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
    echo "playwright"
    exit 0
fi

# Check for Vitest (before Jest since vitest.config takes precedence)
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] || [ -f "vitest.config.mts" ]; then
    echo "vitest"
    exit 0
fi

# Check for Jest
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.mjs" ]; then
    echo "jest"
    exit 0
fi

# Check package.json for JS test runners
if [ -f "package.json" ]; then
    if grep -q '"@playwright/test"' package.json 2>/dev/null; then
        echo "playwright"
        exit 0
    fi
    if grep -q '"jest"' package.json 2>/dev/null; then
        echo "jest"
        exit 0
    fi
    if grep -q '"vitest"' package.json 2>/dev/null; then
        echo "vitest"
        exit 0
    fi
fi

# Check for Go
if [ -f "go.mod" ]; then
    echo "go"
    exit 0
fi

# Check for Rust/Cargo
if [ -f "Cargo.toml" ]; then
    echo "cargo"
    exit 0
fi

# Check for Ruby (RSpec or Minitest)
if [ -f "Gemfile" ]; then
    if grep -q "rspec" Gemfile 2>/dev/null; then
        echo "rspec"
        exit 0
    fi
    if grep -q "minitest" Gemfile 2>/dev/null; then
        echo "minitest"
        exit 0
    fi
fi

# Check for Elixir
if [ -f "mix.exs" ]; then
    echo "mix"
    exit 0
fi

# No test runner detected
echo "unknown"
exit 0
