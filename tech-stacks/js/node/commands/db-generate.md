---
description: Generate Prisma client from schema
---

# Generate Prisma Client

Generate the Prisma client after schema changes.

Use the Task tool to launch the **database-architect** agent with instructions:

1. Verify Prisma schema exists at `prisma/schema.prisma`

2. Run Prisma generate:
   ```bash
   npx prisma generate
   ```

3. Verify client generation succeeded

4. Run type-check to ensure generated types are valid:
   ```bash
   npm run type-check
   ```

5. Display generated client location and usage instructions

**Quality Requirements:**
- Schema must be valid
- No generation errors
- Type-check must pass

Reference the **prisma-setup** skill.
