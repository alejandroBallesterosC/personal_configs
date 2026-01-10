---
name: claude-md-guide
description: Guide for writing and maintaining effective CLAUDE.md files. Activates when creating, editing, reviewing CLAUDE.md, or when Claude makes a repeatable error that should become a rule.
---

# CLAUDE.md Best Practices

Based on practices from Boris Cherny (Claude Code creator), Thariq Shihab (Anthropic), and official documentation.

## Why CLAUDE.md Matters

CLAUDE.md is **automatically re-injected after context compaction** - it's your primary mechanism for persistent project memory. Unlike conversation context, CLAUDE.md survives indefinitely.

## The Golden Rule

> "Whenever Claude makes an error, add a rule to prevent it next time." - Boris Cherny

CLAUDE.md should be a **living document** that improves through use. The Claude Code team contributes to their shared CLAUDE.md multiple times per week.

## Hard Limits

| Constraint | Limit | Why |
|------------|-------|-----|
| Total length | **Under 300 lines** | Stays in context, forces prioritization |
| Line length | Under 200 chars | Readability |
| Instructions | Must be actionable | Vague rules get ignored |

## Required Structure

```markdown
# [Project Name]

[2-3 sentence description of what this project does]

## Architecture
[Key layers, boundaries, data flow - be specific]

## Key Patterns
- [Pattern]: [When and how to use]
- [Pattern]: [When and how to use]

## Code Style
- [Specific convention]
- [Specific convention]

## Testing
- Framework: [name]
- Location: [path]
- Run: `[command]`

## Commands
- Build: `[command]`
- Lint: `[command]`
- Dev: `[command]`

## Key Files
- `[path]`: [purpose]

## Gotchas
- [Learned error pattern to avoid]
```

## What Makes Instructions Effective

### Good Instructions (Actionable)
```markdown
- Use `uv run pytest` not bare `pytest`
- All API endpoints must validate input with Pydantic
- Never commit .env files - use .env.example
- Run `npm run typecheck` before committing
```

### Bad Instructions (Vague)
```markdown
- Write clean code
- Follow best practices
- Be careful with security
- Make sure tests pass
```

## Using @imports for Progressive Disclosure

When you need detailed documentation, use imports instead of inline content:

```markdown
## Architecture
See @docs/architecture.md for detailed system design

## API Guidelines
See @docs/api-conventions.md for endpoint patterns

## Testing
See @docs/testing-guide.md for comprehensive examples
```

This keeps CLAUDE.md concise while preserving access to detailed docs.

## File Hierarchy

| Location | Scope | Use Case |
|----------|-------|----------|
| `~/.claude/CLAUDE.md` | All projects | Personal coding preferences |
| `./CLAUDE.md` | Project root | Team conventions (commit to git) |
| `./CLAUDE.local.md` | Project root | Personal overrides (gitignored) |
| `.claude/rules/*.md` | Path-specific | Context-aware rules with globs |

## When to Add Rules

**Add a rule when:**
- Claude makes the same mistake twice
- A pattern is non-obvious but important
- Team members ask "how do we do X?"
- Code review catches recurring issues

**Remove a rule when:**
- It's never triggered
- It conflicts with newer patterns
- The underlying issue was fixed differently

## Self-Improvement Prompt

When Claude makes an error that could recur, ask:

> "Should this be added to CLAUDE.md? If so, write a concise, actionable rule."

## Common Mistakes to Avoid

1. **Too long** - If over 300 lines, use @imports
2. **Too vague** - "Write good tests" → "Each function needs unit test with edge cases"
3. **Outdated** - Rules for deprecated patterns
4. **Duplicative** - Same rule stated multiple ways
5. **Tutorial content** - CLAUDE.md isn't for teaching the language

## Quality Checklist

Before committing CLAUDE.md changes:

- [ ] Under 300 lines?
- [ ] Every instruction is actionable?
- [ ] No vague/philosophical statements?
- [ ] Commands are copy-pasteable?
- [ ] @imports used for verbose content?
- [ ] Tested that rules prevent intended errors?

## Team Practices (Boris's Approach)

1. **Shared ownership**: Whole team contributes
2. **Code review**: CLAUDE.md changes get reviewed
3. **Error-driven**: Add rules from real mistakes
4. **Regular pruning**: Remove unused rules
5. **Git tracked**: Version controlled with project

## Example: Minimal but Effective

```markdown
# MyApp

E-commerce API serving mobile and web clients.

## Architecture
- `src/api/` - FastAPI routes
- `src/services/` - Business logic
- `src/models/` - SQLAlchemy models
- `src/schemas/` - Pydantic DTOs

## Patterns
- Services never import from api/ (dependency direction)
- All DB queries go through repositories
- Use `Result[T, Error]` for fallible operations

## Style
- snake_case for Python, camelCase for JSON responses
- Type hints required on all public functions
- Docstrings only for non-obvious behavior

## Testing
- Framework: pytest
- Run: `uv run pytest`
- Coverage: `uv run pytest --cov=src`

## Commands
- Dev: `uv run uvicorn src.main:app --reload`
- Migrate: `uv run alembic upgrade head`
- Lint: `uv run ruff check src/`

## Gotchas
- Always use `async with get_db()` not `get_db()`
- Price fields are integers (cents), not floats
- User.email is unique but NOT the primary key
```

This is 40 lines and contains everything Claude needs.
