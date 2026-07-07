#!/usr/bin/env bash
# ABOUTME: Smoke tests for the codebase-hygiene PreToolUse git documentation guard.
# ABOUTME: Exercises git-command detection, the .documentation-check manifest, and output.

set -euo pipefail

HOOKS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$HOOKS_DIR/pre-git-documentation-check.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# Create a fresh git repo to act as the repository being committed to. The plugin hook is run
# from its install location and resolves this repo from the JSON `cwd`; nothing is copied in.
make_repo() {
  local tmp
  tmp=$(mktemp -d)
  git -C "$tmp" init -q
  git -C "$tmp" config user.email "hook-test@example.com"
  git -C "$tmp" config user.name "Hook Test"
  printf '%s\n' "$tmp"
}

# Satisfy the always-on interoperability contract: root AGENTS.md + minimal CLAUDE.md wrapper.
# No .documentation-check is written, so no repo-specific files are required.
add_valid_docs_contract() {
  local repo=$1
  printf '# Test Agent Instructions\n' >"$repo/AGENTS.md"
  printf '@AGENTS.md\n' >"$repo/CLAUDE.md"
  git -C "$repo" add .
  git -C "$repo" commit -q -m fixture
}

# The set of required docs declared by add_documentation_check, mirrored here for assertions.
REQUIRED_DOCS=("docs/architecture.md" "docs/datamodel.md" "docs/api.md")

# Declare repo-specific required docs via a root .documentation-check manifest and create the
# listed files. Includes a comment and a blank line to exercise manifest parsing. Must be
# called on a repo that already has a valid interoperability contract, then committed.
add_documentation_check() {
  local repo=$1
  mkdir -p "$repo/docs"
  {
    printf '# Repo-specific required documentation\n'
    printf '\n'
    printf 'docs/architecture.md|current architecture and component boundaries\n'
    printf 'docs/datamodel.md|complete data model for every persisted entity\n'
    printf 'docs/api.md|request/response schemas for every public endpoint\n'
  } >"$repo/.documentation-check"
  printf '# Architecture\n' >"$repo/docs/architecture.md"
  printf '# Data Model\n' >"$repo/docs/datamodel.md"
  printf '# API\n' >"$repo/docs/api.md"
  git -C "$repo" add .
  git -C "$repo" commit -q -m docs-manifest
}

run_hook_in_repo() {
  local repo=$1
  local provider=$2
  local input=$3
  (
    cd "$repo"
    AGENT_HOOK_INPUT="$input" bash "$SCRIPT" --provider "$provider"
  )
}

run_hook_without_jq() {
  local repo=$1
  local provider=$2
  local input=$3
  local fake_path="$repo/no-jq-bin"

  mkdir -p "$fake_path"
  ln -s "$(command -v dirname)" "$fake_path/dirname"

  (
    cd "$repo"
    PATH="$fake_path" AGENT_HOOK_INPUT="$input" "$BASH" "$SCRIPT" --provider "$provider"
  )
}

# Missing jq must fail closed (block) with a message naming jq.
tmp=$(make_repo)
missing_jq_output=$(run_hook_without_jq "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs\"}}")
rm -rf "$tmp"
printf '%s' "$missing_jq_output" | grep -q '"decision":"block"' || fail "missing jq should block with hook error"
printf '%s' "$missing_jq_output" | grep -q 'Required dependency `jq` is not available' || fail "missing jq reason should name jq"

# A non-commit git command must not emit blocking output.
tmp=$(make_repo)
non_commit_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git status --short\"}}")
rm -rf "$tmp"
if [ -n "$non_commit_output" ]; then
  fail "non-commit git command should not emit blocking output"
fi

# A commit in a repo with a broken contract (no AGENTS.md) must block with the contract reason.
tmp=$(make_repo)
commit_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs\"}}")
rm -rf "$tmp"
printf '%s' "$commit_output" | grep -q '"decision":"block"' || fail "codex git commit should block"
printf '%s' "$commit_output" | grep -q 'Documentation contract checks failed' || fail "missing docs contract reason"

