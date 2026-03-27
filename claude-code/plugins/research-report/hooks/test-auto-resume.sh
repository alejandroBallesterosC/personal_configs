#!/bin/bash
# ABOUTME: Test suite for auto-resume.sh (SessionStart hook for research-report workflows).
# ABOUTME: Validates source filtering, state discovery, artifact listing, and context output after compact or clear.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/auto-resume.sh"
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

# Test helper: run the hook with given stdin, capture stdout+stderr+exit code
run_hook() {
  local input="$1"
  local exit_code=0
  # Run from the test directory so glob patterns resolve against it
  OUTPUT=$(cd "$TEST_DIR" && echo "$input" | bash "$HOOK_SCRIPT" 2>"$TEST_DIR/_stderr") || exit_code=$?
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

assert_output_not_contains() {
  local output="$1"
  local unexpected="$2"
  local test_name="$3"
  TEST_COUNT=$((TEST_COUNT + 1))
  if echo "$output" | grep -q "$unexpected"; then
    echo -e "  ${RED}FAIL${NC}: $test_name (should NOT contain '$unexpected')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo -e "  ${GREEN}PASS${NC}: $test_name (does not contain '$unexpected')"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
}

# Helper: create a research-report state file with proper YAML frontmatter
create_state() {
  local topic="$1"
  local status="$2"
  local phase="${3:-Phase R: Research}"
  mkdir -p "$TEST_DIR/.claude"
  cat > "$TEST_DIR/.claude/research-report-$topic-state.md" << STATEEOF
---
workflow_type: research-report
name: $topic
status: $status
current_phase: "$phase"
iteration: 15
total_iterations_research: 15
sources_cited: 47
findings_count: 23
current_research_strategy: wide-exploration
research_strategies_completed: []
strategy_rotation_threshold: 3
contributions_last_iteration: 2
consecutive_low_contributions: 0
research_budget: 30
---

# Research Report Workflow State: $topic

## Current Phase
$phase

## Original Prompt
Test research prompt for $topic

## Research Progress
- Sources consulted: 47
- Key findings: 23

## Open Questions
1. What is the impact of X?
2. How does Y relate to Z?
STATEEOF
}

# Reset test directory between tests
reset_test_dir() {
  rm -rf "$TEST_DIR/.claude" "$TEST_DIR/docs"
  mkdir -p "$TEST_DIR/.claude"
}

echo "========================================"
echo "Testing auto-resume.sh (research-report)"
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

# ---- Test 1: Non-compact/clear source exits silently ----
echo "--- Test 1: Non-compact/clear source exits 0 silently ---"
reset_test_dir
EXIT_CODE=0
run_hook '{"source": "init"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for source=init"
assert_output_empty "$OUTPUT" "no output for source=init"

EXIT_CODE=0
run_hook '{"source": "resume"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for source=resume"
assert_output_empty "$OUTPUT" "no output for source=resume"

EXIT_CODE=0
run_hook '{}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for empty source"
assert_output_empty "$OUTPUT" "no output for empty source"
echo ""

# ---- Test 2: No active workflow exits silently ----
echo "--- Test 2: No active workflow exits 0 silently ---"
reset_test_dir
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when no state files exist"
assert_output_empty "$OUTPUT" "no output when no state files exist"
echo ""

# ---- Test 3: Completed workflow exits silently ----
echo "--- Test 3: Completed workflow is skipped ---"
reset_test_dir
create_state "my-topic" "complete" "Phase S: Synthesis"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for complete workflow"
assert_output_empty "$OUTPUT" "no output for complete workflow"
echo ""

# ---- Test 4: Active research-report workflow (compact) ----
echo "--- Test 4: Active research-report workflow (compact) ---"
reset_test_dir
create_state "ai-safety" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "ai-safety" "contains topic name"
assert_output_contains "$OUTPUT" "research-report" "contains workflow type"
assert_output_contains "$OUTPUT" "Phase R: Research" "contains current phase"
assert_output_contains "$OUTPUT" "compacted" "contains trigger description"
assert_output_contains "$OUTPUT" "research-report:research-report-guide" "references skill"
assert_output_contains "$OUTPUT" "report.tex" "lists research report path"
echo ""

# ---- Test 5: Active research-report workflow (clear) ----
echo "--- Test 5: Active research-report workflow (clear) ---"
reset_test_dir
create_state "quantum-computing" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "clear"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "quantum-computing" "contains topic name"
assert_output_contains "$OUTPUT" "research-report" "contains workflow type"
assert_output_contains "$OUTPUT" "cleared" "contains trigger description (clear)"
assert_output_contains "$OUTPUT" "research-report:research-report-guide" "references skill"
assert_output_contains "$OUTPUT" "report.tex" "lists research report path"
echo ""

# ---- Test 6: Full state file content embedded in output ----
echo "--- Test 6: Full state file content is embedded in output ---"
reset_test_dir
create_state "content-check" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "workflow_type: research-report" "embeds YAML frontmatter"
assert_output_contains "$OUTPUT" "sources_cited: 47" "embeds sources_cited field"
assert_output_contains "$OUTPUT" "What is the impact of X" "embeds markdown body content"
echo ""

# ---- Test 7: CLAUDE.md listed in restore files ----
echo "--- Test 7: CLAUDE.md listed in restore files ---"
reset_test_dir
create_state "claude-md-check" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "CLAUDE.md" "lists CLAUDE.md in restoration files"
assert_output_contains "$OUTPUT" "research-progress.md" "lists research-progress.md"
echo ""

# ---- Test 8: Multiple topics, only in_progress picked ----
echo "--- Test 8: Multiple topics, only picks in_progress one ---"
reset_test_dir
create_state "topic-a" "complete" "Phase S: Synthesis"
create_state "topic-b" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "topic-b" "picks the in_progress topic"
assert_output_not_contains "$OUTPUT" "Name.*topic-a" "does not pick the complete topic"
echo ""

# ---- Test 9: No autonomous-workflow references in output ----
echo "--- Test 9: No autonomous-workflow references in output ---"
reset_test_dir
create_state "clean-check" "in_progress" "Phase R: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_output_not_contains "$OUTPUT" "autonomous-workflow" "no autonomous-workflow references"
assert_output_not_contains "$OUTPUT" "autonomous-research" "no autonomous-research references"
assert_output_not_contains "$OUTPUT" "autonomous-implement" "no autonomous-implement references"
echo ""

# ---- Summary ----
echo "========================================"
echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
