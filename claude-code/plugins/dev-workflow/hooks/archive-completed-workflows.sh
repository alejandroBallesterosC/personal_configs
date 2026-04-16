#!/bin/bash
# ABOUTME: Archives completed workflow directories to .plugin-state/archive/ on Stop events
# ABOUTME: Ensures archival happens deterministically even if Claude skipped it during completion

# Anchor to git repo root for consistent state file discovery
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi
cd "$REPO_ROOT"

# Debug log file for diagnosing hook behavior
DEBUG_FILE=".plugin-state/archive-workflows-debug.log"

debug_log() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p .plugin-state
  {
    echo "## $timestamp"
    echo ""
    echo "$msg"
    echo ""
    echo "**Working directory:** $(pwd)"
    echo ""
    echo "---"
    echo ""
  } >> "$DEBUG_FILE"
}

# Log hook invocation
debug_log "**Hook invoked.**"

# Read and discard hook input from stdin (prevents EPIPE errors)
cat > /dev/null

# Check for yq dependency (required for YAML frontmatter parsing)
if ! command -v yq &>/dev/null; then
  debug_log "**DEPENDENCY MISSING:** yq not found in PATH ($PATH)"
  echo "ERROR: yq is required but not installed." >&2
  echo "The archive-completed-workflows hook cannot parse YAML frontmatter without yq." >&2
  echo "Install: brew install yq (macOS) or see https://github.com/mikefarah/yq#install" >&2
  exit 2
fi

# Check TDD workflows
for state_file in .plugin-state/workflow-*/*-state.md; do
  [ -f "$state_file" ] || continue
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "complete" ]; then
    workflow_dir=$(dirname "$state_file")
    name=$(basename "$workflow_dir")
    debug_log "**Archiving TDD workflow:** $name ($state_file -> .plugin-state/archive/$name)"
    mkdir -p .plugin-state/archive
    mv "$workflow_dir" ".plugin-state/archive/$name"
  fi
done

# Check debug workflows
for state_file in .plugin-state/debug/*/*-state.md; do
  [ -f "$state_file" ] || continue
  # Skip the archive directory
  case "$state_file" in .plugin-state/archive/*) continue ;; esac
  status=$(yq --front-matter=extract '.status' "$state_file" 2>/dev/null)
  if [ "$status" = "complete" ]; then
    session_dir=$(dirname "$state_file")
    name=$(basename "$session_dir")
    debug_log "**Archiving debug workflow:** $name ($state_file -> .plugin-state/archive/debug-$name)"
    mkdir -p .plugin-state/archive
    mv "$session_dir" ".plugin-state/archive/debug-$name"
  fi
done

debug_log "**Finished.** Scan complete."
exit 0