# Valid contract with no .documentation-check: always-on reminder fires once, then the
# unchanged diff is allowed on the second attempt. The reminder must NOT include the
# required-docs emphasis sentence (no manifest declared).
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
input="{\"cwd\":\"$tmp\",\"session_id\":\"impl-no-docs-test-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m implementation\"}}"
first_output=$(run_hook_in_repo "$tmp" codex "$input")
printf '%s' "$first_output" | grep -q '"decision":"block"' || fail "valid contract should still block first commit attempt with the always-on reminder"
printf '%s' "$first_output" | grep -q 'ensure all documentation is up to date' || fail "always-on reminder text missing"
if printf '%s' "$first_output" | grep -q 'In particular, it is very important'; then
  rm -rf "$tmp"
  fail "no .documentation-check should omit the required-docs emphasis sentence"
fi
second_output=$(run_hook_in_repo "$tmp" codex "$input")
rm -rf "$tmp"
if [ -n "$second_output" ]; then
  fail "unchanged diff should be allowed on second commit attempt"
fi

# Valid contract WITH a .documentation-check manifest: reminder names the required docs and
# includes the emphasis sentence; the comment and blank line in the manifest are ignored.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
add_documentation_check "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
manifest_input="{\"cwd\":\"$tmp\",\"session_id\":\"impl-with-docs-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m implementation\"}}"
manifest_first=$(run_hook_in_repo "$tmp" codex "$manifest_input")
printf '%s' "$manifest_first" | grep -q 'In particular, it is very important' || fail "declared .documentation-check should add the required-docs emphasis sentence"
printf '%s' "$manifest_first" | grep -q 'docs/datamodel.md' || fail "always-on reminder should name the declared required docs"
if printf '%s' "$manifest_first" | grep -q 'Required documentation file'; then
  rm -rf "$tmp"
  fail "manifest comment/blank lines must not be treated as required doc paths"
fi
manifest_second=$(run_hook_in_repo "$tmp" codex "$manifest_input")
rm -rf "$tmp"
if [ -n "$manifest_second" ]; then
  fail "unchanged diff with a manifest should be allowed on second commit attempt"
fi

# functions.exec_command payload (command at .tool_input.command) must block on broken contract.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
functions_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"session_id\":\"functions-command-test-$session_suffix\",\"tool_name\":\"functions.exec_command\",\"tool_input\":{\"command\":\"git commit -m implementation\"}}")
rm -rf "$tmp"
printf '%s' "$functions_output" | grep -q '"decision":"block"' || fail "functions.exec_command command payload should block"

# A commit issued from a subdirectory must resolve the repo root and evaluate its contract.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf 'print("hello")\n' >"$tmp/backend/app.py"
session_suffix=$(basename "$tmp")
subdir_output=$(
  cd "$tmp/backend"
  AGENT_HOOK_INPUT="{\"cwd\":\"$tmp/backend\",\"session_id\":\"subdir-docs-test-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m implementation\"}}" \
    "$BASH" "$SCRIPT" --provider codex
)
rm -rf "$tmp"
printf '%s' "$subdir_output" | grep -q '"decision":"block"' || fail "subdirectory commit should still fire the always-on reminder"
printf '%s' "$subdir_output" | grep -q 'ensure all documentation is up to date' || fail "subdirectory commit should evaluate repo-root docs contract before the always-on reminder"

# A diff that already changes docs still gets the always-on reminder once, then the unchanged
# diff is allowed on rerun. The reminder is intentionally not conditional on doc changes.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
printf '# Notes\n' >"$tmp/NOTES.md"
session_suffix=$(basename "$tmp")
docs_input="{\"cwd\":\"$tmp\",\"session_id\":\"docs-and-code-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs-and-code\"}}"
docs_first=$(run_hook_in_repo "$tmp" codex "$docs_input")
printf '%s' "$docs_first" | grep -q 'ensure all documentation is up to date' || fail "diff with documentation changes should still get the always-on reminder once"
docs_second=$(run_hook_in_repo "$tmp" codex "$docs_input")
rm -rf "$tmp"
if [ -n "$docs_second" ]; then
  fail "diff with documentation changes should be allowed on second commit attempt"
