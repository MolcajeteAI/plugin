---
description: Run tests with race detector
---

# Run Tests with Race Detector

Execute tests with Go's race detector to catch concurrency issues.

Use the Task tool to launch the **tester** agent with instructions:

1. Run `make test-race` (or `go test -race -v ./...`)
2. Show test results
3. Display any race conditions detected
4. Explain race condition issues if found
5. Suggest fixes for race conditions

**Note:** Race detector is essential for detecting concurrent access issues.

Reference the testing-patterns and concurrency-patterns skills.
