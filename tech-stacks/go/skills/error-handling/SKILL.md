---
name: error-handling
description: Modern Go error handling patterns (Go 1.13+). Use when handling, creating, or wrapping errors.
---

# Error Handling Skill

Modern error handling patterns following Go 1.13+ conventions.

## When to Use

Use this skill when:
- Creating errors
- Wrapping errors
- Checking error types
- Implementing error handling logic

## Error Creation

### Sentinel Errors

```go
var (
    ErrNotFound      = errors.New("not found")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrInvalidInput  = errors.New("invalid input")
)

// Usage
if user == nil {
    return ErrNotFound
}
```

### Error Wrapping

```go
// Wrap errors with context
func GetUser(ctx context.Context, id int) (*User, error) {
    user, err := db.Query(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user %d: %w", id, err)
    }
    return user, nil
}
```

### Custom Error Types

```go
type ValidationError struct {
    Field string
    Value interface{}
    Err   error
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s=%v: %v", e.Field, e.Value, e.Err)
}

func (e *ValidationError) Unwrap() error {
    return e.Err
}
```

## Error Checking

### errors.Is

```go
// Check for specific error
if errors.Is(err, ErrNotFound) {
    return http.StatusNotFound
}

// Works with wrapped errors
err := fmt.Errorf("database error: %w", ErrNotFound)
errors.Is(err, ErrNotFound) // true
```

### errors.As

```go
// Type assertion for error details
var validationErr *ValidationError
if errors.As(err, &validationErr) {
    log.Printf("validation failed: field=%s", validationErr.Field)
}
```

## Error Handling Patterns

### Check-Early-Return

```go
func ProcessUser(ctx context.Context, id int) error {
    user, err := GetUser(ctx, id)
    if err != nil {
        return fmt.Errorf("get user: %w", err)
    }

    if err := ValidateUser(user); err != nil {
        return fmt.Errorf("validate user: %w", err)
    }

    if err := SaveUser(ctx, user); err != nil {
        return fmt.Errorf("save user: %w", err)
    }

    return nil
}
```

### Error Context

```go
// Add context to errors
func (s *Service) CreateOrder(ctx context.Context, order *Order) error {
    if err := s.validateOrder(order); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }

    if err := s.repo.Save(ctx, order); err != nil {
        return fmt.Errorf("failed to save order %d: %w", order.ID, err)
    }

    return nil
}
```

## Error Propagation

### Simple Propagation

```go
func GetUser(id int) (*User, error) {
    user, err := db.QueryUser(id)
    if err != nil {
        return nil, fmt.Errorf("query user: %w", err)
    }
    return user, nil
}
```

### Multi-Error Handling

```go
func ProcessBatch(items []Item) error {
    var errs []error

    for _, item := range items {
        if err := ProcessItem(item); err != nil {
            errs = append(errs, fmt.Errorf("item %d: %w", item.ID, err))
        }
    }

    if len(errs) > 0 {
        return fmt.Errorf("batch processing failed: %v", errs)
    }

    return nil
}
```

## Panic vs Error

### Use Errors (Preferred)

```go
// Good - return error
func Divide(a, b int) (int, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
```

### Use Panic (Rare)

```go
// Only for truly exceptional, unrecoverable situations
func MustCompile(pattern string) *regexp.Regexp {
    re, err := regexp.Compile(pattern)
    if err != nil {
        panic(fmt.Sprintf("invalid pattern: %v", err))
    }
    return re
}
```

### Recover from Panic

```go
func SafeHandler(w http.ResponseWriter, r *http.Request) {
    defer func() {
        if err := recover(); err != nil {
            log.Printf("panic: %v", err)
            http.Error(w, "Internal Server Error", 500)
        }
    }()

    // handler logic
}
```

## Error Handling in Goroutines

### Use Channels

```go
func ProcessAsync(ctx context.Context) error {
    errCh := make(chan error, 1)

    go func() {
        errCh <- doWork(ctx)
    }()

    select {
    case <-ctx.Done():
        return ctx.Err()
    case err := <-errCh:
        return err
    }
}
```

### Use errgroup

```go
import "golang.org/x/sync/errgroup"

func ProcessParallel(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item // capture range variable
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}
```

## Best Practices

1. **Always check errors** - Never ignore with `_`
2. **Wrap errors with context** - Use `fmt.Errorf("context: %w", err)`
3. **Use errors.Is** - For checking specific errors
4. **Use errors.As** - For type assertions
5. **Return early** - Check errors immediately
6. **Don't panic** - Use errors for expected failures
7. **Add context** - Make errors debuggable
8. **Wrap, don't replace** - Preserve error chain

## Anti-Patterns

### Don't Ignore Errors

```go
// Bad
data, _ := ioutil.ReadFile("config.json")

// Good
data, err := ioutil.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("failed to read config: %w", err)
}
```

### Don't Lose Error Context

```go
// Bad - loses original error
if err != nil {
    return errors.New("failed to process")
}

// Good - preserves error chain
if err != nil {
    return fmt.Errorf("failed to process: %w", err)
}
```

### Don't Panic for Expected Errors

```go
// Bad
func GetConfig() *Config {
    data, err := ioutil.ReadFile("config.json")
    if err != nil {
        panic(err) // Don't do this
    }
    // ...
}

// Good
func GetConfig() (*Config, error) {
    data, err := ioutil.ReadFile("config.json")
    if err != nil {
        return nil, fmt.Errorf("read config: %w", err)
    }
    // ...
}
```
