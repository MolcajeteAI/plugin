---
description: Install and audit dependencies
---

# Install Dependencies

Install project dependencies and run security audit.

Use the Task tool to launch the **security** agent with instructions:

1. Check if `package.json` exists
2. Detect package manager (npm, pnpm, yarn) from lock file
3. Install dependencies:
   ```bash
   npm install
   # or
   pnpm install
   # or
   yarn install
   ```
4. Run security audit:
   ```bash
   npm audit
   ```
5. Report any vulnerabilities found
6. Suggest fixes for any high/critical vulnerabilities

**Quality Requirements:**
- All dependencies installed successfully
- No high or critical vulnerabilities (or documented exceptions)

Reference the **dependency-security** skill.
