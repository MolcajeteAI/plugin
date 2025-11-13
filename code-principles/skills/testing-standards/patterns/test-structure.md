# Test Structure Patterns

Well-structured tests are easier to read, understand, and maintain. This guide covers two popular test structure patterns: AAA (Arrange-Act-Assert) and Given-When-Then.

## AAA Pattern (Arrange-Act-Assert)

The AAA pattern divides tests into three clear sections:

### 1. Arrange
Set up the test data and preconditions.

### 2. Act
Execute the code being tested.

### 3. Assert
Verify the results match expectations.

### Example

```javascript
test('calculates order total with tax', () => {
  // Arrange
  const items = [
    { price: 10, quantity: 2 },
    { price: 5, quantity: 1 }
  ];
  const taxRate = 0.1;
  const calculator = new OrderCalculator(taxRate);

  // Act
  const total = calculator.calculateTotal(items);

  // Assert
  expect(total).toBe(27.5); // (10*2 + 5*1) * 1.1 = 27.5
});
```

### Benefits
- Clear structure
- Easy to read
- Easy to locate test failure
- Self-documenting

### Best Practices

**Use blank lines to separate sections:**
```javascript
test('creates user with valid data', () => {
  // Arrange
  const userData = { name: 'John', email: 'john@example.com' };

  // Act
  const user = createUser(userData);

  // Assert
  expect(user.id).toBeDefined();
  expect(user.name).toBe('John');
});
```

**Keep Arrange section focused:**
```javascript
// Bad - too much setup
test('updates user email', () => {
  const db = createDatabase();
  const emailService = new EmailService();
  const logger = new Logger();
  const cache = new Cache();
  const validator = new Validator();
  const userService = new UserService(db, emailService, logger, cache, validator);
  const user = userService.createUser({ name: 'John' });

  // ...
});

// Good - extract to helper
test('updates user email', () => {
  const userService = createUserService();
  const user = createTestUser({ name: 'John' });

  const updated = userService.updateEmail(user.id, 'new@example.com');

  expect(updated.email).toBe('new@example.com');
});
```

**Single Act per test:**
```javascript
// Bad - multiple actions
test('user lifecycle', () => {
  const user = createUser({ name: 'John' });
  const updated = updateUser(user.id, { name: 'Jane' });
  const deleted = deleteUser(user.id);

  expect(updated.name).toBe('Jane');
  expect(deleted).toBe(true);
});

// Good - separate tests
test('creates user', () => {
  const user = createUser({ name: 'John' });
  expect(user.name).toBe('John');
});

test('updates user name', () => {
  const user = createUser({ name: 'John' });

  const updated = updateUser(user.id, { name: 'Jane' });

  expect(updated.name).toBe('Jane');
});
```

## Given-When-Then Pattern

The Given-When-Then pattern is similar to AAA but uses BDD (Behavior-Driven Development) language.

### 1. Given (Context)
The initial state or preconditions.

### 2. When (Action)
The behavior being tested.

### 3. Then (Outcome)
The expected result.

### Example

```javascript
describe('Shopping Cart', () => {
  test('applies discount when cart total exceeds $100', () => {
    // Given a cart with items totaling $120
    const cart = new ShoppingCart();
    cart.addItem({ price: 100 });
    cart.addItem({ price: 20 });

    // When a 10% discount is applied
    cart.applyDiscount(0.10);

    // Then the total should be $108
    expect(cart.getTotal()).toBe(108);
  });
});
```

### Benefits
- Natural language flow
- Focus on behavior
- Good for BDD
- Stakeholder-friendly

### BDD Style with describe blocks

```javascript
describe('User Authentication', () => {
  describe('given a registered user', () => {
    describe('when they login with correct credentials', () => {
      test('then they receive an access token', () => {
        const user = registerUser({ email: 'test@example.com', password: 'Pass123' });

        const result = login('test@example.com', 'Pass123');

        expect(result.token).toBeDefined();
      });

      test('then they are redirected to dashboard', () => {
        const user = registerUser({ email: 'test@example.com', password: 'Pass123' });

        const result = login('test@example.com', 'Pass123');

        expect(result.redirectUrl).toBe('/dashboard');
      });
    });

    describe('when they login with incorrect password', () => {
      test('then they receive an error', () => {
        const user = registerUser({ email: 'test@example.com', password: 'Pass123' });

        const result = login('test@example.com', 'WrongPass');

        expect(result.error).toBe('Invalid credentials');
      });
    });
  });
});
```

## Test Naming Conventions

### Pattern 1: should + behavior

```javascript
test('should calculate tax on order total', () => {});
test('should throw error when email is invalid', () => {});
test('should send welcome email after registration', () => {});
```

### Pattern 2: Descriptive sentence

