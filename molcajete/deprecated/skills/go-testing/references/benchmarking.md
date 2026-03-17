# Benchmarking in Go

## Basic Benchmark

```go
func BenchmarkFibonacci(b *testing.B) {
    for b.Loop() {
        Fibonacci(20)
    }
}
```

### Running Benchmarks

```bash
# Run all benchmarks in a package
go test -bench=. ./internal/parser/

# Run specific benchmark
go test -bench=BenchmarkFibonacci ./internal/parser/

# With memory allocation stats
go test -bench=. -benchmem ./internal/parser/

# Run benchmarks without tests
go test -bench=. -run=^$ ./internal/parser/
```

### Reading Results

```
BenchmarkFibonacci-8    312750    3821 ns/op    0 B/op    0 allocs/op
```

- `BenchmarkFibonacci-8` — Name and GOMAXPROCS.
- `312750` — Iterations run.
- `3821 ns/op` — Nanoseconds per operation.
- `0 B/op` — Bytes allocated per operation (with `-benchmem`).
- `0 allocs/op` — Allocations per operation (with `-benchmem`).

## Memory Benchmarks

Always use `-benchmem` to track allocations. Allocations often matter more than raw speed.

```go
func BenchmarkBuildResponse(b *testing.B) {
    data := generateTestData()
    b.ResetTimer() // don't measure setup

    for b.Loop() {
        BuildResponse(data)
    }
}
```

### Reducing Allocations

```go
// ❌ Allocates on every call
func Join(parts []string) string {
    result := ""
    for _, p := range parts {
        result += p + ","
    }
    return result
}

// ✅ Pre-allocate with strings.Builder
func Join(parts []string) string {
    var b strings.Builder
    b.Grow(estimatedSize(parts))
    for i, p := range parts {
        if i > 0 {
            b.WriteByte(',')
        }
        b.WriteString(p)
    }
    return b.String()
}
```

## Sub-Benchmarks

Compare different implementations or input sizes.

```go
func BenchmarkSort(b *testing.B) {
    sizes := []int{10, 100, 1000, 10000}

    for _, size := range sizes {
        data := generateRandomSlice(size)

        b.Run(fmt.Sprintf("stdlib-%d", size), func(b *testing.B) {
            for b.Loop() {
                s := make([]int, len(data))
                copy(s, data)
                sort.Ints(s)
            }
        })

        b.Run(fmt.Sprintf("slices-%d", size), func(b *testing.B) {
            for b.Loop() {
                s := make([]int, len(data))
                copy(s, data)
                slices.Sort(s)
            }
        })
    }
}
```

### Output

```
BenchmarkSort/stdlib-10-8      5000000    240 ns/op
BenchmarkSort/stdlib-100-8      500000   3200 ns/op
BenchmarkSort/stdlib-1000-8      30000  42000 ns/op
BenchmarkSort/slices-10-8      6000000    190 ns/op
BenchmarkSort/slices-100-8      600000   2800 ns/op
BenchmarkSort/slices-1000-8      35000  38000 ns/op
```

## benchstat — Statistical Comparison

### Workflow

```bash
# 1. Baseline — run benchmark 10 times
go test -bench=BenchmarkSort -count=10 ./... > old.txt

# 2. Make your optimization changes

# 3. After — run benchmark 10 times
go test -bench=BenchmarkSort -count=10 ./... > new.txt

# 4. Compare
benchstat old.txt new.txt
```

### Reading benchstat Output

```
name          old time/op  new time/op  delta
Sort/100-8    3.20µs ± 2%  2.80µs ± 1%  -12.50%  (p=0.000 n=10+10)
Sort/1000-8   42.0µs ± 3%  38.0µs ± 2%   -9.52%  (p=0.000 n=10+10)
```

- **±** — Standard deviation. High variance (>5%) means results are noisy.
- **delta** — Percentage change. Negative means faster.
- **p-value** — Statistical significance. `p=0.000` means the difference is real.
- **n=10+10** — Samples used from each run.

### Install benchstat

```bash
go install golang.org/x/perf/cmd/benchstat@latest
```

### Rules for Reliable Benchmarks

- **Run at least `-count=10`** — Single runs are too noisy.
- **Close other programs** — Background processes add noise.
- **Use consistent hardware** — Don't compare results across different machines.
- **Use `b.ResetTimer()`** — After expensive setup that shouldn't be measured.
- **Use `b.StopTimer()` / `b.StartTimer()`** — For per-iteration setup.

## Benchmark with Setup

```go
func BenchmarkProcessLargeFile(b *testing.B) {
    // Expensive setup — not measured
    data, err := os.ReadFile("testdata/large.json")
    if err != nil {
        b.Fatal(err)
    }
    b.ResetTimer()

    for b.Loop() {
        ProcessJSON(data)
    }
}
```

### Per-Iteration Setup

```go
func BenchmarkShuffle(b *testing.B) {
    original := generateSlice(10000)

    for b.Loop() {
        b.StopTimer()
        data := make([]int, len(original))
        copy(data, original)
        b.StartTimer()

        Shuffle(data)
    }
}
```

## Benchmark Anti-Patterns

### Compiler Optimization

```go
// ❌ Compiler might optimize away the result
func BenchmarkHash(b *testing.B) {
    for b.Loop() {
        Hash("hello") // result unused — compiler may eliminate
    }
}

// ✅ Use the result to prevent optimization
var benchResult string

func BenchmarkHash(b *testing.B) {
    var r string
    for b.Loop() {
        r = Hash("hello")
    }
    benchResult = r
}
```

### Not Resetting Timer

```go
// ❌ Setup time included in measurement
func BenchmarkProcess(b *testing.B) {
    db := connectToDatabase() // expensive!
    for b.Loop() {
        Process(db)
    }
}

// ✅ Reset timer after setup
func BenchmarkProcess(b *testing.B) {
    db := connectToDatabase()
    b.ResetTimer()
    for b.Loop() {
        Process(db)
    }
}
```

### Single Run Comparison

```bash
# ❌ One run per change — meaningless
go test -bench=. ./... > before.txt
go test -bench=. ./... > after.txt

# ✅ Multiple runs for statistical significance
go test -bench=. -count=10 ./... > before.txt
go test -bench=. -count=10 ./... > after.txt
benchstat before.txt after.txt
```
