#!/usr/bin/env bash
# ABOUTME: Smoke tests for the codebase-hygiene plugin hook configuration.
# ABOUTME: Ensures the documentation guard is wired to PreToolUse via hooks/hooks.json.

set -euo pipefail

HOOKS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

python3 - "$HOOKS_DIR" <<'PY' || fail "plugin hook config policy failed"
import json
import pathlib
import sys

hooks_dir = pathlib.Path(sys.argv[1])
errors = []

config_path = hooks_dir / "hooks.json"
if not config_path.exists():
    print(f"{config_path}: missing plugin hooks.json", file=sys.stderr)
    sys.exit(1)

data = json.loads(config_path.read_text())
hooks = data.get("hooks", {})

# The documentation guard must be a PreToolUse hook (it blocks git/GitHub mutations before
# they run). Stop/Notification would fire too late to guard a commit.
pre_hooks = hooks.get("PreToolUse", [])
if not pre_hooks:
    errors.append("hooks.json: missing PreToolUse hook")
else:
    matcher = pre_hooks[0].get("matcher", "")
    # Must cover Bash commands and GitHub MCP/CLI tool calls, matching the guard's detection.
    for token in ("Bash", "github"):
        if token not in matcher:
            errors.append(f"hooks.json: PreToolUse matcher should include {token!r}")

for late_event in ("Stop", "Notification", "SessionStart"):
    if hooks.get(late_event):
        errors.append(f"hooks.json: {late_event} hook should not be configured for the docs guard")

text = json.dumps(data)
if "pre-git-documentation-check.sh" not in text:
    errors.append("hooks.json: does not invoke pre-git-documentation-check.sh")
if "${CLAUDE_PLUGIN_ROOT}" not in text:
    errors.append("hooks.json: hook command should use ${CLAUDE_PLUGIN_ROOT} for a portable install path")
if "--provider claude" not in text:
    errors.append("hooks.json: hook command should pass --provider claude")

# The script the config points at must actually exist and be executable-as-bash.
script = hooks_dir / "pre-git-documentation-check.sh"
if not script.exists():
    errors.append(f"{script}: referenced hook script is missing")
common = hooks_dir / "hook-common.sh"
if not common.exists():
    errors.append(f"{common}: shared hook helper is missing")

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)
PY

# The hook scripts must at least parse cleanly.
for script in "$HOOKS_DIR/pre-git-documentation-check.sh" "$HOOKS_DIR/hook-common.sh"; do
  bash -n "$script" || fail "$(basename "$script") has a syntax error"
done

printf 'hook config smoke tests passed\n'
