#!/bin/bash
# ABOUTME: Test suite for stop-hook.sh (iteration engine + completion verifier) in the long-horizon-impl plugin.
# ABOUTME: Validates iteration blocking, budget verification per workflow type, feature resolution checks, and dependency errors.

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

# Helper: create a research state file at .plugin-state/ path
create_research_state() {
  local topic="$1"
  local status="$2"
  local workflow_type="$3"
  local total_research="$4"
  local research_budget="$5"
  local iteration="${6:-10}"
  local command="${7:-/long-horizon-impl:1-research-and-plan '$topic' 'test prompt' --research-iterations $research_budget}"
  mkdir -p "$TEST_DIR/.plugin-state"
  cat > "$TEST_DIR/.plugin-state/lhi-$topic-research-state.md" << STATEEOF
---
workflow_type: $workflow_type
name: $topic
status: $status
current_phase: "Phase A: Research"
iteration: $iteration
total_iterations_research: $total_research
sources_cited: 30
findings_count: 15
current_research_strategy: wide-exploration
research_budget: $research_budget
command: |
  $command
---

# Long-Horizon-Impl Workflow State: $topic
STATEEOF
}

# Helper: create an implementation state file at .plugin-state/ path
create_implementation_state() {
  local topic="$1"
  local status="$2"
  local workflow_type="$3"
  local total_research="$4"
  local research_budget="$5"
  local total_planning="$6"
  local planning_budget="$7"
  local iteration="${8:-25}"
  local command="${9:-/long-horizon-impl:1-research-and-plan '$topic' 'test prompt' --research-iterations $research_budget --plan-iterations $planning_budget}"
  mkdir -p "$TEST_DIR/.plugin-state"
  cat > "$TEST_DIR/.plugin-state/lhi-$topic-implementation-state.md" << STATEEOF
---
workflow_type: $workflow_type
name: $topic
status: $status
current_phase: "Phase B: Planning"
iteration: $iteration
total_iterations_research: $total_research
total_iterations_planning: $total_planning
total_iterations_coding: 5
research_budget: $research_budget
planning_budget: $planning_budget
features_total: 5
features_complete: 3
features_failed: 1
command: |
  $command
---

# Long-Horizon-Impl Workflow State: $topic
STATEEOF
}

# Helper: create a feature-list.json at .plugin-state/ path
create_feature_list() {
  local topic="$1"
  # $2 is the JSON content
  echo "$2" > "$TEST_DIR/.plugin-state/lhi-$topic-feature-list.json"
}

# Reset test directory between tests
reset_test_dir() {
  rm -rf "$TEST_DIR/.plugin-state"
  mkdir -p "$TEST_DIR/.plugin-state"
}

echo "========================================"
echo "Testing stop-hook.sh (long-horizon-impl)"
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
# TEST 1: No state files → exit 0
# ==================================================================
echo "--- Test 1: No active state — exit 0, no output ---"
reset_test_dir
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when no state files"
assert_output_empty "$OUTPUT" "no output when no state files"
echo ""

# ==================================================================
# TEST 2: in_progress + lhi-research-plan → block, command re-fed
# ==================================================================
echo "--- Test 2: in_progress + lhi-research-plan — block with command ---"
reset_test_dir
create_research_state "my-topic" "in_progress" "lhi-research-plan" 5 50 10 "/long-horizon-impl:1-research-and-plan 'my-topic' 'test prompt' --research-iterations 50"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "1-research-and-plan" "reason contains the command"
assert_output_contains "$OUTPUT" "systemMessage" "has systemMessage field"
echo ""

# ==================================================================
# TEST 3: in_progress + lhi-implement → exit 0 (ralph-loop pass-through)
# ==================================================================
echo "--- Test 3: in_progress + lhi-implement — exit 0 (ralph-loop pass-through) ---"
reset_test_dir
create_implementation_state "impl-topic" "in_progress" "lhi-implement" 0 0 0 0 25 "/long-horizon-impl:2-implement 'impl-topic'"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (pass-through to ralph-loop)"
assert_output_empty "$OUTPUT" "no output (ralph-loop handles iteration)"
echo ""

