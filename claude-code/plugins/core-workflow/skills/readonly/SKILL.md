---
name: readonly
description: Run a prompt in read-only mode (no file edits, no git changes). User-invoked only.
disable-model-invocation: true
argument-hint: <prompt>
allowed-tools: Read, Grep, Glob, LS, WebSearch, WebFetch, Task, TodoRead
---

# Instructions:

You are to carry out the following prompt thoroughly. If the following prompt is empty or blank, respond with "Usage: /core-workflow:readonly <prompt>" and stop.

## IMPORTANT: DO NOT EDIT ANY CODE, CHANGE ANY FILES, OR MAKE ANY GIT ADDITIONS, COMMITS, or PUSHES WHILE CARRYING OUT THESE INSTRUCTIONS.

## Prompt:
$ARGUMENTS
