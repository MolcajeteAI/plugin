---
name: go-writing-code
description: >-
  This skill should be used when writing, reviewing, or refactoring Go code. It
  covers Go idioms, error handling, concurrency patterns, project structure, API
  patterns (HTTP, gRPC, GraphQL), security practices, documentation standards,
  and mandatory post-change verification.
---

# Go Writing Code

Quick reference for writing idiomatic, production-quality Go code. Each section summarizes the key rules — reference files provide full examples and edge cases.

## Go Code Idioms

### Naming

- **MixedCaps** — Go uses `MixedCaps` or `mixedCaps`, never underscores. Exported names start with uppercase.
- **Short names for short scopes** — `i` for loop index, `r` for reader, `ctx` for context. Longer names for longer scopes.
- **Package names** — Lowercase, single word, no underscores. The package name is part of the API: `http.Client`, not `http.HTTPClient`.
- **Interface names** — Single-method interfaces use method name + `er` suffix: `Reader`, `Writer`, `Stringer`.
- **Acronyms** — All caps: `HTTPClient`, `userID`, `xmlParser`.

### Core Idioms

- **Accept interfaces, return structs** — Functions take narrow interfaces as parameters and return concrete types. This maximizes flexibility for callers while keeping implementations concrete.
- **Context first** — `ctx context.Context` is always the first parameter. Never store context in structs.
- **Zero values are useful** — Design types so the zero value is ready to use. `sync.Mutex{}` works without initialization. `bytes.Buffer{}` is an empty buffer ready for writes.
- **Make the zero value useful** — If a type cannot have a useful zero value, provide a constructor: `NewServer(opts...)`.
- **Functional options** — Use the functional options pattern for configurable constructors instead of config structs with many fields.

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080} // sensible defaults
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

- **Small interfaces** — Prefer 1-2 method interfaces. Compose larger interfaces from smaller ones.
- **Embedding for composition** — Embed types to compose behavior, not to simulate inheritance.

## Error Handling

Go errors are values. Handle them explicitly — never ignore them.

### Rules

1. **Always check errors** — Every error return must be handled. Use `_` only when you explicitly document why.
2. **Wrap with context** — Use `fmt.Errorf("operation failed: %w", err)` to add context while preserving the error chain.
3. **Sentinel errors** — Define package-level errors for expected conditions: `var ErrNotFound = errors.New("not found")`.
4. **Check with `errors.Is` and `errors.As`** — Never compare error strings. Use `errors.Is(err, ErrNotFound)` or `errors.As(err, &target)`.
5. **Don't panic** — Reserve `panic` for truly unrecoverable situations (programmer errors, impossible states). Never panic in library code.
6. **Custom error types** — Implement the `error` interface for errors that carry structured data (status codes, field names).

```go
// Sentinel error
var ErrUserNotFound = errors.New("user not found")

// Wrapping with context
user, err := repo.FindByID(ctx, id)
if err != nil {
    return fmt.Errorf("finding user %s: %w", id, err)
}

// Checking wrapped errors
if errors.Is(err, ErrUserNotFound) {
    return nil, status.Error(codes.NotFound, "user not found")
}
```

See [references/error-handling.md](./references/error-handling.md) for sentinel error patterns, errgroup usage, and custom error types.

## Concurrency

Go's concurrency primitives are powerful but require discipline to use safely.

### Rules

1. **Start goroutines with clear ownership** — Every goroutine must have a clear owner responsible for its lifecycle.
2. **Use context for cancellation** — Pass `context.Context` to all goroutines. Check `ctx.Done()` in long-running loops.
3. **Channels for communication, mutexes for state** — Use channels to pass data between goroutines. Use `sync.Mutex` to protect shared state.
4. **Always prevent goroutine leaks** — Every goroutine must have a way to terminate. Use `context.WithCancel`, `context.WithTimeout`, or channel signaling.
5. **Prefer `sync.WaitGroup` for fan-out** — Use `WaitGroup` when launching multiple goroutines and waiting for all to complete.
6. **Use `errgroup.Group` for error propagation** — When any goroutine failure should cancel the rest.

