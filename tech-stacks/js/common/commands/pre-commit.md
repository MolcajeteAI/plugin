---
description: Pre-commit quality gate
---

# Pre-Commit Quality Gate

Run quality checks on staged files before committing.

Use the Task tool to launch the **quality-guardian** agent with instructions:

1. Check if Husky is configured:
   - Look for `.husky/` directory
   - Look for `prepare` script in package.json

2. If not configured, set up pre-commit hooks:
   ```bash
   npm install -D husky lint-staged
   npx husky init
   ```

3. Configure lint-staged in `package.json`:
   ```json
   {
     "lint-staged": {
       "*.{ts,tsx}": [
         "biome check --write",
         "biome format --write"
       ],
       "*.{json,md}": [
         "biome format --write"
       ]
     }
   }
   ```

4. Create `.husky/pre-commit`:
   ```bash
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"

   npx lint-staged
   npm run type-check
   ```

5. Test the hook:
   ```bash
   git add .
   git commit -m "test commit"
   ```

**What pre-commit checks:**
- Lint staged files
- Format staged files
- Run type-check on entire project

**Quality Requirements:**
- All staged files must pass lint
- All staged files must be formatted
- Type-check must pass

Reference the **pre-commit-hooks** skill.
