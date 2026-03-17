# Post-Change Verification Protocol

## The 5 Steps (MANDATORY)

Every Go code change must pass all 5 steps before it is considered complete. No exceptions.

```bash
# Step 1: Format
gofmt -w .
# or: make fmt

# Step 2: Lint
golangci-lint run ./...
# or: make lint

# Step 3: Vet
go vet ./...
# or: make vet

# Step 4: Build
go build ./...
# or: make build

# Step 5: Test
go test -race ./...
# or: make test
```

## Why This Order

1. **Format first** — Ensures code is readable before any analysis.
2. **Lint second** — Catches style issues and common mistakes that vet might miss.
3. **Vet third** — Finds subtle bugs (printf format mismatches, unreachable code, mutex copy).
4. **Build fourth** — Confirms compilation succeeds before running tests.
5. **Test last** — Validates behavior with the race detector enabled.

## Zero Tolerance Policy

- **All steps must pass** — A lint warning is a failure. A test skip is acceptable only when documented.
- **Fix immediately** — Don't defer issues to "clean up later." Fix them now.
- **No suppression** — Don't add `//nolint` or `//go:nosplit` to bypass checks unless there's a documented, justified reason.

## Makefile Integration

Every Go project must have a Makefile with these targets:

```makefile
.PHONY: fmt lint vet build test check

fmt:
	gofmt -w .

lint:
	golangci-lint run ./...

vet:
	go vet ./...

build:
	go build -o bin/app ./cmd/server

test:
	go test -race -cover ./...

# Run all checks in sequence
check: fmt lint vet build test
```

### One-Command Verification

```bash
make check
```

This runs all 5 steps in order. If any step fails, the chain stops.

## Troubleshooting

### Format Issues

```bash
# Check what would change (dry run)
gofmt -d .

# Format specific files
gofmt -w internal/service/user.go
```

### Lint Failures

```bash
# Run specific linters
golangci-lint run --enable=errcheck ./...

# Show more context
golangci-lint run --out-format=line-number ./...

# List enabled linters
golangci-lint linters
```

### Vet Warnings

Common vet warnings:
- **printf format mismatch** — `%d` with a string argument.
- **unreachable code** — Code after a `return` statement.
- **mutex copied** — Passing a mutex by value instead of pointer.
- **struct tag format** — Malformed JSON/XML struct tags.

### Test Failures

```bash
# Run a specific failing test
go test -run TestSpecificName -v ./internal/service/...

# Run with verbose output for debugging
go test -race -v -count=1 ./...

# Run only short tests (skip integration)
go test -short ./...
```

### Race Detector Failures

The `-race` flag in step 5 may catch data races that pass without it.

```bash
# Run with race detector and verbose output
go test -race -v ./internal/service/...

# Build and run binary with race detector
go build -race -o bin/app-race ./cmd/server
./bin/app-race
```

Common race fixes:
- Add `sync.Mutex` protection for shared state.
- Use channels instead of shared variables.
- Use `sync.Map` for concurrent map access.
- Use `atomic` operations for simple counters.
