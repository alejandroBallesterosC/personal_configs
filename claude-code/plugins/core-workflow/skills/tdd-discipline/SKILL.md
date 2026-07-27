---
name: tdd-discipline
description: TDD guidance for the RED/GREEN/REFACTOR cycle. Use when writing tests, implementing test-driven, or refactoring under test coverage.
---

# TDD Discipline

## Test with real services and real APIs

Strongly prefer real data and real APIs. Reach for a mock only in two cases: an internal component being developed in parallel in the same codebase that genuinely does not exist yet, or an external API that has failed after many attempts. The second should be rare.

When you do test against a mock, say so unprompted. A passing test suite that never touched the real API is a different claim than one that did, and the user cannot tell the difference from the output.

## Do not hack your way around tests

Do not hard-code a value to satisfy an assertion, weaken an assertion, or reshape the test to match broken behavior. Implement the intended functionality in good faith. A green suite bought this way is worse than a red one, because it also destroys the signal.

## The cycle

```
RED → GREEN → REFACTOR → (repeat)
```

**RED** — Write one failing test. Confirm it fails for the reason you expect, not from a typo or an import error. The name should describe the behavior. One test at a time: writing ten and then implementing is not TDD, it is a spec followed by a sprint.

**GREEN** — Write the minimum code to pass this test. Do not generalize past it, add options nobody asked for, or optimize. Over-engineering during GREEN is the most common way the cycle degrades.

**REFACTOR** — Improve the code with the tests staying green. One change at a time, run the tests after each, undo when they go red. Never refactor while red: you lose the ability to tell which change broke what.

## Writing the tests

Structure each test as arrange, act, assert, and let the phases be visible. A reader should be able to see the setup, the single action under test, and the claim.

Cover the boundaries, since this is where defects actually live: zero items, one item, many, minimum and maximum values, invalid input, empty strings and nulls.

Each test runs in isolation — no dependence on another test, no dependence on execution order, and it cleans up after itself.

Test public behavior, not private methods. A test coupled to internals fails during honest refactors and stops meaning anything.

## Running them

Run the project's test command after GREEN and after every refactor, as a normal part of the cycle rather than something a hook has to force. If the command is not obvious, check the README, `package.json` scripts, or the CI config.

For visual and frontend verification, use the `playwright` plugin's skill.
