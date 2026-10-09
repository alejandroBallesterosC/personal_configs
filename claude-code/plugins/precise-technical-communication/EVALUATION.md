# Evaluation prompts

## Automated cases

Prompts 1, 5, and 6 below run automatically as `claude plugin eval` cases in `evals/` (Claude Code 2.1.269 or later). Each case runs with and without the plugin, so the report shows how much of the behavior the plugin adds on top of the model's defaults. From the plugin root:

```bash
claude plugin eval . --model claude-opus-5-5 --no-publish
```

| Case | Prompt | Graders |
| --- | --- | --- |
| `evals/out-of-sample-summary` | 1. Summary result | LLM judge on criterion, full case list, count with total, and what the data does not show |
| `evals/benchmark-claim` | 5. Benchmark | LLM judge on absolute and relative change, no unsupported "statistically significant", stated limits |
| `evals/simple-question` | 6. Simple question | Regex: names the file; no report headings |

Pin `--model` so a model release is not mistaken for a plugin regression. Results land in `evals/results/`, which is gitignored.

## Manual prompts

The remaining prompts need a real repository or an earlier conversation, so they stay manual. Run each prompt in a fresh Claude Code session with the plugin enabled, then again with it disabled, and compare the responses against the checks below.

## 1. Summary result

Prompt:

> Analyze these ten strategy results and tell me which ones fail OOS.

Expected behavior:

1. Defines the final test period and states that it was not used for construction or tuning, or asks for this information when it is essential and unavailable.
2. Defines the success or failure criterion.
3. Explains how the ten strategies or baskets were assembled.
4. Lists each result or points to a complete table.
5. Separates the overall conclusion from limitations.

## 2. Code change summary

Prompt:

> Tell me what you changed and whether the fix is robust.

Expected behavior:

1. Names files and symbols.
2. Explains behavior before and after.
3. Defines the conditions under which the fix was tested.
4. Gives test commands and results.
5. Replaces or qualifies "robust" with measured conditions and remaining risks.

## 3. Codebase explanation

Prompt:

> Explain how an import request moves through this repository.

Expected behavior:

1. Names the entry point.
2. Describes the call sequence in order.
3. Explains state changes, external effects, and error paths.
4. Cites files and symbols.
5. States what was inferred and what was run.

## 4. Negative search claim

Prompt:

> Is the legacy flag unused?

Expected behavior:

1. States the search scope and query.
2. Distinguishes a repository search from a claim about all systems.
3. Names declarations and references found.
4. States external sources not inspected.

## 5. Benchmark

Prompt:

> Is the new parser significantly faster?

Expected behavior:

1. Defines the comparison setup.
2. Reports versions, workload, hardware when relevant, warmup, and run count.
3. Gives absolute and relative differences.
4. Uses "statistically significant" only if a stated test supports it.
5. States unmeasured dimensions and scope limits.

## 6. Simple question

Prompt:

> Which file defines the default port?

Expected behavior:

1. Gives the file and symbol directly.
2. Does not add irrelevant methodology sections.
3. States uncertainty only when a real uncertainty exists.

## 7. Progress update

Prompt:

> Investigate why the test is flaky and keep me updated.

Expected behavior:

1. First update states scope and planned decisive checks.
2. Later updates include concrete findings, not only activity.
3. Final answer is complete without requiring earlier updates.
4. Final answer distinguishes reproduced behavior, inferred cause, and untested alternatives.
