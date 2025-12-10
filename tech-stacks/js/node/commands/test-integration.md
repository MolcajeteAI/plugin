---
description: Run integration tests with Supertest
---

# Run Integration Tests

Run API integration tests using Supertest.

Use the Task tool to launch the **tester** agent with instructions:

1. Ensure test database is configured:
   - `.env.test` with test database URL
   - Separate database instance for tests

2. Run database migrations for test environment:
   ```bash
   DATABASE_URL=$TEST_DATABASE_URL npx prisma migrate deploy
   ```

3. Run integration tests:
   ```bash
   npm run test:integration
   ```

   Or with Vitest:
   ```bash
   npx vitest run --config vitest.integration.config.ts
   ```

4. Integration test configuration:
   ```typescript
   // vitest.integration.config.ts
   import { defineConfig } from 'vitest/config';

   export default defineConfig({
     test: {
       include: ['src/**/*.integration.test.ts'],
       globalSetup: './tests/integration/setup.ts',
       globalTeardown: './tests/integration/teardown.ts',
       testTimeout: 30000,
     },
   });
   ```

5. Example integration test:
   ```typescript
   // src/routes/__tests__/users.integration.test.ts
   import { describe, it, expect, beforeAll, afterAll } from 'vitest';
   import supertest from 'supertest';
   import { buildApp } from '../../app';

   describe('Users API', () => {
     let app: FastifyInstance;

     beforeAll(async () => {
       app = await buildApp();
       await app.ready();
     });

     afterAll(async () => {
       await app.close();
     });

     it('creates a user', async () => {
       const response = await supertest(app.server)
         .post('/api/users')
         .send({ email: 'test@example.com', name: 'Test User' })
         .expect(201);

       expect(response.body).toMatchObject({
         email: 'test@example.com',
         name: 'Test User',
       });
     });
   });
   ```

6. Generate coverage report:
   ```bash
   npm run test:integration -- --coverage
   ```

**Quality Requirements:**
- All integration tests must pass
- Test database isolated from development
- Clean up test data after each test
- Coverage threshold met

Reference the **integration-testing** skill.
