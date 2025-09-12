#!/bin/bash
# ABOUTME: Syncs Claude Code docs from this repo to global config (~/.claude/docs)
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
REPO_DOCS_DIR="$(dirname "$0")/../claude-code/docs"
GLOBAL_DOCS_DIR="$HOME/.claude/docs"

# Check if repo docs directory exists
if [ ! -d "$REPO_DOCS_DIR" ]; then
    echo "Error: Repo docs directory not found at $REPO_DOCS_DIR"
    exit 1
fi

# Create global docs directory if it doesn't exist
mkdir -p "$GLOBAL_DOCS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing docs in global config..."
    rm -f "$GLOBAL_DOCS_DIR"/*.md
fi

# Copy all .md files from repo to global
echo "Syncing docs from repo to global config..."
if [ -n "$(ls -A "$REPO_DOCS_DIR"/*.md 2>/dev/null)" ]; then
    cp -f "$REPO_DOCS_DIR"/*.md "$GLOBAL_DOCS_DIR/"
    echo "Successfully copied $(ls -1 "$REPO_DOCS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') doc(s)"
else
    echo "No .md doc files found in repo"
fi

echo "Sync complete!"