#!/usr/bin/env bash
# ABOUTME: Shared PreToolUse guard before agent-driven commits/PR creation.
# ABOUTME: Enforces documentation contracts before git/GitHub mutations.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-common.sh
. "$SCRIPT_DIR/hook-common.sh"

# Optional per-repo documentation manifest, read from the root of the repo being committed
# to. Each non-empty, non-comment line is a "path|description" entry naming a documentation
# file (path relative to the repo root) that must exist and stay non-empty before any
# commit/PR mutation is allowed. Lines beginning with '#' are comments. When the file is
# absent or has no entries, no repo-specific files are enforced; the root and subdirectory
# AGENTS.md/CLAUDE.md pairing checks and the always-on documentation reminder still run.
DOCUMENTATION_CHECK_FILE=".documentation-check"

# Populated by load_required_docs from the repo's .documentation-check manifest.
REQUIRED_DOC_FILES=()

load_required_docs() {
  local repo_root="$1"
  local manifest="$repo_root/$DOCUMENTATION_CHECK_FILE"
  local line
  local trimmed

  REQUIRED_DOC_FILES=()

  [ -f "$manifest" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    # Trim surrounding whitespace so indented entries and comments are handled.
    trimmed="${line#"${line%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [ -z "$trimmed" ] && continue
    case "$trimmed" in
      \#*) continue ;;
    esac
    REQUIRED_DOC_FILES+=("$trimmed")
  done <"$manifest"
}

PROVIDER=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --provider)
      PROVIDER="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

case "$PROVIDER" in
  claude | codex | cursor) ;;
  *) PROVIDER="codex" ;;
esac

hook_require_jq "$PROVIDER"

deny_pretool() {
  local reason="$1"

  if [ "$PROVIDER" = "cursor" ]; then
    # Cursor beforeShellExecution / beforeMCPExecution block via permission:"deny".
    # followup_message is a stop/subagentStop-only field and does NOT block a tool call.
    printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' \
      "$(json_escape "$reason")" \
      "$(json_escape "$reason")"
  else
    printf '{"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
      "$(json_escape "$reason")" \
      "$(json_escape "$reason")"
  fi
}

claude_wrapper_is_valid() {
  local file="$1"
  local content

  if [ ! -f "$file" ]; then
    return 1
  fi

  content="$(sed -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$file" 2>/dev/null || true)"
  [ "$content" = "@AGENTS.md" ]
}

# Render the configured required-doc paths as an inline, comma-separated list of
# backtick-quoted paths for use in reminder messages. Empty when no files are configured.
required_docs_inline_list() {
  local rel
  local out=""

  for rel in "${REQUIRED_DOC_FILES[@]+"${REQUIRED_DOC_FILES[@]}"}"; do
    if [ -n "$out" ]; then
      out="$out, "
    fi
    out="$out\`${rel%%|*}\`"
  done

  printf '%s' "$out"
}

document_contract_issues() {
  local cwd="$1"
  local rel
  local doc_path
  local dir

  if [ ! -s "$cwd/AGENTS.md" ]; then
    printf '%s\n' '- Root `AGENTS.md` is missing or empty. Restore it as the canonical repo instructions.'
  fi

  if ! claude_wrapper_is_valid "$cwd/CLAUDE.md"; then
    printf '%s\n' '- Root `CLAUDE.md` must contain exactly `@AGENTS.md` and no other content.'
  fi

  for rel in "${REQUIRED_DOC_FILES[@]+"${REQUIRED_DOC_FILES[@]}"}"; do
    doc_path="${rel%%|*}"
    if [ ! -s "$cwd/$doc_path" ]; then
      printf -- '- Required documentation file `%s` is missing or empty; create it with %s.\n' "$doc_path" "${rel#*|}"
    fi
  done

  while IFS= read -r dir; do
    dir="${dir#./}"
    [ "$dir" = "." ] && continue

    if [ ! -s "$cwd/$dir/AGENTS.md" ]; then
      printf -- '- `%s/CLAUDE.md` exists but `%s/AGENTS.md` is missing or empty. Keep `AGENTS.md` as the source of truth in that directory.\n' "$dir" "$dir"
    fi

    if [ ! -s "$cwd/$dir/CLAUDE.md" ]; then
      printf -- '- `%s/AGENTS.md` exists but `%s/CLAUDE.md` is missing or empty. Add an import-only `CLAUDE.md` wrapper.\n' "$dir" "$dir"
    elif ! claude_wrapper_is_valid "$cwd/$dir/CLAUDE.md"; then
      printf -- '- `%s/CLAUDE.md` must contain exactly `@AGENTS.md` and no other content.\n' "$dir"
    fi
  done < <(
    cd "$cwd" && find . \
      \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ -o -name .mypy_cache -o -name .pytest_cache -o -name dist -o -name build -o -name coverage -o -path './.plugin-state' \) -prune \
      -o \( -name AGENTS.md -o -name CLAUDE.md \) -type f -print \
      | while IFS= read -r path; do dirname "$path"; done \
      | sort -u
  )
}

