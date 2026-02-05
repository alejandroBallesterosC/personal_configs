#!/bin/bash
# ABOUTME: Auto-resume debug workflow after context reset (compact or clear)
# ABOUTME: Reads state file and injects full context for seamless continuation

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

# Only run after compact or clear
if [ "$SOURCE" != "compact" ] && [ "$SOURCE" != "clear" ]; then
  exit 0
fi

# Find the most recently modified debug state file
# Structure: docs/debug/<bug-name>/<bug-name>-state.md
STATE_FILE=""
if ls -d docs/debug/*/ 2>/dev/null | head -1 > /dev/null; then
  STATE_FILE=$(find docs/debug -name "*-state.md" -type f 2>/dev/null | head -1)
fi

# No active debug session found
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if session is complete
if grep -qi "Current Phase.*COMPLETE\|^COMPLETE$" "$STATE_FILE" 2>/dev/null; then
  exit 0
fi

# Extract bug name from directory (docs/debug/<bug-name>/<bug-name>-state.md)
SESSION_DIR=$(dirname "$STATE_FILE")
BUG_NAME=$(basename "$SESSION_DIR")

# Read the entire state file content
STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null)

# Determine the trigger type for accurate messaging
if [ "$SOURCE" = "clear" ]; then
  TRIGGER_DESC="cleared"
else
  TRIGGER_DESC="compacted"
fi

# Build context message with full state file content
CONTEXT="## Debug Workflow Resumed After Context Reset

**Bug**: $BUG_NAME
**State File**: docs/debug/$BUG_NAME/$BUG_NAME-state.md
**Trigger**: Context was $TRIGGER_DESC

---

### Debug Session State (from state file)

$STATE_CONTENT

---

### Instructions

Context was $TRIGGER_DESC during an active debug session. To continue:

1. **FIRST**: Use the Skill tool to invoke \`debug-workflow:debug-workflow-guide\` to load workflow context
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

# Escape the context for JSON
ESCAPED_CONTEXT=$(echo "$CONTEXT" | jq -Rs .)

# Output JSON with additionalContext
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED_CONTEXT
  }
}
EOF
