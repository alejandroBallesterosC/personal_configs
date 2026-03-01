# Claude Session Feedback Plugin

Tools for exporting conversation history, reading past sessions, and getting feedback on Claude Code usage.

## Components

- **4 commands**: export-conversation, read-conversation-history, provide-user-feedback, research-best-practices

## Commands

| Command | Purpose |
|---------|---------|
| `/claude-session-feedback:export-conversation` | Export current conversation to `.claude/history/` as timestamped `.txt` file with summary |
| `/claude-session-feedback:read-conversation-history` | Browse previously exported conversations in `.claude/history/` |
| `/claude-session-feedback:provide-user-feedback` | Get feedback on your Claude Code usage informed by recent best practices from Anthropic engineers |
| `/claude-session-feedback:research-best-practices <prompt>` | Research Claude Code best practices from official docs and expert sources, then answer a question |

## Conversation History Format

Exported conversations are stored as plain text files:
- **Location**: `.claude/history/` (created if it does not exist)
- **Filename**: `DD-MM-YY__HH-MM-SS.txt` (ET timezone, 24-hour format)
- **Content**: Summary at top, followed by conversation transcript

## Usage

```bash
# Export current conversation before compacting
/claude-session-feedback:export-conversation

# Read past sessions after compacting or in a fresh session
/claude-session-feedback:read-conversation-history

# Get feedback on how you used Claude Code this session
/claude-session-feedback:provide-user-feedback

# Research a Claude Code question using credible sources
/claude-session-feedback:research-best-practices "What are the best practices for using subagents?"
```

## Version

1.0.0
