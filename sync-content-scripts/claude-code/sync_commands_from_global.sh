#!/bin/bash
# ABOUTME: Syncs Claude Code commands from global config (~/.claude/commands) to this repo
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
REPO_COMMANDS_DIR="$(dirname "$0")/../../claude-code/commands"

# Check if global commands directory exists
if [ ! -d "$GLOBAL_COMMANDS_DIR" ]; then
    echo "Error: Global Claude Code commands directory not found at $GLOBAL_COMMANDS_DIR"
    exit 1
fi

# Create repo commands directory if it doesn't exist
mkdir -p "$REPO_COMMANDS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing commands in repo..."
    rm -f "$REPO_COMMANDS_DIR"/*.md
fi

# Copy all .md files from global to repo
echo "Syncing commands from global config to repo..."
if [ -n "$(ls -A "$GLOBAL_COMMANDS_DIR"/*.md 2>/dev/null)" ]; then
    cp -f "$GLOBAL_COMMANDS_DIR"/*.md "$REPO_COMMANDS_DIR/"
    echo "Successfully copied $(ls -1 "$GLOBAL_COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') command(s)"
else
    echo "No .md command files found in global config"
fi

echo "Sync complete!"