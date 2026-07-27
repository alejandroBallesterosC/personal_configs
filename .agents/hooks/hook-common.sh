#!/usr/bin/env bash
# ABOUTME: Shared Bash helpers for provider hook adapters.
# ABOUTME: Keeps cwd/session parsing and provider JSON output consistent.

set -u

read_hook_input() {
  if [ -n "${AGENT_HOOK_INPUT:-}" ]; then
    printf '%s' "$AGENT_HOOK_INPUT"
    return 0
  fi

  cat 2>/dev/null || true
}

hook_read_input() {
  HOOK_INPUT="$(read_hook_input)"
}

hook_require_jq() {
  local provider="$1"
  local message='HOOK ERROR: Required dependency `jq` is not available. Install jq and rerun the hook.'

  if command -v jq >/dev/null 2>&1; then
    return 0
  fi

  emit_message "$provider" "$message"
  exit 0
}

hook_json_get() {
  local filter="$1"
  local default_value="${2:-}"
  local value

  if [ -z "${HOOK_INPUT:-}" ]; then
    printf '%s' "$default_value"
    return 0
  fi

  value="$(printf '%s' "$HOOK_INPUT" | jq -er "$filter // empty" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s' "$value"
  else
    printf '%s' "$default_value"
  fi
}

hook_workspace_root() {
  hook_json_get '.workspace_roots[0]' ''
}

hook_provider_env() {
  local provider="$1"
  local suffix="$2"
  local upper
  local name

  upper=$(upper_provider "$provider")
  name="${upper}_${suffix}"
  printf '%s' "${!name-}"
}

hook_resolve_cwd() {
  local provider="$1"

  first_present \
    "$(hook_json_get '.cwd' '')" \
    "$(hook_json_get '.workspace' '')" \
    "$(hook_json_get '.workspace_dir' '')" \
    "$(hook_workspace_root)" \
    "$(hook_provider_env "$provider" CWD)" \
    "$(hook_provider_env "$provider" WORKSPACE)" \
    "${CLAUDE_PROJECT_DIR:-}" \
    "${PWD:-}" \
    "$(pwd 2>/dev/null || true)"
}

hook_optional_session_id() {
  local provider="$1"

  first_present \
    "$(hook_json_get '.session_id' '')" \
    "$(hook_provider_env "$provider" SESSION_ID)" \
    "${SESSION_ID:-}"
}

hook_conversation_id() {
  local provider="$1"

  first_present \
    "$(hook_json_get '.conversation_id' '')" \
    "$(hook_json_get '.thread_id' '')" \
    "$(hook_json_get '.generation_id' '')" \
    "$(hook_provider_env "$provider" CONVERSATION_ID)" \
    "$(hook_provider_env "$provider" THREAD_ID)" \
    "$(hook_provider_env "$provider" GENERATION_ID)" \
    "${CONVERSATION_ID:-}" \
    "${THREAD_ID:-}"
}

hook_session_id() {
  local provider="$1"

  first_present \
    "$(hook_optional_session_id "$provider")" \
    "$(hook_conversation_id "$provider")" \
    "default"
}

first_present() {
  local value
  for value in "$@"; do
    if [ -n "$value" ]; then
      printf '%s' "$value"
      return 0
    fi
  done
}

upper_provider() {
  case "$1" in
    claude) printf 'CLAUDE' ;;
    codex) printf 'CODEX' ;;
    cursor) printf 'CURSOR' ;;
    *) printf '%s' "$1" ;;
  esac
}

safe_token() {
  local value=$1
  printf '%s' "${value//[^A-Za-z0-9_.-]/_}"
}

truthy() {
  case "$1" in
    1 | true | TRUE | True | yes | YES | Yes | y | Y | on | ON | On) return 0 ;;
    *) return 1 ;;
  esac
}

json_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

emit_message() {
  local provider=$1
  local message=$2
  local escaped
  escaped=$(json_escape "$message")

  if [ "$provider" = "cursor" ]; then
    # Pre-tool blocking shape for Cursor beforeShellExecution / beforeMCPExecution.
    # followup_message only continues a stop/subagentStop loop; it never blocks a tool call.
    printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' "$escaped" "$escaped"
  else
    printf '{"decision":"block","reason":"%s"}\n' "$escaped"
  fi
}
