---
name: readonly
description: Run a prompt in read-only mode (no file edits, no git changes). User-invoked only.
disable-model-invocation: true
argument-hint: <prompt>
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch, Agent
disallowed-tools: Edit, Write, NotebookEdit, Bash
---

# Instructions:

You are to carry out the following prompt. If the following prompt is empty or blank, respond with "Usage: /core-workflow:readonly <prompt>" and stop.

This is a read-only investigation: report findings, do not change anything. `disallowed-tools` blocks edits and shell access for this turn, so answer from reading alone. If you delegate, use read-only agents such as `Explore`, so the delegated work stays read-only too.

## Prompt:
$ARGUMENTS
