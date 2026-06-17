---
description: Execute a plan — run the TDD red/green/mutation lifecycle for one or more tasks (slices) inside a plan folder.
model: claude-opus-4-6
argument-hint: "<plan-id> <T-NNN | T-NNN.N> [more ...]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Build Command

`/m:build` executes a plan produced by `/m:plan`. It walks the tasks the user named, runs the TDD lifecycle for each, updates the plan checkboxes, and flips the corresponding log entries to `implemented`.

The plan's `mode` (`default` or `cover`) decides whether `/m:build` writes production code:

- **mode: default** — writes production code, integration tests (always), unit tests (when required).
- **mode: cover** — writes integration tests (always) and unit tests (when required). **No production code.** Tests assert behavior of code that already exists.

**Do NOT commit code.** The user reviews your output and commits themselves.

**Arguments:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never plain-text questions.

## Step 1: Parse Arguments

`$ARGUMENTS` must contain:

1. A plan ID as the first token. Format: `YYYYMMDDTHHMMSS-<descriptive-name>` (the folder name under `.molcajete/plans/`).
2. One or more task IDs. Each is `T-NNN` (whole slice) or `T-NNN.N` (one sub-task).

Examples:

- `/m:build 20260616T141530-add-checkout T-001`
- `/m:build 20260616T141530-add-checkout T-001 T-002 T-003`
- `/m:build 20260616T141530-add-checkout T-001.1 T-001.2`

If `$ARGUMENTS` is empty or missing a plan-id, list available plans:

```
ls .molcajete/plans/
```

Then tell the user:

> "Usage: `/m:build <plan-id> <T-NNN | T-NNN.N> [...]`. Available plans: {list of plan folder names}."

Stop.

If the plan-id does not resolve to a folder under `.molcajete/plans/`, refuse with the available list and stop.

## Step 2: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/SKILL.md` — slice file schema and Test File Convention.
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — runner inference, outer-edge mocking, coverage gate.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — log entry transitions, UC status roll-up.

## Step 3: Verify Prerequisites

1. `specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. If any is missing: "Project foundation not found. Run `/m:setup` first." Stop.
2. Ensure `.molcajete/settings.json` exists and contains `testing.threshold`:
   - If the file does not exist, create `.molcajete/` and write `{"testing": {"threshold": 80}}`. Tell the user: "Initialized `.molcajete/settings.json` with default `testing.threshold = 80`. Edit it to change the coverage gate."
   - If the file exists but `testing.threshold` is missing, merge in `testing.threshold = 80` (preserving every other key) and write it back.
   - If `testing.threshold` is already set, use that value.

## Step 4: Load the Plan

1. Read `.molcajete/plans/<plan-id>/plan.md`.
2. Parse:
   - **Mode line** (`mode: default` or `mode: cover`) at the top.
   - **FEAT / UC sections** (h2 / h3 headings).
   - **Task list** under each UC: `T-NNN` lines with optional `T-NNN.N` sub-tasks. Each task references a slice filename (e.g., `UC-0KTg-001-validate-email.md`).
3. Build an in-memory task index: `T-NNN → { feat, uc, slice_file_path, sub_tasks }`. The slice file path is the UC folder plus the referenced filename.
4. For each task ID in `$ARGUMENTS`:
   - `T-NNN` (whole slice) → mark every sub-task under it for execution.
   - `T-NNN.N` (single sub-task) → mark only that sub-task.
   - Unknown task ID → refuse with: "Task `{id}` is not in plan `{plan-id}`. Available tasks: {list}." Stop.

## Step 5: Present the Build Plan

Show the user via AskUserQuestion: "Executing plan `{plan-id}` in `mode: {mode}`. {N} task(s): {list of tasks with slice file references}. Proceed?"

Options: "Proceed" / "Cancel".

If "Cancel", stop without writing.

## Step 6: Tech Stack and Runner Resolution

Read `specs/TECH-STACK.md`. Locate the **Running tests** and **Coverage** sections (per the host project's `/m:setup`-generated TECH-STACK):

- **Running tests** — the project's exact test command(s). Use the per-module entry that matches the slice's module (the module is encoded in the slice file path).
- **Coverage** — the project's exact coverage command and how to read stats (collector, report path).

If the **Running tests** section is missing for the matching module, halt: "`specs/TECH-STACK.md` is missing the **Running tests** entry for module `{module}`. Run `/m:setup` to populate it."

If the **Coverage** section is missing or marked "not available", proceed anyway — the coverage gate falls back to a best-effort estimate against the 80% floor (or whatever `testing.threshold` says). Note this in the final report.

Resolve the test runner per the testing skill's **Runner Inference**. Cache test + coverage commands for this invocation.

## Step 7: Execute Each Slice

For each slice marked in Step 4, run the slice through the TDD lifecycle. Process slices in plan order (`T-NNN` ascending). For each slice:

### 7.1 Load the slice

1. Read the slice file at the resolved path.
2. Parse frontmatter (`id`, `name`, `use_case`, `feature`, `objective`, `files.create`, `files.modify`, `depends_on`, `provides`, `entry_type`, `covers`, `last_update`). Reject the slice if it declares `test_file` in frontmatter.
3. Capture body sections (`## Rationale`, `## Contracts` subsections, `## Tests`).

