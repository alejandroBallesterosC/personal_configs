---
name: export-to-obsidian
description: Export the current Claude Code session transcript (full, or the last N turns) as Markdown into an Obsidian vault. User-invoked only.
disable-model-invocation: true
argument-hint: "[N]  (optional: export only the last N turns)"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/export.sh *)
---

# Export to Obsidian

Export the current Claude Code session's transcript to a Markdown file in the
user's Obsidian vault. This skill is **user-invoked only** (`disable-model-invocation: true`);
Claude never triggers it on its own.

## What to do

Run the bundled export script via the Bash tool. The script locates the current
session's transcript, renders it to Markdown (turns, tool calls in collapsible
blocks), and writes it into the vault.

- **Full transcript** (no argument):

  ```bash
  "${CLAUDE_SKILL_DIR}/scripts/export.sh"
  ```

- **Last N turns** (when the user passed a number, e.g. `/export-to-obsidian:export-to-obsidian 5`):

  ```bash
  "${CLAUDE_SKILL_DIR}/scripts/export.sh" --last 5
  ```

A "turn" is one user prompt plus the assistant's response to it (including tool
calls). Pass `--last N` only when the user asked for the last N turns; otherwise
export the whole transcript.

After running, report the destination path the script prints. If the script
prints remote-staging instructions instead (see below), relay them to the user
verbatim — do not attempt the pull yourself.

## How it behaves: local vs. remote

The script detects whether this session is running locally or on a remote box
reached over SSH:

- **Local**: writes the Markdown straight into
  `$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/claude-code-transcripts/`.
- **Remote (SSH)**: the vault is on the user's local machine, which this box
  cannot (and by design must not) reach. The script instead stages the file on
  the remote host and prints a one-line command for the user to run **on their
  local machine**. That local command asks the user to Allow/Deny, then pulls
  the file into the vault using the user's existing local→remote SSH
  credentials. The remote box is never given any path back to the local machine.

## Prerequisites

- `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` must point at the Obsidian vault (used when
  running locally, and by the local puller).
- `python3` must be available (the renderer is Python 3, standard library only).
- For the remote path, the user installs the local puller
  (`local-puller/cc-obsidian-pull.sh`) on their own machine. See the plugin
  README.

If `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` is unset when running locally, the script
exits with a clear message; relay it and ask the user to set the variable.
