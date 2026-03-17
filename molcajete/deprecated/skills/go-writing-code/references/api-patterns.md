# API Patterns in Go

## HTTP Handlers with Chi

### Handler Structure

Group handlers into a struct with dependencies injected:

```go
type Handler struct {
    service    UserService
    logger     *slog.Logger
}

func NewHandler(service UserService, logger *slog.Logger) *Handler {
    return &Handler{service: service, logger: logger}
}
```

### Route Registration

```go
func (h *Handler) Routes() chi.Router {
    r := chi.NewRouter()

    r.Get("/", h.ListUsers)
    r.Post("/", h.CreateUser)
    r.Route("/{userID}", func(r chi.Router) {
        r.Get("/", h.GetUser)
        r.Put("/", h.UpdateUser)
        r.Delete("/", h.DeleteUser)
    })

    return r
}

// Mount in main router
r := chi.NewRouter()
r.Mount("/api/users", userHandler.Routes())
```

### Handler Implementation

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    id := chi.URLParam(r, "userID")

    user, err := h.service.FindByID(ctx, id)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    respondJSON(w, http.StatusOK, user)
}

func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateUserRequest
    if err := decodeJSON(r, &req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    user, err := h.service.Create(ctx, req.Name, req.Email)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    respondJSON(w, http.StatusCreated, user)
}
```

### JSON Response Helpers

```go
func respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    if err := json.NewEncoder(w).Encode(data); err != nil {
        // Log but don't try to write another response
        slog.Error("encoding response", "error", err)
    }
}

func respondError(w http.ResponseWriter, status int, message string) {
    respondJSON(w, status, map[string]string{"error": message})
}

