#!/bin/bash
# ABOUTME: Archives completed workflow directories to docs/archive/ on Stop events
# ABOUTME: Ensures archival happens deterministically even if Claude skipped it during completion

# Check for yq dependency (required for YAML frontmatter parsing)
if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required but not installed." >&2
  echo "The archive-completed-workflows hook cannot parse YAML frontmatter without yq." >&2
  echo "Install: brew install yq (macOS) or see https://github.com/mikefarah/yq#install" >&2
  exit 1
fi

# Find git repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0
cd "$REPO_ROOT"

# Check TDD workflows
for state_file in docs/workflow-*/*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "complete" ]; then
    workflow_dir=$(dirname "$state_file")
    name=$(basename "$workflow_dir")
    mkdir -p docs/archive
    mv "$workflow_dir" "docs/archive/$name"
  fi
done

# Check debug workflows
for state_file in docs/debug/*/*-state.md; do
  [ -f "$state_file" ] || continue
  # Skip the archive directory
  case "$state_file" in docs/archive/*) continue ;; esac
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "complete" ]; then
    session_dir=$(dirname "$state_file")
    name=$(basename "$session_dir")
    mkdir -p docs/archive
    mv "$session_dir" "docs/archive/debug-$name"
  fi
done

exit 0
