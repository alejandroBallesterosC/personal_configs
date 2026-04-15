#!/bin/sh
# ABOUTME: Sends terminal bell and macOS banner notifications for Claude Code events.
# ABOUTME: Uses terminal-notifier with click-to-focus if available, falls back to osascript.

kind="${1:-input}"

# Drain stdin to prevent EPIPE errors from the hook runner
cat > /dev/null

# Send a BEL to the terminal/tmux client for Ghostty bell-features
printf '\a' > /dev/tty 2>/dev/null || true

# macOS banner notification with terminal-notifier (preferred) or osascript (fallback)
if command -v terminal-notifier > /dev/null 2>&1; then
  project="$(basename "$PWD")"
  case "$kind" in
    input)
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "$project" \
        -message "Needs your input" \
        -sound Funk \
        -activate com.mitchellh.ghostty
      ;;
    done)
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "$project" \
        -message "Finished responding" \
        -sound Glass \
        -activate com.mitchellh.ghostty
      ;;
  esac
else
  case "$kind" in
    input)
      osascript -e 'display notification "Claude Code needs your input" with title "Claude Code" sound name "Funk"'
      ;;
    done)
      osascript -e 'display notification "Claude finished responding" with title "Claude Code" sound name "Glass"'
      ;;
  esac
fi
