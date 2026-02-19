# UPDATE DOCS

## Objective
Update all relevant docmentation (.md) files in this repo so they accurately reflect the current state of the repo/codebase. DO NOT EDIT OR UPDATE ANY CLAUDE.md files in this repo.

## Instructions
1. Launch four Claude Sonnet code-explorer agents in parallel such that they each independently review the current state of the entire codebase very thoroughly.

2. Next, spawn four Claude Sonnet agents in parallel to thoroughly review all documentation files (.md) in this repo.
   
3. Finally use the agents' findings to surface cases where the documentation files are not up to date or are in conflict with the current state of the codebase (not consistent) and other documentation files.
   
4. Update the documentation files while adhering to the specified requirements below. By the end all documentation files should be consistent with the current state of the codebase and all other documentation files in this repo.

## Requirements
- EXCLUDE ALL CLAUDE.md files from this. DO NOT EDIT OR UPDATE ANY CLAUDE.md files in this repo.
- NEVER not write TODOs or potential improvements in any documentation file that I have not explicitly asked for.
- NEVER use Emojis.
- If a central README.md does not exist in the root of this repo please create one.

### Documentation Specific Requirements
- Remove stale information that is no longer accurate or in sync with the current state of the codebase.
- Ensure all of the documentation files (.md) are linked and explained at the beginning of the main/central README.md in the root of the repo
- Use `@path/to/file` imports to reference existing documentation instead of duplicating content when possible