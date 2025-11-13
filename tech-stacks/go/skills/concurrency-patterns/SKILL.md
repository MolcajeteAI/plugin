---
name: concurrency-patterns
description: Goroutines, channels, and sync patterns for concurrent programming. Use when implementing concurrent operations.
---

# Concurrency Patterns Skill

Go concurrency patterns using goroutines, channels, and synchronization primitives.

## When to Use

Use this skill when:
- Implementing concurrent operations
- Managing goroutines
- Using channels for communication
- Synchronizing concurrent access

## Goroutines

### Basic Usage

```go
// Start a goroutine
go func() {
    fmt.Println("Hello from goroutine")
}()

// With parameters
go processItem(item)

// Anonymous function with closure
for _, item := range items {
    item := item // capture range variable
    go func() {
        process(item)
    }()
}
```

### Context for Cancellation

```go
func worker(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            doWork()
        }
    }
}

ctx, cancel := context.WithCancel(context.Background())
go worker(ctx)
// Later...
cancel() // stop the worker
```

## Channels

### Basic Patterns

```go
// Unbuffered channel
ch := make(chan int)

// Buffered channel
ch := make(chan int, 10)

// Send
ch <- 42

// Receive
value := <-ch

// Receive with ok
value, ok := <-ch
if !ok {
    // channel closed
}

// Close
close(ch)
```

### Fan-Out/Fan-In

```go
func fanOut(input <-chan int, workers int) []<-chan int {
    channels := make([]<-chan int, workers)
    for i := 0; i < workers; i++ {
        channels[i] = worker(input)
    }
    return channels
}

func fanIn(channels ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for v := range c {
                out <- v
            }
        }(ch)
    }

    go func() {
        wg.Wait()
        close(out)
    }()

    return out
}
```

### Pipeline Pattern

```go
func generator(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for _, n := range nums {
            out <- n
        }
    }()
    return out
}

func square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            out <- n * n
        }
    }()
    return out
}

// Usage
nums := generator(1, 2, 3, 4)
squares := square(nums)
for v := range squares {
    fmt.Println(v)
}
```

## Worker Pools

```go
func workerPool(ctx context.Context, jobs <-chan Job, results chan<- Result, numWorkers int) {
    var wg sync.WaitGroup

    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for {
                select {
                case <-ctx.Done():
                    return
                case job, ok := <-jobs:
                    if !ok {
                        return
                    }
                    result := processJob(job)
                    select {
                    case results <- result:
                    case <-ctx.Done():
                        return
                    }
                }
            }
        }()
    }

    wg.Wait()
    close(results)
}
```

## Synchronization

### sync.WaitGroup

```go
var wg sync.WaitGroup

for i := 0; i < 10; i++ {
    wg.Add(1)
    go func(id int) {
        defer wg.Done()
        process(id)
    }(i)
}

wg.Wait() // wait for all goroutines
```

### sync.Mutex

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Inc() {
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

### sync.RWMutex

```go
type Cache struct {
    mu    sync.RWMutex
    items map[string]*Item
}

func (c *Cache) Get(key string) *Item {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.items[key]
}

func (c *Cache) Set(key string, item *Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}
```

### sync.Once

```go
var (
    instance *Singleton
    once     sync.Once
)

func GetInstance() *Singleton {
    once.Do(func() {
        instance = &Singleton{}
    })
    return instance
}
```

## errgroup

```go
import "golang.org/x/sync/errgroup"

func processParallel(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item // capture
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }

    return g.Wait() // returns first error
}
```

## Select Statement

```go
func handleRequests(ctx context.Context, requests <-chan Request, timeout time.Duration) {
    for {
        select {
        case <-ctx.Done():
            return
        case req := <-requests:
            processRequest(req)
        case <-time.After(timeout):
            log.Println("timeout")
        }
    }
}
```

## Avoiding Goroutine Leaks

### Always Provide Exit Path

```go
// Good - can be stopped
func worker(ctx context.Context) {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return // exit path
        case <-ticker.C:
            doWork()
        }
    }
}

// Bad - goroutine leak
func worker() {
    ticker := time.NewTicker(time.Second)
    for range ticker.C {
        doWork() // no way to stop
    }
}
```

### Close Channels to Signal Completion

```go
func generator(done <-chan struct{}) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for i := 0; ; i++ {
            select {
            case out <- i:
            case <-done:
                return
            }
        }
    }()
    return out
}
```

## Best Practices

1. **Use context for cancellation** - Pass context.Context
2. **Avoid shared memory** - Communicate via channels
3. **Close channels from sender** - Not receiver
4. **Check channel closure** - Use `value, ok := <-ch`
5. **Capture range variables** - In goroutine loops
6. **Use WaitGroup** - To wait for goroutines
7. **Defer mutex unlocks** - Prevent deadlocks
8. **Provide exit paths** - Prevent goroutine leaks
9. **Use errgroup** - For error handling
10. **Profile concurrent code** - Use race detector

## Common Pitfalls

### Forgetting to Capture Loop Variable

```go
// Bad
for _, item := range items {
    go func() {
        process(item) // wrong item!
    }()
}

// Good
for _, item := range items {
    item := item // capture
    go func() {
        process(item)
    }()
}
```

### Goroutine Leak

```go
// Bad - leaks goroutine
func leak() {
    ch := make(chan int)
    go func() {
        ch <- 1 // blocks forever if no receiver
    }()
}

// Good - can complete
func noLeak() {
    ch := make(chan int, 1) // buffered
    go func() {
        ch <- 1 // won't block
    }()
}
```

### Race Conditions

```go
// Bad - data race
var counter int
for i := 0; i < 10; i++ {
    go func() {
        counter++ // race!
    }()
}

// Good - synchronized
var mu sync.Mutex
var counter int
for i := 0; i < 10; i++ {
    go func() {
        mu.Lock()
        counter++
        mu.Unlock()
    }()
}
```
