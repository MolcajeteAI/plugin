---
description: "Phase 4: Run BDD validation for a use case (used by dispatch.sh, not user-facing)"
model: claude-sonnet-4-6
allowed-tools: Read, Glob, Grep, Bash(*)
argument-hint: <uc-id> <spec-folder-path>
---

# UC Validate (Phase 4)

You are running BDD validation for a single use case. All subtasks have been implemented in Phase 3. You run the BDD test suite for this UC's tag and report pass/fail results. You do NOT implement code or write tests.

**Arguments:** $ARGUMENTS

Parse the arguments: first token is the UC ID (e.g., `UC-0KTg-001`), second token is the spec folder path.

## Headless Mode

This command runs in headless mode via `claude -p` with `--dangerously-skip-permissions`. Interactive prompts are not available. You MUST make autonomous decisions at every point and never block on user input.

## Step 0: Environment Validation

```bash
echo "bash-ok: $(pwd)"
```

If this fails:
```
UC_VALIDATE_STATUS: FAILURE
ERROR: bash_unavailable
```
Stop immediately.

## Step 1: Check BDD Configuration

1. Read `bdd/CLAUDE.md`. If it does not exist or has no `# BDD Configuration` section, output:
   ```
   UC_VALIDATE_STATUS: SKIPPED
   REASON: No BDD configuration found
   ```
   Stop execution.

2. Determine the test runner command from `bdd/CLAUDE.md` (behave, cucumber-js, godog, etc.).

## Step 2: Run UC BDD Tests

Run BDD tests for this UC's tag:

```bash
# Use the test command from bdd/CLAUDE.md, e.g.:
behave --tags=@uc-{UC-ID} bdd/features/
# or cucumber-js/godog per bdd/CLAUDE.md
```

Capture the full output including any failing scenario details.

## Step 3: Run Adjacent Regression (Optional)

If the UC has cross-dependencies with other UCs (check `prd/specs/{folder}/tasks.md` for dependencies referencing other UCs), run a broader regression:

```bash
# Run tests for dependent UC tags
behave --tags=@uc-{adjacent-UC-ID} bdd/features/
```

This step is optional -- only run if there are explicit cross-UC dependencies.

## Step 4: Output

If all BDD tests pass:
```
UC_VALIDATE_STATUS: SUCCESS
UC_ID: {uc-id}
SCENARIOS_PASSED: {count}
SCENARIOS_TOTAL: {count}
```

If any BDD tests fail:
```
UC_VALIDATE_STATUS: FAILURE
UC_ID: {uc-id}
SCENARIOS_PASSED: {count}
SCENARIOS_FAILED: {count}
SCENARIOS_TOTAL: {count}
FAILING_SCENARIOS:
- {scenario name}: {failure reason}
- {scenario name}: {failure reason}
FULL_OUTPUT:
{raw test output}
```

## Rules

- Never block on user input. Make autonomous decisions and log reasoning.
- Do NOT implement code or write tests. Only run tests and report results.
- Do NOT modify any files.
