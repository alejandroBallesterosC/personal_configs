# Goal
Update the CLAUDE.md files and all relevant docmentation (.md) files in this repo so they accurately reflect the current state of the repo/codebase. The CLAUDE.md files should help claude code work effectively in the repo, while other markdown documentation files should help new people to the repo effectively work in it.

# Instructions
Do this by first reviewing the progress we have made, then review the current state of the entire codebase very thoroughly, then thoroughly review all documentation files (.md) in this repo, next ensure these documentation files are all up to date with our current progress and state of the codebase by updating them while adhering to the specified requirements below. Finally, review the CLAUDE.md files throughout this repo and update them according to the specified requirements below.

# Requirements
- Do not write TODOs or elaborate potential improvements in any CLAUDE.md or other documentation file that I have not explicitly asked for, if you want to note suggested improvements or things to think about long term you can do that in a very concise section at a high level.
- Do not use Emojis.
- If a central README.md does not exist in the root of this repo please create one. If a CLAUDE.md does not exist in the root of this repo please create one.

## Documentation Specific Requirements
- The documentation should help someone new to the repo understand it and self-serve easily, keep only information that does this and do not be overly verbose. The docs should be concise while still going into enough detail to be helpful for people to self-serve.
- Remove stale information that is no longer accurate or in sync with the current state of the codebase.
- Ensure all of the documentation files (.md) are linked and explained at the beginning of the main/central README.md in the root of the repo

## CLAUDE.md Specific Requirements
When updating the CLAUDE.md files in this repo:
- Thoroughly review the current contents of **CLAUDE.md** in the root of the repo first.
- Prune any outdated or redundant items (commands, workflows, gotchas).
- Maintain a bulleted list of the important tools, commands, or scripts for working in the codebase.
- Maintain a bulleted list of changes in workflows, build/test/deploy commands, or directory structure.
- Maintain a bulleted list of Project-specific gotchas or exceptions.
- Maintain a project map: Key modules & where code lives (1–2 bullets each), the existing high-level structure (architecture, conventions, commands, gotchas).
- Keep the file **concise, bullet-based, and actionable** (no long prose).
- Use `@path/to/file` imports if a section is long or duplicated elsewhere. This is helpful for referencing the documentation that already exists in the codebase.
- Preserve clarity: ensure each bullet is precise and unambiguous.
- If the CLAUDE.md file is longer than the recommended limit please remove old updates and/or summarize older or less relevant information as necessary. As of 9/24/2025 this limit was 40k characters but please validate this is still true today.

### General CLAUDE.md Best Practices
- Remember that CLAUDE.md files are hierarchical - subdirectory files provide context when working in that directory so do not provide information in a CLAUDE.md file that doesn't correspond to the location of that file in the repo. CLAUDE.md files in the root of the repo cover the entire repo.
- Keep CLAUDE.mds concise, human-readable, actionable
- Document: commands, gotchas, workflows, naming patterns, critical warnings
- Use "IMPORTANT" or "YOU MUST" for critical adherence
- Include code examples and specific file references
- Make it a living document (update as you learn)