#!/bin/bash
# ABOUTME: Syncs Claude Code skills from this repo to global config (~/.claude/skills)
# ABOUTME: Use --overwrite flag to clear destination before copying

set -e

# Define paths
REPO_SKILLS_DIR="$(dirname "$0")/../../claude-code/skills"
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"

# Check if repo skills directory exists
if [ ! -d "$REPO_SKILLS_DIR" ]; then
    echo "Error: Repo skills directory not found at $REPO_SKILLS_DIR"
    exit 1
fi

# Create global skills directory if it doesn't exist
mkdir -p "$GLOBAL_SKILLS_DIR"

# Check for --overwrite flag
if [ "$1" == "--overwrite" ]; then
    echo "Overwrite mode: Clearing existing skills in global config..."
    # Only remove skill directories that exist in repo to avoid deleting unrelated skills
    for skill_dir in "$REPO_SKILLS_DIR"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            if [ -d "$GLOBAL_SKILLS_DIR/$skill_name" ]; then
                rm -rf "$GLOBAL_SKILLS_DIR/$skill_name"
            fi
        fi
    done
fi

# Copy all skill directories from repo to global
echo "Syncing skills from repo to global config..."
skill_count=0
for skill_dir in "$REPO_SKILLS_DIR"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        rm -rf "$GLOBAL_SKILLS_DIR/$skill_name"
        cp -r "$skill_dir" "$GLOBAL_SKILLS_DIR/$skill_name"
        echo "  - Copied skill: $skill_name"
        skill_count=$((skill_count + 1))
    fi
done

if [ $skill_count -eq 0 ]; then
    echo "No skill directories found in repo"
else
    echo "Successfully copied $skill_count skill(s)"
fi

echo "Sync complete!"
