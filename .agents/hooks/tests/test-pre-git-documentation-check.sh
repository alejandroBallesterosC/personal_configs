#!/usr/bin/env bash
# ABOUTME: Smoke tests for the agent PreToolUse git documentation guard.
# ABOUTME: Exercises git-command detection and provider-specific block output.

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
SCRIPT="$ROOT/.agents/hooks/pre-git-documentation-check.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

make_repo() {
  local tmp
  tmp=$(mktemp -d)
  git -C "$tmp" init -q
  git -C "$tmp" config user.email "agent-hook-test@example.com"
  git -C "$tmp" config user.name "Agent Hook Test"
  mkdir -p "$tmp/.agents/hooks"
  cp "$ROOT/.agents/hooks/hook-common.sh" "$tmp/.agents/hooks/hook-common.sh"
  cp "$SCRIPT" "$tmp/.agents/hooks/pre-git-documentation-check.sh"
  printf '%s\n' "$tmp"
}

# Build a repo that satisfies the documentation contract. The doc set below MUST stay in
# sync with REQUIRED_DOC_FILES in pre-git-documentation-check.sh: a missing entry makes the
# fixture fail the contract, so the guard emits "contract checks failed" instead of the
# always-on reminder and every test that expects the reminder path fails.
add_valid_docs_contract() {
  local repo=$1
  mkdir -p "$repo/docs"
  printf '# Test Agent Instructions\n' >"$repo/AGENTS.md"
  printf '@AGENTS.md\n' >"$repo/CLAUDE.md"
  printf '# Evals Endpoint Interface\n' >"$repo/docs/evals-endpoint-interface.md"
  printf '# Interfaces\n' >"$repo/docs/interfaces.md"
  printf '# Data Model\n' >"$repo/docs/datamodel.md"
  printf '# Current Implementation Architecture\n' >"$repo/docs/current-implementation-architecture.md"
  git -C "$repo" add .
  git -C "$repo" commit -q -m fixture
}

run_hook_in_repo() {
  local repo=$1
  local provider=$2
  local input=$3
  (
    cd "$repo"
    AGENT_HOOK_INPUT="$input" bash .agents/hooks/pre-git-documentation-check.sh --provider "$provider"
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
    PATH="$fake_path" AGENT_HOOK_INPUT="$input" "$BASH" .agents/hooks/pre-git-documentation-check.sh --provider "$provider"
  )
}

run_hook() {
  local provider=$1
  local input=$2
  local tmp
  tmp=$(make_repo)
  run_hook_in_repo "$tmp" "$provider" "$input"
  rm -rf "$tmp"
}

tmp=$(make_repo)
missing_jq_output=$(run_hook_without_jq "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs\"}}")
rm -rf "$tmp"
printf '%s' "$missing_jq_output" | grep -q '"decision":"block"' || fail "missing jq should block with hook error"
printf '%s' "$missing_jq_output" | grep -q 'Required dependency `jq` is not available' || fail "missing jq reason should name jq"

tmp=$(make_repo)
non_commit_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git status --short\"}}")
rm -rf "$tmp"
if [ -n "$non_commit_output" ]; then
  fail "non-commit git command should not emit blocking output"
fi

tmp=$(make_repo)
commit_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs\"}}")
rm -rf "$tmp"
printf '%s' "$commit_output" | grep -q '"decision":"block"' || fail "codex git commit should block"
printf '%s' "$commit_output" | grep -q 'Documentation contract checks failed' || fail "missing docs contract reason"

tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
input="{\"cwd\":\"$tmp\",\"session_id\":\"impl-no-docs-test-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m implementation\"}}"
first_output=$(run_hook_in_repo "$tmp" codex "$input")
printf '%s' "$first_output" | grep -q '"decision":"block"' || fail "valid contract should still block first commit attempt with the always-on reminder"
printf '%s' "$first_output" | grep -q 'ensure all documentation is up to date' || fail "always-on reminder text missing"
printf '%s' "$first_output" | grep -q 'docs/datamodel.md' || fail "always-on reminder should name the configured required docs"
second_output=$(run_hook_in_repo "$tmp" codex "$input")
rm -rf "$tmp"
if [ -n "$second_output" ]; then
  fail "unchanged diff should be allowed on second commit attempt"
fi

tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
functions_output=$(run_hook_in_repo "$tmp" codex "{\"cwd\":\"$tmp\",\"session_id\":\"functions-command-test-$session_suffix\",\"tool_name\":\"functions.exec_command\",\"tool_input\":{\"command\":\"git commit -m implementation\"}}")
rm -rf "$tmp"
printf '%s' "$functions_output" | grep -q '"decision":"block"' || fail "functions.exec_command command payload should block"

tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/backend"
printf 'print("hello")\n' >"$tmp/backend/app.py"
session_suffix=$(basename "$tmp")
subdir_output=$(
  (
    cd "$tmp/backend"
    AGENT_HOOK_INPUT="{\"cwd\":\"$tmp/backend\",\"session_id\":\"subdir-docs-test-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m implementation\"}}" \
      "$BASH" "$tmp/.agents/hooks/pre-git-documentation-check.sh" --provider codex
  )
)
rm -rf "$tmp"
printf '%s' "$subdir_output" | grep -q '"decision":"block"' || fail "subdirectory commit should still fire the always-on reminder"
printf '%s' "$subdir_output" | grep -q 'ensure all documentation is up to date' || fail "subdirectory commit should evaluate repo-root docs contract before the always-on reminder"

