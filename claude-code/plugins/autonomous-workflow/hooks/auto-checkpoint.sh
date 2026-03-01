#!/bin/bash
# ABOUTME: PreCompact hook that saves transcript and state before context compaction.
# ABOUTME: Prevents loss of research context during long-running autonomous workflows.

set -euo pipefail

# Hard dependency: jq for JSON parsing
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed." >&2
  echo "The auto-checkpoint hook cannot parse JSON without jq." >&2
  echo "Install: brew install jq (macOS) or see https://github.com/jqlang/jq#installation" >&2
  exit 1
fi

# Read hook input from stdin
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

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

# No active workflow — nothing to checkpoint
if [ -z "$ACTIVE_STATE" ]; then
  exit 0
fi

# Extract topic name from directory path (topic is two levels up from state file)
STATE_DIR=$(dirname "$ACTIVE_STATE")
TOPIC=$(basename "$(dirname "$STATE_DIR")")
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create transcripts directory if needed
TRANSCRIPTS_DIR="$STATE_DIR/transcripts"
mkdir -p "$TRANSCRIPTS_DIR"

# Save transcript snapshot (if available)
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  cp "$TRANSCRIPT_PATH" "$TRANSCRIPTS_DIR/${TIMESTAMP}-transcript.jsonl"
fi

# Save state file snapshot
cp "$ACTIVE_STATE" "$TRANSCRIPTS_DIR/${TIMESTAMP}-state.md"

# Append compaction event to progress.txt (if it exists)
# progress.txt lives in the implementation directory
if echo "$STATE_DIR" | grep -q '/implementation$'; then
  PROGRESS_FILE="$STATE_DIR/progress.txt"
else
  PROGRESS_FILE="$(dirname "$STATE_DIR")/implementation/progress.txt"
fi
if [ -f "$PROGRESS_FILE" ]; then
  echo "[${TIMESTAMP}] COMPACTION EVENT: transcript and state saved to transcripts/" >> "$PROGRESS_FILE"
fi

exit 0
