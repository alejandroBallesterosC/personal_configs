#!/bin/bash
# ABOUTME: Stop hook that blocks Claude from stopping during TDD implementation phases (7, 8, 9) until workflow completion.
# ABOUTME: Re-feeds the current phase command via the block JSON reason field so Claude can resume after context compaction.

set -euo pipefail

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".plugin-state/dev-tdd-gate-debug.log"

debug_log() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p .plugin-state
  {
    echo "## $timestamp"
    echo ""
    echo "$msg"
    echo ""
    echo "**Working directory:** $(pwd)"
    echo ""
    echo "---"
    echo ""
  } >> "$DEBUG_FILE"
}

debug_log "**Hook invoked.**"

# Check for required dependencies
if ! command -v yq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** yq not found in PATH ($PATH)"
  echo "ERROR: yq is required but not installed." >&2
  echo "The TDD implementation gate hook cannot parse workflow state files without yq." >&2
  echo "Install: brew install yq (macOS) or see https://github.com/mikefarah/yq#install" >&2
  exit 2
fi
if ! command -v jq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** jq not found in PATH ($PATH)"
  echo "ERROR: jq is required but not installed." >&2
  echo "The TDD implementation gate hook cannot produce JSON output without jq." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 2
fi

# Read and discard hook input from stdin (required so stdin doesn't hang)
cat > /dev/null

# Find active TDD implementation workflow state file
ACTIVE_STATE=""
for state_file in docs/workflow-*/*-state.md; do
  [ -f "$state_file" ] || continue
  wf_type=$(yq --front-matter=extract '.workflow_type' "$state_file" 2>/dev/null)
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$wf_type" = "tdd-implementation" ] && [ "$status" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# No active TDD workflow — allow stop
if [ -z "$ACTIVE_STATE" ]; then
  debug_log "**Allowing stop:** No active TDD implementation workflow found"
  exit 0
fi

debug_log "**Active TDD workflow found:** $ACTIVE_STATE"

# Extract fields from YAML frontmatter
STATUS=$(yq --front-matter=extract '.status' "$ACTIVE_STATE" 2>/dev/null)
CURRENT_PHASE=$(yq --front-matter=extract '.current_phase' "$ACTIVE_STATE" 2>/dev/null)
COMMAND=$(yq --front-matter=extract '.command' "$ACTIVE_STATE" 2>/dev/null)
NAME=$(yq --front-matter=extract '.name' "$ACTIVE_STATE" 2>/dev/null)
DESCRIPTION=$(yq --front-matter=extract '.description' "$ACTIVE_STATE" 2>/dev/null)

debug_log "**Fields:** status=$STATUS, current_phase=$CURRENT_PHASE, name=$NAME, command=$(echo "$COMMAND" | head -1)"

# If status is complete or phase is COMPLETE — allow stop
if [ "$STATUS" = "complete" ] || [ "$CURRENT_PHASE" = "COMPLETE" ]; then
  debug_log "**Allowing stop:** Workflow is complete (status=$STATUS, phase=$CURRENT_PHASE)"
  exit 0
fi

# Extract phase number from current_phase (e.g., "Phase 7: Implementation" → 7)
PHASE_NUM=$(echo "$CURRENT_PHASE" | grep -oE 'Phase [0-9]+' | grep -oE '[0-9]+' || echo "0")

# Planning phases (2-6) have natural pause points — allow stop
if [ "$PHASE_NUM" -lt 7 ] 2>/dev/null; then
  debug_log "**Allowing stop:** Phase $PHASE_NUM is a planning phase (< 7)"
  exit 0
fi

# Implementation phases (7, 8, 9) — block stop and re-feed command
debug_log "**Phase $PHASE_NUM detected:** Blocking stop for implementation phase."

# Build the command to re-feed
if [ -n "$COMMAND" ] && [ "$COMMAND" != "null" ]; then
  REFEED_COMMAND="$COMMAND"
else
  # Fallback: construct command from name + description + phase number
  debug_log "**WARNING:** command field is empty/missing in $ACTIVE_STATE. Constructing fallback."
  case "$PHASE_NUM" in
    7) REFEED_COMMAND="/dev-workflow:7-implement $NAME \"$DESCRIPTION\"" ;;
    8) REFEED_COMMAND="/dev-workflow:8-e2e-test $NAME \"$DESCRIPTION\"" ;;
    9) REFEED_COMMAND="/dev-workflow:9-review $NAME" ;;
    *) REFEED_COMMAND="/dev-workflow:continue-workflow $NAME" ;;
  esac
fi

# Trim trailing whitespace/newlines from command
CLEAN_COMMAND=$(echo "$REFEED_COMMAND" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

SYSTEM_MSG="TDD implementation gate: Workflow '$NAME' is in Phase $PHASE_NUM — blocking stop until completion. State file: $ACTIVE_STATE"

debug_log "**Blocking stop:** Re-feeding command for Phase $PHASE_NUM."

jq -n \
  --arg reason "$CLEAN_COMMAND" \
  --arg msg "$SYSTEM_MSG" \
  '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
exit 0
