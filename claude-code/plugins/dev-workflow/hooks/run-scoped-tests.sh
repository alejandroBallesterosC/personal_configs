#!/bin/bash
# ABOUTME: Stop hook that runs scoped tests and blocks Claude from stopping if they fail.
# ABOUTME: Uses exit 0 + JSON decision:block pattern per Claude Code hooks spec.

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".claude/run-scoped-tests-debug.md"

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

# Log hook invocation
debug_log "**Hook invoked.**"

# Check for jq dependency (required for producing JSON block output on test failure)
if ! command -v jq &>/dev/null; then
    debug_log "**DEPENDENCY MISSING:** jq not found in PATH ($PATH)"
    echo "ERROR: jq is required but not installed." >&2
    echo "The run-scoped-tests hook cannot produce JSON output without jq." >&2
    echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
    exit 2
fi

# Read and discard hook input from stdin (required so stdin doesn't hang).
# No need to check stop_hook_active: Claude can remove tests from .tdd-test-scope
# to unblock itself if tests keep failing, which is the intended escape hatch.
cat > /dev/null

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the git repo root (the .tdd-test-scope file must be placed there)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    # Not in a git repo, fall back to current directory
    REPO_ROOT="."
fi

# Check if .tdd-test-scope exists in repo root
SCOPE_FILE="$REPO_ROOT/.tdd-test-scope"
if [ ! -f "$SCOPE_FILE" ]; then
    # No scope file = no tests to run (Claude hasn't requested verification)
    debug_log "**Exiting:** No .tdd-test-scope file found at $SCOPE_FILE"
    exit 0
fi

SCOPE=$(cat "$SCOPE_FILE")

# Handle special cases
if [ "$SCOPE" = "none" ] || [ -z "$SCOPE" ]; then
    debug_log "**Exiting:** Scope is 'none' or empty, removing scope file"
    rm -f "$SCOPE_FILE"
    exit 0
fi

# Change to repo root to run tests (test runners expect to run from project root)
cd "$REPO_ROOT"

# Detect the test runner
DETECTED=$("$SCRIPT_DIR/detect-test-runner.sh")

# Extract runner-specific options and file paths from scope
# Format:
#   - File paths: tests/test_foo.py, src/__tests__/Button.test.tsx
#   - Keywords: all, none
#   - Runner-specific: pytest:-m "unit", vitest:--grep "pattern", etc.

extract_runner_options() {
    local runner_prefix="$1"
    local options=""
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        if [[ "$line" =~ ^${runner_prefix}: ]]; then
            # Remove prefix and add to options
            options="$options ${line#${runner_prefix}:}"
        fi
    done <<< "$SCOPE"
    echo "$options"
}

extract_file_paths() {
    local extension_pattern="$1"
    local files=""
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        # Skip runner-specific options (contain colon with known prefix)
        [[ "$line" =~ ^(pytest|vitest|jest|playwright|cargo|go_test|rspec|mix): ]] && continue
        # Skip keywords
        [[ "$line" = "all" || "$line" = "none" ]] && continue
        # Match file extensions
        if [[ "$line" =~ $extension_pattern ]]; then
            files="$files $line"
        fi
    done <<< "$SCOPE"
    echo "$files"
}

# Check if scope contains "all"
is_all() {
    while IFS= read -r line; do
        [[ "$line" = "all" ]] && return 0
    done <<< "$SCOPE"
    return 1
}

