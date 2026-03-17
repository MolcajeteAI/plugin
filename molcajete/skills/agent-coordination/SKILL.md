---
name: agent-coordination
description: >-
  Documents agent chains used in coordinated builds. Use when implementing
  or debugging the /m:run dispatch pipeline, understanding agent boundaries,
  or reasoning about the Tester -> Developer -> Validator workflow.
user-invocable: false
---

# Agent Coordination

How agents collaborate in the `/m:run` dispatch pipeline. Each UC gets one shared session and one git worktree. Three agents operate in sequence inside the worktree.

## Dispatch Chain

| Phase | Agent | Command | Invoked | Scope | Does NOT |
|-------|-------|---------|---------|-------|----------|
| 1 | **Tester** | `run/test.md` | Once per UC, before subtasks | `bdd/steps/` only | Write production code, run tests, merge |
| 2 | **Developer** | `run/build.md` | Once per subtask | Production code + unit tests | Modify `bdd/`, run BDD tests, merge |
| 3 | **Validator** | Inline Bash | Once per UC, after all subtasks | Read-only (runs tests) | Write code, merge on failure |

### Tester

Replaces `NotImplementedError` stubs in step definitions with real assertions. This is the red phase — tests should fail because no production code exists yet. Commits step definitions inside the worktree.

**Input:** Feature files tagged `@{UC_ID}`, step definitions from `bdd/steps/`
**Output:** `{status, step_files, scenarios_count, commit, error}`
**Retries:** Up to 2 on failure before UC is marked failed

### Developer

Implements production code and writes unit tests for one subtask. Reads feature files and step definitions as context (read-only) to understand what BDD tests expect.

**Input:** Task brief from `tasks.md`, feature files, step definitions, prior subtask git log
**Output:** `{status, files_modified, commit, error}`
**Retries:** Up to 2 on review failure (with feedback from LLM Review)

### LLM Review

Lightweight correctness check after each Developer commit. Uses a cheaper model (Sonnet) with tight bounds (5 turns, $0.50).

**Checks:** Files committed, changes match task, no obvious errors
**Output:** `{verdict: pass|fail, reason}`
**On failure:** Developer is resumed with review feedback

### Validator

Runs BDD tests inside the worktree with `--tags=@{UC_ID}`. Test exit code is the sole done signal. On green: merges worktree to base branch via `merge.sh`. On red: resumes Developer session with test failure output.

**Retries:** Up to 2 BDD fix cycles before UC is marked failed

## Session Model

All agents for a UC share one session (1M context window):

1. Tester starts the session with `--name "$UC_ID"`
2. Developer resumes with `--resume "$UC_ID"` for each subtask
3. LLM Review resumes with `--resume "$UC_ID"`
4. BDD fix resumes with `--resume "$UC_ID"`

This keeps the full UC context (spec, step definitions, prior subtask work) accumulated across all agents.

## Worktree Isolation

- One worktree per UC, created by dispatch.sh
- All agents operate inside the same worktree
- Base branch never receives code directly — only via `merge.sh` after BDD validation
- Worktree cleaned up on successful merge, preserved on failure for inspection

## Interactive vs. Headless

The dispatch pipeline is **headless** — no user interaction during execution. Interactive commands (`/m:dev`, `/m:fix`, `/m:test`) are separate and unaffected.

| Workflow | Commands | User Interaction |
|----------|----------|-----------------|
| Interactive | `/m:dev`, `/m:fix`, `/m:review`, `/m:test` | AskUserQuestion, plan approval |
| Headless | `run/test.md`, `run/build.md`, LLM Review | None — `dispatch.sh` orchestrates |
