# YAGNI - You Aren't Gonna Need It

## Definition

**YAGNI (You Aren't Gonna Need It)** is a principle that states you should not add functionality until it is actually needed, not when you just foresee that you might need it.

The principle comes from Extreme Programming (XP) and emphasizes implementing things when you actually need them, never when you just foresee that you might need them.

## Core Concept

- **Build for today, not for tomorrow**
- **Don't implement features "just in case"**
- **Avoid speculative generality**
- **Focus on actual requirements, not potential ones**
- **Every line of code has a cost**

## The Cost of Premature Features

### 1. Development Time
Time spent building unused features could be spent on actual requirements.

### 2. Maintenance Burden
Every line of code needs to be maintained, tested, and understood.

### 3. Increased Complexity
Extra code makes the system harder to understand and modify.

### 4. Wrong Abstractions
Features built too early are often based on incorrect assumptions.

### 5. Opportunity Cost
Resources spent on speculative features aren't available for real needs.

## Examples of YAGNI Violations

### Example 1: Premature Abstraction

**Bad - Building for unknown future:**
```javascript
class UserManager {
  constructor() {
    // We might need multiple storage backends in the future
    this.storageStrategy = this.getStorageStrategy();
    this.cacheStrategy = this.getCacheStrategy();
    this.validationStrategy = this.getValidationStrategy();
  }

  getStorageStrategy() {
    // Complex factory pattern for future flexibility
    const config = this.loadConfig();
    switch (config.storageType) {
      case 'sql': return new SQLStorage();
      case 'nosql': return new NoSQLStorage();
      case 'file': return new FileStorage();
      default: return new InMemoryStorage();
    }
  }

  getCacheStrategy() {
    // We might want different caching strategies
    return new LRUCache(); // Only this is ever used
  }

  getValidationStrategy() {
    // We might have different validation rules
    return new StandardValidator(); // Only this is ever used
  }
}
```

**Good - Build what you need now:**
```javascript
class UserManager {
  constructor(database) {
    this.db = database;
  }

  async getUser(id) {
    return await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async saveUser(user) {
    return await this.db.query('INSERT INTO users VALUES (?, ?)', [user.id, user.name]);
  }
}

// Add abstraction only when you actually need multiple storage backends
```

### Example 2: Speculative Features

**Bad - Features nobody asked for:**
```javascript
class Calculator {
  add(a, b) {
    return a + b;
  }

  subtract(a, b) {
    return a - b;
  }

  // "We might need these someday"
  multiply(a, b) {
    return a * b;
  }

  divide(a, b) {
    return a / b;
  }

  power(base, exponent) {
    return Math.pow(base, exponent);
  }

  squareRoot(n) {
    return Math.sqrt(n);
  }

  // ... 20 more mathematical operations nobody asked for
}

// Requirement was only: addition and subtraction
```

**Good - Implement actual requirements:**
```javascript
class Calculator {
  add(a, b) {
    return a + b;
  }

  subtract(a, b) {
    return a - b;
  }
}

// Add multiply() and divide() when they're actually needed
```

### Example 3: Over-Configuration

**Bad - Configuration for everything:**
```javascript
class EmailService {
  constructor(config) {
    this.host = config.host;
    this.port = config.port;
    this.username = config.username;
    this.password = config.password;

    // "These might be useful someday"
    this.retryAttempts = config.retryAttempts || 3;
    this.retryDelay = config.retryDelay || 1000;
    this.timeout = config.timeout || 30000;
    this.maxConnections = config.maxConnections || 5;
    this.tlsVersion = config.tlsVersion || '1.2';
    this.cipher = config.cipher || 'AES256';
    this.compressionLevel = config.compressionLevel || 6;
    this.keepAlive = config.keepAlive !== undefined ? config.keepAlive : true;
    this.debugMode = config.debugMode || false;
    this.logLevel = config.logLevel || 'info';
    // Nobody has ever changed these defaults
  }
}
```

**Good - Only configure what's needed:**
```javascript
class EmailService {
  constructor({ host, port, username, password }) {
    this.host = host;
    this.port = port;
    this.username = username;
    this.password = password;
  }

  async send(to, subject, body) {
    // Simple implementation
  }
}

// Add configuration options when they're actually needed
```

### Example 4: Premature Optimization

**Bad - Optimizing before measuring:**
```javascript
class DataProcessor {
  constructor() {
    // "We might have performance issues with large datasets"
    this.cache = new LRUCache(10000);
    this.workerPool = new WorkerThreadPool(8);
    this.batchSize = 1000;
  }

  async process(data) {
    // Complex batching and caching logic
    // when data sets are always < 100 items
    const batches = this.createBatches(data);
    const results = await Promise.all(
      batches.map(batch => this.workerPool.execute(batch))
    );
    return results.flat();
  }
}
```

**Good - Simple solution first:**
```javascript
class DataProcessor {
  async process(data) {
    return data.map(item => this.processItem(item));
  }

  processItem(item) {
    // Simple processing
  }
}

// Optimize only when there's an actual performance problem
```

## Decision Framework

### When to Add Features

Ask these questions before implementing:

1. **Is this required NOW?**
   - If no, don't build it

2. **Do I have a concrete use case?**
   - If no, don't build it

3. **Is this based on actual requirements?**
   - If no, don't build it

4. **Will this complicate the codebase?**
   - If yes, is the benefit worth the cost?

5. **Can this be added later without significant refactoring?**
   - If yes, add it later when needed

### Red Flags

Watch for these phrases:
- "We might need this someday"
- "This will make it more flexible"
- "Let's future-proof this"
- "We should support multiple X"
- "What if we want to Y?"
- "This could be useful for Z"

### When NOT to Apply YAGNI

YAGNI doesn't mean "never plan ahead." Don't apply YAGNI to:

1. **Architecture decisions that are hard to change**
   - Database schema design
   - API contracts
   - File formats

2. **Security and compliance requirements**
   - Authentication/authorization
   - Data encryption
   - Audit logging

3. **Known immediate requirements**
   - Features in the current sprint/iteration
   - Documented requirements

4. **Critical non-functional requirements**
   - Performance constraints
   - Scalability needs
   - Reliability requirements

## Real-World Examples

### Example 1: API Versioning

**Bad - Over-engineering:**
```javascript
// "We might need versioning someday"
class API {
  constructor() {
    this.versions = {
      v1: new APIv1(),
      v2: new APIv2(), // Doesn't exist yet
      v3: new APIv3()  // Doesn't exist yet
    };
  }

  handleRequest(version, endpoint, data) {
    return this.versions[version].handle(endpoint, data);
  }
}
```

**Good - Start simple:**
```javascript
class API {
  handleRequest(endpoint, data) {
    // Simple routing
    switch (endpoint) {
      case '/users': return this.getUsers();
      case '/products': return this.getProducts();
    }
  }
}

// Add versioning when you actually release v2
```

### Example 2: Feature Flags

**Bad - Feature flags for everything:**
```javascript
class Features {
  constructor() {
    this.flags = {
      newUI: false,           // Might want to toggle this
      betaFeature: false,     // Might want to toggle this
      darkMode: false,        // Might want to toggle this
      analytics: false,       // Might want to toggle this
      chat: false,            // Might want to toggle this
      notifications: false    // Might want to toggle this
    };
  }

  isEnabled(feature) {
    return this.flags[feature] || false;
  }
}

// Complex conditional logic everywhere
if (features.isEnabled('newUI')) { /* ... */ }
```

**Good - Feature flags only when needed:**
```javascript
// Just build features normally
// Add feature flags when you need gradual rollout or A/B testing
```

### Example 3: Plugins System

**Bad - Building plugin system too early:**
```javascript
class Application {
  constructor() {
    this.plugins = [];
    this.hooks = {
      beforeStart: [],
      afterStart: [],
      beforeRequest: [],
      afterRequest: [],
      // 20 more hooks nobody uses
    };
  }

  registerPlugin(plugin) {
    this.plugins.push(plugin);
    plugin.register(this.hooks);
  }

  async start() {
    await this.runHooks('beforeStart');
    // start logic
    await this.runHooks('afterStart');
  }
}

// Nobody ever writes plugins
```

**Good - Simple extension when needed:**
```javascript
class Application {
  async start() {
    // Simple application logic
  }
}

// Add plugin system when you have actual plugins to support
```

## Benefits of YAGNI

1. **Faster Delivery** - Less code to write and test
2. **Lower Maintenance** - Fewer features to maintain
3. **Better Focus** - Team focuses on actual requirements
4. **Simpler Code** - Less complexity
5. **Right Abstractions** - Built when needs are clear
6. **Lower Costs** - Less development and maintenance time

## Applying YAGNI

### In Planning
- Question every "nice to have" feature
- Focus on MVP (Minimum Viable Product)
- Defer features to future iterations

### In Development
- Implement only current requirements
- Resist the urge to add "just in case" code
- Delete unused code

### In Code Review
- Challenge unnecessary complexity
- Question premature abstractions
- Verify features match requirements

### In Refactoring
- Remove unused features
- Simplify over-engineered solutions
- Delete dead code

## Balancing YAGNI

### YAGNI vs DRY
- Don't extract abstractions until duplication is clear
- Wait for 3 instances before abstracting (Rule of Three)

### YAGNI vs SOLID
- Don't design for extensibility you don't need
- Apply SOLID when requirements show the need

### YAGNI vs Good Design
- YAGNI doesn't mean write bad code
- Still write clean, maintainable code
- Just don't add unused features

## Best Practices

1. **Start with MVP** - Build minimum viable product first
2. **Iterate Based on Feedback** - Add features when users need them
3. **Delete Unused Code** - Remove features that aren't used
4. **Question Assumptions** - Challenge "we might need"
5. **Measure Usage** - Track which features are actually used
6. **Refactor When Needed** - Don't fear changing code later

## Common Objections

### "But refactoring later will be expensive"
- Building unused features now is expensive too
- Refactoring is often easier than anticipated
- You might never need that feature

### "But we need flexibility"
- Build flexibility when you need it
- Premature flexibility adds complexity
- Right abstractions come from real use

### "But this will be harder to add later"
- Maybe, but maybe you won't need it
- Cost now vs uncertain cost later
- You'll have better information later

## Summary

YAGNI is about building what you need today, not what you might need tomorrow. Focus on current requirements, deliver working software quickly, and add features when they're actually needed. Trust that good code can be refactored when new requirements emerge. Remember: the cheapest code to maintain is code you never wrote.
