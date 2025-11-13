# DRY - Don't Repeat Yourself

## Definition

**DRY (Don't Repeat Yourself)** is a software development principle that states: "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

The principle aims to reduce repetition of code patterns and logic. When the same piece of logic appears in multiple places, changes must be made in all those places, increasing the risk of errors and maintenance burden.

## Core Concept

DRY is about knowledge and intent, not just code:
- **Code duplication** - Same code in multiple places
- **Logic duplication** - Same logic expressed differently
- **Data duplication** - Same data stored in multiple places
- **Process duplication** - Same process executed in multiple ways

## Detection Methods

### 1. Identical Code Blocks
```javascript
// BAD: Repeated validation logic
function createUser(data) {
  if (!data.email) throw new Error('Email required');
  if (!data.email.includes('@')) throw new Error('Invalid email');
  // ... create user
}

function updateUser(id, data) {
  if (!data.email) throw new Error('Email required');
  if (!data.email.includes('@')) throw new Error('Invalid email');
  // ... update user
}
```

### 2. Similar Patterns with Variations
```javascript
// BAD: Similar functions with slight variations
function getUserById(id) {
  return database.query('SELECT * FROM users WHERE id = ?', [id]);
}

function getProductById(id) {
  return database.query('SELECT * FROM products WHERE id = ?', [id]);
}

function getOrderById(id) {
  return database.query('SELECT * FROM orders WHERE id = ?', [id]);
}
```

### 3. Copy-Paste Indicators
- Multiple files changed for a single logical change
- Similar bug fixes needed in multiple places
- Difficulty finding all instances of a pattern

## Prevention Strategies

### 1. Extract Functions
```javascript
// GOOD: Extracted validation logic
function validateEmail(email) {
  if (!email) throw new Error('Email required');
  if (!email.includes('@')) throw new Error('Invalid email');
}

function createUser(data) {
  validateEmail(data.email);
  // ... create user
}

function updateUser(id, data) {
  validateEmail(data.email);
  // ... update user
}
```

### 2. Use Abstraction
```javascript
// GOOD: Generic function with parameters
function getEntityById(tableName, id) {
  return database.query(`SELECT * FROM ${tableName} WHERE id = ?`, [id]);
}

const getUserById = (id) => getEntityById('users', id);
const getProductById = (id) => getEntityById('products', id);
const getOrderById = (id) => getEntityById('orders', id);
```

### 3. Configuration Over Code
```javascript
// GOOD: Configuration-driven approach
const validationRules = {
  email: [
    { test: (v) => !!v, message: 'Email required' },
    { test: (v) => v.includes('@'), message: 'Invalid email' }
  ],
  password: [
    { test: (v) => v.length >= 8, message: 'Password too short' }
  ]
};

function validate(field, value) {
  const rules = validationRules[field];
  for (const rule of rules) {
    if (!rule.test(value)) throw new Error(rule.message);
  }
}
```

### 4. Inheritance and Composition
```javascript
// GOOD: Base class with common functionality
class BaseRepository {
  constructor(tableName) {
    this.tableName = tableName;
  }

  findById(id) {
    return database.query(`SELECT * FROM ${this.tableName} WHERE id = ?`, [id]);
  }

  findAll() {
    return database.query(`SELECT * FROM ${this.tableName}`);
  }
}

class UserRepository extends BaseRepository {
  constructor() {
    super('users');
  }

  findByEmail(email) {
    return database.query('SELECT * FROM users WHERE email = ?', [email]);
  }
}
```

## Code Examples

### Example 1: Form Validation

**Before (WET - Write Everything Twice):**
```javascript
function validateLoginForm(data) {
  const errors = {};
  if (!data.email) errors.email = 'Email required';
  if (data.email && !data.email.includes('@')) errors.email = 'Invalid email';
  if (!data.password) errors.password = 'Password required';
  return errors;
}

function validateRegistrationForm(data) {
  const errors = {};
  if (!data.email) errors.email = 'Email required';
  if (data.email && !data.email.includes('@')) errors.email = 'Invalid email';
  if (!data.password) errors.password = 'Password required';
  if (data.password && data.password.length < 8) errors.password = 'Password too short';
  if (!data.name) errors.name = 'Name required';
  return errors;
}
```

**After (DRY):**
```javascript
const validators = {
  required: (value, field) => !value ? `${field} required` : null,
  email: (value) => value && !value.includes('@') ? 'Invalid email' : null,
  minLength: (min) => (value) => value && value.length < min ? `Minimum ${min} characters` : null
};

function validateForm(data, rules) {
  const errors = {};
  for (const [field, fieldRules] of Object.entries(rules)) {
    for (const rule of fieldRules) {
      const error = rule(data[field], field);
      if (error) {
        errors[field] = error;
        break;
      }
    }
  }
  return errors;
}

const loginRules = {
  email: [validators.required, validators.email],
  password: [validators.required]
};

const registrationRules = {
  email: [validators.required, validators.email],
  password: [validators.required, validators.minLength(8)],
  name: [validators.required]
};
```

### Example 2: API Endpoints

**Before (WET):**
```javascript
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await db.users.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await db.products.findById(req.params.id);
    if (!product) return res.status(404).json({ error: 'Not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**After (DRY):**
```javascript
function getEntityHandler(repository) {
  return async (req, res) => {
    try {
      const entity = await repository.findById(req.params.id);
      if (!entity) return res.status(404).json({ error: 'Not found' });
      res.json(entity);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  };
}

app.get('/api/users/:id', getEntityHandler(db.users));
app.get('/api/products/:id', getEntityHandler(db.products));
```

## When NOT to DRY

### 1. Premature Abstraction
Don't extract common code until you see the pattern repeated 2-3 times. Wait to understand the full pattern before abstracting.

```javascript
// DON'T create abstraction after one instance
function processUserData(data) { /* ... */ }

// DO wait until you see the pattern
function processUserData(data) { /* ... */ }
function processProductData(data) { /* ... */ }
// Now consider: function processData(type, data) { /* ... */ }
```

### 2. Coincidental Duplication
Similar code doesn't mean same intent. If two pieces of code happen to look alike but serve different purposes, don't force them together.

```javascript
// These look similar but serve different purposes
function formatUserDisplayName(user) {
  return `${user.firstName} ${user.lastName}`;
}

function formatProductDescription(product) {
  return `${product.brand} ${product.model}`;
}
// DON'T combine these - they're coincidentally similar
```

### 3. Over-Abstraction
Too much abstraction can make code harder to understand and maintain.

```javascript
// BAD: Over-abstracted
function process(config) {
  const { validator, transformer, persistor, notifier } = config;
  const validated = validator(config.data);
  const transformed = transformer(validated);
  const persisted = persistor(transformed);
  notifier(persisted);
}

// GOOD: Clear and explicit
function createUser(data) {
  validateUser(data);
  const user = transformUserData(data);
  const saved = saveUser(user);
  sendWelcomeEmail(saved);
}
```

## Benefits of DRY

1. **Easier Maintenance** - Change logic in one place
2. **Fewer Bugs** - No inconsistencies between duplicates
3. **Better Readability** - Clear intent through abstraction
4. **Faster Development** - Reuse existing code
5. **Consistent Behavior** - Same logic produces same results

## Costs of DRY

1. **Increased Coupling** - Changes affect multiple callers
2. **Added Complexity** - Abstractions can be harder to understand
3. **Performance Overhead** - Extra function calls and indirection
4. **Harder Debugging** - Stack traces go through abstraction layers

## Best Practices

1. **Rule of Three** - Wait until code appears 3 times before extracting
2. **Name Well** - Abstractions should have clear, descriptive names
3. **Keep It Simple** - Don't over-parameterize abstractions
4. **Document Intent** - Explain why the abstraction exists
5. **Test Thoroughly** - Shared code affects multiple places
6. **Refactor Gradually** - Extract incrementally, don't rewrite everything

## Detection Checklist

Ask yourself:
- [ ] Am I copy-pasting code?
- [ ] Would a bug fix need to be made in multiple places?
- [ ] Is the same logic expressed differently in different places?
- [ ] Can I extract a function/class/module?
- [ ] Would extraction make the code clearer or more complex?
- [ ] Is this real duplication or coincidental similarity?

## Summary

DRY is about reducing knowledge duplication, not just code duplication. Extract common patterns into reusable abstractions, but don't abstract too early or too much. Balance DRY with readability and maintainability. The goal is maintainable code, not minimal lines of code.
