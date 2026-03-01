#!/bin/bash
# ABOUTME: Auto-resume autonomous workflow after context reset (compact or clear).
# ABOUTME: Searches for active autonomous state files, parses YAML frontmatter, and injects context for Claude to continue.

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_ROOT="${REPO_ROOT:-.}"
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".claude/autonomous-auto-resume-debug.md"

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

# Log hook invocation
debug_log "**Hook invoked.**"

# Check for required dependencies (yq for YAML frontmatter, jq for JSON)
if ! command -v yq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** yq not found in PATH ($PATH)"
  echo "ERROR: yq is required but not installed." >&2
  echo "The auto-resume hook cannot parse workflow state files without yq." >&2
  echo "Install: brew install yq (macOS) or see https://github.com/mikefarah/yq#install" >&2
  exit 2
fi
if ! command -v jq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** jq not found in PATH ($PATH)"
  echo "ERROR: jq is required but not installed." >&2
  echo "The auto-resume hook cannot produce JSON output without jq." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 2
fi

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

# Only run after compact or clear
if [ "$SOURCE" != "compact" ] && [ "$SOURCE" != "clear" ]; then
  debug_log "**Exiting:** Source is '$SOURCE' (not compact or clear)"
  exit 0
fi

# Determine the trigger type for accurate messaging
if [ "$SOURCE" = "clear" ]; then
  TRIGGER_DESC="cleared"
else
  TRIGGER_DESC="compacted"
fi

# Find active autonomous workflow state file
# Check implementation state files first (later phases take priority)
ACTIVE_STATE=""
for state_file in docs/autonomous/*/implementation/*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# If no implementation state, check research state files
if [ -z "$ACTIVE_STATE" ]; then
  for state_file in docs/autonomous/*/research/*-state.md; do
    [ -f "$state_file" ] || continue
    status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
    if [ "$status" = "in_progress" ]; then
      ACTIVE_STATE="$state_file"
      break
    fi
  done
fi

# No active workflow — nothing to resume
if [ -z "$ACTIVE_STATE" ]; then
  debug_log "**Exiting:** No active autonomous workflow found"
  exit 0
fi

debug_log "**Active workflow found:** $ACTIVE_STATE"

# Extract fields from YAML frontmatter
WORKFLOW_TYPE=$(yq --front-matter=extract '.workflow_type' "$ACTIVE_STATE" 2>/dev/null)
CURRENT_PHASE=$(yq --front-matter=extract '.current_phase' "$ACTIVE_STATE" 2>/dev/null)
NAME=$(yq --front-matter=extract '.name' "$ACTIVE_STATE" 2>/dev/null)

STATE_DIR=$(dirname "$ACTIVE_STATE")
TOPIC_DIR=$(dirname "$STATE_DIR")
STATE_CONTENT=$(cat "$ACTIVE_STATE" 2>/dev/null)

# Build context restoration files list based on workflow type
RESEARCH_DIR="${TOPIC_DIR}/research"
IMPL_DIR="${TOPIC_DIR}/implementation"

RESTORE_FILES="- \`${ACTIVE_STATE}\` (state file — already included below)"

# Research report is always relevant
RESTORE_FILES="${RESTORE_FILES}
- \`${RESEARCH_DIR}/${NAME}-report.tex\` (research report)"

# Implementation plan is relevant for research-plan, full-auto, and implement modes
case "$WORKFLOW_TYPE" in
  autonomous-research-plan|autonomous-full-auto|autonomous-implement)
    RESTORE_FILES="${RESTORE_FILES}
- \`${IMPL_DIR}/${NAME}-implementation-plan.md\` (implementation plan)"
    ;;
esac

# Feature list and progress are relevant for full-auto and implement modes
case "$WORKFLOW_TYPE" in
  autonomous-full-auto|autonomous-implement)
    RESTORE_FILES="${RESTORE_FILES}
- \`${IMPL_DIR}/feature-list.json\` (implementation tracker)
- \`${IMPL_DIR}/progress.txt\` (progress log)"
    ;;
esac

RESTORE_FILES="${RESTORE_FILES}
- \`CLAUDE.md\` (project conventions)"

# Build context message
CONTEXT="## Autonomous Workflow Resumed After Context Reset

**Name**: ${NAME}
**Workflow Type**: ${WORKFLOW_TYPE}
**Current Phase**: ${CURRENT_PHASE}
**State File**: ${ACTIVE_STATE}
**Trigger**: Context was ${TRIGGER_DESC}

---

### Workflow State (from state file)

${STATE_CONTENT}

---

### Instructions

Context was ${TRIGGER_DESC} during an active autonomous workflow. To continue:

1. **FIRST**: Use the Skill tool to invoke \`autonomous-workflow:autonomous-workflow-guide\` to load workflow context
2. Review the workflow state above to understand current progress
3. Read the context restoration files listed below
4. Continue from where we left off in **${CURRENT_PHASE}**

**Context Restoration Files**:
${RESTORE_FILES}

**Continue the workflow now.** Read any additional files needed and proceed with the next action indicated in the state."

debug_log "**Injecting context.** Workflow: $NAME, type: $WORKFLOW_TYPE, phase: $CURRENT_PHASE, trigger: $TRIGGER_DESC"

# Escape context for JSON and output
ESCAPED_CONTEXT=$(echo "$CONTEXT" | jq -Rs .)

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED_CONTEXT
  }
}
EOF
