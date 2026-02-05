#!/bin/bash
# ABOUTME: Syncs the CLAUDE.md file from global config (~/.claude/CLAUDE.md) to this repo
# ABOUTME: This copies the main Claude configuration file from the global location

set -e

# Define paths
GLOBAL_CLAUDE_FILE="$HOME/.claude/CLAUDE.md"
REPO_CLAUDE_FILE="$(dirname "$0")/../../claude-code/CLAUDE.md"

# Check if global CLAUDE.md exists
if [ ! -f "$GLOBAL_CLAUDE_FILE" ]; then
    echo "Error: CLAUDE.md not found at $GLOBAL_CLAUDE_FILE"
    exit 1
fi

# Create repo claude-code directory if it doesn't exist
mkdir -p "$(dirname "$REPO_CLAUDE_FILE")"

# Copy CLAUDE.md from global to repo
echo "Syncing CLAUDE.md from global config to repo..."
cp -f "$GLOBAL_CLAUDE_FILE" "$REPO_CLAUDE_FILE"
echo "Successfully copied CLAUDE.md to $REPO_CLAUDE_FILE"

echo "Sync complete!"