is_commitish_bash_command() {
  local command="$1"
  local git_binary='(git|/[^[:space:]]*/git)'
  local gh_binary='(gh|/[^[:space:]]*/gh)'
  # A command begins at the start of the string, after a real shell separator
  # (; | & ( ) or a newline), optionally followed by whitespace and leading env
  # assignments. A plain space or tab is NOT a separator, so `git`/`gh` appearing
  # as an argument to another command (e.g. `echo git commit`, `grep "git push" .`)
  # must not match.
  local newline=$'\n'
  local sep="(^|[;|&()${newline}])"
  local lead="[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*"
  local prefix="${sep}${lead}"

  [[ "$command" =~ $prefix$git_binary[[:space:]]+(commit|merge|cherry-pick|revert|rebase|push)([[:space:]]|$) ]] && return 0
  [[ "$command" =~ $prefix$git_binary[[:space:]]+commit-tree([[:space:]]|$) ]] && return 0
  [[ "$command" =~ $prefix$gh_binary[[:space:]]+(pr[[:space:]]+(create|merge)|repo[[:space:]]+sync|release[[:space:]]+create|api)([[:space:]]|$) ]] && return 0

  return 1
}

is_commitish_github_tool() {
  local tool_name="$1"
  local input_text="$2"
  local combined

  combined="$(printf '%s %s' "$tool_name" "$input_text" | tr '[:upper:]' '[:lower:]')"
  [[ "$combined" == *github* ]] || return 1

  case "$combined" in
    *commit* | \
    *push* | \
    *merge* | \
    *pull_request* | \
    *pull-request* | \
    *create_pr* | \
    *create-pull* | \
    *create_pull* | \
    *create_or_update_file* | \
    *update_file* | \
    *create_file* | \
    *delete_file* | \
    *create_ref* | \
    *update_ref*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_commitish_tool_call() {
  local tool_name="$1"
  local command_text="$2"
  local input_text="$3"

  case "$tool_name" in
    "" | Bash | Shell | shell | functions.exec_command | exec_command)
      # Empty tool name covers Cursor's beforeShellExecution payload, which carries the
      # command at top-level `.command` with no tool_name field.
      is_commitish_bash_command "$command_text"
      return $?
      ;;
    *)
      is_commitish_github_tool "$tool_name" "$input_text"
      ;;
  esac
}

hook_read_input

TOOL_NAME="$(hook_json_get '(.tool_name // .name // .toolName // .tool)' '')"
COMMAND_TEXT="$(hook_json_get '(.tool_input.cmd // .tool_input.command // .input.cmd // .input.command // .cmd // .command // .arguments.cmd // .arguments.command // .args.cmd // .args.command)' '')"
INPUT_TEXT="$(hook_json_get '(.tool_input // .input // .arguments // .args // {}) | tostring' '')"

if [ -z "$INPUT_TEXT" ]; then
  INPUT_TEXT="$HOOK_INPUT"
fi

if ! is_commitish_tool_call "$TOOL_NAME" "$COMMAND_TEXT" "$INPUT_TEXT"; then
  exit 0
fi

CWD="$(hook_resolve_cwd "$PROVIDER")"
SESSION="$(hook_session_id "$PROVIDER")"

if ! git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Resolve the root of the repo being committed to (the working directory's git toplevel),
# not the plugin's install location, so the guard checks the user's repo.
REPO_ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

load_required_docs "$REPO_ROOT"

REQUIRED_DOCS_LIST="$(required_docs_inline_list)"

CONTRACT_ISSUES="$(document_contract_issues "$REPO_ROOT")"
if [ -n "$CONTRACT_ISSUES" ]; then
  if [ -n "$REQUIRED_DOCS_LIST" ]; then
    REQUIRED_DOCS_SENTENCE=" and $REQUIRED_DOCS_LIST must exist and stay current"
  else
    REQUIRED_DOCS_SENTENCE=""
  fi
  deny_pretool "DOCUMENTATION PRE-COMMIT GUARD: Documentation contract checks failed. Fix these issues before committing or publishing changes:

$CONTRACT_ISSUES

Root AGENTS.md is the source of truth, CLAUDE.md files must be minimal @AGENTS.md wrappers${REQUIRED_DOCS_SENTENCE}."
  exit 0
fi

# All deterministic contract checks passed. Always remind once per session+diff that the
# whole codebase's documentation must reflect the current state of the code, then allow the
# unchanged diff on the second attempt.
STATUS="$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null || true)"
if [ -n "$STATUS" ]; then
  FINGERPRINT="$(printf '%s' "$STATUS" | cksum | awk '{print $1}')"
  MARKER="/tmp/${PROVIDER}-docs-precommit-reviewed-$(safe_token "$SESSION")-$FINGERPRINT"

  if [ ! -f "$MARKER" ]; then
    : >"$MARKER"
    if [ -n "$REQUIRED_DOCS_LIST" ]; then
      REQUIRED_DOCS_EMPHASIS="In particular, it is very important that $REQUIRED_DOCS_LIST always be up to date. "
    else
      REQUIRED_DOCS_EMPHASIS=""
    fi
    deny_pretool "DOCUMENTATION PRE-COMMIT GUARD: **CRITICAL** Before committing please take a moment to ensure all documentation is up to date with the current state of the codebase. ${REQUIRED_DOCS_EMPHASIS}Ensure ALL README files, AGENTS.md files, and all other documentation files throughout the entire codebase are also up to date with the current state of the codebase. There should be no stale, obviously redundant, or inaccurate documentation in the entire codebase. Load the agents-md-improver skill if it's not already loaded this session. If you have reviewed docs and truly no documentation updates are needed (NOTE: this should be very rare) or you have already ensured all documentation is up to date please rerun your commit command; this guard will allow the unchanged diff on the second attempt provided all other documentation checks pass."
    exit 0
  fi
fi
