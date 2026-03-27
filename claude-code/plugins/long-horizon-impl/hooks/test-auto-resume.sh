#!/bin/bash
# ABOUTME: Test suite for auto-resume.sh in the long-horizon-impl plugin.
# ABOUTME: Creates realistic state files matching documented frontmatter formats and validates hook behavior.

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

# Helper: create a research state file with proper YAML frontmatter
create_research_state() {
  local topic="$1"
  local workflow_type="$2"
  local status="$3"
  local phase="$4"
  mkdir -p "$TEST_DIR/.claude"
  cat > "$TEST_DIR/.claude/lhi-$topic-research-state.md" << STATEEOF
---
workflow_type: $workflow_type
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

# Long-Horizon-Impl Workflow State: $topic

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

create_implementation_state() {
  local topic="$1"
  local workflow_type="$2"
  local status="$3"
  local phase="$4"
  mkdir -p "$TEST_DIR/.claude"
  cat > "$TEST_DIR/.claude/lhi-$topic-implementation-state.md" << STATEEOF
---
workflow_type: $workflow_type
name: $topic
status: $status
current_phase: "$phase"
iteration: 25
total_iterations_research: 15
total_iterations_planning: 5
total_iterations_coding: 5
sources_cited: 47
findings_count: 23
research_budget: 30
planning_budget: 15
features_total: 10
features_complete: 3
features_failed: 1
---

# Long-Horizon-Impl Workflow State: $topic

## Current Phase
$phase

## Implementation Progress
- Features total: 10
- Features complete: 3
- Features failed: 1
STATEEOF
}

# Reset test directory between tests
reset_test_dir() {
  rm -rf "$TEST_DIR/.claude" "$TEST_DIR/docs"
  mkdir -p "$TEST_DIR/.claude"
}

echo "========================================"
echo "Testing auto-resume.sh (long-horizon-impl)"
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
# TEST 1: Non-compact/clear source → exit 0, no output
# ==================================================================
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

# ==================================================================
# TEST 2: No active workflow → exit 0
# ==================================================================
echo "--- Test 2: No active workflow exits 0 silently ---"
reset_test_dir
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code when no state files exist"
assert_output_empty "$OUTPUT" "no output when no state files exist"
echo ""

# ==================================================================
# TEST 3: Completed workflow → exit 0
# ==================================================================
echo "--- Test 3: Completed workflow is skipped ---"
reset_test_dir
create_research_state "my-topic" "lhi-research-plan" "complete" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for complete workflow"
assert_output_empty "$OUTPUT" "no output for complete workflow"
echo ""

# ==================================================================
# TEST 4: Active lhi-research-plan in Phase A → output contains topic, workflow type, report.tex, planning artifacts
# ==================================================================
echo "--- Test 4: Active lhi-research-plan in Phase A (compact) ---"
reset_test_dir
create_research_state "ai-safety" "lhi-research-plan" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "ai-safety" "contains topic name"
assert_output_contains "$OUTPUT" "lhi-research-plan" "contains workflow type"
assert_output_contains "$OUTPUT" "Phase A: Research" "contains current phase"
assert_output_contains "$OUTPUT" "compacted" "contains trigger description"
assert_output_contains "$OUTPUT" "long-horizon-impl:long-horizon-impl-guide" "references skill"
assert_output_contains "$OUTPUT" "ai-safety-report.tex" "lists research report"
assert_output_contains "$OUTPUT" "implementation-plan.md" "lists implementation plan (lhi-research-plan)"
assert_output_contains "$OUTPUT" "functional-requirements.md" "lists functional requirements"
assert_output_contains "$OUTPUT" "architecture-plan.md" "lists architecture plan"
assert_output_contains "$OUTPUT" "test-plan.md" "lists test plan"
assert_output_not_contains "$OUTPUT" "feature-list.json" "does NOT list feature-list (research-plan has no implementation)"
echo ""

# ==================================================================
# TEST 5: Active lhi-research-plan in Phase B → output contains planning artifacts
# ==================================================================
echo "--- Test 5: Active lhi-research-plan in Phase B ---"
reset_test_dir
create_research_state "my-saas" "lhi-research-plan" "complete" "Phase A: Research"
create_implementation_state "my-saas" "lhi-research-plan" "in_progress" "Phase B: Planning"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "Phase B: Planning" "contains planning phase"
assert_output_contains "$OUTPUT" "implementation-plan.md" "lists implementation plan"
assert_output_contains "$OUTPUT" "functional-requirements.md" "lists functional requirements"
assert_output_not_contains "$OUTPUT" "feature-list.json" "does NOT list feature-list (planning phase)"
echo ""

# ==================================================================
# TEST 6: Active lhi-implement → output contains feature-list, escalations, progress
# ==================================================================
echo "--- Test 6: Active lhi-implement workflow ---"
reset_test_dir
create_implementation_state "quick-build" "lhi-implement" "in_progress" "Implementation"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "lhi-implement" "contains workflow type"
assert_output_contains "$OUTPUT" "implementation-plan.md" "lists plan"
assert_output_contains "$OUTPUT" "feature-list.json" "lists feature-list"
assert_output_contains "$OUTPUT" "escalations.json" "lists escalations"
assert_output_contains "$OUTPUT" "progress.txt" "lists progress log"
assert_output_not_contains "$OUTPUT" "report.tex" "does NOT list research report (implement has no research)"
echo ""

# ==================================================================
# TEST 7: Implementation state priority over research state
# ==================================================================
echo "--- Test 7: Implementation state takes priority (both exist, impl in_progress) ---"
reset_test_dir
create_research_state "dual-state" "lhi-research-plan" "complete" "Phase A: Research"
create_implementation_state "dual-state" "lhi-research-plan" "in_progress" "Phase B: Planning"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "Phase B: Planning" "picks implementation state (priority)"
assert_output_not_contains "$OUTPUT" "Phase A: Research" "does NOT pick research state"
echo ""

# ==================================================================
# TEST 8: Full state content embedded
# ==================================================================
echo "--- Test 8: Full state file content is embedded in context ---"
reset_test_dir
create_research_state "content-check" "lhi-research-plan" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_output_contains "$OUTPUT" "workflow_type: lhi-research-plan" "embeds YAML frontmatter"
assert_output_contains "$OUTPUT" "sources_cited: 47" "embeds sources_cited field"
assert_output_contains "$OUTPUT" "What is the impact of X" "embeds markdown body content"
assert_output_contains "$OUTPUT" "CLAUDE.md" "lists CLAUDE.md in restoration files"
echo ""

# ==================================================================
# TEST 9: Multiple topics, only in_progress picked
# ==================================================================
echo "--- Test 9: Multiple topics, only picks in_progress one ---"
reset_test_dir
create_research_state "topic-a" "lhi-research-plan" "complete" "Phase A: Research"
create_research_state "topic-b" "lhi-research-plan" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_contains "$OUTPUT" "topic-b" "picks the in_progress topic"
echo ""

# ==================================================================
# TEST 10: Both states complete exits silently
# ==================================================================
echo "--- Test 10: Both states complete exits silently ---"
reset_test_dir
create_research_state "done-project" "lhi-research-plan" "complete" "Phase A: Research"
create_implementation_state "done-project" "lhi-research-plan" "complete" "Phase B: Planning"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_empty "$OUTPUT" "no output when both states complete"
echo ""

# ---- Summary ----
echo "========================================"
echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
