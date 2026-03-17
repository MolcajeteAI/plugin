# Concurrency in Go

## Goroutine Lifecycle Management

Every goroutine must have a clear owner and a clear termination path. Leaked goroutines consume memory and CPU indefinitely.

### Rule: Always Use Context for Cancellation

```go
func (s *Server) processQueue(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case msg := <-s.queue:
            if err := s.handle(ctx, msg); err != nil {
                log.Printf("handling message: %v", err)
            }
        }
    }
}
```

### Rule: WaitGroup for Goroutine Completion

```go
func (s *Service) ProcessBatch(ctx context.Context, items []Item) error {
    var wg sync.WaitGroup
    errs := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func() {
            defer wg.Done()
            if err := s.process(ctx, item); err != nil {
                errs <- err
            }
        }()
    }

    wg.Wait()
    close(errs)

    for err := range errs {
        return fmt.Errorf("batch processing: %w", err)
    }
    return nil
}
```

## Worker Pool Pattern

Limit concurrency for resource-intensive operations.

```go
func ProcessItems(ctx context.Context, items []Item, workers int) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(workers)

    for _, item := range items {
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}
```

### Manual Worker Pool (More Control)

```go
func WorkerPool(ctx context.Context, items []Item, workers int) error {
    jobs := make(chan Item, len(items))
    g, ctx := errgroup.WithContext(ctx)

    // Start workers
    for range workers {
        g.Go(func() error {
            for item := range jobs {
                select {
                case <-ctx.Done():
                    return ctx.Err()
                default:
                    if err := processItem(ctx, item); err != nil {
                        return err
                    }
                }
            }
            return nil
        })
    }

    // Send jobs
    for _, item := range items {
        select {
        case <-ctx.Done():
            break
        case jobs <- item:
        }
    }
    close(jobs)

    return g.Wait()
}
```

## Fan-Out / Fan-In

Distribute work across goroutines (fan-out) and collect results (fan-in).

```go
func FanOutFanIn(ctx context.Context, urls []string) ([]Result, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]Result, len(urls))

    for i, url := range urls {
        g.Go(func() error {
            result, err := fetch(ctx, url)
            if err != nil {
                return err
            }
            results[i] = result // safe: each goroutine writes to unique index
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

### Fan-In with Channels

```go
func FanIn(ctx context.Context, channels ...<-chan Result) <-chan Result {
    merged := make(chan Result)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for result := range ch {
                select {
                case <-ctx.Done():
                    return
                case merged <- result:
                }
            }
        }()
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

## Sync Primitives

### sync.Mutex — Protect Shared State

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.count
}
```

### sync.RWMutex — Multiple Readers, Single Writer

```go
type Cache struct {
    mu    sync.RWMutex
    items map[string]string
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    val, ok := c.items[key]
    return val, ok
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = value
}
```

### sync.Once — One-Time Initialization

```go
type DBPool struct {
    once sync.Once
    pool *pgxpool.Pool
}

func (d *DBPool) Get(ctx context.Context) (*pgxpool.Pool, error) {
    var err error
    d.once.Do(func() {
        d.pool, err = pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
    })
    return d.pool, err
}
```

### sync.Pool — Reuse Temporary Objects

Use for frequently allocated, short-lived objects in hot paths.

```go
var bufPool = sync.Pool{
    New: func() any {
        return new(bytes.Buffer)
    },
}

func ProcessRequest(data []byte) string {
    buf := bufPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufPool.Put(buf)
    }()

    buf.Write(data)
    // ... process
    return buf.String()
}
```

## Channel Patterns

### Done Channel (Pre-Context Pattern)

```go
func worker(done <-chan struct{}, jobs <-chan Job) {
    for {
        select {
        case <-done:
            return
        case job, ok := <-jobs:
            if !ok {
                return
            }
            process(job)
        }
    }
}
```

### Timeout with Channel

```go
func fetchWithTimeout(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}
```

### Pipeline

```go
func pipeline(ctx context.Context, input <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range input {
            select {
            case <-ctx.Done():
                return
            case out <- n * 2:
            }
        }
    }()
    return out
}
```

## Common Pitfalls

### Goroutine Leak — Blocked Channel Send

```go
// ❌ Goroutine leaks if nobody reads from ch
func leaky() <-chan int {
    ch := make(chan int)
    go func() {
        ch <- expensiveComputation() // blocks forever if nobody reads
    }()
    return ch
}

// ✅ Use buffered channel or context
func safe(ctx context.Context) <-chan int {
    ch := make(chan int, 1) // buffered: goroutine won't block
    go func() {
        select {
        case ch <- expensiveComputation():
        case <-ctx.Done():
        }
    }()
    return ch
}
```

### Race Condition — Unsynchronized Map Access

```go
// ❌ Data race
func unsafeMap() {
    m := make(map[string]int)
    go func() { m["a"] = 1 }()
    go func() { m["b"] = 2 }()
}

// ✅ Use sync.Mutex or sync.Map
func safeMap() {
    var mu sync.Mutex
    m := make(map[string]int)
    go func() {
        mu.Lock()
        m["a"] = 1
        mu.Unlock()
    }()
    go func() {
        mu.Lock()
        m["b"] = 2
        mu.Unlock()
    }()
}
```

### Deadlock — Lock Ordering

```go
// ❌ Potential deadlock: goroutine 1 locks A then B, goroutine 2 locks B then A
// ✅ Always acquire locks in the same order across all goroutines
```

### Closing Channels

- **Only the sender closes the channel** — Never close a channel from the receiver side.
- **Close once** — Closing an already-closed channel panics. Use `sync.Once` if multiple senders.
- **Don't close channels you don't own** — If a function receives a channel, it should not close it.
