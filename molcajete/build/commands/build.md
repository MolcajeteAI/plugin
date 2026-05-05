---
description: Implement a plan task — production code, tests, and step definitions
model: claude-opus-4-6
argument-hint: "<plan-name> <T-NNN>"
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

You implement a single plan task interactively. You read the plan, load the task context, write production code and/or step definitions based on the task's intent, update plan state, and commit. No worktrees, no hooks, no headless sessions -- the user is present and handles testing.

**Arguments:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response. This keeps you in control of the conversation flow.

## Step 1: Load Skills

Read all four skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/build/skills/implementing/SKILL.md` -- plan authority, state transitions, implementation procedures, error handling
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/SKILL.md` -- BDD conventions, step writing, tagging, scaffold
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/git-committing/SKILL.md` -- commit format, style detection, attribution
4. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` -- plan JSON schema reference

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

1. Verify `prd/PROJECT.md` and `prd/MODULES.md` both exist. If either is missing:

   "Project foundation not found. Run `/m:setup` first to create PROJECT.md and MODULES.md."

   Then stop.

2. Verify `.molcajete/plans/` directory exists. If missing:

   "No plans directory found. Run `/m:plan` first to generate a plan."

   Then stop.

## Step 3: Parse Arguments

Parse `$ARGUMENTS` for two required tokens:

1. **Plan name** -- the directory name under `.molcajete/plans/` (e.g., `202604021530-login`)
2. **Task ID** -- the task identifier (e.g., `T-001`)

If `$ARGUMENTS` is empty or contains fewer than two tokens:

1. List available plans by globbing `.molcajete/plans/*/plan.json`
2. Tell the user:

   "Usage: `/m:build <plan-name> <T-NNN>`\n\nAvailable plans:\n{list each plan directory name}"

   Then stop.

Verify the plan exists: glob `.molcajete/plans/{plan-name}/plan.json`. If not found:

1. List available plans
2. Tell the user: "Plan '{plan-name}' not found." with the list of available plans

Then stop.

## Step 4: Load Plan

1. Read `plan.json` from `.molcajete/plans/{plan-name}/plan.json`
2. Read `plan.md` from `.molcajete/plans/{plan-name}/plan.md` (if it exists)
3. Parse the plan JSON. Verify it has `tasks` array and required top-level fields (`title`, `status`, `scope`, `base_branch`).

## Step 5: Validate Task

1. Find the task with matching `id` in the plan's `tasks` array. If not found:

   "Task {T-NNN} not found in plan '{plan-name}'. Available tasks:\n\n{list each task: id, title, status}"

   Then stop.

2. If the task's status is `implemented`:

   Count implemented vs. total tasks. Tell the user:

   "Task {T-NNN} ({title}) is already implemented. Plan progress: {X}/{Y} tasks done."

   If other pending tasks exist with met dependencies, list them as candidates. Then stop.

3. Check dependencies: for each ID in `task.depends_on`, verify the corresponding task has `status: "implemented"`. If any dependency is not met:

   "Task {T-NNN} is blocked. These dependencies are not yet implemented:\n\n{list each unmet dep: id, title, status}"

   Then stop.

4. Present the task to the user via AskUserQuestion:

   - Question: "**{task.id}: {task.title}**\n\n**Intent:** {task.intent}\n**Scenario:** {task.scenario || 'none (infrastructure)'}\n**Use Case:** {task.use_case}\n**Feature:** {task.feature}\n**Module:** {task.module}\n\n**Description:**\n{task.description}\n\n**Files to modify:**\n{task.files_to_modify as bulleted list}\n\n{if task.sub_tasks}**Sub-tasks:** {count} sub-tasks{/if}\n\nReady to implement?"
   - Header: "Build Task"
   - Options: "Proceed" / "Cancel"

   If "Cancel", stop.

## Step 6: Load Task Context

