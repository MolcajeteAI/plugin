---
description: Initialize new Go project with Makefile and build structure
---

# Initialize Go Project

Initialize a new Go project with user-selected structure.

Use the Task tool to launch the **developer** agent with instructions:

1. Ask user for project name and module path
2. Ask user to select project structure:
   - Standard layout (golang-standards)
   - Hexagonal architecture
   - Flat structure (simple)
3. Create directory structure (including `bin/` directory)
4. Initialize go.mod
5. Create main.go with basic structure
6. **REQUIRED: Create Makefile** with:
   - `build` target (builds to `./bin/` directory)
   - `run` target
   - `test` target
   - `fmt` target (runs `go fmt`)
   - `lint` target
   - `clean` target (removes `bin/` directory)
7. Create .gitignore (must include `bin/` directory)
8. Create README.md with:
   - Project description
   - Build instructions using Make
   - Development principles (YAGNI, KISS, Readability)
9. Initialize git repository (if not exists)
10. Run `make fmt` to format all code
11. Run `make build` to verify setup
12. Display next steps

**Build System Requirements:**
- Makefile is REQUIRED
- Binaries must build to `./bin/` directory
- Never build to project root
- Include all standard targets

Reference the project-structure and code-quality skills.
