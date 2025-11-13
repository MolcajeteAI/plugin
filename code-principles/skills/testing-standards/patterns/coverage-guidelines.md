# Coverage Guidelines

Code coverage measures which parts of your code are executed during tests. While 100% coverage doesn't guarantee bug-free code, it helps identify untested areas.

## Coverage Metrics

### Line Coverage
Percentage of code lines executed during tests.

### Branch Coverage
Percentage of decision branches (if/else, switch) executed.

### Function Coverage
Percentage of functions called during tests.

### Statement Coverage
Percentage of statements executed.

## Coverage Targets by Code Type

### Business Logic: 80-100%

**What:**
- Core algorithms
- Business rules
- Data transformations
- Calculations

**Why high coverage:**
- Critical to application
- Complex logic prone to bugs
- High ROI on tests

**Example:**
```javascript
// Order pricing - should have 90%+ coverage
class OrderPricing {
  calculateTotal(items, discountCode, loyaltyPoints) {
    let subtotal = this.calculateSubtotal(items);
    subtotal = this.applyDiscount(subtotal, discountCode);
    subtotal = this.applyLoyaltyPoints(subtotal, loyaltyPoints);
    const tax = this.calculateTax(subtotal);
    const shipping = this.calculateShipping(items);
    return subtotal + tax + shipping;
  }
}
```

### Data Access Layer: 70-90%

**What:**
- Database queries
- Repository methods
- Data mappers

**Why moderate coverage:**
- Integration tests better than unit tests
- Some code is simple CRUD
- Database-specific logic needs testing

**Example:**
```javascript
// Repository - 70-80% coverage acceptable
class UserRepository {
  async findById(id) {
    return await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async findByEmail(email) {
    return await this.db.query('SELECT * FROM users WHERE email = ?', [email]);
  }

  // Complex query should be tested
  async findActiveUsersWithOrders() {
    return await this.db.query(`
      SELECT u.* FROM users u
      INNER JOIN orders o ON u.id = o.user_id
      WHERE u.is_active = true
      GROUP BY u.id
      HAVING COUNT(o.id) > 0
    `);
  }
}
```

### API Controllers/Routes: 60-80%

**What:**
- HTTP endpoints
- Request handlers
- Response formatting

**Why moderate coverage:**
- Integration tests more valuable
- Simple pass-through code
- Focus on integration over unit

**Example:**
```javascript
// Controller - 60-70% coverage fine
class UserController {
  async getUser(req, res) {
    const user = await this.userService.getUser(req.params.id);
    res.json(user);
  }

  async createUser(req, res) {
    const user = await this.userService.createUser(req.body);
    res.status(201).json(user);
  }
}
```

### UI Components: 40-70%

**What:**
- React/Vue/Angular components
- Templates
- UI logic

**Why lower coverage:**
- Visual testing important
- Fast-changing code
- User testing more valuable

**Example:**
```javascript
// Component - 40-60% coverage acceptable
function UserProfile({ user }) {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
      {user.isAdmin && <AdminBadge />}
    </div>
  );
}
```

### Utility Functions: 90-100%

**What:**
- Pure functions
- Helpers
- Formatters
- Validators

**Why high coverage:**
- Easy to test
- Reused everywhere
- High impact if broken

**Example:**
```javascript
// Utilities - should have 95%+ coverage
function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency
  }).format(amount);
}

function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

### Configuration: 20-40%

**What:**
- Config files
- Environment setup
- Constants

**Why low coverage:**
- Simple assignments
- No logic to test
- Better tested through integration

## Target Guidelines Summary

| Code Type | Target Coverage | Priority |
|-----------|----------------|----------|
| Business Logic | 80-100% | HIGH |
| Utilities | 90-100% | HIGH |
| Data Access | 70-90% | MEDIUM |
| API Controllers | 60-80% | MEDIUM |
| UI Components | 40-70% | MEDIUM |
| Configuration | 20-40% | LOW |

## What NOT to Test

### 1. Third-Party Libraries

```javascript
// Don't test that lodash works
test('lodash groupBy works', () => {
  const result = _.groupBy([1, 2, 3], n => n % 2);
  expect(result).toEqual({ 0: [2], 1: [1, 3] });
});
```

### 2. Framework Code

```javascript
// Don't test that Express routing works
test('Express handles GET requests', () => {
  const app = express();
  app.get('/test', (req, res) => res.send('ok'));
  // Testing Express, not your code
});
```

### 3. Simple Getters/Setters

```javascript
// Don't test trivial code
class User {
  getName() {
    return this.name;
  }

  setName(name) {
    this.name = name;
  }
}

// No need for:
test('getName returns name', () => {
  const user = new User();
  user.name = 'John';
  expect(user.getName()).toBe('John');
});
```

### 4. Constants and Configuration

```javascript
// Don't test constants
const API_ENDPOINT = 'https://api.example.com';

