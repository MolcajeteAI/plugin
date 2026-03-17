# Mocking in Go

## Interface-Based Mocks

Go's implicit interfaces make mocking straightforward. Define a small interface at the consumer, then create a test implementation.

### Manual Mock

```go
// Production interface (defined at consumer)
type UserStore interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Create(ctx context.Context, user *User) error
}

// Test mock
type mockUserStore struct {
    findByIDFn func(ctx context.Context, id string) (*User, error)
    createFn   func(ctx context.Context, user *User) error
}

func (m *mockUserStore) FindByID(ctx context.Context, id string) (*User, error) {
    if m.findByIDFn != nil {
        return m.findByIDFn(ctx, id)
    }
    return nil, errors.New("FindByID not implemented")
}

func (m *mockUserStore) Create(ctx context.Context, user *User) error {
    if m.createFn != nil {
        return m.createFn(ctx, user)
    }
    return errors.New("Create not implemented")
}
```

### Using the Mock

```go
func TestUserService_GetProfile(t *testing.T) {
    store := &mockUserStore{
        findByIDFn: func(ctx context.Context, id string) (*User, error) {
            if id == "123" {
                return &User{ID: "123", Name: "Alice"}, nil
            }
            return nil, ErrNotFound
        },
    }

    svc := NewUserService(store)

    t.Run("existing user", func(t *testing.T) {
        user, err := svc.GetProfile(context.Background(), "123")
        if err != nil {
            t.Fatalf("unexpected error: %v", err)
        }
        if user.Name != "Alice" {
            t.Errorf("got name %q, want %q", user.Name, "Alice")
        }
    })

    t.Run("nonexistent user", func(t *testing.T) {
        _, err := svc.GetProfile(context.Background(), "999")
        if !errors.Is(err, ErrNotFound) {
            t.Errorf("got error %v, want ErrNotFound", err)
        }
    })
}
```

## Test Doubles Taxonomy

| Type | Purpose | Example |
|---|---|---|
| **Stub** | Returns canned answers | `findByIDFn: func(...) { return fixedUser, nil }` |
| **Spy** | Records calls for later assertion | Tracks how many times a method was called |
| **Mock** | Verifies specific interactions | Asserts methods called with expected arguments |
| **Fake** | Working implementation with shortcuts | In-memory database, local file store |

### Spy Example

```go
type spyNotifier struct {
    calls []struct {
        userID  string
        message string
    }
}

func (s *spyNotifier) Send(ctx context.Context, userID, message string) error {
    s.calls = append(s.calls, struct {
        userID  string
        message string
    }{userID, message})
    return nil
}

func TestNotificationOnCreate(t *testing.T) {
    notifier := &spyNotifier{}
    svc := NewUserService(store, notifier)

    svc.CreateUser(context.Background(), "alice", "alice@example.com")

    if len(notifier.calls) != 1 {
        t.Fatalf("expected 1 notification, got %d", len(notifier.calls))
    }
    if notifier.calls[0].message != "Welcome!" {
        t.Errorf("got message %q, want %q", notifier.calls[0].message, "Welcome!")
    }
}
```

### Fake Example — In-Memory Store

```go
type fakeUserStore struct {
    users map[string]*User
    mu    sync.Mutex
}

func newFakeUserStore() *fakeUserStore {
    return &fakeUserStore{users: make(map[string]*User)}
}

func (f *fakeUserStore) FindByID(ctx context.Context, id string) (*User, error) {
    f.mu.Lock()
    defer f.mu.Unlock()
    user, ok := f.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return user, nil
}

func (f *fakeUserStore) Create(ctx context.Context, user *User) error {
    f.mu.Lock()
    defer f.mu.Unlock()
    if _, exists := f.users[user.ID]; exists {
        return ErrAlreadyExists
    }
    f.users[user.ID] = user
    return nil
}
```

## httptest

### Testing Handlers (ResponseRecorder)

