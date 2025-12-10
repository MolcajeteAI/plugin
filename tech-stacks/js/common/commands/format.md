---
description: Format code
model: haiku
---

# Format Code

Apply consistent formatting to all source files.

Execute the following command:

```bash
npm run format
```

**For Biome:**
```bash
biome format --write .
```

**For Prettier:**
```bash
prettier --write .
```

**Files Formatted:**
- `*.ts`, `*.tsx` - TypeScript files
- `*.js`, `*.jsx` - JavaScript files
- `*.json` - JSON files
- `*.md` - Markdown files

Reference the **biome-setup** or **eslint-flat-config** skill based on project configuration.
