#!/bin/sh
# ABOUTME: Sends terminal bell and macOS banner notifications for Claude Code events.
# ABOUTME: Bell via the hook JSON terminalSequence field; banners via terminal-notifier or osascript.

kind="${1:-input}"

# Drain stdin to prevent EPIPE errors from the hook runner
cat > /dev/null

# Hooks run without a controlling terminal, so writing BEL to /dev/tty fails. Instead the hook
# asks Claude Code to emit the BEL on its own terminal, which reaches tmux and Ghostty's
# bell-features the same way. This JSON must be the hook's only stdout.
printf '{"terminalSequence":"\\u0007"}\n'

# macOS banner notification with terminal-notifier (preferred) or osascript (fallback).
# Their output is discarded so it cannot corrupt the JSON above.
if command -v terminal-notifier > /dev/null 2>&1; then
  project="$(basename "$PWD")"
  case "$kind" in
    input)
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "$project" \
        -message "Needs your input" \
        -sound Funk \
        -activate com.mitchellh.ghostty > /dev/null 2>&1
      ;;
    done)
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "$project" \
        -message "Finished responding" \
        -sound Glass \
        -activate com.mitchellh.ghostty > /dev/null 2>&1
      ;;
  esac
elif command -v osascript > /dev/null 2>&1; then
  case "$kind" in
    input)
      osascript -e 'display notification "Claude Code needs your input" with title "Claude Code" sound name "Funk"' > /dev/null 2>&1
      ;;
    done)
      osascript -e 'display notification "Claude finished responding" with title "Claude Code" sound name "Glass"' > /dev/null 2>&1
      ;;
  esac
fi

# Banners are macOS-only. On other platforms the bell above is the whole
# notification, so exit successfully rather than reporting a hook failure.
exit 0
