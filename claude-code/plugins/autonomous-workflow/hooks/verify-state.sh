#!/bin/bash
# ABOUTME: Stop hook that verifies autonomous workflow state file accuracy before allowing exit.
# ABOUTME: Prevents state drift across iterations in long-running autonomous workflows.

set -euo pipefail

# Hard dependency: jq for JSON parsing and output
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 1
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Prevent infinite blocking loops: if Claude is already continuing from a
# previous Stop hook block, allow exit to avoid deadlock
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Find active autonomous workflow state file
ACTIVE_STATE=""
for state_file in docs/autonomous/*/research/*-state.md docs/autonomous/*/implementation/*-state.md; do
  [ -f "$state_file" ] || continue
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$state_file")
  STATUS=$(echo "$FRONTMATTER" | grep '^status:' | sed 's/status: *//' | sed "s/^['\"]//;s/['\"]$//")
  if [ "$STATUS" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# No active workflow — allow stop
if [ -z "$ACTIVE_STATE" ]; then
  exit 0
fi

# Extract fields from YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$ACTIVE_STATE")
CURRENT_PHASE=$(echo "$FRONTMATTER" | grep '^current_phase:' | sed 's/current_phase: *//' | sed "s/^['\"]//;s/['\"]$//")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
FEATURES_COMPLETE=$(echo "$FRONTMATTER" | grep '^features_complete:' | sed 's/features_complete: *//' || echo "0")

STATE_DIR=$(dirname "$ACTIVE_STATE")
NAME=$(basename "$(dirname "$STATE_DIR")")

# --- Phase C verification: feature-list.json consistency ---
if echo "$CURRENT_PHASE" | grep -qi "implementation"; then
  FEATURE_LIST="$STATE_DIR/feature-list.json"

  if [ -f "$FEATURE_LIST" ]; then
    # Count features marked as passing in JSON
    PASSES_IN_JSON=$(jq '[.features[] | select(.passes == true)] | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
    # Count features marked as failed in JSON
    FAILED_IN_JSON=$(jq '[.features[] | select(.failed == true)] | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
    FEATURES_FAILED_STATE=$(echo "$FRONTMATTER" | grep '^features_failed:' | sed 's/features_failed: *//' || echo "0")

    # Compare passing count to state file
    if [ "$PASSES_IN_JSON" != "$FEATURES_COMPLETE" ] || [ "$FAILED_IN_JSON" != "$FEATURES_FAILED_STATE" ]; then
      REASON="State file says features_complete=$FEATURES_COMPLETE, features_failed=$FEATURES_FAILED_STATE but feature-list.json has $PASSES_IN_JSON passing and $FAILED_IN_JSON failed. Update the state file to match reality."
      jq -n \
        --arg reason "$REASON" \
        '{
          "decision": "block",
          "reason": $reason,
          "systemMessage": "Autonomous workflow: state file is stale. Update it before stopping."
        }'
      exit 0
    fi
  fi
fi

# --- Phase A/B verification: artifacts were updated this iteration ---
if echo "$CURRENT_PHASE" | grep -qi "research\|planning"; then
  # Skip check on first iteration (files were just created)
  if [ -n "$ITERATION" ] && [ "$ITERATION" -gt 1 ] 2>/dev/null; then
    TOPIC_DIR=$(dirname "$STATE_DIR")
    ARTIFACT_UPDATED=false

    if echo "$CURRENT_PHASE" | grep -qi "research"; then
      # Phase A: check if any .tex file in the research dir is newer than the state file
      for tex_file in "$STATE_DIR"/*.tex; do
        [ -f "$tex_file" ] || continue
        if [ "$tex_file" -nt "$ACTIVE_STATE" ]; then
          ARTIFACT_UPDATED=true
          break
        fi
      done
    elif echo "$CURRENT_PHASE" | grep -qi "planning"; then
      # Phase B: check if the .md plan file in implementation dir is newer than the state file
      PLAN_FILE="$STATE_DIR/${NAME}-implementation-plan.md"
      if [ -f "$PLAN_FILE" ] && [ "$PLAN_FILE" -nt "$ACTIVE_STATE" ]; then
        ARTIFACT_UPDATED=true
      fi
    fi

    if [ "$ARTIFACT_UPDATED" = false ]; then
      # Check if state file itself was updated recently (within last 5 min)
      # If the state file is fresh, the artifact might just be about to be written
      STATE_AGE=$(( $(date +%s) - $(stat -f %m "$ACTIVE_STATE" 2>/dev/null || stat -c %Y "$ACTIVE_STATE" 2>/dev/null || echo "0") ))
      if [ "$STATE_AGE" -gt 300 ]; then
        REASON="No artifact in $STATE_DIR was updated this iteration (Phase: $CURRENT_PHASE, Iteration: $ITERATION). The report/plan should be updated every iteration during research and planning phases."
        jq -n \
          --arg reason "$REASON" \
          '{
            "decision": "block",
            "reason": $reason,
            "systemMessage": "Autonomous workflow: artifact was not updated this iteration. Update it before stopping."
          }'
        exit 0
      fi
    fi
  fi
fi

# All checks passed — allow stop
exit 0
