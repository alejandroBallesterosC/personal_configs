#!/bin/bash
# ABOUTME: Stop hook that drives iteration (re-feeds command on in_progress) and verifies completion criteria per workflow type.
# ABOUTME: Drives multi-iteration execution by re-feeding the command, and verifies completion criteria before allowing stop.

set -euo pipefail

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".claude/autonomous-stop-hook-debug.md"

debug_log() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p .claude
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
  echo "The stop hook cannot parse workflow state files without yq." >&2
  echo "Install: brew install yq (macOS) or see https://github.com/mikefarah/yq#install" >&2
  exit 2
fi
if ! command -v jq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** jq not found in PATH ($PATH)"
  echo "ERROR: jq is required but not installed." >&2
  echo "The stop hook cannot produce JSON output without jq." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 2
fi

# Read and discard hook input from stdin (required so stdin doesn't hang)
cat > /dev/null

# Find active autonomous workflow state files
# Prioritize in_progress over complete to avoid stale complete files killing active workflows
ACTIVE_STATE=""

# First pass: find in_progress files (implementation state takes priority over research state)
for state_file in .claude/autonomous-*-implementation-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done
if [ -z "$ACTIVE_STATE" ]; then
  for state_file in .claude/autonomous-*-research-state.md; do
    [ -f "$state_file" ] || continue
    status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
    if [ "$status" = "in_progress" ]; then
      ACTIVE_STATE="$state_file"
      break
    fi
  done
fi

# Second pass: if no in_progress found, check for complete files needing verification
if [ -z "$ACTIVE_STATE" ]; then
  for state_file in .claude/autonomous-*-implementation-state.md; do
    [ -f "$state_file" ] || continue
    status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
    if [ "$status" = "complete" ]; then
      ACTIVE_STATE="$state_file"
      break
    fi
  done
fi
if [ -z "$ACTIVE_STATE" ]; then
  for state_file in .claude/autonomous-*-research-state.md; do
    [ -f "$state_file" ] || continue
    status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
    if [ "$status" = "complete" ]; then
      ACTIVE_STATE="$state_file"
      break
    fi
  done
fi

# No active workflow — allow stop
if [ -z "$ACTIVE_STATE" ]; then
  debug_log "**Allowing stop:** No active autonomous workflow found"
  exit 0
fi

debug_log "**Active workflow found:** $ACTIVE_STATE"

# Extract fields from YAML frontmatter
STATUS=$(yq --front-matter=extract '.status' "$ACTIVE_STATE" 2>/dev/null)
ITERATION=$(yq --front-matter=extract '.iteration' "$ACTIVE_STATE" 2>/dev/null)
COMMAND=$(yq --front-matter=extract '.command' "$ACTIVE_STATE" 2>/dev/null)
WORKFLOW_TYPE=$(yq --front-matter=extract '.workflow_type' "$ACTIVE_STATE" 2>/dev/null)
TOTAL_RESEARCH=$(yq --front-matter=extract '.total_iterations_research' "$ACTIVE_STATE" 2>/dev/null)
RESEARCH_BUDGET=$(yq --front-matter=extract '.research_budget' "$ACTIVE_STATE" 2>/dev/null)
TOTAL_PLANNING=$(yq --front-matter=extract '.total_iterations_planning' "$ACTIVE_STATE" 2>/dev/null)
PLANNING_BUDGET=$(yq --front-matter=extract '.planning_budget' "$ACTIVE_STATE" 2>/dev/null)
NAME=$(yq --front-matter=extract '.name' "$ACTIVE_STATE" 2>/dev/null)

debug_log "**Fields:** status=$STATUS, iteration=$ITERATION, workflow_type=$WORKFLOW_TYPE, name=$NAME, command=$(echo "$COMMAND" | head -1)"

