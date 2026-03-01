#!/bin/bash
# ABOUTME: Test suite for autonomous-workflow hooks (auto-resume-after-compact-or-clear.sh).
# ABOUTME: Creates realistic state files matching documented frontmatter formats and validates hook behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/auto-resume-after-compact-or-clear.sh"
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

# Helper: create a state file with proper YAML frontmatter
create_research_state() {
  local topic="$1"
  local workflow_type="$2"
  local status="$3"
  local phase="$4"
  local dir="$TEST_DIR/docs/autonomous/$topic/research"
  mkdir -p "$dir"
  cat > "$dir/$topic-state.md" << STATEEOF
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

# Autonomous Workflow State: $topic

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
  local dir="$TEST_DIR/docs/autonomous/$topic/implementation"
  mkdir -p "$dir"
  cat > "$dir/$topic-state.md" << STATEEOF
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

# Autonomous Workflow State: $topic

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
  rm -rf "$TEST_DIR/docs"
}

echo "========================================"
echo "Testing auto-resume-after-compact-or-clear.sh"
echo "========================================"
echo ""

# ---- Dependency checks ----
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

# ---- Test 3: Completed research workflow exits silently ----
echo "--- Test 3: Completed research workflow is skipped ---"
reset_test_dir
create_research_state "my-topic" "autonomous-research" "complete" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code for complete workflow"
assert_output_empty "$OUTPUT" "no output for complete workflow"
echo ""

# ---- Test 4: Active research workflow (Mode 1) ----
echo "--- Test 4: Active research workflow (Mode 1, compact) ---"
reset_test_dir
create_research_state "ai-safety" "autonomous-research" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_valid_json "$OUTPUT" "output is valid JSON"
assert_json_field "$OUTPUT" '.hookSpecificOutput.hookEventName' "SessionStart" "hookEventName"

# Extract additionalContext for content checks
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "ai-safety" "contains topic name"
assert_output_contains "$CONTEXT" "autonomous-research" "contains workflow type"
assert_output_contains "$CONTEXT" "Phase A: Research" "contains current phase"
assert_output_contains "$CONTEXT" "compacted" "contains trigger description"
assert_output_contains "$CONTEXT" "autonomous-workflow:autonomous-workflow-guide" "references skill"
assert_output_contains "$CONTEXT" "ai-safety-report.tex" "lists research report"
assert_output_not_contains "$CONTEXT" "implementation-plan.md" "does NOT list plan (Mode 1 has no plan)"
assert_output_not_contains "$CONTEXT" "feature-list.json" "does NOT list feature-list (Mode 1 has no implementation)"
echo ""

# ---- Test 5: Active research-plan workflow in research phase (Mode 2) ----
echo "--- Test 5: Active research-plan workflow, Phase A (Mode 2, clear) ---"
reset_test_dir
create_research_state "my-saas" "autonomous-research-plan" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "clear"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_valid_json "$OUTPUT" "output is valid JSON"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "my-saas" "contains topic name"
assert_output_contains "$CONTEXT" "autonomous-research-plan" "contains workflow type"
assert_output_contains "$CONTEXT" "Phase A: Research" "contains phase"
assert_output_contains "$CONTEXT" "cleared" "contains trigger description (clear)"
assert_output_contains "$CONTEXT" "my-saas-report.tex" "lists research report"
assert_output_contains "$CONTEXT" "implementation-plan.md" "lists implementation plan (Mode 2)"
assert_output_not_contains "$CONTEXT" "feature-list.json" "does NOT list feature-list (Mode 2 has no implementation)"
echo ""

# ---- Test 6: Active research-plan workflow in planning phase (Mode 2, Phase B) ----
echo "--- Test 6: Active research-plan workflow, Phase B (Mode 2) ---"
reset_test_dir
# Research state is complete, implementation state is in_progress
create_research_state "my-saas" "autonomous-research-plan" "complete" "Phase A: Research"
create_implementation_state "my-saas" "autonomous-research-plan" "in_progress" "Phase B: Planning"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_valid_json "$OUTPUT" "output is valid JSON"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "Phase B: Planning" "contains planning phase"
assert_output_contains "$CONTEXT" "implementation-plan.md" "lists implementation plan"
assert_output_not_contains "$CONTEXT" "feature-list.json" "does NOT list feature-list (planning phase)"
echo ""

# ---- Test 7: Active full-auto workflow in implementation phase (Mode 3, Phase C) ----
echo "--- Test 7: Active full-auto workflow, Phase C (Mode 3) ---"
reset_test_dir
create_research_state "big-project" "autonomous-full-auto" "complete" "Phase A: Research"
create_implementation_state "big-project" "autonomous-full-auto" "in_progress" "Phase C: Implementation"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_valid_json "$OUTPUT" "output is valid JSON"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "autonomous-full-auto" "contains workflow type"
assert_output_contains "$CONTEXT" "Phase C: Implementation" "contains implementation phase"
assert_output_contains "$CONTEXT" "implementation-plan.md" "lists plan"
assert_output_contains "$CONTEXT" "feature-list.json" "lists feature-list (Mode 3 implementation)"
assert_output_contains "$CONTEXT" "progress.txt" "lists progress log"
echo ""

# ---- Test 8: Active implement-only workflow (Mode 4) ----
echo "--- Test 8: Active implement-only workflow (Mode 4) ---"
reset_test_dir
create_implementation_state "quick-build" "autonomous-implement" "in_progress" "Phase C: Implementation"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_valid_json "$OUTPUT" "output is valid JSON"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "autonomous-implement" "contains workflow type"
assert_output_contains "$CONTEXT" "Phase C: Implementation" "contains phase"
assert_output_contains "$CONTEXT" "implementation-plan.md" "lists plan"
assert_output_contains "$CONTEXT" "feature-list.json" "lists feature-list"
assert_output_contains "$CONTEXT" "progress.txt" "lists progress log"
echo ""

