# Cancel Ralph Loop

Cancel an active Ralph Wiggum loop.

## Instructions

1. Check if `.cursor/ralph-loop.local.md` exists:
   ```bash
   test -f .cursor/ralph-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"
   ```

2. **If NOT_FOUND**: Say "No active Ralph loop found."

3. **If EXISTS**:
   - Read `.cursor/ralph-loop.local.md` to get the current iteration number from the `iteration:` field
   - Remove the file:
     ```bash
     rm .cursor/ralph-loop.local.md
     ```
   - Report: "Cancelled Ralph loop (was at iteration N)" where N is the iteration value
