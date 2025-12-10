---
name: integration-testing
description: API integration testing with Supertest and Vitest. Use when testing API endpoints.
---

# Integration Testing Skill

This skill covers integration testing patterns for Node.js APIs.

## When to Use

Use this skill when:
- Testing API endpoints
- Verifying request/response cycles
- Testing database interactions
- Validating authentication flows

## Core Principle

**TEST REAL BEHAVIOR** - Integration tests verify components work together. Use real databases when possible.

## Setup

```bash
npm install -D vitest supertest @types/supertest
```

## Vitest Configuration

```typescript
// vitest.integration.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['src/**/*.integration.test.ts'],
    globalSetup: './tests/setup/global.ts',
    setupFiles: ['./tests/setup/integration.ts'],
    testTimeout: 30000,
    hookTimeout: 10000,
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,
      },
    },
  },
});
```

## Test Setup

```typescript
// tests/setup/integration.ts
import { beforeAll, afterAll, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

beforeAll(async () => {
  await prisma.$connect();
});

afterAll(async () => {
  await prisma.$disconnect();
});

afterEach(async () => {
  // Clean up test data
  await prisma.$transaction([
    prisma.comment.deleteMany(),
    prisma.post.deleteMany(),
    prisma.session.deleteMany(),
    prisma.user.deleteMany(),
  ]);
});
```

## Basic API Test

```typescript
// src/routes/__tests__/health.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../app';

describe('Health endpoint', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns healthy status', async () => {
    const response = await supertest(app.server)
      .get('/health')
      .expect(200);

    expect(response.body).toMatchObject({
      status: 'healthy',
    });
    expect(response.body.timestamp).toBeDefined();
  });
});
```

## CRUD Endpoint Tests

