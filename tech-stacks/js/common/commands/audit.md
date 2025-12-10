---
description: Security audit
---

# Security Audit

Scan dependencies for known vulnerabilities.

Use the Task tool to launch the **security** agent with instructions:

1. Run npm audit:
   ```bash
   npm audit
   ```

2. If Snyk is available, run:
   ```bash
   npx snyk test
   ```

3. If Socket.dev CLI is available, run:
   ```bash
   npx @socketsecurity/cli scan
   ```

4. Compile results into a report:
   - Number of vulnerabilities by severity
   - Affected packages
   - Available fixes
   - Recommended actions

**Severity Levels:**
- Critical: Immediate action required
- High: Fix within 24 hours
- Moderate: Fix within 1 week
- Low: Fix when convenient

**Quality Requirements:**
- No critical vulnerabilities
- No high vulnerabilities (or documented exceptions)

Reference the **dependency-security** skill.
