---
name: benchmarking
description: Performance benchmarking techniques and analysis. Use when measuring performance.
---

# Benchmarking Skill

Performance benchmarking techniques for Go.

## When to Use

Use when measuring or comparing performance.

## Writing Benchmarks

```go
func BenchmarkGetUser(b *testing.B) {
    svc := NewService()
    ctx := context.Background()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, _ = svc.GetUser(ctx, 1)
    }
}
```

## Running Benchmarks

```bash
# Run all benchmarks
go test -bench=. -benchmem ./...

# Specific benchmark
go test -bench=BenchmarkGetUser -benchmem

# Multiple runs for accuracy
go test -bench=. -benchmem -count=10
```

## Analyzing Results

```
BenchmarkGetUser-8    1000000    1250 ns/op    320 B/op    5 allocs/op
```

- `1000000` - iterations
- `1250 ns/op` - time per operation
- `320 B/op` - bytes allocated
- `5 allocs/op` - allocations per operation

## Comparing with benchstat

```bash
go test -bench=. -count=10 > old.txt
# make changes
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

## Best Practices

- Use `b.ResetTimer()` after setup
- Run multiple times (`-count`)
- Use `benchstat` for comparison
- Focus on allocations
- Profile to understand results
