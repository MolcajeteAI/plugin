---
description: Check formatting
model: haiku
---

# Check Formatting

Verify all files are properly formatted without making changes.

Execute the following command:

```bash
npm run format:check
```

**For Biome:**
```bash
biome format .
```

**For Prettier:**
```bash
prettier --check .
```

**Expected Output:**
- Success: All files formatted correctly (exit code 0)
- Failure: List of files needing formatting

**Quality Requirements:**
- All files must be properly formatted
- Run `npm run format` to fix any issues

Reference the **biome-setup** or **eslint-flat-config** skill based on project configuration.
