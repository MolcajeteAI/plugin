---
name: security-scanning
description: Security scanning tools (gosec, govulncheck). Use when running security analysis.
---

# Security Scanning Skill

Security scanning tools and usage for Go.

## When to Use

Use when performing security analysis or audits.

## gosec - Static Security Analysis

### Installation
```bash
go install github.com/securego/gosec/v2/cmd/gosec@latest
```

### Usage
```bash
# Scan all packages
gosec ./...

# JSON output
gosec -fmt=json -out=results.json ./...

# Specific rules
gosec -include=G401,G501 ./...
```

### Common Issues Detected

- G101: Hardcoded credentials
- G102: Bind to all interfaces
- G103: Unsafe block
- G104: Unhandled errors
- G201: SQL injection
- G202: SQL string concatenation
- G301: Poor file permissions
- G401: Weak cryptography (MD5, SHA1)
- G501: Blocklisted import (DES)

## govulncheck - Vulnerability Scanner

### Installation
```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
```

### Usage
```bash
# Scan for vulnerabilities
govulncheck ./...

# JSON output
govulncheck -json ./...
```

### What It Checks

- Known vulnerabilities in dependencies
- Only reports vulnerabilities in code paths actually used
- Uses official Go vulnerability database

## CI/CD Integration

```yaml
# GitHub Actions
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
      - name: Run Gosec
        run: |
          go install github.com/securego/gosec/v2/cmd/gosec@latest
          gosec ./...
      - name: Run govulncheck
        run: |
          go install golang.org/x/vuln/cmd/govulncheck@latest
          govulncheck ./...
```

## Best Practices

- Run in CI/CD pipeline
- Address Critical/High issues first
- Review false positives
- Keep dependencies updated
- Scan regularly (weekly minimum)
