---
name: performance-profiling
description: pprof usage and performance analysis. Use when profiling applications.
---

# Performance Profiling Skill

Using pprof for performance analysis.

## When to Use

Use when identifying performance bottlenecks.

## CPU Profiling

```bash
# During tests
go test -cpuprofile=cpu.out -bench=.

# Analyze
go tool pprof cpu.out

# Web interface
go tool pprof -http=:8080 cpu.out
```

## Memory Profiling

```bash
# During tests
go test -memprofile=mem.out -bench=.

# Analyze
go tool pprof mem.out
```

## HTTP Endpoint

```go
import _ "net/http/pprof"

func main() {
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
    // your code
}
```

Access profiles at:
- `http://localhost:6060/debug/pprof/`
- `http://localhost:6060/debug/pprof/heap`
- `http://localhost:6060/debug/pprof/goroutine`

## pprof Commands

```
(pprof) top      # Top functions
(pprof) list     # Source code view
(pprof) web      # Graph view
(pprof) pdf      # PDF output
```

## Best Practices

- Profile in production-like conditions
- Profile before optimizing
- Focus on hot paths
- Check both CPU and memory
- Use flamegraphs for visualization
