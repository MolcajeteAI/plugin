# Feature Slicing Anti-Patterns

This guide identifies common mistakes when implementing feature slicing and how to avoid them.

## Anti-Pattern 1: Starting with Horizontal Layers

### The Mistake

Starting by creating all controllers, then all services, then all repositories.

**Bad:**
```
Step 1: Create controllers layer
/controllers
  userController.js
  productController.js
  orderController.js

Step 2: Create services layer
/services
  userService.js
  productService.js
  orderService.js

Step 3: Create models layer
/models
  user.js
  product.js
  order.js
```

### Why It's Wrong

- You're building horizontal layers, not vertical features
- Features are scattered across multiple directories
- Hard to see complete feature implementation
- Defeats the purpose of feature slicing

### The Fix

**Good: Start with vertical slices**
```
/features
  /user-management
    controller.js
    service.js
    repository.js
    model.js
  /product-catalog
    controller.js
    service.js
    repository.js
    model.js
```

Implement one complete feature at a time, top to bottom.

---

## Anti-Pattern 2: Premature Shared Abstractions

### The Mistake

Creating shared utilities or base classes before seeing patterns.

**Bad:**
```
// After implementing just ONE feature, immediately creating shared code
/features
  /user-management
    controller.js
    service.js

/shared
  /base
    baseController.js     // "All controllers will extend this"
    baseService.js        // "All services will use this"
    baseRepository.js     // Created before second feature
```

### Why It's Wrong

- You don't know the pattern yet
- Shared code might not fit future features
- Creates coupling too early
- Violates YAGNI principle

### The Fix

**Good: Wait for 3 instances (Rule of Three)**
```
// Implement features first
/features
  /user-management
    controller.js
    service.js
  /product-catalog
    controller.js
    service.js
  /order-processing
    controller.js
    service.js

// NOW extract common patterns if they truly exist
/shared
  /base
    baseController.js  // Only after seeing the pattern 3 times
```

---

## Anti-Pattern 3: Creating a "Utilities" or "Helpers" Folder

### The Mistake

Creating generic utility folders instead of feature-specific code.

**Bad:**
```
/utils
  validators.js         // Generic validators
  formatters.js         // Generic formatters
  helpers.js           // Generic helpers

/features
  /user-management
    controller.js
    // Uses generic validators from /utils
```

### Why It's Wrong

- Utilities folder becomes a dumping ground
- Hard to know which features use which utilities
- Coupling between features through shared utilities
- Difficult to modify utilities without breaking features

### The Fix

**Good: Keep utilities within features**
```
/features
  /user-management
    controller.js
    service.js
    validators.js        // Feature-specific validators
    formatters.js        // Feature-specific formatters
  /product-catalog
    controller.js
    service.js
    validators.js        // Separate validators for this feature
```

Extract to `/shared` only when you see the same code in 3+ features.

---

## Anti-Pattern 4: Features Directly Depending on Other Features

### The Mistake

One feature importing directly from another feature.

**Bad:**
```javascript
// features/order-processing/orderService.js
import { UserService } from '../user-management/userService.js';
import { ProductService } from '../product-catalog/productService.js';

class OrderService {
  constructor() {
    this.userService = new UserService();      // Direct dependency
    this.productService = new ProductService(); // Direct dependency
  }

  async createOrder(userId, productId) {
    const user = await this.userService.getUser(userId);
    const product = await this.productService.getProduct(productId);
    // Create order
  }
}
```

### Why It's Wrong

- Creates tight coupling between features
- Hard to change one feature without affecting others
- Difficult to test features in isolation
- Can't remove or disable features independently

### The Fix

**Good: Communicate through APIs or events**

**Option 1: Through defined interfaces/contracts**
```javascript
// features/order-processing/orderService.js
class OrderService {
  constructor(userAPI, productAPI) {  // Inject dependencies
    this.userAPI = userAPI;
    this.productAPI = productAPI;
  }

  async createOrder(userId, productId) {
    const user = await this.userAPI.getUser(userId);
    const product = await this.productAPI.getProduct(productId);
    // Create order
  }
}

// app.js - wire dependencies
const userAPI = userFeature.getAPI();
const productAPI = productFeature.getAPI();
const orderService = new OrderService(userAPI, productAPI);
```

**Option 2: Through events**
```javascript
// features/order-processing/orderService.js
class OrderService {
  constructor(eventBus) {
    this.eventBus = eventBus;
  }

  async createOrder(userId, productId) {
    // Emit event instead of direct call
    const user = await this.eventBus.query('user.get', { userId });
    const product = await this.eventBus.query('product.get', { productId });
    // Create order
  }
}
```

---

## Anti-Pattern 5: Mixing Framework Code with Feature Code

### The Mistake

Putting framework-specific code (routes, middleware) directly in feature code.

**Bad:**
```javascript
// features/user-management/userController.js
import express from 'express';

const router = express.Router();  // Framework-specific

router.post('/users', async (req, res) => {  // Framework-specific
  // Business logic mixed with framework code
});

export default router;
```

### Why It's Wrong

- Tight coupling to framework
- Hard to change frameworks
- Difficult to test business logic
- Violates dependency inversion principle

### The Fix

