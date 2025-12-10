---
description: Run TypeScript compiler checks
model: haiku
---

# Run TypeScript Type Check

Check TypeScript types without emitting output.

Execute the following command:

```bash
npm run type-check
```

This runs:
```bash
tsc --noEmit
```

**Expected Output:**
- Success: No output (exit code 0)
- Failure: TypeScript errors with file locations

**Quality Requirements:**
- Zero TypeScript errors
- Zero TypeScript warnings
- No `any` types (implicit or explicit)

Reference the **typescript-strict-config** skill.