Issue all reads in a single parallel batch (one assistant turn, multiple tool_use blocks). This context is essential -- the model must understand the full project, the feature requirements, and the task details to implement correctly.

### 6.1 Project-Level Context

Read all project-level files. These establish the shared vocabulary, tech stack, domains, actors, and feature landscape:

- `prd/PROJECT.md` -- project description (required)
- `prd/TECH-STACK.md` -- technology choices, project organization, and how the project runs (if exists)
- `prd/ACTORS.md` -- system actors for consistent actor references across specs (if exists)
- `prd/DOMAINS.md` -- domain registry so you know what domains exist (e.g., identity, orders) (if exists)
- `prd/FEATURES.md` -- master feature registry showing what is already implemented (if exists)
- `prd/GLOSSARY.md` -- shared terminology for consistent language (if exists)
- `prd/MODULES.md` -- module registry (required)
- `.molcajete/settings.json` -- BDD framework/language settings (if exists)

### 6.2 Feature and Use Case Context

Read the feature-level and use-case-level specs. These define WHAT the code must do:

- **REQUIREMENTS.md** -- feature requirements (EARS syntax, functional/non-functional, acceptance criteria). Derive the path from the UC file's parent feature directory: `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md`
- **ARCHITECTURE.md** -- architecture context, Code Map, data model, integration points. Read from `task.architecture` (if non-empty path)
- **UC file** -- the use case being implemented. Glob `prd/modules/*/features/*/use-cases/{task.use_case}-*.md` to find and read it. Contains the objective, preconditions, trigger, scenarios with Given/Steps/Outcomes/Side Effects

### 6.3 Gherkin and BDD Context

Read the BDD artifacts that define the done signal:

- **Feature file** -- Glob `bdd/features/**/{task.use_case}-*.feature` (or `*.feature.md` for MDG). If not found and `task.scenario` is non-null, tell the user: "Gherkin file not found for {task.use_case}. Run `/m:scenario {task.use_case}` first." Then stop.
- **Step index** -- `bdd/steps/INDEX.md` (if exists) for existing reusable step definitions

### 6.4 Plan Context

The task object from plan.json is already parsed (Step 4). Now load the narrative:

- **Plan.md task section** -- Locate the `### T-NNN` section in `plan.md`. If the task ID has a sub-task format (`T-NNN-M`), use the parent ID (`T-NNN`) to find the section. This section contains: What changes, Important snippets, Files to create/modify, Non-requirements, Verification.
- **Prior task summaries** -- For each task ID in `task.depends_on`, read its `summary` field from `plan.json`. These provide context about what was already built and key decisions made.

## Step 7: Validate plan.md

If `plan.md` is missing or the `### {task.id}` section (or parent `### T-NNN` for sub-tasks) is not found:

"Companion plan.md is missing or the task section was not found. Regenerate the plan with `/m:plan` or restore the file before running `/m:build`."

Then stop.

## Step 8: Update Plan State (in_progress)

1. Set `task.status` to `"in_progress"` in the parsed plan JSON
2. If the plan's top-level `status` is `"pending"`, set it to `"in_progress"`
3. Write the updated plan JSON back to `.molcajete/plans/{plan-name}/plan.json`

## Step 9: Activate Task Scenarios

If `task.scenario` is non-null and the task's previous status was NOT `failed` (i.e., this is not a retry):

1. Derive the scenario tag: `@{task.scenario}` (e.g., `@SC-0A1b`)
2. Read the `.feature` file (already found in Step 6)
3. Find the line containing the scenario tag
4. Remove `@pending` and/or `@dirty` from that tag line
5. Write the edited `.feature` file

On retry (task was previously `failed`), skip this step -- tags were already removed on the first pass.

## Step 10: Implement

Check `task.sub_tasks`:

### Path A: No Sub-Tasks (sub_tasks is null)

Read the appropriate implementation reference based on `task.intent`:

- **`implement`:** Read `${CLAUDE_PLUGIN_ROOT}/build/skills/implementing/references/implement-intent.md` and follow it.
  - Phase A: Production code + unit tests
  - Phase B: Step definitions
