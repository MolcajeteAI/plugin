---
name: code-quality
description: Go idioms, style guide, and best practices with YAGNI/KISS principles. Use when writing or reviewing Go code.
---

# Code Quality Skill

This skill provides Go code quality standards with YAGNI/KISS development philosophy.

## When to Use

Use this skill when:
- Writing new Go code
- Reviewing code quality
- Establishing coding standards
- Refactoring code

## Core Development Principles

### 1. YAGNI (You Aren't Gonna Need It)
- Only implement current requirements
- Don't add features for hypothetical future needs
- Refactor when actual needs arise
- Avoid premature abstraction

**Example:**
```go
// Good - Simple, addresses current need
func GetUser(id int) (*User, error) {
    return db.Query("SELECT * FROM users WHERE id = ?", id)
}

// Bad - YAGNI violation, adding unused caching
func GetUser(id int) (*User, error) {
    if cached, ok := cache.Get(id); ok {
        return cached, nil
    }
    user, err := db.Query("SELECT * FROM users WHERE id = ?", id)
    if err == nil {
        cache.Set(id, user)
    }
    return user, err
}
```

### 2. KISS (Keep It Simple, Stupid)
- Prefer simple, straightforward solutions
- Don't prematurely optimize
- Profile before optimizing
- Clear code beats clever code

**Example:**
```go
// Good - Simple and clear
func Sum(numbers []int) int {
    sum := 0
    for _, n := range numbers {
        sum += n
    }
    return sum
}

// Bad - Unnecessary complexity
func Sum(numbers []int) int {
    ch := make(chan int)
    go func() {
        sum := 0
        for _, n := range numbers {
            sum += n
        }
        ch <- sum
    }()
    return <-ch
}
```

### 3. Readability First
- Code is read more than written
- Use descriptive names
- Keep functions focused and short
- Comment non-obvious logic

### 4. Formatting Standards
- **ALWAYS run `go fmt` after changes**
- Use `goimports` for import management
- Consistent formatting across codebase

### 5. Build System Standards
- **ALWAYS create a Makefile**
- **ALWAYS build to `./bin/` directory**
- Never build binaries to project root
- Use `make build`, never `go build` directly
- Include `fmt`, `test`, `lint`, `clean` targets

## Go Style Guide

### Naming Conventions

```go
// Good naming
type UserService struct {}
func (s *UserService) GetUser(ctx context.Context, id int) (*User, error)
var ErrNotFound = errors.New("not found")
const MaxRetries = 3

// Bad naming
type Userservice struct {}
func (s *Userservice) get_user(ID int) (*User, error)
var errnotfound = errors.New("not found")
const max_retries = 3
```

**Rules:**
- MixedCaps (camelCase/PascalCase), not snake_case
- Exported names start with capital letter
- Acronyms are all caps: `HTTP`, `ID`, `URL`
- Short, descriptive names
- Single-letter names for short-lived variables (i, j, k)

### Package Organization

```go
// Good - grouped by functionality
package user

type Service struct {}
type Repository struct {}
type Handler struct {}

// Bad - grouped by type
package services
type UserService struct {}
type OrderService struct {}
```

### Interface Design

```go
// Good - small, focused interfaces
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Bad - large interface
type FileManager interface {
    Read(p []byte) (n int, err error)
    Write(p []byte) (n int, err error)
    Close() error
    Seek(offset int64, whence int) (int64, error)
    Stat() (FileInfo, error)
}
```

**Rules:**
- Accept interfaces, return structs
- Keep interfaces small
- Define interfaces at point of use
- Interface names often end in -er

### Error Handling

```go
// Good - context, clear naming, simple logic
func (s *Service) GetUser(ctx context.Context, id int) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user: %w", err)
    }
    return user, nil
}

// Bad - missing context, unclear error
func (s *Service) GetUser(id int) (*User, error) {
    user, err := s.repo.FindByID(id)
    if err != nil {
        return nil, err
    }
    return user, nil
}
```

### Context Usage

```go
// Good - context first parameter
func ProcessRequest(ctx context.Context, req Request) error {
    // Check cancellation
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }
    return doWork(ctx, req)
}

// Bad - missing context
func ProcessRequest(req Request) error {
    return doWork(req)
}
```

### Code Organization

```go
// Good structure
type Server struct {
    host string
    port int
}

func NewServer(host string, port int) *Server {
    return &Server{host: host, port: int}
}

func (s *Server) Start() error {
    // implementation
}

// Bad - scattered functions
func StartServer(host string, port int) error {}
func StopServer(s *Server) error {}
```

## Common Patterns

### Functional Options

```go
type Server struct {
    host    string
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithHost(host string) Option {
    return func(s *Server) { s.host = host }
}

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        host:    "localhost",
        port:    8080,
        timeout: 30 * time.Second,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
srv := NewServer(WithHost("0.0.0.0"), WithPort(3000))
```

### Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"mixed", 1, -1, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

## Makefile Requirements

```makefile
.PHONY: build test clean fmt lint

build:
\t@mkdir -p bin
\tgo build -o bin/myapp cmd/myapp/main.go

fmt:
\tgo fmt ./...

test:
\tgo test -v ./...

lint:
\tgolangci-lint run

clean:
\trm -rf bin/
```

## golangci-lint Configuration

Create `.golangci.yml`:

```yaml
linters:
  enable:
    - gofmt
    - goimports
    - govet
    - errcheck
    - staticcheck
    - gosec
    - gosimple
    - ineffassign
    - unused

linters-settings:
  gofmt:
    simplify: true
  goimports:
    local-prefixes: github.com/yourorg/
```

## Anti-Patterns to Avoid

### 1. Premature Optimization
```go
// Bad - optimizing without profiling
type Cache struct {
    mu    sync.RWMutex
    items map[string]*Item
}

// Good - start simple (KISS)
type Cache struct {
    items map[string]*Item
}
```

### 2. Over-Engineering
```go
// Bad - YAGNI violation
type UserFactory interface {
    CreateUser() User
}

type StandardUserFactory struct {}

func (f *StandardUserFactory) CreateUser() User {
    return User{}
}

// Good - simple and direct
func NewUser() User {
    return User{}
}
```

### 3. Ignoring Errors
```go
// Bad
data, _ := ioutil.ReadFile("file.txt")

// Good
data, err := ioutil.ReadFile("file.txt")
if err != nil {
    return fmt.Errorf("failed to read file: %w", err)
}
```

## Best Practices Summary

1. **YAGNI** - Implement only what's needed now
2. **KISS** - Simple solutions, optimize after profiling
3. **Readability** - Clear code over clever code
4. **go fmt** - Format after every change
5. **Makefile** - Use make build, never go build directly
6. **Context** - Pass context.Context as first parameter
7. **Errors** - Always check and wrap errors
8. **Interfaces** - Keep small, define at point of use
9. **Names** - Clear, descriptive, follow conventions
10. **Tests** - Table-driven, comprehensive