fi

# Cursor beforeShellExecution payload shape: top-level `command`, no tool_name. Contract is
# broken (fresh repo, no AGENTS.md) so the guard must deny with permission:"deny".
tmp=$(make_repo)
cursor_shell_output=$(run_hook_in_repo "$tmp" cursor "{\"cwd\":\"$tmp\",\"command\":\"gh pr create --fill\"}")
rm -rf "$tmp"
printf '%s' "$cursor_shell_output" | grep -q '"permission":"deny"' || fail "cursor beforeShellExecution commit should deny (not followup_message)"
printf '%s' "$cursor_shell_output" | grep -q 'Documentation contract checks failed' || fail "cursor deny should include docs contract reason"

# Cursor non-commit shell command must not block.
tmp=$(make_repo)
cursor_noncommit_output=$(run_hook_in_repo "$tmp" cursor "{\"cwd\":\"$tmp\",\"command\":\"git status --short\"}")
rm -rf "$tmp"
if [ -n "$cursor_noncommit_output" ]; then
  fail "cursor beforeShellExecution non-commit command should not emit blocking output"
fi

# Cursor commit with a valid contract: always-on reminder denies once (then allows on rerun).
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
cursor_input="{\"cwd\":\"$tmp\",\"session_id\":\"cursor-impl-test-$session_suffix\",\"command\":\"git commit -m implementation\"}"
cursor_first_output=$(run_hook_in_repo "$tmp" cursor "$cursor_input")
printf '%s' "$cursor_first_output" | grep -q '"permission":"deny"' || fail "cursor valid-contract commit should deny first attempt with the always-on reminder"
printf '%s' "$cursor_first_output" | grep -q 'ensure all documentation is up to date' || fail "cursor always-on reminder text missing"
cursor_second_output=$(run_hook_in_repo "$tmp" cursor "$cursor_input")
rm -rf "$tmp"
if [ -n "$cursor_second_output" ]; then
  fail "cursor unchanged diff should be allowed on second commit attempt"
fi

# Cursor beforeMCPExecution payload shape: a GitHub MCP commit/PR tool must deny.
tmp=$(make_repo)
cursor_mcp_output=$(run_hook_in_repo "$tmp" cursor "{\"cwd\":\"$tmp\",\"tool_name\":\"github_create_pull_request\",\"tool_input\":{\"title\":\"Docs\"}}")
rm -rf "$tmp"
printf '%s' "$cursor_mcp_output" | grep -q '"permission":"deny"' || fail "cursor beforeMCPExecution github PR should deny"

# Cursor missing jq must fail closed (deny), matching Claude/Codex behavior.
tmp=$(make_repo)
cursor_missing_jq=$(run_hook_without_jq "$tmp" cursor "{\"cwd\":\"$tmp\",\"command\":\"git commit -m docs\"}")
rm -rf "$tmp"
printf '%s' "$cursor_missing_jq" | grep -q '"permission":"deny"' || fail "cursor missing jq should deny"
printf '%s' "$cursor_missing_jq" | grep -q 'Required dependency `jq` is not available' || fail "cursor missing jq reason should name jq"

# GitHub MCP PR creation (claude output shape) must block with a permissionDecision deny.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
github_output=$(run_hook_in_repo "$tmp" claude "{\"cwd\":\"$tmp\",\"session_id\":\"github-mcp-test-$session_suffix\",\"tool_name\":\"mcp__github__create_pull_request\",\"tool_input\":{\"title\":\"Docs\"}}")
rm -rf "$tmp"
printf '%s' "$github_output" | grep -q '"decision":"block"' || fail "github MCP PR creation should block"
printf '%s' "$github_output" | grep -q '"permissionDecision":"deny"' || fail "github MCP block should include Claude/Codex permissionDecision"

