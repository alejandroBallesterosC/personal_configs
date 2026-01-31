---
description: Browse Conversation History in .claude/history (useful after compacting)
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit, SlashCommand
---

# Read Conversations

Browse through conversation histories in the .claude/history/ directory to understand what the user did in previous conversations and know where to search for more information in the future if necessary.

## Guidelines:
- The conversation histories are stored as as plain text (.txt) files in ./claude/history (create this directory if it doesn't exit).
- The file titles should be the datetime of the start of each conversation 'DD-MM-YY__HH-MM-SS.txt' (military time standardized to ET time zone).
- At the top of each .txt file, there should be a detailed and thorough but concise summary of what was changed, what was implemented, and what was otherwise done throughout that conversation.
- If there are no files here or the directory doesn't exist, just report to the user that there is no conversation history exported in .claude/history.

## Critical Constraint
** DO NOT MAKE ANY EDITS OR CHANGES TO ANY OTHER FILES IN THIS REPO, DO NOT COMMIT ANYTHING. JUST DO THE TASK ABOVE**
