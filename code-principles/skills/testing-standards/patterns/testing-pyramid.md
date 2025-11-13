# Testing Pyramid

The testing pyramid is a framework that helps balance different types of tests in your test suite. It guides you on how many tests of each type to write and why.

## The Pyramid Structure

```
        /\
       /  \
      / E2E\    ← Few (5-10%)
     /______\
    /        \
   /Integration\ ← Some (20-30%)
  /____________\
 /              \
/   Unit Tests   \ ← Many (60-70%)
/________________\
```

## Test Levels

### Level 1: Unit Tests (Base - 60-70%)

**What they test:**
- Individual functions or methods
- Single classes or modules
- Isolated business logic

**Characteristics:**
- Very fast (< 100ms each)
- No external dependencies (use mocks/stubs)
- Test one thing at a time
- Easy to write and maintain
- Provide precise failure feedback

**Example:**
```javascript
// Unit test for a calculator function
describe('Calculator', () => {
  describe('add', () => {
    test('adds two positive numbers', () => {
      expect(add(2, 3)).toBe(5);
    });

    test('adds negative numbers', () => {
      expect(add(-2, -3)).toBe(-5);
    });

    test('adds positive and negative numbers', () => {
      expect(add(5, -3)).toBe(2);
    });
  });
});
```

**When to write:**
- For all business logic
- For utility functions
- For data transformations
- For validation logic

**Benefits:**
- Fastest feedback loop
- Easiest to debug
- Cheapest to maintain
- Can run thousands in seconds

### Level 2: Integration Tests (Middle - 20-30%)

**What they test:**
- Interaction between components
- Database queries
- API endpoints
- External service integrations

**Characteristics:**
- Moderate speed (< 1 second each)
- Use real dependencies where reasonable
- Test component boundaries
- Verify contracts between modules

**Example:**
```javascript
// Integration test for user service with database
describe('UserService Integration', () => {
  let database;
  let userService;

  beforeAll(async () => {
    database = await createTestDatabase();
    userService = new UserService(database);
  });

  afterAll(async () => {
    await database.close();
  });

  test('saves user to database and retrieves it', async () => {
    const userData = { name: 'John', email: 'john@example.com' };

    // Save user
    const savedUser = await userService.createUser(userData);
    expect(savedUser.id).toBeDefined();

    // Retrieve user
    const retrieved = await userService.getUser(savedUser.id);
    expect(retrieved.name).toBe('John');
    expect(retrieved.email).toBe('john@example.com');
  });
});
```

**When to write:**
- For database interactions
- For API endpoints
- For third-party integrations
- For complex component interactions

**Benefits:**
- Catch integration issues
- Test real behavior
- Verify contracts
- More realistic than unit tests

### Level 3: End-to-End Tests (Top - 5-10%)

**What they test:**
- Complete user workflows
- Full application stack
- Critical business processes

**Characteristics:**
- Slow (seconds to minutes)
- Use real systems
- Test from user perspective
- Fragile and expensive to maintain

**Example:**
```javascript
// E2E test for user registration flow
describe('User Registration E2E', () => {
  test('user can register and login', async () => {
    // Navigate to registration page
    await page.goto('http://localhost:3000/register');

    // Fill registration form
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'SecurePass123');
    await page.fill('[name="confirmPassword"]', 'SecurePass123');

    // Submit form
    await page.click('button[type="submit"]');

    // Verify redirect to dashboard
    await page.waitForURL('**/dashboard');
    expect(await page.textContent('h1')).toBe('Welcome');

    // Logout
    await page.click('button#logout');

    // Login again
    await page.goto('http://localhost:3000/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'SecurePass123');
    await page.click('button[type="submit"]');

    // Verify successful login
    await page.waitForURL('**/dashboard');
  });
});
```

**When to write:**
- For critical user journeys
- For payment flows
- For registration/login
- For core business workflows

**Benefits:**
- Highest confidence
- Test real user experience
- Catch system-level issues
- Verify everything works together

## Distribution Guidelines

### Recommended Ratios

**For a typical application:**
- Unit Tests: 60-70% (hundreds to thousands)
- Integration Tests: 20-30% (dozens to hundreds)
- E2E Tests: 5-10% (a handful to dozens)

**For a backend API:**
- Unit Tests: 70% (business logic)
- Integration Tests: 25% (API endpoints, database)
- E2E Tests: 5% (critical workflows)

**For a frontend application:**
- Unit Tests: 50-60% (components, utilities)
- Integration Tests: 30-40% (component interactions, API calls)
- E2E Tests: 5-10% (user workflows)

## Why This Distribution?

