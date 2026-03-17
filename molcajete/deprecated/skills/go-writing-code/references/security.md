# Security in Go

## Input Validation

Validate all external input at system boundaries — HTTP handlers, GraphQL resolvers, CLI arguments. Once validated, pass typed values internally.

### Validation Rules

```go
func validateCreateUserRequest(req CreateUserRequest) error {
    if req.Name == "" {
        return fmt.Errorf("name is required")
    }
    if len(req.Name) > 100 {
        return fmt.Errorf("name must be 100 characters or fewer")
    }
    if !isValidEmail(req.Email) {
        return fmt.Errorf("invalid email format")
    }
    if len(req.Password) < 8 {
        return fmt.Errorf("password must be at least 8 characters")
    }
    return nil
}
```

### Parse, Don't Validate

Transform raw input into domain types early. Once parsed, the type guarantees validity throughout the system.

```go
type Email string

func ParseEmail(raw string) (Email, error) {
    raw = strings.TrimSpace(strings.ToLower(raw))
    if !emailRegex.MatchString(raw) {
        return "", fmt.Errorf("invalid email: %q", raw)
    }
    return Email(raw), nil
}

// After parsing, Email is always valid — no re-validation needed
func (s *Service) CreateUser(ctx context.Context, name string, email Email) (*User, error) {
    // email is guaranteed valid
}
```

### Numeric Validation

```go
func validateAge(age int) error {
    if age < 0 || age > 150 {
        return fmt.Errorf("age must be between 0 and 150, got %d", age)
    }
    return nil
}

func validatePagination(page, perPage int) error {
    if page < 1 {
        return fmt.Errorf("page must be >= 1")
    }
    if perPage < 1 || perPage > 100 {
        return fmt.Errorf("perPage must be between 1 and 100")
    }
    return nil
}
```

## SQL Injection Prevention

### Always Use Parameterized Queries

```go
// ✅ Correct — parameterized with pgx
row := db.QueryRow(ctx,
    "SELECT id, name, email FROM users WHERE id = $1", userID)

// ✅ Correct — multiple parameters
rows, err := db.Query(ctx,
    "SELECT * FROM appointments WHERE user_id = $1 AND status = $2",
    userID, status)

// ❌ NEVER concatenate user input into SQL
row := db.QueryRow(ctx,
    "SELECT * FROM users WHERE id = " + userID) // SQL INJECTION

// ❌ NEVER use fmt.Sprintf for SQL
query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", name) // SQL INJECTION
```

### Dynamic Queries with Safe Patterns

```go
// Safe dynamic WHERE clauses
func buildQuery(filters Filters) (string, []any) {
    query := "SELECT * FROM users WHERE 1=1"
    args := []any{}
    argNum := 1

    if filters.Name != "" {
        query += fmt.Sprintf(" AND name = $%d", argNum)
        args = append(args, filters.Name)
        argNum++
    }
    if filters.Active != nil {
        query += fmt.Sprintf(" AND active = $%d", argNum)
        args = append(args, *filters.Active)
        argNum++
    }

    // Safe ORDER BY — validate against allowed columns
    allowedSorts := map[string]bool{"name": true, "created_at": true, "email": true}
    if allowedSorts[filters.SortBy] {
        query += " ORDER BY " + filters.SortBy
    }

    return query, args
}
```

## Password Hashing with bcrypt

```go
import "golang.org/x/crypto/bcrypt"

// Hash a password
func HashPassword(password string) (string, error) {
    hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return "", fmt.Errorf("hashing password: %w", err)
    }
    return string(hash), nil
}

// Verify a password
func CheckPassword(hash, password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

### Rules

- **Never store plaintext passwords** — Always hash with bcrypt.
- **Use `bcrypt.DefaultCost`** — Currently 10. Increase if hardware improves.
- **Constant-time comparison** — `bcrypt.CompareHashAndPassword` already handles this.
- **Don't reveal which field failed** — Return "invalid credentials" for both wrong email and wrong password.

## CORS Configuration

```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        origin := r.Header.Get("Origin")

        // Check against allowed origins
        if isAllowedOrigin(origin) {
            w.Header().Set("Access-Control-Allow-Origin", origin)
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
            w.Header().Set("Access-Control-Allow-Credentials", "true")
            w.Header().Set("Access-Control-Max-Age", "86400")
        }

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusNoContent)
            return
        }

        next.ServeHTTP(w, r)
    })
}

func isAllowedOrigin(origin string) bool {
    allowed := []string{
        "https://example.com",
        "https://app.example.com",
    }
    for _, a := range allowed {
        if origin == a {
            return true
        }
    }
    return false
}
```

### CORS Rules

- **Never use `*` with credentials** — The browser rejects it.
- **Whitelist specific origins** — Don't reflect the `Origin` header blindly.
- **Limit allowed methods** — Only expose what the API actually supports.
- **Set `Max-Age`** — Reduces preflight requests. 86400 (24 hours) is common.

## Encryption at Rest

### Encrypting PII

```go
import (
    "crypto/aes"
    "crypto/cipher"
    "crypto/rand"
    "crypto/sha256"
    "encoding/hex"
)

func Encrypt(plaintext string, key []byte) (string, error) {
    block, err := aes.NewCipher(key)
    if err != nil {
        return "", err
    }

    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return "", err
    }

    nonce := make([]byte, gcm.NonceSize())
    if _, err := rand.Read(nonce); err != nil {
        return "", err
    }

    ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
    return hex.EncodeToString(ciphertext), nil
}
```

### SHA-256 Hash for Indexed Lookups

When you need to search encrypted fields (e.g., find user by email), store a deterministic hash alongside the encrypted value.

```go
func HashForLookup(value string) string {
    h := sha256.Sum256([]byte(strings.ToLower(strings.TrimSpace(value))))
    return hex.EncodeToString(h[:])
}

// Store: encrypted email + email_hash
// Search: WHERE email_hash = HashForLookup(searchEmail)
```

## Secrets Management

### Rules

- **Never hardcode secrets** — No API keys, passwords, or tokens in source code.
- **Use environment variables** — `os.Getenv("DATABASE_URL")`.
- **Fail fast on missing secrets** — Check for required env vars at startup.
- **Never log secrets** — Sanitize log output. Mask tokens and keys.

```go
func LoadConfig() (*Config, error) {
    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        return nil, fmt.Errorf("DATABASE_URL is required")
    }

    jwtSecret := os.Getenv("JWT_SECRET")
    if jwtSecret == "" {
        return nil, fmt.Errorf("JWT_SECRET is required")
    }

    return &Config{
        DatabaseURL: dbURL,
        JWTSecret:   jwtSecret,
    }, nil
}
```

## Rate Limiting

```go
import "golang.org/x/time/rate"

func RateLimitMiddleware(rps float64, burst int) func(http.Handler) http.Handler {
    limiter := rate.NewLimiter(rate.Limit(rps), burst)

    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

For per-client rate limiting, use a map of limiters keyed by IP or user ID, protected by a `sync.Mutex`.
