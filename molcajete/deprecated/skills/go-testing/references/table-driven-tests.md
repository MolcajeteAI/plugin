# Table-Driven Tests in Go

## Basic Pattern

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {name: "positive numbers", a: 2, b: 3, want: 5},
        {name: "negative numbers", a: -1, b: -2, want: -3},
        {name: "zero", a: 0, b: 0, want: 0},
        {name: "mixed signs", a: -1, b: 5, want: 4},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

## Parallel Subtests

Run subtests in parallel when they don't share mutable state. This speeds up test execution.

```go
func TestFetchUser(t *testing.T) {
    tests := []struct {
        name    string
        id      string
        want    *User
        wantErr bool
    }{
        {name: "existing user", id: "123", want: &User{ID: "123", Name: "Alice"}},
        {name: "nonexistent user", id: "999", wantErr: true},
        {name: "empty id", id: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            got, err := FetchUser(tt.id)
            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got.ID != tt.want.ID || got.Name != tt.want.Name {
                t.Errorf("FetchUser(%q) = %+v, want %+v", tt.id, got, tt.want)
            }
        })
    }
}
```

### Parallel Safety Rules

- Add `t.Parallel()` as the first line in the subtest.
- Don't share mutable state between subtests.
- Each subtest must only read from `tt` (its own test case).
- Don't modify the test fixture or any shared data structure.

## Error Testing Pattern

```go
func TestParseConfig(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *Config
        wantErr string // expected error substring, empty if no error expected
    }{
        {
            name:  "valid config",
            input: `{"port": 8080}`,
            want:  &Config{Port: 8080},
        },
        {
            name:    "invalid JSON",
            input:   `{invalid}`,
            wantErr: "invalid character",
        },
        {
            name:    "missing port",
            input:   `{}`,
            wantErr: "port is required",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseConfig(tt.input)
            if tt.wantErr != "" {
                if err == nil {
                    t.Fatalf("expected error containing %q, got nil", tt.wantErr)
                }
                if !strings.Contains(err.Error(), tt.wantErr) {
                    t.Fatalf("error %q does not contain %q", err.Error(), tt.wantErr)
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("ParseConfig() = %+v, want %+v", got, tt.want)
            }
        })
    }
}
```

## Cleanup in Subtests

Use `t.Cleanup` for teardown that should run after each subtest.

```go
func TestDatabaseOperations(t *testing.T) {
    tests := []struct {
        name  string
        setup func(db *sql.DB) // per-test setup
        test  func(t *testing.T, db *sql.DB)
    }{
        {
            name: "insert user",
            setup: func(db *sql.DB) {
                // no setup needed
            },
            test: func(t *testing.T, db *sql.DB) {
                err := InsertUser(db, "alice")
                if err != nil {
                    t.Fatalf("inserting user: %v", err)
                }
            },
        },
        {
            name: "find existing user",
            setup: func(db *sql.DB) {
                InsertUser(db, "bob")
            },
            test: func(t *testing.T, db *sql.DB) {
                user, err := FindUser(db, "bob")
                if err != nil {
                    t.Fatalf("finding user: %v", err)
                }
                if user.Name != "bob" {
                    t.Errorf("got name %q, want %q", user.Name, "bob")
                }
            },
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            db := setupTestDB(t) // creates a fresh DB
            t.Cleanup(func() {
                db.Close()
            })

            tt.setup(db)
            tt.test(t, db)
        })
    }
}
```

## Golden File Testing

Compare output against a stored "golden" file. Useful for large outputs (JSON, HTML, SQL).

```go
func TestRenderTemplate(t *testing.T) {
    tests := []struct {
        name string
        data TemplateData
    }{
        {name: "basic", data: TemplateData{Title: "Hello"}},
        {name: "with_items", data: TemplateData{Title: "List", Items: []string{"a", "b"}}},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := RenderTemplate(tt.data)

            goldenFile := filepath.Join("testdata", tt.name+".golden")

            if *update {
                os.MkdirAll("testdata", 0o755)
                os.WriteFile(goldenFile, []byte(got), 0o644)
                return
            }

            want, err := os.ReadFile(goldenFile)
            if err != nil {
                t.Fatalf("reading golden file: %v", err)
            }

            if got != string(want) {
                t.Errorf("output mismatch.\nGot:\n%s\nWant:\n%s", got, string(want))
            }
        })
    }
}

var update = flag.Bool("update", false, "update golden files")
```

Usage:
```bash
# Update golden files
go test -run TestRenderTemplate -update ./...

# Compare against golden files
go test -run TestRenderTemplate ./...
```

## Struct Comparison

### reflect.DeepEqual

```go
if !reflect.DeepEqual(got, want) {
    t.Errorf("mismatch:\ngot:  %+v\nwant: %+v", got, want)
}
```

### cmp.Diff (Better Output)

```go
import "github.com/google/go-cmp/cmp"

if diff := cmp.Diff(want, got); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

### Ignoring Fields

```go
if diff := cmp.Diff(want, got, cmpopts.IgnoreFields(User{}, "CreatedAt", "UpdatedAt")); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## When NOT to Use Table-Driven Tests

- **Single test case** — Just write a regular test function.
- **Complex setup per case** — If each case needs significantly different setup, individual test functions are clearer.
- **Tests that tell a story** — Sequential tests where each builds on the previous (e.g., create → update → delete).
- **Tests with complex assertions** — When the check logic varies significantly between cases.
