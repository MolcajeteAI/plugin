---
name: testing-standards
description: Standards and best practices for writing effective tests including the testing pyramid, test structure patterns, and coverage guidelines
---

# Testing Standards

This skill provides comprehensive guidance on testing strategies, patterns, and coverage standards to ensure code quality and reliability.

## Core Philosophy

**Tests are first-class citizens in the codebase.**

- Write tests alongside production code, not after
- Tests document how code should be used
- Tests enable confident refactoring
- Good tests catch bugs early and reduce debugging time

## When to Use This Skill

Use this skill when:
- Writing any new code (tests first or alongside)
- Reviewing code for test quality
- Establishing testing practices for a team
- Deciding what type of test to write
- Setting coverage goals and standards
- Debugging test failures

## Key Concepts

### 1. Testing Pyramid

The testing pyramid guides the distribution of different test types.

See [Testing Pyramid Pattern](./patterns/testing-pyramid.md) for details.

**Quick Summary:**
- **Many** unit tests (fast, isolated, focused)
- **Some** integration tests (test component interactions)
- **Few** end-to-end tests (test complete workflows)

### 2. Test Structure

Consistent test structure makes tests easier to read and maintain.

See [Test Structure Pattern](./patterns/test-structure.md) for details.

**Common Patterns:**
- **AAA**: Arrange, Act, Assert
- **Given-When-Then**: BDD-style test structure

### 3. Coverage Guidelines

Coverage targets vary by code criticality.

See [Coverage Guidelines](./patterns/coverage-guidelines.md) for details.

**General Targets:**
- Business logic: 80-100% coverage
- Integration points: 70-90% coverage
- UI code: 40-60% coverage

## Testing Principles

### 1. Fast Tests

**Tests should run quickly**
- Unit tests: < 100ms each
- Integration tests: < 1 second each
- E2E tests: < 10 seconds each
- Full suite should run in minutes, not hours

### 2. Independent Tests

**Tests should not depend on each other**
- Each test sets up its own data
- Tests can run in any order
- One test failure doesn't cascade

### 3. Repeatable Tests

**Tests should produce same results every time**
- No randomness (or use fixed seeds)
- No dependency on external state
- No reliance on system time (mock it)

### 4. Self-Validating Tests

**Tests should have clear pass/fail**
- Use assertions, not manual verification
- Clear error messages
- One logical assertion per test

### 5. Timely Tests

**Tests should be written at the right time**
- TDD: Write tests first
- Test-alongside: Write with production code
- Never: Write tests months later

## Test Types

### Unit Tests
- Test single functions/methods in isolation
- Fast and focused
- Mock external dependencies
- Most numerous in test suite

### Integration Tests
- Test interaction between components
- Use real dependencies where reasonable
- Test API contracts
- Moderate speed

### End-to-End Tests
- Test complete user workflows
- Use real systems
- Test critical paths
- Slowest, least numerous

### Contract Tests
- Test API contracts between services
- Ensure backwards compatibility
- Run on both sides of integration

## Best Practices

### 1. Test Behavior, Not Implementation

**Bad:**
```javascript
test('uses correct algorithm', () => {
  const spy = jest.spyOn(calculator, 'quickSort');
  calculator.sortNumbers([3, 1, 2]);
  expect(spy).toHaveBeenCalled();
});
```

**Good:**
```javascript
test('sorts numbers in ascending order', () => {
  const result = calculator.sortNumbers([3, 1, 2]);
  expect(result).toEqual([1, 2, 3]);
});
```

### 2. One Logical Assertion Per Test

**Bad:**
```javascript
test('user creation', () => {
  const user = createUser({ name: 'John', age: 30 });
  expect(user.name).toBe('John');
  expect(user.age).toBe(30);
  expect(user.isActive).toBe(true);
  expect(user.createdAt).toBeDefined();
});
```

**Good:**
```javascript
test('creates user with provided name', () => {
  const user = createUser({ name: 'John' });
  expect(user.name).toBe('John');
});

test('creates user with provided age', () => {
  const user = createUser({ age: 30 });
  expect(user.age).toBe(30);
});

test('sets new user as active by default', () => {
  const user = createUser({});
  expect(user.isActive).toBe(true);
});
```

### 3. Descriptive Test Names

Test names should describe what is being tested and the expected outcome.

**Bad:**
```javascript
test('test1', () => { /* ... */ });
test('user test', () => { /* ... */ });
test('works', () => { /* ... */ });
```

**Good:**
```javascript
test('creates user with valid email', () => { /* ... */ });
test('throws error when email is invalid', () => { /* ... */ });
test('sends welcome email after user creation', () => { /* ... */ });
```

### 4. Test Edge Cases and Errors

Don't only test the happy path.

```javascript
describe('divide', () => {
  test('divides positive numbers', () => {
    expect(divide(10, 2)).toBe(5);
  });

  test('divides negative numbers', () => {
    expect(divide(-10, 2)).toBe(-5);
  });

  test('throws error when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero');
  });

  test('handles decimal results', () => {
    expect(divide(10, 3)).toBeCloseTo(3.333, 2);
  });
});
```

### 5. Use Test Doubles Appropriately

- **Stubs**: Provide fixed responses
- **Mocks**: Verify interactions
- **Spies**: Observe without changing behavior
- **Fakes**: Working implementations for testing

Use the simplest test double that works.

## Common Anti-Patterns

### 1. Testing Implementation Details
Don't test private methods or internal state directly.

### 2. Fragile Tests
Tests that break when refactoring working code.

### 3. Slow Tests
Tests that take too long reduce their value.

### 4. Flaky Tests
Tests that randomly fail reduce trust in test suite.

### 5. Test Interdependence
Tests that rely on execution order or shared state.

## Integration with Feature Slicing

When using feature slicing:
- Keep tests within feature directory
- Test features in isolation
- Mock interactions with other features
- Write integration tests for feature APIs

```
/features
  /user-management
    service.js
    /tests
      service.test.js
      integration.test.js
      e2e.test.js
```

## Testing Workflow

1. **Write Test First** (TDD) or alongside code
2. **Watch It Fail** - Ensure test catches the issue
3. **Write Minimal Code** - Make test pass
4. **Refactor** - Improve code while tests pass
5. **Repeat** - For next piece of functionality

## Resources

- [Testing Pyramid](./patterns/testing-pyramid.md) - Test distribution strategy
- [Test Structure](./patterns/test-structure.md) - AAA and Given-When-Then patterns
- [Coverage Guidelines](./patterns/coverage-guidelines.md) - Coverage targets by code type

## Summary

Good tests are fast, independent, repeatable, self-validating, and timely. Follow the testing pyramid to balance different test types. Write tests that verify behavior, not implementation. Use clear structure and descriptive names. Test edge cases and errors, not just happy paths. Keep tests close to the code they test, especially in feature-sliced architectures.
