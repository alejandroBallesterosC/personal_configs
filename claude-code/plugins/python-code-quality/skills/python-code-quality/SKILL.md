---
name: python-code-quality
description: Use when writing, reviewing, refactoring, cleaning up, hardening, or "minskifying" Python code. The verification-first, runtime-validated (Pydantic-at-boundaries), legible-artifact philosophy for Python, and the anti-overengineering guardrails that keep it pragmatic.
---

# Python Code Quality

## Overview

This skill captures a philosophy for Python code quality, clean up, and hardening code.


A lot of the inspiration is taken from Ron Minsky's "reliable software in the age of agents" argument.

**The core argument:** agents make *producing* code cheap, so the bottleneck moves
to everything downstream — understanding, verifying, reviewing, and safely evolving
the system. The winning move is to invest in **machine-checkable feedback loops** and
**legible artifacts** that maximize human (and agent) comprehension — *without*
adding ceremony that produces no real guarantee. Types/Classes are first class tools for
achieving these goals, but they must be paired with runtime guarantees and not be over-engineered.

**The prime directive:**

```
Every unit of rigor you add must buy a real, runtime guarantee that makes the code more itentional and safer AND/OR make the codebase simpler and more readable to a human. If it buys neither, it is overengineering.
```

The most common failure mode is *rigor theater*: machinery that looks disciplined
(a wall of type annotations, a passing type-check gate, a clever abstraction) but
catches nothing at runtime and makes nothing clearer. Reject it.

## When to Use
- When writing any new code, to make sure it is high quality.
- When reviewing code.
- Refactoring or cleaning up an existing codebase ("strip the frankenstein code",
  "make this safer", "tighten the types", "make the prompts legible").
- Deciding whether a proposed rigor mechanism (a type checker gate, a new
  abstraction, a snapshot test) is worth its carrying cost.

## The Pillars

### 1. Contract-Driven Design: Runtime validation at boundaries

Obsesses over interface contracts: what IS guaranteed, what is NOT, ordering semantics, atomicity.
Contracts are the source of truth; implementations must comply.

Put the guarantee where data actually enters the system: request models, LLM wire
payloads, queue messages, config. A Pydantic model that 422s on bad input or raises
a loud `ValidationError` on a malformed LLM response is a **real** guarantee that
holds at runtime. That is the kind of rigor that pays for itself.

- Pydantic models also make the code more readable, it is much easier to understand what
  the inputs of a function are when there are classes/models, Dict and Any types obfuscate
  the expected inputs and outputs, and therefore expected behavior/functionality of code. We strongly
  prefer pydantic models that can be validated at runtime for this reason.

- Parse external/LLM JSON into a Pydantic model with `model_validate`; do not hand-roll
  `.get()` chains and `isinstance` checks. The model is the single source of truth for
  the shape, and the failure is loud and located.

- Use `Literal` aliases for closed string vocabularies (run modes, roles, enums) in a
  single shared module. On a Pydantic field this also bites at runtime (invalid value →
  422). On a plain function arg it is "only" IDE/reader feedback — still worth it for
  legibility, but be honest that it is not a runtime guarantee.

- Make illegal states hard/impossible to construct, but prefer the *cheapest* form that works:
  a `Literal` field or a small model over a discriminated-union refactor, unless the
  union genuinely prevents a bug that is otherwise reachable.

- Fail loudly when contracts are not upheld. Treat silent failures as the worst imaginable thing.

  
### 2. Expect tests / golden oracles — build them FIRST

Before touching code you intend to preserve the behavior of, capture a byte-exact (or
structured-exact) snapshot of its current output. This is the regression oracle that
lets every later change be verified mechanically, and lets a human review behavior as
a diff. For an LLM pipeline, snapshot the **fully rendered prompts** and the
**API contract field sets** — these are deterministic even when the model is not.

- Capture goldens from the real code paths, commit them as data, and have the test
  only *compare* (never regenerate inline).
- Freeze contract surfaces (request/response field sets, response-builder keys) so an
  accidental addition/removal fails loudly. When a legitimate field is added, updating
  the frozen set is a deliberate, reviewable one-line diff — that friction is the point.
- Treat byte-stability as contractual where it matters (e.g. provider prompt caches key
  on prompt bytes).

### 3. Legibility = the artifact a human opens, not cleaner plumbing

High quality code is not just code that works. High quality code is code that is human readable,
intuitive, and easy to reason about. The standard is always very readable code.

- Strongly dislike obfuscated code where the inputs, behavior, and outputs are not clear.
- Strongly dislike over-abstracted code that becomes obfuscated and less readable.

### 4. Less is More

- If a design needs multiple ways to do the same thing, the model is wrong. Collapse parallel mechanisms until there is one obvious, conceptually clean path.
  Push ownership toward the layer where the concept logically lives — not the nearest convenient one.
- Less code that is simpler and more readable is better than bloated code with bloated abstractions that is obfuscated and not readable.
- Aggressively shrink interfaces so each abstraction owns only what truly belongs there.
- Dislike leaking a specific implementation need into a broad abstraction.
- When a feature gets awkward, go straight to the schema or object model. Would rather change the underlying model than preserve a leaky shape.
- Strong simplification bias — when given a choice, tends toward less abstraction. Tactical duplication is preferred over premature abstraction. When code has gotten too clever with too much edge case handling, push toward a simple abstract base with stateless methods where possible.