```go
g, ctx := errgroup.WithContext(ctx)
for _, item := range items {
    g.Go(func() error {
        return process(ctx, item)
    })
}
if err := g.Wait(); err != nil {
    return fmt.Errorf("processing items: %w", err)
}
```

See [references/concurrency.md](./references/concurrency.md) for worker pools, fan-out/fan-in, sync primitives, and common pitfalls.

## Project Structure

### Standard Layout

```
project/
├── cmd/
│   └── server/
│       └── main.go          # Entry point, wiring only
├── internal/                 # Private application code
│   ├── config/              # Configuration loading
│   ├── handler/             # HTTP/gRPC handlers
│   ├── service/             # Business logic
│   ├── repository/          # Data access
│   └── model/               # Domain types
├── pkg/                      # Public library code (if any)
├── migrations/              # Database migrations
├── Makefile                 # Build, test, lint commands
├── go.mod
└── go.sum
```

### Rules

- **`internal/` for application code** — Everything the application needs, nothing external should import.
- **`cmd/` for entry points** — Minimal code. Wire dependencies and start the server.
- **`pkg/` only when needed** — Only for code genuinely intended for external consumption. Most projects don't need `pkg/`.
- **Flat within reason** — Don't create deep nesting. A package with 5-10 files is fine.
- **One `main.go` per binary** — Each binary gets its own directory under `cmd/`.

See [references/project-structure.md](./references/project-structure.md) for hexagonal architecture, flat structure, and when to choose each.

## API Patterns

### HTTP Handlers (Chi Router)

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    user, err := h.service.FindByID(r.Context(), id)
    if err != nil {
        h.respondError(w, r, err)
        return
    }
    h.respondJSON(w, r, http.StatusOK, user)
}
```

### Middleware

Chain middleware for cross-cutting concerns: logging, auth, rate limiting, CORS, request ID.

```go
r := chi.NewRouter()
r.Use(middleware.RequestID)
r.Use(middleware.Logger)
r.Use(middleware.Recoverer)
r.Use(corsMiddleware)
r.Use(authMiddleware)
```

### GraphQL Resolver Delegation (gqlgen)

Resolver files are regenerated by gqlgen. Never put implementation logic in resolver files — delegate to helper functions.

```go
// user.resolvers.go — generated, delegation only
func (r *queryResolver) Viewer(ctx context.Context) (*model.Viewer, error) {
    return r.resolveViewer(ctx)
}

// user_helpers.go — all implementation
func (r *queryResolver) resolveViewer(ctx context.Context) (*model.Viewer, error) {
    userID, err := auth.UserIDFromContext(ctx)
    if err != nil {
        return nil, err
    }
    return r.service.GetViewer(ctx, userID)
}
```

See [references/api-patterns.md](./references/api-patterns.md) for middleware patterns, gRPC service definitions, error response conventions, and GraphQL best practices.

## Transactions

For multi-service operations that need atomicity, use the context-propagated transaction pattern: `DBExecutor` interface + transaction-in-context + lifecycle hooks (`OnCommit`/`OnRevert`/`OnError`).

See [references/transactions.md](./references/transactions.md) for the full pattern, implementation, and multi-service examples.

## Security

### Input Validation

- Validate all external input at system boundaries (HTTP handlers, GraphQL resolvers).
- Use strong typing — parse into domain types early, pass typed values internally.
- Validate length, format, and range. Reject invalid input with clear error messages.

### SQL Injection Prevention

- **Always use parameterized queries** — Never concatenate user input into SQL strings.
- Use `$1, $2` placeholders (pgx) or `?` placeholders (database/sql).

```go
// ✅ Correct — parameterized
row := db.QueryRow(ctx, "SELECT * FROM users WHERE id = $1", userID)

