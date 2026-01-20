---
name: tdd-guide
description: Provides TDD guidance when writing tests or implementation code. Use when the user is doing test-driven development, writing tests, or implementing features.
---

# TDD Guide Skill

This skill provides guidance for Test-Driven Development practices.

## When to Activate

Activate when:
- Engaging in a TDD workflow
- Writing tests before implementation
- Implementing code to pass tests
- Refactoring code with tests
- Asking about TDD practices
  
**Announce at start:** "I'm using the tdd-guide skill."

## TDD Core Principles

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
❌ Write 10 tests, then implement
✅ Write 1 test, implement, repeat

### 2. Writing Too Much Code
❌ Implement full feature to pass one test
✅ Write minimum code for this test only

### 3. Skipping the Red Phase
❌ Write implementation, then tests
✅ Always see the test fail first

### 4. Refactoring While Red
❌ Clean up code when tests are failing
✅ Only refactor when GREEN

### 5. Testing Implementation Details
❌ Test private methods
✅ Test public behavior

## TDD Benefits Reminder

- **Design feedback**: Hard to test = bad design
- **Documentation**: Tests show how code works
- **Confidence**: Refactor without fear
- **Focus**: One thing at a time
- **Quality**: Fewer bugs, cleaner code

## Quick Reference

| Phase | Do | Don't |
|-------|-----|-------|
| RED | Write one failing test | Write implementation |
| GREEN | Minimal code to pass | Optimize or add features |
| REFACTOR | Improve code quality | Change behavior |
