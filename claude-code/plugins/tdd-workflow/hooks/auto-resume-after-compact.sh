#!/bin/bash
# ABOUTME: Auto-resume TDD workflow after context compaction
# ABOUTME: Reads state file and injects full context for seamless continuation

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

# Only run after compaction
if [ "$SOURCE" != "compact" ]; then
  exit 0
fi

# Find the most recently modified workflow state file
STATE_FILE=""
if [ -d "docs/workflow" ]; then
  STATE_FILE=$(find docs/workflow -name "*-state.md" -type f 2>/dev/null | head -1)
fi

# No active workflow found
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if workflow is complete
if grep -qi "Current Phase.*COMPLETE\|^COMPLETE$" "$STATE_FILE" 2>/dev/null; then
  exit 0
fi

# Extract feature name from filename
FEATURE=$(basename "$STATE_FILE" | sed 's/-state\.md$//')

# Read the entire state file content
STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null)

# Build context message with full state file content
CONTEXT="## TDD Workflow Resumed After Compaction

**Feature**: $FEATURE
**State File**: docs/workflow/$FEATURE-state.md

---

### Workflow State (from state file)

$STATE_CONTENT

---

### Instructions

Context was compacted during an active TDD workflow. To continue:

1. Review the workflow state above to understand current progress
2. Use the **tdd-workflow-guide** skill if you need to understand workflow phases
3. Read the context restoration files listed in the state above
4. Continue from where we left off

**Key files to read** (based on workflow artifacts):
- \`docs/workflow/$FEATURE-state.md\` (already included above)
- \`docs/specs/$FEATURE.md\` (if exists - the specification)
- \`docs/plans/$FEATURE-plan.md\` (if exists - the implementation plan)
- \`docs/plans/$FEATURE-arch.md\` (if exists - the architecture)
- \`docs/context/$FEATURE-exploration.md\` (if exists - codebase exploration)
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
