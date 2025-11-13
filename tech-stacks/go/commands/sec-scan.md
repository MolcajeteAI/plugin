---
description: Run security scanners
---

# Security Scan

Run comprehensive security analysis.

Use the Task tool to launch the **security** agent with instructions:

1. Run gosec for security issues: `gosec ./...`
2. Run govulncheck for vulnerabilities: `govulncheck ./...`
3. Collect and categorize findings
4. Prioritize issues by severity (Critical, High, Medium, Low)
5. Generate security report
6. Recommend fixes for each issue
7. Suggest prevention strategies

**Security Checks:**
- SQL injection
- Command injection
- Path traversal
- Weak cryptography
- Hardcoded secrets
- Insecure randomness
- Known vulnerabilities

Reference the security-scanning and secure-coding skills.
