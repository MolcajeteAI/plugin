---
name: documentation-standards
description: godoc conventions and documentation best practices. Use when documenting code.
---

# Documentation Standards Skill

Go documentation conventions following godoc standards.

## When to Use

Use when writing or reviewing code documentation.

## Package Documentation

```go
// Package user provides user management functionality.
//
// This package handles user authentication, authorization,
// and profile management. It supports multiple authentication
// providers and role-based access control.
//
// Example usage:
//
//     svc := user.NewService(db)
//     user, err := svc.GetUser(ctx, userID)
//     if err != nil {
//         // handle error
//     }
//
package user
```

## Function Documentation

```go
// GetUser retrieves a user by ID.
//
// It returns an error if the user is not found or if
// the database connection fails.
//
// Example:
//
//     user, err := GetUser(ctx, 1)
//     if errors.Is(err, ErrNotFound) {
//         // handle not found
//     }
//
func GetUser(ctx context.Context, id int) (*User, error) {
    // implementation
}
```

## Type Documentation

```go
// User represents a system user with authentication details.
type User struct {
    // ID is the unique identifier for the user.
    ID int

    // Name is the user's display name.
    Name string

    // Email is the user's email address.
    // It must be unique across all users.
    Email string
}
```

## Example Functions

```go
// ExampleGetUser demonstrates how to retrieve a user.
func ExampleGetUser() {
    svc := NewService(db)
    user, err := svc.GetUser(context.Background(), 1)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(user.Name)
    // Output: John Doe
}
```

## godoc Conventions

1. **Start with symbol name** - "GetUser retrieves..."
2. **Complete sentences** - Proper grammar and punctuation
3. **No empty lines** - Between comment and declaration
4. **Explain behavior** - What it does, not how
5. **Document errors** - What errors can be returned
6. **Provide examples** - For non-obvious usage

## README.md Structure

```markdown
# Project Name

Brief description.

## Installation

\`\`\`bash
go get github.com/user/project
\`\`\`

## Usage

\`\`\`go
package main

import "github.com/user/project"

func main() {
    // example code
}
\`\`\`

## Features

- Feature 1
- Feature 2

## Building

\`\`\`bash
make build
\`\`\`

## Testing

\`\`\`bash
make test
\`\`\`

## License

MIT
```

## Best Practices

1. **Document all exports** - Public functions, types, constants
2. **Be concise** - Clear but brief
3. **Use examples** - For complex APIs
4. **Keep updated** - Sync with code changes
5. **Format correctly** - Follow godoc conventions
6. **Link related items** - Reference related functions
7. **Explain non-obvious** - Document "why", not "what"