```go
func TestGetUser(t *testing.T) {
    store := &mockUserStore{
        findByIDFn: func(ctx context.Context, id string) (*User, error) {
            return &User{ID: id, Name: "Alice"}, nil
        },
    }
    handler := NewHandler(store)

    req := httptest.NewRequest("GET", "/users/123", nil)
    // Set Chi URL params
    rctx := chi.NewRouteContext()
    rctx.URLParams.Add("userID", "123")
    req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

    rec := httptest.NewRecorder()
    handler.GetUser(rec, req)

    if rec.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
    }

    var got User
    json.NewDecoder(rec.Body).Decode(&got)
    if got.Name != "Alice" {
        t.Errorf("name = %q, want %q", got.Name, "Alice")
    }
}
```

### Testing HTTP Clients (Test Server)

```go
func TestAPIClient_FetchUser(t *testing.T) {
    srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.URL.Path != "/users/123" {
            t.Errorf("unexpected path: %s", r.URL.Path)
        }
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(User{ID: "123", Name: "Alice"})
    }))
    defer srv.Close()

    client := NewAPIClient(srv.URL)
    user, err := client.FetchUser(context.Background(), "123")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "Alice" {
        t.Errorf("name = %q, want %q", user.Name, "Alice")
    }
}
```

## Database Testing

### Transaction-Based Isolation

```go
func setupTestDB(t *testing.T) *pgxpool.Pool {
    t.Helper()

    pool, err := pgxpool.New(context.Background(), os.Getenv("TEST_DATABASE_URL"))
    if err != nil {
        t.Fatalf("connecting to test database: %v", err)
    }

    t.Cleanup(func() {
        pool.Close()
    })

    return pool
}

func withTx(t *testing.T, pool *pgxpool.Pool, fn func(tx pgx.Tx)) {
    t.Helper()

    ctx := context.Background()
    tx, err := pool.Begin(ctx)
    if err != nil {
        t.Fatalf("starting transaction: %v", err)
    }

    defer tx.Rollback(ctx) // always rollback — test data stays isolated
    fn(tx)
}
```

### testcontainers-go

For CI environments where a shared test database isn't available:

```go
func setupPostgres(t *testing.T) *pgxpool.Pool {
    t.Helper()

    ctx := context.Background()
    container, err := postgres.Run(ctx,
        "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
    )
    if err != nil {
        t.Fatalf("starting postgres container: %v", err)
    }

    t.Cleanup(func() {
        container.Terminate(ctx)
    })

    connStr, err := container.ConnectionString(ctx, "sslmode=disable")
    if err != nil {
        t.Fatalf("getting connection string: %v", err)
    }

    pool, err := pgxpool.New(ctx, connStr)
    if err != nil {
        t.Fatalf("connecting to postgres: %v", err)
    }

    t.Cleanup(func() {
        pool.Close()
    })

    // Run migrations
    runMigrations(t, connStr)

    return pool
}
```

## Mocking Anti-Patterns

### Don't Mock What You Don't Own

```go
// ❌ Mocking the standard library's http.Client
type mockHTTPClient struct{}

// ✅ Define your own interface and mock that
type HTTPDoer interface {
    Do(req *http.Request) (*http.Response, error)
}
```

### Don't Over-Mock

```go
// ❌ Mocking everything — testing the mocks, not the code
func TestService(t *testing.T) {
    mockRepo := &mockRepo{}
    mockCache := &mockCache{}
    mockLogger := &mockLogger{}
    mockMetrics := &mockMetrics{}
    // ... testing mock interactions, not business logic
}

// ✅ Mock only external boundaries
func TestService(t *testing.T) {
    repo := newFakeUserStore() // fake with real behavior
    svc := NewService(repo)    // test real service with fake dependency
}
```

### Don't Assert on Mock Internals

```go
// ❌ Testing implementation details
assert.Equal(t, 1, mock.FindByIDCallCount)
assert.Equal(t, "123", mock.FindByIDArgs[0])

// ✅ Test the observable behavior
user, err := svc.GetProfile(ctx, "123")
assert.NoError(t, err)
assert.Equal(t, "Alice", user.Name)
```
