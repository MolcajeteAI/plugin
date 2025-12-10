---
description: Run tests with Docker containers using testcontainers
---

# Run Tests with Docker Containers

Run integration tests using testcontainers for isolated database instances.

Use the Task tool to launch the **tester** agent with instructions:

1. Ensure Docker is running:
   ```bash
   docker info
   ```

2. Install testcontainers:
   ```bash
   npm install -D @testcontainers/postgresql
   ```

3. Create test setup with containers:
   ```typescript
   // tests/setup/database.ts
   import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
   import { PrismaClient } from '@prisma/client';
   import { execSync } from 'child_process';

   let container: StartedPostgreSqlContainer;
   let prisma: PrismaClient;

   export async function setupDatabase(): Promise<PrismaClient> {
     container = await new PostgreSqlContainer()
       .withDatabase('test')
       .withUsername('test')
       .withPassword('test')
       .start();

     const databaseUrl = container.getConnectionUri();
     process.env.DATABASE_URL = databaseUrl;

     // Run migrations
     execSync('npx prisma migrate deploy', {
       env: { ...process.env, DATABASE_URL: databaseUrl },
     });

     prisma = new PrismaClient({
       datasources: { db: { url: databaseUrl } },
     });

     return prisma;
   }

   export async function teardownDatabase(): Promise<void> {
     await prisma.$disconnect();
     await container.stop();
   }
   ```

4. Use in tests:
   ```typescript
   // src/services/__tests__/user.container.test.ts
   import { describe, it, expect, beforeAll, afterAll } from 'vitest';
   import { PrismaClient } from '@prisma/client';
   import { setupDatabase, teardownDatabase } from '../../../tests/setup/database';
   import { UserService } from '../user';

   describe('UserService with testcontainers', () => {
     let prisma: PrismaClient;
     let userService: UserService;

     beforeAll(async () => {
       prisma = await setupDatabase();
       userService = new UserService(prisma);
     }, 60000);

     afterAll(async () => {
       await teardownDatabase();
     });

     it('creates and retrieves user', async () => {
       const user = await userService.create({
         email: 'test@example.com',
         name: 'Test User',
       });

       const found = await userService.findById(user.id);
       expect(found).toMatchObject({
         email: 'test@example.com',
         name: 'Test User',
       });
     });
   });
   ```

5. Run container tests:
   ```bash
   npx vitest run --config vitest.container.config.ts
   ```

6. Container test configuration:
   ```typescript
   // vitest.container.config.ts
   import { defineConfig } from 'vitest/config';

   export default defineConfig({
     test: {
       include: ['**/*.container.test.ts'],
       testTimeout: 120000,
       hookTimeout: 60000,
       pool: 'forks',
       poolOptions: {
         forks: {
           singleFork: true, // Run serially for container tests
         },
       },
     },
   });
   ```

**Quality Requirements:**
- Docker must be running
- Container startup timeout handled
- Proper cleanup after tests
- Isolated database per test run

Reference the **testcontainers-usage** skill.
