#!/usr/bin/env bash
# ABOUTME: Export the current Claude Code session transcript as Markdown.
# ABOUTME: Writes into an Obsidian vault when local; copies to the local clipboard via OSC 52 when remote.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RENDERER="$SCRIPT_DIR/render_transcript.py"

# Subdirectory of the vault where transcripts land when exporting locally.
TRANSCRIPTS_SUBDIR="claude-code-transcripts"

usage() {
  cat >&2 <<'EOF'
Usage: export.sh [--last N] [--name NAME]

  --last N    Export only the last N turns (default: the full transcript).
  --name NAME Base name for the output file (default: derived from timestamp + session).

Environment:
  CLAUDE_CODE_OBSIDIAN_EXPORT_PATH   Absolute path to the Obsidian vault (required when local).
  CLAUDE_SESSION_ID / CLAUDE_PROJECT_DIR   Provided by Claude Code; used to locate the transcript.
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
# branch between writing straight into the local vault and copying to the local
# clipboard. Fast path: SSH env vars. Fallback: walk the process tree for an sshd
# ancestor, which catches long-lived tmux sessions whose captured env vars have
# gone stale.
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

# Find the pty device backing this Claude Code session, by walking process ancestry
# for the "claude" binary and reading its controlling tty. Writing an OSC 52 escape
# sequence to this device is what reaches the real terminal: a Bash-tool subprocess
# has no controlling tty of its own (its stdout is captured and rendered by Claude
# Code's TUI, not relayed as raw bytes), so the write has to target the session's
# actual pty rather than this subprocess's own stdout.
find_controlling_pty() {
  local pid=$$
  local comm tty
  while [ "$pid" -gt 1 ]; do
    comm="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
    if [ "$comm" = "claude" ]; then
      tty="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
      if [ -n "$tty" ] && [ "$tty" != "?" ]; then
        printf '/dev/%s\n' "$tty"
        return 0
      fi
      return 1
    fi
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    [ -z "$pid" ] && break
  done
  return 1
}

# tmux only forwards OSC 52 out through nested layers (SSH, the local terminal) when
# set-clipboard and allow-passthrough are both live on the running server. Critically,
# tmux does not hot-reload ~/.tmux.conf: a server started before those lines were added
# keeps running without them until the config is explicitly re-sourced, and a write
# under a stale server fails completely silently (no error, clipboard unchanged). This
# check surfaces that failure mode instead of leaving it silent.
tmux_clipboard_ready() {
  [ -n "${TMUX:-}" ] || return 0
  local clip passthrough
  clip="$(tmux show-options -s -v set-clipboard 2>/dev/null || true)"
  passthrough="$(tmux show-options -g -v allow-passthrough 2>/dev/null || true)"
  [ "$clip" = "on" ] && [ "$passthrough" = "on" ]
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

if is_remote_session; then
  # Remote: copy the rendered Markdown into the user's local clipboard via OSC 52,
  # writing straight to this session's pty device so the escape sequence reaches the
  # real terminal through tmux -> SSH -> the local terminal emulator.
  PTY_DEVICE="$(find_controlling_pty || true)"
  if [ -z "$PTY_DEVICE" ]; then
    printf 'export.sh: could not find this session'"'"'s terminal device (no controlling tty found via process ancestry).\n' >&2
    exit 1
  fi

  if ! tmux_clipboard_ready; then
    cat >&2 <<EOF
export.sh: tmux is not forwarding the clipboard on this session.

tmux does not reload ~/.tmux.conf into an already-running server. Reload it once:

  tmux source-file ~/.tmux.conf

then confirm both report "on":

  tmux show-options -s -v set-clipboard
  tmux show-options -g -v allow-passthrough

and re-run this export.
EOF
    exit 1
  fi

  TMP_MD="$(mktemp)"
  trap 'rm -f "$TMP_MD"' EXIT
  render "$TMP_MD" >/dev/null

  BYTE_COUNT="$(wc -c <"$TMP_MD" | tr -d ' ')"
  B64="$(base64 <"$TMP_MD" | tr -d '\n')"
  printf '\033]52;c;%s\a' "$B64" >"$PTY_DEVICE"

  printf 'Copied transcript (%s bytes) to your local clipboard via OSC 52.\nPaste it into Obsidian now.\n\nIf nothing pastes, this pane likely was not in focus when the write happened\n(OSC 52 delivery is silent and undetectable in that case) — re-run the export\nwhile keeping this pane focused.\n' "$BYTE_COUNT"
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
DEST_PATH="$DEST_DIR/$(build_filename)"
render "$DEST_PATH" >/dev/null

printf 'Exported transcript to: %s\n' "$DEST_PATH"
