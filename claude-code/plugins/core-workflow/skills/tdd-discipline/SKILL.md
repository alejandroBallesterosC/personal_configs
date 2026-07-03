---
name: tdd-discipline
description: TDD guidance for the RED/GREEN/REFACTOR cycle. Use when writing tests, implementing test-driven, or refactoring under test coverage.
---

# TDD Discipline Skill

Guidance for Test-Driven Development practices.

## When to Activate

Activate when:
- Engaging in a TDD workflow
- Writing tests before implementation
- Implementing code to pass tests
- Refactoring code with tests

**Announce at start:** "I'm using the tdd-discipline skill."

## Core Principles

### Test With Real Services and Real APIs

Always strongly prefer using real data and real APIs for testing. Only resort to implementing a mock mode for tests when you absolutely positively have to.
If you are integrating with other internal components or services that are being developed in parallel (in the same code base) and are thus not currently available you can implement a mock for testing (only if this component is truly not available yet).
In the rare case an external API is not working after many many attempts you can implement a mock in tests to unblock yourself (this should be a last resort and exceedingly rare).
ALWAYS proactively inform the user when you have tested with a mock rather than with a real API.

### Do Not Hard Code or Hack Your Way Around Tests

Do not just hard code an implementation or hack your way into passing tests. Actually stick to the goal of the project and implementation faithfully. Your implementations and tests should be honest, faithful, and genuine, not a hack to get around tests.

### The TDD Cycle

```
RED → GREEN → REFACTOR → (repeat)
```

1. **RED**: Write a failing test
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve without changing behavior

### RED Phase Rules

- Write ONE test at a time
- Test should fail for the right reason
- Test name describes expected behavior
- Test should be simple and focused

```python
# Good: Focused, descriptive
def test_user_creation_assigns_unique_id():
    user = create_user(name="Alice")
    assert user.id is not None
    assert isinstance(user.id, str)

# Bad: Testing multiple things
def test_user():
    user = create_user(name="Alice")
    assert user.id is not None
    assert user.name == "Alice"
    assert user.email is None
    assert user.is_active == True
```

### GREEN Phase Rules

- Write MINIMAL code to pass
- Don't optimize
- Don't add features
- Don't worry about code quality yet

```python
# Test expects:
def test_add_returns_sum():
    assert add(2, 3) == 5

# Minimal implementation (good):
def add(a, b):
    return a + b

# Over-engineered (bad):
def add(*args, **kwargs):
    """Add any number of values with optional precision."""
    precision = kwargs.get('precision', None)
    result = sum(args)
    return round(result, precision) if precision else result
```

### REFACTOR Phase Rules

- Tests must stay green
- Make ONE change at a time
- Run tests after each change
- Undo if tests fail

Common refactorings:
- Extract function
- Rename for clarity
- Remove duplication
- Simplify conditionals

## Test Writing Guidelines

### Arrange-Act-Assert Pattern

```python
def test_order_total_includes_shipping():
    # Arrange
    order = Order(items=[Item(price=100)])
    shipping = ShippingRate(cost=10)

    # Act
    total = order.calculate_total(shipping)

    # Assert
    assert total == 110
```

### Test Boundaries

Always test:
- Zero items
- One item
- Many items
- Maximum/minimum values
- Invalid inputs
- Empty strings/null values

```python
def test_list_handling():
    # Zero
    assert process([]) == []

    # One
    assert process([1]) == [1]

    # Many
    assert process([1, 2, 3]) == [1, 2, 3]
```

### Test Independence

Each test should:
- Run in isolation
- Not depend on other tests
- Not depend on execution order
- Clean up after itself

## Common TDD Mistakes

### 1. Writing Too Many Tests at Once
Bad: Write 10 tests, then implement
Good: Write 1 test, implement, repeat

### 2. Writing Too Much Code
Bad: Implement full feature to pass one test
Good: Write minimum code for this test only

### 3. Skipping the Red Phase
Bad: Write implementation, then tests
Good: Always see the test fail first

### 4. Refactoring While Red
Bad: Clean up code when tests are failing
Good: Only refactor when GREEN

### 5. Testing Implementation Details
Bad: Test private methods
Good: Test public behavior

## Running Tests

Run the project's test command after implementing (GREEN) and after every refactor (REFACTOR) — don't rely on a hook to force this, just do it as a normal part of the cycle. Look for the test command in the project's README, package.json scripts, or CI config if it's not obvious.

For visual/frontend verification, see the `playwright` plugin's skill.

## Quick Reference

| Phase | Do | Don't |
|-------|-----|-------|
| RED | Write one failing test | Write implementation |
| GREEN | Minimal code to pass | Optimize or add features |
| REFACTOR | Improve code quality | Change behavior |
