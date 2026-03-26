#!/bin/bash
# ABOUTME: Creates symlinks from ~/.claude/ to this repo for CLAUDE.md, commands/, and docs/.
# ABOUTME: Replaces the copy-based sync scripts with a single symlink setup.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_CODE_DIR="$REPO_ROOT/claude-code"
GLOBAL_CLAUDE_DIR="$HOME/.claude"

# Validate source files exist
for source in "$CLAUDE_CODE_DIR/CLAUDE.md" "$CLAUDE_CODE_DIR/commands" "$CLAUDE_CODE_DIR/docs"; do
    if [ ! -e "$source" ]; then
        echo "Error: Source not found: $source"
        exit 1
    fi
done

mkdir -p "$GLOBAL_CLAUDE_DIR"

# Define symlinks: "target|source" pairs
LINKS=(
    "$GLOBAL_CLAUDE_DIR/CLAUDE.md|$CLAUDE_CODE_DIR/CLAUDE.md"
    "$GLOBAL_CLAUDE_DIR/commands|$CLAUDE_CODE_DIR/commands"
    "$GLOBAL_CLAUDE_DIR/docs|$CLAUDE_CODE_DIR/docs"
)

for entry in "${LINKS[@]}"; do
    target="${entry%%|*}"
    source="${entry##*|}"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$source" ]; then
            echo "Already linked: $target -> $source"
            continue
        fi
        echo "Updating symlink: $target -> $source (was $existing)"
        rm "$target"
    elif [ -e "$target" ]; then
        echo "Backing up existing $target to ${target}.bak"
        mv "$target" "${target}.bak"
    fi

    ln -s "$source" "$target"
    echo "Linked: $target -> $source"
done

echo "Done. All symlinks are set up."
