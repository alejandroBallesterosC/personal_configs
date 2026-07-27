#!/usr/bin/env bash
# ABOUTME: Smoke tests for provider hook adapter configuration.
# ABOUTME: Ensures documentation enforcement is attached to PreToolUse, not Stop.

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

python3 - "$ROOT" <<'PY' || fail "provider hook config policy failed"
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
matcher = "Bash|functions.exec_command|exec_command|mcp__github__.*|github.*|GitHub.*|gh"
cursor_command = ".agents/hooks/pre-git-documentation-check.sh --provider cursor"

errors = []

# Claude Code and Codex use Claude-style PreToolUse with the shared broad tool-name matcher.
for rel, pre_key, stop_key, session_key in [
    (".codex/hooks.json", "PreToolUse", "Stop", "SessionStart"),
    (".claude/settings.json", "PreToolUse", "Stop", "SessionStart"),
]:
    data = json.loads((root / rel).read_text())
    hooks = data.get("hooks", {})
    pre_hooks = hooks.get(pre_key, [])
    if not pre_hooks:
        errors.append(f"{rel}: missing {pre_key} hook")
    elif pre_hooks[0].get("matcher") != matcher:
        errors.append(f"{rel}: {pre_key} matcher does not include shared broad matcher")

    text = json.dumps(data)
    if "pre-git-documentation-check.sh" not in text:
        errors.append(f"{rel}: missing pre-git documentation guard")
    if "document-learnings.sh" in text:
        errors.append(f"{rel}: document-learnings stop hook is still active")
    if "git-baseline.sh" in text:
        errors.append(f"{rel}: git-baseline session hook is still active")
    if hooks.get(stop_key):
        errors.append(f"{rel}: {stop_key} hook should not be configured")
    if hooks.get(session_key):
        errors.append(f"{rel}: {session_key} hook should not be configured for docs baseline")

# Cursor must guard the command text and fire in both the IDE and the CLI, so it wires the
# guard to beforeShellExecution (+ beforeMCPExecution). preToolUse only matches the tool type
# (e.g. Shell) and is not honored by the Cursor CLI, so it cannot back a commit guard.
cursor = json.loads((root / ".cursor/hooks.json").read_text())
cursor_hooks = cursor.get("hooks", {})
cursor_text = json.dumps(cursor)

for event in ("beforeShellExecution", "beforeMCPExecution"):
    event_hooks = cursor_hooks.get(event, [])
    if not event_hooks:
        errors.append(f".cursor/hooks.json: missing {event} hook")
    elif cursor_command not in event_hooks[0].get("command", ""):
        errors.append(f".cursor/hooks.json: {event} should call shared repo hook with provider cursor")

if cursor_hooks.get("preToolUse"):
    errors.append(".cursor/hooks.json: preToolUse cannot match command text or fire in the Cursor CLI; use beforeShellExecution")
for dead_key in ("stop", "sessionStart"):
    if cursor_hooks.get(dead_key):
        errors.append(f".cursor/hooks.json: {dead_key} hook should not be configured for docs baseline")
if "document-learnings.sh" in cursor_text:
    errors.append(".cursor/hooks.json: document-learnings stop hook is still active")
if "git-baseline.sh" in cursor_text:
    errors.append(".cursor/hooks.json: git-baseline session hook is still active")

codex_text = (root / ".codex/hooks.json").read_text()
if "git rev-parse --show-toplevel" not in codex_text:
    errors.append(".codex/hooks.json: Codex hook command should resolve repo root with git rev-parse")

claude_text = (root / ".claude/settings.json").read_text()
if "$CLAUDE_PROJECT_DIR" not in claude_text:
    errors.append(".claude/settings.json: Claude hook command should use CLAUDE_PROJECT_DIR")

if cursor_command not in cursor_text:
    errors.append(".cursor/hooks.json: Cursor hook command should call shared repo hook with provider cursor")

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)
PY

printf 'hook config smoke tests passed\n'
