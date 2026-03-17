---
name: go-testing
description: >-
  This skill should be used when writing, reviewing, or debugging Go tests. It
  covers table-driven tests, test organization, assertions, mocking patterns,
  coverage analysis, benchmarking, integration tests, race detection, and test
  quality standards.
---

# Go Testing

Quick reference for writing effective Go tests. Each section summarizes the key rules — reference files provide full examples and edge cases.

## Table-Driven Tests

The standard Go testing pattern. Use it for any function with multiple input/output combinations.

### Basic Pattern

```go
func TestParseAge(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int
        wantErr bool
    }{
        {name: "valid age", input: "25", want: 25},
        {name: "zero", input: "0", want: 0},
        {name: "negative", input: "-1", wantErr: true},
        {name: "not a number", input: "abc", wantErr: true},
        {name: "empty string", input: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseAge(tt.input)
            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got != tt.want {
                t.Errorf("ParseAge(%q) = %d, want %d", tt.input, got, tt.want)
            }
        })
    }
}
```

### Rules

- **Name every test case** — Use the `name` field and `t.Run`. Makes failures easy to identify.
- **Cover edge cases** — Empty inputs, zero values, boundary values, error conditions.
- **Parallel when safe** — Add `t.Parallel()` to subtests when they don't share mutable state.
- **One concept per table** — Don't mix unrelated test scenarios in the same table.

See [references/table-driven-tests.md](./references/table-driven-tests.md) for parallel subtests, cleanup, golden files, and advanced patterns.

## Test Organization

### File Structure

Place tests in a `_test.go` file in the same package:

```
internal/service/
├── user.go
├── user_test.go        # Same package (white-box)
└── user_export_test.go # _test package (black-box, optional)
```

### Naming Conventions

- **Test files** — `<source>_test.go` in the same directory.
- **Test functions** — `Test<FunctionName>` or `Test<Type>_<Method>`.
- **Subtests** — Descriptive names: `"valid email"`, `"empty input"`, `"duplicate key"`.
- **Test helpers** — Prefix with `test` or put in a `testutil` package. Call `t.Helper()` in every test helper.

```go
func newTestUser(t *testing.T, name string) *User {
    t.Helper()
    u, err := NewUser(name, "test@example.com")
    if err != nil {
        t.Fatalf("creating test user: %v", err)
    }
    return u
}
```

### TestMain

Use `TestMain` for package-level setup/teardown (database connections, test servers):

```go
func TestMain(m *testing.M) {
    // Setup
    db := setupTestDB()
    defer db.Close()

    // Run tests
    os.Exit(m.Run())
}
```

## Assertions

### Standard Library (Preferred)

Go's testing package uses explicit comparisons. This keeps tests readable and avoids assertion library dependencies.

```go
if got != want {
    t.Errorf("Add(%d, %d) = %d, want %d", a, b, got, want)
}
```

### When to Use testify

Use `testify` when it significantly improves readability, especially for:
- Deep struct comparison: `assert.Equal(t, want, got)`
- Slice/map comparison: `assert.ElementsMatch(t, want, got)`
- Error checking: `require.NoError(t, err)` (stops test on failure)

### require vs assert

- **`require`** — Stops the test immediately on failure. Use for preconditions and setup steps.
- **`assert`** — Records failure but continues. Use for the actual assertions when you want to see all failures.

```go
func TestCreateUser(t *testing.T) {
    // Preconditions — stop if these fail
    db, err := setupTestDB(t)
    require.NoError(t, err)

    user, err := CreateUser(db, "alice")
    require.NoError(t, err)

    // Assertions — check all properties
    assert.Equal(t, "alice", user.Name)
    assert.NotEmpty(t, user.ID)
    assert.WithinDuration(t, time.Now(), user.CreatedAt, time.Second)
}
```

## Mocking

### Interface-Based Mocks

Define small interfaces at the consumer site, then create test implementations:

```go
// In production code
type UserStore interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// In test code
type mockUserStore struct {
    findByIDFn func(ctx context.Context, id string) (*User, error)
}

func (m *mockUserStore) FindByID(ctx context.Context, id string) (*User, error) {
    return m.findByIDFn(ctx, id)
}
```

### httptest

Use `httptest.NewServer` for HTTP client testing and `httptest.NewRecorder` for handler testing:

```go
func TestGetUser(t *testing.T) {
    rec := httptest.NewRecorder()
    req := httptest.NewRequest("GET", "/users/123", nil)

    handler := NewHandler(mockStore)
    handler.GetUser(rec, req)

    assert.Equal(t, http.StatusOK, rec.Code)
}
```

### Database Testing

- Use a real test database when possible — mocking SQL gives false confidence.
- Use transactions that roll back: start a transaction in setup, rollback in cleanup.
- Use `testcontainers-go` for disposable Postgres instances in CI.

See [references/mocking.md](./references/mocking.md) for mock generation, test doubles taxonomy, and database testing patterns.

## Coverage Analysis

### Running Coverage

```bash
# Basic coverage
go test -cover ./...

# Generate HTML report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Coverage for specific package
go test -cover ./internal/service/...

# Show uncovered lines
go tool cover -func=coverage.out
```

### Coverage Targets

