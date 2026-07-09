#!/usr/bin/env bash
# ABOUTME: Local (Mac) helper that pulls a staged transcript from a remote dev box into the vault.
# ABOUTME: Prompts Allow/Deny before copying so the remote can never push a file unattended.

# INSTALL THIS ON YOUR LOCAL MACHINE, not on the dev box. It is intentionally kept
# out of the plugin's runtime path: the whole security model is that the transfer is
# initiated and approved locally, using SSH credentials that only ever go local->remote.
# The remote dev box is given no path into this machine.
#
# Suggested install:
#   cp local-puller/cc-obsidian-pull.sh ~/bin/cc-obsidian-pull && chmod +x ~/bin/cc-obsidian-pull
# and set (in your local shell profile):
#   export CLAUDE_CODE_OBSIDIAN_EXPORT_PATH="/path/to/your/Obsidian/Vault"
#
# Usage:
#   cc-obsidian-pull <ssh-host> <remote-file-path>
#
#   <ssh-host>          An entry from your ~/.ssh/config (or user@host) for the dev box.
#   <remote-file-path>  Absolute path to the staged .md on the dev box (printed by export.sh).

set -euo pipefail

TRANSCRIPTS_SUBDIR="claude-code-transcripts"

die() {
  printf 'cc-obsidian-pull: %s\n' "$1" >&2
  exit 1
}

[ "$#" -eq 2 ] || die "usage: cc-obsidian-pull <ssh-host> <remote-file-path>"

SSH_HOST="$1"
REMOTE_PATH="$2"
FILENAME="$(basename -- "$REMOTE_PATH")"

[ -n "${CLAUDE_CODE_OBSIDIAN_EXPORT_PATH:-}" ] || die "CLAUDE_CODE_OBSIDIAN_EXPORT_PATH is not set (point it at your vault)."
[ -d "$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH" ] || die "vault path does not exist: $CLAUDE_CODE_OBSIDIAN_EXPORT_PATH"

DEST_DIR="$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/$TRANSCRIPTS_SUBDIR"

# Ask for explicit approval before copying anything. Prefer a native macOS dialog;
# fall back to a terminal y/N prompt on other platforms or when osascript is absent.
approve() {
  local prompt="Pull \"$FILENAME\" from $SSH_HOST into your Obsidian vault?"
  if command -v osascript >/dev/null 2>&1; then
    local answer
    answer="$(osascript -e "button returned of (display dialog \"$prompt\" buttons {\"Deny\", \"Allow\"} default button \"Allow\" with title \"Claude Code -> Obsidian\" giving up after 30)" 2>/dev/null || true)"
    [ "$answer" = "Allow" ]
    return $?
  fi
  printf '%s [y/N] ' "$prompt" >&2
  local reply
  read -r reply
  case "$reply" in
    y | Y | yes | YES) return 0 ;;
    *) return 1 ;;
  esac
}

if ! approve; then
  die "denied — nothing was copied."
fi

mkdir -p "$DEST_DIR"

# Local-initiated pull over the SSH credentials that only go local->remote. Prefer rsync;
# fall back to scp. The remote is never given a way to reach this machine.
if command -v rsync >/dev/null 2>&1; then
  rsync -avz --checksum "$SSH_HOST:$REMOTE_PATH" "$DEST_DIR/"
else
  scp "$SSH_HOST:$REMOTE_PATH" "$DEST_DIR/"
fi

DEST_PATH="$DEST_DIR/$FILENAME"
printf 'Pulled into vault: %s\n' "$DEST_PATH"

if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "Claude Code -> Obsidian" -message "Saved $FILENAME to your vault" >/dev/null 2>&1 || true
fi
