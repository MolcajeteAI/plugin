---
name: implementing
description: >-
  Rules and conventions for interactive plan task implementation via /m:build.
  Covers plan authority, state transitions, implementation procedures by intent,
  sub-task execution, scenario activation, commit rules, and error handling.
  Adapted from the CLI dispatch pipeline for interactive (non-headless) use.
---

# Implementing

Rules for implementing plan tasks interactively via `/m:build`. All implementation work follows these conventions.

## When to Use

- Implementing a plan task via the `/m:build` command
- Understanding the interactive build workflow
- Referencing plan state transitions or implementation procedures

## Interactive vs. CLI Build

The `/m:build` command is a simplified, interactive alternative to the CLI's `molcajete build`. Key differences:

| Aspect | CLI Build (`molcajete build`) | Plugin Build (`/m:build`) |
|--------|-------------------------------|---------------------------|
| Execution | Headless, automated | Interactive, user-present |
| Parallelism | Multiple tasks concurrently | One task at a time |
| Worktrees | Isolated git worktree per task | Works on current branch |
| Hooks | Mandatory `test` hook, optional lifecycle hooks | No hooks -- user handles testing |
| Retry | Automatic dev-test-review cycle (max 7) | No automatic retry -- user re-runs if needed |
| Sessions | Spawns child Claude processes | The model itself does the work |
| User interaction | None (headless) | Can use AskUserQuestion |
| Error handling | Hard-stop on infra issues | Surface to user, let them decide |

## Plan Authority Rule

Two files govern each plan, with distinct authority domains:

- **`plan.json`** -- flow-control authority: task status, intent, dependencies, scenario tag, module, `files_to_modify` ordering. Read from here for state and dispatch decisions.
- **`plan.md`** -- narrative / implementation-intent authority: "What changes", "Important snippets", "Files to create/modify", "Non-requirements", "Verification". May contain human edits made after plan generation. Trust it for implementation guidance.

**Never mutate `plan.md`** during a build. Only `plan.json` gets status updates.

If `plan.md` is missing and `task.intent` is `implement` or `wire-bdd`, the build cannot proceed -- the narrative is required for implementation guidance.

## Plan State Transitions

### Task-Level

```
pending -> in_progress -> implemented
                       -> failed
```

| Transition | When | JSON mutation |
|-----------|------|---------------|
| `pending -> in_progress` | Build starts on this task | `task.status = "in_progress"` |
| `in_progress -> implemented` | Implementation complete | `task.status = "implemented"`, `task.summary = "..."` |
| `in_progress -> failed` | Implementation cannot complete | `task.status = "failed"`, `task.errors = ["..."]` |

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
"summary": "Implemented user registration endpoint with argon2id password hashing. Key decisions: Used argon2id over bcrypt for future-proofing. Watch-outs: Registration handler is async -- callers must await."
```

### Error Format

When a task fails, write errors as an array of strings describing what went wrong:

```json
"errors": ["Connection refused on port 5432 -- database not running. User needs to start the dev environment."]
```

## Sub-Task Execution

When a task has `sub_tasks` (non-null array), sub-tasks execute sequentially:

1. Sub-tasks inherit from the parent: `use_case`, `feature`, `module`, `architecture`, `intent`, `scenario`
2. Sub-task `depends_on` references sibling sub-task IDs only (e.g., `T-003-1`)
3. Check sub-task dependencies before starting each one
4. Each sub-task gets its own commit
5. Each sub-task's status is tracked independently in plan.json
6. If a sub-task fails, the parent task is marked `failed` and execution stops
7. After all sub-tasks complete, the parent task is marked `implemented`

Sub-tasks share the plan.md `### T-NNN` section with their parent (they appear as nested bullets under "Files to create/modify"). Locate the section using the parent task ID.

## Scenario Activation

Before implementing, remove lifecycle tags from the task's scenario in the `.feature` file:

1. If `task.scenario` is non-null, derive the tag `@SC-XXXX` by prepending `@`
2. Locate the `.feature` file via Glob `bdd/features/**/{task.use_case}-*.feature`
3. Remove `@pending` and/or `@dirty` from the `@SC-XXXX` line
4. On retry (task was previously `failed`), skip -- tags were already removed on the first pass

Include the modified `.feature` file in the commit.

## Implementation Procedures

Implementation follows one of two procedures based on `task.intent`:

- **`implement`** -- Specs First (greenfield). Writes production code, unit tests, and step definitions. See `references/implement-intent.md`.
- **`wire-bdd`** -- Code First (brownfield). Writes only step definitions, no production code changes. See `references/wire-bdd-intent.md`.

## Commit Rules

- One commit per task, or one commit per sub-task if the task has sub-tasks
- Follow the git-committing skill for message format and conventions
- Stage specific files -- never `git add .` or `git add -A`
- The commit scope should reference the task's feature, use case, and scenario IDs for traceability
- Self-review before committing: `git diff` to check for debug statements, commented-out code, hardcoded secrets, or TODO placeholders

## Error Handling

### Infrastructure Issues (Surface to User)

If you encounter any of the following, do NOT attempt to fix them. Instead, use AskUserQuestion to inform the user and ask how to proceed:

- Connection refused / connection timed out (services not running)
- HTTP 502/503/504 (upstream server down)
- Docker container not found / not running
- Database unreachable / authentication failed
- Missing environment variables
- Missing system-level CLI tools / binaries not installed
- Port already in use / bind errors
- Permission denied on system resources

These are infrastructure issues outside the task's scope. The user needs to resolve them.

### Project Dependencies (Handle Normally)

Adding missing packages (npm install, pip install, cargo add) is normal development work when the dependency is needed for code you are writing in this task. Handle this without user intervention.

## PRD and BDD Layout

Follow the same layout conventions as the rest of the plugin:

- UC files: `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{uc-slug}.md`
- Feature files: `bdd/features/{module}/{domain}/{UC-XXXX}-{uc-slug}.feature`
- Step definitions: `bdd/steps/{category}_steps.{ext}`
- Step index: `bdd/steps/INDEX.md`

Feature-file discovery is UC-ID-based: `Glob bdd/features/**/{UC-XXXX}-*.feature`. Do not grep for `@UC-XXXX` tags.
