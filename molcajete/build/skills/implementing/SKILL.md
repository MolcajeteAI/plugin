---
name: implementing
description: >-
  Rules for /m:build's two-subagent loop. Defines plan authority and state
  transitions, the Implementer and Validator role contracts, sub-task
  execution, intent handling (implement vs cover), reactive refactor,
  commit rules, and infrastructure error handling. Testing principles
  (mocking, exit doors, tech-stack reading, coverage gate) live in the
  shared testing skill.
---

# Implementing

Rules for implementing plan tasks interactively via `/m:build`. The build command runs a two-subagent loop — Implementer and Validator — inside each task until every named behavior is covered and the full suite passes at the project coverage threshold. The loop semantics, role contracts, mocking, and exit doors are defined in `shared/skills/testing/SKILL.md`; this skill defines the build-command-specific rules that surround the loop.

## When to Use

- Implementing a plan task via the `/m:build` command
- Understanding the interactive build workflow
- Referencing plan state transitions, intent semantics, sub-task rules, or commit conventions

## Interactive vs. CLI Build

The `/m:build` command is a simplified, interactive alternative to the CLI's `molcajete build`. Key differences:

| Aspect | CLI Build (`molcajete build`) | Plugin Build (`/m:build`) |
|--------|-------------------------------|---------------------------|
| Execution | Headless, automated | Interactive, user-present |
| Parallelism | Multiple tasks concurrently | One task at a time |
| Worktrees | Isolated git worktree per task | Works on current branch |
| Hooks | Mandatory `test` hook, optional lifecycle hooks | No hooks -- user handles testing |
| Retry | Automatic dev-test-review cycle (max 7) | The Implementer + Validator loop runs in-line; user is asked at iteration cap |
| Sessions | Spawns child Claude processes | The model itself drives the subagents |
| User interaction | None (headless) | Can use AskUserQuestion |
| Error handling | Hard-stop on infra issues | Surface to user, let them decide |

## Plan Authority Rule

Two files govern each plan, with distinct authority domains:

- **`plan.json`** -- flow-control authority: task status, intent, dependencies, module, `files_to_modify` ordering. Read from here for state and dispatch decisions.
- **`plan.md`** -- narrative / implementation-intent authority: "What changes", "Important snippets", "Files to create/modify", "Non-requirements", "Verification". May contain human edits made after plan generation. Trust it for implementation guidance.

**Never mutate `plan.md`** during a build. Only `plan.json` gets status updates.

If `plan.md` is missing, the build cannot proceed -- the narrative is required for implementation guidance.

## Plan State Transitions

### Task-Level

```
pending -> in_progress -> implemented
                       -> failed
```

| Transition | When | JSON mutation |
|-----------|------|---------------|
| `pending -> in_progress` | Build starts on this task | `task.status = "in_progress"` |
| `in_progress -> implemented` | Validator returns `pass` and every behavior named in the task description is covered | `task.status = "implemented"`, `task.summary = "..."` |
| `in_progress -> failed` | Iteration cap hit and user chose to fail, or hard fault | `task.status = "failed"`, `task.errors = ["..."]` |

### Plan-Level

| Condition | Plan status |
|-----------|-------------|
| First task moves to `in_progress` | `in_progress` |
| All tasks `implemented` | `implemented` |
| Any task `failed` | `failed` |
| Mix of `implemented` and `pending` | `in_progress` |

### Summary Format

When a task completes successfully, write a summary containing:
- What was implemented (1-2 sentences)
- Key decisions made during implementation
- Watch-outs for dependent tasks

```json
"summary": "Implemented user registration handler with argon2id password hashing. Covered behaviors: happy path, duplicate email, weak password. Watch-outs: handler is async -- callers must await."
```

### Error Format

When a task fails, write errors as an array of strings describing what went wrong:

```json
"errors": ["Iteration cap reached with persistent coverage gap in `users/repository.ts`. Validator's last gap report: uncovered branches in updateProfile/case 'archived'. User paused for review."]
```

## Implementer and Validator Contracts

The Implementer and Validator are subagents the orchestrator dispatches via the Agent tool on every loop iteration. Their procedures, context contracts, and return shapes are defined in `shared/skills/testing/SKILL.md`. Two rules belong here:

1. **The orchestrator is the only authority on task completion.** A "pass" claim from the Implementer is not trusted; only the Validator's independent `pass` counts. The Implementer cannot mark its own work done.
2. **Test-first is enforced by file order, not by an extra agent.** The orchestrator diffs the test-file set between Implementer rounds. A round with no new or touched test file is rejected with the feedback "Implementer must write a test before production code."

