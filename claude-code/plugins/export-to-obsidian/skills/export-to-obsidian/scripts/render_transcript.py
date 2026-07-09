#!/usr/bin/env python3
# ABOUTME: Render a Claude Code session JSONL transcript to Markdown.
# ABOUTME: Groups append-only JSONL lines into turns and can emit the full log or the last N turns.

"""Render a Claude Code session transcript (JSONL) to Markdown.

The Claude Code CLI stores each session as an append-only JSONL file at
``~/.claude/projects/<slug>/<session-id>.jsonl`` where ``<slug>`` is the
absolute working directory with every ``/`` replaced by ``-``. A user-invoked
skill receives ``CLAUDE_SESSION_ID`` and ``CLAUDE_PROJECT_DIR`` (but not the
transcript path), so this script reconstructs the path deterministically from
those, with a most-recently-modified fallback.

A "turn" is one genuine user prompt plus the assistant activity that follows it
(assistant text, thinking, tool calls, and the tool results fed back). A JSONL
line is a genuine user prompt when ``type == "user"``, ``message.content`` is a
plain string, and ``isMeta`` is not set (hook-injected feedback carries
``isMeta: true``; tool results arrive as ``user`` lines whose content is a list
of ``tool_result`` blocks).
"""

import argparse
import json
import os
import sys
from pathlib import Path

# Non-conversational bookkeeping line types that carry no message content and are
# skipped entirely when building turns.
_BOOKKEEPING_TYPES = frozenset(
    {
        "mode",
        "permission-mode",
        "file-history-snapshot",
        "ai-title",
        "last-prompt",
        "attachment",
        "summary",
    }
)

# How many characters of a tool result to show before truncating.
_TOOL_RESULT_LIMIT = 4000


def projects_root() -> Path:
    """The ~/.claude/projects directory that holds every session's transcript."""
    return Path.home() / ".claude" / "projects"


def _session_id_of(path: Path) -> str | None:
    """Read the ``sessionId`` recorded inside a transcript's first message line."""
    for obj in _iter_lines(path):
        session_id = obj.get("sessionId")
        if session_id:
            return session_id
    return None


def locate_transcript(session_id: str | None, project_cwd: str | None) -> Path:
    """Find the current session's JSONL file by identity, not by a path formula.

    Claude Code names each transcript ``<session-id>.jsonl``, but the parent
    directory is a slug of the working directory whose exact rule is lossy
    (``/``, ``_``, ``.`` and spaces all collapse to ``-``) and, for git
    worktrees, branch-derived rather than path-derived. Reconstructing the path
    from the cwd is therefore unreliable. Instead:

    1. If ``session_id`` is known, glob every project dir for ``<session-id>.jsonl``
       (the filename is the session id) — this is exact regardless of the slug.
    2. Otherwise fall back to the newest top-level ``.jsonl`` whose recorded
       ``sessionId`` matches, then to the newest top-level ``.jsonl`` overall.

    Nested ``*/subagents/*.jsonl`` sidechain files are never treated as the
    session transcript.
    """
    root = projects_root()
    if not root.is_dir():
        raise FileNotFoundError(f"No Claude Code projects directory at {root}.")

    def top_level(paths):
        # Exclude nested subagent sidechain files (…/<session>/subagents/agent-*.jsonl):
        # a real session transcript sits directly under a project dir.
        return [p for p in paths if p.parent.parent == root]

    if session_id:
        matches = top_level(root.glob(f"*/{session_id}.jsonl"))
        if matches:
            return max(matches, key=lambda p: p.stat().st_mtime)

    candidates = top_level(root.glob("*/*.jsonl"))
    if not candidates:
        raise FileNotFoundError(f"No transcript .jsonl files found under {root}.")

    if session_id:
        # The filename glob missed (unusual), but the id may still be recorded inside.
        by_content = [p for p in candidates if _session_id_of(p) == session_id]
        if by_content:
            return max(by_content, key=lambda p: p.stat().st_mtime)
        raise FileNotFoundError(
            f"No transcript found for session {session_id} under {root}. "
            f"Pass --transcript to point at the file explicitly."
        )

    # No session id available: best-effort newest transcript, optionally scoped to cwd.
    if project_cwd:
        scoped = [p for p in candidates if _session_id_of(p) and _cwd_of(p) == project_cwd]
        if scoped:
            return max(scoped, key=lambda p: p.stat().st_mtime)
    return max(candidates, key=lambda p: p.stat().st_mtime)


