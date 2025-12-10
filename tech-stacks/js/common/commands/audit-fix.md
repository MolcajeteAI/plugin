---
description: Auto-fix vulnerabilities
model: haiku
---

# Auto-Fix Vulnerabilities

Automatically fix known vulnerabilities when safe to do so.

Execute the following command:

```bash
npm audit fix
```

**For more aggressive fixes (may include breaking changes):**
```bash
npm audit fix --force
```

**What it does:**
- Updates vulnerable packages to patched versions
- Respects semver constraints by default
- `--force` flag allows major version updates

**After fixing:**
1. Run tests: `npm test`
2. Verify application works correctly
3. Review any breaking changes
4. Commit the updated `package-lock.json`

**Manual fixes may be required for:**
- Vulnerabilities with no patch available
- Breaking changes that need code updates
- Transitive dependencies

Reference the **dependency-security** skill.