# ---------------------------------------------------------------
# STATUS: in_progress — increment iteration and block with command
# ---------------------------------------------------------------
if [ "$STATUS" = "in_progress" ]; then
  # Validate iteration is numeric
  if ! [[ "$ITERATION" =~ ^[0-9]+$ ]]; then
    debug_log "**WARNING:** iteration is not numeric ('$ITERATION'). Allowing stop."
    echo "WARNING: iteration field is not numeric ('$ITERATION') in $ACTIVE_STATE. Skipping iteration increment." >&2
    exit 0
  fi

  # Validate command is non-empty
  if [ -z "$COMMAND" ] || [ "$COMMAND" = "null" ]; then
    debug_log "**WARNING:** command field is empty in $ACTIVE_STATE. Allowing stop."
    echo "WARNING: command field is empty in $ACTIVE_STATE. Cannot re-feed command." >&2
    exit 0
  fi

  # Increment iteration via sed + atomic temp file
  NEXT_ITERATION=$((ITERATION + 1))
  TEMP_FILE=$(mktemp)
  sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$ACTIVE_STATE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$ACTIVE_STATE"

  # Trim trailing whitespace/newlines from command
  CLEAN_COMMAND=$(echo "$COMMAND" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  SYSTEM_MSG="Continuing autonomous workflow iteration $NEXT_ITERATION. State file: $ACTIVE_STATE"

  debug_log "**Blocking stop:** Incrementing iteration to $NEXT_ITERATION, re-feeding command."

  jq -n \
    --arg reason "$CLEAN_COMMAND" \
    --arg msg "$SYSTEM_MSG" \
    '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
  exit 0
fi

# ---------------------------------------------------------------
# STATUS: complete — verify completion criteria per workflow type
# ---------------------------------------------------------------
if [ "$STATUS" = "complete" ]; then
  ERRORS=""

  # Extract topic name from state filename for feature-list path lookup
  # Filename pattern: autonomous-<topic>-{research,implementation}-state.md
  TOPIC_NAME="$NAME"

  case "$WORKFLOW_TYPE" in
    autonomous-research)
      # Verify: total_iterations_research >= research_budget
      if [ -n "$TOTAL_RESEARCH" ] && [ -n "$RESEARCH_BUDGET" ] && \
         [ "$TOTAL_RESEARCH" != "null" ] && [ "$RESEARCH_BUDGET" != "null" ] && \
         [ "$TOTAL_RESEARCH" -lt "$RESEARCH_BUDGET" ] 2>/dev/null; then
        ERRORS="${ERRORS}Research budget not fulfilled: total_iterations_research ($TOTAL_RESEARCH) < research_budget ($RESEARCH_BUDGET). "
      fi
      ;;

    autonomous-research-plan)
      # Verify: research budget + planning budget
      if [ -n "$TOTAL_RESEARCH" ] && [ -n "$RESEARCH_BUDGET" ] && \
         [ "$TOTAL_RESEARCH" != "null" ] && [ "$RESEARCH_BUDGET" != "null" ] && \
         [ "$TOTAL_RESEARCH" -lt "$RESEARCH_BUDGET" ] 2>/dev/null; then
        ERRORS="${ERRORS}Research budget not fulfilled: total_iterations_research ($TOTAL_RESEARCH) < research_budget ($RESEARCH_BUDGET). "
      fi
      if [ -n "$TOTAL_PLANNING" ] && [ -n "$PLANNING_BUDGET" ] && \
         [ "$TOTAL_PLANNING" != "null" ] && [ "$PLANNING_BUDGET" != "null" ] && \
         [ "$TOTAL_PLANNING" -lt "$PLANNING_BUDGET" ] 2>/dev/null; then
        ERRORS="${ERRORS}Planning budget not fulfilled: total_iterations_planning ($TOTAL_PLANNING) < planning_budget ($PLANNING_BUDGET). "
      fi
      ;;

    autonomous-full-auto)
      # Verify: research budget + planning budget + all features resolved
      if [ -n "$TOTAL_RESEARCH" ] && [ -n "$RESEARCH_BUDGET" ] && \
         [ "$TOTAL_RESEARCH" != "null" ] && [ "$RESEARCH_BUDGET" != "null" ] && \
         [ "$TOTAL_RESEARCH" -lt "$RESEARCH_BUDGET" ] 2>/dev/null; then
        ERRORS="${ERRORS}Research budget not fulfilled: total_iterations_research ($TOTAL_RESEARCH) < research_budget ($RESEARCH_BUDGET). "
      fi
      if [ -n "$TOTAL_PLANNING" ] && [ -n "$PLANNING_BUDGET" ] && \
         [ "$TOTAL_PLANNING" != "null" ] && [ "$PLANNING_BUDGET" != "null" ] && \
         [ "$TOTAL_PLANNING" -lt "$PLANNING_BUDGET" ] 2>/dev/null; then
        ERRORS="${ERRORS}Planning budget not fulfilled: total_iterations_planning ($TOTAL_PLANNING) < planning_budget ($PLANNING_BUDGET). "
      fi
      # Check feature resolution
      FEATURE_LIST=".claude/autonomous-${TOPIC_NAME}-feature-list.json"
      if [ -f "$FEATURE_LIST" ]; then
        TOTAL_FEATURES=$(jq '.features | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
        RESOLVED_FEATURES=$(jq '[.features[] | select(.passes == true or .failed == true)] | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
        if [ "$RESOLVED_FEATURES" -lt "$TOTAL_FEATURES" ] 2>/dev/null; then
          ERRORS="${ERRORS}Not all features resolved: $RESOLVED_FEATURES/$TOTAL_FEATURES resolved in feature-list.json. "
        fi
      fi
      ;;

    autonomous-implement)
      # Verify: all features resolved (no budget checks)
      FEATURE_LIST=".claude/autonomous-${TOPIC_NAME}-feature-list.json"
      if [ -f "$FEATURE_LIST" ]; then
        TOTAL_FEATURES=$(jq '.features | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
        RESOLVED_FEATURES=$(jq '[.features[] | select(.passes == true or .failed == true)] | length' "$FEATURE_LIST" 2>/dev/null || echo "0")
        if [ "$RESOLVED_FEATURES" -lt "$TOTAL_FEATURES" ] 2>/dev/null; then
          ERRORS="${ERRORS}Not all features resolved: $RESOLVED_FEATURES/$TOTAL_FEATURES resolved in feature-list.json. "
        fi
      fi
      ;;

    *)
      debug_log "**WARNING:** Unknown workflow_type '$WORKFLOW_TYPE'. Allowing stop."
      exit 0
      ;;
  esac

  if [ -n "$ERRORS" ]; then
    debug_log "**Blocking stop (complete but verification failed):** $ERRORS"
    REASON="Workflow marked complete but verification failed: ${ERRORS}Fix state before stopping."
    jq -n --arg reason "$REASON" '{"decision": "block", "reason": $reason}'
    exit 0
  fi

  # Clean up state files for completed workflow
  rm -f "$ACTIVE_STATE"
  rm -f ".claude/autonomous-${TOPIC_NAME}-research-state.md"
  rm -f ".claude/autonomous-${TOPIC_NAME}-implementation-state.md"
  debug_log "**Cleaned up:** Removed state files for topic '${TOPIC_NAME}'"

  debug_log "**Allowing stop:** Status is complete and all verification checks passed for $WORKFLOW_TYPE."
  exit 0
fi

# Unknown status — allow stop
debug_log "**Allowing stop:** Unknown status '$STATUS' in $ACTIVE_STATE"
exit 0