def _cwd_of(path: Path) -> str | None:
    """Read the ``cwd`` recorded inside a transcript's first message line."""
    for obj in _iter_lines(path):
        cwd = obj.get("cwd")
        if cwd:
            return cwd
    return None


def _iter_lines(path: Path):
    """Yield parsed JSON objects from a JSONL file, skipping malformed lines."""
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def _is_user_prompt(obj: dict) -> bool:
    """True when a line is a genuine human prompt (string content, not meta/tool_result)."""
    if obj.get("type") != "user":
        return False
    if obj.get("isMeta"):
        return False
    message = obj.get("message")
    if not isinstance(message, dict):
        return False
    return isinstance(message.get("content"), str)


def load_turns(path: Path, include_sidechains: bool = False) -> list[dict]:
    """Group the transcript's JSONL lines into turns.

    Each turn is ``{"prompt": <user line>, "events": [<following lines>]}``.
    Lines before the first genuine prompt (session metadata) are dropped. Sidechain
    (subagent) lines are dropped by default so the main conversation reads cleanly.
    """
    turns: list[dict] = []
    current: dict | None = None

    for obj in _iter_lines(path):
        if obj.get("type") in _BOOKKEEPING_TYPES:
            continue
        if obj.get("isSidechain") and not include_sidechains:
            continue

        if _is_user_prompt(obj):
            if current is not None:
                turns.append(current)
            current = {"prompt": obj, "events": []}
        elif current is not None:
            current["events"].append(obj)

    if current is not None:
        turns.append(current)
    return turns


def _fence(text: str, lang: str = "") -> str:
    """Wrap text in a fenced code block, widening the fence if the text contains backticks."""
    fence = "```"
    while fence in text:
        fence += "`"
    return f"{fence}{lang}\n{text}\n{fence}"


def _stringify(content) -> str:
    """Best-effort flatten of a content value (string, or list of blocks) to text."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                if "text" in block:
                    parts.append(block["text"])
                elif block.get("type") == "image":
                    parts.append("_[image omitted]_")
                else:
                    parts.append(json.dumps(block, ensure_ascii=False))
            else:
                parts.append(str(block))
        return "\n".join(parts)
    return str(content)


def _truncate(text: str) -> str:
    if len(text) <= _TOOL_RESULT_LIMIT:
        return text
    omitted = len(text) - _TOOL_RESULT_LIMIT
    return text[:_TOOL_RESULT_LIMIT] + f"\n… [{omitted} more characters truncated]"


def _render_assistant_block(block: dict) -> str | None:
    """Render one block from an assistant message's content array."""
    btype = block.get("type")
    if btype == "text":
        return block.get("text", "").strip() or None
    if btype == "thinking":
        thinking = block.get("thinking", "").strip()
        if not thinking:
            return None
        return f"<details>\n<summary>Thinking</summary>\n\n{thinking}\n\n</details>"
    if btype == "tool_use":
        name = block.get("name", "tool")
        tool_input = block.get("input", {})
        pretty = json.dumps(tool_input, indent=2, ensure_ascii=False)
        return (
            f"<details>\n<summary>🛠️ Tool call: <code>{name}</code></summary>\n\n"
            f"{_fence(pretty, 'json')}\n\n</details>"
        )
    return None


