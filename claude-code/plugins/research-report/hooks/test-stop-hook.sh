#!/bin/bash
# ABOUTME: Test suite for stop-hook.sh (iteration engine + completion verifier for research-report workflows).
# ABOUTME: Validates iteration blocking, research budget verification, synthesis completion checks, phase transitions, and dependency errors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/stop-hook.sh"
TEST_DIR=$(mktemp -d)
PASS_COUNT=0
FAIL_COUNT=0
TEST_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test helper: run the hook with empty stdin, capture stdout+stderr+exit code
run_hook() {
  local exit_code=0
  # Run from the test directory so glob patterns resolve against it
  OUTPUT=$(cd "$TEST_DIR" && echo '{}' | bash "$HOOK_SCRIPT" 2>"$TEST_DIR/_stderr") || exit_code=$?
  STDERR=$(cat "$TEST_DIR/_stderr")
  return $exit_code
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  TEST_COUNT=$((TEST_COUNT + 1))
  if [ "$actual" -eq "$expected" ]; then
    echo -e "  ${GREEN}PASS${NC}: $test_name (exit code $actual)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $test_name (expected exit $expected, got $actual)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_output_empty() {
  local output="$1"
  local test_name="$2"
  TEST_COUNT=$((TEST_COUNT + 1))
  if [ -z "$output" ]; then
    echo -e "  ${GREEN}PASS${NC}: $test_name (output is empty)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $test_name (expected empty output, got: $output)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_output_contains() {
  local output="$1"
  local expected="$2"
  local test_name="$3"
  TEST_COUNT=$((TEST_COUNT + 1))
  if echo "$output" | grep -q "$expected"; then
    echo -e "  ${GREEN}PASS${NC}: $test_name (contains '$expected')"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $test_name (expected to contain '$expected')"
    if [ ${#output} -lt 500 ]; then
      echo "    Got: $output"
    else
      echo "    Got (first 500 chars): ${output:0:500}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_valid_json() {
  local output="$1"
  local test_name="$2"
  TEST_COUNT=$((TEST_COUNT + 1))
  if echo "$output" | jq . > /dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}: $test_name (valid JSON)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $test_name (invalid JSON)"
    echo "    Got: $output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_field() {
  local output="$1"
  local jq_path="$2"
  local expected="$3"
  local test_name="$4"
  TEST_COUNT=$((TEST_COUNT + 1))
  local actual
  actual=$(echo "$output" | jq -r "$jq_path" 2>/dev/null || echo "JQ_ERROR")
  if [ "$actual" = "$expected" ]; then
    echo -e "  ${GREEN}PASS${NC}: $test_name ($jq_path = '$expected')"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $test_name ($jq_path expected '$expected', got '$actual')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Helper: create a research-report state file at .plugin-state/ path
create_state() {
  local topic="$1"
  local status="$2"
  local total_research="$3"
  local research_budget="$4"
  local iteration="${5:-10}"
  local command="${6:-/research-report:research '$topic' 'test prompt' --research-iterations $research_budget}"
  local current_phase="${7:-Phase R: Research}"
  local synthesis_iteration="${8:-}"
  mkdir -p "$TEST_DIR/.plugin-state"
  {
    echo "---"
    echo "workflow_type: research-report"
    echo "name: $topic"
    echo "status: $status"
    echo "current_phase: \"$current_phase\""
    echo "iteration: $iteration"
    echo "total_iterations_research: $total_research"
    echo "sources_cited: 30"
    echo "findings_count: 15"
    echo "current_research_strategy: wide-exploration"
    echo "research_budget: $research_budget"
    if [ -n "$synthesis_iteration" ]; then
      echo "synthesis_iteration: $synthesis_iteration"
    fi
    echo "command: |"
    echo "  $command"
    echo "---"
    echo ""
    echo "# Research Report Workflow State: $topic"
  } > "$TEST_DIR/.plugin-state/research-report-$topic-state.md"
}

# Reset test directory between tests
reset_test_dir() {
  rm -rf "$TEST_DIR/.plugin-state"
  mkdir -p "$TEST_DIR/.plugin-state"
}

echo "========================================"
echo "Testing stop-hook.sh (research-report)"
echo "========================================"
echo ""

# ---- Prerequisite checks ----
echo "--- Prerequisite checks ---"
TEST_COUNT=$((TEST_COUNT + 1))
if command -v yq &>/dev/null; then
  echo -e "  ${GREEN}PASS${NC}: yq is installed"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: yq is not installed (required for hook)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))
