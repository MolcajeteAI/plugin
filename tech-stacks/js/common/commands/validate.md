---
description: Run all quality checks
---

# Run All Quality Checks

Execute the full validation suite: type-check, lint, format-check, and tests.

Use the Task tool to launch the **quality-guardian** agent with instructions:

1. Run TypeScript type-check:
   ```bash
   npm run type-check
   ```

2. Run linter:
   ```bash
   npm run lint
   ```

3. Check formatting:
   ```bash
   npm run format:check
   ```

4. Run tests:
   ```bash
   npm test
   ```

5. Report overall status:
   - ✅ All checks passed
   - ❌ Which checks failed and why

**Typical validate script:**
```json
{
  "scripts": {
    "validate": "npm run type-check && npm run lint && npm run format:check && npm test"
  }
}
```

**Quality Requirements:**
- All four checks must pass
- Zero errors, zero warnings
- All tests passing

Reference the **code-quality-standards** skill.
