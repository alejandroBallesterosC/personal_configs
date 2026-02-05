# Ralph Loop Command

Start a Ralph Wiggum loop in your current session for iterative development.

## Parameters

This command accepts:
- `PROMPT` (required): The task to work on iteratively
- `--max-iterations N`: Maximum iterations before auto-stop (default: unlimited)
- `--completion-promise TEXT`: Promise phrase to signal completion

## Instructions

Execute the setup script to initialize the Ralph loop:

```bash
"$HOME/.cursor/hooks/scripts/setup-ralph-loop.sh" $ARGUMENTS
```

After setup, work on the task. When you try to exit, the Ralph loop stop hook will feed the SAME PROMPT back to you for the next iteration. You'll see your previous work in files and git history, allowing you to iterate and improve.

## Completion

If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE:

```
<promise>YOUR_PROMISE_TEXT</promise>
```

Do not output false promises to escape the loop. The loop is designed to continue until genuine completion.

## Examples

```
/ralph-loop Build a REST API --max-iterations 20 --completion-promise 'API COMPLETE'
/ralph-loop Fix the auth bug --max-iterations 10
/ralph-loop Refactor the cache layer --completion-promise 'REFACTOR DONE'
```
