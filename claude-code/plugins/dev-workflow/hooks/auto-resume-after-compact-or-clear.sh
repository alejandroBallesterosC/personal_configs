#!/bin/bash
# ABOUTME: Auto-resume TDD implementation or debug workflow after context reset (compact or clear)
# ABOUTME: Checks both docs/workflow-* and docs/debug/*/ for active sessions, parses YAML frontmatter, and injects context

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_ROOT="${REPO_ROOT:-.}"
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".claude/dev-auto-resume-debug.md"

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

# --- Check for TDD implementation workflow ---
# Loop through all workflow dirs, find first with active (non-complete) YAML status
TDD_STATE_FILE=""
TDD_ACTIVE=false
for state_file in docs/workflow-*/*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    TDD_STATE_FILE="$state_file"
    TDD_ACTIVE=true
    break
  elif [ -z "$status" ] && ! grep -qi "Current Phase.*COMPLETE\|^COMPLETE$" "$state_file" 2>/dev/null; then
    # Fallback: no YAML status field, check markdown body
    TDD_STATE_FILE="$state_file"
    TDD_ACTIVE=true
    break
  fi
done

# --- Check for debug workflow ---
# Loop through debug session dirs, skip archive directory, find first active session
DEBUG_STATE_FILE=""
DEBUG_ACTIVE=false
for state_file in docs/debug/*/*-state.md; do
  [ -f "$state_file" ] || continue
  # Skip the archive directory
  case "$state_file" in docs/archive/*) continue ;; esac
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    DEBUG_STATE_FILE="$state_file"
    DEBUG_ACTIVE=true
    break
  elif [ -z "$status" ] && ! grep -qi "Current Phase.*COMPLETE\|^COMPLETE$" "$state_file" 2>/dev/null; then
    # Fallback: no YAML status field, check markdown body
    DEBUG_STATE_FILE="$state_file"
    DEBUG_ACTIVE=true
    break
  fi
done

# No active workflow found
if [ "$TDD_ACTIVE" = false ] && [ "$DEBUG_ACTIVE" = false ]; then
  debug_log "**Exiting:** No active TDD or debug workflow found"
  exit 0
fi

debug_log "**Active workflows found:** TDD=$TDD_ACTIVE (${TDD_STATE_FILE:-none}), Debug=$DEBUG_ACTIVE (${DEBUG_STATE_FILE:-none})"

# Build context message
CONTEXT=""

# --- TDD implementation workflow context ---
if [ "$TDD_ACTIVE" = true ]; then
  WORKFLOW_DIR=$(dirname "$TDD_STATE_FILE")
  FEATURE=$(basename "$WORKFLOW_DIR" | sed 's/^workflow-//')
  TDD_STATE_CONTENT=$(cat "$TDD_STATE_FILE" 2>/dev/null)

  CONTEXT="## TDD Implementation Workflow Resumed After Context Reset

**Feature**: $FEATURE
**State File**: docs/workflow-$FEATURE/$FEATURE-state.md
**Trigger**: Context was $TRIGGER_DESC

---

### Workflow State (from state file)

$TDD_STATE_CONTENT

---

### Instructions

Context was $TRIGGER_DESC during an active TDD implementation workflow. To continue:

1. **FIRST**: Use the Skill tool to invoke \`dev-workflow:tdd-implementation-workflow-guide\` to load workflow context
2. Review the workflow state above to understand current progress
3. Read the context restoration files listed in the state above
4. Continue from where we left off

**Key files to read** (based on workflow artifacts):
- \`docs/workflow-$FEATURE/$FEATURE-state.md\` (already included above)
- \`docs/workflow-$FEATURE/$FEATURE-original-prompt.md\` (if exists - the original request)
- \`docs/workflow-$FEATURE/specs/$FEATURE-specs.md\` (if exists - the specification)
- \`docs/workflow-$FEATURE/plans/$FEATURE-implementation-plan.md\` (if exists - the implementation plan)
- \`docs/workflow-$FEATURE/plans/$FEATURE-architecture-plan.md\` (if exists - the architecture)
- \`docs/workflow-$FEATURE/codebase-context/$FEATURE-exploration.md\` (if exists - codebase exploration)
- \`CLAUDE.md\` (project conventions)

**Continue the workflow now.** Read any additional files needed and proceed with the next action indicated in the state."
fi

# --- Debug workflow context ---
if [ "$DEBUG_ACTIVE" = true ]; then
  SESSION_DIR=$(dirname "$DEBUG_STATE_FILE")
  BUG_NAME=$(basename "$SESSION_DIR")
  DEBUG_STATE_CONTENT=$(cat "$DEBUG_STATE_FILE" 2>/dev/null)

  # Add separator if both are active
  if [ -n "$CONTEXT" ]; then
    CONTEXT="$CONTEXT

---

"
  fi

  CONTEXT="${CONTEXT}## Debug Workflow Resumed After Context Reset

**Bug**: $BUG_NAME
**State File**: docs/debug/$BUG_NAME/$BUG_NAME-state.md
**Trigger**: Context was $TRIGGER_DESC

---

### Debug Session State (from state file)

$DEBUG_STATE_CONTENT

---

### Instructions

Context was $TRIGGER_DESC during an active debug session. To continue:

1. **FIRST**: Use the Skill tool to invoke \`dev-workflow:debug-workflow-guide\` to load workflow context
2. Review the session state above to understand current progress
3. Read the context restoration files listed in the state above
4. Continue from where we left off

**Key files to read** (based on debug artifacts):
- \`docs/debug/$BUG_NAME/$BUG_NAME-state.md\` (already included above)
- \`docs/debug/$BUG_NAME/$BUG_NAME-bug.md\` (if exists - the bug description)
- \`docs/debug/$BUG_NAME/$BUG_NAME-exploration.md\` (if exists - codebase exploration)
- \`docs/debug/$BUG_NAME/$BUG_NAME-hypotheses.md\` (if exists - ranked hypotheses)
- \`docs/debug/$BUG_NAME/$BUG_NAME-analysis.md\` (if exists - log analysis results)
- \`CLAUDE.md\` (project conventions)

**Continue the debug session now.** Read any additional files needed and proceed with the next action indicated in the state."
fi

# Escape the context for JSON
ESCAPED_CONTEXT=$(echo "$CONTEXT" | jq -Rs .)

debug_log "**Injecting context.** TDD=$TDD_ACTIVE, Debug=$DEBUG_ACTIVE, trigger=$TRIGGER_DESC"

# Output JSON with additionalContext
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED_CONTEXT
  }
}
EOF
