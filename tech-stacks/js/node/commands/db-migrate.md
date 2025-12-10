---
description: Run database migrations
---

# Run Database Migrations

Apply pending database migrations.

Use the Task tool to launch the **database-architect** agent with instructions:

1. Check for pending migrations

2. For development:
   ```bash
   npx prisma migrate dev
   ```

3. For production deployment:
   ```bash
   npx prisma migrate deploy
   ```

4. If schema-only push needed (dev only):
   ```bash
   npx prisma db push
   ```

5. Regenerate Prisma client after migration:
   ```bash
   npx prisma generate
   ```

6. Verify database state:
   ```bash
   npx prisma db pull --print
   ```

7. Run type-check to ensure schema matches code:
   ```bash
   npm run type-check
   ```

**Quality Requirements:**
- All migrations must apply successfully
- No data loss warnings without user confirmation
- Type-check must pass after migration

Reference the **migration-strategies** and **prisma-setup** skills.
