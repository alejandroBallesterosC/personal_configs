---
description: Export feedback for user
allowed-tools: Read, Grep, Glob, Bash, Task, Write, Edit, SlashCommand
---

# Export Feedback

Review this conversation's history to provide the user feedback informed by credible recent sources about what they did well and what they coud've improved in their use of Claude Code to accomplish their goal this conversation.

## Methodology
1. Review this conversation's history
2. Browse the official Anthropic documentation and blogs about Claude Code on the internet, Boris Cherny's most recent tweets on X: @bcherny, Thariq Shiphar's most recent tweets on X: @trq212, to find recent Claude Code best practices / advice.
3. Write feedback to the user about what they did well and what they did poorly when using Claude Code to accomplish their goal based on the information you found online.
s
## Guidelines:
- Write the feedback as a plain text (.txt) file in .claude/feedback (create this directory if it does not yet exist).
- The file title should be the datetime of the start of the conversation 'DD-MM-YY__HH-MM-SS.txt' (military time standardized to ET time zone)

## Critical Constraint
** DO NOT MAKE ANY EDITS OR CHANGES TO ANY OTHER FILES IN THIS REPO, DO NOT COMMIT ANYTHING. JUST DO THE TASK ABOVE**

