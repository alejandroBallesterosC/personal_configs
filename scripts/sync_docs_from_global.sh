#!/bin/bash
# ABOUTME: Syncs Claude Code docs from global config (~/.claude/docs) to this repo
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
GLOBAL_DOCS_DIR="$HOME/.claude/docs"
REPO_DOCS_DIR="$(dirname "$0")/../claude-code/docs"

# Check if global docs directory exists
if [ ! -d "$GLOBAL_DOCS_DIR" ]; then
    echo "Error: Global Claude Code docs directory not found at $GLOBAL_DOCS_DIR"
    exit 1
fi

# Create repo docs directory if it doesn't exist
mkdir -p "$REPO_DOCS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing docs in repo..."
    rm -f "$REPO_DOCS_DIR"/*.md
fi

# Copy all .md files from global to repo
echo "Syncing docs from global config to repo..."
if [ -n "$(ls -A "$GLOBAL_DOCS_DIR"/*.md 2>/dev/null)" ]; then
    cp -f "$GLOBAL_DOCS_DIR"/*.md "$REPO_DOCS_DIR/"
    echo "Successfully copied $(ls -1 "$GLOBAL_DOCS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') doc(s)"
else
    echo "No .md doc files found in global config"
fi

echo "Sync complete!"