if command -v jq &>/dev/null; then
  echo -e "  ${GREEN}PASS${NC}: jq is installed"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: jq is not installed (required for hook)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# TEST 1: No state files → exit 0, no output
# ==================================================================
echo "--- Test 1: No active state — exit 0, no output ---"
reset_test_dir
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when no state files"
assert_output_empty "$OUTPUT" "no output when no state files"
echo ""

# ==================================================================
# TEST 2: status: in_progress → block JSON with command as reason
# ==================================================================
echo "--- Test 2: status: in_progress — block with command ---"
reset_test_dir
create_state "my-topic" "in_progress" 5 50 10 "/research-report:research 'my-topic' 'test prompt' --research-iterations 50"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "/research-report:research" "reason contains the command"
assert_output_contains "$OUTPUT" "systemMessage" "has systemMessage field"
echo ""

# ==================================================================
# TEST 3: iteration incremented in state file after block
# ==================================================================
echo "--- Test 3: iteration incremented after block (10 → 11) ---"
reset_test_dir
create_state "inc-test" "in_progress" 5 50 10
EXIT_CODE=0
run_hook || EXIT_CODE=$?
# Read back the state file and check iteration was incremented from 10 to 11
ITERATION_AFTER=$(yq --front-matter=extract '.iteration' "$TEST_DIR/.plugin-state/research-report-inc-test-state.md" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$ITERATION_AFTER" = "11" ]; then
  echo -e "  ${GREEN}PASS${NC}: iteration incremented from 10 to 11"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: iteration expected 11, got $ITERATION_AFTER"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# TEST 4: Corrupt iteration (non-numeric) → exit 0 with stderr warning
# ==================================================================
echo "--- Test 4: Corrupt iteration (non-numeric) — exit 0 with warning ---"
reset_test_dir
mkdir -p "$TEST_DIR/.plugin-state"
cat > "$TEST_DIR/.plugin-state/research-report-corrupt-state.md" << 'CORRUPTEOF'
---
workflow_type: research-report
name: corrupt
status: in_progress
current_phase: "Phase R: Research"
iteration: banana
total_iterations_research: 5
research_budget: 50
command: |
  /research-report:research 'corrupt' 'test'
---

# State
CORRUPTEOF
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 on corrupt iteration"
assert_output_empty "$OUTPUT" "no JSON output on corrupt iteration"
assert_output_contains "$STDERR" "iteration" "stderr warns about iteration"
echo ""

# ==================================================================
# TEST 5: complete + budget fulfilled + synthesis done → exit 0
# ==================================================================
echo "--- Test 5: Complete + budget fulfilled + synthesis done — allow stop ---"
reset_test_dir
create_state "research-done" "complete" 50 50 40 "/research-report:research 'research-done' 'test'" "Phase S: Synthesis" 4
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
echo ""

# ==================================================================
# TEST 6: complete + budget NOT fulfilled → block
# ==================================================================
echo "--- Test 6: Complete + budget NOT fulfilled — block ---"
reset_test_dir
create_state "research-short" "complete" 20 50 30 "/research-report:research 'research-short' 'test'" "Phase S: Synthesis" 3
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "research" "mentions research budget"
echo ""

# ==================================================================
# TEST 7: complete + budget fulfilled but synthesis_iteration < 3 → block
# ==================================================================
echo "--- Test 7: Complete + budget fulfilled but synthesis < 4 — block ---"
reset_test_dir
create_state "synth-short" "complete" 50 50 40 "/research-report:research 'synth-short' 'test'" "Phase S: Synthesis" 1
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "Synthesis not complete" "mentions synthesis not complete"
echo ""

# ==================================================================
# TEST 8: complete + budget fulfilled + synthesis done → state file cleaned up
# ==================================================================
echo "--- Test 8: Complete + all verified — state file cleaned up ---"
reset_test_dir
create_state "cleanup-test" "complete" 50 50 40 "/research-report:research 'cleanup-test' 'test'" "Phase S: Synthesis" 4
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
# Verify state file was deleted
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.plugin-state/research-report-cleanup-test-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# TEST 9: Phase R → Phase S safety net transition
# ==================================================================
echo "--- Test 9: Phase R → Phase S safety net (in_progress + budget reached + still Phase R) ---"
reset_test_dir
create_state "phase-transition" "in_progress" 50 50 40 "/research-report:research 'phase-transition' 'test'" "Phase R: Research"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
# After the hook runs, the phase should have been changed to Phase S
PHASE_AFTER=$(yq --front-matter=extract '.current_phase' "$TEST_DIR/.plugin-state/research-report-phase-transition-state.md" 2>/dev/null)
SYNTH_AFTER=$(yq --front-matter=extract '.synthesis_iteration' "$TEST_DIR/.plugin-state/research-report-phase-transition-state.md" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$PHASE_AFTER" = "Phase S: Synthesis" ]; then
  echo -e "  ${GREEN}PASS${NC}: phase transitioned to Phase S: Synthesis"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: phase expected 'Phase S: Synthesis', got '$PHASE_AFTER'"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$SYNTH_AFTER" = "1" ]; then
  echo -e "  ${GREEN}PASS${NC}: synthesis_iteration set to 1"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: synthesis_iteration expected 1, got '$SYNTH_AFTER'"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
# Should still block (iteration continues)
assert_valid_json "$OUTPUT" "output is valid JSON after phase transition"
assert_json_field "$OUTPUT" '.decision' "block" "still blocks after phase transition"
echo ""

# ==================================================================
# TEST 10: Missing yq → exit 2
# ==================================================================
echo "--- Test 10: Missing yq — exit 2 ---"
TEMP_BIN="$TEST_DIR/_no_yq_bin"
mkdir -p "$TEMP_BIN"
for cmd in bash cat git sed mv mktemp mkdir date jq grep head echo command; do
  CMD_PATH=$(which "$cmd" 2>/dev/null) && ln -sf "$CMD_PATH" "$TEMP_BIN/$cmd" 2>/dev/null || true
done
for cmd in /usr/bin/env /bin/bash /bin/cat /bin/mkdir /bin/mv /bin/sed; do
  [ -f "$cmd" ] && ln -sf "$cmd" "$TEMP_BIN/$(basename "$cmd")" 2>/dev/null || true
done
EXIT_CODE=0
BASH_PATH=$(which bash)
OUTPUT=$(cd "$TEST_DIR" && echo '{}' | PATH="$TEMP_BIN" "$BASH_PATH" "$HOOK_SCRIPT" 2>"$TEST_DIR/_stderr") || EXIT_CODE=$?
STDERR=$(cat "$TEST_DIR/_stderr")
assert_exit_code 2 "$EXIT_CODE" "exit code 2 when yq missing"
assert_output_contains "$STDERR" "yq" "stderr mentions yq"
echo ""

# ==================================================================
# TEST 11: Missing jq → exit 2
# ==================================================================
echo "--- Test 11: Missing jq — exit 2 ---"
TEMP_BIN2="$TEST_DIR/_no_jq_bin"
mkdir -p "$TEMP_BIN2"
for cmd in bash cat git sed mv mktemp mkdir date yq grep head echo command; do
  CMD_PATH=$(which "$cmd" 2>/dev/null) && ln -sf "$CMD_PATH" "$TEMP_BIN2/$cmd" 2>/dev/null || true
done
for cmd in /usr/bin/env /bin/bash /bin/cat /bin/mkdir /bin/mv /bin/sed; do
  [ -f "$cmd" ] && ln -sf "$cmd" "$TEMP_BIN2/$(basename "$cmd")" 2>/dev/null || true
done
EXIT_CODE=0
OUTPUT=$(cd "$TEST_DIR" && echo '{}' | PATH="$TEMP_BIN2" "$BASH_PATH" "$HOOK_SCRIPT" 2>"$TEST_DIR/_stderr") || EXIT_CODE=$?
STDERR=$(cat "$TEST_DIR/_stderr")
assert_exit_code 2 "$EXIT_CODE" "exit code 2 when jq missing"
assert_output_contains "$STDERR" "jq" "stderr mentions jq"
echo ""

# ---- Summary ----
echo "========================================"
echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
