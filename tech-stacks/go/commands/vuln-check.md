---
description: Check for vulnerable dependencies
---

# Check Vulnerabilities

Check dependencies for known vulnerabilities.

Use the Task tool to launch the **security** agent with instructions:

1. Run `govulncheck ./...`
2. Display vulnerabilities found in dependencies
3. Show vulnerability details (CVE, severity, affected versions)
4. Recommend updates or mitigations
5. Check if vulnerabilities are actually used in code
6. Suggest dependency updates

**Note:** govulncheck only reports vulnerabilities in code paths that are actually used.

Reference the security-scanning skill.