### 1. Speed
```
Unit:        ██ (milliseconds)
Integration: ████████ (hundreds of milliseconds)
E2E:         ████████████████████ (seconds)
```

More unit tests = faster feedback.

### 2. Cost
```
Unit:        $ (cheap to write and maintain)
Integration: $$ (moderate cost)
E2E:         $$$ (expensive and fragile)
```

More unit tests = lower maintenance cost.

### 3. Debugging
```
Unit:        ✓ Easy (precise failure location)
Integration: ○ Moderate (narrowed to components)
E2E:         ✗ Hard (anywhere in the flow)
```

More unit tests = easier debugging.

### 4. Confidence
```
Unit:        ~ Low (isolated test)
Integration: ~~ Medium (some integration)
E2E:         ~~~ High (complete system)
```

Pyramid balances confidence with speed and cost.

## Anti-Pattern: Ice Cream Cone

**Bad: Inverted pyramid**
```
        /\
       /  \
      /Unit\    ← Few unit tests
     /______\
    /        \
   /Integration\
  /____________\
 /              \
/      E2E       \ ← Too many E2E tests
/________________\
```

**Problems:**
- Slow test suite (hours to run)
- Expensive to maintain
- Hard to debug failures
- Low developer productivity
- Flaky tests

## Practical Examples

### Example 1: E-commerce Checkout

**Unit Tests (70%):**
```javascript
// Cart calculations
test('calculates subtotal correctly')
test('applies discount code')
test('calculates tax')
test('calculates shipping cost')

// Validation
test('validates credit card number')
test('validates shipping address')
test('validates email format')

// Business logic
test('checks product availability')
test('applies loyalty points')
```

**Integration Tests (25%):**
```javascript
// API endpoints
test('POST /api/cart/add adds item to cart')
test('POST /api/checkout processes payment')
test('GET /api/orders/:id retrieves order')

// Database
test('saves order to database')
test('updates inventory after purchase')
```

**E2E Tests (5%):**
```javascript
// Critical flow
test('complete checkout flow from cart to confirmation')
test('guest checkout flow')
```

### Example 2: User Authentication System

**Unit Tests (60%):**
```javascript
// Password hashing
test('hashes password correctly')
test('verifies password against hash')

// Token generation
test('generates valid JWT token')
test('validates JWT token')
test('expires old tokens')

// Validation
test('validates email format')
test('validates password strength')
```

**Integration Tests (30%):**
```javascript
// API endpoints
test('POST /api/auth/register creates user')
test('POST /api/auth/login returns token')
test('POST /api/auth/logout invalidates token')

// Database
test('stores user in database')
test('retrieves user by email')
```

**E2E Tests (10%):**
```javascript
// User flows
test('user registration and login flow')
test('password reset flow')
test('session management across pages')
```

## Testing Strategy by Code Type

### Pure Functions (100% Unit)
```javascript
// Pure calculation - only unit tests needed
function calculateDiscount(price, percentage) {
  return price * (percentage / 100);
}

test('calculates 10% discount correctly', () => {
  expect(calculateDiscount(100, 10)).toBe(10);
});
```

### Services with Dependencies (70% Unit, 30% Integration)
```javascript
// Service with database dependency
class UserService {
  async getUser(id) {
    return await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }
}

// Unit test with mock
test('queries database with correct ID', async () => {
  const mockDb = { query: jest.fn().mockResolvedValue({ id: 1 }) };
  const service = new UserService(mockDb);
  await service.getUser(1);
  expect(mockDb.query).toHaveBeenCalledWith(
    'SELECT * FROM users WHERE id = ?',
    [1]
  );
});

// Integration test with real database
test('retrieves actual user from database', async () => {
  const service = new UserService(realDb);
  const user = await service.getUser(1);
  expect(user.email).toBe('test@example.com');
});
```

### API Endpoints (30% Unit, 60% Integration, 10% E2E)
```javascript
// Most API tests should be integration tests
test('GET /api/users/:id returns user', async () => {
  const response = await request(app).get('/api/users/1');
  expect(response.status).toBe(200);
  expect(response.body.email).toBe('test@example.com');
});
```

## Benefits of Following the Pyramid

1. **Fast Feedback** - Most tests run in seconds
2. **Easy Debugging** - Failures pinpoint exact problem
3. **Low Maintenance** - Unit tests rarely break on refactors
4. **High Confidence** - E2E tests cover critical paths
5. **Good ROI** - Balance between coverage and cost

## Summary

Follow the testing pyramid to create a balanced, maintainable test suite. Write many fast unit tests for business logic, some integration tests for component interactions, and few E2E tests for critical workflows. This distribution provides fast feedback, easy debugging, and high confidence at a reasonable cost.
