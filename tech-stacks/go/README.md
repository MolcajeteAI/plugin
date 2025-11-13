# Go Development Plugin

Comprehensive Go development toolkit enforcing YAGNI/KISS principles, Makefile-driven builds, and Go community best practices.

## Quick Start

### Initialize a New Project
```bash
/go:init
```

Creates a new Go project with:
- Proper directory structure (cmd/, internal/, pkg/)
- Makefile with all standard targets
- go.mod initialization
- .gitignore with bin/ directory
- README with build instructions

### Build and Run
```bash
/go:build    # Builds to ./bin/ using Makefile
/go:run      # Runs the application
```

### Testing
```bash
/go:test           # Run tests
/go:test-race      # Run with race detector
/go:coverage       # Generate coverage report
/go:bench          # Run benchmarks
```

### Code Quality
```bash
/go:fmt      # Format code (always run after changes!)
/go:lint     # Run golangci-lint
/go:vet      # Run go vet
```

### Security
```bash
/go:sec-scan      # Run gosec and govulncheck
/go:vuln-check    # Check dependencies for vulnerabilities
```

### Performance
```bash
/go:profile      # Profile CPU, memory, or goroutines
/go:optimize     # Analyze and suggest optimizations
```

### Deployment
```bash
/go:docker-build    # Build optimized Docker image
/go:deploy          # Deploy to target platform
```

## Core Principles

1. **YAGNI** - Write only what's needed now
2. **KISS** - Keep it simple, optimize after profiling
3. **Readability** - Clear code over clever code
4. **go fmt** - Always format after changes
5. **Makefile** - Use make build, never go build directly
6. **./bin/** - All binaries go here, never project root

## Project Structure

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── service/
│   └── repository/
├── pkg/
│   └── util/
├── bin/              # Build output (gitignored)
│   └── myapp
├── go.mod
├── Makefile          # REQUIRED
└── .gitignore        # Must include bin/
```

## Agents

- **go:developer** - Idiomatic Go development
- **go:tester** - Comprehensive testing
- **go:optimizer** - Performance optimization
- **go:security** - Security scanning
- **go:deployer** - Docker & deployment
- **go:api-builder** - REST/gRPC APIs
- **go:debugger** - Debug tests & runtime
- **go:documenter** - godoc documentation

## Requirements

- Go >= 1.21
- make (for Makefile)
- golangci-lint (recommended)
- gosec (recommended)
- govulncheck (recommended)
- Docker (for containerization)

## Learn More

See [PLUGIN.md](./PLUGIN.md) for complete documentation.
