---
name: coverage-analysis
description: Test coverage tracking and improvement strategies. Use when analyzing test coverage.
---

# Coverage Analysis Skill

Test coverage analysis and improvement strategies.

## When to Use

Use when analyzing or improving test coverage.

## Running Coverage

```bash
# Basic coverage
go test -cover ./...

# Generate coverage profile
go test -coverprofile=coverage.out ./...

# HTML report
go tool cover -html=coverage.out

# Function-level coverage
go tool cover -func=coverage.out
```

## Interpreting Coverage

```
github.com/user/project/service/user.go:15:   GetUser         80.0%
github.com/user/project/service/user.go:25:   CreateUser      100.0%
github.com/user/project/service/user.go:35:   DeleteUser      0.0%
total:                                         (statements)    75.5%
```

## Coverage Goals

- **70-80%** - Good baseline
- **80-90%** - Excellent
- **90%+** - Diminishing returns
- Focus on critical paths
- Don't chase 100%

## CI/CD Integration

```yaml
# GitHub Actions
- name: Test with Coverage
  run: |
    go test -v -coverprofile=coverage.out ./...
    go tool cover -func=coverage.out
```

## Best Practices

- Track coverage trends
- Cover critical paths first
- Don't ignore edge cases
- Quality over quantity
