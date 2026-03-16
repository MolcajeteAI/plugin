---
description: "Run a spec end-to-end: plan, build, test, validate"
model: claude-opus-4-6
allowed-tools: Read, Write, Glob, Grep, Bash, Agent, AskUserQuestion
argument-hint: <spec-folder>
---

# Run Spec End-to-End

You are the Planner for `/m:run`. Your job: parse `tasks.md` into a validated `tasks.json`, then launch the dispatcher. One focused prompt — no sub-agents.

**Spec folder argument:** $ARGUMENTS

## Step 1: Resolve Spec Folder

Determine the spec folder path from `$ARGUMENTS`:

1. If `$ARGUMENTS` is empty, list folders in `prd/specs/` and use AskUserQuestion to ask which one.
2. If `$ARGUMENTS` is a full path (e.g., `prd/specs/20260316-1650-simplified_dispatch_pipeline`), use it directly.
3. If `$ARGUMENTS` is a partial name (e.g., `simplified_dispatch` or `20260316`), search `prd/specs/` for a matching folder. If multiple matches, use AskUserQuestion to disambiguate.

Verify the folder exists and contains `tasks.md`. If `tasks.md` is missing, tell the user to run `/m:tasks` first and stop.

Set `SPEC_FOLDER` to the resolved path (e.g., `prd/specs/20260316-1650-simplified_dispatch_pipeline`).

## Step 2: Check for Existing tasks.json (Resume Flow)

Check if `{SPEC_FOLDER}/tasks.json` already exists.

### If tasks.json exists

Read it and summarize the current state:
- Count UCs by status: done, failed, pending
- Count subtasks by status per UC

Present the status to the user and use AskUserQuestion:
- Question: "tasks.json already exists with the status above. Resume the run?"
- Header: "Resume"
- Options:
  - "Yes — skip done UCs, restart failed ones" — keep existing tasks.json, reset failed UCs and their subtasks to `pending`, leave done UCs as-is
  - "Cancel" — stop execution
- multiSelect: false

If the user chooses "Yes":
1. Read the existing tasks.json
2. For each UC where `done` is `true`: leave it unchanged
3. For each UC where `done` is `false` and any subtask has `status: "failed"`:
   - Reset all `failed` subtasks to `status: "pending"`, `retries: 0`, `commit: null`, `review: null`, `error: null`
   - Reset the tester object if `tester.status` is `"failed"`: set `status: "pending"`, `retries: 0`, `commit: null`, `step_files: []`, `scenarios_count: 0`, `error: null`
4. Write the updated tasks.json back
5. Skip to Step 7 (display summary and launch)

### If tasks.json does not exist

Proceed to Step 3.

## Step 3: Read and Parse tasks.md

Read `{SPEC_FOLDER}/tasks.md` and extract the structure:

### 3a. Extract Use Cases

Find all headings matching `## [ ] UC-{tag}-NNN. {title}` or `## [x] UC-{tag}-NNN. {title}`.

For each UC, extract:
- `id`: The UC ID (e.g., `UC-0Rz0-001`)
- `title`: The title after the ID and period (e.g., `Simplified Planner`)

### 3b. Extract Tasks and Subtasks

Under each UC heading, find tasks and subtasks:

- **Tasks** match `- [ ] N. {title}` or `- [x] N. {title}` (where N is a number)
- **Subtasks** match `- [ ] N.M {title}` or `- [x] N.M {title}` (indented under a task)

For each task/subtask, extract:
- `id`: The dot-notation identifier (e.g., `1` for a task, `1.1` for a subtask)
- `title`: The title text

If a task has subtasks, the subtasks become the entries in the `subtasks` array. If a task has NO subtasks, the task itself becomes a single entry in `subtasks` with its own id.

### 3c. Generate Tags

For each UC, generate the BDD tag:
- Take the UC ID (e.g., `UC-0Rz0-001`)
- Replace the `UC-` prefix with `uc-`, preserving the Base-62 case in the middle segment: `uc-0Rz0-001`
- This becomes the `tag` field and is used as `@uc-0Rz0-001` in BDD feature files

## Step 4: Match UCs to BDD Feature Files

For each UC, find its BDD feature file:

1. Use Grep to search `bdd/features/` for files containing `@uc-{tag}` (using the tag generated in Step 3c). Search for the tag case-insensitively.
2. If exactly one file matches, set `feature_file` to that file's path (relative to project root).
3. If no file matches, record a validation error: `"No feature file found for UC {id} — expected @{tag} tag in bdd/features/"`.
4. If multiple files match, use the first match and note it (multiple feature files for one UC is unusual but acceptable).

## Step 5: Validate Invariants

Check all invariants before writing tasks.json. Collect ALL errors (don't stop at the first one):

| Rule | Error Message |
|------|---------------|
| At least one UC exists | `"tasks.json has no use cases"` |
| Every UC has a non-empty `feature_file` | `"UC {id} has no feature_file — every UC must map to a BDD feature"` |
| Every `feature_file` path exists on disk | `"Feature file {path} not found for UC {id}"` |
| Every subtask has a unique `id` within its UC | `"Duplicate subtask id {id} in UC {uc_id}"` |
| All subtask `status` fields are `pending` | `"Subtask {id} has non-pending initial status"` |
| `bdd/steps/` directory exists and contains at least one file | `"Step files required — run /m:stories first"` |

If any validation errors exist, display ALL of them and stop. Do not write tasks.json.

## Step 6: Build and Write tasks.json

Determine the base branch:

```bash
git rev-parse --abbrev-ref HEAD
```

Build the tasks.json object following the schema:

```json
{
  "spec_folder": "{SPEC_FOLDER}",
  "base_branch": "{current git branch}",
  "created_at": "{ISO-8601 UTC timestamp}",
  "use_cases": [
    {
      "id": "{UC ID}",
      "title": "{UC title}",
      "tag": "{lowercase tag}",
      "feature_file": "{path to feature file}",
      "done": false,
      "worktree": null,
      "tester": {
        "status": "pending",
        "retries": 0,
        "commit": null,
        "step_files": [],
        "scenarios_count": 0,
        "error": null
      },
      "subtasks": [
        {
          "id": "{subtask id}",
          "title": "{subtask title}",
          "status": "pending",
          "retries": 0,
          "commit": null,
          "review": null,
          "error": null
        }
      ]
    }
  ]
}
```

Write the JSON to `{SPEC_FOLDER}/tasks.json` with 2-space indentation.

## Step 7: Display Summary and Confirm Launch

Display a summary table:

```
Spec: {SPEC_FOLDER}
Base branch: {base_branch}

| UC | Title | Subtasks | Feature File | Status |
|----|-------|----------|--------------|--------|
| {id} | {title} | {count} | {feature_file} | {pending/done/failed} |

Total: {N} use cases, {M} subtasks
```

For resume runs, show which UCs are done (will be skipped) and which are pending/reset.

Then use AskUserQuestion:
- Question: "Ready to launch the dispatcher?"
- Header: "Launch"
- Options:
  - "Yes, launch dispatch" — proceed to Step 8
  - "No, just generate tasks.json" — stop here (tasks.json is already written)
- multiSelect: false

## Step 8: Launch Dispatcher

Launch the dispatcher:

```bash
bash molcajete/scripts/dispatch.sh "{SPEC_FOLDER}/tasks.json"
```

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Do not use sub-agents. Read files directly.
- Do not modify tasks.md — the Planner is read-only on tasks.md.
- Write only tasks.json (and update it on resume).
- Do not use the word "comprehensive" in any output.
- All validation errors must be shown at once, not one at a time.
