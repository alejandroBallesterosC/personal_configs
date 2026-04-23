#!/bin/bash
# ABOUTME: Auto-resume research-report workflow after context reset (compact or clear).
# ABOUTME: Searches for active research-report state files, parses YAML frontmatter, and injects context for Claude to continue.

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_ROOT="${REPO_ROOT:-.}"
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".plugin-state/research-report-auto-resume-debug.log"

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

# Find active research-report workflow state file
# State files live at .plugin-state/research-report-<topic>-state.md
ACTIVE_STATE=""
for state_file in .plugin-state/research-report-*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "in_progress" ]; then
    ACTIVE_STATE="$state_file"
    break
  fi
done

# No active workflow — nothing to resume
if [ -z "$ACTIVE_STATE" ]; then
  debug_log "**Exiting:** No active research-report workflow found"
  exit 0
fi

debug_log "**Active workflow found:** $ACTIVE_STATE"

# Extract fields from YAML frontmatter
WORKFLOW_TYPE=$(yq --front-matter=extract '.workflow_type' "$ACTIVE_STATE" 2>/dev/null)
CURRENT_PHASE=$(yq --front-matter=extract '.current_phase' "$ACTIVE_STATE" 2>/dev/null)
NAME=$(yq --front-matter=extract '.name' "$ACTIVE_STATE" 2>/dev/null)

STATE_CONTENT=$(cat "$ACTIVE_STATE" 2>/dev/null)

# Build artifact list for research-report workflows
RESTORE_FILES="- \`${ACTIVE_STATE}\` (state file — already included below)
- \`docs/research-report/${NAME}/${NAME}-report.tex\` (research report)
- \`docs/research-report/${NAME}/evidence-pool.jsonl\` (structured findings — Phase R output)
- \`docs/research-report/${NAME}/chapter-arguments.json\` (chapter-level argument hypotheses — Phase O output)
- \`docs/research-report/${NAME}/voice-guide.md\` (single-authorial-voice spec — Phase S Voice output, may not exist yet)
- \`docs/research-report/${NAME}/research-progress.md\` (high-level living summary)
- \`CLAUDE.md\` (project conventions)"

# Build context message
# Output as plain text to stdout.
# This is more reliable than the additionalContext JSON format,
# which has a confirmed bug (#28305) with the compact matcher.
CONTEXT="## Research Report Workflow Resumed After Context Reset

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

Context was ${TRIGGER_DESC} during an active research-report workflow. To continue:

1. **FIRST**: Use the Skill tool to invoke \`research-report:research-report-guide\` to load workflow context
2. Review the workflow state above to understand current progress
3. Read the context restoration files listed below
4. Continue from where we left off in **${CURRENT_PHASE}**

**Context Restoration Files**:
${RESTORE_FILES}

**Continue the workflow now.** Read any additional files needed and proceed with the next action indicated in the state."

debug_log "**Injecting context.** Workflow: $NAME, type: $WORKFLOW_TYPE, phase: $CURRENT_PHASE, trigger: $TRIGGER_DESC"

echo "$CONTEXT"
