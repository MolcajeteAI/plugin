# Coverage Analysis in Go

## Running Coverage

### Basic Coverage Report

```bash
# Show coverage percentage per package
go test -cover ./...

# Output:
# ok  internal/service    0.5s    coverage: 82.3% of statements
# ok  internal/handler    0.3s    coverage: 71.5% of statements
```

### Generate Coverage Profile

```bash
# Generate profile
go test -coverprofile=coverage.out ./...

# View in terminal (per-function breakdown)
go tool cover -func=coverage.out

# Generate HTML report
go tool cover -html=coverage.out -o coverage.html

# Open in browser
open coverage.html
```

### Per-Package Coverage

```bash
# Coverage for a specific package
go test -cover -coverprofile=coverage.out ./internal/service/...

# Coverage for multiple specific packages
go test -cover -coverprofile=coverage.out ./internal/service/... ./internal/handler/...
```

### Coverage Modes

```bash
# set (default) — did this statement run? (boolean)
go test -covermode=set -coverprofile=coverage.out ./...

# count — how many times did this statement run?
go test -covermode=count -coverprofile=coverage.out ./...

# atomic — like count, but safe for concurrent tests
go test -covermode=atomic -coverprofile=coverage.out ./...
```

Use `atomic` when running tests with `-race` or `t.Parallel()`.

## Coverage Targets

| Level | Range | When to Target |
|---|---|---|
| Good | 70–80% | Most application code |
| Excellent | 80–90% | Business-critical logic, financial calculations |
| Diminishing returns | 90%+ | Only for safety-critical or regulated code |

### Per-Code-Type Targets

| Code Type | Target | Notes |
|---|---|---|
| Business logic / services | 80–90% | Core value — test thoroughly |
| Repository / data access | 70–80% | Use integration tests with real DB |
| HTTP handlers | 60–80% | Test request parsing, response codes |
| Middleware | 70–80% | Test both pass-through and rejection |
| Configuration | 30–50% | Test validation, not file loading |
| Generated code | 0% | Exclude from coverage |

## What NOT to Test

Exclude these from coverage targets:

- **Generated code** — gqlgen resolvers, protobuf, wire.
- **`main.go` wiring** — Dependency injection and server startup.
- **Trivial getters/setters** — Single-line accessor methods.
- **Third-party library code** — Trust external dependencies to test themselves.
- **Dead code** — Delete it instead of testing it.

### Excluding Files from Coverage

```bash
# Exclude generated files by convention
go test -coverprofile=coverage.out ./... | grep -v '_gen.go'

# Or use build tags
//go:build !coverage
```

## CI Integration

### Coverage Gate in Makefile

```makefile
COVERAGE_THRESHOLD := 70

test-coverage:
	go test -race -coverprofile=coverage.out -covermode=atomic ./...
	@total=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | tr -d '%'); \
	echo "Total coverage: $$total%"; \
	if [ $$(echo "$$total < $(COVERAGE_THRESHOLD)" | bc) -eq 1 ]; then \
		echo "Coverage $$total% is below threshold $(COVERAGE_THRESHOLD)%"; \
		exit 1; \
	fi
```

### GitHub Actions Example

```yaml
- name: Run tests with coverage
  run: go test -race -coverprofile=coverage.out -covermode=atomic ./...

- name: Check coverage threshold
  run: |
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "Coverage below 70% threshold"
      exit 1
    fi
```

## Analyzing Coverage Gaps

### Find Uncovered Functions

```bash
go tool cover -func=coverage.out | grep '0.0%'
```

### Find Partially Covered Functions

```bash
go tool cover -func=coverage.out | awk -F'\t' '$NF != "100.0%" && $NF != "0.0%" {print}'
```

### HTML Report for Visual Inspection

The HTML report highlights:
- **Green** — Covered statements.
- **Red** — Uncovered statements.
- **Yellow** — Statements covered in some but not all code paths (with `-covermode=count`).

```bash
go test -coverprofile=coverage.out -covermode=count ./...
go tool cover -html=coverage.out
```

## Coverage Anti-Patterns

- **Chasing 100%** — Diminishing returns. Time spent testing trivial code is time not spent on real tests.
- **Testing to coverage, not behavior** — Writing tests that execute code but don't assert meaningful behavior.
- **Ignoring branch coverage** — Line coverage can be misleading. An `if/else` with only the `if` branch tested shows 50% branch coverage but may show higher line coverage.
- **Coverage as a gate without context** — A file with 60% coverage might be fine (mostly generated code), while another with 80% might be undertested (missing error paths).
