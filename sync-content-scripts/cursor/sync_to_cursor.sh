#!/bin/bash
# ABOUTME: Syncs cursor components from personal_configs to ~/.cursor/
# ABOUTME: Creates directories, copies files, sets permissions, warns about hooks.json merge

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")/../cursor"
TARGET_DIR="$HOME/.cursor"

echo "=== Syncing to Cursor ==="
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create target directories
echo "Creating directories..."
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/skills"
mkdir -p "$TARGET_DIR/subagents"
mkdir -p "$TARGET_DIR/hooks/scripts"

# Sync commands
if [ -d "$SOURCE_DIR/commands" ] && [ "$(ls -A "$SOURCE_DIR/commands" 2>/dev/null)" ]; then
    echo "Syncing commands..."
    cp -r "$SOURCE_DIR/commands/"* "$TARGET_DIR/commands/"
    echo "  - $(ls "$SOURCE_DIR/commands/" | wc -l | tr -d ' ') command files"
fi

# Sync skills (includes playwright with runtime files)
if [ -d "$SOURCE_DIR/skills" ] && [ "$(ls -A "$SOURCE_DIR/skills" 2>/dev/null)" ]; then
    echo "Syncing skills..."
    cp -r "$SOURCE_DIR/skills/"* "$TARGET_DIR/skills/"
    # Make playwright executor executable
    if [ -f "$TARGET_DIR/skills/playwright/run.js" ]; then
        chmod +x "$TARGET_DIR/skills/playwright/run.js"
    fi
    echo "  - $(ls -d "$SOURCE_DIR/skills/"*/ 2>/dev/null | wc -l | tr -d ' ') skill directories"
fi

# Sync subagents
if [ -d "$SOURCE_DIR/subagents" ] && [ "$(ls "$SOURCE_DIR/subagents/"*.md 2>/dev/null)" ]; then
    echo "Syncing subagents..."
    cp "$SOURCE_DIR/subagents/"*.md "$TARGET_DIR/subagents/"
    echo "  - $(ls "$SOURCE_DIR/subagents/"*.md | wc -l | tr -d ' ') subagent files"
fi

# Sync hook scripts
if [ -d "$SOURCE_DIR/hooks/scripts" ] && [ "$(ls "$SOURCE_DIR/hooks/scripts/"*.sh 2>/dev/null)" ]; then
    echo "Syncing hook scripts..."
    cp "$SOURCE_DIR/hooks/scripts/"*.sh "$TARGET_DIR/hooks/scripts/"
    chmod +x "$TARGET_DIR/hooks/scripts/"*.sh
    echo "  - $(ls "$SOURCE_DIR/hooks/scripts/"*.sh | wc -l | tr -d ' ') hook scripts"
fi

# Handle hooks.json
echo ""
echo "=== hooks.json ==="
if [ -f "$TARGET_DIR/hooks.json" ]; then
    echo "WARNING: $TARGET_DIR/hooks.json already exists!"
    echo "You must manually merge the hook configurations."
    echo ""
    echo "Source: $SOURCE_DIR/hooks/hooks.json"
    echo "Backup: $TARGET_DIR/hooks.json.bak"
    cp "$TARGET_DIR/hooks.json" "$TARGET_DIR/hooks.json.bak"
else
    if [ -f "$SOURCE_DIR/hooks/hooks.json" ]; then
        echo "No existing hooks.json found. Copying..."
        cp "$SOURCE_DIR/hooks/hooks.json" "$TARGET_DIR/hooks.json"
        echo "  - hooks.json installed"
    fi
fi

echo ""
echo "=== Sync Complete ==="
echo ""
echo "Installed to $TARGET_DIR:"
echo "  commands/     - $(ls "$TARGET_DIR/commands/" 2>/dev/null | wc -l | tr -d ' ') files"
echo "  skills/       - $(ls -d "$TARGET_DIR/skills/"*/ 2>/dev/null | wc -l | tr -d ' ') directories"
echo "  subagents/    - $(ls "$TARGET_DIR/subagents/"*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "  hooks/scripts - $(ls "$TARGET_DIR/hooks/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ') scripts"

# Check if playwright needs setup
if [ -f "$TARGET_DIR/skills/playwright/run.js" ] && [ ! -d "$TARGET_DIR/skills/playwright/node_modules" ]; then
    echo ""
    echo "NOTE: Playwright skill not yet set up. Run:"
    echo "  cd $TARGET_DIR/skills/playwright && npm run setup"
fi

echo ""
echo "Restart Cursor to pick up changes."
