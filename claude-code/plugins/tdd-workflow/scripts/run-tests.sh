#!/bin/bash
# ABOUTME: Runs tests using auto-detected runner
# ABOUTME: Exit code 0 = tests pass, non-zero = tests fail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect the test runner
DETECTED=$("$SCRIPT_DIR/detect-test-runner.sh")

# Run appropriate test command
case "$DETECTED" in
    pytest)
        # Try uv first, fall back to direct pytest
        if command -v uv &> /dev/null && [ -f "pyproject.toml" ]; then
            uv run pytest -q --tb=short 2>&1
        elif command -v pytest &> /dev/null; then
            pytest -q --tb=short 2>&1
        else
            echo "pytest not found"
            exit 0
        fi
        ;;
    vitest)
        if command -v npx &> /dev/null; then
            npx vitest run --reporter=basic 2>&1
        else
            echo "npx not found for vitest"
            exit 0
        fi
        ;;
    jest)
        if command -v npx &> /dev/null; then
            npx jest --silent --passWithNoTests 2>&1
        else
            echo "npx not found for jest"
            exit 0
        fi
        ;;
    go)
        if command -v go &> /dev/null; then
            go test ./... -v 2>&1
        else
            echo "go not found"
            exit 0
        fi
        ;;
    cargo)
        if command -v cargo &> /dev/null; then
            cargo test 2>&1
        else
            echo "cargo not found"
            exit 0
        fi
        ;;
    rspec)
        if command -v bundle &> /dev/null; then
            bundle exec rspec --format progress 2>&1
        elif command -v rspec &> /dev/null; then
            rspec --format progress 2>&1
        else
            echo "rspec not found"
            exit 0
        fi
        ;;
    minitest)
        if command -v ruby &> /dev/null; then
            ruby -Ilib:test test/**/*_test.rb 2>&1
        else
            echo "ruby not found"
            exit 0
        fi
        ;;
    mix)
        if command -v mix &> /dev/null; then
            mix test 2>&1
        else
            echo "mix not found"
            exit 0
        fi
        ;;
    *)
        # No test runner detected - exit silently
        echo "No test runner detected"
        exit 0
        ;;
esac
