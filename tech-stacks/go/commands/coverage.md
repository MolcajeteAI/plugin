---
description: Generate coverage report
---

# Generate Coverage Report

Generate and analyze test coverage.

Use the Task tool to launch the **tester** agent with instructions:

1. Run `make coverage` (or `go test -coverprofile=coverage.out ./...`)
2. Generate HTML coverage report: `go tool cover -html=coverage.out`
3. Display coverage percentage
4. Show uncovered lines/functions
5. Suggest areas to improve coverage
6. Open coverage report in browser if possible

Reference the coverage-analysis skill.
