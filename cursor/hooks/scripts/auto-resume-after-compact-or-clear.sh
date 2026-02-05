#!/bin/bash
# ABOUTME: Auto-resume TDD workflow after context reset (compact or clear)
# ABOUTME: Reads state file and injects full context for seamless continuation

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

# Only run after compact or clear
if [ "$SOURCE" != "compact" ] && [ "$SOURCE" != "clear" ]; then
  exit 0
fi

# Find the most recently modified workflow state file
# New structure: docs/workflow-<feature>/<feature>-state.md
STATE_FILE=""
if ls -d docs/workflow-* 2>/dev/null | head -1 > /dev/null; then
  STATE_FILE=$(find docs/workflow-* -name "*-state.md" -type f 2>/dev/null | head -1)
fi

# No active workflow found
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if workflow is complete
if grep -qi "Current Phase.*COMPLETE\|^COMPLETE$" "$STATE_FILE" 2>/dev/null; then
  exit 0
fi

# Extract feature name from directory (docs/workflow-<feature>/<feature>-state.md)
WORKFLOW_DIR=$(dirname "$STATE_FILE")
FEATURE=$(basename "$WORKFLOW_DIR" | sed 's/^workflow-//')

# Read the entire state file content
STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null)

# Determine the trigger type for accurate messaging
if [ "$SOURCE" = "clear" ]; then
  TRIGGER_DESC="cleared"
else
  TRIGGER_DESC="compacted"
fi

# Build context message with full state file content
CONTEXT="## TDD Workflow Resumed After Context Reset

**Feature**: $FEATURE
**State File**: docs/workflow-$FEATURE/$FEATURE-state.md
**Trigger**: Context was $TRIGGER_DESC

---

### Workflow State (from state file)

$STATE_CONTENT

---

### Instructions

Context was $TRIGGER_DESC during an active TDD workflow. To continue:

1. **FIRST**: Use the Skill tool to invoke \`tdd-workflow-guide\` to load workflow context
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