### 5. Delete dead code from evidence, not vibes

Removing code is one of the highest-leverage cleanups, but only when you've proven it's
dead. Trace actual consumers before deleting.

- Check the real consumer(s) — including other repos/services — for what they send and
  read. Delete a field/endpoint only when the evidence says nothing consumes it.
- When removing tests, distinguish "subject module is gone → delete the test" from
  "subject is live but imports a dead helper → trim the test". Never delete coverage of
  live behavior.
- Surface real bugs you find as issues (and a strict `xfail` with a pointer), rather than
  silently fixing unrelated things or papering over them.

## Anti-Patterns (what we explicitly REJECTED — and why)

| Anti-pattern | Why we rejected it |
|---|---|
| **Static type-checker CI gate (mypy/basedpyright ratchet)** | Allowlist maintenance, checker-only `cast()`s, config gymnastics, and CI flakes (e.g. `failOnWarnings` behaving differently local vs CI) — all for zero *runtime* guarantee. The IDE + Pydantic already give the signal that matters. Removing the gate lost no safety. |
| **Annotations that don't bite at runtime, treated as guarantees** | A type hint Python never enforces is documentation, not a contract. Keep them for legibility, but do not pretend they protect anything, and do not add ceremony around them. The best practice is to use type hints of models/classes validated at run time. |
| **Byte-identity migration that cleans plumbing but not the readable output** | Effort spent on the wrong layer. If the human still can't see the final artifact in one place, the legibility goal was not met. |
| **Discriminated-union / abstraction refactors with no concrete bug to prevent** | "What if we need to switch X later" complexity. Quote the real cost; prefer the cheapest representation until a concrete need appears. |
| **Over-applying production architecture to a prototype/dev path** | Dev/smoke/first-pass deliverables get the simplest implementation that works. Production rigor is opt-in per need, not default. |
| **Speculative type-safety busywork** | A sea of `NewType`/`Final`/nested generics that the reader has to wade through and that catch nothing. Annotate where it clarifies or validates; stop there. |

## Decision Guide

Before adding a rigor mechanism, ask in order:

1. **Does it produce a runtime guarantee?** (validation that actually fires on bad data)
   → If yes, strong candidate. Prefer Pydantic at the boundary.
2. **If not a runtime guarantee, does it make a human-read artifact dead-obvious?**
   (a golden, a rendered doc, a `Literal` that documents a closed set)
   → If yes, worth it — but label it honestly as legibility, not protection.
3. **If neither:** it is overengineering. Don't add it. If it already exists, removing it
   is a net win.

For "make it safe": reach for a boundary model + a golden/expect test, not a type-checker.
For "make it legible": build and pin the artifact a reviewer opens, not a tidier internal API.
For "clean it up": prove dead before deleting; preserve behavior with a golden first.

## Red Flags — STOP and reconsider

- "Let's add a type-checking gate to CI" → re-justify against the Decision Guide; default is no.
- Writing a `cast()` or `# type: ignore` purely to satisfy a checker → the checker is the problem.
- Adding annotations/abstractions and calling the code "safer" with no runtime check added.
- Refactoring assembly code in the name of "legibility" without producing a readable artifact.
- Deleting a field/endpoint/test without having checked its real consumers.
- Building production-grade machinery into a dev/prototype path "to be safe".

## Rationalizations

| Excuse | Reality |
|---|---|
| "Types make it safer" | Only if enforced at runtime. In Python that means Pydantic at boundaries, not annotations a checker reads. |
| "A type-check gate is just good hygiene" | It is carrying cost (allowlists, casts, CI flakes) for no runtime guarantee here. Use the IDE; gate on ruff + tests + goldens. |
| "The Jinja/abstraction cleanup makes it legible" | Legibility is the artifact a human opens. If you didn't build/pin that, you cleaned plumbing, not legibility. |
| "We might need this abstraction later" | Quote the real cost now; build it when the concrete need appears. |
| "It's obviously dead, delete it" | Prove it from consumers (including other repos). Obvious-looking code is often load-bearing. |
| "Add the production-grade version while we're here" | Prototype paths get the simplest thing that works; rigor is opt-in per need. |

## What "good" looks like

A reference for the bar: typed `Literal`s + Pydantic models. The best practice is to use type hints of models/classes that are also validated at run time.
This does two things:
1. Implements strong runtime guarantees that are aligned with the code's intent and fail loudly otherwise.
2. Makes the codebase far more readable and understandable by a human. Pydantic models / classes make it easy to reason about the core abstractions in the code.
   Type hints that use pydantic models make the inputs and outpus of functions easy to understand, where as using Any types and Dicts (especially nested dicts) as type hints
   achieves nothing, it remains extremely unclear to a human reading the code what the expected inputs and outputs of a function or component are in the codebase.

Enforcing these guarantees via runtime validation on classes is even more important at boundaries between components and boundaries between systems (APIs etc).