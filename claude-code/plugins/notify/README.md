# notify

Terminal bell and macOS banner notifications when Claude Code needs input or finishes responding. Designed for tmux + Ghostty workflows.

## What it does

- Sends a BEL character to trigger Ghostty's `bell-features` (dock bounce, title indicator, border flash, system sound)
- Shows a macOS banner notification with project context and click-to-focus via `terminal-notifier`
- Falls back to `osascript` if `terminal-notifier` is not installed

## Hook events

| Event | Matcher | Trigger |
|-------|---------|---------|
| `Notification` | `permission_prompt\|idle_prompt\|elicitation_dialog` | Claude needs your input (permission, idle, or MCP dialog) |
| `Stop` | (all) | Claude finished responding |

## Dependencies

```bash
brew install terminal-notifier
```

Without `terminal-notifier`, notifications fall back to `osascript` (no click-to-focus, no per-event sounds, notifications appear under "Script Editor" in Notification Center).

## Setup

### Ghostty

Add to `~/.config/ghostty/config`:

```
bell-features = system,attention,title,border
```

### tmux (optional but recommended)

Add to `~/.tmux.conf` to forward bells from background panes to Ghostty:

```tmux
set -g bell-action any
set -g visual-bell off
setw -g monitor-bell on
```

- `bell-action any` forwards bells from all windows, not just the active one
- `visual-bell off` (default) ensures the BEL reaches Ghostty instead of being intercepted by tmux
- `monitor-bell on` highlights the window name in the status bar when a bell fires

### Sticky notifications (optional)

To prevent notifications from auto-dismissing after 5 seconds:

System Settings > Notifications > terminal-notifier > change "Banners" to "Alerts"

## Installation

```
/plugin install notify
```
