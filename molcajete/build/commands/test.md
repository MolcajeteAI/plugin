---
description: Write, run, or analyze tests for code
model: claude-sonnet-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: <file path or "run" or "coverage">
---

# Test

You write, run, and analyze tests for code in this project. You detect the target stack and follow the project's established testing patterns.

**Input:** $ARGUMENTS

## Step 1: Detect Mode and Stack

Parse `$ARGUMENTS` to determine the mode:

| Input | Mode |
|-------|------|
| File/directory path | **write** — generate tests for that code |
| `run` | **run** — execute existing test suite |
| `run <path>` | **run** — execute tests for specific path |
| `coverage` | **coverage** — run coverage analysis |
| `coverage <path>` | **coverage** — coverage for specific path |
| Empty | Use AskUserQuestion to ask what to test |

Detect the stack from the target:

| Indicator | Stack | Test skill |
|-----------|-------|------------|
| `.go` files | Go | go-testing |
| `.tsx` files in `src/components/` | React | react-testing |
| `.ts`/`.tsx` files | TypeScript | typescript-testing |
| `server/` path | Go | go-testing |
| `patient/`, `doctor/`, `console/` path | React | react-testing |

## Write Mode

### Step W1: Load Context via Sub-Agents

Launch 2 parallel sub-agents using the Task tool in a single message:

**Agent 1 — Testing Conventions** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the relevant testing skill based on the detected stack:
  - For Go: `${CLAUDE_PLUGIN_ROOT}/skills/go-testing/SKILL.md`
  - For TypeScript: `${CLAUDE_PLUGIN_ROOT}/skills/typescript-testing/SKILL.md`
  - For React: `${CLAUDE_PLUGIN_ROOT}/skills/react-testing/SKILL.md`
  - If Node.js integration: `${CLAUDE_PLUGIN_ROOT}/skills/node-testing/SKILL.md`
  Return:
  ```
  TESTING_CONVENTIONS:
  - Test file placement: {where test files go}
  - Naming patterns: {test naming conventions}
  - Import conventions: {standard imports and test utilities}
  - Assertion style: {assertion library and patterns}
  - Mocking approach: {how to mock dependencies}
  - Table-driven tests: {if applicable, the pattern to follow}
  - Special utilities: {e.g., renderWithI18n for React}
  ```

**Agent 2 — Code and Pattern Analysis** (subagent_type: `general-purpose`):
- Prompt: Analyze the target code and find existing test patterns:
  - Read the target file or all files in the target directory at `{target path}`
  - Identify: exported functions/components, logic branches (conditions, error paths, edge cases), dependencies (external APIs, database, state)
  - Search for existing test files near the target:
    - Go: `_test.go` files in the same package
    - Frontend: `__tests__/` directories in sibling or parent directories
  - Read 1-2 existing test files to understand import conventions, assertion style, mocking approach, and naming patterns
  Return:
  ```
  TARGET_ANALYSIS:
  - Exports: {list of functions/components to test}
  - Logic branches: {conditions, error paths, edge cases}
  - Dependencies: {what needs mocking}
  - Suggested test cases: {list of test cases covering main paths, error paths, edge cases}

  EXISTING_PATTERNS:
  - Test file example: {path to an existing test file}
  - Import style: {how imports are structured}
  - Assertion library: {testify, vitest expect, etc.}
  - Mocking style: {how mocks are set up}
  - Naming pattern: {how tests are named}
  ```

Use the returned context for all subsequent steps. Do NOT read these files again yourself.

### Step W2: Write Tests

Generate test files following the conventions from Agent 1 and the patterns from Agent 2:

**Go:**
- Place in the same directory as the target: `{filename}_test.go`
- Use table-driven tests for functions with multiple input/output combinations
- Test error paths explicitly
- Use `testify` if the project uses it, otherwise standard library

**React/TypeScript:**
- Place in `__tests__/` sibling directory: `__tests__/{ComponentName}.test.tsx`
- Use Testing Library queries (follow priority: role > label > text > testId)
- Test user interactions with `userEvent`
- Use `renderWithI18n` from `@drzum/ui/test` for components with i18n

### Step W3: Run New Tests

Execute the new tests to verify they pass:
- **Go**: `cd server && go test -run TestXxx ./internal/path/...`
- **Frontend**: `pnpm --filter <app> test -- src/path/__tests__/file.test.tsx`

If tests fail, fix them and re-run. Do NOT leave failing tests.

### Step W4: Format

Run the formatter on test files:
- **Go**: `gofmt`
- **Frontend**: Biome via the project's format command

## Run Mode

### Step R1: Detect Test Runner

- **Go**: `go test` (from `server/` directory)
- **Frontend**: `pnpm --filter <app> test`

### Step R2: Execute Tests

Run the appropriate command:
- If a specific path was given, run tests for that path only
- If no path, run the full suite for the detected stack

### Step R3: Report Results

Report:
- Total tests: passed / failed / skipped
- Any failures with file path, test name, and error message
- Suggestions for fixing failures

## Coverage Mode

### Step C1: Run Coverage

- **Go**: `cd server && go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out`
- **Frontend**: `pnpm --filter <app> test -- --coverage`

If a specific path was given, scope coverage to that path.

### Step C2: Analyze Gaps

Identify:
- Files with low coverage (below 70%)
- Untested public functions/components
- Untested error paths and edge cases

### Step C3: Report

Report:
- Overall coverage percentage
- Top files needing tests (sorted by coverage gap)
- Specific functions/components to test next
- Use AskUserQuestion to ask if the user wants tests written for the identified gaps

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow the project's existing test patterns — match import style, assertion library, and naming conventions.
- Place test files in the correct location: `__tests__/` for frontend, same directory for Go.
- Do not use the word "comprehensive" in any output.
- Never stage files or create commits — the user manages git.
- Do NOT add Biome ignore comments. Fix the underlying issue instead.