# ==================================================================
# TEST 4: waiting_for_input → exit 0
# ==================================================================
echo "--- Test 4: waiting_for_input — exit 0 ---"
reset_test_dir
create_research_state "waiting-topic" "waiting_for_input" "lhi-research-plan" 0 50
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (pausing for human input)"
assert_output_empty "$OUTPUT" "no output when waiting for input"
echo ""

# ==================================================================
# TEST 5: Iteration increment (10 → 11)
# ==================================================================
echo "--- Test 5: Iteration incremented after block ---"
reset_test_dir
create_research_state "inc-test" "in_progress" "lhi-research-plan" 5 50 10
EXIT_CODE=0
run_hook || EXIT_CODE=$?
# Read back the state file and check iteration was incremented from 10 to 11
ITERATION_AFTER=$(yq --front-matter=extract '.iteration' "$TEST_DIR/.plugin-state/lhi-inc-test-research-state.md" 2>/dev/null)
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
# TEST 6: Corrupt iteration (non-numeric) → exit 0 with stderr warning
# ==================================================================
echo "--- Test 6: Corrupt iteration (non-numeric) — exit 0 with warning ---"
reset_test_dir
mkdir -p "$TEST_DIR/.plugin-state"
cat > "$TEST_DIR/.plugin-state/lhi-corrupt-research-state.md" << 'CORRUPTEOF'
---
workflow_type: lhi-research-plan
name: corrupt
status: in_progress
current_phase: "Phase A: Research"
iteration: banana
total_iterations_research: 5
research_budget: 50
command: |
  /long-horizon-impl:1-research-and-plan 'corrupt' 'test'
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
# TEST 7: complete + lhi-research-plan + both budgets met → exit 0
# ==================================================================
echo "--- Test 7: complete + lhi-research-plan + both budgets met — allow stop ---"
reset_test_dir
create_implementation_state "rp-done" "complete" "lhi-research-plan" 40 40 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when both budgets fulfilled"
assert_output_empty "$OUTPUT" "no output when both budgets fulfilled"
echo ""

# ==================================================================
# TEST 8: complete + lhi-research-plan + research budget not met → block
# ==================================================================
echo "--- Test 8: complete + lhi-research-plan + research budget not met — block ---"
reset_test_dir
create_implementation_state "rp-research-short" "complete" "lhi-research-plan" 20 40 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "research" "mentions research budget issue"
echo ""

# ==================================================================
# TEST 9: complete + lhi-research-plan + planning budget not met → block
# ==================================================================
echo "--- Test 9: complete + lhi-research-plan + planning budget not met — block ---"
reset_test_dir
create_implementation_state "rp-plan-short" "complete" "lhi-research-plan" 40 40 10 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "planning" "mentions planning budget issue"
echo ""

# ==================================================================
# TEST 10: complete + lhi-implement + all features resolved → exit 0
# ==================================================================
echo "--- Test 10: complete + lhi-implement + all features resolved — allow stop ---"
reset_test_dir
create_implementation_state "impl-done" "complete" "lhi-implement" 0 0 0 0 25 "/long-horizon-impl:2-implement 'impl-done'"
create_feature_list "impl-done" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": true, "failed": false},
    {"id": "F003", "name": "feat3", "passes": false, "failed": true}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all features resolved"
assert_output_empty "$OUTPUT" "no output when all features resolved"
echo ""

# ==================================================================
# TEST 11: complete + lhi-implement + features not resolved → block
# ==================================================================
echo "--- Test 11: complete + lhi-implement + features NOT all resolved — block ---"
reset_test_dir
create_implementation_state "impl-pending" "complete" "lhi-implement" 0 0 0 0 25 "/long-horizon-impl:2-implement 'impl-pending'"
create_feature_list "impl-pending" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": false, "failed": false}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "feature" "mentions unresolved features"
echo ""

