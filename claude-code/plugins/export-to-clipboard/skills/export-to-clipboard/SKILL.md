---
name: export-to-clipboard
description: Export the current Claude Code session transcript (full, or the last N turns) as Markdown into the user's clipboard. User-invoked only.
disable-model-invocation: true
argument-hint: "[N]  (optional: export only the last N turns)"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/export.sh *)
---

# Export to Clipboard

Export the current Claude Code session's transcript to Markdown — written to
the user's Obsidian vault when running locally, or copied to the user's
clipboard when running remotely over SSH. This skill is **user-invoked only**
(`disable-model-invocation: true`); Claude never triggers it on its own.

## What to do

Run the bundled export script via the Bash tool. The script locates the current
session's transcript, renders it to Markdown (turns, tool calls in collapsible
blocks), and writes it into the vault (local) or the clipboard (remote).

- **Full transcript** (no argument):

  ```bash
  "${CLAUDE_SKILL_DIR}/scripts/export.sh"
  ```

- **Last N turns** (when the user passed a number, e.g. `/export-to-clipboard:export-to-clipboard 5`):

  ```bash
  "${CLAUDE_SKILL_DIR}/scripts/export.sh" --last 5
  ```

A "turn" is one user prompt plus the assistant's response to it (including tool
calls). Pass `--last N` only when the user asked for the last N turns; otherwise
export the whole transcript.

After running, report what the script printed. On the local path that's the
destination file. On the remote path that's a confirmation that the transcript
was copied to the user's local clipboard (or an error — see below) — relay it
verbatim and tell the user to paste into Obsidian themselves; do not attempt to
verify or complete the paste.

## How it behaves: local vs. remote

The script detects whether this session is running locally or on a remote box
reached over SSH:

- **Local**: writes the Markdown straight into
  `$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/claude-code-transcripts/`.
- **Remote (SSH)**: the vault is on the user's local machine, which this box
  cannot (and by design must not) reach. The script instead copies the
  rendered Markdown to the user's **local clipboard** via an OSC 52 terminal
  escape sequence, written directly to the session's pty device (the way the
  built-in `/copy` command does it). The user pastes it into Obsidian
  themselves — no file ever touches the remote-to-local boundary.

  This only works when tmux is forwarding OSC 52 (`set-clipboard on` and
  `allow-passthrough on` on the *live* tmux server — tmux does not hot-reload
  `~/.tmux.conf`, so a server started before those lines were added needs an
  explicit `tmux source-file ~/.tmux.conf`) and when the pane running Claude
  Code is the one currently focused at the moment the write happens. If either
  is false, the write is either reported as a clear error (missing tmux
  options) or fails completely silently (pane not focused — nothing pastes,
  with no error). If nothing pastes after a remote export, tell the user to
  re-run it while keeping this pane focused.

## Prerequisites

- `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` must point at the Obsidian vault (used when
  running locally).
- `python3` must be available (the renderer is Python 3, standard library only).
- For the remote path: tmux with `set-clipboard on` and `allow-passthrough on`
  live on the running server, and a local terminal that supports OSC 52 (e.g.
  Ghostty, iTerm2).

If `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` is unset when running locally, the script
exits with a clear message; relay it and ask the user to set the variable.
