#!/bin/bash
# ABOUTME: Stop hook that prompts Claude to document meaningful learnings and
# ABOUTME: update project documentation after implementation work with file changes.

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Avoid infinite loop - if already triggered by a stop hook, allow stop
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
CWD=$(echo "$INPUT" | jq -r '.cwd')

# Only trigger if we're in a git repo with changes that differ from session baseline
HAS_NEW_CHANGES=false
if cd "$CWD" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BASELINE_FILE="/tmp/claude-git-baseline-${SESSION_ID}"
  CURRENT_FILE="/tmp/claude-git-current-${SESSION_ID}"
  git status --porcelain > "$CURRENT_FILE"

  if [ -f "$BASELINE_FILE" ]; then
    # Compare against session start baseline
    if ! diff -q "$BASELINE_FILE" "$CURRENT_FILE" >/dev/null 2>&1; then
      HAS_NEW_CHANGES=true
    fi
  else
    # No baseline exists — fall back to checking if any changes exist at all
    if [ -s "$CURRENT_FILE" ]; then
      HAS_NEW_CHANGES=true
    fi
  fi

  rm -f "$CURRENT_FILE"
fi

if [ "$HAS_NEW_CHANGES" = "false" ]; then
  exit 0
fi

# Implementation work detected - prompt Claude to document learnings
cat <<'HOOK_EOF'
{"decision": "block", "reason": "DOCUMENTATION HOOK: You just completed implementation work that produced file changes. Before finishing, do the following:\n\n1. **Reflect on learnings**: Were there meaningful architectural decisions, non-obvious solutions, debugging insights, configuration changes, or important patterns discovered during this work?\n\n2. **Update project documentation**: If yes, update the CLAUDE.md in the root of this repo and any other RELEVANT existing documentation files in the project (check CLAUDE.md for the documentation reference). Prefer updating existing docs over creating new ones. Only create a new doc file if the learnings truly don't fit anywhere existing.\n\n3. **Update auto-memory**: If any learnings are broadly useful across projects (not project-specific), update your auto-memory files.\n\n4. **Skip if trivial**: If the changes were trivial (typo fixes, minor config tweaks, formatting) or already well-documented, briefly state that no documentation updates are needed and stop.\n\nBe concise in your documentation updates — capture the essence, not a verbose narrative. All documentation should capture the up to date and accurate information about the codebase."}
HOOK_EOF

exit 0
