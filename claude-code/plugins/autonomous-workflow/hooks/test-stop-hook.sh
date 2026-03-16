#!/bin/bash
# ABOUTME: Test suite for stop-hook.sh (iteration engine + completion verifier).
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

# Helper: create a research state file at .claude/ path
create_research_state() {
  local topic="$1"
  local status="$2"
  local workflow_type="$3"
  local total_research="$4"
  local research_budget="$5"
  local iteration="${6:-10}"
  local command="${7:-/autonomous-workflow:research '$topic' 'test prompt' --research-iterations $research_budget}"
  mkdir -p "$TEST_DIR/.claude"
  cat > "$TEST_DIR/.claude/autonomous-$topic-research-state.md" << STATEEOF
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

# Autonomous Workflow State: $topic
STATEEOF
}

# Helper: create an implementation state file at .claude/ path
create_implementation_state() {
  local topic="$1"
  local status="$2"
  local workflow_type="$3"
  local total_research="$4"
  local research_budget="$5"
  local total_planning="$6"
  local planning_budget="$7"
  local iteration="${8:-25}"
  local command="${9:-/autonomous-workflow:full-auto '$topic' 'test prompt' --research-iterations $research_budget --plan-iterations $planning_budget}"
  mkdir -p "$TEST_DIR/.claude"
  cat > "$TEST_DIR/.claude/autonomous-$topic-implementation-state.md" << STATEEOF
---
workflow_type: $workflow_type
name: $topic
status: $status
current_phase: "Phase C: Implementation"
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

# Autonomous Workflow State: $topic
STATEEOF
}

# Helper: create a feature-list.json at .claude/ path
create_feature_list() {
  local topic="$1"
  # $2 is the JSON content
  echo "$2" > "$TEST_DIR/.claude/autonomous-$topic-feature-list.json"
}

# Reset test directory between tests
reset_test_dir() {
  rm -rf "$TEST_DIR/.claude"
  mkdir -p "$TEST_DIR/.claude"
}

echo "========================================"
echo "Testing stop-hook.sh"
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
# ITERATION ENGINE TESTS
# ==================================================================

# ---- Test 1: No active state → exit 0, no output ----
echo "--- Test 1: No active state — exit 0, no output ---"
reset_test_dir
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when no state files"
assert_output_empty "$OUTPUT" "no output when no state files"
echo ""

# ---- Test 2: status: in_progress → block JSON with command as reason ----
echo "--- Test 2: status: in_progress — block with command ---"
reset_test_dir
create_research_state "my-topic" "in_progress" "autonomous-research" 5 50 10 "/autonomous-workflow:research 'my-topic' 'test prompt' --research-iterations 50"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "/autonomous-workflow:research" "reason contains the command"
assert_output_contains "$OUTPUT" "systemMessage" "has systemMessage field"
echo ""

