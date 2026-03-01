#!/bin/bash
# ABOUTME: Detects the test runner for the current project
# ABOUTME: Returns: pytest, playwright, vitest, jest, go, cargo, rspec, minitest, mix, or "unknown"

# Debug log file for diagnosing test runner detection
DEBUG_FILE=".claude/detect-test-runner-debug.md"

debug_log() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p .claude
  {
    echo "## $timestamp"
    echo ""
    echo "$msg"
    echo ""
    echo "**Working directory:** $(pwd)"
    echo ""
    echo "---"
    echo ""
  } >> "$DEBUG_FILE"
}

debug_log "**Invoked.** Scanning for test runner..."

# Check for Python (pytest)
if [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
    # Verify pytest is actually used
    if grep -q "pytest" pyproject.toml 2>/dev/null || \
       grep -q "pytest" setup.cfg 2>/dev/null || \
       [ -f "pytest.ini" ]; then
        debug_log "**Detected:** pytest"
        echo "pytest"
        exit 0
    fi
fi

# Check for Playwright (check before other JS runners)
if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
    debug_log "**Detected:** playwright (config file)"
    echo "playwright"
    exit 0
fi

# Check for Vitest (before Jest since vitest.config takes precedence)
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] || [ -f "vitest.config.mts" ]; then
    debug_log "**Detected:** vitest (config file)"
    echo "vitest"
    exit 0
fi

# Check for Jest
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.mjs" ]; then
    debug_log "**Detected:** jest (config file)"
    echo "jest"
    exit 0
fi

# Check package.json for JS test runners
if [ -f "package.json" ]; then
    if grep -q '"@playwright/test"' package.json 2>/dev/null; then
        debug_log "**Detected:** playwright (package.json)"
        echo "playwright"
        exit 0
    fi
    if grep -q '"jest"' package.json 2>/dev/null; then
        debug_log "**Detected:** jest (package.json)"
        echo "jest"
        exit 0
    fi
    if grep -q '"vitest"' package.json 2>/dev/null; then
        debug_log "**Detected:** vitest (package.json)"
        echo "vitest"
        exit 0
    fi
fi

# Check for Go
if [ -f "go.mod" ]; then
    debug_log "**Detected:** go"
    echo "go"
    exit 0
fi

# Check for Rust/Cargo
if [ -f "Cargo.toml" ]; then
    debug_log "**Detected:** cargo"
    echo "cargo"
    exit 0
fi

# Check for Ruby (RSpec or Minitest)
if [ -f "Gemfile" ]; then
    if grep -q "rspec" Gemfile 2>/dev/null; then
        debug_log "**Detected:** rspec"
        echo "rspec"
        exit 0
    fi
    if grep -q "minitest" Gemfile 2>/dev/null; then
        debug_log "**Detected:** minitest"
        echo "minitest"
        exit 0
    fi
fi

# Check for Elixir
if [ -f "mix.exs" ]; then
    debug_log "**Detected:** mix"
    echo "mix"
    exit 0
fi

# No test runner detected
debug_log "**No test runner detected.** Returning 'unknown'"
echo "unknown"
exit 0