### 7.2 Validate slice

1. **Check dependencies.** For each ID in `depends_on`, verify the dependency slice exists in the same UC folder. Check `.molcajete/slices/{dep-id}.json` for `status: "implemented"`. If any unmet, halt: "Slice `{id}` is blocked. Unmet deps: {list}." Stop.
2. **Check file invariants:**
   - `objective: implement` (mode: default) — every path in `files.create` must NOT exist; every path in `files.modify` must exist.
   - `objective: coverage` (mode: cover) — `files.create` must be empty; every path in `files.modify` must exist.
3. **Derive test file path.** Apply the slicing skill's Test File Convention from frontmatter + `specs/MODULES.md`:
   ```
   {module.Tests}/features/{feature-dir-name}/{uc-dir-name}/{NNN}-{entry-type}-{slice-name}.{test-ext}
   ```
   Apply the validation rules in the slicing skill's "Build-time validation" list verbatim.

### 7.3 Load build payload

Parallel batch:

- **Dependency exports.** For each `depends_on` slice, read its file and `grep` its sources for each name in `provides`. Capture signature lines only (no full bodies).
- **Existing modify files.** Read the current contents of every path in `files.modify`.
- The TECH-STACK module section from Step 6.

### 7.4 Phase 1 — Scaffold the test file

Translate the slice's `## Tests` nested-bullet plan into runner-equivalent test code at the derived test path. Top-level bullets → outermost `describe` (use `SC-XXXX: {name}` as the block name when the bullet starts with `**SC-XXXX:`). Nested bullets → nested `describe`. Leaves → `it`.

- `objective: implement` (mode: default): `it` bodies are empty (or contain a single `expect.fail("not implemented")` placeholder when the runner requires it). Initial run must be RED.
- `objective: coverage` (mode: cover): `it` bodies contain the full assertions implied by the bullet text. Initial run must be GREEN.

Add imports the assertions need.

Write the test file. Create parent directories as needed.

### 7.5 Phase 1 check — initial test run

Run the scoped test command against the derived test file only.

- **mode: default** / `objective: implement` — expect RED.
  - GREEN → run the mutation check (7.7). If mutation turns it RED, the implementation already satisfies the slice; skip Phase 2 and record outcome. If GREEN after mutation, halt with an escalation under `.molcajete/escalations/{id}.md`.
  - RED → proceed to 7.6 (Phase 2 implement).
- **mode: cover** / `objective: coverage` — expect GREEN.
  - GREEN → proceed to 7.6 (Phase 2 add assertions) and then mutation check.
  - RED → halt with an escalation under `.molcajete/escalations/{id}.md`: "Coverage slice {id} scaffold is RED before tests are added — existing implementation appears broken or the scaffold targets the wrong files. Investigate via `/m:fix`."

