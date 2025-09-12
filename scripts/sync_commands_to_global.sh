#!/bin/bash
# ABOUTME: Syncs Claude Code commands from this repo to global config (~/.claude/commands)
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
REPO_COMMANDS_DIR="$(dirname "$0")/../claude-code/commands"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"

# Check if repo commands directory exists
if [ ! -d "$REPO_COMMANDS_DIR" ]; then
    echo "Error: Repo commands directory not found at $REPO_COMMANDS_DIR"
    exit 1
fi

# Create global commands directory if it doesn't exist
mkdir -p "$GLOBAL_COMMANDS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing commands in global config..."
    rm -f "$GLOBAL_COMMANDS_DIR"/*.md
fi

# Copy all .md files from repo to global
echo "Syncing commands from repo to global config..."
if [ -n "$(ls -A "$REPO_COMMANDS_DIR"/*.md 2>/dev/null)" ]; then
    cp -f "$REPO_COMMANDS_DIR"/*.md "$GLOBAL_COMMANDS_DIR/"
    echo "Successfully copied $(ls -1 "$REPO_COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') command(s)"
else
    echo "No .md command files found in repo"
fi

echo "Sync complete!"