## Intent Handling

Each task carries an `intent`:

| Intent | Source | Implementer behavior |
|---|---|---|
| `implement` | `/m:plan` (greenfield) | Each behavior is a production capability to build. Write the test for the behavior; write production code in its final form to make it pass. |
| `cover` | `/m:reverse-plan` (coverage recovery) | Each behavior is an uncovered code path to exercise with a new test. Production code is touched only when the path has no testable seam (reactive refactor — see below). When possible, add tests only. |

The Validator treats both intents identically: the same coverage gate, the same `pass` / `tests_failed` / `coverage_low` outcomes.

## Reactive Refactor

Restructuring production code is appropriate only when triggered by one of:

1. **Validator feedback that requires it.** The fix for a failing test or uncovered branch cannot be expressed by additive changes — the shape is wrong and must be reshaped.
2. **Accommodating a later task.** A later task's behavior does not fit the shape of code written for an earlier task. Reshape as part of the current task; do not reopen the earlier one; do not amend the plan.

Refactoring solely to "improve" code outside those triggers is out of scope. The build loop optimises for finishing the task, not for stylistic cleanup.

For `intent: cover` tasks specifically: refactor only when the production code has no testable seam (e.g., a service constructs its outer-edge clients internally with no injection point). The minimum reshaping needed to make the path testable is the right scope; broader refactors are not.

## Sub-Task Execution

When a task has `sub_tasks` (non-null array), sub-tasks execute sequentially. They exist for context-budget splitting only — never for Red/Green/Refactor phases.

1. Sub-tasks inherit from the parent: `use_case`, `feature`, `module`, `architecture`, `intent`.
2. Sub-task `depends_on` references sibling sub-task IDs only (e.g., `T-003-1`).
3. Check sub-task dependencies before starting each one.
4. The two-subagent loop runs inside each sub-task scoped to its own `description` and `files_to_modify`.
5. The coverage gate runs at the parent-task level after all sub-tasks complete — a final Validator pass confirms the full suite passes and coverage is met.
6. If a sub-task fails, the parent task is marked `failed` and execution stops.
7. After all sub-tasks complete successfully, the parent task is marked `implemented`.

Sub-tasks share the plan.md `### T-NNN` section with their parent (they appear as nested bullets under "Files to create/modify"). Locate the section using the parent task ID.

## Run Logs

The build command writes a per-task log at `.molcajete/plans/{plan-name}/runs/{task.id}.log`. Every Implementer and Validator round is appended with iteration number, behavior name, files changed, Implementer note, Validator outcome, and any failure detail. The log is the source of truth for debugging stuck loops.

## Commit Rules

- One commit per task, or one commit per sub-task if the task has sub-tasks
- Follow the git-committing skill for message format and conventions
- Stage specific files -- never `git add .` or `git add -A`
- The commit scope should reference the task's feature and use case IDs for traceability
- Self-review before committing: `git diff` to check for debug statements, commented-out code, hardcoded secrets, or TODO placeholders

## Error Handling

### Infrastructure Issues (Surface to User)

If you encounter any of the following during a loop round, do NOT attempt to fix them. Stop the loop and use AskUserQuestion to inform the user and ask how to proceed:

- Connection refused / connection timed out (services not running)
- HTTP 502/503/504 (upstream server down)
- Docker container not found / not running
- Database unreachable / authentication failed
- Missing environment variables
- Missing system-level CLI tools / binaries not installed
- Port already in use / bind errors
- Permission denied on system resources

These are infrastructure issues outside the task's scope. The user needs to resolve them before the loop can continue.

### Project Dependencies (Handle Normally)

Adding missing packages (npm install, pip install, cargo add) is normal development work when the dependency is needed for code you are writing in this task. Handle this without user intervention.

### Incomplete `prd/tech-stack.md`

If the relevant `Module` section is missing `Framework` or `Key libraries` (or those rows still contain template placeholders), halt with a clear message naming the missing rows and pointing the user at `/m:setup`. The `Testing` row is the only exception — blank is fine and triggers inference per `shared/skills/testing/SKILL.md` → "Runner Inference".

## PRD Layout

Follow the same layout conventions as the rest of the plugin:

- UC files: `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{uc-slug}.md`
- Tests follow the runner's convention for the module (next to the file, in a sibling `__tests__`, in `tests/`, etc.) — pick whichever the existing test files in that module already use; do not invent a new layout.
