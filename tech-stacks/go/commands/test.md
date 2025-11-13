---
description: Run test suite with coverage
---

# Run Tests

Execute the test suite with optional race detection and coverage.

Use the Task tool to launch the **tester** agent with instructions:

1. Run `make test` (or `go test -v ./...` if no Makefile)
2. Show test results with pass/fail counts
3. Display any failing test details
4. Optionally run with race detector (`make test-race`)
5. Generate coverage report if requested (`make coverage`)
6. Show coverage percentage
7. Suggest improvements if coverage is low

Reference the testing-patterns and coverage-analysis skills.
