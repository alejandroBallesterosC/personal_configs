#!/bin/bash
# ABOUTME: Runs tests based on scope defined in .tdd-test-scope file
# ABOUTME: Supports file paths, keywords, and runner-specific options with prefixes

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if .tdd-test-scope exists
SCOPE_FILE=".tdd-test-scope"
if [ ! -f "$SCOPE_FILE" ]; then
    # No scope file = no tests to run (Claude hasn't requested verification)
    exit 0
fi

SCOPE=$(cat "$SCOPE_FILE")

# Handle special cases
if [ "$SCOPE" = "none" ] || [ -z "$SCOPE" ]; then
    rm -f "$SCOPE_FILE"
    exit 0
fi

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

# Run appropriate test command
case "$DETECTED" in
    pytest)
        run_pytest
        ;;
    vitest)
        run_vitest
        ;;
    jest)
        run_jest
        ;;
    playwright)
        run_playwright
        ;;
    go)
        run_go
        ;;
    cargo)
        run_cargo
        ;;
    rspec)
        run_rspec
        ;;
    minitest)
        run_minitest
        ;;
    mix)
        run_mix
        ;;
    *)
        echo "No supported test runner detected"
        exit 0
        ;;
esac

# Clean up scope file after running (one-shot verification)
rm -f "$SCOPE_FILE"