# Detection must key on command position, not substring. A plain space is not a shell command
# separator, so `git`/`gh` appearing as an argument to another command must NOT trigger the guard.
tmp=$(make_repo)
echo_git_output=$(run_hook_in_repo "$tmp" claude "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"echo git commit\"}}")
rm -rf "$tmp"
if [ -n "$echo_git_output" ]; then
  fail "echo git commit (git as argument) should not trigger the guard"
fi

tmp=$(make_repo)
grep_git_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"grep -r \\\"git push\\\" .\"}}")
rm -rf "$tmp"
if [ -n "$grep_git_output" ]; then
  fail "grep -r \"git push\" . (git as argument) should not trigger the guard"
fi

# Real commit-ish invocations after a command separator or leading env assignment must still block.
tmp=$(make_repo)
chained_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"cd /tmp && git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$chained_output" | grep -q '"decision":"block"' || fail "git commit after && should still block"

tmp=$(make_repo)
envassign_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"FOO=bar git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$envassign_output" | grep -q '"decision":"block"' || fail "git commit with leading env assignment should still block"

# Each declared required-doc file, when missing or empty, must block REPEATEDLY (the rerun
# marker only allows an otherwise-passing contract; a broken contract is never silenced).
for required in "${REQUIRED_DOCS[@]}"; do
  tmp=$(make_repo)
  add_valid_docs_contract "$tmp"
  add_documentation_check "$tmp"
  : >"$tmp/$required"   # truncate to empty -> "missing or empty"
  session_suffix=$(basename "$tmp")
  missing_input="{\"cwd\":\"$tmp\",\"session_id\":\"missing-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}"
  missing_first=$(run_hook_in_repo "$tmp" codex "$missing_input")
  printf '%s' "$missing_first" | grep -q '"decision":"block"' || fail "empty $required should block"
  printf '%s' "$missing_first" | grep -q "Required documentation file \`$required\`" || fail "block should name missing $required"
  missing_second=$(run_hook_in_repo "$tmp" codex "$missing_input")
  rm -rf "$tmp"
  printf '%s' "$missing_second" | grep -q '"decision":"block"' || fail "empty $required should block REPEATEDLY (not allowed on rerun)"
done

# Subdirectory pairing: a CLAUDE.md without a sibling AGENTS.md must block.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf '@AGENTS.md\n' >"$tmp/backend/CLAUDE.md"
orphan_claude=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$orphan_claude" | grep -q '"decision":"block"' || fail "subdir CLAUDE.md without AGENTS.md should block"
printf '%s' "$orphan_claude" | grep -q 'backend/AGENTS.md` is missing' || fail "block should flag missing backend/AGENTS.md"

# Subdirectory pairing: an AGENTS.md without a sibling CLAUDE.md must block.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf '# Backend\n' >"$tmp/backend/AGENTS.md"
orphan_agents=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$orphan_agents" | grep -q '"decision":"block"' || fail "subdir AGENTS.md without CLAUDE.md should block"
printf '%s' "$orphan_agents" | grep -q 'backend/CLAUDE.md` is missing' || fail "block should flag missing backend/CLAUDE.md"

# Subdirectory pairing: a CLAUDE.md whose content is not exactly "@AGENTS.md" must block.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf '# Backend\n' >"$tmp/backend/AGENTS.md"
printf '@AGENTS.md\nextra line\n' >"$tmp/backend/CLAUDE.md"
bad_wrapper=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$bad_wrapper" | grep -q '"decision":"block"' || fail "subdir CLAUDE.md with extra content should block"
printf '%s' "$bad_wrapper" | grep -q 'backend/CLAUDE.md` must contain exactly' || fail "block should flag non-wrapper backend/CLAUDE.md"

