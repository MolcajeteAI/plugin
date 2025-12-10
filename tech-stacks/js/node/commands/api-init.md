---
description: Initialize REST/GraphQL API project with Fastify, Prisma, and modern patterns
---

# Initialize API Project

Initialize a new Node.js API project with type-safe configuration.

Use the Task tool to launch the **api-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - API type (REST, GraphQL, tRPC)
   - HTTP framework (Fastify - default, Express, Hono)
   - ORM choice (Prisma - default, Drizzle ORM)
   - Database type (PostgreSQL, MySQL, SQLite)
   - Authentication method (JWT, session, none)

2. Create project structure:
   ```
   project/
   ├── src/
   │   ├── index.ts              # Entry point
   │   ├── app.ts                # App configuration
   │   ├── config/
   │   │   └── index.ts          # Environment config
   │   ├── routes/
   │   │   ├── index.ts          # Route registration
   │   │   └── health.ts         # Health check endpoint
   │   ├── middleware/
   │   │   ├── error-handler.ts  # Global error handler
   │   │   └── auth.ts           # Authentication middleware
   │   ├── services/
   │   │   └── __tests__/
   │   ├── db/
   │   │   └── index.ts          # Database client
   │   └── __tests__/
   │       └── health.test.ts
   ├── prisma/
   │   └── schema.prisma
   ├── dist/
   ├── tsconfig.json
   ├── package.json
   ├── .env.example
   ├── .gitignore
   └── README.md
   ```

3. Create `package.json` with scripts:
   ```json
   {
     "type": "module",
     "scripts": {
       "dev": "tsx watch src/index.ts",
       "build": "tsup src/index.ts --format esm --dts",
       "start": "node dist/index.js",
       "type-check": "tsc --noEmit",
       "lint": "biome check .",
       "format": "biome format --write .",
       "test": "vitest run",
       "test:watch": "vitest",
       "test:integration": "vitest run --config vitest.integration.config.ts",
       "db:generate": "prisma generate",
       "db:migrate": "prisma migrate dev",
       "db:push": "prisma db push",
       "db:seed": "tsx prisma/seed.ts",
       "validate": "npm run type-check && npm run lint && npm test"
     }
   }
   ```

4. Create Fastify app configuration:
   ```typescript
   // src/app.ts
   import Fastify from 'fastify';
   import { config } from './config';

   export async function buildApp() {
     const app = Fastify({
       logger: {
         level: config.logLevel,
       },
     });

     // Register plugins
     await app.register(import('./routes'));

     return app;
   }
   ```

5. Create health check endpoint

6. Create error handling middleware

7. Set up Prisma schema with initial User model

8. Create `.env.example`:
   ```
   DATABASE_URL=postgresql://user:password@localhost:5432/dbname
   JWT_SECRET=your-secret-key
   PORT=3000
   NODE_ENV=development
   LOG_LEVEL=info
   ```

9. Install dependencies:
   - fastify, @fastify/cors, @fastify/jwt
   - @prisma/client, prisma
   - zod, pino
   - tsx, tsup (dev)

10. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- All tests passing
- NO `any` types allowed

Reference the **fastify-patterns**, **prisma-setup**, and **zod-validation** skills.