def _render_tool_result(block: dict) -> str:
    is_error = block.get("is_error")
    label = "❌ Tool result (error)" if is_error else "Tool result"
    body = _truncate(_stringify(block.get("content", "")).rstrip())
    return (
        f"<details>\n<summary>{label}</summary>\n\n{_fence(body)}\n\n</details>"
    )


def _render_event(obj: dict) -> list[str]:
    """Render a single non-prompt event line to Markdown fragments."""
    fragments: list[str] = []
    otype = obj.get("type")
    message = obj.get("message")

    if otype == "assistant" and isinstance(message, dict):
        content = message.get("content")
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict):
                    rendered = _render_assistant_block(block)
                    if rendered:
                        fragments.append(rendered)
        elif isinstance(content, str) and content.strip():
            fragments.append(content.strip())

    elif otype == "user" and isinstance(message, dict):
        # A non-prompt user line: tool results fed back to the model.
        content = message.get("content")
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_result":
                    fragments.append(_render_tool_result(block))

    return fragments


def render_markdown(turns: list[dict], transcript_path: Path, note: str | None = None) -> str:
    """Render grouped turns to a Markdown document."""
    lines: list[str] = []
    lines.append(f"# Claude Code transcript — {transcript_path.stem}")
    lines.append("")
    lines.append(f"- Source: `{transcript_path}`")
    lines.append(f"- Turns exported: {len(turns)}")
    if note:
        lines.append(f"- {note}")
    lines.append("")

    for index, turn in enumerate(turns, start=1):
        prompt = turn["prompt"]
        timestamp = prompt.get("timestamp", "")
        heading = f"## Turn {index}"
        if timestamp:
            heading += f" — {timestamp}"
        lines.append(heading)
        lines.append("")

        prompt_text = _stringify(prompt.get("message", {}).get("content", "")).strip()
        lines.append("**User:**")
        lines.append("")
        for prompt_line in prompt_text.splitlines() or [""]:
            lines.append(f"> {prompt_line}")
        lines.append("")

        rendered_any = False
        for event in turn["events"]:
            for fragment in _render_event(event):
                lines.append(fragment)
                lines.append("")
                rendered_any = True
        if not rendered_any:
            lines.append("_(no assistant response recorded)_")
            lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--last",
        type=int,
        default=None,
        metavar="N",
        help="Export only the last N turns (default: the whole transcript).",
    )
    parser.add_argument(
        "--session-id",
        default=os.environ.get("CLAUDE_SESSION_ID"),
        help="Session id (defaults to $CLAUDE_SESSION_ID).",
    )
    parser.add_argument(
        "--project-dir",
        default=os.environ.get("CLAUDE_PROJECT_DIR"),
        help="Session working directory (defaults to $CLAUDE_PROJECT_DIR, then cwd).",
    )
    parser.add_argument(
        "--transcript",
        default=None,
        help="Explicit transcript .jsonl path (overrides session-id/project-dir lookup).",
    )
    parser.add_argument(
        "--include-sidechains",
        action="store_true",
        help="Include subagent (sidechain) lines in the main turn sequence.",
    )
    parser.add_argument(
        "--output",
        "-o",
        default=None,
        help="Write Markdown to this path (default: stdout).",
    )
    args = parser.parse_args(argv)

    if args.last is not None and args.last <= 0:
        parser.error("--last must be a positive integer")

    try:
        if args.transcript:
            transcript = Path(args.transcript).expanduser()
            if not transcript.is_file():
                raise FileNotFoundError(f"Transcript not found: {transcript}")
        else:
            transcript = locate_transcript(args.session_id, args.project_dir)
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    turns = load_turns(transcript, include_sidechains=args.include_sidechains)
    note = None
    if args.last is not None and args.last < len(turns):
        turns = turns[-args.last :]
        note = f"Last {len(turns)} of the session's turns"

    markdown = render_markdown(turns, transcript, note=note)

    if args.output:
        out_path = Path(args.output).expanduser()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(markdown, encoding="utf-8")
        print(str(out_path))
    else:
        sys.stdout.write(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