# ---- Test 3: iteration incremented in state file after block ----
echo "--- Test 3: iteration incremented after block ---"
reset_test_dir
create_research_state "inc-test" "in_progress" "autonomous-research" 5 50 10
EXIT_CODE=0
run_hook || EXIT_CODE=$?
# Read back the state file and check iteration was incremented from 10 to 11
ITERATION_AFTER=$(yq --front-matter=extract '.iteration' "$TEST_DIR/.claude/autonomous-inc-test-research-state.md" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$ITERATION_AFTER" = "11" ]; then
  echo -e "  ${GREEN}PASS${NC}: iteration incremented from 10 to 11"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: iteration expected 11, got $ITERATION_AFTER"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ---- Test 4: Corrupt iteration (non-numeric) → exit 0 with stderr warning ----
echo "--- Test 4: Corrupt iteration (non-numeric) — exit 0 with warning ---"
reset_test_dir
mkdir -p "$TEST_DIR/.claude"
cat > "$TEST_DIR/.claude/autonomous-corrupt-research-state.md" << 'CORRUPTEOF'
---
workflow_type: autonomous-research
name: corrupt
status: in_progress
current_phase: "Phase A: Research"
iteration: banana
total_iterations_research: 5
research_budget: 50
command: |
  /autonomous-workflow:research 'corrupt' 'test'
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
# MODE 1: RESEARCH WORKFLOW COMPLETION VERIFICATION
# ==================================================================

# ---- Test 5: Research complete + budget fulfilled → exit 0 ----
echo "--- Test 5: Research complete + budget fulfilled — allow stop ---"
reset_test_dir
create_research_state "research-done" "complete" "autonomous-research" 50 50
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when research budget fulfilled"
assert_output_empty "$OUTPUT" "no output when research budget fulfilled"
echo ""

# ---- Test 6: Research complete + budget NOT fulfilled → block with error ----
echo "--- Test 6: Research complete + budget NOT fulfilled — block ---"
reset_test_dir
create_research_state "research-short" "complete" "autonomous-research" 20 50
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "research" "mentions research budget"
echo ""

# ==================================================================
# MODE 2: RESEARCH-AND-PLAN WORKFLOW COMPLETION VERIFICATION
# ==================================================================

# ---- Test 7: Research-plan complete + both budgets fulfilled → exit 0 ----
echo "--- Test 7: Research-plan complete + both budgets fulfilled — allow stop ---"
reset_test_dir
create_implementation_state "rp-done" "complete" "autonomous-research-plan" 40 40 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when both budgets fulfilled"
assert_output_empty "$OUTPUT" "no output when both budgets fulfilled"
echo ""

# ---- Test 8: Research-plan complete + research budget NOT fulfilled → block ----
echo "--- Test 8: Research-plan complete + research budget NOT fulfilled — block ---"
reset_test_dir
create_implementation_state "rp-research-short" "complete" "autonomous-research-plan" 20 40 20 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "research" "mentions research budget issue"
echo ""

# ---- Test 9: Research-plan complete + planning budget NOT fulfilled → block ----
echo "--- Test 9: Research-plan complete + planning budget NOT fulfilled — block ---"
reset_test_dir
create_implementation_state "rp-plan-short" "complete" "autonomous-research-plan" 40 40 10 20
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "planning" "mentions planning budget issue"
echo ""

# ==================================================================
# MODE 3: FULL-AUTO WORKFLOW COMPLETION VERIFICATION
# ==================================================================

# ---- Test 10: Full-auto complete + budgets fulfilled + all features resolved → exit 0 ----
echo "--- Test 10: Full-auto complete + all verified — allow stop ---"
reset_test_dir
create_implementation_state "fa-done" "complete" "autonomous-full-auto" 50 50 20 20
create_feature_list "fa-done" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": true, "failed": false},
    {"id": "F003", "name": "feat3", "passes": false, "failed": true}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
echo ""

# ---- Test 11: Full-auto complete + budgets fulfilled + features NOT all resolved → block ----
echo "--- Test 11: Full-auto complete + features NOT all resolved — block ---"
reset_test_dir
create_implementation_state "fa-features-pending" "complete" "autonomous-full-auto" 50 50 20 20
create_feature_list "fa-features-pending" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": false, "failed": false},
    {"id": "F003", "name": "feat3", "passes": false, "failed": false}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "feature" "mentions unresolved features"
echo ""

# ---- Test 12: Full-auto complete + features resolved but budgets NOT fulfilled → block ----
echo "--- Test 12: Full-auto complete + features resolved but budgets NOT fulfilled — block ---"
reset_test_dir
create_implementation_state "fa-budget-short" "complete" "autonomous-full-auto" 20 50 10 20
create_feature_list "fa-budget-short" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": true, "failed": false}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "research" "mentions budget issue"
echo ""

# ==================================================================
# MODE 4: IMPLEMENT WORKFLOW COMPLETION VERIFICATION
# ==================================================================

# ---- Test 13: Implement complete + all features resolved → exit 0 ----
echo "--- Test 13: Implement complete + all features resolved — allow stop ---"
reset_test_dir
create_implementation_state "impl-done" "complete" "autonomous-implement" 0 0 0 0 25 "/autonomous-workflow:implement 'impl-done'"
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

# ---- Test 14: Implement complete + features NOT all resolved → block ----
echo "--- Test 14: Implement complete + features NOT all resolved — block ---"
reset_test_dir
create_implementation_state "impl-pending" "complete" "autonomous-implement" 0 0 0 0 25 "/autonomous-workflow:implement 'impl-pending'"
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
# PRIORITY TESTS
# ==================================================================

# ---- Test 15: Implementation state takes priority over research state ----
echo "--- Test 15: Implementation state takes priority over research state ---"
reset_test_dir
create_research_state "priority-test" "in_progress" "autonomous-full-auto" 5 50
create_implementation_state "priority-test" "in_progress" "autonomous-full-auto" 50 50 20 20 25 "/autonomous-workflow:full-auto 'priority-test' 'test' --research-iterations 50 --plan-iterations 20"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
# The command should reference the implementation state, not research
assert_output_contains "$OUTPUT" "full-auto" "blocks with implementation state command"
echo ""

# ---- Test 16: Complete state with no active work → exit 0 ----
echo "--- Test 16: All complete state files — exit 0 ---"
reset_test_dir
create_research_state "all-done" "complete" "autonomous-research" 50 50
EXIT_CODE=0
# For this test, override the research budget check by making budget fulfilled
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when complete and budget fulfilled"
echo ""

# ==================================================================
# DEPENDENCY CHECKS
# ==================================================================

# ---- Test 17: Missing yq → exit 2 with stderr message ----
echo "--- Test 17: Missing yq — exit 2 ---"
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

# ---- Test 18: Missing jq → exit 2 with stderr message ----
echo "--- Test 18: Missing jq — exit 2 ---"
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
# STATE FILE CLEANUP TESTS
# ==================================================================

# ---- Test 19: Mode 3 complete — both state files cleaned up ----
echo "--- Test 19: Mode 3 complete — both state files cleaned up ---"
reset_test_dir
create_research_state "cleanup-test" "complete" "autonomous-full-auto" 50 50
create_implementation_state "cleanup-test" "complete" "autonomous-full-auto" 50 50 20 20
create_feature_list "cleanup-test" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false},
    {"id": "F002", "name": "feat2", "passes": true, "failed": false}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
