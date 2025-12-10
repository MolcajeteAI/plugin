---
description: Validate API schemas with Zod
---

# Validate API Schemas

Validate all Zod schemas and ensure type consistency.

Use the Task tool to launch the **api-builder** agent with instructions:

1. Find all Zod schema files:
   - `src/schemas/*.ts`
   - `src/routes/**/schema.ts`
   - Inline schemas in route files

2. Validate schema definitions:
   - All schemas export properly
   - Type inference works (`z.infer<typeof Schema>`)
   - No circular dependencies

3. Run type-check:
   ```bash
   npm run type-check
   ```

4. Check for common issues:
   - Unused schemas
   - Missing required fields
   - Inconsistent naming

5. Generate schema documentation (optional):
   ```bash
   npx zod-to-json-schema
   ```

6. Validate runtime behavior with tests:
   ```bash
   npm test -- --grep schema
   ```

**Quality Requirements:**
- All schemas must pass type-check
- Schema inference must work correctly
- No `any` types in schema definitions
- Tests for schema validation logic

Reference the **zod-validation** skill.
