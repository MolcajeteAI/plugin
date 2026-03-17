# Transaction Management in Go

## The Problem

Multi-service operations need to share a database transaction. When `ServiceA.Create()` calls `ServiceB.Create()` internally, both must operate within the same transaction — or each operates independently. Without a pattern, you end up either:

- Passing `*sql.Tx` through every function signature (couples everything to transactions)
- Creating separate transactions per service (no atomicity across services)
- Wrapping everything in a god function (no separation of concerns)

## The Pattern: Context-Propagated Transactions

Three components work together:

1. **DBExecutor interface** — Unifies `*sql.DB` and `*sql.Tx` so services don't care which they're using.
2. **Transaction-in-context** — Store the active transaction in `context.Context` so it flows through service boundaries automatically.
3. **Transaction lifecycle hooks** — Register callbacks that fire on commit, rollback, or error for side effects that depend on transaction outcome.

## Component 1: DBExecutor Interface

Define a common interface satisfied by both `*sql.DB` (no transaction) and `*sql.Tx` (in transaction):

```go
type DBExecutor interface {
    ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
    PrepareContext(ctx context.Context, query string) (*sql.Stmt, error)
    QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
    QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// Compile-time interface checks
var (
    _ DBExecutor = (*sql.DB)(nil)
    _ DBExecutor = (*sql.Tx)(nil)
)
```

Services accept `DBExecutor` — they work identically whether called inside or outside a transaction.

## Component 2: Transaction in Context

Store and retrieve the active transaction via context:

```go
type txContextKey struct{}

// WithTx stores a transaction in the context.
func WithTx(ctx context.Context, tx *TxWithHooks) context.Context {
    return context.WithValue(ctx, txContextKey{}, tx)
}

// TxFromContext retrieves the transaction from context, if present.
func TxFromContext(ctx context.Context) (*TxWithHooks, bool) {
    tx, ok := ctx.Value(txContextKey{}).(*TxWithHooks)
    return tx, ok
}

// ExecutorFromContext returns the transaction if one exists in context,
// otherwise returns the fallback (typically *sql.DB).
func ExecutorFromContext(ctx context.Context, fallback DBExecutor) DBExecutor {
    if tx, ok := TxFromContext(ctx); ok {
        return tx
    }
    return fallback
}
```

### Usage in Services

Services call `ExecutorFromContext` to get whatever executor is active:

```go
type UserService struct {
    db *sql.DB
}

func (s *UserService) Create(ctx context.Context, name, email string) (*User, error) {
    exec := ExecutorFromContext(ctx, s.db)

    var user User
    err := exec.QueryRowContext(ctx,
        "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email",
        name, email,
    ).Scan(&user.ID, &user.Name, &user.Email)
    if err != nil {
        return nil, fmt.Errorf("inserting user: %w", err)
    }
    return &user, nil
}
```

This service works identically whether called directly (uses `*sql.DB`) or inside a transaction (uses the `*TxWithHooks` from context).

## Component 3: Transaction Lifecycle Hooks

Wrap `*sql.Tx` with hooks that fire based on the transaction outcome:

```go
type TxWithHooks struct {
    *sql.Tx
    commitHooks []func()
    revertHooks []func()
    errorHooks  []func(error)
    done        bool
}

func Wrap(tx *sql.Tx) *TxWithHooks {
    return &TxWithHooks{Tx: tx}
}

// OnCommit registers a callback to run after successful Commit.
func (t *TxWithHooks) OnCommit(fn func()) {
    t.commitHooks = append(t.commitHooks, fn)
}

// OnRevert registers a callback to run after Rollback or failed Commit.
func (t *TxWithHooks) OnRevert(fn func()) {
    t.revertHooks = append(t.revertHooks, fn)
}

// OnError registers a callback to run with the error when Commit fails.
func (t *TxWithHooks) OnError(fn func(error)) {
    t.errorHooks = append(t.errorHooks, fn)
}

func (t *TxWithHooks) Commit() error {
    err := t.Tx.Commit()
    if err != nil {
        t.fireError(err)
        t.fireRevert()
        return err
    }
    t.done = true
    t.fireCommit()
    return nil
}

func (t *TxWithHooks) Rollback() error {
    err := t.Tx.Rollback()
    if !t.done {
        t.done = true
        t.fireRevert()
    }
    return err
}
```

`TxWithHooks` also satisfies `DBExecutor` since it embeds `*sql.Tx`.

### When to Use Hooks

- **OnCommit** — Send notifications, publish events, invalidate caches. These should only happen if the data actually persisted.
- **OnRevert** — Clean up optimistic side effects (delete uploaded files, release reserved slots).
- **OnError** — Log the commit error, trigger alerts, record metrics.

```go
func (s *AppointmentService) Book(ctx context.Context, req BookRequest) (*Appointment, error) {
    exec := ExecutorFromContext(ctx, s.db)

    appt, err := insertAppointment(ctx, exec, req)
    if err != nil {
        return nil, err
    }

    // Only send confirmation if the transaction commits
    if tx, ok := TxFromContext(ctx); ok {
        tx.OnCommit(func() {
            s.notifier.SendConfirmation(appt.UserID, appt.ID)
        })
        tx.OnRevert(func() {
            s.slots.Release(appt.SlotID)
        })
    }

    return appt, nil
}
```