**Good: Separate framework from business logic**
```javascript
// features/user-management/domain/userService.js
class UserService {
  // Pure business logic, no framework dependencies
  async createUser(userData) {
    // Business logic
  }
}

// features/user-management/api/userController.js
class UserController {
  constructor(userService) {
    this.userService = userService;
  }

  async createUser(req, res) {
    // Framework adapter
    const userData = req.body;
    const user = await this.userService.createUser(userData);
    res.json(user);
  }
}

// features/user-management/api/routes.js
import express from 'express';

export function createUserRoutes(userController) {
  const router = express.Router();
  router.post('/users', (req, res) => userController.createUser(req, res));
  return router;
}
```

---

## Anti-Pattern 6: Over-Abstracting Too Early

### The Mistake

Creating complex abstractions in the first feature implementation.

**Bad:**
```javascript
// First feature, already over-engineered
class GenericFeatureFactory {
  createFeature(config) {
    return new Feature({
      controller: this.createController(config.controllerType),
      service: this.createService(config.serviceType),
      repository: this.createRepository(config.repositoryType)
    });
  }

  createController(type) { /* complex factory logic */ }
  createService(type) { /* complex factory logic */ }
  createRepository(type) { /* complex factory logic */ }
}
```

### Why It's Wrong

- Complexity without proven need
- Hard to understand
- Violates YAGNI and KISS
- Premature optimization

### The Fix

**Good: Start simple, refactor when needed**
```javascript
// Simple, direct implementation
class UserController {
  constructor(userService) {
    this.userService = userService;
  }

  async getUser(req, res) {
    const user = await this.userService.getUser(req.params.id);
    res.json(user);
  }
}

// Add abstraction only when pattern becomes clear
```

---

## Anti-Pattern 7: Tests in Separate Test Directory

### The Mistake

Keeping all tests in a separate `/test` directory organized by test type.

**Bad:**
```
/src
  /features
    /user-management
      controller.js
      service.js
/test
  /unit
    userService.test.js
  /integration
    userController.test.js
```

### Why It's Wrong

- Tests separated from code they test
- Hard to find relevant tests
- Difficult to see test coverage for a feature
- When feature is removed, tests might be left behind

### The Fix

**Good: Tests within feature directory**
```
/features
  /user-management
    controller.js
    service.js
    /tests
      controller.test.js
      service.test.js
      integration.test.js
```

All code related to a feature, including tests, lives together.

---

## Anti-Pattern 8: God Features (Too Large)

### The Mistake

Creating features that are too large and do too much.

**Bad:**
```
/features
  /user-system
    userController.js
    profileController.js
    settingsController.js
    authController.js
    notificationController.js
    // 20 more files...
```

### Why It's Wrong

- Feature is too large to understand
- Multiple responsibilities (violates SRP)
- Hard to test
- Difficult to maintain

### The Fix

**Good: Split into smaller, focused features**
```
/features
  /user-authentication
    loginController.js
    authService.js
  /user-profile
    profileController.js
    profileService.js
  /user-settings
    settingsController.js
    settingsService.js
  /user-notifications
    notificationController.js
    notificationService.js
```

Each feature has a single, clear responsibility.

---

## Anti-Pattern 9: No Feature Documentation

### The Mistake

Not documenting what each feature does or how to use it.

**Bad:**
```
/features
  /user-management
    controller.js
    service.js
    repository.js
    // No README or documentation
```

### Why It's Wrong

- New developers don't understand feature purpose
- No overview of feature capabilities
- Missing API documentation
- Hard to onboard team members

### The Fix

**Good: Each feature has documentation**
```
/features
  /user-management
    README.md          # Feature documentation
    controller.js
    service.js
    repository.js
```

**README.md should include:**
- Feature overview
- API endpoints
- Dependencies
- How to test
- Related features

---

## Anti-Pattern 10: Inconsistent Feature Structure

### The Mistake

Each feature has a different directory structure.

**Bad:**
```
/features
  /user-management
    /api
      controller.js
    /business
      service.js

  /product-catalog
    handlers/
      productHandler.js
    logic/
      productLogic.js

  /order-processing
    controller.js
    service.js
```

### Why It's Wrong

- Confusing for developers
- Hard to navigate codebase
- Inconsistent patterns
- Difficult to onboard

### The Fix

**Good: Consistent structure across features**
```
/features
  /user-management
    /api
      controller.js
    /domain
      service.js
    /data
      repository.js

  /product-catalog
    /api
      controller.js
    /domain
      service.js
    /data
      repository.js

  /order-processing
    /api
      controller.js
    /domain
      service.js
    /data
      repository.js
```

Establish conventions and stick to them.

---

## Summary: Quick Checklist

Avoid these anti-patterns:

- [ ] Don't start with horizontal layers
- [ ] Don't create shared code before seeing 3 instances
- [ ] Don't make features depend directly on other features
- [ ] Don't mix framework code with business logic
- [ ] Don't over-abstract in first implementation
- [ ] Don't separate tests from feature code
- [ ] Don't create features that are too large
- [ ] Don't skip feature documentation
- [ ] Don't use inconsistent structures across features
- [ ] Don't create generic utility folders too early

## Best Practices Recap

✅ **Do:**
- Start with vertical slices
- Keep related code together
- Extract shared code only after 3+ instances
- Communicate between features through APIs/events
- Separate framework code from business logic
- Keep tests with feature code
- Document each feature
- Maintain consistent structure
- Keep features focused and small

By avoiding these anti-patterns, you'll create a maintainable, understandable, and scalable feature-sliced architecture.
