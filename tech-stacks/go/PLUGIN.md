# Go Development Plugin

Professional Go development toolkit with YAGNI/KISS principles, Makefile-driven builds, and comprehensive lifecycle support.

## Plugin ID

`go`

## Description

Comprehensive Go development assistance from project initialization through deployment, enforcing Go community best practices and modern development principles.

## Core Development Philosophy

1. **YAGNI (You Aren't Gonna Need It)** - Only implement current requirements
2. **KISS (Keep It Simple, Stupid)** - Simple solutions, optimize after profiling
3. **Readability First** - Clear, maintainable code
4. **Consistent Formatting** - Always run `go fmt` after changes
5. **Makefile-Driven Builds** - Every project has a Makefile
6. **Clean Build Structure** - Binaries go to `./bin/`, never project root

## Specialized Agents

### 1. go:developer
**Use PROACTIVELY** to implement Go applications following idiomatic patterns, YAGNI/KISS principles, and proper error handling.

**Capabilities:**
- go-development
- idiomatic-code
- error-handling
- package-design

**Tools:** Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion

### 2. go:tester
**Use PROACTIVELY** to write comprehensive tests (unit, integration, benchmarks) with table-driven patterns and proper mocking.

**Capabilities:**
- unit-testing
- integration-testing
- benchmarking
- test-coverage

**Tools:** Read, Write, Edit, Bash, Grep, Glob

### 3. go:optimizer
Profiles and optimizes Go applications for performance using pprof and benchmarking.

**Capabilities:**
- cpu-profiling
- memory-profiling
- optimization
- benchmarking

**Tools:** Read, Edit, Bash, Grep, Glob

### 4. go:security
Performs security analysis using gosec, govulncheck, and manual code review (READ-ONLY).

**Capabilities:**
- security-scanning
- vulnerability-detection
- secure-code-review

**Tools:** Read, Bash, Grep, Glob

### 5. go:deployer
Builds Docker images and deploys Go applications to various platforms.

**Capabilities:**
- docker-containerization
- kubernetes-deployment
- deployment-validation

**Tools:** Read, Write, Bash, AskUserQuestion, Grep, Glob

### 6. go:api-builder
**Use PROACTIVELY** to build REST APIs and gRPC services with proper patterns and middleware.

**Capabilities:**
- rest-api-development
- grpc-development
- middleware-design

**Tools:** Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion

### 7. go:debugger
Debugs test failures and runtime issues using verbose output, race detector, and log analysis.

**Capabilities:**
- test-debugging
- runtime-debugging
- log-analysis

**Tools:** Read, Bash, Grep, Glob

### 8. go:documenter
Generates and maintains Go documentation with godoc conventions.

**Capabilities:**
- godoc-generation
- readme-creation
- api-documentation

**Tools:** Read, Write, Edit, Bash, Grep, Glob

## Skills

### Core Development
1. **project-structure** - Standard Go project layouts (standard, hexagonal, flat)
2. **code-quality** - Go idioms, YAGNI/KISS principles, and best practices
3. **error-handling** - Modern error patterns (errors.Is, errors.As, wrapping)
4. **concurrency-patterns** - Goroutines, channels, sync patterns

### Testing
5. **testing-patterns** - Table-driven tests, testify, mocking strategies
6. **coverage-analysis** - Coverage tracking and improvement
7. **benchmarking** - Performance benchmarking techniques

### Performance
8. **performance-profiling** - pprof usage and analysis
9. **optimization-techniques** - Memory, CPU, allocation optimization

### Security
10. **security-scanning** - gosec, govulncheck usage
11. **secure-coding** - Security best practices, OWASP

### APIs
12. **rest-api-patterns** - HTTP handlers, middleware, routing
13. **grpc-patterns** - gRPC service definition and implementation

### Deployment
14. **docker-patterns** - Multi-stage builds, optimization
15. **deployment-strategies** - Kubernetes, serverless, VMs

### Documentation
16. **documentation-standards** - godoc conventions

## Commands

### Project Management
- `/go:init` - Initialize new Go project with Makefile and structure
- `/go:mod-tidy` - Clean up dependencies

### Development
- `/go:build` - Build application using Makefile
- `/go:run` - Run application
- `/go:generate` - Run go generate
- `/go:fmt` - Format code
- `/go:lint` - Run linters
- `/go:vet` - Run go vet

### Testing
- `/go:test` - Run test suite
- `/go:test-race` - Run tests with race detector
- `/go:coverage` - Generate coverage report
- `/go:bench` - Run benchmarks

### Performance
- `/go:profile` - Profile application (CPU, memory, goroutines)
- `/go:optimize` - Suggest and apply optimizations

### Security
- `/go:sec-scan` - Run security scanners (gosec, govulncheck)
- `/go:vuln-check` - Check for vulnerable dependencies

### Deployment
- `/go:docker-build` - Build Docker image
- `/go:docker-run` - Run Docker container
- `/go:deploy` - Deploy to target environment

### Debugging
- `/go:debug` - Debug tests or application

## Tech Stack Keywords

The plugin activates for projects using:
- go
- golang
- gin
- echo
- fiber
- chi
- gorm
- grpc
- protobuf

## Agent Chaining Examples

**Development → Testing → Deployment:**
```
go:developer → go:tester → go:security → go:deployer
```

**Performance Optimization:**
```
go:optimizer (profile) → go:developer (apply fixes) → go:optimizer (verify)
```

**API Development:**
```
go:api-builder → go:tester → go:documenter → go:deployer
```

**Security Review:**
```
go:security → go:developer (fix issues) → go:security (verify)
```

## Build System Standards

Every agent that compiles code follows these rules:
- **ALWAYS use Makefile** for build operations
- **NEVER run `go build` directly**
- **ALWAYS build to `./bin/` directory**
- **NEVER build to project root**
- **ALWAYS run `go fmt` before building**

## Requirements

### Core
- Go >= 1.21

### Recommended
- golangci-lint (Meta-linter)
- gosec (Security scanner)
- govulncheck (Vulnerability scanner)
- Docker (Containerization)

### Optional
- testify (Testing framework)
- mockgen (Mock generation)
- Wire (Dependency injection)
- sqlc (SQL code generation)

## Supported Deployment Targets

- Docker
- Kubernetes
- AWS Lambda
- Google Cloud Functions
- Azure Functions
- Google Cloud Run
- AWS ECS/Fargate
- Fly.io
- Heroku
- DigitalOcean App Platform

## Version

1.0.0
