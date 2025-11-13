---
description: Run go generate
---

# Run Go Generate

Execute go generate directives in the codebase.

Use the Task tool to launch the **developer** agent with instructions:

1. Find files with //go:generate directives
2. Run `go generate ./...`
3. Show which files were generated
4. Verify generated code compiles
5. Display any errors

**Common Go Generate Uses:**
- Mock generation (mockgen)
- String method generation (stringer)
- Protocol buffer compilation (protoc-gen-go)
- SQL code generation (sqlc)
- Wire dependency injection

**Example Directive:**
```go
//go:generate mockgen -source=interface.go -destination=mock.go
```

Reference the code-quality skill.
