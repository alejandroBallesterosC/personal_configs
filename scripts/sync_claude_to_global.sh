#!/bin/bash
# ABOUTME: Syncs the CLAUDE.md file from this repo to global config (~/.claude/CLAUDE.md)
# ABOUTME: This copies the main Claude configuration file to the global location

set -e

# Define paths
REPO_CLAUDE_FILE="$(dirname "$0")/../claude-code/CLAUDE.md"
GLOBAL_CLAUDE_FILE="$HOME/.claude/CLAUDE.md"

# Check if repo CLAUDE.md exists
if [ ! -f "$REPO_CLAUDE_FILE" ]; then
    echo "Error: CLAUDE.md not found at $REPO_CLAUDE_FILE"
    exit 1
fi

# Create global .claude directory if it doesn't exist
mkdir -p "$(dirname "$GLOBAL_CLAUDE_FILE")"

# Copy CLAUDE.md from repo to global
echo "Syncing CLAUDE.md from repo to global config..."
cp -f "$REPO_CLAUDE_FILE" "$GLOBAL_CLAUDE_FILE"
echo "Successfully copied CLAUDE.md to $GLOBAL_CLAUDE_FILE"

echo "Sync complete!"
