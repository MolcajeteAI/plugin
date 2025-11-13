---
description: Run linters
---

# Run Linters

Run golangci-lint to check code quality.

Use the Task tool to launch the **developer** agent with instructions:

1. Check if golangci-lint is installed
2. Run `make lint` (or `golangci-lint run`)
3. Display linting issues by category
4. Suggest fixes for common issues
5. Explain lint errors if unclear

**Common Linters:**
- gofmt, goimports (formatting)
- govet (suspicious constructs)
- errcheck (unchecked errors)
- staticcheck (advanced analysis)
- gosec (security issues)

Reference the code-quality skill.
