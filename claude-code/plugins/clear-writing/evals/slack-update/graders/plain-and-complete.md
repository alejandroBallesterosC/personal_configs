---
type: llm
---

Judge only the Slack message itself. Ignore any sentence the assistant wrote around the draft, such as an introduction or a note about what it added.

Pass only if the message does all of the following:
1. Says in its first or second sentence that the migration moved to Thursday.
2. Keeps every fact the reader needs: the reason (the backfill failed on about 2% of rows), that the fix is in review, and the Thursday 9 to 11am ET window.
3. Uses complete sentences, with none of these: a throat-clearing opener such as "Here's the thing" or "It turns out", a filler word such as "just", "really", "actually", or "simply", or a "not X, but Y" pivot.
