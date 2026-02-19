---
description: Update all docs and todos in this repo
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit, Skill
---

# Update Docs and ToDos

Update the CLAUDE.md files and all relevant docmentation (.md) files in this repo so they accurately reflect the current state of the repo/codebase. The CLAUDE.md files should help claude code work effectively in the repo, while other markdown documentation files should help new people to the repo effectively work in it.

## Instructions

1. Launch four Claude Sonnet code-explorer agents in parallel such that they each independently review the current state of the entire codebase very thoroughly.

2. Next, spawn four Claude Sonnet agents in parallel to thoroughly review all documentation files (.md) in this repo.
   
3. Finally use the agents' findings to surface cases where the documentation files are not up to date or are in conflict with the current state of the codebase (not consistent) and other documentation files.
   
4. Update the documentation files while adhering to the specified requirements below. By the end all documentation files should be consistent with the current state of the codebase and all other documentation files in this repo.


## Requirements

- NEVER not write TODOs or potential improvements in any non CLAUDE.md documentation file that I have not explicitly asked for. If you want to note suggested improvements or things to think about long term in a CLAUDE.md file you can do that in a very concise section at a high level, but never in other types of documentation (.md) files.
- Some documentation files are meant to detail workflow progress for LLMs, please make sure you keep the formatting the same when updating these files.
- NEVER use Emojis.
- If a central README.md does not exist in the root of this repo please create one.
- If a CLAUDE.md does not exist in the root of this repo please create one.

## Documentation Specific Requirements

- Remove stale information that is no longer accurate or in sync with the current state of the codebase.
- If a major component of the current codebase is missing documentation, add it.
- Ensure all of the documentation files (.md) are linked and explained at the beginning of the main/central README.md in the root of the repo

## CLAUDE.md Specific Requirements

- ALWAYS load the `/claude-md-best-practices:writing-claude-md` skill when making any change to a CLAUDE.md file
- Ensure CLAUDE.md files are consistent with READMEs and other documentation files and up to date with the current state of the codebase
- Prune outdated or redundant items
- Use `@path/to/file` imports to reference existing documentation instead of duplicating content when possible