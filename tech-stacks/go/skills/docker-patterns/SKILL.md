---
name: docker-patterns
description: Docker containerization best practices. Use when creating Dockerfiles.
---

# Docker Patterns Skill

Docker containerization best practices for Go.

## When to Use

Use when creating or optimizing Docker images.

## Multi-Stage Dockerfile

```dockerfile
# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/app/main.go

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
```

## Distroless Image

```dockerfile
# Build stage
FROM golang:1.23 AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o main cmd/app/main.go

# Runtime stage
FROM gcr.io/distroless/static-debian11
COPY --from=builder /app/main /
CMD ["/main"]
```

## Docker Compose

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

## .dockerignore

```
bin/
.git/
.gitignore
*.md
.env
.vscode/
.idea/
*.test
coverage.out
```

## Best Practices

1. **Multi-stage builds** - Small final images
2. **Static binaries** - CGO_ENABLED=0
3. **Small base images** - Alpine or distroless
4. **Layer caching** - Copy go.mod before source
5. **Health checks** - Add HEALTHCHECK instruction
6. **Non-root user** - Run as non-root
7. **.dockerignore** - Exclude unnecessary files
8. **Security** - Scan with trivy

## Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
```
