---
description: Generate tasks.json and launch the coordinated build
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: <spec folder path>
---

# Run Coordinated Build

You are generating a `tasks.json` file from the task plan and launching the coordinated build pipeline. The coordinator dispatches tasks in dependency order, running up to N tasks concurrently per level.

**Spec folder:** $ARGUMENTS

## Step 1: Locate Spec Folder

1. If `$ARGUMENTS` is a path (contains `/`), use it directly.
2. If `$ARGUMENTS` is a name or slug, search `prd/specs/*/` for a matching folder.
3. If ambiguous or no match, use AskUserQuestion to ask the user which spec folder to use.
4. Verify the folder exists and contains at least `tasks.md`.

## Step 2: Verify Prerequisites

1. **tasks.md** -- Read `prd/specs/{folder}/tasks.md`. If it does not exist, stop and tell the user to run `/m:tasks` first.
2. **Go Task** -- Run `which task` to verify Go Task is installed. If not found, tell the user to install it: `go install github.com/go-task/task/v3/cmd/task@latest`.
3. **BDD scenarios** -- Check if `bdd/features/` exists and contains `.feature` files tagged with UCs from this spec. Report BDD status (available/not available).

## Step 3: Generate tasks.json

Parse `tasks.md` and generate `prd/specs/{folder}/tasks.json` with this schema:

```json
{
  "spec": "{folder-name}",
  "generated": "{ISO-8601 timestamp}",
  "timeout": 897,
  "use_cases": [
    {
      "id": "UC-{tag}-NNN",
      "title": "Use case title",
      "phase": "pending",
      "retries": 0,
      "error": null,
      "subtasks": [
        {
          "id": "UC-{tag}-NNN/N.M",
          "title": "Subtask title",
          "complexity": "{points}",
          "dependencies": ["UC-{tag}-NNN/N.M"],
          "status": "pending | completed | in_progress | failed",
          "retries": 0,
          "worktree": null,
          "commit": null,
          "error": null
        }
      ]
    }
  ]
}
```

### Schema Notes

- Subtasks are nested under their parent UC (no flat `tasks[]` array).
- Each UC has a `phase` field tracking the pipeline stage: `pending | planning | bdd_writing | implementing | validating | completed | failed`.
- The `timeout` field at root level is fixed at 897 seconds.
- Set all UC phases to `"pending"` and all subtask statuses to `"pending"` (or `"completed"` for `[x]` checkboxes).

### Parsing Rules

- Each `- [ ]` checkbox line is a pending task. Each `- [x]` is completed.
- Extract task ID from the format `N.M {title}` under UC headings.
- Extract complexity from `- Complexity: {N}` sub-bullets.
- Extract dependencies from `- Dependencies: {list}` sub-bullets. Parse comma-separated task IDs.
- Combine UC heading ID with task number: `UC-{tag}-NNN` + `/N.M`.
- Group subtasks under their UC heading. Extract UC ID and title from the heading.

## Step 4: Present Summary

Display a summary table:

| Metric | Value |
|--------|-------|
| Spec folder | {path} |
| Use cases | {count} |
| Total subtasks | {count} |
| Completed | {count} |
| Pending | {count} |
| BDD scenarios | {available/not available} |
| Timeout | 897s |
| Max parallel UCs | {MOLCAJETE_MAX_PARALLEL or 1} |

Also display a UC breakdown:

| UC ID | Title | Subtasks | Phase |
|-------|-------|----------|-------|
| UC-{tag}-NNN | {title} | {count} | pending |

Use AskUserQuestion:
- Question: "Ready to launch the coordinated build?"
- Options:
  - "Yes, launch" -- proceed to Step 5
  - "No, cancel" -- stop

## Step 5: Launch Coordinator

Run the coordinator:

```bash
task -t ${CLAUDE_PLUGIN_ROOT}/scripts/Taskfile.yml run -- {spec-folder-path}
```

Monitor the output. The coordinator handles dispatching, merging, retries, and status updates.

## Step 6: Final Report

After the coordinator exits:

1. Read `prd/specs/{folder}/tasks.json` for final status.
2. Display a UC-level completion report:

| UC ID | Title | Phase | Retries |
|-------|-------|-------|---------|
| UC-{tag}-NNN | {title} | {phase} | {retries} |

3. Display a subtask-level report:

| Subtask ID | Title | Status | Commit |
|------------|-------|--------|--------|
| UC-{tag}-NNN/N.M | {title} | {status} | {hash or N/A} |

4. If any UCs failed, list them with error details.
5. If BDD scenarios exist, suggest running the full BDD suite: "Run the full BDD validation with `/m:test bdd`"

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
