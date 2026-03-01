#!/bin/bash
# ABOUTME: SessionStart hook that restores autonomous workflow context after compact/clear.
# ABOUTME: Reads state file and outputs context restoration instructions for the main instance.

set -euo pipefail

# Hard dependency: jq for JSON output
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed." >&2
  echo "The auto-resume hook cannot produce JSON output without jq." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 1
fi

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

# Only run after compact or clear
if [ "$SOURCE" != "compact" ] && [ "$SOURCE" != "clear" ]; then
  exit 0
fi

if [ "$SOURCE" = "clear" ]; then
  TRIGGER_DESC="cleared"
else
  TRIGGER_DESC="compacted"
fi

# Find active autonomous workflow state file
ACTIVE_STATE=""
for state_file in docs/autonomous/*/research/*-state.md docs/autonomous/*/implementation/*-state.md; do
  [ -f "$state_file" ] || continue
  # Parse YAML frontmatter using sed/grep (no yq dependency)
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$state_file")
  STATUS=$(echo "$FRONTMATTER" | grep '^status:' | sed 's/status: *//' | sed "s/^['\"]//;s/['\"]$//")
  if [ "$STATUS" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# No active workflow — nothing to resume
if [ -z "$ACTIVE_STATE" ]; then
  exit 0
fi

# Extract fields from YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$ACTIVE_STATE")
WORKFLOW_TYPE=$(echo "$FRONTMATTER" | grep '^workflow_type:' | sed 's/workflow_type: *//' | sed "s/^['\"]//;s/['\"]$//")
CURRENT_PHASE=$(echo "$FRONTMATTER" | grep '^current_phase:' | sed 's/current_phase: *//' | sed "s/^['\"]//;s/['\"]$//")
NAME=$(echo "$FRONTMATTER" | grep '^name:' | sed 's/name: *//' | sed "s/^['\"]//;s/['\"]$//")

STATE_DIR=$(dirname "$ACTIVE_STATE")
TOPIC_DIR=$(dirname "$STATE_DIR")
STATE_CONTENT=$(cat "$ACTIVE_STATE" 2>/dev/null)

# Build context restoration files list based on directory context
RESTORE_FILES="- \`${ACTIVE_STATE}\` (state file — already included below)"

# Research report is always in the research directory
RESEARCH_DIR="${TOPIC_DIR}/research"
IMPL_DIR="${TOPIC_DIR}/implementation"

RESTORE_FILES="${RESTORE_FILES}
- \`${RESEARCH_DIR}/${NAME}-report.tex\` (research report)"

case "$WORKFLOW_TYPE" in
  autonomous-research-plan|autonomous-full-auto|autonomous-implement)
    RESTORE_FILES="${RESTORE_FILES}
- \`${IMPL_DIR}/${NAME}-implementation-plan.md\` (implementation plan)"
    ;;
esac

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
