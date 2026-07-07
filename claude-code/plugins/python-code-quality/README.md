# python-code-quality

Python-specific code-quality principles: a verification-first, runtime-validated, legible-artifact philosophy, with anti-overengineering guardrails that keep it pragmatic.

```
/plugin install python-code-quality
```

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `python-code-quality` | Skill | Principles for writing, reviewing, refactoring, and hardening Python code |

## What the skill covers

- **Contract-driven design**: runtime validation at boundaries with Pydantic models; parse external/LLM JSON with `model_validate` rather than hand-rolled `.get()` chains; `Literal` aliases for closed vocabularies; fail loudly.
- **Golden/expect tests first**: capture a byte-exact or structured-exact snapshot before changing behavior you intend to preserve, so later changes are verified mechanically.
- **Legibility**: high-quality code is the readable artifact a human opens, not just cleaner internal plumbing.
- **Less is more**: one obvious path over parallel mechanisms; tactical duplication over premature abstraction.
- **Delete dead code from evidence**: trace real consumers before removing a field, endpoint, or test.
- **Anti-patterns and rationalizations**: why a static type-checker CI gate, annotations-as-guarantees, and speculative type-safety busywork are rejected when they buy no runtime guarantee and make nothing clearer.

The prime directive: every unit of rigor must buy a real runtime guarantee, make the code simpler and more readable to a human, or both — otherwise it is overengineering.