run_pytest() {
    local pytest_cmd="pytest -q --tb=short"
    if command -v uv &> /dev/null && [ -f "pyproject.toml" ]; then
        pytest_cmd="uv run pytest -q --tb=short"
    fi

    if is_all; then
        $pytest_cmd 2>&1
    else
        local options=$(extract_runner_options "pytest")
        local files=$(extract_file_paths '\.py$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            $pytest_cmd $options $files 2>&1
        else
            # No scope specified for pytest, skip
            echo "No pytest scope specified"
            exit 0
        fi
    fi
}

run_vitest() {
    if is_all; then
        npx vitest run --reporter=basic 2>&1
    else
        local options=$(extract_runner_options "vitest")
        local files=$(extract_file_paths '\.(test|spec)\.(ts|js|tsx|jsx|mts|mjs)$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            npx vitest run --reporter=basic $options $files 2>&1
        else
            echo "No vitest scope specified"
            exit 0
        fi
    fi
}

run_jest() {
    if is_all; then
        npx jest --passWithNoTests 2>&1
    else
        local options=$(extract_runner_options "jest")
        local files=$(extract_file_paths '\.(test|spec)\.(ts|js|tsx|jsx)$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            npx jest --passWithNoTests $options $files 2>&1
        else
            echo "No jest scope specified"
            exit 0
        fi
    fi
}

run_playwright() {
    if is_all; then
        npx playwright test 2>&1
    else
        local options=$(extract_runner_options "playwright")
        local files=$(extract_file_paths '\.(test|spec)\.(ts|js)$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            npx playwright test $options $files 2>&1
        else
            echo "No playwright scope specified"
            exit 0
        fi
    fi
}

run_go() {
    if is_all; then
        go test ./... -v 2>&1
    else
        local options=$(extract_runner_options "go_test")
        local files=$(extract_file_paths '_test\.go$')

        if [ -n "$options" ]; then
            # go_test:-run TestParser → go test ./... -run TestParser
            go test ./... -v $options 2>&1
        elif [ -n "$files" ]; then
            # Run tests in specific packages based on file paths
            local packages=""
            for f in $files; do
                packages="$packages ./$(dirname $f)/..."
            done
            go test -v $packages 2>&1
        else
            echo "No go test scope specified"
            exit 0
        fi
    fi
}

run_cargo() {
    if is_all; then
        cargo test 2>&1
    else
        local options=$(extract_runner_options "cargo")

        if [ -n "$options" ]; then
            # cargo:parser_tests → cargo test parser_tests
            cargo test $options 2>&1
        else
            # Cargo doesn't use file paths the same way
            echo "No cargo scope specified"
            exit 0
        fi
    fi
}

run_rspec() {
    if is_all; then
        bundle exec rspec --format progress 2>&1
    else
        local options=$(extract_runner_options "rspec")
        local files=$(extract_file_paths '_spec\.rb$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            bundle exec rspec --format progress $options $files 2>&1
        else
            echo "No rspec scope specified"
            exit 0
        fi
    fi
}

run_mix() {
    if is_all; then
        mix test 2>&1
    else
        local options=$(extract_runner_options "mix")
        local files=$(extract_file_paths '_test\.exs$')

        if [ -n "$files" ] || [ -n "$options" ]; then
            mix test $options $files 2>&1
        else
            echo "No mix scope specified"
            exit 0
        fi
    fi
}

run_minitest() {
    if is_all; then
        ruby -Ilib:test test/**/*_test.rb 2>&1
    else
        local options=$(extract_runner_options "minitest")
        local files=$(extract_file_paths '_test\.rb$')

        if [ -n "$files" ]; then
            ruby -Ilib:test $options $files 2>&1
        elif [ -n "$options" ]; then
            ruby -Ilib:test test/**/*_test.rb $options 2>&1
        else
            echo "No minitest scope specified"
            exit 0
        fi
    fi
}

# Run appropriate test command, capturing output and exit code
case "$DETECTED" in
    pytest)      TEST_OUTPUT=$(run_pytest);  TEST_EXIT=$? ;;
    vitest)      TEST_OUTPUT=$(run_vitest);  TEST_EXIT=$? ;;
    jest)        TEST_OUTPUT=$(run_jest);    TEST_EXIT=$? ;;
    playwright)  TEST_OUTPUT=$(run_playwright); TEST_EXIT=$? ;;
    go)          TEST_OUTPUT=$(run_go);      TEST_EXIT=$? ;;
    cargo)       TEST_OUTPUT=$(run_cargo);   TEST_EXIT=$? ;;
    rspec)       TEST_OUTPUT=$(run_rspec);   TEST_EXIT=$? ;;
    minitest)    TEST_OUTPUT=$(run_minitest); TEST_EXIT=$? ;;
    mix)         TEST_OUTPUT=$(run_mix);     TEST_EXIT=$? ;;
    *)
        debug_log "**Exiting:** No supported test runner detected (got: '$DETECTED')"
        echo "No supported test runner detected"
        rm -f "$SCOPE_FILE"
        exit 0
        ;;
esac

debug_log "**Ran tests:** runner=$DETECTED, exit_code=$TEST_EXIT, scope=$(cat "$REPO_ROOT/.tdd-test-scope" 2>/dev/null || echo 'already removed')"

# Clean up scope file after running (one-shot verification)
rm -f "$SCOPE_FILE"

# If tests passed, allow Claude to stop
if [ "$TEST_EXIT" -eq 0 ]; then
    debug_log "**Tests passed.** Allowing stop."
    exit 0
fi

debug_log "**Tests FAILED.** Blocking stop. Exit code: $TEST_EXIT"

# Tests failed: block Claude from stopping using exit 0 + JSON decision pattern.
# Strip ANSI escape codes and truncate to last 200 lines for clean JSON output.
TRUNCATED_OUTPUT=$(echo "$TEST_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | tail -200)
HEADER="Scoped tests failed ($DETECTED, exit code $TEST_EXIT). Fix the failing tests before stopping."
printf '%s\n\n%s' "$HEADER" "$TRUNCATED_OUTPUT" | jq -Rs '{ "decision": "block", "reason": . }'

exit 0