// No need for:
test('API_ENDPOINT is correct', () => {
  expect(API_ENDPOINT).toBe('https://api.example.com');
});
```

## Coverage Analysis Tools

### JavaScript/TypeScript
- Jest (built-in coverage)
- Istanbul/nyc
- Codecov
- Coveralls

### Running Coverage

```bash
# Jest
npm test -- --coverage

# nyc with Mocha
nyc mocha

# View HTML report
open coverage/lcov-report/index.html
```

### Coverage Reports

```
-------------------------|----------|----------|----------|----------|
File                     |  % Stmts | % Branch |  % Funcs |  % Lines |
-------------------------|----------|----------|----------|----------|
All files                |    85.23 |    78.45 |    88.12 |    85.67 |
 src/                    |    87.34 |    81.23 |    90.45 |    87.89 |
  calculator.js          |      100 |      100 |      100 |      100 |
  validator.js           |    95.45 |    88.23 |      100 |    95.45 |
 src/services/           |    82.12 |    75.34 |    85.23 |    82.45 |
  userService.js         |    78.23 |    70.12 |    80.34 |    78.67 |
  orderService.js        |    85.67 |    80.23 |    90.12 |    86.23 |
-------------------------|----------|----------|----------|----------|
```

## Interpreting Coverage

### Good Coverage (>80%)
```javascript
// All paths tested
function getDiscount(orderTotal, isVIP) {
  if (orderTotal > 100) {
    return isVIP ? 0.20 : 0.10;
  }
  return 0;
}

test('regular customer with large order gets 10% discount', () => {
  expect(getDiscount(150, false)).toBe(0.10);
});

test('VIP customer with large order gets 20% discount', () => {
  expect(getDiscount(150, true)).toBe(0.20);
});

test('small order gets no discount', () => {
  expect(getDiscount(50, false)).toBe(0);
});
```

### Poor Coverage (<50%)
```javascript
// Missing edge cases
function processOrder(order) {
  if (!order) return null;
  if (!order.items || order.items.length === 0) return null;
  if (order.total < 0) throw new Error('Invalid total');

  const processed = calculateTotal(order.items);
  if (processed > 1000) {
    sendNotification(order.userId);
  }
  return processed;
}

// Only one test
test('processes valid order', () => {
  const order = { items: [{price: 10}], total: 10 };
  expect(processOrder(order)).toBe(10);
});
// Missing: null order, empty items, negative total, large orders
```

## Branch Coverage

Branch coverage is often more important than line coverage.

```javascript
// 100% line coverage, 50% branch coverage
function isEligible(user) {
  return user.age >= 18 && user.country === 'US';
}

test('18-year-old US user is eligible', () => {
  expect(isEligible({ age: 18, country: 'US' })).toBe(true);
});
// Missing: age < 18, non-US country, combination of both
```

**Better:**
```javascript
test('user over 18 in US is eligible', () => {
  expect(isEligible({ age: 18, country: 'US' })).toBe(true);
});

test('user under 18 is not eligible', () => {
  expect(isEligible({ age: 17, country: 'US' })).toBe(false);
});

test('non-US user is not eligible', () => {
  expect(isEligible({ age: 18, country: 'UK' })).toBe(false);
});
```

## Coverage vs Quality

### High Coverage ≠ Good Tests

```javascript
// 100% coverage but poor test
function add(a, b) {
  return a + b;
}

test('add function', () => {
  add(1, 2); // No assertion!
});
```

### Good Tests = High Coverage + Quality Assertions

```javascript
test('adds two positive numbers', () => {
  expect(add(2, 3)).toBe(5);
});

test('adds negative numbers', () => {
  expect(add(-2, -3)).toBe(-5);
});

test('adds mixed positive and negative', () => {
  expect(add(5, -3)).toBe(2);
});
```

## Coverage Enforcement

### CI/CD Integration

```json
// package.json
{
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 70,
        "functions": 80,
        "lines": 80,
        "statements": 80
      },
      "./src/core/": {
        "branches": 90,
        "functions": 95,
        "lines": 95,
        "statements": 95
      }
    }
  }
}
```

### Gradual Improvement

Don't try to reach 80% immediately:

1. **Measure current coverage**
2. **Set slightly higher target** (current + 5%)
3. **Enforce in CI/CD**
4. **Incrementally increase**

## Best Practices

1. **Focus on Branch Coverage** - More valuable than line coverage
2. **Test Business Logic First** - Highest ROI
3. **Don't Chase 100%** - Diminishing returns after ~85%
4. **Quality Over Quantity** - Good assertions matter more than high coverage
5. **Cover Edge Cases** - Null, empty, negative, boundary values
6. **Use Coverage to Find Gaps** - Not as a goal itself
7. **Exclude Generated Code** - Config, migrations, etc.

## Summary

Aim for 80%+ coverage on business logic and utilities, 60-80% on API layers, and 40-70% on UI components. Focus on branch coverage, not just line coverage. Use coverage to identify untested code, not as an end goal. Quality tests with good assertions matter more than high coverage numbers. Don't waste time testing framework code, third-party libraries, or trivial getters/setters.