## The WithTransaction Helper

Ties everything together — starts a transaction, stores it in context, handles commit/rollback, and retries on serialization failures.

```go
func WithTransaction(ctx context.Context, db *sql.DB, opts *sql.TxOptions, fn func(ctx context.Context) error) error {
    // Join existing transaction if one is already in context.
    if _, ok := TxFromContext(ctx); ok {
        return fn(ctx)
    }

    var err error
    for attempt := range maxRetries {
        err = executeInTransaction(ctx, db, opts, fn)
        if err == nil || !isSerializationFailure(err) {
            return err
        }
    }
    return fmt.Errorf("transaction failed after %d retries: %w", maxRetries, err)
}

func executeInTransaction(ctx context.Context, db *sql.DB, opts *sql.TxOptions, fn func(ctx context.Context) error) (retErr error) {
    rawTx, err := db.BeginTx(ctx, opts)
    if err != nil {
        return fmt.Errorf("begin transaction: %w", err)
    }
    tx := Wrap(rawTx)
    defer func() {
        if p := recover(); p != nil {
            _ = tx.Rollback()
            panic(p)
        }
        if retErr != nil {
            _ = tx.Rollback()
        }
    }()

    txCtx := WithTx(ctx, tx)
    if err := fn(txCtx); err != nil {
        return err
    }
    return tx.Commit()
}
```

### Key Behaviors

1. **Join semantics** — If a transaction already exists in context, `WithTransaction` reuses it instead of starting a new one. This lets nested service calls share the same transaction automatically.
2. **Serialization retry** — On PostgreSQL SQLSTATE 40001 (serialization failure), the entire operation retries up to `maxRetries` times.
3. **Panic safety** — Panics inside `fn` trigger a rollback before the panic propagates.
4. **Hook execution** — Commit hooks fire only on successful commit. Revert hooks fire on rollback or failed commit.

### Generic Variant for Return Values

```go
func WithTransactionResult[T any](ctx context.Context, db *sql.DB, opts *sql.TxOptions, fn func(ctx context.Context) (T, error)) (T, error) {
    if _, ok := TxFromContext(ctx); ok {
        return fn(ctx)
    }
    // ... same retry and execution logic, returning (T, error)
}
```

## Full Example: Multi-Service Transaction

```go
func (h *Handler) RegisterPatient(ctx context.Context, req RegisterRequest) error {
    return db.WithTransaction(ctx, h.db, nil, func(ctx context.Context) error {
        // UserService.Create uses ExecutorFromContext internally
        user, err := h.userService.Create(ctx, req.Name, req.Email)
        if err != nil {
            return fmt.Errorf("creating user: %w", err)
        }

        // PatientService.Create also uses ExecutorFromContext — same transaction
        _, err = h.patientService.Create(ctx, user.ID, req.DateOfBirth)
        if err != nil {
            return fmt.Errorf("creating patient: %w", err)
        }

        // Schedule welcome appointment — same transaction
        _, err = h.appointmentService.Book(ctx, BookRequest{
            UserID: user.ID,
            Type:   "welcome",
        })
        if err != nil {
            return fmt.Errorf("booking welcome appointment: %w", err)
        }

        // All three services wrote to the same transaction.
        // If any fails, everything rolls back.
        // OnCommit hooks fire only after all three succeed.
        return nil
    })
}
```

### What Happens

- All three services call `ExecutorFromContext(ctx, s.db)` and get the same `*TxWithHooks`.
- If `appointmentService.Book` fails, the user and patient records roll back too.
- Any `OnCommit` hooks registered by the services (notifications, events) fire only after the final commit.
- Any `OnRevert` hooks fire if the transaction rolls back.

## File Organization

```
internal/db/
├── executor.go              # DBExecutor interface
├── tx_context.go            # WithTx, TxFromContext, ExecutorFromContext
├── transaction_helper.go    # WithTransaction, WithTransactionResult
└── txhooks/
    └── txhooks.go           # TxWithHooks (OnCommit, OnRevert, OnError)
```

## Rules

1. **Services always use `ExecutorFromContext`** — Never access `*sql.DB` directly for queries. Always go through `ExecutorFromContext(ctx, s.db)`.
2. **Only the outermost caller starts transactions** — Handlers or use-case functions call `WithTransaction`. Services are transaction-agnostic.
3. **Side effects go in hooks** — Notifications, event publishing, cache invalidation belong in `OnCommit`. Cleanup belongs in `OnRevert`.
4. **Never start a new transaction inside an existing one** — `WithTransaction` handles join semantics automatically. If a transaction exists in context, it's reused.
5. **Hooks must be idempotent and non-failing** — Hook callbacks should not return errors. If they can fail, handle the failure internally (log and continue).
