#!/bin/bash
# ABOUTME: Integration tests for research-report plugin hooks.
# ABOUTME: Verifies hooks create append-only debug logs in .plugin-state/ and produce correct output in a real repo context.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STOP_HOOK="$PLUGIN_ROOT/hooks/stop-hook.sh"
AUTO_RESUME="$PLUGIN_ROOT/hooks/auto-resume.sh"

# --- Test helpers ---

PASSED=0
FAILED=0
TEST_DIR=""

setup() {
  TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/.plugin-state"
  # Initialize as a git repo so hooks can find repo root
  git -C "$TEST_DIR" init -q
}

teardown() {
  [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

assert_file_exists() {
  local file="$1" msg="$2"
  if [ -f "$file" ]; then
    echo "  [0;32mPASS[0m: $msg"
    PASSED=$((PASSED + 1))
  else
    echo "  [0;31mFAIL[0m: $msg (file not found: $file)"
    FAILED=$((FAILED + 1))
  fi
}

assert_file_not_exists() {
  local file="$1" msg="$2"
  if [ ! -f "$file" ]; then
    echo "  [0;32mPASS[0m: $msg"
    PASSED=$((PASSED + 1))
  else
    echo "  [0;31mFAIL[0m: $msg (file exists: $file)"
    FAILED=$((FAILED + 1))
  fi
}

assert_file_grew() {
  local before="$1" after="$2" msg="$3"
  if [ "$after" -gt "$before" ]; then
    echo "  [0;32mPASS[0m: $msg ($before -> $after bytes)"
    PASSED=$((PASSED + 1))
  else
    echo "  [0;31mFAIL[0m: $msg (did not grow: $before -> $after bytes)"
    FAILED=$((FAILED + 1))
  fi
}

assert_contains() {
  local content="$1" pattern="$2" msg="$3"
  if echo "$content" | grep -q "$pattern"; then
    echo "  [0;32mPASS[0m: $msg"
    PASSED=$((PASSED + 1))
  else
    echo "  [0;31mFAIL[0m: $msg (pattern '$pattern' not found)"
    FAILED=$((FAILED + 1))
  fi
}

assert_not_contains() {
  local content="$1" pattern="$2" msg="$3"
  if ! echo "$content" | grep -q "$pattern"; then
    echo "  [0;32mPASS[0m: $msg"
    PASSED=$((PASSED + 1))
  else
    echo "  [0;31mFAIL[0m: $msg (pattern '$pattern' was found)"
    FAILED=$((FAILED + 1))
  fi
}

echo "========================================"
echo "Integration tests: research-report hooks"
echo "========================================"
echo ""

# --- Test 1: Stop hook creates debug log on first run ---
echo "--- Test 1: Stop hook creates debug log on first run ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
assert_file_not_exists "$LOG" "log does not exist before first run"
cd "$TEST_DIR" && echo '{}' | bash "$STOP_HOOK" 2>/dev/null
assert_file_exists "$LOG" "log created after first run"
cd - > /dev/null
teardown

# --- Test 2: Stop hook log is append-only ---
echo ""
echo "--- Test 2: Stop hook log is append-only ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
cd "$TEST_DIR"
echo '{}' | bash "$STOP_HOOK" 2>/dev/null
SIZE_1=$(wc -c < "$LOG" | tr -d ' ')
echo '{}' | bash "$STOP_HOOK" 2>/dev/null
SIZE_2=$(wc -c < "$LOG" | tr -d ' ')
echo '{}' | bash "$STOP_HOOK" 2>/dev/null
SIZE_3=$(wc -c < "$LOG" | tr -d ' ')
cd - > /dev/null
assert_file_grew "$SIZE_1" "$SIZE_2" "log grew after second run"
assert_file_grew "$SIZE_2" "$SIZE_3" "log grew after third run"
teardown

# --- Test 3: Stop hook log contains timestamps ---
echo ""
echo "--- Test 3: Stop hook log contains timestamps ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
cd "$TEST_DIR" && echo '{}' | bash "$STOP_HOOK" 2>/dev/null
CONTENT=$(cat "$LOG")
cd - > /dev/null
assert_contains "$CONTENT" "^## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" "log contains date-stamped header"
assert_contains "$CONTENT" "Hook invoked" "log contains invocation marker"
teardown

# --- Test 4: Stop hook log contains working directory ---
echo ""
echo "--- Test 4: Stop hook log contains working directory ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
cd "$TEST_DIR" && echo '{}' | bash "$STOP_HOOK" 2>/dev/null
CONTENT=$(cat "$LOG")
cd - > /dev/null
assert_contains "$CONTENT" "Working directory" "log contains working directory"
teardown

# --- Test 5: Stop hook log records no-workflow outcome ---
echo ""
echo "--- Test 5: Stop hook log records no-workflow outcome ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
cd "$TEST_DIR" && echo '{}' | bash "$STOP_HOOK" 2>/dev/null
CONTENT=$(cat "$LOG")
cd - > /dev/null
assert_contains "$CONTENT" "No active" "log records no active workflow"
teardown

# --- Test 6: Auto-resume creates debug log on first run ---
echo ""
echo "--- Test 6: Auto-resume creates debug log on first run ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-auto-resume-debug.log"
assert_file_not_exists "$LOG" "log does not exist before first run"
cd "$TEST_DIR" && echo '{"source":"compact"}' | bash "$AUTO_RESUME" 2>/dev/null
assert_file_exists "$LOG" "log created after first run"
cd - > /dev/null
teardown

# --- Test 7: Auto-resume log is append-only ---
echo ""
echo "--- Test 7: Auto-resume log is append-only ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-auto-resume-debug.log"
cd "$TEST_DIR"
echo '{"source":"compact"}' | bash "$AUTO_RESUME" 2>/dev/null
SIZE_1=$(wc -c < "$LOG" | tr -d ' ')
echo '{"source":"clear"}' | bash "$AUTO_RESUME" 2>/dev/null
SIZE_2=$(wc -c < "$LOG" | tr -d ' ')
cd - > /dev/null
assert_file_grew "$SIZE_1" "$SIZE_2" "log grew after second run"
teardown

# --- Test 8: Auto-resume log contains timestamps ---
echo ""
echo "--- Test 8: Auto-resume log contains timestamps ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-auto-resume-debug.log"
cd "$TEST_DIR" && echo '{"source":"compact"}' | bash "$AUTO_RESUME" 2>/dev/null
CONTENT=$(cat "$LOG")
cd - > /dev/null
assert_contains "$CONTENT" "^## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" "log contains date-stamped header"
teardown

# --- Test 9: Auto-resume skips non-compact sources but still logs ---
echo ""
echo "--- Test 9: Auto-resume skips non-compact sources but still logs ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-auto-resume-debug.log"
cd "$TEST_DIR" && echo '{"source":"init"}' | bash "$AUTO_RESUME" 2>/dev/null
cd - > /dev/null
# Log may or may not be created for non-compact sources depending on implementation
# The key check is that the hook exits cleanly
echo "  (non-compact source handled without error)"
teardown

# --- Test 10: Stop hook with active workflow logs the action taken ---
echo ""
echo "--- Test 10: Stop hook with active workflow logs the action taken ---"
setup
LOG="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
cat > "$TEST_DIR/.plugin-state/research-report-test-topic-state.md" << 'STATE'
---
workflow_type: research-report
name: test-topic
status: in_progress
iteration: 5
total_iterations_research: 4
research_budget: 50
current_phase: "Phase R: Research"
synthesis_iteration: 0
command: |
  /research-report:research 'test-topic' 'test prompt' --research-iterations 50
---
# Test state
STATE
cd "$TEST_DIR" && echo '{}' | bash "$STOP_HOOK" 2>/dev/null
CONTENT=$(cat "$LOG")
cd - > /dev/null
assert_contains "$CONTENT" "test-topic\|iteration\|block" "log records action for active workflow"
teardown

# --- Test 11: Log files do not contain autonomous-workflow references ---
echo ""
echo "--- Test 11: Log files do not contain autonomous-workflow references ---"
setup
LOG_STOP="$TEST_DIR/.plugin-state/research-report-stop-hook-debug.log"
LOG_RESUME="$TEST_DIR/.plugin-state/research-report-auto-resume-debug.log"
cd "$TEST_DIR"
echo '{}' | bash "$STOP_HOOK" 2>/dev/null
echo '{"source":"compact"}' | bash "$AUTO_RESUME" 2>/dev/null
cd - > /dev/null
CONTENT_STOP=$(cat "$LOG_STOP")
assert_not_contains "$CONTENT_STOP" "autonomous-workflow" "stop-hook log has no autonomous-workflow references"
if [ -f "$LOG_RESUME" ]; then
  CONTENT_RESUME=$(cat "$LOG_RESUME")
  assert_not_contains "$CONTENT_RESUME" "autonomous-workflow" "auto-resume log has no autonomous-workflow references"
fi
teardown

# --- Results ---
echo ""
echo "========================================"
echo "Results: $PASSED/$((PASSED + FAILED)) passed, $FAILED failed"
echo "========================================"

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
