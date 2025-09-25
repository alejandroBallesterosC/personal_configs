#!/bin/bash
# ABOUTME: Syncs MCP configuration from global config (~/.claude/mcp.json) to this repo
# ABOUTME: Use --overwrite flag to replace existing configuration

set -e

# Define paths
GLOBAL_MCP_FILE="$HOME/.claude/mcp.json"
REPO_MCP_FILE="$(dirname "$0")/../claude-code/mcp.json"

# Check if global MCP file exists
if [ ! -f "$GLOBAL_MCP_FILE" ]; then
    echo "Error: Global MCP configuration not found at $GLOBAL_MCP_FILE"
    exit 1
fi

# Create repo claude-code directory if it doesn't exist
REPO_CLAUDE_DIR="$(dirname "$0")/../claude-code"
mkdir -p "$REPO_CLAUDE_DIR"

# Check for --overwrite flag or if file doesn't exist
if [ "$1" == "--overwrite" ] || [ ! -f "$REPO_MCP_FILE" ]; then
    if [ -f "$REPO_MCP_FILE" ] && [ "$1" == "--overwrite" ]; then
        echo "Overwrite mode: Replacing existing MCP configuration in repo..."
    fi

    # Copy MCP configuration from global to repo
    echo "Syncing MCP configuration from global config to repo..."
    cp -f "$GLOBAL_MCP_FILE" "$REPO_MCP_FILE"

    echo "Successfully copied MCP configuration"
else
    echo "MCP configuration already exists in repo. Use --overwrite flag to replace it."
    exit 1
fi

echo "Sync complete!"