# ---- Test 9: Implementation state takes priority over research state ----
echo "--- Test 9: Implementation state takes priority (both exist, impl in_progress) ---"
reset_test_dir
create_research_state "dual-state" "autonomous-full-auto" "complete" "Phase A: Research"
create_implementation_state "dual-state" "autonomous-full-auto" "in_progress" "Phase C: Implementation"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "Phase C: Implementation" "picks implementation state (priority)"
assert_output_not_contains "$CONTEXT" "Phase A: Research" "does NOT pick research state"
echo ""

# ---- Test 10: Both states complete exits silently ----
echo "--- Test 10: Both states complete exits silently ---"
reset_test_dir
create_research_state "done-project" "autonomous-full-auto" "complete" "Phase A: Research"
create_implementation_state "done-project" "autonomous-full-auto" "complete" "Phase C: Implementation"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
assert_output_empty "$OUTPUT" "no output when both states complete"
echo ""

# ---- Test 11: State file content is included in context ----
echo "--- Test 11: Full state file content is embedded in context ---"
reset_test_dir
create_research_state "content-check" "autonomous-research" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "workflow_type: autonomous-research" "embeds YAML frontmatter"
assert_output_contains "$CONTEXT" "sources_cited: 47" "embeds sources_cited field"
assert_output_contains "$CONTEXT" "What is the impact of X" "embeds markdown body content"
assert_output_contains "$CONTEXT" "CLAUDE.md" "lists CLAUDE.md in restoration files"
echo ""

# ---- Test 12: Multiple topics - only picks in_progress one ----
echo "--- Test 12: Multiple topics, only picks in_progress one ---"
reset_test_dir
create_research_state "topic-a" "autonomous-research" "complete" "Phase A: Research"
create_research_state "topic-b" "autonomous-research" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "topic-b" "picks the in_progress topic"
echo ""

# ---- Test 13: Frontmatter parsing with quoted values ----
echo "--- Test 13: Frontmatter parsing with quoted string values ---"
reset_test_dir
local_dir="$TEST_DIR/docs/autonomous/quoted-test/research"
mkdir -p "$local_dir"
cat > "$local_dir/quoted-test-state.md" << 'QEOF'
---
workflow_type: "autonomous-research"
name: "quoted-test"
status: "in_progress"
current_phase: "Phase A: Research"
iteration: 5
total_iterations_research: 5
sources_cited: 10
findings_count: 8
current_research_strategy: "deep-dive"
research_strategies_completed: ["wide-exploration", "source-verification"]
strategy_rotation_threshold: 3
contributions_last_iteration: 3
consecutive_low_contributions: 0
---

# Autonomous Workflow State: quoted-test
QEOF
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code with quoted YAML values"
assert_valid_json "$OUTPUT" "valid JSON with quoted YAML"
CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
assert_output_contains "$CONTEXT" "quoted-test" "correctly parsed quoted name"
assert_output_contains "$CONTEXT" "autonomous-research" "correctly parsed quoted workflow_type"
assert_output_contains "$CONTEXT" "Phase A: Research" "correctly parsed quoted phase"
echo ""

# ---- Test 14: Frontmatter with extra fields (forward compatibility) ----
echo "--- Test 14: Frontmatter with extra/future fields ---"
reset_test_dir
local_dir="$TEST_DIR/docs/autonomous/extra-fields/research"
mkdir -p "$local_dir"
cat > "$local_dir/extra-fields-state.md" << 'XEOF'
---
workflow_type: autonomous-research
name: extra-fields
status: in_progress
current_phase: "Phase A: Research"
iteration: 1
total_iterations_research: 1
sources_cited: 0
findings_count: 0
current_research_strategy: wide-exploration
research_strategies_completed: []
strategy_rotation_threshold: 3
contributions_last_iteration: 0
consecutive_low_contributions: 0
some_future_field: "whatever"
another_field: 42
---

# State file with extra fields
XEOF
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "exit code with extra fields"
assert_valid_json "$OUTPUT" "valid JSON even with extra frontmatter fields"
echo ""

# ---- Test 15: Verify JSON structure matches expected format ----
echo "--- Test 15: JSON output structure matches expected hook format ---"
reset_test_dir
create_research_state "json-check" "autonomous-research" "in_progress" "Phase A: Research"
EXIT_CODE=0
run_hook '{"source": "compact"}' || EXIT_CODE=$?
# Verify the JSON has exactly the right structure
HAS_HOOK_OUTPUT=$(echo "$OUTPUT" | jq 'has("hookSpecificOutput")' 2>/dev/null)
HAS_EVENT_NAME=$(echo "$OUTPUT" | jq '.hookSpecificOutput | has("hookEventName")' 2>/dev/null)
HAS_CONTEXT=$(echo "$OUTPUT" | jq '.hookSpecificOutput | has("additionalContext")' 2>/dev/null)
TEST_COUNT=$((TEST_COUNT + 1))
if [ "$HAS_HOOK_OUTPUT" = "true" ] && [ "$HAS_EVENT_NAME" = "true" ] && [ "$HAS_CONTEXT" = "true" ]; then
  echo -e "  ${GREEN}PASS${NC}: JSON has correct structure (hookSpecificOutput.hookEventName + additionalContext)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}FAIL${NC}: JSON structure mismatch"
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
