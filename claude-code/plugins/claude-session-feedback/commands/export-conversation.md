---
description: Export this conversation to .claude/history (useful before compacting)
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit, SlashCommand
---

# Export Conversation

Use the /export command to export this conversation to ./claude/history. Include a summary.

## Guidelines:
- Write the conversation history as a plain text (.txt) file in ./claude/history (create this directory if it doesn't exit).
- The file title should be the datetime of the start of the conversation 'DD-MM-YY__HH-MM-SS.txt' (military time standardized to ET time zone).
- At the top of the .txt file, write a detailed and thorough but concise summary of what was changed, what was implemented, and what was otherwise done throughout this conversation.

## Critical Constraint
** DO NOT MAKE ANY EDITS OR CHANGES TO ANY OTHER FILES IN THIS REPO, DO NOT COMMIT ANYTHING. JUST DO THE TASK ABOVE**
