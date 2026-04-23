#!/bin/bash
# ABOUTME: Stop hook that drives iteration (re-feeds command on in_progress) and verifies completion criteria for research-report workflows.
# ABOUTME: Drives multi-iteration execution by re-feeding the command, and verifies all Phase R/S sub-phase fields before allowing stop on complete.

set -euo pipefail

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".plugin-state/research-report-stop-hook-debug.log"

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

# Find active research-report workflow state files
ACTIVE_STATE=""

# First pass: find in_progress research-report state files
for state_file in .plugin-state/research-report-*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# Second pass: check for complete files needing verification
if [ -z "$ACTIVE_STATE" ]; then
  for state_file in .plugin-state/research-report-*-state.md; do
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
  debug_log "**Allowing stop:** No active research-report workflow found"
  exit 0
fi

debug_log "**Active workflow found:** $ACTIVE_STATE"

# Extract fields from YAML frontmatter
STATUS=$(yq --front-matter=extract '.status' "$ACTIVE_STATE" 2>/dev/null)
ITERATION=$(yq --front-matter=extract '.iteration' "$ACTIVE_STATE" 2>/dev/null)
COMMAND=$(yq --front-matter=extract '.command' "$ACTIVE_STATE" 2>/dev/null)
WORKFLOW_TYPE=$(yq --front-matter=extract '.workflow_type' "$ACTIVE_STATE" 2>/dev/null)
NAME=$(yq --front-matter=extract '.name' "$ACTIVE_STATE" 2>/dev/null)
CURRENT_PHASE=$(yq --front-matter=extract '.current_phase' "$ACTIVE_STATE" 2>/dev/null)

TOTAL_RESEARCH=$(yq --front-matter=extract '.total_iterations_research' "$ACTIVE_STATE" 2>/dev/null)
RESEARCH_BUDGET=$(yq --front-matter=extract '.research_budget' "$ACTIVE_STATE" 2>/dev/null)

VOICE_GUIDE_WRITTEN=$(yq --front-matter=extract '.voice_guide_written' "$ACTIVE_STATE" 2>/dev/null)
CHAPTER_ARGS_LOCKED=$(yq --front-matter=extract '.chapter_arguments_locked' "$ACTIVE_STATE" 2>/dev/null)
CHAPTER_COUNT=$(yq --front-matter=extract '.chapter_count' "$ACTIVE_STATE" 2>/dev/null)
WRITING_CHAPTER=$(yq --front-matter=extract '.writing_chapter' "$ACTIVE_STATE" 2>/dev/null)
CONCLUSIONS_WRITTEN=$(yq --front-matter=extract '.conclusions_written' "$ACTIVE_STATE" 2>/dev/null)
FRONT_SYNTHESIS_WRITTEN=$(yq --front-matter=extract '.front_synthesis_written' "$ACTIVE_STATE" 2>/dev/null)

READING_ITERATION=$(yq --front-matter=extract '.reading_iteration' "$ACTIVE_STATE" 2>/dev/null)
READING_PHASE=$(yq --front-matter=extract '.reading_phase' "$ACTIVE_STATE" 2>/dev/null)
READING_PASSES_COMPLETED=$(yq --front-matter=extract '.reading_passes_completed' "$ACTIVE_STATE" 2>/dev/null)

# Hardcoded minimum: at least IDENTIFY + VERIFY (early termination floor)
MIN_READING_PASSES=2
# Hardcoded maximum: IDENTIFY + 3 FIX + VERIFY
MAX_READING_PASSES=5

debug_log "**Fields:** status=$STATUS, iteration=$ITERATION, current_phase=$CURRENT_PHASE, name=$NAME, total_research=$TOTAL_RESEARCH/$RESEARCH_BUDGET, voice=$VOICE_GUIDE_WRITTEN, chapters_locked=$CHAPTER_ARGS_LOCKED, chapter_count=$CHAPTER_COUNT, writing_chapter=$WRITING_CHAPTER, conclusions=$CONCLUSIONS_WRITTEN, front_synthesis=$FRONT_SYNTHESIS_WRITTEN, reading_iter=$READING_ITERATION, reading_phase=$READING_PHASE, reading_completed=$READING_PASSES_COMPLETED, command=$(echo "$COMMAND" | head -1)"

