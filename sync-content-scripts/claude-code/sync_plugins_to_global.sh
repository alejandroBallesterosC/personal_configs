#!/bin/bash
# ABOUTME: Syncs Claude Code plugins from this repo to global config (~/.claude/plugins)
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
REPO_PLUGINS_DIR="$(dirname "$0")/../../claude-code/plugins"
GLOBAL_PLUGINS_DIR="$HOME/.claude/plugins"

# Check if repo plugins directory exists
if [ ! -d "$REPO_PLUGINS_DIR" ]; then
    echo "Error: Repo plugins directory not found at $REPO_PLUGINS_DIR"
    exit 1
fi

# Create global plugins directory if it doesn't exist
mkdir -p "$GLOBAL_PLUGINS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing plugins in global config..."
    # Only remove plugin directories that exist in repo to avoid deleting unrelated plugins
    for plugin_dir in "$REPO_PLUGINS_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            plugin_name=$(basename "$plugin_dir")
            if [ -d "$GLOBAL_PLUGINS_DIR/$plugin_name" ]; then
                rm -rf "$GLOBAL_PLUGINS_DIR/$plugin_name"
            fi
        fi
    done
fi

# Copy all plugin directories from repo to global
echo "Syncing plugins from repo to global config..."
plugin_count=0
for plugin_dir in "$REPO_PLUGINS_DIR"/*; do
    if [ -d "$plugin_dir" ]; then
        plugin_name=$(basename "$plugin_dir")
        rm -rf "$GLOBAL_PLUGINS_DIR/$plugin_name"
        cp -r "$plugin_dir" "$GLOBAL_PLUGINS_DIR/$plugin_name"
        echo "  - Copied plugin: $plugin_name"
        plugin_count=$((plugin_count + 1))
    fi
done

if [ $plugin_count -eq 0 ]; then
    echo "No plugin directories found in repo"
else
    echo "Successfully copied $plugin_count plugin(s)"
fi

# Copy marketplace manifest if it exists
if [ -d "$REPO_PLUGINS_DIR/.claude-plugin" ]; then
    mkdir -p "$GLOBAL_PLUGINS_DIR/.claude-plugin"
    cp -r "$REPO_PLUGINS_DIR/.claude-plugin/"* "$GLOBAL_PLUGINS_DIR/.claude-plugin/"
    echo "  - Copied marketplace manifest"
fi

echo "Sync complete!"
echo ""
echo "To load a plugin, run: claude --plugin-dir ~/.claude/plugins/<plugin-name>"
echo "Or add a local marketplace: /plugin marketplace add ~/.claude/plugins"
