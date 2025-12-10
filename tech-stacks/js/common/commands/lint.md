---
description: Run linter
model: haiku
---

# Run Linter

Check code for linting errors and style issues.

Execute the following command:

```bash
npm run lint
```

**For Biome:**
```bash
biome check .
```

**For ESLint:**
```bash
eslint .
```

**Quality Requirements:**
- Zero linting errors
- Zero linting warnings (warnings are treated as errors)

**Auto-fix:**
```bash
# Biome
biome check --write .

# ESLint
eslint --fix .
```

Reference the **eslint-flat-config** or **biome-setup** skill based on project configuration.