| Level | Range | Meaning |
|---|---|---|
| Good | 70–80% | Solid coverage for most projects |
| Excellent | 80–90% | Strong confidence in code correctness |
| Diminishing returns | 90%+ | Only pursue for critical paths |

### What NOT to Test

- Generated code (protobuf, gqlgen resolvers)
- Trivial getters/setters
- `main.go` wiring code
- Third-party library internals

See [references/coverage.md](./references/coverage.md) for CI integration, coverage gates, and per-package analysis.

## Benchmarking

### Basic Pattern

```go
func BenchmarkParseAge(b *testing.B) {
    for b.Loop() {
        ParseAge("25")
    }
}
```

### Running Benchmarks

```bash
# Run all benchmarks
go test -bench=. ./...

# With memory allocation stats
go test -bench=. -benchmem ./...

# Specific benchmark
go test -bench=BenchmarkParseAge -benchmem ./internal/parser/

# Compare results with benchstat
go test -bench=. -count=10 ./... > old.txt
# ... make changes ...
go test -bench=. -count=10 ./... > new.txt
benchstat old.txt new.txt
```

### Rules

- **Always use `-benchmem`** — Allocation counts matter as much as speed.
- **Run multiple times** — Use `-count=10` for reliable results. Single runs are noisy.
- **Use `benchstat`** — Compare before/after with statistical confidence.
- **Benchmark hot paths** — Focus on code that runs frequently, not cold paths.
- **Reset timer for setup** — Use `b.ResetTimer()` after expensive setup that shouldn't be measured.

See [references/benchmarking.md](./references/benchmarking.md) for memory benchmarks, sub-benchmarks, and benchstat workflow.

## Integration Tests

### Naming Convention

Use build tags or `_integration_test.go` suffix to separate from unit tests:

```go
//go:build integration

package service_test

func TestUserService_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    // ...
}
```

### Database Integration Tests

```go
func TestUserRepository_Create(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    db := testutil.NewTestDB(t) // starts container, runs migrations
    repo := NewUserRepository(db)

    user, err := repo.Create(ctx, "alice", "alice@example.com")
    require.NoError(t, err)
    assert.NotEmpty(t, user.ID)

    // Verify persisted
    found, err := repo.FindByID(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, "alice", found.Name)
}
```

### API Integration Tests

Test the full HTTP stack with `httptest.NewServer`:

```go
func TestAPI_CreateUser(t *testing.T) {
    srv := httptest.NewServer(setupRouter())
    defer srv.Close()

    resp, err := http.Post(srv.URL+"/users", "application/json",
        strings.NewReader(`{"name":"alice"}`))
    require.NoError(t, err)
    defer resp.Body.Close()

    assert.Equal(t, http.StatusCreated, resp.StatusCode)
}
```

## Race Detection

### Usage

```bash
# Always run tests with race detector
go test -race ./...

# Build with race detector for manual testing
go build -race ./cmd/server
```

### Common Race Conditions

- **Unsynchronized map access** — Maps are not safe for concurrent use. Use `sync.RWMutex` or `sync.Map`.
- **Shared slice append** — Multiple goroutines appending to the same slice. Pre-allocate or use a mutex.
- **Check-then-act** — Reading a value, making a decision, then acting — the value may have changed.
- **Closure over loop variable** — Pre Go 1.22: goroutines capturing loop variables. Fixed in Go 1.22+ but be aware when supporting older versions.

### Rules

- **Run `-race` in CI** — Always. It's a hard requirement, not optional.
- **Fix all race conditions** — Zero tolerance. A race is a bug, even if tests pass without it.
- **Test concurrent code explicitly** — Launch multiple goroutines in tests to stress concurrent paths.

## Test Quality

### FIRST Principles

- **Fast** — Unit tests run in milliseconds. Full suite in under a minute.
- **Independent** — Tests don't depend on execution order or shared mutable state.
- **Repeatable** — Same result every time. No randomness, no external dependencies in unit tests.
- **Self-validating** — Clear pass/fail. No manual checking of output.
- **Timely** — Write tests alongside code, not as an afterthought.

### Anti-Patterns

- **Testing implementation details** — Assert on behavior, not internal method calls.
- **Flaky tests** — Tests that pass/fail randomly. Fix immediately — they erode trust.
- **Slow tests** — Unit tests taking seconds. Mock external dependencies or use `testing.Short()`.
- **Test interdependence** — Tests that fail when run in a different order.
- **Excessive mocking** — Mocking everything means you're testing mocks, not code.
- **No error path tests** — Only testing the happy path. Error handling is where bugs hide.

### Post-Change Verification

After writing or modifying tests, always run the full verification protocol from the `go-writing-code` skill:

```bash
make fmt && make lint && make vet && make build && make test
```

All 5 steps must pass. See `go-writing-code` skill for details.

## Reference Files

| File | Description |
|---|---|
| [references/table-driven-tests.md](./references/table-driven-tests.md) | Parallel subtests, cleanup, golden files, advanced patterns |
| [references/mocking.md](./references/mocking.md) | Interface mocks, httptest, test doubles, database testing |
| [references/coverage.md](./references/coverage.md) | Coverage commands, targets, CI integration, per-package analysis |
| [references/benchmarking.md](./references/benchmarking.md) | Benchmark patterns, benchstat, memory benchmarks, sub-benchmarks |
