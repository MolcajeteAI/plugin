---
description: Build project
---

# Build Project

Compile TypeScript and bundle the project for production.

Use the Task tool to launch the **quality-guardian** agent with instructions:

1. Run type-check first:
   ```bash
   npm run type-check
   ```
2. If type-check passes, run build:
   ```bash
   npm run build
   ```
3. Verify build output exists in `dist/` directory
4. Report build success or any errors

**Typical build commands:**
- Library: `tsup src/index.ts --format esm,cjs --dts`
- App: Framework-specific build command

**Quality Requirements:**
- Type-check must pass with zero errors
- Build must complete successfully
- Output files must be generated

Reference the **build-tools** skill.
