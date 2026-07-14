# export-to-clipboard

Export the current Claude Code session's transcript — the full log, or just the last N turns — as Markdown: written straight into an Obsidian vault when running locally, or copied to your clipboard when running remotely over SSH. The skill is **user-invoked only**: Claude can never trigger it on its own.

```
/plugin install export-to-clipboard
```

Invoke with:

```
/export-to-clipboard:export-to-clipboard        # full transcript
/export-to-clipboard:export-to-clipboard 5       # last 5 turns
```

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `export-to-clipboard` | Skill (user-only) | Runs the export. `disable-model-invocation: true`, so only you can trigger it via `/…`. |
| `scripts/render_transcript.py` | Python 3 (stdlib) | Locates the current session's JSONL, groups it into turns, renders Markdown (tool calls in collapsible blocks). |
| `scripts/export.sh` | Bash | Entry point. Detects local vs. remote and either writes to the vault or copies to the local clipboard. |

## How it works

A "turn" is one user prompt plus the assistant's response to it, including tool calls.

The current session's transcript is located by **session identity, not by a path formula**: Claude Code names each transcript `<session-id>.jsonl`, so the script globs `~/.claude/projects/*/` for that filename (using `$CLAUDE_SESSION_ID`). This is deliberate — the parent directory is a lossy slug of the working directory (`/`, `_`, `.`, and spaces all collapse to `-`) and is branch-derived for git worktrees, so reconstructing the path from the cwd is unreliable.

### Local vs. remote

The script detects whether the session runs locally or on a remote box reached over SSH (via `$SSH_CONNECTION`/`$SSH_TTY`, with a process-ancestry fallback for long-lived tmux sessions):

- **Local** — writes the Markdown straight into `$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/claude-code-transcripts/`, named `<UTC-timestamp>-<session-prefix>[-lastN].md`.
- **Remote** — the vault is on your local machine, which the remote box cannot (and by design must not) reach. The script instead copies the rendered Markdown straight to your local clipboard, the same way the built-in `/copy` command does, so you paste it into Obsidian yourself.

## Remote clipboard copy (OSC 52)

The remote path uses the [OSC 52](https://sunaku.github.io/tmux-yank-osc52.html) terminal escape sequence (`\033]52;c;<base64>\a`) — the standard "set the local clipboard" code, sent from the dev box through the SSH connection to your local terminal.

A subprocess run by Claude Code's Bash tool has no controlling terminal of its own (its stdout is captured and rendered by Claude Code's TUI, not relayed as raw bytes to the real terminal), so the script can't just print the escape sequence. Instead it walks process ancestry to find the `claude` CLI process's controlling pty (e.g. `/dev/pts/5`) and writes the sequence straight to that device. From there, tmux intercepts it and forwards it out through the SSH connection to the local terminal, the same path `/copy` uses.

This requires two things to be true on the **live** tmux server at write time:

- `set-clipboard on` (server option)
- `allow-passthrough on` (window option)

tmux does not hot-reload `~/.tmux.conf` — a server started before those lines were added into the config keeps running without them until you explicitly run `tmux source-file ~/.tmux.conf`. `export.sh` checks both live options before writing and exits with a clear error (including the exact reload command) if either is off, rather than attempting a write that would silently do nothing.

The one failure mode the script *cannot* detect: OSC 52 clipboard-set is only delivered by tmux to the terminal when the pane is focused at the moment of the write (per [tmux#3793](https://github.com/tmux/tmux/issues/3793), this is deliberate — background panes are not allowed to set the clipboard). If you've switched away from the pane running Claude Code between invoking the export and pasting, the write is dropped with no error and nothing changes in your clipboard. If a paste comes up empty, re-run the export while keeping the pane focused.

This needs no local helper script, no staging directory, and no explicit pull step — it's a single command, mirroring `/copy`. The tradeoff is the silent failure above, which has no fallback: a failed copy just means re-running the export.

## Environment

| Variable | Where | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` | local machine | Absolute path to the Obsidian vault. Required for a local export. |
| `CLAUDE_SESSION_ID`, `CLAUDE_PROJECT_DIR` | provided by Claude Code | Used to locate the current transcript. |

## Dependencies

- `python3` (standard library only) — the renderer, on whichever box the session runs.
- `tmux` with `set-clipboard on` and `allow-passthrough on` on the live server — required for the remote clipboard copy.
- A local terminal emulator that supports OSC 52 (e.g. Ghostty, iTerm2) — required for the remote clipboard copy.

## Tests

```bash
python3 skills/export-to-clipboard/scripts/tests/test_render_transcript.py
```