# A correctly-paired subdirectory (AGENTS.md + minimal CLAUDE.md) passes the contract and only
# sees the always-on reminder (allowed on rerun).
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf '# Backend\n' >"$tmp/backend/AGENTS.md"
printf '@AGENTS.md\n' >"$tmp/backend/CLAUDE.md"
session_suffix=$(basename "$tmp")
paired_input="{\"cwd\":\"$tmp\",\"session_id\":\"paired-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}"
paired_first=$(run_hook_in_repo "$tmp" codex "$paired_input")
printf '%s' "$paired_first" | grep -q 'ensure all documentation is up to date' || fail "correctly-paired subdir should pass contract and get the always-on reminder"
paired_second=$(run_hook_in_repo "$tmp" codex "$paired_input")
rm -rf "$tmp"
if [ -n "$paired_second" ]; then
  fail "correctly-paired subdir unchanged diff should be allowed on rerun"
fi

# Root CLAUDE.md must contain exactly "@AGENTS.md"; extra content blocks (claude output shape).
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf '@AGENTS.md\nextra line\n' >"$tmp/CLAUDE.md"
root_claude=$(run_hook_in_repo "$tmp" claude "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$root_claude" | grep -q '"permissionDecision":"deny"' || fail "root CLAUDE.md with extra content should block (claude)"
printf '%s' "$root_claude" | grep -q 'Root `CLAUDE.md` must contain exactly' || fail "block should flag root CLAUDE.md content"

# Missing root AGENTS.md blocks.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
rm -f "$tmp/AGENTS.md"
root_agents=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}")
rm -rf "$tmp"
printf '%s' "$root_agents" | grep -q 'Root `AGENTS.md` is missing or empty' || fail "missing root AGENTS.md should block"

# A broken contract blocks REPEATEDLY (no one-shot marker bypass for contract failures).
tmp=$(make_repo)
session_suffix=$(basename "$tmp")
repeat_input="{\"cwd\":\"$tmp\",\"session_id\":\"contract-repeat-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}"
repeat_first=$(run_hook_in_repo "$tmp" codex "$repeat_input")
repeat_second=$(run_hook_in_repo "$tmp" codex "$repeat_input")
rm -rf "$tmp"
printf '%s' "$repeat_first" | grep -q 'Documentation contract checks failed' || fail "broken contract should block (first attempt)"
printf '%s' "$repeat_second" | grep -q 'Documentation contract checks failed' || fail "broken contract should block REPEATEDLY (second attempt)"

# Claude always-on reminder (valid contract): deny once (CRITICAL), then allow on rerun.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
claude_input="{\"cwd\":\"$tmp\",\"session_id\":\"claude-reminder-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m implementation\"}}"
claude_first=$(run_hook_in_repo "$tmp" claude "$claude_input")
printf '%s' "$claude_first" | grep -q '"permissionDecision":"deny"' || fail "claude valid-contract commit should block first attempt"
printf '%s' "$claude_first" | grep -q 'CRITICAL' || fail "claude always-on reminder should be CRITICAL"
printf '%s' "$claude_first" | grep -q 'ensure all documentation is up to date' || fail "claude always-on reminder text missing"
claude_second=$(run_hook_in_repo "$tmp" claude "$claude_input")
rm -rf "$tmp"
if [ -n "$claude_second" ]; then
  fail "claude unchanged diff should be allowed on second commit attempt"
fi

# A commit outside any git work tree must not block (guard only acts inside a repo).
tmp=$(mktemp -d)
non_repo_output=$(
  cd "$tmp"
  AGENT_HOOK_INPUT="{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}" \
    "$BASH" "$SCRIPT" --provider codex
)
rm -rf "$tmp"
if [ -n "$non_repo_output" ]; then
  fail "commit outside a git work tree should not emit blocking output"
fi

printf 'pre-git-documentation-check smoke tests passed\n'
