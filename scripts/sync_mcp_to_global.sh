#!/bin/bash
# ABOUTME: Syncs MCP configuration from this repo to global config (~/.claude/mcp.json)
# ABOUTME: Use --overwrite flag to replace existing configuration

set -e

# Define paths
REPO_MCP_FILE="$(dirname "$0")/../claude-code/mcp.json"
GLOBAL_MCP_FILE="$HOME/.claude/mcp.json"

# Check if repo MCP file exists
if [ ! -f "$REPO_MCP_FILE" ]; then
    echo "Error: Repo MCP configuration not found at $REPO_MCP_FILE"
    exit 1
fi

# Create global claude directory if it doesn't exist
GLOBAL_CLAUDE_DIR="$HOME/.claude"
mkdir -p "$GLOBAL_CLAUDE_DIR"

# Check for --overwrite flag or if file doesn't exist
if [ "$1" == "--overwrite" ] || [ ! -f "$GLOBAL_MCP_FILE" ]; then
    if [ -f "$GLOBAL_MCP_FILE" ] && [ "$1" == "--overwrite" ]; then
        echo "Overwrite mode: Replacing existing MCP configuration in global config..."
    fi

    # Copy MCP configuration from repo to global
    echo "Syncing MCP configuration from repo to global config..."
    cp -f "$REPO_MCP_FILE" "$GLOBAL_MCP_FILE"

    echo "Successfully copied MCP configuration"
else
    echo "MCP configuration already exists in global config. Use --overwrite flag to replace it."
    exit 1
fi

echo "Sync complete!"