# Verify state files were deleted
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.claude/autonomous-cleanup-test-implementation-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: implementation state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: implementation state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.claude/autonomous-cleanup-test-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ---- Test 20: Mode 1 complete — research state cleaned up, no error for missing impl state ----
echo "--- Test 20: Mode 1 complete — research-only cleanup (rm -f tolerates missing impl state) ---"
reset_test_dir
create_research_state "research-cleanup" "complete" "autonomous-research" 50 50
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when research budget fulfilled"
assert_output_empty "$OUTPUT" "no output when research budget fulfilled"
# Verify research state file was deleted
TEST_COUNT=$((TEST_COUNT + 1))
if [ ! -f "$TEST_DIR/.claude/autonomous-research-cleanup-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file was deleted"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file still exists"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
# Verify no error occurred despite missing implementation state file
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "  ${GREEN}PASS${NC}: no error from rm -f on nonexistent implementation state"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: unexpected error from cleanup"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ==================================================================
# STATE DISCOVERY EDGE CASES
# ==================================================================

# ---- Test 21: Stale complete implementation state must not kill in_progress research ----
echo "--- Test 21: Stale complete impl state must not kill in_progress research ---"
reset_test_dir
# Create a research state that is in_progress (active work)
create_research_state "edge-case" "in_progress" "autonomous-research" 5 50 10 "/autonomous-workflow:research 'edge-case' 'test prompt' --research-iterations 50"
# Create a stale implementation state that is complete (leftover from previous run)
create_implementation_state "edge-case" "complete" "autonomous-full-auto" 50 50 20 20
create_feature_list "edge-case" '{
  "features": [
    {"id": "F001", "name": "feat1", "passes": true, "failed": false}
  ]
}'
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block (should continue research)"
assert_output_contains "$OUTPUT" "research" "blocks with research command (not cleanup)"
# Verify research state file still exists (not cleaned up)
TEST_COUNT=$((TEST_COUNT + 1))
if [ -f "$TEST_DIR/.claude/autonomous-edge-case-research-state.md" ]; then
  echo -e "  ${GREEN}PASS${NC}: research state file preserved (not deleted by stale impl cleanup)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: research state file was deleted (stale impl state killed active research)"
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
