---
description: Run end-to-end tests for backend services
---

# Run End-to-End Tests

Run E2E tests that test the complete application stack.

Use the Task tool to launch the **tester** agent with instructions:

1. Start required services (database, cache, etc.):
   ```bash
   docker-compose up -d
   ```

2. Wait for services to be ready:
   ```bash
   npx wait-on tcp:5432 tcp:6379
   ```

3. Run migrations:
   ```bash
   npx prisma migrate deploy
   ```

4. Seed test data:
   ```bash
   npx prisma db seed
   ```

5. Start application in test mode:
   ```bash
   NODE_ENV=test npm run start &
   ```

6. Run E2E tests:
   ```bash
   npx vitest run --config vitest.e2e.config.ts
   ```

7. E2E test configuration:
   ```typescript
   // vitest.e2e.config.ts
   import { defineConfig } from 'vitest/config';

   export default defineConfig({
     test: {
       include: ['tests/e2e/**/*.e2e.test.ts'],
       globalSetup: './tests/e2e/setup.ts',
       globalTeardown: './tests/e2e/teardown.ts',
       testTimeout: 60000,
       hookTimeout: 30000,
     },
   });
   ```

8. Example E2E test:
   ```typescript
   // tests/e2e/auth.e2e.test.ts
   import { describe, it, expect } from 'vitest';

   const API_URL = process.env.API_URL || 'http://localhost:3000';

   describe('Authentication E2E', () => {
     it('completes full auth flow', async () => {
       // Register
       const registerResponse = await fetch(`${API_URL}/api/auth/register`, {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({
           email: 'e2e@example.com',
           password: 'Password123!',
           name: 'E2E User',
         }),
       });
       expect(registerResponse.status).toBe(201);

       // Login
       const loginResponse = await fetch(`${API_URL}/api/auth/login`, {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({
           email: 'e2e@example.com',
           password: 'Password123!',
         }),
       });
       expect(loginResponse.status).toBe(200);
       const { token } = await loginResponse.json();

       // Access protected resource
       const profileResponse = await fetch(`${API_URL}/api/users/me`, {
         headers: { Authorization: `Bearer ${token}` },
       });
       expect(profileResponse.status).toBe(200);
     });
   });
   ```

9. Clean up:
   ```bash
   docker-compose down
   ```

**Quality Requirements:**
- All E2E tests must pass
- Services properly started and stopped
- Test data cleaned up
- No flaky tests

Reference the **e2e-testing-backend** skill.
