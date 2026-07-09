# export-to-obsidian

Export the current Claude Code session's transcript — the full log, or just the last N turns — as a Markdown file into an Obsidian vault. The skill is **user-invoked only**: Claude can never trigger it on its own.

```
/plugin install export-to-obsidian
```

Invoke with:

```
/export-to-obsidian:export-to-obsidian        # full transcript
/export-to-obsidian:export-to-obsidian 5       # last 5 turns
```

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `export-to-obsidian` | Skill (user-only) | Runs the export. `disable-model-invocation: true`, so only you can trigger it via `/…`. |
| `scripts/render_transcript.py` | Python 3 (stdlib) | Locates the current session's JSONL, groups it into turns, renders Markdown (tool calls in collapsible blocks). |
| `scripts/export.sh` | Bash | Entry point. Detects local vs. remote and either writes to the vault or stages for a local pull. |
| `local-puller/cc-obsidian-pull.sh` | Bash (install on your Mac) | Pulls a staged transcript from a remote dev box into the vault, after an Allow/Deny prompt. |

## How it works

A "turn" is one user prompt plus the assistant's response to it, including tool calls. Files are written to `$CLAUDE_CODE_OBSIDIAN_EXPORT_PATH/claude-code-transcripts/` and named `<UTC-timestamp>-<session-prefix>[-lastN].md`.

The current session's transcript is located by **session identity, not by a path formula**: Claude Code names each transcript `<session-id>.jsonl`, so the script globs `~/.claude/projects/*/` for that filename (using `$CLAUDE_SESSION_ID`). This is deliberate — the parent directory is a lossy slug of the working directory (`/`, `_`, `.`, and spaces all collapse to `-`) and is branch-derived for git worktrees, so reconstructing the path from the cwd is unreliable.

### Local vs. remote

The script detects whether the session runs locally or on a remote box reached over SSH (via `$SSH_CONNECTION`/`$SSH_TTY`, with a process-ancestry fallback for long-lived tmux sessions):

- **Local** — writes the Markdown straight into the vault.
- **Remote** — the vault is on your local machine, which the remote box cannot (and by design must not) reach. The script stages the file on the remote host and prints a one-line command for you to run **on your local machine**.

## Secure remote → local transfer

The design goal is that the remote dev box is **never given any path back to your local machine** — no reverse tunnel, no `authorized_keys` entry, no daemon. The transfer is always initiated *and approved* locally:

1. On the remote box, invoke the skill. It stages `…/claude-code-transcripts/<file>.md` under `$CLAUDE_CODE_OBSIDIAN_STAGING_DIR` (default `~/.cache/claude-code-transcripts`) and prints a `cc-obsidian-pull` command.
2. On your local machine, run that command. It shows a macOS Allow/Deny dialog, then pulls the file with `rsync`/`scp` using the SSH credentials that only ever go local→remote.

Because the pull is local-initiated, the remote can never push a file unattended, and closing your SSH session leaves nothing behind. This was chosen over an `ssh -R` reverse-forward approach, which would open a session-scoped inbound path to your machine and needs a standing local listener — strictly more attack surface.

### Installing the local puller (on your Mac)

```bash
cp local-puller/cc-obsidian-pull.sh ~/bin/cc-obsidian-pull && chmod +x ~/bin/cc-obsidian-pull
```

Add to your local shell profile:

```bash
export CLAUDE_CODE_OBSIDIAN_EXPORT_PATH="/path/to/your/Obsidian/Vault"
```

The puller is intentionally shipped outside the plugin's runtime path — it belongs on the machine that holds the vault, not on the dev box.

## Environment

| Variable | Where | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_OBSIDIAN_EXPORT_PATH` | local machine | Absolute path to the Obsidian vault. Required for a local export and for the puller. |
| `CLAUDE_CODE_OBSIDIAN_STAGING_DIR` | remote box | Optional. Where remote exports are staged (default `~/.cache/claude-code-transcripts`). |
| `CLAUDE_SESSION_ID`, `CLAUDE_PROJECT_DIR` | provided by Claude Code | Used to locate the current transcript. |

## Dependencies

- `python3` (standard library only) — the renderer, on whichever box the session runs.
- `rsync` or `scp`, and `ssh` — on your local machine, for the remote pull.
- `osascript` (macOS, built in) — the Allow/Deny dialog; falls back to a terminal `y/N` prompt elsewhere.
- `terminal-notifier` (optional) — a confirmation banner after a successful pull.

## Tests

```bash
python3 skills/export-to-obsidian/scripts/tests/test_render_transcript.py
```