# ==================================================================
# TEST 12: Implementation state priority over research state
# ==================================================================
echo "--- Test 12: Implementation state takes priority over research state ---"
reset_test_dir
create_research_state "priority-test" "in_progress" "lhi-research-plan" 5 50
create_implementation_state "priority-test" "in_progress" "lhi-research-plan" 50 50 20 20 25 "/long-horizon-impl:1-research-and-plan 'priority-test' 'test' --research-iterations 50 --plan-iterations 20"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
# The command should reference the implementation state, not research
assert_output_contains "$OUTPUT" "1-research-and-plan" "blocks with implementation state command"
echo ""

# ==================================================================
# TEST 13: All complete → exit 0, state files cleaned up
# ==================================================================
echo "--- Test 13: All complete — exit 0, state files cleaned up ---"
reset_test_dir
create_research_state "cleanup-test" "complete" "lhi-research-plan" 50 50
create_implementation_state "cleanup-test" "complete" "lhi-research-plan" 50 50 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
# Verify state files were deleted
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.plugin-state/lhi-cleanup-test-implementation-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: implementation state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: implementation state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.plugin-state/lhi-cleanup-test-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# TEST 14: Missing yq → exit 2
# ==================================================================
echo "--- Test 14: Missing yq — exit 2 ---"
# Create a temp bin with everything EXCEPT yq, using symlinks
TEMP_BIN="$TEST_DIR/_no_yq_bin"
mkdir -p "$TEMP_BIN"
# Symlink essential binaries: bash, cat, git, sed, mv, mktemp, mkdir, date, jq, grep, head, echo, command
for cmd in bash cat git sed mv mktemp mkdir date jq grep head echo command; do
  CMD_PATH=$(which "$cmd" 2>/dev/null) && ln -sf "$CMD_PATH" "$TEMP_BIN/$cmd" 2>/dev/null || true
done
# Ensure /usr/bin essentials are available too
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
# TEST 15: Missing jq → exit 2
# ==================================================================
echo "--- Test 15: Missing jq — exit 2 ---"
TEMP_BIN2="$TEST_DIR/_no_jq_bin"
mkdir -p "$TEMP_BIN2"
# Symlink everything EXCEPT jq
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

# ==================================================================
# TEST 16: Stale complete impl state must not kill in_progress research
# ==================================================================
echo "--- Test 16: Stale complete impl state must not kill in_progress research ---"
reset_test_dir
# Create a research state that is in_progress (active work)
create_research_state "edge-case" "in_progress" "lhi-research-plan" 5 50 10 "/long-horizon-impl:1-research-and-plan 'edge-case' 'test prompt' --research-iterations 50"
# Create a stale implementation state that is complete (leftover from previous run)
create_implementation_state "edge-case" "complete" "lhi-research-plan" 50 50 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block (should continue research)"
assert_output_contains "$OUTPUT" "1-research-and-plan" "blocks with research command (not cleanup)"
# Verify research state file still exists (not cleaned up)
TEST_COUNT=$((TEST_COUNT + 1))
if [ -f "$TEST_DIR/.plugin-state/lhi-edge-case-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file preserved (not deleted by stale impl cleanup)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file was deleted (stale impl state killed active research)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# TEST 17: B0 pause — impl state waiting_for_input + research state complete → exit 0
# ==================================================================
echo "--- Test 17: B0 pause — impl waiting_for_input + research complete — allow stop ---"
reset_test_dir
# Research phase is complete
create_research_state "b0-test" "complete" "lhi-research-plan" 30 30
# Implementation state created at Phase A→B transition, paused at B0
create_implementation_state "b0-test" "waiting_for_input" "lhi-research-plan" 30 30 1 20 31 "/long-horizon-impl:1-research-and-plan 'b0-test' 'test prompt' --research-iterations 30 --plan-iterations 20"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (B0 pause allows stop)"
assert_output_empty "$OUTPUT" "no output when paused at B0"
# Verify state files are preserved (not cleaned up)
TEST_COUNT=$((TEST_COUNT + 1))
if [ -f "$TEST_DIR/.plugin-state/lhi-b0-test-implementation-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: implementation state file preserved during B0 pause"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: implementation state file was deleted during B0 pause"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))
if [ -f "$TEST_DIR/.plugin-state/lhi-b0-test-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file preserved during B0 pause"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file was deleted during B0 pause"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ---- Summary ----
echo "========================================"
echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
