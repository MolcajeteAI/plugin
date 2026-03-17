# Error Handling in Go

## Sentinel Errors

Define package-level errors for expected, checkable conditions. Sentinel errors are part of your package's public API.

```go
package repository

import "errors"

var (
    ErrNotFound      = errors.New("not found")
    ErrAlreadyExists = errors.New("already exists")
    ErrForbidden     = errors.New("forbidden")
    ErrInvalidInput  = errors.New("invalid input")
)
```

### Naming Convention

- Prefix with `Err`: `ErrNotFound`, `ErrTimeout`, `ErrInvalidInput`.
- Keep messages lowercase, no punctuation — they get wrapped into larger messages.
- Group related sentinel errors together with a `var` block.

### When to Use

- The caller needs to take different action based on the error type.
- The error represents a domain concept (not found, unauthorized, conflict).
- The error crosses package boundaries.

### When NOT to Use

- The error is purely internal and callers don't need to distinguish it.
- The error message alone is sufficient (use `fmt.Errorf` instead).

## Error Wrapping

Wrap errors to add context as they propagate up the call stack. Use `%w` to preserve the error chain.

```go
func (s *UserService) GetProfile(ctx context.Context, id string) (*Profile, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting profile for user %s: %w", id, err)
    }

    prefs, err := s.repo.GetPreferences(ctx, user.ID)
    if err != nil {
        return nil, fmt.Errorf("loading preferences for user %s: %w", id, err)
    }

    return &Profile{User: user, Preferences: prefs}, nil
}
```

### Wrapping Rules

1. **Add context about the operation** — What was being done when the error occurred.
2. **Include relevant identifiers** — User IDs, resource names, etc.
3. **Use `%w` for wrappable errors** — Allows callers to use `errors.Is` and `errors.As`.
4. **Use `%v` when you want to hide the error** — Breaks the chain. Use when the underlying error is an implementation detail.
5. **Don't over-wrap** — If the error already has enough context, just return it.
6. **Wrap at package boundaries** — Add context when errors cross package boundaries.

### Common Pattern: Wrap and Return

```go
// ✅ Good — adds context
if err != nil {
    return fmt.Errorf("creating user %q: %w", name, err)
}

// ❌ Bad — adds no value
if err != nil {
    return fmt.Errorf("error: %w", err)
}

// ❌ Bad — wraps with redundant info
if err != nil {
    return fmt.Errorf("CreateUser failed with error: %w", err)
}
```

## Checking Errors

### errors.Is — Check for Specific Error Values

```go
user, err := repo.FindByID(ctx, id)
if errors.Is(err, repository.ErrNotFound) {
    // Handle not found — maybe return 404
    return nil, status.Error(codes.NotFound, "user not found")
}
if err != nil {
    // Handle unexpected error
    return nil, fmt.Errorf("finding user: %w", err)
}
```

### errors.As — Extract Error Types

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}

// Checking
var valErr *ValidationError
if errors.As(err, &valErr) {
    // Access structured error data
    log.Printf("validation failed on field %s: %s", valErr.Field, valErr.Message)
}
```

## Custom Error Types

Use custom error types when errors need to carry structured data beyond a message.

```go
type AppError struct {
    Code    int    // HTTP status code or internal code
    Message string // User-facing message
    Op      string // Operation that failed
    Err     error  // Underlying error
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %s: %v", e.Op, e.Message, e.Err)
    }
    return fmt.Sprintf("%s: %s", e.Op, e.Message)
}

func (e *AppError) Unwrap() error {
    return e.Err
}

// Constructor
func NewAppError(op string, code int, message string, err error) *AppError {
    return &AppError{Code: code, Message: message, Op: op, Err: err}
}

// Usage
func (s *Service) CreateUser(ctx context.Context, name string) (*User, error) {
    if name == "" {
        return nil, NewAppError("CreateUser", 400, "name is required", nil)
    }
    user, err := s.repo.Insert(ctx, name)
    if err != nil {
        return nil, NewAppError("CreateUser", 500, "failed to create user", err)
    }
    return user, nil
}
```

## errgroup for Concurrent Error Handling

`errgroup.Group` runs goroutines concurrently and returns the first error. When one goroutine fails, the context is canceled, stopping the others.

```go
import "golang.org/x/sync/errgroup"

func (s *Service) LoadDashboard(ctx context.Context, userID string) (*Dashboard, error) {
    g, ctx := errgroup.WithContext(ctx)

    var user *User
    var appointments []*Appointment
    var notifications []*Notification

    g.Go(func() error {
        var err error
        user, err = s.userRepo.FindByID(ctx, userID)
        return err
    })

    g.Go(func() error {
        var err error
        appointments, err = s.appointmentRepo.ListByUser(ctx, userID)
        return err
    })

    g.Go(func() error {
        var err error
        notifications, err = s.notificationRepo.ListUnread(ctx, userID)
        return err
    })

    if err := g.Wait(); err != nil {
        return nil, fmt.Errorf("loading dashboard for user %s: %w", userID, err)
    }

    return &Dashboard{
        User:          user,
        Appointments:  appointments,
        Notifications: notifications,
    }, nil
}
```

### errgroup with Limit

Control concurrency to avoid overwhelming resources:

```go
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(10) // max 10 concurrent goroutines

for _, item := range items {
    g.Go(func() error {
        return process(ctx, item)
    })
}

if err := g.Wait(); err != nil {
    return fmt.Errorf("processing items: %w", err)
}
```

## Error Handling Anti-Patterns

### Don't Ignore Errors

```go
// ❌ Never do this
result, _ := riskyOperation()

// ✅ Handle or explicitly document why it's safe to ignore
result, err := riskyOperation()
if err != nil {
    log.Printf("non-critical operation failed: %v", err)
    // Continue with default value
}
```

### Don't Log and Return

```go
// ❌ Error gets logged multiple times as it propagates
if err != nil {
    log.Printf("error: %v", err)
    return err
}

// ✅ Either log OR return — not both
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}
```

### Don't Use panic for Expected Errors

```go
// ❌ panic for expected conditions
func MustParseConfig(path string) *Config {
    cfg, err := ParseConfig(path)
    if err != nil {
        panic(err)
    }
    return cfg
}

// ✅ Return errors — let the caller decide
func ParseConfig(path string) (*Config, error) {
    // ...
}
```

`Must` functions are acceptable only in `init()` or `main()` for hard dependencies, and in test helpers.
