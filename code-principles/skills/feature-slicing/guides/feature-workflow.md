# Feature Slicing Workflow

This guide provides a complete step-by-step workflow for implementing features using the feature slicing approach.

## Overview

Feature slicing implements features vertically - including all layers needed for that feature in one cohesive module. This contrasts with horizontal layering where you implement controllers, then services, then models separately.

## Complete Workflow

### Step 1: Identify the Feature

**Questions to ask:**
- What user-facing capability am I building?
- What is the business value of this feature?
- What is the smallest useful version of this feature?

**Example:**
- Feature: "User Authentication"
- Value: Users can securely log into the application
- MVP: Login with email/password

### Step 2: Create Feature Directory Structure

Create a directory for your feature with all necessary files.

**Structure:**
```
/features
  /user-authentication
    /api           # API routes/controllers
    /domain        # Business logic
    /data          # Data access
    /ui            # User interface (if applicable)
    /tests         # Feature tests
    README.md      # Feature documentation
```

**Alternative flat structure for simple features:**
```
/features
  /user-authentication
    controller.js
    service.js
    repository.js
    model.js
    validator.js
    tests/
    README.md
```

### Step 3: Implement from Top to Bottom (Outside-In)

Start with the API/UI layer and work your way down.

**3.1: Define the Interface (Controller/API)**

```javascript
// features/user-authentication/api/authController.js
class AuthController {
  async login(req, res) {
    // Define what the outside world sees
    const { email, password } = req.body;

    // Delegate to service (we'll implement this next)
    const result = await authService.login(email, password);

    res.json(result);
  }

  async logout(req, res) {
    // Logout logic
  }
}
```

**3.2: Implement Business Logic (Service)**

```javascript
// features/user-authentication/domain/authService.js
class AuthService {
  constructor(userRepository, tokenService) {
    this.userRepository = userRepository;
    this.tokenService = tokenService;
  }

  async login(email, password) {
    // Validate input
    this.validateLoginInput(email, password);

    // Get user from repository
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValid = await this.verifyPassword(password, user.passwordHash);
    if (!isValid) {
      throw new Error('Invalid credentials');
    }

    // Generate token
    const token = await this.tokenService.generate(user.id);

    return { token, user: { id: user.id, email: user.email } };
  }

  validateLoginInput(email, password) {
    if (!email || !password) {
      throw new Error('Email and password required');
    }
  }

  async verifyPassword(password, hash) {
    // Password verification logic
    return bcrypt.compare(password, hash);
  }
}
```

**3.3: Implement Data Access (Repository)**

```javascript
// features/user-authentication/data/userRepository.js
class UserRepository {
  constructor(database) {
    this.db = database;
  }

  async findByEmail(email) {
    return await this.db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
  }

  async findById(id) {
    return await this.db.query(
      'SELECT * FROM users WHERE id = ?',
      [id]
    );
  }
}
```

**3.4: Define Data Models**

```javascript
// features/user-authentication/domain/user.js
class User {
  constructor({ id, email, passwordHash, createdAt }) {
    this.id = id;
    this.email = email;
    this.passwordHash = passwordHash;
    this.createdAt = createdAt;
  }

  // Domain methods
  isActive() {
    // Business logic for user status
  }
}
```

### Step 4: Write Tests Within the Feature

Keep all tests related to the feature together.

```javascript
// features/user-authentication/tests/authService.test.js
describe('AuthService', () => {
  let authService;
  let mockUserRepository;
  let mockTokenService;

  beforeEach(() => {
    mockUserRepository = {
      findByEmail: jest.fn()
    };
    mockTokenService = {
      generate: jest.fn()
    };
    authService = new AuthService(mockUserRepository, mockTokenService);
  });

  describe('login', () => {
    it('should return token for valid credentials', async () => {
      // Test implementation
    });

    it('should throw error for invalid credentials', async () => {
      // Test implementation
    });
  });
});
```

### Step 5: Document the Feature

Create a README within the feature directory.

```markdown
<!-- features/user-authentication/README.md -->
# User Authentication Feature

## Overview
Handles user login and logout functionality.

## Components
- **AuthController**: API endpoints for authentication
- **AuthService**: Business logic for authentication
- **UserRepository**: Data access for users
- **TokenService**: JWT token generation and validation

## API Endpoints
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/logout` - Logout user

## Dependencies
- bcrypt (password hashing)
- jsonwebtoken (token generation)

## Testing
Run tests: `npm test features/user-authentication`
```

### Step 6: Integrate with Application

Connect the feature to your main application.

```javascript
// app.js or main router
import { authRouter } from './features/user-authentication/api/authRoutes.js';

app.use('/api/auth', authRouter);
```

## Feature Workflow Example: E-commerce Product Catalog

Let's implement a "Product Catalog" feature step by step.

### Step 1: Identify Feature
- Feature: Product Catalog
- Value: Users can browse and search products
- MVP: List products, view product details, search by name

### Step 2: Create Structure

```
/features
  /product-catalog
    /api
      productController.js
      productRoutes.js
    /domain
      productService.js
      product.js
      productValidator.js
    /data
      productRepository.js
    /tests
      productService.test.js
      productRepository.test.js
    README.md