// ❌ Wrong — string concatenation
row := db.QueryRow(ctx, "SELECT * FROM users WHERE id = " + userID)
```

### Secrets Management

- Never hardcode secrets. Use environment variables or a secrets manager.
- Use bcrypt for password hashing (`golang.org/x/crypto/bcrypt`).
- Encrypt PII at rest. Use SHA-256 hashes for indexed lookups on encrypted fields.

See [references/security.md](./references/security.md) for CORS configuration, bcrypt usage, and encryption patterns.

## Documentation

Follow godoc conventions:

- **Package comments** — First sentence is a summary. Start with `// Package <name> ...`.
- **Exported names** — Comment every exported type, function, constant. Start with the name: `// Server represents...`.
- **Examples** — Write `Example` test functions for complex APIs. They serve as both docs and tests.
- **No stutter** — `http.Server` comment says "Server represents...", not "HTTPServer represents...".

```go
// Package auth provides JWT-based authentication and authorization.
package auth

// Token represents a signed JWT access token with its expiration time.
type Token struct {
    Value     string
    ExpiresAt time.Time
}

// NewToken creates a signed JWT token for the given user ID.
// The token expires after the configured TTL.
func NewToken(userID string, ttl time.Duration) (*Token, error) {
```

## Post-Change Verification (MANDATORY)

After every code change, run this 5-step verification. No exceptions.

### The 5 Steps

```bash
# 1. Format
gofmt -w .
# or: make fmt

# 2. Lint
golangci-lint run ./...
# or: make lint

# 3. Vet
go vet ./...
# or: make vet

# 4. Build
go build ./...
# or: make build

# 5. Test
go test -race ./...
# or: make test
```

### Rules

- **All 5 steps must pass** before considering a change complete.
- **Fix issues immediately** — Don't defer lint warnings or test failures.
- **Run with `-race`** — The race detector catches data races that tests alone miss.
- **Use the Makefile** — Projects must have a Makefile with `fmt`, `lint`, `vet`, `build`, `test` targets.

See [references/post-change-protocol.md](./references/post-change-protocol.md) for the full verification workflow and troubleshooting.

## Code Quality Rules

### YAGNI/KISS in Go

- **No unused abstractions** — Don't create interfaces until you have two implementations. Don't create packages for a single file.
- **No wrapper proliferation** — Avoid wrapping standard library types without adding real value. A `StringSlice` type that just wraps `[]string` adds complexity without benefit.
- **Direct is better** — Call functions directly instead of routing through unnecessary layers. `repo.FindUser(ctx, id)` is better than `service.GetUser(ctx, id)` that just calls `repo.FindUser(ctx, id)`.
- **Flat packages** — Avoid deeply nested package hierarchies. Prefer a flat structure within `internal/`.

### Makefile Required

Every Go project must have a Makefile with at minimum:

```makefile
.PHONY: build run test fmt lint vet generate

build:
	go build -o bin/app ./cmd/server

run: build
	./bin/app

test:
	go test -race -cover ./...

fmt:
	gofmt -w .

lint:
	golangci-lint run ./...

vet:
	go vet ./...

generate:
	go generate ./...
```

### Performance

- **Profile before optimizing** — Use `pprof` to identify bottlenecks. Never optimize without data.
- **Benchmark before and after** — Use `go test -bench` to measure optimization impact.
- **Allocations matter** — Reduce allocations in hot paths. Use `sync.Pool` for frequently allocated objects. Pre-allocate slices with `make([]T, 0, capacity)`.

## Reference Files

| File | Description |
|---|---|
| [references/error-handling.md](./references/error-handling.md) | Sentinel errors, wrapping patterns, errgroup, custom error types |
| [references/concurrency.md](./references/concurrency.md) | Worker pools, fan-out/fan-in, sync primitives, goroutine leak prevention |
| [references/patterns.md](./references/patterns.md) | Functional options, interface composition, builder pattern |
| [references/project-structure.md](./references/project-structure.md) | Standard layout, hexagonal architecture, flat structure |
| [references/api-patterns.md](./references/api-patterns.md) | HTTP handlers, middleware, gRPC services, GraphQL resolver delegation |
| [references/security.md](./references/security.md) | Input validation, SQL injection prevention, bcrypt, CORS, encryption |
| [references/transactions.md](./references/transactions.md) | Context-propagated transactions, DBExecutor, lifecycle hooks, multi-service atomicity |
| [references/post-change-protocol.md](./references/post-change-protocol.md) | Mandatory 5-step verification workflow |