# A diff that already changes docs still gets the always-on reminder once, then the unchanged
# diff is allowed on rerun. The reminder is intentionally not conditional on doc changes.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
printf '# Update\n' >"$tmp/docs/interfaces.md"
session_suffix=$(basename "$tmp")
docs_input="{\"cwd\":\"$tmp\",\"session_id\":\"docs-and-code-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs-and-code\"}}"
docs_first=$(run_hook_in_repo "$tmp" codex "$docs_input")
printf '%s' "$docs_first" | grep -q 'ensure all documentation is up to date' || fail "diff with documentation changes should still get the always-on reminder once"
docs_second=$(run_hook_in_repo "$tmp" codex "$docs_input")
rm -rf "$tmp"
if [ -n "$docs_second" ]; then
  fail "diff with documentation changes should be allowed on second commit attempt"
fi

# A local scripts/check_docs_policy.py must not affect the shared guard: behavior is identical
# to any other repo (reminder once, then allow on rerun); the guard never runs external checkers.
tmp=$(make_repo)
add_valid_docs_contract "$tmp"
mkdir -p "$tmp/scripts"
printf 'import sys\nsys.exit(7)\n' >"$tmp/scripts/check_docs_policy.py"
printf '# Update with local checker ignored\n' >"$tmp/docs/interfaces.md"
session_suffix=$(basename "$tmp")
checker_input="{\"cwd\":\"$tmp\",\"session_id\":\"docs-checker-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m docs-checker-ignored\"}}"
checker_first=$(run_hook_in_repo "$tmp" codex "$checker_input")
printf '%s' "$checker_first" | grep -q 'ensure all documentation is up to date' || fail "local scripts/check_docs_policy.py should not change the shared guard reminder"
checker_second=$(run_hook_in_repo "$tmp" codex "$checker_input")
rm -rf "$tmp"
if [ -n "$checker_second" ]; then
  fail "local scripts/check_docs_policy.py should not affect the shared guard on rerun"
fi

# Cursor beforeShellExecution payload shape: top-level `command`, no tool_name. Contract is
# broken (fresh repo, no AGENTS.md/docs) so the guard must deny with permission:"deny".
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

tmp=$(make_repo)
add_valid_docs_contract "$tmp"
printf 'print("hello")\n' >"$tmp/app.py"
session_suffix=$(basename "$tmp")
github_output=$(run_hook_in_repo "$tmp" claude "{\"cwd\":\"$tmp\",\"session_id\":\"github-mcp-test-$session_suffix\",\"tool_name\":\"mcp__github__create_pull_request\",\"tool_input\":{\"title\":\"Docs\"}}")
rm -rf "$tmp"
printf '%s' "$github_output" | grep -q '"decision":"block"' || fail "github MCP PR creation should block"
printf '%s' "$github_output" | grep -q '"permissionDecision":"deny"' || fail "github MCP block should include Claude/Codex permissionDecision"

# Detection must key on command position, not substring. A plain space is not a shell
# command separator, so `git`/`gh` appearing as an argument to another command must NOT
# trigger the guard, even though the text contains "git commit" / "git push".
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

# Each configured required-doc file, when missing or empty, must block REPEATEDLY (the
# rerun marker only allows an otherwise-passing contract; a broken contract is never silenced).
for required in docs/evals-endpoint-interface.md docs/interfaces.md docs/datamodel.md; do
  tmp=$(make_repo)
  add_valid_docs_contract "$tmp"
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

# A correctly-paired subdirectory (AGENTS.md + minimal CLAUDE.md) passes the contract and
# only sees the always-on reminder (allowed on rerun).
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

# Claude always-on reminder (valid contract): deny once, then allow the unchanged diff on rerun.
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

# Empty REQUIRED_DOC_FILES: no specific files enforced, no crash under set -u (bash 3.2 safe),
# and the always-on reminder omits the required-docs emphasis sentence.
if command -v perl >/dev/null 2>&1; then
  tmp=$(make_repo)
  # Line-anchored so it empties the real array (line start), not the REQUIRED_DOC_FILES=() example in the comment.
  perl -0777 -pi -e 's/^REQUIRED_DOC_FILES=\([^)]*\)/REQUIRED_DOC_FILES=()/m' "$tmp/.agents/hooks/pre-git-documentation-check.sh"
  # Valid root AGENTS.md/CLAUDE.md pairing, but deliberately NO docs/ files at all.
  printf '# Test Agent Instructions\n' >"$tmp/AGENTS.md"
  printf '@AGENTS.md\n' >"$tmp/CLAUDE.md"
  git -C "$tmp" add -A
  git -C "$tmp" commit -q -m fixture
  printf 'print("hello")\n' >"$tmp/app.py"
  session_suffix=$(basename "$tmp")
  empty_input="{\"cwd\":\"$tmp\",\"session_id\":\"empty-docs-$session_suffix\",\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git commit -m x\"}}"
  empty_first=$(run_hook_in_repo "$tmp" codex "$empty_input")
  if printf '%s' "$empty_first" | grep -q 'Required documentation file'; then
    rm -rf "$tmp"
    fail "empty REQUIRED_DOC_FILES should not enforce any specific docs"
  fi
  printf '%s' "$empty_first" | grep -q 'ensure all documentation is up to date' || { rm -rf "$tmp"; fail "empty list should still emit the always-on reminder"; }
  if printf '%s' "$empty_first" | grep -q 'In particular, it is very important'; then
    rm -rf "$tmp"
    fail "empty list reminder should omit the required-docs emphasis sentence"
  fi
  empty_second=$(run_hook_in_repo "$tmp" codex "$empty_input")
  rm -rf "$tmp"
  if [ -n "$empty_second" ]; then
    fail "empty list unchanged diff should be allowed on rerun"
  fi
fi

printf 'pre-git-documentation-check smoke tests passed\n'
