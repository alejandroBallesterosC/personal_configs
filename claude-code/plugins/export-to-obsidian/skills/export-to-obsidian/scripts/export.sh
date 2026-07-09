#!/usr/bin/env bash
# ABOUTME: Export the current Claude Code session transcript to an Obsidian vault.
# ABOUTME: Writes directly when local; stages the file and prints a local-pull command when remote.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RENDERER="$SCRIPT_DIR/render_transcript.py"

# Subdirectory of the vault (and of the remote staging dir) where transcripts land.
TRANSCRIPTS_SUBDIR="claude-code-transcripts"
# Remote staging directory the local puller reads from.
REMOTE_STAGING_DIR="${CLAUDE_CODE_OBSIDIAN_STAGING_DIR:-$HOME/.cache/claude-code-transcripts}"

usage() {
  cat >&2 <<'EOF'
Usage: export.sh [--last N] [--name NAME]

  --last N    Export only the last N turns (default: the full transcript).
  --name NAME Base name for the output file (default: derived from timestamp + session).

Environment:
  CLAUDE_CODE_OBSIDIAN_EXPORT_PATH   Absolute path to the Obsidian vault (required when local).
  CLAUDE_SESSION_ID / CLAUDE_PROJECT_DIR   Provided by Claude Code; used to locate the transcript.
  CLAUDE_CODE_OBSIDIAN_STAGING_DIR   Remote staging dir (default: ~/.cache/claude-code-transcripts).
EOF
}

LAST=""
NAME=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --last)
      LAST="${2:-}"
      shift 2
      ;;
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'export.sh: unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -n "$LAST" ] && ! printf '%s' "$LAST" | grep -Eq '^[1-9][0-9]*$'; then
  printf 'export.sh: --last must be a positive integer, got: %s\n' "$LAST" >&2
  exit 2
fi

# Detect whether this shell is running on a remote host reached over SSH, so we can
# branch between writing straight into the local vault and staging for a local pull.
# Fast path: SSH env vars. Fallback: walk the process tree for an sshd ancestor, which
# catches long-lived tmux sessions whose captured env vars have gone stale.
is_remote_session() {
  if [ -n "${SSH_CONNECTION:-}${SSH_TTY:-}${SSH_CLIENT:-}" ]; then
    return 0
  fi
  local pid=$$
  local comm
  while [ "$pid" -gt 1 ]; do
    comm="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
    case "$comm" in
      *sshd*) return 0 ;;
    esac
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    [ -z "$pid" ] && break
  done
  return 1
}

# Build the output filename: <UTC-timestamp>-<session-prefix>[-lastN].md
build_filename() {
  if [ -n "$NAME" ]; then
    printf '%s.md' "$NAME"
    return 0
  fi
  local stamp session_prefix suffix
  stamp="$(date -u +%Y%m%d-%H%M%S)"
  session_prefix="${CLAUDE_SESSION_ID:-session}"
  session_prefix="${session_prefix:0:8}"
  suffix=""
  [ -n "$LAST" ] && suffix="-last${LAST}"
  printf '%s-%s%s.md' "$stamp" "$session_prefix" "$suffix"
}

render() {
  local dest="$1"
  local args=(--output "$dest")
  [ -n "$LAST" ] && args=(--last "$LAST" "${args[@]}")
  python3 "$RENDERER" "${args[@]}"
}

FILENAME="$(build_filename)"

if is_remote_session; then
  # Remote: render into a staging directory on this box and print a marked one-liner
  # for the LOCAL machine to pull. The remote never touches the local vault directly.
  mkdir -p "$REMOTE_STAGING_DIR"
  STAGED_PATH="$REMOTE_STAGING_DIR/$FILENAME"
  render "$STAGED_PATH" >/dev/null

  REMOTE_HOST="$(hostname 2>/dev/null || echo remote)"
  REMOTE_USER="${USER:-$(id -un 2>/dev/null || echo user)}"

  cat <<EOF
Transcript staged on the remote host (no file was pushed to your machine).

  Remote file: ${STAGED_PATH}
  Remote host: ${REMOTE_USER}@${REMOTE_HOST}

To pull it into your local Obsidian vault, run this ON YOUR LOCAL MACHINE
(it will ask you to Allow/Deny before copying):

  cc-obsidian-pull <ssh-host-for-this-devbox> "${STAGED_PATH}"

where <ssh-host-for-this-devbox> is the ~/.ssh/config Host (or user@host) you
use to reach this box. The pull uses your local->remote SSH credentials; this
box is given no way to reach your machine.
EOF
  exit 0
fi

# Local: write straight into the vault.
if [ -z "${CLAUDE_CODE_OBSIDIAN_EXPORT_PATH:-}" ]; then
  printf 'export.sh: CLAUDE_CODE_OBSIDIAN_EXPORT_PATH is not set. Point it at your Obsidian vault.\n' >&2
  exit 1
fi
if [ ! -d "$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH" ]; then
  printf 'export.sh: vault path does not exist: %s\n' "$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH" >&2
  exit 1
fi

DEST_DIR="$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/$TRANSCRIPTS_SUBDIR"
mkdir -p "$DEST_DIR"
DEST_PATH="$DEST_DIR/$FILENAME"
render "$DEST_PATH" >/dev/null

printf 'Exported transcript to: %s\n' "$DEST_PATH"
