# Go Design Patterns

## Functional Options

The standard Go pattern for configurable constructors. Avoids large config structs and provides sensible defaults.

### Basic Pattern

```go
type Server struct {
    port         int
    readTimeout  time.Duration
    writeTimeout time.Duration
    logger       *slog.Logger
}

type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func WithReadTimeout(d time.Duration) Option {
    return func(s *Server) { s.readTimeout = d }
}

func WithWriteTimeout(d time.Duration) Option {
    return func(s *Server) { s.writeTimeout = d }
}

func WithLogger(logger *slog.Logger) Option {
    return func(s *Server) { s.logger = logger }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        port:         8080,
        readTimeout:  10 * time.Second,
        writeTimeout: 10 * time.Second,
        logger:       slog.Default(),
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
srv := NewServer(
    WithPort(9090),
    WithReadTimeout(30 * time.Second),
)
```

### When to Use

- Constructor has 3+ optional parameters.
- You want sensible defaults that callers can override.
- Configuration needs may grow over time.

### When NOT to Use

- Only 1-2 parameters — just pass them directly.
- All parameters are required — use a plain constructor.
- Configuration is static and won't change — use a config struct.

### With Validation

```go
type Option func(*Server) error

func WithPort(port int) Option {
    return func(s *Server) error {
        if port < 1 || port > 65535 {
            return fmt.Errorf("invalid port: %d", port)
        }
        s.port = port
        return nil
    }
}

func NewServer(opts ...Option) (*Server, error) {
    s := &Server{port: 8080}
    for _, opt := range opts {
        if err := opt(s); err != nil {
            return nil, fmt.Errorf("applying option: %w", err)
        }
    }
    return s, nil
}
```

## Interface Composition

Go interfaces are implicitly satisfied. Small interfaces compose into larger ones.

### Small Interfaces First

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type ReadWriter interface {
    Reader
    Writer
}
```

### Accept Interfaces, Return Structs

```go
// ✅ Function accepts a narrow interface
func Copy(dst Writer, src Reader) (int64, error) {
    // ...
}

// ✅ Constructor returns a concrete type
func NewFileWriter(path string) (*FileWriter, error) {
    // ...
}
```

### Define Interfaces at the Consumer

```go
// ❌ Don't define interfaces in the implementation package
package repository

type UserRepository interface { // Too broad, couples consumers
    FindByID(ctx context.Context, id string) (*User, error)
    Create(ctx context.Context, u *User) error
    Update(ctx context.Context, u *User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context) ([]*User, error)
}

// ✅ Define interfaces where they're used
package service

type UserFinder interface { // Only what this consumer needs
    FindByID(ctx context.Context, id string) (*User, error)
}

type UserCreator interface {
    Create(ctx context.Context, u *User) error
}
```

## Builder Pattern

Use when constructing complex objects step by step. Less common in Go than functional options, but useful for objects with many interdependent fields.

```go
type QueryBuilder struct {
    table      string
    conditions []string
    args       []any
    orderBy    string
    limit      int
}

func NewQuery(table string) *QueryBuilder {
    return &QueryBuilder{table: table}
}

func (q *QueryBuilder) Where(condition string, args ...any) *QueryBuilder {
    q.conditions = append(q.conditions, condition)
    q.args = append(q.args, args...)
    return q
}

func (q *QueryBuilder) OrderBy(field string) *QueryBuilder {
    q.orderBy = field
    return q
}

func (q *QueryBuilder) Limit(n int) *QueryBuilder {
    q.limit = n
    return q
}

func (q *QueryBuilder) Build() (string, []any) {
    query := "SELECT * FROM " + q.table
    if len(q.conditions) > 0 {
        query += " WHERE " + strings.Join(q.conditions, " AND ")
    }
    if q.orderBy != "" {
        query += " ORDER BY " + q.orderBy
    }
    if q.limit > 0 {
        query += fmt.Sprintf(" LIMIT %d", q.limit)
    }
    return query, q.args
}

// Usage
query, args := NewQuery("users").
    Where("age > $1", 18).
    Where("active = $2", true).
    OrderBy("name").
    Limit(10).
    Build()
```

## Embedding for Composition

Embed types to compose behavior. This is not inheritance — it's delegation with syntactic sugar.

```go
type BaseHandler struct {
    logger *slog.Logger
}

func (h *BaseHandler) respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func (h *BaseHandler) respondError(w http.ResponseWriter, status int, msg string) {
    h.respondJSON(w, status, map[string]string{"error": msg})
}

type UserHandler struct {
    BaseHandler // Embeds JSON response methods
    service UserService
}

// UserHandler can call h.respondJSON and h.respondError directly
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.FindByID(r.Context(), chi.URLParam(r, "id"))
    if err != nil {
        h.respondError(w, http.StatusNotFound, "user not found")
        return
    }
    h.respondJSON(w, http.StatusOK, user)
}
```

### Rules

- **Embed for behavior, not for data** — Embed when you want the methods, not just the fields.
- **Don't embed to hide fields** — If you need to restrict access, use a field and write wrapper methods.
- **Avoid deep embedding** — One level of embedding is clear. Two or more levels become confusing.

## Type Assertions and Type Switches

### Type Switch

```go
func handleValue(v any) string {
    switch val := v.(type) {
    case string:
        return val
    case int:
        return strconv.Itoa(val)
    case error:
        return val.Error()
    default:
        return fmt.Sprintf("%v", val)
    }
}
```

### Safe Type Assertion

```go
// ✅ Always use the two-value form
if s, ok := v.(string); ok {
    // use s
}

// ❌ Panics if v is not a string
s := v.(string)
```
