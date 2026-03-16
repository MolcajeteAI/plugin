---
description: "Phase 2: Write BDD step definitions for a use case (used by dispatch.sh, not user-facing)"
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task
argument-hint: <uc-id> <spec-folder-path>
---

# UC BDD (Phase 2)

You are writing BDD step definitions for all scenarios in a single use case. You read the plan files from Phase 1, invoke the Tester agent to implement step definition bodies, verify they fail (red gate), and commit. You do NOT implement production code or run full test suites.

**Arguments:** $ARGUMENTS

Parse the arguments: first token is the UC ID (e.g., `UC-0KTg-001`), second token is the spec folder path.

## Headless Mode

This command runs in headless mode via `claude -p` with `--dangerously-skip-permissions`. Interactive prompts are not available. You MUST make autonomous decisions at every point and never block on user input.

## Designated Agents

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` -- invocation protocol and handoff patterns
- **Tester** (`${CLAUDE_PLUGIN_ROOT}/agents/tester.md`) -- implements BDD step definitions from the plans (red phase)

## Step 0: Environment Validation

```bash
echo "bash-ok: $(pwd)"
```

If this fails:
```
UC_BDD_STATUS: FAILURE
ERROR: bash_unavailable
```
Stop immediately.

## Step 1: Check BDD Availability

1. Read `bdd/CLAUDE.md`. If it does not exist or has no `# BDD Configuration` section, output:
   ```
   UC_BDD_STATUS: SKIPPED
   REASON: No BDD configuration found
   ```
   Stop execution.

2. Grep `bdd/features/` for files containing `@uc-{UC-ID}`.

3. If no matching scenarios exist, output:
   ```
   UC_BDD_STATUS: SKIPPED
   REASON: No BDD scenarios tagged @uc-{UC-ID}
   ```
   Stop execution.

## Step 2: Read Plan Files

1. Read all plan files from Phase 1 at `prd/specs/{feature}/plans/*-task-{UC-ID}--*.md`.
2. Extract planned interfaces from each plan: function signatures, API endpoints, component names, CSS selectors.
3. These planned interfaces are what step definitions will assert against.

## Step 3: Invoke Tester Agent

Read the Tester agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/tester.md` and follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`.

Invoke the Tester agent with:
- Input: UC brief, all plan files (with planned interfaces), BDD scenarios for `@uc-{UC-ID}`, step definition file paths with TODO bodies
- Scope: ONLY `bdd/steps/` files
- Goal: Implement step definition bodies for ALL scenarios tagged `@uc-{UC-ID}`
- The Tester discovers stack-specific testing skills at runtime

## Step 4: Red Gate

Run BDD tests inline via Bash, using the framework from `bdd/CLAUDE.md`:

```bash
# Use the test command from bdd/CLAUDE.md, e.g.:
behave --tags=@uc-{UC-ID} bdd/features/
# or cucumber-js/godog per bdd/CLAUDE.md
```

- `EXIT != 0` (tests fail): **Expected.** Log "RED GATE PASSED -- tests fail as expected" and proceed.
- `EXIT == 0` (tests pass): **Unexpected.** Re-invoke Tester to strengthen assertions. Max 2 retries, then log warning and proceed.
- Syntax/import error: Re-invoke Tester to fix. Max 2 retries, then log warning and proceed.

## Step 5: Commit Step Definitions

```bash
git add bdd/steps/
git commit -m "test({uc-id}): implement BDD step definitions (red phase)

UC: {uc-id}
Scenarios: {count}
Status: Red gate passed -- tests fail as expected"
```

## Step 6: Output

```
UC_BDD_STATUS: SUCCESS
UC_ID: {uc-id}
SCENARIOS: {count}
STEP_FILES:
- {path-to-step-file-1}
- {path-to-step-file-2}
```

If any step fails critically:
```
UC_BDD_STATUS: FAILURE
UC_ID: {uc-id}
ERROR: {description}
```

## Rules

- Never block on user input. Make autonomous decisions and log reasoning.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
- Do NOT implement production code.
- Do NOT run full test suites -- only BDD tests for this UC's tag.
