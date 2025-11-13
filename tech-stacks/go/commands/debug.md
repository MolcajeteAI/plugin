---
description: Debug tests or application
---

# Debug Tests or Application

Debug failing tests or runtime issues.

Use the Task tool to launch the **debugger** agent with instructions:

1. Ask user what to debug (tests, specific function, runtime issue)
2. If tests:
   - Run with verbose output: `go test -v`
   - Run with race detector if concurrent: `go test -race -v`
   - Run specific test: `go test -v -run TestName`
3. Analyze error messages and stack traces
4. Check for common issues:
   - Race conditions
   - Nil pointer dereferences
   - Goroutine leaks
   - Deadlocks
5. Provide diagnosis and specific fix recommendations

**Debugging Tools:**
- Verbose test output (`-v`)
- Race detector (`-race`)
- Goroutine profiling
- Stack traces
- Log analysis

Reference the concurrency-patterns and error-handling skills.
