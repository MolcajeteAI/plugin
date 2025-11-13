---
name: project-structure
description: Standard Go project layouts and architecture patterns. Use when initializing projects or understanding codebase structure.
---

# Project Structure Skill

This skill defines standard Go project layouts following community conventions.

## When to Use

Use this skill when:
- Initializing new Go projects
- Organizing existing codebases
- Choosing project architecture
- Setting up build systems

## Required Components (ALL Projects)

1. **Makefile** - ALWAYS required for build automation
2. **bin/** directory - ALWAYS where binaries are built (gitignored)
3. **.gitignore** - MUST include `bin/` directory
4. **go.mod** - Module definition
5. **README.md** - With build instructions using Make

## Standard Layout (golang-standards/project-layout)

```
project/
├── cmd/                    # Command entry points
│   └── myapp/
│       └── main.go
├── internal/              # Private application code
│   ├── handler/
│   ├── service/
│   └── repository/
├── pkg/                   # Public libraries
│   └── util/
├── api/                   # API specifications (OpenAPI, gRPC)
├── web/                   # Web application assets
├── configs/               # Configuration files
├── scripts/               # Build and utility scripts
├── deployments/           # Deployment configs (Docker, K8s)
├── test/                  # Integration and system tests
├── docs/                  # Documentation
├── bin/                   # Build output (REQUIRED, gitignored)
│   └── myapp
├── go.mod                 # Go module definition
├── go.sum                 # Dependency checksums
├── Makefile              # Build automation (REQUIRED)
├── .gitignore            # Must include bin/
├── Dockerfile
└── README.md
```

## Directory Purposes

- **cmd/** - Main applications for this project. Directory name matches binary name.
- **internal/** - Private application and library code. Not importable by other projects.
- **pkg/** - Library code that's ok to use by external applications.
- **bin/** - Binary output (NEVER commit these)
- **api/** - OpenAPI/Swagger specs, protocol buffer files
- **web/** - Web application specific components
- **configs/** - Configuration file templates or default configs
- **test/** - Additional external test apps and test data
- **docs/** - Design and user documents
- **scripts/** - Scripts for build, install, analysis, etc.
- **deployments/** - IaaS, PaaS, system and container orchestration deployment configurations

## Alternative Architectures

### Hexagonal/Clean Architecture
```
project/
├── cmd/
├── internal/
│   ├── domain/          # Business logic
│   ├── ports/           # Interfaces
│   ├── adapters/        # Implementations
│   └── app/             # Application layer
└── ...
```

### Flat Structure (Simple Projects)
```
project/
├── main.go
├── handler.go
├── service.go
├── bin/
├── go.mod
├── Makefile
└── README.md
```

## When to Use Each Structure

- **Standard layout:** Medium to large projects, multiple binaries
- **Hexagonal:** Complex domain logic, clear separation needed
- **Flat:** Small utilities, CLIs, simple tools

## Build System Standards

### Makefile (REQUIRED)

Every project MUST have a Makefile:

```makefile
.PHONY: build test clean lint fmt run

# Build binary to ./bin directory
build:
\t@mkdir -p bin
\tgo build -o bin/myapp cmd/myapp/main.go

# Run the application
run: build
\t./bin/myapp

# Run tests
test:
\tgo test -v ./...

# Run tests with race detector
test-race:
\tgo test -v -race ./...

# Run tests with coverage
coverage:
\tgo test -coverprofile=coverage.out ./...
\tgo tool cover -html=coverage.out

# Format code
fmt:
\tgo fmt ./...

# Run linters
lint:
\tgolangci-lint run

# Clean build artifacts
clean:
\trm -rf bin/
\trm -f coverage.out

# Install dependencies
deps:
\tgo mod download
\tgo mod tidy
```

### Build Rules

- Every project MUST have a Makefile
- Binaries MUST be built to `./bin/` directory
- Never build to project root
- `bin/` directory MUST be in .gitignore
- Use `make build`, NEVER `go build` directly

## .gitignore Template

```
# Binaries
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary
*.test

# Output of the go coverage tool
*.out

# Dependency directories
vendor/

# Go workspace file
go.work

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
```

## go.mod Best Practices

```go
module github.com/username/project

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/stretchr/testify v1.8.4
)
```

- Use Go 1.21 or later
- Run `go mod tidy` regularly
- Commit go.sum to version control
- Use `go mod vendor` if needed for reproducible builds

## README.md Template

```markdown
# Project Name

Brief description of what this project does.

## Prerequisites

- Go >= 1.21
- make

## Installation

\`\`\`bash
git clone https://github.com/username/project
cd project
make deps
\`\`\`

## Building

\`\`\`bash
make build
\`\`\`

Binary will be in `./bin/`

## Running

\`\`\`bash
make run
\`\`\`

## Testing

\`\`\`bash
make test
make test-race
make coverage
\`\`\`

## Development

\`\`\`bash
make fmt      # Format code
make lint     # Run linters
make vet      # Run go vet
\`\`\`

## License

MIT
```

## Notes

- Follow the standard layout for new projects
- Keep directory structure flat until complexity requires organization
- Use `internal/` to prevent external imports
- Binary names should match directory names in `cmd/`
- Makefile is non-negotiable
- Always build to `./bin/`