```

### Step 3: Implement (Outside-In)

**API Layer:**
```javascript
// features/product-catalog/api/productController.js
class ProductController {
  constructor(productService) {
    this.productService = productService;
  }

  async listProducts(req, res) {
    const { page = 1, limit = 20, search } = req.query;
    const products = await this.productService.listProducts({ page, limit, search });
    res.json(products);
  }

  async getProduct(req, res) {
    const { id } = req.params;
    const product = await this.productService.getProduct(id);
    res.json(product);
  }
}
```

**Domain Layer:**
```javascript
// features/product-catalog/domain/productService.js
class ProductService {
  constructor(productRepository) {
    this.repository = productRepository;
  }

  async listProducts({ page, limit, search }) {
    const offset = (page - 1) * limit;

    if (search) {
      return await this.repository.searchByName(search, { limit, offset });
    }

    return await this.repository.findAll({ limit, offset });
  }

  async getProduct(id) {
    const product = await this.repository.findById(id);
    if (!product) {
      throw new Error('Product not found');
    }
    return product;
  }
}
```

**Data Layer:**
```javascript
// features/product-catalog/data/productRepository.js
class ProductRepository {
  constructor(database) {
    this.db = database;
  }

  async findAll({ limit, offset }) {
    return await this.db.query(
      'SELECT * FROM products LIMIT ? OFFSET ?',
      [limit, offset]
    );
  }

  async findById(id) {
    return await this.db.query(
      'SELECT * FROM products WHERE id = ?',
      [id]
    );
  }

  async searchByName(name, { limit, offset }) {
    return await this.db.query(
      'SELECT * FROM products WHERE name LIKE ? LIMIT ? OFFSET ?',
      [`%${name}%`, limit, offset]
    );
  }
}
```

## Comparison: Horizontal vs Vertical Implementation

### Horizontal (Traditional) Approach

**Step 1: Create all controllers**
```
/controllers
  userController.js
  productController.js
  orderController.js
```

**Step 2: Create all services**
```
/services
  userService.js
  productService.js
  orderService.js
```

**Step 3: Create all models**
```
/models
  user.js
  product.js
  order.js
```

**Problems:**
- Changes scattered across multiple directories
- Hard to see complete feature implementation
- Merge conflicts when multiple developers work
- Difficult to remove or disable features

### Vertical (Feature Slice) Approach

**Implement complete feature:**
```
/features
  /user-management
    controller.js
    service.js
    repository.js
    model.js
    tests/
```

**Benefits:**
- All code for feature in one place
- Easy to see feature scope
- Parallel development without conflicts
- Simple to remove or disable features

## Benefits in Practice

### 1. Easier Code Reviews
Reviewers see complete feature implementation in one pull request within one directory.

### 2. Better Refactoring
All related code is together, making refactoring safer and easier.

### 3. Feature Toggles
Easy to enable/disable features by not loading the feature module.

```javascript
// app.js
const features = {
  'user-auth': true,
  'product-catalog': true,
  'payment': false  // Disabled feature
};

Object.entries(features).forEach(([name, enabled]) => {
  if (enabled) {
    loadFeature(name);
  }
});
```

### 4. Team Ownership
Teams can own entire features without stepping on each other's toes.

### 5. Parallel Development
Multiple developers implement different features simultaneously without conflicts.

## Trade-offs

### Benefits
- High cohesion within features
- Low coupling between features
- Easy navigation and understanding
- Clear ownership and boundaries
- Parallel development enabled

### Costs
- Some code duplication across features (initially)
- Requires discipline to not create shared code too early
- May feel unusual for developers used to layered architecture
- Need clear guidelines on when to extract shared code

## Best Practices

1. **Start Vertical** - Always begin with vertical slice
2. **Shared Last** - Extract shared code only after 3+ instances
3. **Complete Features** - Include tests and docs in feature directory
4. **Clear Boundaries** - Features should not directly depend on each other
5. **Communicate Through APIs** - Features interact through defined interfaces
6. **Document Features** - Each feature has its own README
7. **Independent Tests** - Tests should run per-feature

## Common Questions

**Q: What about shared utilities?**
A: Keep them in features until you see 3+ instances, then extract to `/shared` or `/common`.

**Q: What about database models used by multiple features?**
A: Start with models in features. Extract to `/shared/models` only when necessary.

**Q: How do features communicate?**
A: Through events, message queues, or defined API contracts. Avoid direct dependencies.

**Q: What about authentication/authorization?**
A: Cross-cutting concerns can live in `/shared` or as middleware, but feature-specific auth logic stays in the feature.

## Summary

Feature slicing organizes code by business capabilities, creating vertical slices through all technical layers. Start by implementing complete features in isolation, test them thoroughly, and extract shared code only when clear patterns emerge. This approach leads to more maintainable, understandable, and scalable codebases.
