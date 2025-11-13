---
name: testing-patterns
description: Table-driven tests, mocking strategies, and comprehensive testing patterns. Use when writing tests.
---

# Testing Patterns Skill

Comprehensive Go testing patterns following community best practices.

## When to Use

Use this skill when writing or reviewing tests.

## Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
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

## Using Testify

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestService_GetUser(t *testing.T) {
    svc := NewService()
    user, err := svc.GetUser(1)

    require.NoError(t, err)
    assert.Equal(t, "John", user.Name)
    assert.Greater(t, user.ID, 0)
}
```

## Mocking with Interfaces

```go
type UserRepository interface {
    GetUser(id int) (*User, error)
}

type mockUserRepo struct {
    users map[int]*User
}

func (m *mockUserRepo) GetUser(id int) (*User, error) {
    if user, ok := m.users[id]; ok {
        return user, nil
    }
    return nil, ErrNotFound
}

func TestService(t *testing.T) {
    repo := &mockUserRepo{
        users: map[int]*User{
            1: {ID: 1, Name: "John"},
        },
    }
    svc := NewService(repo)
    // test with mock
}
```

## HTTP Testing

```go
func TestHandler(t *testing.T) {
    req := httptest.NewRequest("GET", "/users/1", nil)
    w := httptest.NewRecorder()

    handler := NewHandler(mockService)
    handler.GetUser(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Body.String(), "John")
}
```

## Best Practices

- Use table-driven tests
- Test one thing per test
- Use testify for clarity
- Mock external dependencies
- Test edge cases
- Run with race detector: `go test -race`
