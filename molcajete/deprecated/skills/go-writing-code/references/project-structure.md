# Go Project Structure

## Standard Layout

The most widely adopted layout for Go applications. Suitable for medium to large projects.

```
project/
├── cmd/
│   ├── server/
│   │   └── main.go              # HTTP/gRPC server entry point
│   └── worker/
│       └── main.go              # Background worker entry point
├── internal/
│   ├── config/
│   │   └── config.go            # Environment/file configuration
│   ├── handler/
│   │   ├── user.go              # HTTP handlers for users
│   │   └── appointment.go       # HTTP handlers for appointments
│   ├── service/
│   │   ├── user.go              # Business logic for users
│   │   └── appointment.go       # Business logic for appointments
│   ├── repository/
│   │   ├── user.go              # Database operations for users
│   │   └── appointment.go       # Database operations for appointments
│   ├── model/
│   │   ├── user.go              # Domain types
│   │   └── appointment.go
│   └── middleware/
│       ├── auth.go              # Authentication middleware
│       └── logging.go           # Request logging middleware
├── pkg/                          # Public library code (optional)
│   └── validator/
│       └── validator.go
├── migrations/
│   ├── 001_create_users.sql
│   └── 002_create_appointments.sql
├── Makefile
├── go.mod
├── go.sum
└── README.md
```

### Key Rules

- **`cmd/`** — One directory per binary. Minimal code: parse flags, load config, wire dependencies, start server.
- **`internal/`** — The Go compiler enforces that `internal/` packages cannot be imported by external modules. Put all application code here.
- **`pkg/`** — Only for code intended for external consumption. Most projects don't need this. If uncertain, put it in `internal/`.
- **`migrations/`** — Database migration files, ordered by number.

### cmd/main.go Should Be Thin

```go
func main() {
    cfg := config.Load()

    db, err := database.Connect(cfg.DatabaseURL)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    repo := repository.New(db)
    svc := service.New(repo)
    handler := handler.New(svc)

    router := setupRouter(handler)
    log.Fatal(http.ListenAndServe(cfg.Port, router))
}
```

## Hexagonal Architecture (Ports and Adapters)

Isolates business logic from infrastructure concerns. The domain core defines interfaces (ports) that infrastructure implements (adapters).

```
internal/
├── domain/
│   ├── user.go                  # Domain entities and value objects
│   ├── appointment.go
│   └── ports.go                 # Interface definitions (ports)
├── app/
│   ├── user_service.go          # Application services (use cases)
│   └── appointment_service.go
├── adapter/
│   ├── postgres/
│   │   ├── user_repo.go         # PostgreSQL adapter
│   │   └── appointment_repo.go
│   ├── redis/
│   │   └── cache.go             # Redis adapter
│   └── http/
│       ├── handler.go           # HTTP adapter
│       └── middleware.go
└── config/
    └── config.go
```

### Ports (Interfaces)

```go
// domain/ports.go
package domain

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Create(ctx context.Context, user *User) error
}

type NotificationSender interface {
    Send(ctx context.Context, userID string, message string) error
}
```

### When to Use

- Large applications with complex business logic.
- Multiple external integrations (databases, APIs, message queues).
- Need to swap infrastructure without touching business logic.
- Strong testing requirements (easy to mock infrastructure).

### When NOT to Use

- Small applications or microservices with simple CRUD.
- The indirection adds complexity without proportional benefit.

## Flat Structure

For small projects, CLIs, and microservices. Everything in one or two packages.

```
project/
├── main.go
├── handler.go
├── service.go
├── repository.go
├── model.go
├── handler_test.go
├── service_test.go
├── Makefile
├── go.mod
└── go.sum
```

### When to Use

- Small projects (under ~10 files of application code).
- CLI tools.
- Simple microservices with a single responsibility.
- Prototypes and proof-of-concepts.

### When NOT to Use

- When the package exceeds ~15 files — split into subpackages.
- When multiple developers work on the project simultaneously.
- When the project has multiple entry points.

## Decision Guide

| Factor | Flat | Standard | Hexagonal |
|---|---|---|---|
| Project size | Small (<10 files) | Medium (10–50 files) | Large (50+ files) |
| Team size | 1–2 developers | 2–5 developers | 5+ developers |
| External dependencies | Few | Several | Many |
| Business logic complexity | Simple CRUD | Moderate | Complex |
| Infrastructure swapping | Not needed | Occasional | Frequent |
| Testing requirements | Basic | Moderate | Extensive |

### Rules of Thumb

1. **Start flat** — Begin with the simplest structure that works.
2. **Grow into standard** — When you have 10+ files or need multiple packages.
3. **Adopt hexagonal** — When business logic is complex and infrastructure is diverse.
4. **Never go deeper than needed** — A flat package with 5 files is better than 5 packages with 1 file each.
5. **Package by functionality** — Group code by what it does, not by its type (all models together, all handlers together).

## Package Design

### Naming

- **Short, lowercase, single word** — `user`, `auth`, `config`. Not `user_service`, `authPackage`.
- **No generic names** — Avoid `utils`, `helpers`, `common`, `shared`. Put utilities where they're used.
- **No stutter** — `http.Client`, not `http.HTTPClient`. `auth.Token`, not `auth.AuthToken`.

### Size

- **5–15 files** is a healthy package size.
- **1 file** — Too granular. Consider merging with a related package.
- **20+ files** — Consider splitting by sub-functionality.

### Dependencies

- **No circular imports** — Go forbids them. Design packages in a directed acyclic graph.
- **Depend inward** — Handlers depend on services, services depend on repositories. Never the reverse.
- **Define interfaces at the consumer** — The `service` package defines the `UserRepository` interface it needs, not the `repository` package.