- **`wire-bdd`:** Read `${CLAUDE_PLUGIN_ROOT}/build/skills/implementing/references/wire-bdd-intent.md` and follow it.
  - Single phase: Step definitions only (no production code changes)

Use the plan.md `### T-NNN` section as the implementation guide. It contains "What changes", "Important snippets", "Files to create/modify", "Non-requirements", and "Verification".

Use the Gherkin `.feature` file content to understand what scenarios assert. Filter by `task.scenario` (the `@SC-XXXX` tag) to focus on the in-scope scenario.

### Path B: With Sub-Tasks (sub_tasks is an array)

Iterate through sub-tasks in order, respecting `depends_on`:

For each sub-task:

1. **Check dependencies** -- For each ID in `sub_task.depends_on`, verify the corresponding sibling sub-task has `status: "implemented"`. If a dependency has `status: "failed"`, mark this sub-task and the parent task as `failed` and stop.

2. **Mark in_progress** -- Set `sub_task.status` to `"in_progress"` and write plan.json.

3. **Implement** -- Implement the sub-task's scope:
   - Read `sub_task.description` for what to implement
   - Read `sub_task.files_to_modify` for target files
   - The sub-task inherits `intent`, `use_case`, `feature`, `module`, `architecture`, `scenario` from the parent task
   - Follow the same implementation procedure as Path A, but scoped to this sub-task's files and description

4. **Commit** -- Read and follow the git-committing skill. Stage only the files modified in this sub-task.

5. **Update status** -- Set `sub_task.status` to `"implemented"` with `sub_task.summary`, or `"failed"` with `sub_task.errors`. Write plan.json.

6. **Handle failure** -- If the sub-task failed:
   - Set the parent `task.status` to `"failed"`
   - Set `task.errors` to `["Sub-task {sub_task.id} failed: {sub_task.errors}"]`
   - Write plan.json
   - Report the failure to the user and stop

After all sub-tasks complete successfully, proceed to Step 11.

## Step 11: Commit

**Skip this step if the task had sub-tasks** -- each sub-task already committed individually.

For tasks without sub-tasks:

1. Read the git-committing skill if not already loaded
2. Self-review: run `git diff` and check for debug statements, commented-out code, hardcoded secrets, or TODO placeholders
3. Stage specific files -- never `git add .` or `git add -A`
4. Commit following the git-committing skill's format

## Step 12: Update Plan State (final)

1. **Task status:**
   - If implementation succeeded: set `task.status` to `"implemented"` and write `task.summary` describing what was implemented, key decisions, and watch-outs for dependent tasks
   - If implementation failed: set `task.status` to `"failed"` and write `task.errors` describing what went wrong

2. **Plan-level status:**
   - Count tasks by status
   - If ALL tasks are `"implemented"`: set plan `status` to `"implemented"`
   - If this task `"failed"`: set plan `status` to `"failed"`
   - Otherwise: keep plan `status` as `"in_progress"`

3. Write the updated plan JSON to `.molcajete/plans/{plan-name}/plan.json`

## Step 13: Report

Tell the user what happened:

- **Files created/modified** -- list all files that were created or changed
- **Task summary** -- the summary written to plan.json
- **Plan progress** -- "Completed {task.id} ({X}/{Y} tasks done)"

Then suggest next steps:

- **If more pending tasks have met dependencies:** "Next tasks ready:\n{list: id, title}\n\nRun `/m:build {plan-name} <T-NNN>` to continue."
- **If all tasks are implemented:** "All {Y} tasks complete. Plan '{plan-name}' is fully implemented."
- **If this task failed:** "Task {task.id} failed. Fix the issue and re-run `/m:build {plan-name} {task.id}` to retry."
- **If remaining tasks are blocked:** "Remaining tasks are blocked by failed dependencies. Fix the failed tasks first."
