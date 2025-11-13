---
description: Build application using Makefile to ./bin directory
---

# Build Application

Build the application using the Makefile.

Use the Task tool to launch the **developer** agent with instructions:

1. Verify Makefile exists (create if missing)
2. Run `make fmt` to format code first
3. Run `make build` to compile binary
4. Verify binary is created in `./bin/` directory
5. Display build success and binary location
6. If build fails, show errors and suggest fixes

**Build Requirements:**
- MUST use `make build`, never `go build` directly
- Binary MUST be in `./bin/` directory
- Code MUST be formatted before building

Reference the code-quality skill.
