---
description: Check dependency licenses
---

# Check Dependency Licenses

Verify all dependency licenses are compatible with the project.

Use the Task tool to launch the **security** agent with instructions:

1. Run license checker:
   ```bash
   npx license-checker --summary
   ```

2. Check for problematic licenses:
   ```bash
   npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense"
   ```

3. Generate detailed report if issues found:
   ```bash
   npx license-checker --json > licenses.json
   ```

4. Report findings:
   - List of all licenses used
   - Any licenses requiring attention (GPL, LGPL, AGPL)
   - Any unknown or missing licenses

**Safe Licenses (Permissive):**
- MIT
- Apache-2.0
- BSD-2-Clause
- BSD-3-Clause
- ISC
- 0BSD
- Unlicense

**Requires Review (Copyleft):**
- GPL-2.0, GPL-3.0
- LGPL-2.1, LGPL-3.0
- AGPL-3.0
- MPL-2.0

Reference the **license-compliance** skill.
