#!/usr/bin/env python3
# ABOUTME: Tests for the Claude Code transcript renderer.
# ABOUTME: Covers turn grouping, isMeta/sidechain/bookkeeping filtering, last-N, and rendering.

"""Run with: python3 test_render_transcript.py  (stdlib unittest, no dependencies)."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import render_transcript as rt  # noqa: E402


def write_jsonl(lines: list[dict]) -> Path:
    tmp = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8")
    for obj in lines:
        tmp.write(json.dumps(obj) + "\n")
    tmp.flush()
    tmp.close()
    return Path(tmp.name)


def user_prompt(text, ts="2026-01-01T00:00:00.000Z", **extra):
    obj = {"type": "user", "timestamp": ts, "message": {"role": "user", "content": text}}
    obj.update(extra)
    return obj


def assistant(blocks, **extra):
    obj = {"type": "assistant", "message": {"role": "assistant", "content": blocks}}
    obj.update(extra)
    return obj


def tool_result_line(content, is_error=False):
    return {
        "type": "user",
        "message": {
            "role": "user",
            "content": [{"type": "tool_result", "tool_use_id": "t1", "content": content, "is_error": is_error}],
        },
    }


class TurnGroupingTests(unittest.TestCase):
    def test_basic_turns(self):
        path = write_jsonl(
            [
                {"type": "mode", "mode": "normal"},  # bookkeeping, dropped
                user_prompt("first question"),
                assistant([{"type": "text", "text": "first answer"}]),
                user_prompt("second question"),
                assistant([{"type": "text", "text": "second answer"}]),
            ]
        )
        turns = rt.load_turns(path)
        path.unlink()
        self.assertEqual(len(turns), 2)
        self.assertEqual(turns[0]["prompt"]["message"]["content"], "first question")
        self.assertEqual(len(turns[0]["events"]), 1)

    def test_ismeta_user_is_not_a_turn(self):
        # Hook-injected feedback arrives as a user line with isMeta:true and must not
        # start a new turn.
        path = write_jsonl(
            [
                user_prompt("real prompt"),
                assistant([{"type": "text", "text": "answer"}]),
                user_prompt("Stop hook feedback: ...", isMeta=True),
                assistant([{"type": "text", "text": "post-hook answer"}]),
            ]
        )
        md = rt.render_markdown(rt.load_turns(path), path)
        turns = rt.load_turns(path)
        path.unlink()
        # The isMeta feedback must not open a second turn.
        self.assertEqual(len(turns), 1)
        # It is retained as an event (alongside both assistant replies) but not rendered
        # as a user prompt, so its text does not appear as a "**User:**" block.
        self.assertEqual(len(turns[0]["events"]), 3)
        self.assertEqual(md.count("**User:**"), 1)
        self.assertIn("post-hook answer", md)

    def test_tool_result_user_is_not_a_turn(self):
        path = write_jsonl(
            [
                user_prompt("do a thing"),
                assistant([{"type": "tool_use", "id": "t1", "name": "Bash", "input": {"command": "ls"}}]),
                tool_result_line("file1\nfile2"),
                assistant([{"type": "text", "text": "done"}]),
            ]
        )
        turns = rt.load_turns(path)
        path.unlink()
        self.assertEqual(len(turns), 1)
        self.assertEqual(len(turns[0]["events"]), 3)

    def test_sidechain_excluded_by_default(self):
        path = write_jsonl(
            [
                user_prompt("main prompt"),
                assistant([{"type": "text", "text": "main answer"}]),
                user_prompt("sidechain prompt", isSidechain=True),
                assistant([{"type": "text", "text": "sidechain answer"}], isSidechain=True),
            ]
        )
        turns = rt.load_turns(path)
        self.assertEqual(len(turns), 1)
        turns_with = rt.load_turns(path, include_sidechains=True)
        path.unlink()
        self.assertEqual(len(turns_with), 2)

    def test_leading_metadata_dropped(self):
        # Lines before the first genuine prompt are session metadata, not a turn.
        path = write_jsonl(
            [
                {"type": "permission-mode", "permissionMode": "default"},
                assistant([{"type": "text", "text": "orphan"}]),  # no preceding prompt
                user_prompt("actual first prompt"),
            ]
        )
        turns = rt.load_turns(path)
        path.unlink()
        self.assertEqual(len(turns), 1)


class RenderingTests(unittest.TestCase):
    def test_last_n_slice(self):
        lines = []
        for i in range(5):
            lines.append(user_prompt(f"q{i}"))
            lines.append(assistant([{"type": "text", "text": f"a{i}"}]))
        path = write_jsonl(lines)
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns[-2:], path, note="Last 2 of the session's turns")
        path.unlink()
        self.assertIn("Last 2 of the session's turns", md)
        self.assertIn("q3", md)
        self.assertIn("q4", md)
        self.assertNotIn("q0", md)

    def test_tool_call_and_result_render_as_details(self):
        path = write_jsonl(
            [
                user_prompt("run it"),
                assistant([{"type": "tool_use", "id": "t1", "name": "Bash", "input": {"command": "ls"}}]),
                tool_result_line("output here"),
            ]
        )
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns, path)
        path.unlink()
        self.assertIn("<details>", md)
        self.assertIn("Tool call", md)
        self.assertIn("Bash", md)
        self.assertIn("output here", md)

    def test_error_tool_result_flagged(self):
        path = write_jsonl(
            [
                user_prompt("run it"),
                tool_result_line("boom", is_error=True),
            ]
        )
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns, path)
        path.unlink()
        self.assertIn("error", md.lower())

    def test_thinking_block_collapsed(self):
        path = write_jsonl(
            [
                user_prompt("think"),
                assistant([{"type": "thinking", "thinking": "secret reasoning", "signature": "x"}]),
            ]
        )
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns, path)
        path.unlink()
        self.assertIn("Thinking", md)
        self.assertIn("secret reasoning", md)

    def test_fence_widens_around_backticks(self):
        # Tool output containing a code fence must not break out of its own fence.
        path = write_jsonl(
            [
                user_prompt("show code"),
                tool_result_line("```python\nprint('hi')\n```"),
            ]
        )
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns, path)
        path.unlink()
        self.assertIn("````", md)  # fence widened to 4+ backticks

    def test_truncation(self):
        big = "x" * (rt._TOOL_RESULT_LIMIT + 500)
        path = write_jsonl(
            [
                user_prompt("big"),
                tool_result_line(big),
            ]
        )
        turns = rt.load_turns(path)
        md = rt.render_markdown(turns, path)
        path.unlink()
        self.assertIn("more characters truncated", md)


class LocatorTests(unittest.TestCase):
    """The locator matches on session id (the filename), not a cwd->slug formula."""

    def _fake_home(self, home: Path):
        orig = rt.Path.home
        rt.Path.home = staticmethod(lambda: home)
        self.addCleanup(lambda: setattr(rt.Path, "home", orig))

    def _line(self, session_id, cwd="/tmp/example"):
        return json.dumps({"type": "user", "sessionId": session_id, "cwd": cwd,
                           "message": {"role": "user", "content": "hi"}}) + "\n"

    def test_finds_by_session_id_across_arbitrary_slug_dir(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            # A slug dir whose name matches NO cwd formula (as real worktree slugs don't).
            proj = home / ".claude" / "projects" / "-some-branch-derived-slug"
            proj.mkdir(parents=True)
            target = proj / "sess-abc.jsonl"
            target.write_text(self._line("sess-abc"))
            (proj / "sess-other.jsonl").write_text(self._line("sess-other"))
            self._fake_home(home)
            self.assertEqual(rt.locate_transcript("sess-abc", "/tmp/example"), target)

    def test_ignores_subagent_sidechain_files(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            proj = home / ".claude" / "projects" / "-proj"
            (proj / "sess-abc" / "subagents").mkdir(parents=True)
            main = proj / "sess-abc.jsonl"
            main.write_text(self._line("sess-abc"))
            # A nested sidechain file that happens to share the session id must be ignored.
            (proj / "sess-abc" / "subagents" / "sess-abc.jsonl").write_text(self._line("sess-abc"))
            self._fake_home(home)
            self.assertEqual(rt.locate_transcript("sess-abc", None), main)

    def test_unknown_session_id_raises(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            proj = home / ".claude" / "projects" / "-proj"
            proj.mkdir(parents=True)
            (proj / "sess-real.jsonl").write_text(self._line("sess-real"))
            self._fake_home(home)
            with self.assertRaises(FileNotFoundError):
                rt.locate_transcript("sess-missing", None)


if __name__ == "__main__":
    unittest.main(verbosity=2)