# ---------------------------------------------------------------
# STATUS: in_progress — increment iteration and block with command
# ---------------------------------------------------------------
if [ "$STATUS" = "in_progress" ]; then
  if ! [[ "$ITERATION" =~ ^[0-9]+$ ]]; then
    debug_log "**WARNING:** iteration is not numeric ('$ITERATION'). Allowing stop."
    echo "WARNING: iteration field is not numeric ('$ITERATION') in $ACTIVE_STATE." >&2
    exit 0
  fi

  if [ -z "$COMMAND" ] || [ "$COMMAND" = "null" ]; then
    debug_log "**WARNING:** command field is empty in $ACTIVE_STATE. Allowing stop."
    echo "WARNING: command field is empty in $ACTIVE_STATE. Cannot re-feed command." >&2
    exit 0
  fi

  # Phase R → Phase S: Voice safety net
  # If research budget is reached but phase is still R, transition to Phase S: Voice
  if [ "$CURRENT_PHASE" = "Phase R: Research" ] && \
     [ -n "$TOTAL_RESEARCH" ] && [ "$TOTAL_RESEARCH" != "null" ] && \
     [ -n "$RESEARCH_BUDGET" ] && [ "$RESEARCH_BUDGET" != "null" ] && \
     [ "$TOTAL_RESEARCH" -ge "$RESEARCH_BUDGET" ] 2>/dev/null; then
    TEMP_PHASE=$(mktemp "${ACTIVE_STATE}.XXXXXX")
    yq --front-matter=process '.current_phase = "Phase S: Voice"' "$ACTIVE_STATE" > "$TEMP_PHASE"
    mv "$TEMP_PHASE" "$ACTIVE_STATE"
    debug_log "**Phase transition (safety net):** Phase R → Phase S: Voice for $NAME"
  fi

  # Increment iteration via sed + atomic temp file
  NEXT_ITERATION=$((ITERATION + 1))
  TEMP_FILE=$(mktemp "${ACTIVE_STATE}.XXXXXX")
  sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$ACTIVE_STATE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$ACTIVE_STATE"

  CLEAN_COMMAND=$(echo "$COMMAND" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  SYSTEM_MSG="Continuing research-report workflow iteration $NEXT_ITERATION (phase: $CURRENT_PHASE). State file: $ACTIVE_STATE"

  debug_log "**Blocking stop:** Incrementing iteration to $NEXT_ITERATION, re-feeding command."

  jq -n \
    --arg reason "$CLEAN_COMMAND" \
    --arg msg "$SYSTEM_MSG" \
    '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
  exit 0
fi

# ---------------------------------------------------------------
# STATUS: complete — verify completion criteria for research-report
# ---------------------------------------------------------------
if [ "$STATUS" = "complete" ]; then
  ERRORS=""
  TOPIC_NAME="$NAME"

  if [ "$WORKFLOW_TYPE" != "research-report" ]; then
    debug_log "**WARNING:** Unknown workflow_type '$WORKFLOW_TYPE'. Allowing stop."
    exit 0
  fi

  # Detect workflow mode: edit (Phase E:*) vs original creation (Phase R/S:*)
  IS_EDIT="false"
  case "$CURRENT_PHASE" in
    "Phase E:"*) IS_EDIT="true" ;;
  esac

  # ---- Original-creation-only checks (skipped for edits) ----
  if [ "$IS_EDIT" = "false" ]; then
    # Verify: research budget fulfilled (only for original creation; edit has separate edit_research_budget)
    if [ -n "$TOTAL_RESEARCH" ] && [ -n "$RESEARCH_BUDGET" ] && \
       [ "$TOTAL_RESEARCH" != "null" ] && [ "$RESEARCH_BUDGET" != "null" ] && \
       [ "$TOTAL_RESEARCH" -lt "$RESEARCH_BUDGET" ] 2>/dev/null; then
      ERRORS="${ERRORS}Research budget not fulfilled: total_iterations_research ($TOTAL_RESEARCH) < research_budget ($RESEARCH_BUDGET). "
    fi

    # Verify: all body chapters written (writing_chapter > chapter_count after last chapter)
    # During edit, writing_chapter is set to chapter_count+1 from initial reconstruction; checking would always pass but is meaningless.
    if [ -n "$CHAPTER_COUNT" ] && [ "$CHAPTER_COUNT" != "null" ] && \
       [ -n "$WRITING_CHAPTER" ] && [ "$WRITING_CHAPTER" != "null" ] && \
       [ "$WRITING_CHAPTER" -le "$CHAPTER_COUNT" ] 2>/dev/null; then
      ERRORS="${ERRORS}Body chapters incomplete: writing_chapter ($WRITING_CHAPTER) <= chapter_count ($CHAPTER_COUNT). "
    fi
  fi

  # ---- Checks that apply to BOTH original creation and edits ----

  # Verify: voice guide written (true for original creation; for edit, true since reconstruction sets it from existing artifact)
  if [ "$VOICE_GUIDE_WRITTEN" != "true" ]; then
    ERRORS="${ERRORS}Voice guide not written: voice_guide_written=$VOICE_GUIDE_WRITTEN (expected true). "
  fi

  # Verify: chapter arguments locked
  if [ "$CHAPTER_ARGS_LOCKED" != "true" ]; then
    ERRORS="${ERRORS}Chapter arguments not locked: chapter_arguments_locked=$CHAPTER_ARGS_LOCKED (expected true). "
  fi

  # Verify: back Conclusions written (must be true after edit's Rewrite-Conclusions step)
  if [ "$CONCLUSIONS_WRITTEN" != "true" ]; then
    ERRORS="${ERRORS}Back Conclusions not written: conclusions_written=$CONCLUSIONS_WRITTEN (expected true). "
  fi

  # Verify: front Synthesis written (must be true after edit's Rewrite-Front-Synthesis step)
  if [ "$FRONT_SYNTHESIS_WRITTEN" != "true" ]; then
    ERRORS="${ERRORS}Front Synthesis not written: front_synthesis_written=$FRONT_SYNTHESIS_WRITTEN (expected true). "
  fi

  # Verify: minimum reader passes completed (IDENTIFY + VERIFY floor; max is 5 with early termination)
  # For edit, reading_passes_completed is reset to 0 at edit start and re-incremented during edit's Read phase.
  if [ -n "$READING_PASSES_COMPLETED" ] && [ "$READING_PASSES_COMPLETED" != "null" ] && \
     [ "$READING_PASSES_COMPLETED" -lt "$MIN_READING_PASSES" ] 2>/dev/null; then
    ERRORS="${ERRORS}Reader passes incomplete: reading_passes_completed ($READING_PASSES_COMPLETED) < minimum required ($MIN_READING_PASSES — IDENTIFY + VERIFY). "
  fi

  # Verify: final phase is Compile (Phase S: Compile for original creation, Phase E: Compile for edit)
  EXPECTED_FINAL_PHASE="Phase S: Compile"
  [ "$IS_EDIT" = "true" ] && EXPECTED_FINAL_PHASE="Phase E: Compile"
  if [ "$CURRENT_PHASE" != "$EXPECTED_FINAL_PHASE" ]; then
    ERRORS="${ERRORS}Final phase not reached: current_phase is '$CURRENT_PHASE', expected '$EXPECTED_FINAL_PHASE'. "
  fi

  if [ -n "$ERRORS" ]; then
    debug_log "**Blocking stop (complete but verification failed):** $ERRORS"
    REASON="Workflow marked complete but verification failed: ${ERRORS}Fix state before stopping."
    jq -n --arg reason "$REASON" '{"decision": "block", "reason": $reason}'
    exit 0
  fi

  # Clean up state file for completed workflow
  rm -f ".plugin-state/research-report-${TOPIC_NAME}-state.md"
  debug_log "**Cleaned up:** Removed state file for topic '${TOPIC_NAME}'"

  debug_log "**Allowing stop:** Status is complete and all verification checks passed for $WORKFLOW_TYPE."
  exit 0
fi

# Unknown status — allow stop
debug_log "**Allowing stop:** Unknown status '$STATUS' in $ACTIVE_STATE"
exit 0
