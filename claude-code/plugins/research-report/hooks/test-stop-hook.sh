#!/bin/bash
# ABOUTME: Test suite for stop-hook.sh (iteration engine + completion verifier for research-report workflows).
# ABOUTME: Validates iteration blocking, research budget verification, Phase S sub-phase completion checks, phase transitions, and dependency errors.

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

# Helper: create a research-report state file with full new schema.
# Required positional args: topic, status, total_research, research_budget, iteration, command
# Optional named via env: CURRENT_PHASE, VOICE_GUIDE_WRITTEN, CHAPTER_ARGS_LOCKED, CHAPTER_COUNT,
# WRITING_CHAPTER, CONCLUSIONS_WRITTEN, FRONT_SYNTHESIS_WRITTEN, READING_PASSES_COMPLETED
# Note: reading_budget is no longer a state field — max 5 passes is hardcoded with early termination.
create_state() {
  local topic="$1"
  local status="$2"
  local total_research="$3"
  local research_budget="$4"
  local iteration="${5:-10}"
  local command="${6:-/research-report:research 'test prompt' --research-iterations $research_budget}"
  local current_phase="${CURRENT_PHASE:-Phase R: Research}"
  local voice_guide_written="${VOICE_GUIDE_WRITTEN:-false}"
  local chapter_args_locked="${CHAPTER_ARGS_LOCKED:-false}"
  local chapter_count="${CHAPTER_COUNT:-0}"
  local writing_chapter="${WRITING_CHAPTER:-0}"
  local conclusions_written="${CONCLUSIONS_WRITTEN:-false}"
  local front_synthesis_written="${FRONT_SYNTHESIS_WRITTEN:-false}"
  local reading_passes_completed="${READING_PASSES_COMPLETED:-0}"
  mkdir -p "$TEST_DIR/.plugin-state"
  {
    echo "---"
    echo "workflow_type: research-report"
    echo "name: $topic"
    echo "status: $status"
    echo "current_phase: \"$current_phase\""
    echo "iteration: $iteration"
    echo "total_iterations_research: $total_research"
    echo "research_budget: $research_budget"
    echo "current_research_strategy: wide-exploration"
    echo "evidence_pool_count: 30"
    echo "sources_cited: 30"
    echo "voice_guide_written: $voice_guide_written"
    echo "chapter_arguments_locked: $chapter_args_locked"
    echo "chapter_count: $chapter_count"
    echo "writing_chapter: $writing_chapter"
    echo "conclusions_written: $conclusions_written"
    echo "front_synthesis_written: $front_synthesis_written"
    echo "reading_passes_completed: $reading_passes_completed"
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
  unset CURRENT_PHASE VOICE_GUIDE_WRITTEN CHAPTER_ARGS_LOCKED CHAPTER_COUNT
  unset WRITING_CHAPTER CONCLUSIONS_WRITTEN FRONT_SYNTHESIS_WRITTEN
  unset READING_PASSES_COMPLETED
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
create_state "my-topic" "in_progress" 5 50 10 "/research-report:research 'my-topic' 'test prompt' --research-iterations 50 --reading-iterations 3"
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
# TEST 5: complete + ALL Phase S sub-phases done → allow stop
# ==================================================================
echo "--- Test 5: Complete + all sub-phases done — allow stop ---"
reset_test_dir
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "research-done" "complete" 50 50 80 "/research-report:research 'research-done' 'test'"
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
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "research-short" "complete" 20 50 30 "/research-report:research 'research-short' 'test'"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "Research budget not fulfilled" "mentions research budget"
echo ""

# ==================================================================
# TEST 7: complete + voice guide NOT written → block
# ==================================================================
echo "--- Test 7: Complete + voice_guide_written false — block ---"
reset_test_dir
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=false CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "voice-fail" "complete" 50 50 80 "/research-report:research 'voice-fail' 'test'"
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.decision' "block" "decision is block"
assert_output_contains "$OUTPUT" "Voice guide not written" "mentions voice guide"
echo ""

# ==================================================================
# TEST 8: complete + body chapters incomplete → block
# ==================================================================
echo "--- Test 8: Complete + writing_chapter <= chapter_count — block ---"
reset_test_dir
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=3 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "chapters-incomplete" "complete" 50 50 80
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code 0 (block via JSON)"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_output_contains "$OUTPUT" "Body chapters incomplete" "mentions body chapters incomplete"
echo ""

# ==================================================================
# TEST 9: complete + reader passes incomplete → block
# ==================================================================
echo "--- Test 9: Complete + reading_passes_completed < reading_budget — block ---"
reset_test_dir
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=1 \
create_state "reader-short" "complete" 50 50 80
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "Reader passes incomplete" "mentions reader passes incomplete"
echo ""

# ==================================================================
# TEST 10: complete + final phase not Compile → block
# ==================================================================
echo "--- Test 10: Complete + current_phase != 'Phase S: Compile' — block ---"
reset_test_dir
CURRENT_PHASE="Phase S: Read" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "wrong-phase" "complete" 50 50 80
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "Final phase not reached" "mentions final phase not reached"
echo ""

# ==================================================================
# TEST 11: complete + all verified → state file cleaned up
# ==================================================================
echo "--- Test 11: Complete + all verified — state file cleaned up ---"
reset_test_dir
CURRENT_PHASE="Phase S: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=3 \
create_state "cleanup-test" "complete" 50 50 80
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when all checks pass"
assert_output_empty "$OUTPUT" "no output when all checks pass"
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
# TEST 12: Phase R → Phase S: Voice safety net transition
# ==================================================================
echo "--- Test 12: Phase R → Phase S: Voice safety net (in_progress + budget reached + still Phase R) ---"
reset_test_dir
CURRENT_PHASE="Phase R: Research" \
create_state "phase-transition" "in_progress" 50 50 60
EXIT_CODE=0
run_hook || EXIT_CODE=$?
PHASE_AFTER=$(yq --front-matter=extract '.current_phase' "$TEST_DIR/.plugin-state/research-report-phase-transition-state.md" 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$PHASE_AFTER" = "Phase S: Voice" ]; then
  echo -e "  ${GREEN}PASS${NC}: phase transitioned to Phase S: Voice"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: phase expected 'Phase S: Voice', got '$PHASE_AFTER'"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
assert_valid_json "$OUTPUT" "output is valid JSON after phase transition"
assert_json_field "$OUTPUT" '.decision' "block" "still blocks after phase transition"
echo ""

# ==================================================================
# TEST 13a: Edit mode — Phase E: Compile + all post-actions done — allow stop
# ==================================================================
echo "--- Test 13a: Edit complete + Phase E: Compile + post-actions done — allow stop ---"
reset_test_dir
# Edit mode: total_iterations_research/research_budget reflect ORIGINAL creation budget,
# but they may have been reset to 0 during edit (we skip the budget check for edits).
CURRENT_PHASE="Phase E: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=2 \
create_state "edit-done" "complete" 0 0 30
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "edit complete + all checks pass"
assert_output_empty "$OUTPUT" "no output when edit complete"
echo ""

# ==================================================================
# TEST 13b: Edit mode — current_phase is mid-edit but status: complete — block (final phase wrong)
# ==================================================================
echo "--- Test 13b: Edit + status=complete + current_phase=Phase E: Read — block ---"
reset_test_dir
CURRENT_PHASE="Phase E: Read" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=2 \
create_state "edit-mid" "complete" 0 0 30
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "Final phase not reached" "edit blocks when not at Phase E: Compile"
assert_output_contains "$OUTPUT" "Phase E: Compile" "expected phase mentions Phase E: Compile (not Phase S)"
echo ""

# ==================================================================
# TEST 13c: Edit mode — reader passes incomplete — block
# ==================================================================
echo "--- Test 13c: Edit + Phase E: Compile + reader passes < 2 — block ---"
reset_test_dir
CURRENT_PHASE="Phase E: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=1 \
create_state "edit-reader-short" "complete" 0 0 30
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "Reader passes incomplete" "edit blocks on insufficient reader passes"
echo ""

# ==================================================================
# TEST 13d: Edit mode — research budget check is SKIPPED for edits
# ==================================================================
echo "--- Test 13d: Edit + total_iterations_research < research_budget should NOT block (edits skip budget check) ---"
reset_test_dir
CURRENT_PHASE="Phase E: Compile" \
VOICE_GUIDE_WRITTEN=true CHAPTER_ARGS_LOCKED=true \
CHAPTER_COUNT=5 WRITING_CHAPTER=6 \
CONCLUSIONS_WRITTEN=true FRONT_SYNTHESIS_WRITTEN=true \
READING_PASSES_COMPLETED=2 \
create_state "edit-low-budget" "complete" 0 50 30
EXIT_CODE=0
run_hook || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "edit allows stop even if research budget < total"
assert_output_empty "$OUTPUT" "no error output for edit with low research"
echo ""

# ==================================================================
# TEST 13: Missing yq → exit 2
# ==================================================================
echo "--- Test 13: Missing yq — exit 2 ---"
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
# TEST 14: Missing jq → exit 2
# ==================================================================
echo "--- Test 14: Missing jq — exit 2 ---"
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
