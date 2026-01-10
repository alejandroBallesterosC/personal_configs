#!/bin/bash
# ABOUTME: Syncs Claude Code plugins from global config (~/.claude/plugins) to this repo
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
GLOBAL_PLUGINS_DIR="$HOME/.claude/plugins"
REPO_PLUGINS_DIR="$(dirname "$0")/../claude-code/plugins"

# Check if global plugins directory exists
if [ ! -d "$GLOBAL_PLUGINS_DIR" ]; then
    echo "Error: Global Claude Code plugins directory not found at $GLOBAL_PLUGINS_DIR"
    exit 1
fi

# Create repo plugins directory if it doesn't exist
mkdir -p "$REPO_PLUGINS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing plugins in repo..."
    # Only remove plugin directories that exist in global to avoid deleting unrelated plugins
    for plugin_dir in "$GLOBAL_PLUGINS_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            plugin_name=$(basename "$plugin_dir")
            if [ -d "$REPO_PLUGINS_DIR/$plugin_name" ]; then
                rm -rf "$REPO_PLUGINS_DIR/$plugin_name"
            fi
        fi
    done
fi

# Copy all plugin directories from global to repo
echo "Syncing plugins from global config to repo..."
plugin_count=0
for plugin_dir in "$GLOBAL_PLUGINS_DIR"/*; do
    if [ -d "$plugin_dir" ]; then
        plugin_name=$(basename "$plugin_dir")
        rm -rf "$REPO_PLUGINS_DIR/$plugin_name"
        cp -r "$plugin_dir" "$REPO_PLUGINS_DIR/$plugin_name"
        echo "  - Copied plugin: $plugin_name"
        plugin_count=$((plugin_count + 1))
    fi
done

if [ $plugin_count -eq 0 ]; then
    echo "No plugin directories found in global config"
else
    echo "Successfully copied $plugin_count plugin(s)"
fi

echo "Sync complete!"