func decodeJSON(r *http.Request, v any) error {
    dec := json.NewDecoder(r.Body)
    dec.DisallowUnknownFields()
    return dec.Decode(v)
}
```

## Middleware

### Middleware Signature

```go
func MyMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Before handler
        // ...

        next.ServeHTTP(w, r)

        // After handler
        // ...
    })
}
```

### Request ID Middleware

```go
func RequestID(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        id := r.Header.Get("X-Request-ID")
        if id == "" {
            id = uuid.NewString()
        }
        ctx := context.WithValue(r.Context(), requestIDKey, id)
        w.Header().Set("X-Request-ID", id)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

### Auth Middleware

```go
func AuthRequired(authService auth.Service) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := extractBearerToken(r)
            if token == "" {
                respondError(w, http.StatusUnauthorized, "missing token")
                return
            }

            claims, err := authService.ValidateToken(token)
            if err != nil {
                respondError(w, http.StatusUnauthorized, "invalid token")
                return
            }

            ctx := auth.WithUserID(r.Context(), claims.UserID)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}

func extractBearerToken(r *http.Request) string {
    h := r.Header.Get("Authorization")
    return strings.TrimPrefix(h, "Bearer ")
}
```

### Middleware Stack

```go
r := chi.NewRouter()

// Global middleware
r.Use(middleware.RequestID)
r.Use(middleware.RealIP)
r.Use(middleware.Logger)
r.Use(middleware.Recoverer)
r.Use(middleware.Timeout(30 * time.Second))
r.Use(corsMiddleware)

// Public routes
r.Group(func(r chi.Router) {
    r.Post("/auth/login", authHandler.Login)
    r.Post("/auth/register", authHandler.Register)
})

// Protected routes
r.Group(func(r chi.Router) {
    r.Use(AuthRequired(authService))
    r.Mount("/api/users", userHandler.Routes())
    r.Mount("/api/appointments", appointmentHandler.Routes())
})
```

## Error Response Conventions

Map domain errors to HTTP status codes consistently:

```go
func (h *Handler) handleError(w http.ResponseWriter, r *http.Request, err error) {
    switch {
    case errors.Is(err, repository.ErrNotFound):
        respondError(w, http.StatusNotFound, "resource not found")
    case errors.Is(err, repository.ErrAlreadyExists):
        respondError(w, http.StatusConflict, "resource already exists")
    case errors.Is(err, repository.ErrForbidden):
        respondError(w, http.StatusForbidden, "access denied")
    default:
        h.logger.Error("unhandled error", "error", err, "path", r.URL.Path)
        respondError(w, http.StatusInternalServerError, "internal server error")
    }
}
```

## gRPC Service Patterns

### Service Definition

```protobuf
service UserService {
    rpc GetUser(GetUserRequest) returns (User);
    rpc CreateUser(CreateUserRequest) returns (User);
    rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
}
```

### Server Implementation

```go
type userServer struct {
    pb.UnimplementedUserServiceServer
    service UserService
}

func (s *userServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
    if req.GetId() == "" {
        return nil, status.Error(codes.InvalidArgument, "id is required")
    }

    user, err := s.service.FindByID(ctx, req.GetId())
    if err != nil {
        if errors.Is(err, repository.ErrNotFound) {
            return nil, status.Error(codes.NotFound, "user not found")
        }
        return nil, status.Error(codes.Internal, "internal error")
    }

    return toProtoUser(user), nil
}
```

### gRPC Error Mapping

```go
func mapGRPCError(err error) error {
    switch {
    case errors.Is(err, repository.ErrNotFound):
        return status.Error(codes.NotFound, err.Error())
    case errors.Is(err, repository.ErrAlreadyExists):
        return status.Error(codes.AlreadyExists, err.Error())
    case errors.Is(err, repository.ErrForbidden):
        return status.Error(codes.PermissionDenied, err.Error())
    case errors.Is(err, repository.ErrInvalidInput):
        return status.Error(codes.InvalidArgument, err.Error())
    default:
        return status.Error(codes.Internal, "internal error")
    }
}
```

## GraphQL Resolver Delegation (gqlgen)

### The Rule

Resolver files (`*.resolvers.go`) are regenerated by gqlgen. Never put implementation logic in them. Every resolver method must be a single-line delegation to a helper function.

### File Organization

```
graph/
├── schema.graphqls           # GraphQL schema
├── schema.resolvers.go       # Generated — delegation only
├── schema_helpers.go         # Implementation for schema resolvers
├── user.resolvers.go         # Generated — delegation only
├── user_helpers.go           # Implementation for user resolvers
├── model/
│   └── models_gen.go         # Generated models
└── generated.go              # Generated runtime
```

### Pattern

```go
// user.resolvers.go — GENERATED, touch only to add delegation calls
func (r *queryResolver) Viewer(ctx context.Context) (*model.Viewer, error) {
    return r.resolveViewer(ctx)
}

func (r *queryResolver) User(ctx context.Context, id string) (*model.User, error) {
    return r.resolveUser(ctx, id)
}

// user_helpers.go — All implementation lives here
func (r *queryResolver) resolveViewer(ctx context.Context) (*model.Viewer, error) {
    userID, err := auth.UserIDFromContext(ctx)
    if err != nil {
        return nil, err
    }

    user, err := r.userRepo.FindByID(ctx, userID)
    if err != nil {
        return nil, fmt.Errorf("resolving viewer: %w", err)
    }

    return mapToViewer(user), nil
}

func (r *queryResolver) resolveUser(ctx context.Context, id string) (*model.User, error) {
    user, err := r.userRepo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("resolving user %s: %w", id, err)
    }
    return mapToModel(user), nil
}
```

### Shared vs Per-App Helpers

When multiple GraphQL schemas share logic:

```
internal/
├── graph/helpers/            # Shared helper functions
│   ├── user.go              # Common user operations
│   └── appointment.go       # Common appointment operations
├── patient/graph/
│   ├── user.resolvers.go    # Generated
│   └── user_helpers.go      # Calls shared helpers + patient-specific logic
├── doctor/graph/
│   ├── user.resolvers.go    # Generated
│   └── user_helpers.go      # Calls shared helpers + doctor-specific logic
└── console/graph/
    ├── user.resolvers.go    # Generated
    └── user_helpers.go      # Calls shared helpers + admin-specific logic
```

### Dataloader Pattern

For N+1 query prevention in GraphQL:

```go
// dataloader.go
type Loaders struct {
    UserByID *dataloader.Loader[string, *model.User]
}

func NewLoaders(repo repository.UserRepo) *Loaders {
    return &Loaders{
        UserByID: dataloader.NewBatchedLoader(func(
            ctx context.Context, keys []string,
        ) []*dataloader.Result[*model.User] {
            users, err := repo.FindByIDs(ctx, keys)
            // ... map results to keys
        }),
    }
}
```
