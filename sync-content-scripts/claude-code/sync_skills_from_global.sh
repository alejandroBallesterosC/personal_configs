#!/bin/bash
# ABOUTME: Syncs Claude Code skills from global config (~/.claude/skills) to this repo
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"
REPO_SKILLS_DIR="$(dirname "$0")/../../claude-code/skills"

# Check if global skills directory exists
if [ ! -d "$GLOBAL_SKILLS_DIR" ]; then
    echo "Error: Global Claude Code skills directory not found at $GLOBAL_SKILLS_DIR"
    exit 1
fi

# Create repo skills directory if it doesn't exist
mkdir -p "$REPO_SKILLS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing skills in repo..."
    # Only remove skill directories that exist in global to avoid deleting unrelated skills
    for skill_dir in "$GLOBAL_SKILLS_DIR"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            if [ -d "$REPO_SKILLS_DIR/$skill_name" ]; then
                rm -rf "$REPO_SKILLS_DIR/$skill_name"
            fi
        fi
    done
fi

# Copy all skill directories from global to repo
echo "Syncing skills from global config to repo..."
skill_count=0
for skill_dir in "$GLOBAL_SKILLS_DIR"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        rm -rf "$REPO_SKILLS_DIR/$skill_name"
        cp -r "$skill_dir" "$REPO_SKILLS_DIR/$skill_name"
        echo "  - Copied skill: $skill_name"
        skill_count=$((skill_count + 1))
    fi
done

if [ $skill_count -eq 0 ]; then
    echo "No skill directories found in global config"
else
    echo "Successfully copied $skill_count skill(s)"
fi

echo "Sync complete!"
