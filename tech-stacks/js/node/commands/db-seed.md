---
description: Seed database with test data
---

# Seed Database

Seed the database with development or test data.

Use the Task tool to launch the **database-architect** agent with instructions:

1. Check for existing seed file at `prisma/seed.ts`

2. If seed file doesn't exist, create one:
   ```typescript
   // prisma/seed.ts
   import { PrismaClient } from '@prisma/client';

   const prisma = new PrismaClient();

   async function main(): Promise<void> {
     // Clear existing data
     await prisma.$transaction([
       // Add deleteMany calls in correct order
     ]);

     // Create seed data
     console.log('Seeding database...');

     // Add seed data creation

     console.log('Database seeded successfully');
   }

   main()
     .catch((e) => {
       console.error(e);
       process.exit(1);
     })
     .finally(async () => {
       await prisma.$disconnect();
     });
   ```

3. Ensure package.json has seed script:
   ```json
   {
     "prisma": {
       "seed": "tsx prisma/seed.ts"
     }
   }
   ```

4. Run seed:
   ```bash
   npx prisma db seed
   ```

5. Or run directly:
   ```bash
   npx tsx prisma/seed.ts
   ```

6. Verify seeded data

**Quality Requirements:**
- Seed script must be idempotent (safe to run multiple times)
- Clear existing data before seeding
- Use transactions for data integrity
- Type-safe seed data

Reference the **prisma-setup** skill.
