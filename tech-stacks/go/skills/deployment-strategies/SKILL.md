---
name: deployment-strategies
description: Deployment strategies for Go applications. Use when deploying applications.
---

# Deployment Strategies Skill

Deployment patterns for Go applications.

## When to Use

Use when deploying Go applications to various platforms.

## Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          value: postgres
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## AWS Lambda

```go
package main

import (
    "context"
    "github.com/aws/aws-lambda-go/lambda"
)

type Request struct {
    Name string `json:"name"`
}

type Response struct {
    Message string `json:"message"`
}

func handler(ctx context.Context, req Request) (Response, error) {
    return Response{
        Message: "Hello " + req.Name,
    }, nil
}

func main() {
    lambda.Start(handler)
}
```

## Google Cloud Run

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o server

FROM alpine:latest
COPY --from=builder /app/server /server
CMD ["/server"]
```

Deploy:
```bash
gcloud run deploy myapp --source . --region us-central1
```

## Best Practices

1. **Health checks** - Implement /health and /ready endpoints
2. **Resource limits** - Set CPU/memory limits
3. **Graceful shutdown** - Handle SIGTERM
4. **Configuration** - Use environment variables
5. **Logging** - Structured logging to stdout
6. **Monitoring** - Prometheus metrics
7. **Secrets** - Use secret managers
8. **Zero-downtime** - Rolling updates

## Graceful Shutdown

```go
func main() {
    srv := &http.Server{Addr: ":8080"}

    go func() {
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    // Wait for interrupt
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
    <-quit

    // Graceful shutdown
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal(err)
    }
}
```