```typescript
// src/routes/__tests__/users.integration.test.ts
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../app';
import { createTestUser, generateAuthToken } from '../../../tests/helpers';

describe('Users API', () => {
  let app: FastifyInstance;
  let authToken: string;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    const user = await createTestUser({ role: 'ADMIN' });
    authToken = generateAuthToken(user);
  });

  describe('POST /api/users', () => {
    it('creates a user with valid data', async () => {
      const userData = {
        email: 'newuser@example.com',
        name: 'New User',
        password: 'Password123!',
      };

      const response = await supertest(app.server)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send(userData)
        .expect(201);

      expect(response.body).toMatchObject({
        email: userData.email,
        name: userData.name,
      });
      expect(response.body.id).toBeDefined();
      expect(response.body.password).toBeUndefined();
    });

    it('rejects invalid email format', async () => {
      const response = await supertest(app.server)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'invalid-email',
          name: 'Test',
          password: 'Password123!',
        })
        .expect(400);

      expect(response.body.error).toBeDefined();
    });

    it('rejects duplicate email', async () => {
      await createTestUser({ email: 'existing@example.com' });

      const response = await supertest(app.server)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'existing@example.com',
          name: 'Test',
          password: 'Password123!',
        })
        .expect(400);

      expect(response.body.error).toContain('email');
    });
  });

  describe('GET /api/users/:id', () => {
    it('returns user by id', async () => {
      const user = await createTestUser();

      const response = await supertest(app.server)
        .get(`/api/users/${user.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: user.id,
        email: user.email,
        name: user.name,
      });
    });

    it('returns 404 for non-existent user', async () => {
      await supertest(app.server)
        .get('/api/users/non-existent-id')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('PUT /api/users/:id', () => {
    it('updates user data', async () => {
      const user = await createTestUser();

      const response = await supertest(app.server)
        .put(`/api/users/${user.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Updated Name' })
        .expect(200);

      expect(response.body.name).toBe('Updated Name');
    });
  });

  describe('DELETE /api/users/:id', () => {
    it('deletes user', async () => {
      const user = await createTestUser();

      await supertest(app.server)
        .delete(`/api/users/${user.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(204);

      // Verify deletion
      await supertest(app.server)
        .get(`/api/users/${user.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });
});
```

## Authentication Tests

```typescript
// src/routes/__tests__/auth.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../app';
import { createTestUser } from '../../../tests/helpers';

describe('Auth API', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /api/auth/login', () => {
    it('returns tokens for valid credentials', async () => {
      await createTestUser({
        email: 'test@example.com',
        password: 'Password123!',
      });

      const response = await supertest(app.server)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Password123!',
        })
        .expect(200);

      expect(response.body.accessToken).toBeDefined();
      expect(response.body.refreshToken).toBeDefined();
      expect(response.body.user).toMatchObject({
        email: 'test@example.com',
      });
    });

    it('rejects invalid password', async () => {
      await createTestUser({
        email: 'test@example.com',
        password: 'Password123!',
      });

      await supertest(app.server)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'WrongPassword!',
        })
        .expect(401);
    });
  });

  describe('POST /api/auth/refresh', () => {
    it('returns new tokens with valid refresh token', async () => {
      const user = await createTestUser();
      const loginResponse = await supertest(app.server)
        .post('/api/auth/login')
        .send({
          email: user.email,
          password: 'Password123!',
        });

      const response = await supertest(app.server)
        .post('/api/auth/refresh')
        .send({ refreshToken: loginResponse.body.refreshToken })
        .expect(200);

      expect(response.body.accessToken).toBeDefined();
      expect(response.body.refreshToken).toBeDefined();
    });
  });

  describe('Protected routes', () => {
    it('requires authentication', async () => {
      await supertest(app.server)
        .get('/api/users/me')
        .expect(401);
    });

    it('rejects invalid token', async () => {
      await supertest(app.server)
        .get('/api/users/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});
```

## Test Helpers

```typescript
// tests/helpers/index.ts
import { PrismaClient, User, Role } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const prisma = new PrismaClient();

interface CreateUserOptions {
  email?: string;
  name?: string;
  password?: string;
  role?: Role;
}

export async function createTestUser(options: CreateUserOptions = {}): Promise<User> {
  const {
    email = `test-${Date.now()}@example.com`,
    name = 'Test User',
    password = 'Password123!',
    role = 'USER',
  } = options;

  const hashedPassword = await bcrypt.hash(password, 10);

  return prisma.user.create({
    data: { email, name, password: hashedPassword, role },
  });
}

export function generateAuthToken(user: User): string {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: '1h' }
  );
}

export async function createTestPost(authorId: string, options = {}) {
  return prisma.post.create({
    data: {
      title: 'Test Post',
      slug: `test-post-${Date.now()}`,
      content: 'Test content',
      authorId,
      ...options,
    },
  });
}
```

## Database Seeding for Tests

```typescript
// tests/setup/seed.ts
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

export async function seedTestData() {
  const password = await bcrypt.hash('Password123!', 10);

  const admin = await prisma.user.create({
    data: {
      email: 'admin@test.com',
      name: 'Admin',
      password,
      role: 'ADMIN',
    },
  });

  const user = await prisma.user.create({
    data: {
      email: 'user@test.com',
      name: 'User',
      password,
      role: 'USER',
    },
  });

  return { admin, user };
}
```

## Running Tests

```bash
# Run integration tests
npm run test:integration

# Run with coverage
npm run test:integration -- --coverage

# Run specific file
npm run test:integration -- users.integration.test.ts

# Watch mode
npm run test:integration -- --watch
```

## Best Practices

1. **Isolate tests** - Each test should be independent
2. **Clean up** - Reset database state between tests
3. **Use factories** - Create test data with helpers
4. **Test edge cases** - Invalid input, auth failures, not found
5. **Check response shape** - Validate complete response structure
6. **Test status codes** - Verify correct HTTP status codes

## Notes

- Integration tests are slower than unit tests
- Use a separate test database
- Run sequentially to avoid conflicts
- Mock external services (email, payments)
