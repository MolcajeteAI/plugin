---
name: testing-patterns
description: Unit testing patterns with Vitest. Use when writing tests for TypeScript code.
---

# Testing Patterns Skill

This skill covers unit testing patterns for TypeScript with Vitest.

## When to Use

Use this skill when:
- Writing unit tests
- Organizing test files
- Implementing test patterns
- Improving test quality

## Core Principle

**TEST BEHAVIOR, NOT IMPLEMENTATION** - Tests should verify what code does, not how it does it.

## Test Structure

### Arrange-Act-Assert (AAA)

```typescript
import { describe, it, expect } from 'vitest';

describe('calculateTotal', () => {
  it('should calculate total with tax', () => {
    // Arrange
    const items = [
      { price: 100, quantity: 2 },
      { price: 50, quantity: 1 },
    ];
    const taxRate = 0.1;

    // Act
    const result = calculateTotal(items, taxRate);

    // Assert
    expect(result).toBe(275); // (200 + 50) * 1.1
  });
});
```

### Given-When-Then (BDD Style)

```typescript
describe('User Authentication', () => {
  describe('given valid credentials', () => {
    describe('when user logs in', () => {
      it('then returns authentication token', async () => {
        const credentials = { email: 'user@example.com', password: 'valid' };
        const result = await login(credentials);
        expect(result.token).toBeDefined();
      });
    });
  });
});
```

## Test Organization

### File Structure

```
src/
├── utils/
│   ├── format.ts
│   └── __tests__/
│       └── format.test.ts
├── services/
│   ├── user.ts
│   └── __tests__/
│       └── user.test.ts
```

### Describe Block Organization

```typescript
describe('UserService', () => {
  // Setup shared across all tests
  let userService: UserService;

  beforeEach(() => {
    userService = new UserService();
  });

  describe('createUser', () => {
    it('should create user with valid data', () => { });
    it('should throw for invalid email', () => { });
    it('should hash password before storing', () => { });
  });

  describe('findUser', () => {
    it('should return user by id', () => { });
    it('should return null for non-existent user', () => { });
  });
});
```

## Assertion Patterns

### Basic Assertions

```typescript
// Equality
expect(value).toBe(expected);           // Strict equality (===)
expect(value).toEqual(expected);        // Deep equality
expect(value).toStrictEqual(expected);  // Deep equality + type

// Truthiness
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();

// Numbers
expect(value).toBeGreaterThan(3);
expect(value).toBeLessThan(10);
expect(value).toBeCloseTo(0.3, 5);     // Floating point

// Strings
expect(value).toMatch(/pattern/);
expect(value).toContain('substring');

// Arrays
expect(array).toContain(item);
expect(array).toHaveLength(3);

// Objects
expect(object).toHaveProperty('key');
expect(object).toHaveProperty('key', 'value');
expect(object).toMatchObject({ partial: true });
```

### Async Assertions

```typescript
// Resolves
await expect(promise).resolves.toBe('value');
await expect(promise).resolves.toEqual({ data: 'value' });

// Rejects
await expect(promise).rejects.toThrow('error message');
await expect(promise).rejects.toBeInstanceOf(Error);
```

### Error Assertions

```typescript
// Sync errors
expect(() => throwingFunction()).toThrow();
expect(() => throwingFunction()).toThrow('error message');
expect(() => throwingFunction()).toThrow(CustomError);

// Async errors
await expect(asyncThrowingFunction()).rejects.toThrow();
```

## Test Data Patterns

### Factories

```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

function createUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-123',
    name: 'Test User',
    email: 'test@example.com',
    ...overrides,
  };
}

// Usage
it('should update user name', () => {
  const user = createUser({ name: 'Original' });
  const updated = updateUser(user, { name: 'Updated' });
  expect(updated.name).toBe('Updated');
});
```

### Builders

```typescript
class UserBuilder {
  private user: User = {
    id: 'user-123',
    name: 'Test User',
    email: 'test@example.com',
  };

  withId(id: string): this {
    this.user.id = id;
    return this;
  }

  withName(name: string): this {
    this.user.name = name;
    return this;
  }

  build(): User {
    return { ...this.user };
  }
}

// Usage
const user = new UserBuilder()
  .withId('custom-id')
  .withName('Custom Name')
  .build();
```

## Setup and Teardown

```typescript
import { describe, it, beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

describe('Database tests', () => {
  // Run once before all tests
  beforeAll(async () => {
    await database.connect();
  });

  // Run once after all tests
  afterAll(async () => {
    await database.disconnect();
  });

  // Run before each test
  beforeEach(async () => {
    await database.clear();
  });

  // Run after each test
  afterEach(() => {
    vi.clearAllMocks();
  });
});
```

## Parameterized Tests

```typescript
import { describe, it, expect } from 'vitest';

describe('isValidEmail', () => {
  it.each([
    ['user@example.com', true],
    ['user@sub.example.com', true],
    ['invalid', false],
    ['@example.com', false],
    ['user@', false],
  ])('should return %s for "%s"', (email, expected) => {
    expect(isValidEmail(email)).toBe(expected);
  });
});

// With named parameters
describe('calculateDiscount', () => {
  it.each`
    price   | quantity | expected
    ${100}  | ${1}     | ${100}
    ${100}  | ${5}     | ${450}
    ${100}  | ${10}    | ${800}
  `('should calculate $expected for $quantity items at $price', ({ price, quantity, expected }) => {
    expect(calculateDiscount(price, quantity)).toBe(expected);
  });
});
```

## Async Testing

```typescript
// Using async/await
it('should fetch user data', async () => {
  const user = await fetchUser('123');
  expect(user.name).toBe('Test User');
});

// Using resolves
it('should resolve with user data', async () => {
  await expect(fetchUser('123')).resolves.toMatchObject({
    name: 'Test User',
  });
});

// Testing timeouts
it('should timeout after 5 seconds', async () => {
  await expect(slowOperation()).rejects.toThrow('timeout');
}, 10000); // Custom timeout
```

## Testing Exceptions

```typescript
describe('validateInput', () => {
  it('should throw ValidationError for empty input', () => {
    expect(() => validateInput('')).toThrow(ValidationError);
  });

  it('should throw with specific message', () => {
    expect(() => validateInput('')).toThrow('Input cannot be empty');
  });

  it('should throw with error properties', () => {
    try {
      validateInput('');
      expect.fail('Should have thrown');
    } catch (error) {
      expect(error).toBeInstanceOf(ValidationError);
      expect((error as ValidationError).code).toBe('EMPTY_INPUT');
    }
  });
});
```

## Test Isolation

```typescript
describe('isolated tests', () => {
  // Each test gets fresh instance
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
    vi.clearAllMocks();
  });

  it('test 1 - creates user', () => {
    service.create({ name: 'User 1' });
    expect(service.count()).toBe(1);
  });

  it('test 2 - also starts empty', () => {
    // This test starts with empty service
    expect(service.count()).toBe(0);
  });
});
```

## Best Practices Summary

1. **Use AAA pattern** - Arrange, Act, Assert
2. **One assertion per test** - Keep tests focused
3. **Descriptive names** - Tests are documentation
4. **Use factories** - Consistent test data
5. **Isolate tests** - No shared mutable state
6. **Test edge cases** - Empty, null, error paths
7. **Avoid implementation details** - Test behavior

## Code Review Checklist

- [ ] Tests follow AAA pattern
- [ ] Test names describe behavior
- [ ] Each test is independent
- [ ] Factories used for test data
- [ ] Edge cases covered
- [ ] Async tests properly awaited
- [ ] Errors properly asserted