```javascript
test('calculates tax on order total', () => {});
test('throws error when email is invalid', () => {});
test('sends welcome email after registration', () => {});
```

### Pattern 3: Given-When-Then in name

```javascript
test('given valid user, when updating email, then email is updated', () => {});
test('given invalid email, when creating user, then throws error', () => {});
```

### Best Naming Practices

**Be specific:**
```javascript
// Bad
test('test user', () => {});
test('it works', () => {});

// Good
test('creates user with valid email', () => {});
test('sends welcome email after user registration', () => {});
```

**Include context:**
```javascript
// Bad
test('returns error', () => {});

// Good
test('returns validation error when email format is invalid', () => {});
```

**Describe the expected behavior:**
```javascript
// Bad
test('discount function', () => {});

// Good
test('applies 10% discount when cart total exceeds $100', () => {});
```

## Test Organization

### Organize by feature/module

```javascript
describe('UserService', () => {
  describe('createUser', () => {
    test('creates user with valid data', () => {});
    test('throws error when email is duplicate', () => {});
    test('sends welcome email', () => {});
  });

  describe('updateUser', () => {
    test('updates user email', () => {});
    test('throws error when user not found', () => {});
  });

  describe('deleteUser', () => {
    test('deletes user from database', () => {});
    test('throws error when user has active orders', () => {});
  });
});
```

### Setup and Teardown

```javascript
describe('Database Operations', () => {
  let database;

  // Runs once before all tests
  beforeAll(async () => {
    database = await createTestDatabase();
  });

  // Runs before each test
  beforeEach(async () => {
    await database.clear();
  });

  // Runs after each test
  afterEach(async () => {
    // Cleanup if needed
  });

  // Runs once after all tests
  afterAll(async () => {
    await database.close();
  });

  test('saves record', async () => {
    await database.save({ name: 'Test' });
    const record = await database.find({ name: 'Test' });
    expect(record).toBeDefined();
  });
});
```

## Common Patterns

### Test Data Builders

```javascript
class UserBuilder {
  constructor() {
    this.user = {
      name: 'Test User',
      email: 'test@example.com',
      age: 25,
      isActive: true
    };
  }

  withName(name) {
    this.user.name = name;
    return this;
  }

  withEmail(email) {
    this.user.email = email;
    return this;
  }

  inactive() {
    this.user.isActive = false;
    return this;
  }

  build() {
    return this.user;
  }
}

// Usage
test('creates user with custom email', () => {
  const userData = new UserBuilder()
    .withEmail('custom@example.com')
    .build();

  const user = createUser(userData);
  expect(user.email).toBe('custom@example.com');
});
```

### Object Mothers (Factory Functions)

```javascript
function createTestUser(overrides = {}) {
  return {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    isActive: true,
    ...overrides
  };
}

// Usage
test('updates inactive user status', () => {
  const user = createTestUser({ isActive: false });

  const updated = activateUser(user.id);

  expect(updated.isActive).toBe(true);
});
```

### Assertion Messages

```javascript
// Add custom messages for better failure output
test('calculates correct total', () => {
  const total = calculateTotal([10, 20, 30]);

  expect(total).toBe(60, 'Total should be sum of all items');
});
```

## Anti-Patterns

### 1. Multiple unrelated assertions
```javascript
// Bad
test('user functionality', () => {
  expect(createUser()).toBeDefined();
  expect(updateUser(1, {})).toBeTruthy();
  expect(deleteUser(1)).toBe(true);
});

// Good - separate tests
test('creates user', () => {
  expect(createUser()).toBeDefined();
});

test('updates user', () => {
  expect(updateUser(1, {})).toBeTruthy();
});
```

### 2. Logic in tests
```javascript
// Bad
test('calculates totals', () => {
  for (let i = 0; i < 10; i++) {
    expect(calculate(i)).toBe(i * 2);
  }
});

// Good
test('doubles the input', () => {
  expect(calculate(5)).toBe(10);
});

test('doubles zero', () => {
  expect(calculate(0)).toBe(0);
});
```

### 3. Testing implementation details
```javascript
// Bad
test('uses caching', () => {
  const spy = jest.spyOn(cache, 'get');
  service.getUser(1);
  expect(spy).toHaveBeenCalled();
});

// Good
test('returns user quickly on second call', async () => {
  await service.getUser(1); // Prime cache

  const start = Date.now();
  await service.getUser(1);
  const duration = Date.now() - start;

  expect(duration).toBeLessThan(10);
});
```

## Summary

Use AAA (Arrange-Act-Assert) or Given-When-Then to structure tests clearly. Write descriptive test names that explain what is being tested and the expected outcome. Organize tests logically with describe blocks. Use setup/teardown hooks appropriately. Extract test data creation to builders or factory functions. Keep tests simple - no logic in tests. One logical assertion per test.
