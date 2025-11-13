---
description: Run benchmarks
---

# Run Benchmarks

Execute performance benchmarks.

Use the Task tool to launch the **tester** agent with instructions:

1. Run `go test -bench=. -benchmem ./...`
2. Display benchmark results (iterations, time, memory)
3. If previous results exist, compare using benchstat
4. Identify performance regressions
5. Suggest areas for optimization if needed

**Benchmark Output:**
- ns/op - Nanoseconds per operation
- B/op - Bytes allocated per operation
- allocs/op - Allocations per operation

Reference the benchmarking skill.
