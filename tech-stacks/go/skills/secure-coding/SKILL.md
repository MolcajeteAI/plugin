---
name: secure-coding
description: Security best practices for Go applications. Use when writing security-sensitive code.
---

# Secure Coding Skill

Security best practices following OWASP guidelines.

## When to Use

Use when writing or reviewing security-sensitive code.

## Input Validation

```go
// Good - validate and sanitize
func GetUser(w http.ResponseWriter, r *http.Request) {
    idStr := r.URL.Query().Get("id")
    id, err := strconv.Atoi(idStr)
    if err != nil || id < 1 {
        http.Error(w, "invalid ID", http.StatusBadRequest)
        return
    }
    // use id safely
}
```

## SQL Injection Prevention

```go
// Bad - SQL injection vulnerable
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Query(query)

// Good - parameterized query
query := "SELECT * FROM users WHERE id = ?"
db.Query(query, userID)

// Good - named parameters
query := "SELECT * FROM users WHERE id = :id"
db.NamedQuery(query, map[string]interface{}{"id": userID})
```

## Command Injection Prevention

```go
// Bad - shell injection
cmd := exec.Command("sh", "-c", "echo "+userInput)

// Good - avoid shell
cmd := exec.Command("echo", userInput)

// Good - validate input
if !isValidInput(userInput) {
    return errors.New("invalid input")
}
```

## Path Traversal Prevention

```go
// Good - validate and clean paths
func serveFile(filename string) error {
    // Validate filename
    clean := filepath.Clean(filename)
    if strings.Contains(clean, "..") {
        return errors.New("invalid path")
    }

    // Ensure it's in allowed directory
    basePath := "/var/www/files"
    fullPath := filepath.Join(basePath, clean)
    if !strings.HasPrefix(fullPath, basePath) {
        return errors.New("path outside allowed directory")
    }

    return ioutil.ReadFile(fullPath)
}
```

## Cryptography Best Practices

```go
import "crypto/rand"

// Good - crypto/rand for randomness
func generateToken() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", err
    }
    return base64.URLEncoding.EncodeToString(b), nil
}

// Bad - math/rand is not cryptographically secure
func badToken() string {
    return fmt.Sprintf("%d", rand.Int())
}
```

## Password Hashing

```go
import "golang.org/x/crypto/bcrypt"

// Hash password
func hashPassword(password string) (string, error) {
    hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(hash), err
}

// Verify password
func verifyPassword(hash, password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

## Secrets Management

```go
// Good - environment variables
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    log.Fatal("API_KEY not set")
}

// Bad - hardcoded secrets
const apiKey = "sk_live_xxxxx" // Never do this!
```

## CORS Configuration

```go
// Good - specific origins
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        origin := r.Header.Get("Origin")
        if isAllowedOrigin(origin) {
            w.Header().Set("Access-Control-Allow-Origin", origin)
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        }
        next.ServeHTTP(w, r)
    })
}

// Bad - allow all origins
w.Header().Set("Access-Control-Allow-Origin", "*")
```

## Best Practices

1. **Validate all inputs** - Never trust user data
2. **Use parameterized queries** - Prevent SQL injection
3. **Avoid shell execution** - Use exec.Command directly
4. **Use crypto/rand** - Not math/rand
5. **Hash passwords** - Use bcrypt
6. **Store secrets securely** - Environment variables or secret managers
7. **Validate file paths** - Prevent traversal
8. **Use HTTPS** - Always
9. **Set security headers** - CSP, X-Frame-Options, etc.
10. **Keep dependencies updated** - Run govulncheck
