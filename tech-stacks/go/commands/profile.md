---
description: Profile application performance
---

# Profile Application

Profile the application for CPU, memory, or goroutine usage.

Use the Task tool to launch the **optimizer** agent with instructions:

1. Ask user for profile type (CPU, memory, goroutine, block, mutex)
2. Run application/tests with profiling enabled
3. Generate profile data
4. Analyze profile with pprof
5. Display top functions by resource usage
6. Identify optimization opportunities
7. Suggest specific improvements

**Profile Commands:**
- CPU: `go test -cpuprofile=cpu.out -bench=.`
- Memory: `go test -memprofile=mem.out -bench=.`
- Analyze: `go tool pprof -http=:8080 cpu.out`

Reference the performance-profiling and optimization-techniques skills.