### 7.6 Phase 2 — Implement or assert

- **mode: default** / `implement` slice: write production code in its final form to satisfy the slice's Contracts (Types / API Surface / Behavior) and turn the scaffold GREEN. Fill empty `it` bodies with concrete assertions as you implement. Honour `dependency_exports` signatures verbatim.
- **mode: cover** / `coverage` slice: add more assertions to the scaffold to close coverage on `files.modify`. **Do not write production code.** The only exception is the testing skill's reactive refactor rule for genuinely untestable seams — in cover mode this is rare and surfaces as a `/m:fix` escalation, not a code change here.

Run the scoped test + coverage commands.

- All green + per-file coverage ≥ `testing.threshold` on every touched file → proceed to 7.7 (mutation check).
- RED → retry up to 3 more times. Each retry: the only context is the failing test output plus the slice frontmatter. Do NOT re-read the slice body, dependency exports, or modify files.
- On the 3rd RED, halt with an escalation under `.molcajete/escalations/{id}.md` with the last test output.

### 7.7 Mutation check

For each file in `files.modify` (and `files.create` if present), rewrite every exported function/binding named in `slice.provides` to throw `new Error('MUTANT')` (or language-equivalent). Save originals first. Run the scoped test command. Restore originals in a `finally`.

- `implement` slice: mutation is only run when the scaffold started GREEN unexpectedly (Phase 1 check). Success = RED.
- `coverage` slice: mutation is mandatory after Phase 2. Success = RED. GREEN after mutation means added assertions are vacuous; retry up to 3 more times passing only the mutation report plus the slice frontmatter.

**Never leave a file mutated on exit.** Verify restoration by re-reading and comparing to the saved original.

### 7.8 Record per-slice outcome

Write `.molcajete/slices/{id}.json`:

```json
{
  "id": "{id}",
  "use_case": "{use_case}",
  "feature": "{feature}",
  "objective": "{objective}",
  "status": "implemented",
  "plan_id": "<plan-id>",
  "completed_at": "{ISO timestamp}",
  "files_touched": [...],
  "covers": [...],
  "summary": "{one paragraph: what got built / what got covered, key decisions, anything downstream slices should know}"
}
```

## Step 8: Update the Plan and Logs

After every requested task succeeds:

1. **Update `plan.md`.** Flip each completed task/sub-task checkbox from `[ ]` to `[x]`. Preserve the rest of the file verbatim.
2. **Update each UC's log.** For every UC whose slices were completed by this run, use the `uc-log` shared skill to:
   - Locate the log entry whose `plan:<plan-id>` matches and whose corresponding slices are now all `implemented`.
   - Flip its status from `dirty` to `implemented` and move the line from `TODO:` to `DONE:` (prepended at the top of `DONE:`).
   - Recompute and write the UC's frontmatter `status` per the roll-up rules. If every log entry on the UC is `implemented`, the UC status becomes `implemented`.

If a slice failed (escalation written), do **not** flip the log entry — leave it in `TODO:` as `dirty`. The user resolves the escalation and re-runs `/m:build` for that task.

## Step 9: Report

Tell the user:

- The plan ID and mode.
- For each completed task: slice ID, name, objective, files touched, materialized test file path, final coverage percentage.
- For each escalation (if any): slice ID and escalation file path.
- UC status changes (e.g., `UC-0KTg: dirty → implemented`).
- Plan checklist progress (e.g., "3 of 5 tasks complete in plan `{plan-id}`").

If the host project's coverage collector wasn't available (per Step 6) and you estimated against the floor, note that explicitly: "Coverage was estimated; `specs/TECH-STACK.md` does not declare a coverage collector for module `{module}`."

If every task in the plan is now complete, suggest: "Plan `{plan-id}` is fully executed."

If unfinished tasks remain, suggest: "Next: `/m:build {plan-id} {next-T-NNN}` to continue."
